"""Session 2.6 — Routers 보강 통합 테스트 (B-Q10 cascade, 2026-04-27).

Targets routers without dedicated test files:
- users (admin RBAC)
- competitions (mixed RBAC)
- configs (admin)
- blind_structures (admin RBAC for write)
- payout_structures (admin RBAC for write)

Strict rule: production code 0 modification, tests/ only.
"""
import pytest


# ── helpers ──────────────────────────────────────


def _login_token(client, email="admin@test.com", password="Admin123!") -> str:
    """Return access token for admin (default) — pattern shared with test_auth.py."""
    resp = client.post("/auth/login", json={"email": email, "password": password})
    return resp.json()["data"]["accessToken"]


def _admin_headers(client) -> dict:
    return {"Authorization": f"Bearer {_login_token(client)}"}


# ── users router ────────────────────────────────


def test_users_list_unauthenticated_401(client, seed_users):
    """GET /api/v1/users without auth → 401."""
    resp = client.get("/api/v1/users")
    assert resp.status_code == 401


def test_users_list_admin_200(client, seed_users):
    """GET /api/v1/users with admin token → 200."""
    resp = client.get("/api/v1/users", headers=_admin_headers(client))
    assert resp.status_code == 200
    body = resp.json()
    assert "data" in body
    assert isinstance(body["data"], list)


def test_users_create_admin_201(client, seed_users):
    """POST /api/v1/users with admin → 201."""
    resp = client.post(
        "/api/v1/users",
        json={
            "email": "router-new@example.com",
            "password": "Pwd1234!",
            "displayName": "RouterNew",
            "role": "viewer",
        },
        headers=_admin_headers(client),
    )
    assert resp.status_code == 201
    body = resp.json()
    assert body["data"]["email"] == "router-new@example.com"


def test_users_create_duplicate_email_409(client, seed_users):
    """POST /api/v1/users with duplicate email → 409."""
    payload = {
        "email": "router-dup@example.com",
        "password": "Pwd1234!",
        "displayName": "Dup",
        "role": "viewer",
    }
    client.post("/api/v1/users", json=payload, headers=_admin_headers(client))
    resp = client.post("/api/v1/users", json=payload, headers=_admin_headers(client))
    assert resp.status_code == 409


def test_users_get_admin(client, seed_users):
    """GET /api/v1/users/{id} as admin → 200."""
    create = client.post(
        "/api/v1/users",
        json={
            "email": "router-get@example.com",
            "password": "Pwd1234!",
            "displayName": "Getter",
            "role": "viewer",
        },
        headers=_admin_headers(client),
    )
    user_id = create.json()["data"]["userId"]
    resp = client.get(f"/api/v1/users/{user_id}", headers=_admin_headers(client))
    assert resp.status_code == 200


def test_users_get_not_found_404(client, seed_users):
    """GET /api/v1/users/{99999} → 404."""
    resp = client.get("/api/v1/users/99999", headers=_admin_headers(client))
    assert resp.status_code == 404


def test_users_delete_soft(client, seed_users):
    """DELETE /api/v1/users/{id} → soft-delete (returns deleted: True)."""
    create = client.post(
        "/api/v1/users",
        json={
            "email": "router-del@example.com",
            "password": "Pwd1234!",
            "displayName": "DelMe",
            "role": "viewer",
        },
        headers=_admin_headers(client),
    )
    user_id = create.json()["data"]["userId"]
    resp = client.delete(f"/api/v1/users/{user_id}", headers=_admin_headers(client))
    assert resp.status_code == 200
    assert resp.json()["data"]["deleted"] is True


# ── competitions router ─────────────────────────


def test_competitions_list_unauthenticated_401(client, seed_users):
    """GET /api/v1/competitions without auth → 401."""
    resp = client.get("/api/v1/competitions")
    assert resp.status_code == 401


def test_competitions_list_authenticated_200(client, seed_users):
    """GET /api/v1/competitions with any auth → 200 (get_current_user, not admin-only)."""
    resp = client.get("/api/v1/competitions", headers=_admin_headers(client))
    assert resp.status_code == 200


def test_competitions_create_admin_201(client, seed_users):
    """POST /api/v1/competitions admin → 201."""
    resp = client.post(
        "/api/v1/competitions",
        json={"name": "RouterComp", "competitionType": 0, "competitionTag": 0},
        headers=_admin_headers(client),
    )
    assert resp.status_code == 201
    assert resp.json()["data"]["name"] == "RouterComp"


