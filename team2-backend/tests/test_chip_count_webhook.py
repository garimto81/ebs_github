"""Chip count webhook receiver tests — Cycle 20 Wave 2 (issue #435).

SSOT contract: docs/2. Development/2.2 Backend/APIs/WSOP_LIVE_Chip_Count_Sync.md
WS event: docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md §4.2.11
State machine: docs/2. Development/2.5 Shared/Chip_Count_State.md

Covers:
- HMAC-SHA256 signature verification (canonical = METHOD\\nPATH\\nTS\\nSHA256(body).hex)
- Replay protection (±300s timestamp drift)
- Idempotency (header == body.snapshot_id; DB UNIQUE on snapshot_id)
- DB INSERT (immutable append, one row per seat)
- WS chip_count_synced broadcast (lobby channel)
- Schema validation (seat_number, chip_count, table_id)
"""
from __future__ import annotations

import hashlib
import hmac
import json
import uuid
from datetime import datetime, timedelta, timezone

import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session, select

from src.app.config import settings as app_settings


TEST_SECRET = "test-webhook-secret-32-bytes-hex-aaaaaaaaaaaaaaaaaa"


@pytest.fixture(autouse=True)
def _patch_webhook_secret(monkeypatch):
    monkeypatch.setattr(app_settings, "wsop_live_webhook_secret", TEST_SECRET)


PATH = "/api/wsop-live/chip-count-snapshot"


def _canonical(method: str, path: str, timestamp: str, body_bytes: bytes) -> str:
    body_hash = hashlib.sha256(body_bytes).hexdigest()
    return f"{method}\n{path}\n{timestamp}\n{body_hash}"


def _sign(method: str, path: str, timestamp: str, body_bytes: bytes,
          secret: str = TEST_SECRET) -> str:
    msg = _canonical(method, path, timestamp, body_bytes).encode("utf-8")
    return hmac.new(secret.encode("utf-8"), msg, hashlib.sha256).hexdigest()


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _seed_table(db: Session) -> int:
    from src.models.competition import Competition, Event, EventFlight, Series
    from src.models.table import Table

    comp = Competition(name="Test Comp")
    db.add(comp)
    db.commit()
    db.refresh(comp)

    series = Series(
        competition_id=comp.competition_id,
        series_name="S1",
        year=2026,
        begin_at="2026-05-01",
        end_at="2026-05-30",
    )
    db.add(series)
    db.commit()
    db.refresh(series)

    event = Event(
        series_id=series.series_id,
        event_no=1,
        event_name="E1",
        buy_in=1000,
    )
    db.add(event)
    db.commit()
    db.refresh(event)

    flight = EventFlight(event_id=event.event_id, display_name="Day 1A")
    db.add(flight)
    db.commit()
    db.refresh(flight)

    table = Table(event_flight_id=flight.event_flight_id, table_no=1, name="T1")
    db.add(table)
    db.commit()
    db.refresh(table)
    return table.table_id


def _make_body(table_id: int, snapshot_id: str | None = None,
               recorded_at: str | None = None, break_id: int = 1024,
               seats: list | None = None) -> dict:
    return {
        "snapshot_id": snapshot_id or str(uuid.uuid4()),
        "break_id": break_id,
        "table_id": table_id,
        "recorded_at": recorded_at or _now_iso(),
        "seats": seats if seats is not None else [
            {"seat_number": 1, "player_id": 901, "chip_count": 125000},
            {"seat_number": 2, "player_id": 902, "chip_count": 87500},
            {"seat_number": 3, "player_id": None, "chip_count": 0},
        ],
    }


def _post(client: TestClient, body: dict, *,
          signature: str | None = None,
          timestamp: str | None = None,
          idempotency_key: str | None = None,
          omit_signature: bool = False):
    ts = timestamp or _now_iso()
    body_bytes = json.dumps(body, separators=(",", ":")).encode("utf-8")
    sig = signature if signature is not None else _sign("POST", PATH, ts, body_bytes)
    headers = {
        "Content-Type": "application/json; charset=utf-8",
        "X-WSOP-Timestamp": ts,
        "Idempotency-Key": idempotency_key or body["snapshot_id"],
    }
    if not omit_signature:
        headers["X-WSOP-Signature"] = sig
    return client.post(PATH, content=body_bytes, headers=headers)


# 1. Valid signature persists snapshot ─────────────────────────

def test_valid_signature_persists_snapshot(client: TestClient, db_session: Session):
    from src.models.chip_count_snapshot import ChipCountSnapshot

    table_id = _seed_table(db_session)
    body = _make_body(table_id)

    resp = _post(client, body)

    assert resp.status_code == 202, resp.text
    payload = resp.json()
    assert payload["status"] == "accepted"
    assert payload["snapshot_id"] == body["snapshot_id"]
    assert payload["ws_event_dispatched"] is True
    assert "received_at" in payload

    rows = db_session.exec(
        select(ChipCountSnapshot).where(
            ChipCountSnapshot.snapshot_id == body["snapshot_id"]
        )
    ).all()
    assert len(rows) == 3
    by_seat = {r.seat_number: r for r in rows}
    assert by_seat[1].chip_count == 125000
    assert by_seat[1].player_id == 901
    assert by_seat[3].player_id is None
    assert by_seat[3].chip_count == 0
    assert all(r.break_id == 1024 for r in rows)
    assert all(r.signature_ok is True for r in rows)
    assert all(r.source == "wsop-live-webhook" for r in rows)


