"""Gate 3-9 ~ 3-12: EventFlightSummary, clock_tick, replay pagination."""
import json

import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session

from src.repositories.event_repository import event_repository
from src.security.jwt import create_access_token
from src.websocket.lobby_handler import (
    broadcast_clock_tick,
    broadcast_event_flight_summary,
)


def _make_token(user_id=1, email="admin@test.com", role="admin") -> str:
    return create_access_token(user_id, email, role)


# ── Gate 3-9: EventFlightSummary broadcast ──

def test_event_flight_summary_broadcast(client: TestClient, seed_users):
    """broadcast_event_flight_summary sends to Lobby subscribers."""
    from src.main import app
    import asyncio

    token = _make_token(
        user_id=seed_users["admin"].user_id,
        email="admin@test.com",
        role="admin",
    )

    with client.websocket_connect(f"/ws/lobby?token={token}") as ws:
        manager = app.state.ws_manager

        # Trigger broadcast (run async in sync test context)
        loop = asyncio.new_event_loop()
        sent = loop.run_until_complete(
            broadcast_event_flight_summary(manager, {
                "eventFlightId": 123,
                "displayName": "Day 1A",
                "status": "live",
                "entries": 1200,
                "playersLeft": 890,
            })
        )
        loop.close()

        assert sent >= 1

        msg = json.loads(ws.receive_text())
        assert msg["type"] == "event_flight_summary"
        assert msg["tableId"] == "*"
        assert msg["payload"]["displayName"] == "Day 1A"


# ── Gate 3-10: clock_tick broadcast ──

def test_clock_tick_broadcast(client: TestClient, seed_users):
    """broadcast_clock_tick sends to Lobby subscribers."""
    from src.main import app
    import asyncio

    token = _make_token(
        user_id=seed_users["admin"].user_id,
        email="admin@test.com",
        role="admin",
    )

    with client.websocket_connect(f"/ws/lobby?token={token}") as ws:
        manager = app.state.ws_manager

        loop = asyncio.new_event_loop()
        sent = loop.run_until_complete(
            broadcast_clock_tick(manager, {
                "eventFlightId": 123,
                "status": "running",
                "level": 8,
                "time_remaining_sec": 719,
            })
        )
        loop.close()

        assert sent >= 1

        msg = json.loads(ws.receive_text())
        assert msg["type"] == "clock_tick"
        assert msg["payload"]["level"] == 8


# ── Gate 3-11: GET /tables/:id/events?since=0&limit=5 → 5 events + has_more ──

def test_replay_events_with_pagination(client: TestClient, seed_users, db_session: Session):
    """Replay with limit returns correct page + has_more=true."""
    token = _make_token(
        user_id=seed_users["admin"].user_id,
        email="admin@test.com",
        role="admin",
    )
    table_id = "tbl-replay"

    # Insert 8 events
    for i in range(8):
        event_repository.append(
            table_id=table_id,
            event_type="hand_started",
            payload={"handNumber": i + 1},
            db=db_session,
        )

    resp = client.get(
        f"/api/v1/tables/{table_id}/events?since=0&limit=5",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    body = resp.json()
    data = body["data"]

    assert len(data["events"]) == 5
    assert data["events"][0]["seq"] == 1
    assert data["events"][4]["seq"] == 5
    assert data["last_seq"] == 5
    assert data["has_more"] is True


# ── Gate 3-12: GET /tables/:id/events?since=5&limit=5 → rest + has_more=false ──

def test_replay_events_second_page(client: TestClient, seed_users, db_session: Session):
    """Second page returns remaining events + has_more=false."""
    token = _make_token(
        user_id=seed_users["admin"].user_id,
        email="admin@test.com",
        role="admin",
    )
    table_id = "tbl-replay2"

    # Insert 8 events
    for i in range(8):
        event_repository.append(
            table_id=table_id,
            event_type="action_performed",
            payload={"action": "fold", "n": i},
            db=db_session,
        )

    resp = client.get(
        f"/api/v1/tables/{table_id}/events?since=5&limit=5",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    body = resp.json()
    data = body["data"]

    assert len(data["events"]) == 3  # seq 6, 7, 8
    assert data["events"][0]["seq"] == 6
    assert data["last_seq"] == 8
    assert data["has_more"] is False


# ── Replay can_undo field ──

def test_replay_events_include_can_undo(client: TestClient, seed_users, db_session: Session):
    """Replay events include can_undo field based on inverse_payload."""
    token = _make_token(
        user_id=seed_users["admin"].user_id,
        email="admin@test.com",
        role="admin",
    )
    table_id = "tbl-undo-replay"

    # Event with inverse_payload
    event_repository.append(
        table_id=table_id,
        event_type="seat_assigned",
        payload={"seat": 3},
        inverse_payload={"seat": 3, "playerId": None},
        db=db_session,
    )
    # Event without inverse_payload
    event_repository.append(
        table_id=table_id,
        event_type="hand_started",
        payload={"handNumber": 1},
        db=db_session,
    )

    resp = client.get(
        f"/api/v1/tables/{table_id}/events?since=0",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    events = resp.json()["data"]["events"]

    assert events[0]["can_undo"] is True   # has inverse_payload
    assert events[1]["can_undo"] is False  # no inverse_payload


# ── Replay requires auth ──

def test_replay_events_requires_auth(client: TestClient):
    """Replay endpoint returns 401 without auth."""
    resp = client.get("/api/v1/tables/tbl-1/events?since=0")
    assert resp.status_code == 401
