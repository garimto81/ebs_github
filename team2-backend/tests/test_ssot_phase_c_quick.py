"""Phase C quick SSOT alignment — Table status + Skin method normalization."""
import pytest

from src.models.competition import Competition


def _login(client, role="admin"):
    emails = {"admin": "admin@test.com"}
    passwords = {"admin": "Admin123!"}
    resp = client.post("/auth/login", json={
        "email": emails[role], "password": passwords[role],
    })
    return {"Authorization": f"Bearer {resp.json()['data']['accessToken']}"}


# ── Table /status ──


def test_table_status_endpoint(client, seed_users, db_session):
    headers = _login(client, "admin")
    comp = Competition(name="WSOP")
    db_session.add(comp)
    db_session.commit()
    db_session.refresh(comp)
    sr = client.post("/api/v1/series", json={
        "competitionId": comp.competition_id, "seriesName": "S",
        "year": 2026, "beginAt": "2026-05-27", "endAt": "2026-07-17",
    }, headers=headers)
    er = client.post("/api/v1/events", json={
        "seriesId": sr.json()["data"]["seriesId"],
        "eventNo": 1, "eventName": "E",
    }, headers=headers)
    fr = client.post("/api/v1/flights", json={
        "eventId": er.json()["data"]["eventId"], "displayName": "F",
    }, headers=headers)
    tr = client.post("/api/v1/tables", json={
        "eventFlightId": fr.json()["data"]["eventFlightId"],
        "tableNo": 1, "name": "T1",
    }, headers=headers)
    tid = tr.json()["data"]["tableId"]

    resp = client.get(f"/api/v1/tables/{tid}/status", headers=headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["tableId"] == tid
    assert "status" in data
    assert "occupiedSeats" in data
    assert "maxPlayers" in data


# ── Skin PUT /skins/:id (SSOT L745) ──


def test_skin_put_canonical_path(client, seed_users):
    headers = _login(client, "admin")
    cr = client.post("/api/v1/skins", json={
        "name": "Test Skin", "description": "x",
    }, headers=headers)
    sid = cr.json()["data"]["skinId"]

    resp = client.put(f"/api/v1/skins/{sid}", json={
        "description": "updated",
    }, headers=headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["description"] == "updated"


# ── Skin POST /skins/:id/activate (SSOT L749) ──


def test_skin_activate_post_canonical(client, seed_users):
    headers = _login(client, "admin")
    cr = client.post("/api/v1/skins", json={
        "name": "Activate Skin",
    }, headers=headers)
    sid = cr.json()["data"]["skinId"]

    resp = client.post(f"/api/v1/skins/{sid}/activate", headers=headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["isDefault"] is True
