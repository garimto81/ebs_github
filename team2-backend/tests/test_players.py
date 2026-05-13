"""Gate 2 — Player E2E tests.

Cycle 21 (Players_HandHistory_API.md v1.0.0) 응답 형태 변경:
  - GET list  : ApiResponse{data, meta} → PlayerListResponse{items, next_cursor, has_more}
  - GET detail: ApiResponse{data}       → PlayerDetailResponse (직접 PlayerListItem 필드)
  - POST/PUT/DELETE: ApiResponse 유지 (관리 endpoint 는 contract 밖)
"""


# ── Helpers ──────────────────────────────────────────


def _login(client, email="admin@test.com", password="Admin123!") -> str:
    resp = client.post("/api/v1/auth/login", json={"email": email, "password": password})
    return resp.json()["data"]["accessToken"]


def _auth(client, role="admin"):
    emails = {"admin": "admin@test.com", "operator": "operator@test.com", "viewer": "viewer@test.com"}
    passwords = {"admin": "Admin123!", "operator": "Op123!", "viewer": "View123!"}
    return {"Authorization": f"Bearer {_login(client, emails[role], passwords[role])}"}


# ── Gate 2-13: POST /players → 201 ──────────────────


def test_create_player(client, seed_users):
    headers = _auth(client, "admin")
    resp = client.post("/api/v1/players", json={
        "firstName": "Phil",
        "lastName": "Ivey",
        "nationality": "USA",
        "wsopId": "WSOP-001",
    }, headers=headers)
    assert resp.status_code == 201
    data = resp.json()["data"]
    assert data["firstName"] == "Phil"
    assert data["lastName"] == "Ivey"
    assert data["playerId"] is not None


# ── Gate 2-14: GET /players?search=홍길동 → 200 ─────


def test_search_players(client, seed_users):
    headers = _auth(client, "admin")
    # Create players
    client.post("/api/v1/players", json={
        "firstName": "길동",
        "lastName": "홍",
        "nationality": "KOR",
    }, headers=headers)
    client.post("/api/v1/players", json={
        "firstName": "Daniel",
        "lastName": "Negreanu",
        "nationality": "CAN",
    }, headers=headers)

    # Search Korean name (Cycle 21 v1.0.0 — items/next_cursor/has_more)
    resp = client.get("/api/v1/players?search=홍", headers=headers)
    assert resp.status_code == 200
    body = resp.json()
    assert "items" in body and "hasMore" in body
    assert len(body["items"]) == 1
    assert body["items"][0]["lastName"] == "홍"

    # Search all
    resp = client.get("/api/v1/players", headers=headers)
    assert resp.status_code == 200
    assert len(resp.json()["items"]) == 2


def test_get_player_detail(client, seed_users):
    headers = _auth(client, "admin")
    cr = client.post("/api/v1/players", json={
        "firstName": "Phil",
        "lastName": "Hellmuth",
    }, headers=headers)
    pid = cr.json()["data"]["playerId"]

    # Cycle 21 v1.0.0: detail 응답은 PlayerDetailResponse 직접 (no ApiResponse wrap)
    resp = client.get(f"/api/v1/players/{pid}", headers=headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["firstName"] == "Phil"
    assert body["playerId"] == pid
    assert body.get("stats") is None  # include_stats=false default


def test_update_player(client, seed_users):
    headers = _auth(client, "admin")
    cr = client.post("/api/v1/players", json={
        "firstName": "Old",
        "lastName": "Name",
    }, headers=headers)
    pid = cr.json()["data"]["playerId"]

    resp = client.put(f"/api/v1/players/{pid}", json={
        "firstName": "New",
    }, headers=headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["firstName"] == "New"
    assert resp.json()["data"]["lastName"] == "Name"
