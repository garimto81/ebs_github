"""Gate 2 — Table / Seat E2E tests."""
import pytest

from src.models.competition import Competition


# ── Helpers ──────────────────────────────────────────


def _login(client, email="admin@test.com", password="Admin123!") -> str:
    resp = client.post("/api/v1/auth/login", json={"email": email, "password": password})
    return resp.json()["data"]["accessToken"]


def _auth(client, role="admin"):
    emails = {"admin": "admin@test.com", "operator": "operator@test.com", "viewer": "viewer@test.com"}
    passwords = {"admin": "Admin123!", "operator": "Op123!", "viewer": "View123!"}
    return {"Authorization": f"Bearer {_login(client, emails[role], passwords[role])}"}


def _seed_hierarchy(client, db_session, headers) -> dict:
    """Create competition → series → event → flight. Return IDs."""
    comp = Competition(name="WSOP")
    db_session.add(comp)
    db_session.commit()
    db_session.refresh(comp)

    sr = client.post("/api/v1/series", json={
        "competitionId": comp.competition_id,
        "seriesName": "2026 WSOP",
        "year": 2026,
        "beginAt": "2026-05-27",
        "endAt": "2026-07-17",
    }, headers=headers)
    series_id = sr.json()["data"]["seriesId"]

    er = client.post(f"/api/v1/series/{series_id}/events", json={
        "seriesId": series_id,
        "eventNo": 1,
        "eventName": "Main Event",
    }, headers=headers)
    event_id = er.json()["data"]["eventId"]

    fr = client.post(f"/api/v1/events/{event_id}/flights", json={
        "eventId": event_id,
        "displayName": "Day 1A",
    }, headers=headers)
    flight_id = fr.json()["data"]["eventFlightId"]

    return {"seriesId": series_id, "eventId": event_id, "flight_id": flight_id}


def _create_player(client, headers, first="John", last="Doe"):
    resp = client.post("/api/v1/players", json={
        "firstName": first,
        "lastName": last,
        "nationality": "USA",
    }, headers=headers)
    return resp.json()["data"]["playerId"]


# ── Gate 2-6: POST /tables (admin) → 201, auto 10 seats ─


def test_create_table_auto_seats(client, seed_users, db_session):
    headers = _auth(client, "admin")
    ids = _seed_hierarchy(client, db_session, headers)

    resp = client.post(f"/api/v1/flights/{ids['flight_id']}/tables", json={
        "tableNo": 1,
        "name": "Feature Table 1",
        "type": "feature",
        "maxPlayers": 9,
    }, headers=headers)
    assert resp.status_code == 201
    table_id = resp.json()["data"]["tableId"]
    assert table_id is not None

    # Verify 10 seats auto-created
    seats_resp = client.get(f"/api/v1/tables/{table_id}/seats", headers=headers)
    assert seats_resp.status_code == 200
    seats = seats_resp.json()["data"]
    assert len(seats) == 10


# ── Gate 2-7: GET /tables/:id/seats → 200 + 10 seats (empty) ─


def test_get_seats_all_empty(client, seed_users, db_session):
    headers = _auth(client, "admin")
    ids = _seed_hierarchy(client, db_session, headers)

    tr = client.post(f"/api/v1/flights/{ids['flight_id']}/tables", json={
        "tableNo": 1,
        "name": "Table 1",
    }, headers=headers)
    table_id = tr.json()["data"]["tableId"]

    resp = client.get(f"/api/v1/tables/{table_id}/seats", headers=headers)
    assert resp.status_code == 200
    seats = resp.json()["data"]
    assert len(seats) == 10
    for seat in seats:
        assert seat["status"] == "empty"
        assert seat["playerId"] is None


# ── Gate 2-8: PUT /seats/3 (assign player) → 200 + status=new ─


