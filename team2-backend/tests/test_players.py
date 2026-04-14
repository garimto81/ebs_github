"""Gate 2 — Player E2E tests."""
import pytest


# ── Helpers ──────────────────────────────────────────


def _login(client, email="admin@test.com", password="Admin123!") -> str:
    resp = client.post("/auth/login", json={"email": email, "password": password})
    return resp.json()["data"]["access_token"]


def _auth(client, role="admin"):
    emails = {"admin": "admin@test.com", "operator": "operator@test.com", "viewer": "viewer@test.com"}
    passwords = {"admin": "Admin123!", "operator": "Op123!", "viewer": "View123!"}
    return {"Authorization": f"Bearer {_login(client, emails[role], passwords[role])}"}


# ── Gate 2-13: POST /players → 201 ──────────────────


def test_create_player(client, seed_users):
    headers = _auth(client, "admin")
    resp = client.post("/api/v1/players", json={
        "first_name": "Phil",
        "last_name": "Ivey",
        "nationality": "USA",
        "wsop_id": "WSOP-001",
    }, headers=headers)
    assert resp.status_code == 201
    data = resp.json()["data"]
    assert data["first_name"] == "Phil"
    assert data["last_name"] == "Ivey"
    assert data["player_id"] is not None


# ── Gate 2-14: GET /players?search=홍길동 → 200 ─────


def test_search_players(client, seed_users):
    headers = _auth(client, "admin")
    # Create players
    client.post("/api/v1/players", json={
        "first_name": "길동",
        "last_name": "홍",
        "nationality": "KOR",
    }, headers=headers)
    client.post("/api/v1/players", json={
        "first_name": "Daniel",
        "last_name": "Negreanu",
        "nationality": "CAN",
    }, headers=headers)

    # Search Korean name
    resp = client.get("/api/v1/players?search=홍", headers=headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert len(data) == 1
    assert data[0]["last_name"] == "홍"

    # Search all
    resp = client.get("/api/v1/players", headers=headers)
    assert resp.status_code == 200
    assert len(resp.json()["data"]) == 2


def test_get_player_detail(client, seed_users):
    headers = _auth(client, "admin")
    cr = client.post("/api/v1/players", json={
        "first_name": "Phil",
        "last_name": "Hellmuth",
    }, headers=headers)
    pid = cr.json()["data"]["player_id"]

    resp = client.get(f"/api/v1/players/{pid}", headers=headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["first_name"] == "Phil"


def test_update_player(client, seed_users):
    headers = _auth(client, "admin")
    cr = client.post("/api/v1/players", json={
        "first_name": "Old",
        "last_name": "Name",
    }, headers=headers)
    pid = cr.json()["data"]["player_id"]

    resp = client.put(f"/api/v1/players/{pid}", json={
        "first_name": "New",
    }, headers=headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["first_name"] == "New"
    assert resp.json()["data"]["last_name"] == "Name"
