"""CCR-050 — Flight lifecycle transitions + Clock extensions.

SSOT Backend_HTTP.md L306-307, L342-344.
"""
import pytest

from src.models.competition import Competition


def _login(client, role="admin"):
    emails = {"admin": "admin@test.com", "operator": "operator@test.com"}
    passwords = {"admin": "Admin123!", "operator": "Op123!"}
    resp = client.post("/auth/login", json={
        "email": emails[role], "password": passwords[role],
    })
    return {"Authorization": f"Bearer {resp.json()['data']['accessToken']}"}


def _bootstrap_flight(client, db_session, headers, status_="running"):
    comp = Competition(name="WSOP")
    db_session.add(comp)
    db_session.commit()
    db_session.refresh(comp)
    sr = client.post("/api/v1/series", json={
        "competitionId": comp.competition_id,
        "seriesName": "S", "year": 2026,
        "beginAt": "2026-05-27", "endAt": "2026-07-17",
    }, headers=headers)
    sid = sr.json()["data"]["seriesId"]
    er = client.post("/api/v1/events", json={
        "seriesId": sid, "eventNo": 1, "eventName": "E",
    }, headers=headers)
    eid = er.json()["data"]["eventId"]
    fr = client.post("/api/v1/flights", json={
        "eventId": eid, "displayName": "F1",
    }, headers=headers)
    fid = fr.json()["data"]["eventFlightId"]
    # Transition created → running via start_clock
    if status_ == "running":
        client.post(f"/api/v1/flights/{fid}/clock/start", headers=headers)
    return fid


# ── PUT /flights/:id/complete ──


def test_complete_running_flight_transitions(client, seed_users, db_session):
    headers = _login(client, "admin")
    fid = _bootstrap_flight(client, db_session, headers, "running")
    resp = client.put(f"/api/v1/flights/{fid}/complete", json={
        "finalResults": {"totalEntries": 100, "prizePool": 50000},
    }, headers=headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["status"] == "completed"


def test_complete_created_flight_409(client, seed_users, db_session):
    headers = _login(client, "admin")
    fid = _bootstrap_flight(client, db_session, headers, "created")
    resp = client.put(f"/api/v1/flights/{fid}/complete", json={}, headers=headers)
    assert resp.status_code == 409


# ── PUT /flights/:id/cancel ──


def test_cancel_running_flight(client, seed_users, db_session):
    headers = _login(client, "admin")
    fid = _bootstrap_flight(client, db_session, headers, "running")
    resp = client.put(f"/api/v1/flights/{fid}/cancel", json={
        "reason": "venue closure",
    }, headers=headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["status"] == "canceled"


def test_cancel_completed_flight_409(client, seed_users, db_session):
    headers = _login(client, "admin")
    fid = _bootstrap_flight(client, db_session, headers, "running")
    client.put(f"/api/v1/flights/{fid}/complete", json={}, headers=headers)
    resp = client.put(f"/api/v1/flights/{fid}/cancel", json={}, headers=headers)
    assert resp.status_code == 409


# ── Clock extensions ──


def test_clock_detail_accepts_partial(client, seed_users, db_session):
    headers = _login(client, "admin")
    fid = _bootstrap_flight(client, db_session, headers, "running")
    resp = client.put(f"/api/v1/flights/{fid}/clock/detail", json={
        "theme": "final_table",
    }, headers=headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["theme"] == "final_table"


def test_clock_reload_page(client, seed_users, db_session):
    headers = _login(client, "admin")
    fid = _bootstrap_flight(client, db_session, headers, "running")
    resp = client.put(f"/api/v1/flights/{fid}/clock/reload-page", headers=headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["reload_requested"] is True


def test_clock_adjust_stack_validates_non_negative(client, seed_users, db_session):
    headers = _login(client, "admin")
    fid = _bootstrap_flight(client, db_session, headers, "running")
    resp = client.put(f"/api/v1/flights/{fid}/clock/adjust-stack", json={
        "averageStack": -100,
    }, headers=headers)
    assert resp.status_code == 400


def test_clock_adjust_stack_valid(client, seed_users, db_session):
    headers = _login(client, "admin")
    fid = _bootstrap_flight(client, db_session, headers, "running")
    resp = client.put(f"/api/v1/flights/{fid}/clock/adjust-stack", json={
        "averageStack": 45000, "reason": "re-entry closed",
    }, headers=headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["averageStack"] == 45000
