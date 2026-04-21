"""Gate 4 — Idempotency middleware E2E tests."""
from datetime import datetime, timezone, timedelta

from src.models.audit_event import IdempotencyKey
from src.models.competition import Competition


# ── Helpers ──────────────────────────────────────────


def _login(client, email="admin@test.com", password="Admin123!") -> str:
    resp = client.post("/auth/login", json={"email": email, "password": password})
    return resp.json()["data"]["accessToken"]


def _auth(client, role="admin"):
    emails = {"admin": "admin@test.com", "operator": "operator@test.com"}
    passwords = {"admin": "Admin123!", "operator": "Op123!"}
    return {"Authorization": f"Bearer {_login(client, emails[role], passwords[role])}"}


def _seed_competition(db_session) -> int:
    comp = Competition(name="WSOP")
    db_session.add(comp)
    db_session.commit()
    db_session.refresh(comp)
    return comp.competition_id


def _series_body(competition_id: int) -> dict:
    return {
        "competitionId": competition_id,
        "seriesName": "2026 WSOP",
        "year": 2026,
        "beginAt": "2026-05-27",
        "endAt": "2026-07-17",
    }


# ── Gate 4-1: Idempotent replay ───────────────────────


def test_idempotent_replay(client, seed_users, db_session):
    """POST with Idempotency-Key → 201; same key+body again → 201 + Idempotent-Replayed."""
    comp_id = _seed_competition(db_session)
    headers = _auth(client, "admin")
    body = _series_body(comp_id)
    headers["Idempotency-Key"] = "key-replay-001"

    # First request
    resp1 = client.post("/api/v1/series", json=body, headers=headers)
    assert resp1.status_code == 201

    # Second request — same key, same body
    resp2 = client.post("/api/v1/series", json=body, headers=headers)
    assert resp2.status_code == 201
    assert resp2.headers.get("idempotent-replayed") == "true"
    # Response body should match
    assert resp2.json()["data"]["seriesName"] == "2026 WSOP"


# ── Gate 4-2: Key reused with different body → 409 ────


def test_idempotency_key_reused_different_body(client, seed_users, db_session):
    """Same Idempotency-Key + different body → 409 IDEMPOTENCY_KEY_REUSED."""
    comp_id = _seed_competition(db_session)
    headers = _auth(client, "admin")
    headers["Idempotency-Key"] = "key-conflict-001"

    body1 = _series_body(comp_id)
    resp1 = client.post("/api/v1/series", json=body1, headers=headers)
    assert resp1.status_code == 201

    # Different body with same key
    body2 = _series_body(comp_id)
    body2["seriesName"] = "Different Series"
    resp2 = client.post("/api/v1/series", json=body2, headers=headers)
    assert resp2.status_code == 409
    assert resp2.json()["error"]["code"] == "IDEMPOTENCY_KEY_REUSED"


# ── Gate 4-3: No Idempotency-Key → normal processing ──


def test_no_idempotency_key_passthrough(client, seed_users, db_session):
    """Mutation without Idempotency-Key → processed normally (no caching)."""
    comp_id = _seed_competition(db_session)
    headers = _auth(client, "admin")
    body = _series_body(comp_id)

    resp1 = client.post("/api/v1/series", json=body, headers=headers)
    assert resp1.status_code == 201

    # Second identical request (no key) creates a second series
    resp2 = client.post("/api/v1/series", json=body, headers=headers)
    assert resp2.status_code == 201
    # These should be different series (different IDs)
    assert resp1.json()["data"]["seriesId"] != resp2.json()["data"]["seriesId"]


# ── Gate 4-4: Expired key → treated as miss ────────────


def test_expired_idempotency_key(client, seed_users, db_session):
    """Expired idempotency key is ignored; request processed as new."""
    comp_id = _seed_competition(db_session)
    headers = _auth(client, "admin")
    body = _series_body(comp_id)
    headers["Idempotency-Key"] = "key-expired-001"

    # First request
    resp1 = client.post("/api/v1/series", json=body, headers=headers)
    assert resp1.status_code == 201

    # Manually expire the key in DB
    from sqlmodel import select
    row = db_session.exec(
        select(IdempotencyKey).where(IdempotencyKey.key == "key-expired-001")
    ).first()
    assert row is not None
    row.expires_at = (datetime.now(timezone.utc) - timedelta(hours=1)).isoformat()
    db_session.add(row)
    db_session.commit()

    # Same key+body → should be treated as new (expired)
    resp2 = client.post("/api/v1/series", json=body, headers=headers)
    assert resp2.status_code == 201
    # Should NOT have replayed header (it's a fresh request)
    assert resp2.headers.get("idempotent-replayed") is None


# ── Gate 4: GET passthrough (not intercepted) ─────────


def test_get_not_intercepted(client, seed_users):
    """GET requests are never intercepted by idempotency middleware."""
    headers = _auth(client, "admin")
    headers["Idempotency-Key"] = "key-get-001"
    resp = client.get("/api/v1/series", headers=headers)
    assert resp.status_code == 200
    assert resp.headers.get("idempotent-replayed") is None
