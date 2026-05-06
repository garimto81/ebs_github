"""Gate 5-1 ~ 5-5: WSOP LIVE sync + mock seed + CB integration."""
import pytest
from sqlmodel import Session

from src.models.competition import Competition, Series, Event, EventFlight
from src.models.table import Player


# ── Helpers ──────────────────────────────────────────


def _login(client, email="admin@test.com", password="Admin123!") -> str:
    resp = client.post("/api/v1/auth/login", json={"email": email, "password": password})
    return resp.json()["data"]["accessToken"]


def _auth(client, role="admin"):
    emails = {"admin": "admin@test.com", "operator": "operator@test.com", "viewer": "viewer@test.com"}
    passwords = {"admin": "Admin123!", "operator": "Op123!", "viewer": "View123!"}
    return {"Authorization": f"Bearer {_login(client, emails[role], passwords[role])}"}


# ── Gate 5-1: POST /sync/mock/seed → 200 + correct counts ──


def test_seed_mock_data(client, seed_users, db_session):
    """Seed creates README-aligned data: 2 Comp, 2 Series, 3 Events, 4 Flights, 9 Players, 3 Tables, etc."""
    headers = _auth(client, "admin")
    resp = client.post("/api/v1/sync/mock/seed", headers=headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["competitions"] == 2
    assert data["series"] == 2
    assert data["events"] == 3
    assert data["flights"] == 4
    assert data["players"] == 9
    assert data["tables"] == 3
    assert data["seats"] == 26
    assert data["blind_structures"] == 1
    assert data["blind_structure_levels"] == 14
    assert data["decks"] == 2
    assert data["deck_cards"] == 104
    assert data["configs"] == 10
    assert data["skins"] == 3
    assert data["output_presets"] == 4


# ── Gate 5-2: GET /sync/status → 200 + source info ──


def test_sync_status(client, seed_users, db_session):
    """Sync status returns source information."""
    headers = _auth(client, "admin")
    resp = client.get("/api/v1/sync/status", headers=headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert "sources" in data
    assert "wsop_live" in data["sources"]


# ── Gate 5-3: WSOP mock polling (CB-wrapped) → UPSERT success ──


def test_trigger_sync_creates_series(client, seed_users, db_session):
    """Trigger sync via POST /sync/trigger/wsop_live creates series via UPSERT."""
    headers = _auth(client, "admin")

    # Need a competition first for UPSERT to insert into
    comp = Competition(name="WSOP", competition_type=0)
    db_session.add(comp)
    db_session.commit()

    resp = client.post("/api/v1/sync/trigger/wsop_live", headers=headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["source"] == "wsop_live"
    assert data["created"] == 3  # 3 mock series


def test_trigger_sync_upsert_updates_existing(client, seed_users, db_session):
    """Second sync run updates existing series (not duplicates)."""
    headers = _auth(client, "admin")

    comp = Competition(name="WSOP", competition_type=0)
    db_session.add(comp)
    db_session.commit()

    # First sync — creates
    client.post("/api/v1/sync/trigger/wsop_live", headers=headers)

    # Second sync — updates
    resp = client.post("/api/v1/sync/trigger/wsop_live", headers=headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["updated"] == 3
    assert data["created"] == 0


# ── Gate 5-4: Polling failure triggers CB OPEN ──


@pytest.mark.asyncio
async def test_cb_trips_open_on_repeated_failures(client, seed_users, db_session):
    """CB opens after enough failures in the window."""
    from src.observability.circuit_breaker import CircuitBreaker, CircuitOpenError

    cb = CircuitBreaker(failure_ratio=0.5, window_size=4, open_duration_s=0.3)

    async def _fail():
        raise RuntimeError("WSOP API unreachable")

    # Fill window with failures
    for _ in range(4):
        try:
            await cb.call(_fail)
        except (RuntimeError, CircuitOpenError):
            pass

    assert cb.state == "OPEN"

    # Calls during OPEN are rejected
    with pytest.raises(CircuitOpenError):
        await cb.call(_fail)


# ── Gate 5-5: CB CLOSED recovery ──


@pytest.mark.asyncio
async def test_cb_recovers_to_closed():
    """After timeout, CB transitions OPEN → HALF_OPEN → CLOSED on success."""
    import asyncio
    import time
    from src.observability.circuit_breaker import CircuitBreaker, CircuitOpenError

    cb = CircuitBreaker(failure_ratio=0.5, window_size=4, open_duration_s=0.2)

    async def _fail():
        raise RuntimeError("fail")

    async def _success():
        return "ok"

    # Trip open by filling window + setting state directly
    for _ in range(cb.window_size):
        cb._record_failure()
    cb.state = "OPEN"
    cb._opened_at = time.monotonic()

    assert cb.state == "OPEN"

    # Wait for open duration
    await asyncio.sleep(0.25)

    # Success call should recover
    result = await cb.call(_success)
    assert result == "ok"
    assert cb.state == "CLOSED"


# ── Additional: seed requires admin role ──


def test_seed_mock_requires_admin(client, seed_users, db_session):
    """Non-admin cannot seed mock data."""
    headers = _auth(client, "viewer")
    resp = client.post("/api/v1/sync/mock/seed", headers=headers)
    assert resp.status_code == 403


# ── Additional: reset mock data ──


def test_reset_mock_data(client, seed_users, db_session):
    """Reset cleans up seeded data."""
    headers = _auth(client, "admin")
    client.post("/api/v1/sync/mock/seed", headers=headers)
    resp = client.delete("/api/v1/sync/mock/reset", headers=headers)
    assert resp.status_code == 200
    assert "deleted" in resp.json()["data"]


# ── Additional: unknown source → 400 ──


def test_trigger_unknown_source(client, seed_users, db_session):
    """Unknown sync source returns 400."""
    headers = _auth(client, "admin")
    resp = client.post("/api/v1/sync/trigger/unknown", headers=headers)
    assert resp.status_code == 400
