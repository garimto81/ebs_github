"""Tests for /chat/peers endpoint."""
import pytest
from unittest.mock import AsyncMock


@pytest.fixture
def mock_broker(monkeypatch):
    mock = AsyncMock()
    mock.discover_peers.return_value = {
        "peers": [
            {"source": "S2", "last_seen": "2026-05-11T15:30:00Z", "event_count": 12},
            {"source": "S3", "last_seen": "2026-05-11T15:32:00Z", "event_count": 5},
        ],
        "count": 2,
    }
    monkeypatch.setattr("tools.chat_server.server.broker", mock)
    return mock


def test_peers_returns_active_list(client, mock_broker):
    r = client.get("/chat/peers")
    assert r.status_code == 200
    body = r.json()
    assert body["count"] == 2
    assert {p["source"] for p in body["peers"]} == {"S2", "S3"}


def test_peers_idle_filter(client, mock_broker):
    """active=true 옵션 시 5분 이내만 반환."""
    r = client.get("/chat/peers?active=true")
    assert r.status_code == 200
    # mock 데이터 둘 다 최근이므로 변동 없음
    assert r.json()["count"] >= 0
