"""Gate 3-1 ~ 3-5, 3-15, 3-16: WebSocket auth, CC→BO→Lobby, ping/pong, disconnect."""
import json
import time

import pytest
from fastapi.testclient import TestClient

from src.security.jwt import create_access_token


# ── Helpers ──

def _make_token(user_id=1, email="op@test.com", role="operator") -> str:
    return create_access_token(user_id, email, role)


def _make_expired_token() -> str:
    """Create a token that is already expired."""
    from datetime import datetime, timedelta, timezone
    from jose import jwt
    from src.app.config import settings

    now = datetime.now(timezone.utc)
    payload = {
        "sub": "1",
        "email": "op@test.com",
        "role": "operator",
        "type": "access",
        "iat": int((now - timedelta(hours=2)).timestamp()),
        "exp": int((now - timedelta(hours=1)).timestamp()),  # expired 1h ago
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


# ── Gate 3-1: WS /ws/cc (valid JWT) → connect success ──

def test_ws_cc_connect_valid_jwt(client: TestClient, seed_users):
    token = _make_token(
        user_id=seed_users["operator"].user_id,
        email="operator@test.com",
        role="operator",
    )
    with client.websocket_connect(f"/ws/cc?token={token}&table_id=tbl-1") as ws:
        # Connection succeeded — send a message and expect ack
        ws.send_text(json.dumps({
            "type": "HandStarted",
            "tableId": "tbl-1",
            "payload": {"handNumber": 1},
            "messageId": "msg-001",
        }))
        ack = json.loads(ws.receive_text())
        assert ack["type"] == "Ack"
        assert ack["payload"]["status"] == "ok"


# ── Gate 3-2: WS /ws/cc (invalid JWT) → connect rejected ──

def test_ws_cc_connect_invalid_jwt(client: TestClient):
    with pytest.raises(Exception):
        with client.websocket_connect("/ws/cc?token=invalid-token&table_id=tbl-1") as ws:
            ws.receive_text()


# ── Gate 3-3: WS /ws/cc (expired JWT) → connect rejected ──

def test_ws_cc_connect_expired_jwt(client: TestClient):
    expired = _make_expired_token()
    with pytest.raises(Exception):
        with client.websocket_connect(f"/ws/cc?token={expired}&table_id=tbl-1") as ws:
            ws.receive_text()


# ── Gate 3-4: CC→BO HandStarted → audit_events INSERT + seq ──

def test_cc_hand_started_creates_audit_event(client: TestClient, seed_users, db_session):
    token = _make_token(
        user_id=seed_users["operator"].user_id,
        email="operator@test.com",
        role="operator",
    )
    with client.websocket_connect(f"/ws/cc?token={token}&table_id=tbl-5") as ws:
        ws.send_text(json.dumps({
            "type": "HandStarted",
            "tableId": "tbl-5",
            "payload": {"handId": 42, "handNumber": 15, "dealerSeat": 3},
            "messageId": "msg-hs-001",
        }))
        ack = json.loads(ws.receive_text())
        assert ack["payload"]["status"] == "ok"
        assert "seq" in ack["payload"]
        assert ack["payload"]["seq"] == 1

    # Verify in DB
    from sqlalchemy import text
    row = db_session.execute(
        text("SELECT * FROM audit_events WHERE table_id='tbl-5' AND seq=1")
    ).fetchone()
    assert row is not None
    assert row.event_type == "hand_started"


# ── Gate 3-5: CC→BO event → Lobby WS receives it ──

def test_cc_event_forwarded_to_lobby(client: TestClient, seed_users):
    token_op = _make_token(
        user_id=seed_users["operator"].user_id,
        email="operator@test.com",
        role="operator",
    )
    token_admin = _make_token(
        user_id=seed_users["admin"].user_id,
        email="admin@test.com",
        role="admin",
    )

    # Connect Lobby first
    with client.websocket_connect(f"/ws/lobby?token={token_admin}") as ws_lobby:
        # Connect CC
        with client.websocket_connect(
            f"/ws/cc?token={token_op}&table_id=tbl-7"
        ) as ws_cc:
            # Lobby receives OperatorConnected first
            op_connected = json.loads(ws_lobby.receive_text())
            assert op_connected["type"] == "OperatorConnected"

            # CC sends event
            ws_cc.send_text(json.dumps({
                "type": "HandStarted",
                "tableId": "tbl-7",
                "payload": {"handNumber": 1},
                "messageId": "msg-fwd-001",
            }))

            # CC gets ack
            ack = json.loads(ws_cc.receive_text())
            assert ack["type"] == "Ack"

            # Lobby receives forwarded event
            fwd = json.loads(ws_lobby.receive_text())
            assert fwd["type"] == "HandStarted"
            assert fwd["tableId"] == "tbl-7"
            assert fwd["seq"] == 1

        # After CC disconnect, Lobby should receive OperatorDisconnected
        disconn = json.loads(ws_lobby.receive_text())
        assert disconn["type"] == "OperatorDisconnected"
        assert disconn["payload"]["reason"] == "disconnected"


# ── Gate 3-15: WS connection stays alive (simplified ping/pong) ──

def test_ws_connection_stays_alive(client: TestClient, seed_users):
    """Verify WS connection remains open for normal message exchange."""
    token = _make_token(
        user_id=seed_users["operator"].user_id,
        email="operator@test.com",
        role="operator",
    )
    with client.websocket_connect(f"/ws/cc?token={token}&table_id=tbl-ping") as ws:
        # Send multiple messages — connection should stay alive
        for i in range(3):
            ws.send_text(json.dumps({
                "type": "ActionPerformed",
                "tableId": "tbl-ping",
                "payload": {"actionType": "fold", "seat": i},
                "messageId": f"msg-ping-{i}",
            }))
            ack = json.loads(ws.receive_text())
            assert ack["type"] == "Ack"
            assert ack["payload"]["status"] == "ok"


# ── Gate 3-16: WS disconnect → OperatorDisconnected event ──

def test_ws_disconnect_sends_operator_disconnected(client: TestClient, seed_users):
    """When CC disconnects, Lobby receives OperatorDisconnected."""
    token_op = _make_token(
        user_id=seed_users["operator"].user_id,
        email="operator@test.com",
        role="operator",
    )
    token_admin = _make_token(
        user_id=seed_users["admin"].user_id,
        email="admin@test.com",
        role="admin",
    )

    with client.websocket_connect(f"/ws/lobby?token={token_admin}") as ws_lobby:
        # CC connects and disconnects
        with client.websocket_connect(
            f"/ws/cc?token={token_op}&table_id=tbl-dc"
        ) as ws_cc:
            # Lobby gets OperatorConnected
            connected = json.loads(ws_lobby.receive_text())
            assert connected["type"] == "OperatorConnected"

        # CC context exited → disconnect
        disconn = json.loads(ws_lobby.receive_text())
        assert disconn["type"] == "OperatorDisconnected"
        assert disconn["payload"]["operatorId"] == str(seed_users["operator"].user_id)


# ── Lobby subscribe test ──

def test_lobby_subscribe(client: TestClient, seed_users):
    """Lobby can subscribe with filters."""
    token = _make_token(
        user_id=seed_users["admin"].user_id,
        email="admin@test.com",
        role="admin",
    )
    with client.websocket_connect(f"/ws/lobby?token={token}") as ws:
        ws.send_text(json.dumps({
            "type": "Subscribe",
            "payload": {"table_ids": ["tbl-1", "tbl-2"]},
            "messageId": "msg-sub-001",
        }))
        ack = json.loads(ws.receive_text())
        assert ack["type"] == "Ack"
        assert ack["payload"]["subscribed"] is True