def test_assign_seat(client, seed_users, db_session):
    headers = _auth(client, "admin")
    ids = _seed_hierarchy(client, db_session, headers)

    tr = client.post(f"/api/v1/flights/{ids['flight_id']}/tables", json={
        "tableNo": 1, "name": "T1",
    }, headers=headers)
    table_id = tr.json()["data"]["tableId"]
    player_id = _create_player(client, headers)

    resp = client.put(f"/api/v1/tables/{table_id}/seats/3", json={
        "playerId": player_id,
    }, headers=headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["status"] == "new"
    assert data["playerId"] == player_id
    assert data["seatNo"] == 3


# ── Gate 2-9: PUT /seats/3 (already occupied) → 409 ─


def test_assign_seat_occupied(client, seed_users, db_session):
    headers = _auth(client, "admin")
    ids = _seed_hierarchy(client, db_session, headers)

    tr = client.post(f"/api/v1/flights/{ids['flight_id']}/tables", json={
        "tableNo": 1, "name": "T1",
    }, headers=headers)
    table_id = tr.json()["data"]["tableId"]
    p1 = _create_player(client, headers, "Alice", "A")
    p2 = _create_player(client, headers, "Bob", "B")

    # First assign succeeds
    client.put(f"/api/v1/tables/{table_id}/seats/3", json={"playerId": p1}, headers=headers)

    # Second assign to same seat → 409
    resp = client.put(f"/api/v1/tables/{table_id}/seats/3", json={"playerId": p2}, headers=headers)
    assert resp.status_code == 409
    assert "SEAT_OCCUPIED" in str(resp.json())


# ── Gate 2-10: SeatStatus happy path: empty→new→playing→busted→empty ─


def test_seat_status_happy_path(client, seed_users, db_session):
    headers = _auth(client, "admin")
    ids = _seed_hierarchy(client, db_session, headers)

    tr = client.post(f"/api/v1/flights/{ids['flight_id']}/tables", json={
        "tableNo": 1, "name": "T1",
    }, headers=headers)
    table_id = tr.json()["data"]["tableId"]
    player_id = _create_player(client, headers)

    # empty → new (via assign)
    resp = client.put(f"/api/v1/tables/{table_id}/seats/5", json={
        "playerId": player_id,
    }, headers=headers)
    assert resp.json()["data"]["status"] == "new"

    # new → playing
    resp = client.put(f"/api/v1/tables/{table_id}/seats/5", json={
        "status": "playing",
    }, headers=headers)
    assert resp.json()["data"]["status"] == "playing"

    # playing → busted
    resp = client.put(f"/api/v1/tables/{table_id}/seats/5", json={
        "status": "busted",
    }, headers=headers)
    assert resp.json()["data"]["status"] == "busted"

    # busted → empty
    resp = client.put(f"/api/v1/tables/{table_id}/seats/5", json={
        "status": "empty",
    }, headers=headers)
    assert resp.json()["data"]["status"] == "empty"
    assert resp.json()["data"]["playerId"] is None


# ── Gate 2-11: SeatStatus: empty→reserved→empty ─────


def test_seat_status_reserved_path(client, seed_users, db_session):
    headers = _auth(client, "admin")
    ids = _seed_hierarchy(client, db_session, headers)

    tr = client.post(f"/api/v1/flights/{ids['flight_id']}/tables", json={
        "tableNo": 1, "name": "T1",
    }, headers=headers)
    table_id = tr.json()["data"]["tableId"]

    # empty → reserved
    resp = client.put(f"/api/v1/tables/{table_id}/seats/7", json={
        "status": "reserved",
    }, headers=headers)
    assert resp.json()["data"]["status"] == "reserved"

    # reserved → empty
    resp = client.put(f"/api/v1/tables/{table_id}/seats/7", json={
        "status": "empty",
    }, headers=headers)
    assert resp.json()["data"]["status"] == "empty"


# ── Gate 2-12: Invalid transition: playing→reserved → 400 ─


def test_seat_status_invalid_transition(client, seed_users, db_session):
    headers = _auth(client, "admin")
    ids = _seed_hierarchy(client, db_session, headers)

    tr = client.post(f"/api/v1/flights/{ids['flight_id']}/tables", json={
        "tableNo": 1, "name": "T1",
    }, headers=headers)
    table_id = tr.json()["data"]["tableId"]
    player_id = _create_player(client, headers)

    # Assign → new
    client.put(f"/api/v1/tables/{table_id}/seats/2", json={"playerId": player_id}, headers=headers)
    # new → playing
    client.put(f"/api/v1/tables/{table_id}/seats/2", json={"status": "playing"}, headers=headers)

    # playing → reserved (invalid)
    resp = client.put(f"/api/v1/tables/{table_id}/seats/2", json={"status": "reserved"}, headers=headers)
    assert resp.status_code == 400
    assert "INVALID_TRANSITION" in str(resp.json())


# ── Gate 2-16: Operator table access (TODO — Phase 1 allows all) ─


def test_operator_table_access_phase1(client, seed_users, db_session):
    """Phase 1: Operator can access all tables. TODO: restrict to assigned tables."""
    admin_headers = _auth(client, "admin")
    ids = _seed_hierarchy(client, db_session, admin_headers)

    tr = client.post(f"/api/v1/flights/{ids['flight_id']}/tables", json={
        "tableNo": 1, "name": "T1",
    }, headers=admin_headers)
    table_id = tr.json()["data"]["tableId"]

    # Operator can view
    op_headers = _auth(client, "operator")
    resp = client.get(f"/api/v1/tables/{table_id}/seats", headers=op_headers)
    assert resp.status_code == 200
    # TODO: Gate 2-16 full — restrict operator to assigned tables only
