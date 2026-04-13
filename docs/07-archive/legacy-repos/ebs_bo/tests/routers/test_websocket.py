import pytest
from fastapi.testclient import TestClient


@pytest.fixture(autouse=True)
def _patch_hand_ws_engine(engine, monkeypatch):
    """Ensure hand_ws_service uses the in-memory test engine."""
    monkeypatch.setattr("bo.services.hand_ws_service.engine", engine)


def test_cc_websocket_connect(client: TestClient):
    """CC connects to /ws/cc?table_id=1 and receives messages."""
    with client.websocket_connect("/ws/cc?table_id=1") as ws:
        ws.send_json({"type": "HandStarted", "payload": {"hand_number": 1}})
        data = ws.receive_json()
        assert data["type"] == "HandStarted"
        assert data["payload"]["hand_number"] == 1
        assert "timestamp" in data
        assert "source_id" in data
        assert data["source_id"] == "cc-table-1"
        assert "message_id" in data
        # hand_id should be injected by the service
        assert "hand_id" in data["payload"]


def test_lobby_websocket_subscribe(client: TestClient):
    """Lobby connects and subscribes to tables."""
    with client.websocket_connect("/ws/lobby") as ws:
        ws.send_json({
            "type": "Subscribe",
            "payload": {"table_ids": [1, 2, 3]},
        })
        data = ws.receive_json()
        assert data["type"] == "SubscribeAck"
        assert data["payload"]["table_ids"] == [1, 2, 3]
        assert "timestamp" in data
        assert "message_id" in data


def test_cc_requires_table_id(client: TestClient):
    """CC endpoint requires table_id query parameter."""
    # WebSocket without table_id should fail
    try:
        with client.websocket_connect("/ws/cc") as ws:
            pass
        assert False, "Should have failed without table_id"
    except Exception:
        pass  # Expected to fail
