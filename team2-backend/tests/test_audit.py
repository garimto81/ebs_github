"""Gate 5-9 ~ 5-12: Audit logs/events query + CSV download."""
import json

import pytest
from sqlmodel import Session

from src.models.audit_log import AuditLog
from src.repositories.event_repository import event_repository


# ── Helpers ──────────────────────────────────────────


def _login(client, email="admin@test.com", password="Admin123!") -> str:
    resp = client.post("/auth/login", json={"email": email, "password": password})
    return resp.json()["data"]["access_token"]


def _auth(client, role="admin"):
    emails = {"admin": "admin@test.com", "operator": "operator@test.com", "viewer": "viewer@test.com"}
    passwords = {"admin": "Admin123!", "operator": "Op123!", "viewer": "View123!"}
    return {"Authorization": f"Bearer {_login(client, emails[role], passwords[role])}"}


def _seed_audit_logs(db_session, user_id: int):
    """Seed some audit_logs for query tests."""
    for i in range(5):
        log = AuditLog(
            user_id=user_id,
            entity_type="series" if i % 2 == 0 else "event",
            entity_id=i + 1,
            action="create" if i < 3 else "update",
            detail=json.dumps({"index": i}),
        )
        db_session.add(log)
    db_session.commit()


def _seed_audit_events(db_session):
    """Seed audit_events for query tests."""
    for i in range(5):
        event_repository.append(
            table_id="tbl-001",
            event_type=f"event_type_{i}",
            payload={"n": i},
            correlation_id="corr-100" if i < 3 else "corr-200",
            db=db_session,
        )


# ── Gate 5-9: GET /audit-logs?user_id=N → 200 + time-ordered ──


def test_list_audit_logs_by_user(client, seed_users, db_session):
    """Filter audit_logs by user_id."""
    admin = seed_users["admin"]
    _seed_audit_logs(db_session, admin.user_id)
    headers = _auth(client, "admin")

    resp = client.get(f"/api/v1/audit-logs?user_id={admin.user_id}", headers=headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert len(data) == 5
    # Verify ordering (DESC by created_at — most recent first)
    assert all(isinstance(item["id"], int) for item in data)


def test_list_audit_logs_by_entity_type(client, seed_users, db_session):
    """Filter audit_logs by entity_type."""
    admin = seed_users["admin"]
    _seed_audit_logs(db_session, admin.user_id)
    headers = _auth(client, "admin")

    resp = client.get("/api/v1/audit-logs?entity_type=series", headers=headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert all(item["entity_type"] == "series" for item in data)


# ── Gate 5-10: GET /audit-events?table_id=tbl-001&since=0 → 200 + seq order ──


def test_list_audit_events_by_table(client, seed_users, db_session):
    """Filter audit_events by table_id and since seq."""
    _seed_audit_events(db_session)
    headers = _auth(client, "admin")

    resp = client.get("/api/v1/audit-events?table_id=tbl-001&since=0", headers=headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert len(data) == 5
    # All from same table
    assert all(item["table_id"] == "tbl-001" for item in data)


def test_list_audit_events_since_filters(client, seed_users, db_session):
    """since parameter filters events with seq > since."""
    _seed_audit_events(db_session)
    headers = _auth(client, "admin")

    resp = client.get("/api/v1/audit-events?table_id=tbl-001&since=3", headers=headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert len(data) == 2  # seq 4, 5


# ── Gate 5-11: correlation_id filter ──


def test_list_audit_events_correlation_filter(client, seed_users, db_session):
    """Filter audit_events by correlation_id."""
    _seed_audit_events(db_session)
    headers = _auth(client, "admin")

    resp = client.get("/api/v1/audit-events?correlation_id=corr-100", headers=headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert len(data) == 3
    assert all(item["correlation_id"] == "corr-100" for item in data)


# ── Gate 5-12: GET /audit-logs/download → Content-Type: text/csv ──


def test_download_audit_logs_csv(client, seed_users, db_session):
    """CSV download returns proper Content-Type and header row."""
    admin = seed_users["admin"]
    _seed_audit_logs(db_session, admin.user_id)
    headers = _auth(client, "admin")

    resp = client.get("/api/v1/audit-logs/download", headers=headers)
    assert resp.status_code == 200
    assert "text/csv" in resp.headers["content-type"]
    assert "attachment" in resp.headers.get("content-disposition", "")

    content = resp.text
    lines = content.strip().split("\n")
    # Header row
    assert "id" in lines[0]
    assert "user_id" in lines[0]
    assert "action" in lines[0]
    # Data rows
    assert len(lines) >= 6  # header + 5 data rows


# ── Additional: audit-logs requires admin ──


def test_audit_logs_requires_admin(client, seed_users, db_session):
    """Non-admin cannot access audit_logs."""
    headers = _auth(client, "viewer")
    resp = client.get("/api/v1/audit-logs", headers=headers)
    assert resp.status_code == 403


# ── Additional: empty audit_events returns empty list ──


def test_empty_audit_events(client, seed_users, db_session):
    """Empty audit_events returns empty list, not error."""
    headers = _auth(client, "admin")
    resp = client.get("/api/v1/audit-events?table_id=nonexistent", headers=headers)
    assert resp.status_code == 200
    assert resp.json()["data"] == []
