"""Tests for /chat/stream SSE multiplex.

Note: TestClient 는 SSE 를 streaming response 로 처리. iter_lines 사용.

sse-starlette 2.1 ships a global `AppStatus.should_exit_event` that binds to
the first event loop it sees. TestClient creates a fresh loop per request,
which causes `RuntimeError: bound to a different event loop` on the 2nd test.
The `reset_sse_app_status` fixture resets it before each test.
"""
import json
import pytest
from unittest.mock import AsyncMock

from sse_starlette.sse import AppStatus


@pytest.fixture(autouse=True)
def reset_sse_app_status():
    """Reset sse-starlette's global event so each TestClient call gets a fresh loop binding."""
    AppStatus.should_exit_event = None
    yield
    AppStatus.should_exit_event = None


@pytest.fixture
def mock_broker(monkeypatch):
    mock = AsyncMock()
    # 첫 subscribe 호출: 단일 이벤트 반환
    # 두 번째 호출: empty (timeout)
    mock.subscribe.side_effect = [
        {
            "events": [
                {
                    "seq": 1,
                    "topic": "chat:room:design",
                    "source": "S2",
                    "ts": "2026-05-11T15:30:00Z",
                    "payload": {
                        "kind": "msg", "from": "S2", "to": [],
                        "body": "hi", "mentions": [], "ts": "2026-05-11T15:30:00Z",
                    },
                }
            ],
            "next_seq": 2,
            "mode": "history",
        },
        {"events": [], "next_seq": 2, "mode": "timeout"},
    ]
    monkeypatch.setattr("tools.chat_server.server.broker", mock)
    return mock


def test_sse_headers(client, mock_broker):
    """SSE response has correct Content-Type + Cache-Control (no-cache or no-store)."""
    with client.stream("GET", "/chat/stream?from_seq=0") as r:
        assert r.status_code == 200
        assert r.headers["content-type"].startswith("text/event-stream")
        # sse-starlette 2.1 uses 'no-store' (stricter than 'no-cache');
        # both achieve the same goal: prevent caching.
        cc = r.headers.get("cache-control", "").lower()
        assert "no-cache" in cc or "no-store" in cc


def test_sse_emits_chat_event(client, mock_broker):
    """First subscribe returns 1 event → SSE 'chat' event emitted with seq=1.

    Reads streaming response line-by-line and verifies the SSE wire format:
      event: chat
      data: {"seq": 1, ...}
    """
    with client.stream("GET", "/chat/stream?from_seq=0") as r:
        assert r.status_code == 200
        saw_event_line = False
        saw_data_line = False
        # iter_lines may emit blank lines between SSE records — read a bounded
        # number to avoid hanging on the mock's empty timeout response.
        for i, line in enumerate(r.iter_lines()):
            if i > 50:
                break
            if line.startswith("event:"):
                # event_type should be 'chat' (topic chat:room:design)
                assert "chat" in line
                saw_event_line = True
            elif line.startswith("data:"):
                data = json.loads(line[len("data:"):].strip())
                assert data["seq"] == 1
                assert data["topic"] == "chat:room:design"
                saw_data_line = True
            if saw_event_line and saw_data_line:
                break
        assert saw_event_line, "expected an 'event:' line in SSE stream"
        assert saw_data_line, "expected a 'data:' line with seq=1"
