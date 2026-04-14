"""Gate 5-6 ~ 5-8: Undo via inverse event append + dual-write."""
import json

import pytest
from sqlalchemy import text
from sqlmodel import Session

from src.models.audit_event import AuditEvent
from src.repositories.event_repository import event_repository


# ── Helpers ──────────────────────────────────────────


def _login(client, email="admin@test.com", password="Admin123!") -> str:
    resp = client.post("/auth/login", json={"email": email, "password": password})
    return resp.json()["data"]["access_token"]


def _auth(client, role="admin"):
    emails = {"admin": "admin@test.com", "operator": "operator@test.com", "viewer": "viewer@test.com"}
    passwords = {"admin": "Admin123!", "operator": "Op123!", "viewer": "View123!"}
    return {"Authorization": f"Bearer {_login(client, emails[role], passwords[role])}"}


def _create_undoable_event(db_session: Session) -> AuditEvent:
    """Create a seat_moved event with inverse_payload."""
    return event_repository.append(
        table_id="tbl-001",
        event_type="seat_moved",
        payload={"seat": 3, "player_id": "p-1", "from_table": "tbl-001", "to_table": "tbl-002"},
        inverse_payload={"seat": 3, "player_id": "p-1", "from_table": "tbl-002", "to_table": "tbl-001"},
        correlation_id="corr-001",
        actor_user_id="1",
        db=db_session,
    )


# ── Gate 5-6: Undo seat_moved → inverse event appended + original preserved ──


def test_undo_seat_moved(client, seed_users, db_session):
    """Undo appends an inverse event; original is NOT deleted."""
    original = _create_undoable_event(db_session)
    headers = _auth(client, "admin")

    resp = client.post(f"/api/v1/events/{original.id}/undo", headers=headers)
    assert resp.status_code == 200

    data = resp.json()["data"]
    assert data["event_type"] == "undo_seat_moved"
    assert data["table_id"] == "tbl-001"
    inverse_id = data["inverse_event_id"]

    # Original event still exists
    original_check = db_session.get(AuditEvent, original.id)
    assert original_check is not None

    # Inverse event exists with correct causation_id
    inverse_check = db_session.get(AuditEvent, inverse_id)
    assert inverse_check is not None
    assert inverse_check.causation_id == str(original.id)
    assert inverse_check.correlation_id == "corr-001"
    assert inverse_check.event_type == "undo_seat_moved"


# ── Gate 5-7: Undo without inverse_payload → 400 UNDO_NOT_ALLOWED ──


def test_undo_not_allowed_without_inverse_payload(client, seed_users, db_session):
    """Events without inverse_payload cannot be undone."""
    event = event_repository.append(
        table_id="tbl-002",
        event_type="hand_started",
        payload={"hand_number": 1},
        # No inverse_payload
        db=db_session,
    )
    headers = _auth(client, "admin")

    resp = client.post(f"/api/v1/events/{event.id}/undo", headers=headers)
    assert resp.status_code == 400
    assert "UNDO_NOT_ALLOWED" in resp.json()["detail"]


# ── Gate 5-8: Dual-write — audit_events + audit_logs both recorded ──


def test_undo_dual_write(client, seed_users, db_session):
    """Undo writes to both audit_events (inverse) and audit_logs (admin action)."""
    original = _create_undoable_event(db_session)
    headers = _auth(client, "admin")

    resp = client.post(f"/api/v1/events/{original.id}/undo", headers=headers)
    assert resp.status_code == 200

    # Check audit_events — undo event exists
    rows = db_session.execute(
        text("SELECT * FROM audit_events WHERE event_type='undo_seat_moved'")
    ).fetchall()
    assert len(rows) == 1

    # Check audit_logs — undo admin action recorded
    log_rows = db_session.execute(
        text("SELECT * FROM audit_logs WHERE action='undo'")
    ).fetchall()
    assert len(log_rows) == 1
    log = log_rows[0]
    assert log.entity_type == "audit_event"
    assert log.entity_id == original.id
    detail = json.loads(log.detail)
    assert detail["original_event_type"] == "seat_moved"


# ── Additional: Undo nonexistent event → 404 ──


def test_undo_nonexistent_event(client, seed_users, db_session):
    """Undo of non-existent event returns 404."""
    headers = _auth(client, "admin")
    resp = client.post("/api/v1/events/99999/undo", headers=headers)
    assert resp.status_code == 404
    assert "EVENT_NOT_FOUND" in resp.json()["detail"]


# ── Additional: Undo requires admin role ──


def test_undo_requires_admin(client, seed_users, db_session):
    """Only admin can undo events."""
    original = _create_undoable_event(db_session)
    headers = _auth(client, "viewer")
    resp = client.post(f"/api/v1/events/{original.id}/undo", headers=headers)
    assert resp.status_code == 403