def test_competitions_get_existing(client, seed_users):
    """GET /api/v1/competitions/{id} → 200."""
    create = client.post(
        "/api/v1/competitions",
        json={"name": "GetComp"},
        headers=_admin_headers(client),
    )
    cid = create.json()["data"]["competitionId"]
    resp = client.get(
        f"/api/v1/competitions/{cid}", headers=_admin_headers(client)
    )
    assert resp.status_code == 200


def test_competitions_get_not_found_404(client, seed_users):
    """GET /api/v1/competitions/99999 → 404."""
    resp = client.get(
        "/api/v1/competitions/99999", headers=_admin_headers(client)
    )
    assert resp.status_code == 404


def test_competitions_delete_admin(client, seed_users):
    """DELETE /api/v1/competitions/{id} admin → 200."""
    create = client.post(
        "/api/v1/competitions",
        json={"name": "DelComp"},
        headers=_admin_headers(client),
    )
    cid = create.json()["data"]["competitionId"]
    resp = client.delete(
        f"/api/v1/competitions/{cid}", headers=_admin_headers(client)
    )
    assert resp.status_code == 200


# ── configs router ──────────────────────────────


def test_configs_get_section_unauthenticated_401(client, seed_users):
    """GET /api/v1/configs/{section} without auth → 401."""
    resp = client.get("/api/v1/configs/general")
    assert resp.status_code == 401


def test_configs_get_empty_section_returns_empty_list(client, seed_users):
    """GET /api/v1/configs/{empty-section} → 200 with empty data list."""
    resp = client.get(
        "/api/v1/configs/nonexistent-section",
        headers=_admin_headers(client),
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["data"] == []
    assert body["meta"]["total"] == 0


def test_configs_bulk_update_admin(client, seed_users):
    """PUT /api/v1/configs/{section} admin → 200 with results."""
    resp = client.put(
        "/api/v1/configs/general",
        json=[
            {"key": "test_key_1", "value": "v1", "scope": "global"},
            {"key": "test_key_2", "value": "v2", "scope": "global"},
        ],
        headers=_admin_headers(client),
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["meta"]["updated"] == 2
    assert len(body["data"]) == 2


# ── blind_structures router ─────────────────────


def _bs_payload(name: str = "RouterBS"):
    return {
        "name": name,
        "levels": [
            {"levelNo": 1, "smallBlind": 100, "bigBlind": 200, "durationMinutes": 20},
            {"levelNo": 2, "smallBlind": 200, "bigBlind": 400, "durationMinutes": 20},
        ],
    }


def test_blind_structures_list_authenticated(client, seed_users):
    """GET /api/v1/blind-structures with auth → 200."""
    resp = client.get(
        "/api/v1/blind-structures", headers=_admin_headers(client)
    )
    assert resp.status_code == 200


def test_blind_structures_create_admin(client, seed_users):
    """POST /api/v1/blind-structures admin → 201/200."""
    resp = client.post(
        "/api/v1/blind-structures",
        json=_bs_payload("RouterBSCreate"),
        headers=_admin_headers(client),
    )
    # Admin-protected route returns 200 or 201 depending on framework default
    assert resp.status_code in (200, 201)


def test_blind_structures_get_not_found_404(client, seed_users):
    """GET /api/v1/blind-structures/99999 → 404."""
    resp = client.get(
        "/api/v1/blind-structures/99999",
        headers=_admin_headers(client),
    )
    assert resp.status_code == 404


# ── payout_structures router ────────────────────


def _ps_payload(name: str = "RouterPS"):
    return {
        "name": name,
        "levels": [
            {"positionFrom": 1, "positionTo": 1, "payoutPct": 50.0},
            {"positionFrom": 2, "positionTo": 2, "payoutPct": 30.0},
        ],
    }


def test_payout_structures_list_authenticated(client, seed_users):
    """GET /api/v1/payout-structures with auth → 200."""
    resp = client.get(
        "/api/v1/payout-structures", headers=_admin_headers(client)
    )
    assert resp.status_code == 200


def test_payout_structures_create_admin(client, seed_users):
    """POST /api/v1/payout-structures admin → 200/201."""
    resp = client.post(
        "/api/v1/payout-structures",
        json=_ps_payload("RouterPSCreate"),
        headers=_admin_headers(client),
    )
    assert resp.status_code in (200, 201)


def test_payout_structures_get_not_found_404(client, seed_users):
    """GET /api/v1/payout-structures/99999 → 404."""
    resp = client.get(
        "/api/v1/payout-structures/99999",
        headers=_admin_headers(client),
    )
    assert resp.status_code == 404