# 2. Invalid signature returns 401 ─────────────────────────────

def test_invalid_signature_returns_401(client: TestClient, db_session: Session):
    table_id = _seed_table(db_session)
    body = _make_body(table_id)

    resp = _post(client, body, signature="0" * 64)

    assert resp.status_code == 401
    assert resp.json()["error"] == "SIGNATURE_INVALID"


# 3. Replay attack blocked (timestamp drift > 300s) ────────────

def test_replay_attack_blocked(client: TestClient, db_session: Session):
    table_id = _seed_table(db_session)
    body = _make_body(table_id)
    old_ts = (datetime.now(timezone.utc) - timedelta(seconds=400)).isoformat().replace(
        "+00:00", "Z"
    )

    resp = _post(client, body, timestamp=old_ts)

    assert resp.status_code == 401
    assert resp.json()["error"] == "TIMESTAMP_DRIFT"


# 4. Idempotency: second call → already_processed ──────────────

def test_idempotency_returns_same_response(client: TestClient, db_session: Session):
    from src.models.chip_count_snapshot import ChipCountSnapshot

    table_id = _seed_table(db_session)
    body = _make_body(table_id)

    r1 = _post(client, body)
    r2 = _post(client, body)

    assert r1.status_code == 202
    assert r1.json()["status"] == "accepted"

    assert r2.status_code == 200
    assert r2.json()["status"] == "already_processed"
    assert r2.json()["snapshot_id"] == body["snapshot_id"]

    rows = db_session.exec(
        select(ChipCountSnapshot).where(
            ChipCountSnapshot.snapshot_id == body["snapshot_id"]
        )
    ).all()
    assert len(rows) == 3  # not duplicated


# 5. Malformed body returns 400 ────────────────────────────────

def test_invalid_body_400(client: TestClient, db_session: Session):
    _seed_table(db_session)
    ts = _now_iso()
    body_bytes = b"{not valid json"
    sig = _sign("POST", PATH, ts, body_bytes)
    resp = client.post(
        PATH,
        content=body_bytes,
        headers={
            "Content-Type": "application/json",
            "X-WSOP-Signature": sig,
            "X-WSOP-Timestamp": ts,
            "Idempotency-Key": str(uuid.uuid4()),
        },
    )
    assert resp.status_code == 400


# 6. seat_number out of range returns 400 ──────────────────────

def test_seat_number_validation(client: TestClient, db_session: Session):
    table_id = _seed_table(db_session)
    body = _make_body(
        table_id,
        seats=[{"seat_number": 11, "player_id": 1, "chip_count": 100}],
    )

    resp = _post(client, body)

    assert resp.status_code == 400


# 7. Negative chip_count returns 400 ───────────────────────────

def test_chip_count_non_negative(client: TestClient, db_session: Session):
    table_id = _seed_table(db_session)
    body = _make_body(
        table_id,
        seats=[{"seat_number": 1, "player_id": 1, "chip_count": -1}],
    )

    resp = _post(client, body)

    assert resp.status_code == 400


# 8. WS chip_count_synced event broadcasts on commit ───────────

def test_ws_event_broadcasts(client: TestClient, db_session: Session, seed_users):
    from src.security.jwt import create_access_token

    table_id = _seed_table(db_session)
    body = _make_body(table_id)
    token = create_access_token(
        user_id=seed_users["admin"].user_id,
        email="admin@test.com",
        role="admin",
    )

    with client.websocket_connect(f"/ws/lobby?token={token}") as ws:
        resp = _post(client, body)
        assert resp.status_code == 202

        chip_event = None
        for _ in range(5):
            msg = json.loads(ws.receive_text())
            if msg.get("type") == "chip_count_synced":
                chip_event = msg
                break

        assert chip_event is not None, "chip_count_synced event not broadcast"
        assert chip_event["data"]["table_id"] == table_id
        assert chip_event["data"]["snapshot_id"] == body["snapshot_id"]
        assert chip_event["data"]["break_id"] == 1024
        assert len(chip_event["data"]["seats"]) == 3
        assert chip_event["data"]["signature_ok"] is True


# 9 (bonus). Idempotency-Key ≠ body.snapshot_id → 409 ──────────

def test_idempotency_header_body_mismatch_409(client: TestClient, db_session: Session):
    table_id = _seed_table(db_session)
    body = _make_body(table_id)

    resp = _post(client, body, idempotency_key=str(uuid.uuid4()))

    assert resp.status_code == 409
    assert resp.json()["error"] == "IDEMPOTENCY_MISMATCH"
