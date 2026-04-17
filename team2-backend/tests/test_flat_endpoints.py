"""SSOT flat REST endpoints (Backend_HTTP.md L261/263/302/304/402/404).

Backend initially shipped only nested variants (`/flights/{id}/tables`, etc).
SSOT explicitly specifies flat REST with query filters. These tests verify the
flat variants exist and behave consistently with the nested counterparts.
"""
import pytest

from src.models.competition import Competition


def _login(client, email, password):
    resp = client.post("/auth/login", json={"email": email, "password": password})
    return resp.json()["data"]["access_token"]


def _auth(client, role="admin"):
    emails = {"admin": "admin@test.com", "operator": "operator@test.com", "viewer": "viewer@test.com"}
    passwords = {"admin": "Admin123!", "operator": "Op123!", "viewer": "View123!"}
    return {"Authorization": f"Bearer {_login(client, emails[role], passwords[role])}"}


def _bootstrap(client, db_session, headers):
    """Competition → Series → Event → Flight. Returns ids dict."""
    comp = Competition(name="WSOP")
    db_session.add(comp)
    db_session.commit()
    db_session.refresh(comp)
    sr = client.post("/api/v1/series", json={
        "competition_id": comp.competition_id,
        "series_name": "2026 WSOP",
        "year": 2026,
        "begin_at": "2026-05-27",
        "end_at": "2026-07-17",
    }, headers=headers)
    series_id = sr.json()["data"]["series_id"]
    return {"series_id": series_id}


# ── POST /events (flat) — SSOT L263 ────────────────────────────


def test_flat_post_events_creates_under_series_in_body(client, seed_users, db_session):
    headers = _auth(client, "admin")
    ids = _bootstrap(client, db_session, headers)

    resp = client.post("/api/v1/events", json={
        "series_id": ids["series_id"],
        "event_no": 42,
        "event_name": "Flat POST Event",
    }, headers=headers)
    assert resp.status_code == 201, resp.text
    body = resp.json()["data"]
    assert body["series_id"] == ids["series_id"]
    assert body["event_no"] == 42


# ── GET /flights?event_id= — SSOT L302 ─────────────────────────


def test_flat_get_flights_filtered_by_event_id(client, seed_users, db_session):
    headers = _auth(client, "admin")
    ids = _bootstrap(client, db_session, headers)
    er = client.post("/api/v1/events", json={
        "series_id": ids["series_id"], "event_no": 1, "event_name": "E1",
    }, headers=headers)
    event_id = er.json()["data"]["event_id"]
    client.post(f"/api/v1/events/{event_id}/flights", json={
        "event_id": event_id, "display_name": "Day 1A",
    }, headers=headers)
    client.post(f"/api/v1/events/{event_id}/flights", json={
        "event_id": event_id, "display_name": "Day 1B",
    }, headers=headers)

    resp = client.get(f"/api/v1/flights?event_id={event_id}", headers=headers)
    assert resp.status_code == 200, resp.text
    data = resp.json()["data"]
    assert len(data) == 2
    for f in data:
        assert f["event_id"] == event_id


# ── POST /flights (flat) — SSOT L304 ───────────────────────────


def test_flat_post_flights_uses_body_event_id(client, seed_users, db_session):
    headers = _auth(client, "admin")
    ids = _bootstrap(client, db_session, headers)
    er = client.post("/api/v1/events", json={
        "series_id": ids["series_id"], "event_no": 1, "event_name": "E1",
    }, headers=headers)
    event_id = er.json()["data"]["event_id"]

    resp = client.post("/api/v1/flights", json={
        "event_id": event_id, "display_name": "Flat Flight",
    }, headers=headers)
    assert resp.status_code == 201, resp.text
    assert resp.json()["data"]["event_id"] == event_id


# ── GET /tables?flight_id= — SSOT L402 (reported 404) ──────────


def test_flat_get_tables_filtered_by_flight_id(client, seed_users, db_session):
    """The endpoint that returned 404 to the frontend."""
    headers = _auth(client, "admin")
    ids = _bootstrap(client, db_session, headers)
    er = client.post("/api/v1/events", json={
        "series_id": ids["series_id"], "event_no": 1, "event_name": "E1",
    }, headers=headers)
    event_id = er.json()["data"]["event_id"]
    fr = client.post("/api/v1/flights", json={
        "event_id": event_id, "display_name": "Day 1A",
    }, headers=headers)
    flight_id = fr.json()["data"]["event_flight_id"]
    client.post(f"/api/v1/flights/{flight_id}/tables", json={
        "table_no": 1, "name": "T1",
    }, headers=headers)
    client.post(f"/api/v1/flights/{flight_id}/tables", json={
        "table_no": 2, "name": "T2",
    }, headers=headers)

    resp = client.get(f"/api/v1/tables?flight_id={flight_id}", headers=headers)
    assert resp.status_code == 200, resp.text
    data = resp.json()["data"]
    assert len(data) == 2
    for t in data:
        assert t["event_flight_id"] == flight_id


def test_flat_get_tables_without_flight_id_returns_all(client, seed_users, db_session):
    """SSOT: `?flight_id=` is an optional filter. Omit returns all tables."""
    headers = _auth(client, "admin")
    resp = client.get("/api/v1/tables", headers=headers)
    assert resp.status_code == 200, resp.text
    assert isinstance(resp.json()["data"], list)


# ── POST /tables (flat) — SSOT L404 ────────────────────────────


def test_flat_post_tables_uses_body_flight_id(client, seed_users, db_session):
    headers = _auth(client, "admin")
    ids = _bootstrap(client, db_session, headers)
    er = client.post("/api/v1/events", json={
        "series_id": ids["series_id"], "event_no": 1, "event_name": "E1",
    }, headers=headers)
    event_id = er.json()["data"]["event_id"]
    fr = client.post("/api/v1/flights", json={
        "event_id": event_id, "display_name": "Day 1A",
    }, headers=headers)
    flight_id = fr.json()["data"]["event_flight_id"]

    resp = client.post("/api/v1/tables", json={
        "event_flight_id": flight_id,
        "table_no": 7,
        "name": "Flat Table",
    }, headers=headers)
    assert resp.status_code == 201, resp.text
    data = resp.json()["data"]
    assert data["event_flight_id"] == flight_id
    assert data["table_no"] == 7


# ── Nested endpoints still work (back-compat) ──────────────────


def test_nested_endpoints_still_work_for_backcompat(client, seed_users, db_session):
    headers = _auth(client, "admin")
    ids = _bootstrap(client, db_session, headers)
    er = client.post(f"/api/v1/series/{ids['series_id']}/events", json={
        "series_id": ids["series_id"], "event_no": 99, "event_name": "Nested",
    }, headers=headers)
    assert er.status_code == 201
    event_id = er.json()["data"]["event_id"]
    fr = client.post(f"/api/v1/events/{event_id}/flights", json={
        "event_id": event_id, "display_name": "Nested Day",
    }, headers=headers)
    assert fr.status_code == 201
    flight_id = fr.json()["data"]["event_flight_id"]
    tr = client.post(f"/api/v1/flights/{flight_id}/tables", json={
        "table_no": 1, "name": "Nested T1",
    }, headers=headers)
    assert tr.status_code == 201
