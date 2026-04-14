"""Gate 2 — Series / Event / Flight E2E tests."""
import pytest

from src.models.competition import Competition


# ── Helpers ──────────────────────────────────────────


def _login(client, email="admin@test.com", password="Admin123!") -> str:
    resp = client.post("/auth/login", json={"email": email, "password": password})
    return resp.json()["data"]["access_token"]


def _auth(client, role="admin"):
    emails = {"admin": "admin@test.com", "operator": "operator@test.com", "viewer": "viewer@test.com"}
    passwords = {"admin": "Admin123!", "operator": "Op123!", "viewer": "View123!"}
    return {"Authorization": f"Bearer {_login(client, emails[role], passwords[role])}"}


def _seed_competition(db_session) -> int:
    comp = Competition(name="WSOP")
    db_session.add(comp)
    db_session.commit()
    db_session.refresh(comp)
    return comp.competition_id


def _create_series(client, headers, competition_id):
    return client.post("/api/v1/series", json={
        "competition_id": competition_id,
        "series_name": "2026 WSOP",
        "year": 2026,
        "begin_at": "2026-05-27",
        "end_at": "2026-07-17",
    }, headers=headers)


# ── Gate 2-1: POST /series (admin) → 201 ────────────


def test_create_series_admin(client, seed_users, db_session):
    comp_id = _seed_competition(db_session)
    headers = _auth(client, "admin")
    resp = _create_series(client, headers, comp_id)
    assert resp.status_code == 201
    data = resp.json()["data"]
    assert data["series_name"] == "2026 WSOP"
    assert data["year"] == 2026
    assert data["series_id"] is not None


# ── Gate 2-2: POST /series (operator) → 403 ─────────


def test_create_series_operator_forbidden(client, seed_users, db_session):
    comp_id = _seed_competition(db_session)
    headers = _auth(client, "operator")
    resp = _create_series(client, headers, comp_id)
    assert resp.status_code == 403


# ── Gate 2-3: GET /series → 200 + list ──────────────


def test_list_series(client, seed_users, db_session):
    comp_id = _seed_competition(db_session)
    headers = _auth(client, "admin")
    _create_series(client, headers, comp_id)
    resp = client.get("/api/v1/series", headers=headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert isinstance(data, list)
    assert len(data) >= 1


# ── Gate 2-4: POST /events (admin) → 201 ────────────


def test_create_event(client, seed_users, db_session):
    comp_id = _seed_competition(db_session)
    headers = _auth(client, "admin")
    sr = _create_series(client, headers, comp_id)
    series_id = sr.json()["data"]["series_id"]

    resp = client.post(f"/api/v1/series/{series_id}/events", json={
        "series_id": series_id,
        "event_no": 1,
        "event_name": "$10K NL Holdem",
        "buy_in": 10000,
        "game_type": 0,
        "bet_structure": 0,
    }, headers=headers)
    assert resp.status_code == 201
    data = resp.json()["data"]
    assert data["event_name"] == "$10K NL Holdem"
    assert data["event_id"] is not None


# ── Gate 2-5: POST /flights (admin) → 201 ───────────


def test_create_flight(client, seed_users, db_session):
    comp_id = _seed_competition(db_session)
    headers = _auth(client, "admin")
    sr = _create_series(client, headers, comp_id)
    series_id = sr.json()["data"]["series_id"]

    er = client.post(f"/api/v1/series/{series_id}/events", json={
        "series_id": series_id,
        "event_no": 1,
        "event_name": "Event 1",
    }, headers=headers)
    event_id = er.json()["data"]["event_id"]

    resp = client.post(f"/api/v1/events/{event_id}/flights", json={
        "event_id": event_id,
        "display_name": "Day 1A",
    }, headers=headers)
    assert resp.status_code == 201
    data = resp.json()["data"]
    assert data["display_name"] == "Day 1A"
    assert data["event_flight_id"] is not None


# ── Gate 2-15: DELETE /series (has children) → 409 ───


def test_delete_series_has_children(client, seed_users, db_session):
    comp_id = _seed_competition(db_session)
    headers = _auth(client, "admin")
    sr = _create_series(client, headers, comp_id)
    series_id = sr.json()["data"]["series_id"]

    # Create a child event
    client.post(f"/api/v1/series/{series_id}/events", json={
        "series_id": series_id,
        "event_no": 1,
        "event_name": "Child Event",
    }, headers=headers)

    resp = client.delete(f"/api/v1/series/{series_id}", headers=headers)
    assert resp.status_code == 409
    assert "HAS_CHILDREN" in str(resp.json())


def test_delete_series_no_children(client, seed_users, db_session):
    comp_id = _seed_competition(db_session)
    headers = _auth(client, "admin")
    sr = _create_series(client, headers, comp_id)
    series_id = sr.json()["data"]["series_id"]

    resp = client.delete(f"/api/v1/series/{series_id}", headers=headers)
    assert resp.status_code == 200
