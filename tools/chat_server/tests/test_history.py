"""Tests for /chat/history endpoint."""
import pytest
from unittest.mock import AsyncMock


@pytest.fixture
def mock_broker(monkeypatch):
    mock = AsyncMock()
    mock.get_history.return_value = {
        "events": [
            {
                "seq": 42,
                "topic": "chat:room:design",
                "source": "S2",
                "ts": "2026-05-11T15:30:00Z",
                "payload": {
                    "kind": "msg",
                    "from": "S2",
                    "to": ["S3"],
                    "body": "test",
                    "mentions": ["@S3"],
                    "ts": "2026-05-11T15:30:00Z",
                },
            }
        ],
        "count": 1,
    }
    monkeypatch.setattr("tools.chat_server.server.broker", mock)
    return mock


def test_history_default_channel(client, mock_broker):
    r = client.get("/chat/history?channel=room:design")
    assert r.status_code == 200
    body = r.json()
    assert len(body["events"]) == 1
    assert body["events"][0]["payload"]["body"] == "test"
    mock_broker.get_history.assert_called_once()
    args = mock_broker.get_history.call_args.kwargs
    assert args["topic"] == "chat:room:design"


def test_history_since_seq(client, mock_broker):
    r = client.get("/chat/history?channel=room:design&since_seq=10&limit=30")
    assert r.status_code == 200
    args = mock_broker.get_history.call_args.kwargs
    assert args["since_seq"] == 10
    assert args["limit"] == 30


def test_history_missing_channel_400(client, mock_broker):
    r = client.get("/chat/history")
    assert r.status_code == 422  # FastAPI auto-validates required query
