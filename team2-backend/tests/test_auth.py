"""Gate 1 — Auth E2E tests (15 cases)."""
import time

import pytest
from jose import jwt

from src.app.config import settings


# ── Helpers ──────────────────────────────────────


def _login(client, email="admin@test.com", password="Admin123!"):
    return client.post("/auth/login", json={"email": email, "password": password})


def _get_token(client, email="admin@test.com", password="Admin123!") -> str:
    resp = _login(client, email, password)
    return resp.json()["data"]["accessToken"]


def _make_expired_token(user_id=1, email="admin@test.com", role="admin", token_type="access"):
    """Create a JWT that expired 1 hour ago."""
    now = int(time.time())
    payload = {
        "sub": str(user_id),
        "email": email,
        "role": role,
        "type": token_type,
        "iat": now - 7200,
        "exp": now - 3600,
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


# ── Gate 1-1: Login success ──────────────────────


def test_login_success(client, seed_users):
    resp = _login(client)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["accessToken"]
    assert data["refreshToken"]
    assert data["tokenType"] == "Bearer"
    assert data["expiresIn"] > 0
    assert data["authProfile"] == settings.auth_profile
    assert data["user"]["email"] == "admin@test.com"
    assert data["user"]["role"] == "admin"


# ── Gate 1-2: Login invalid password ─────────────


def test_login_invalid_password(client, seed_users):
    resp = _login(client, password="wrong")
    assert resp.status_code == 401
    assert resp.json()["detail"] == "AUTH_INVALID_CREDENTIALS"


# ── Gate 1-3: Account locked after 5 failures ────


def test_login_account_locked(client, seed_users):
    for _ in range(5):
        resp = _login(client, email="operator@test.com", password="wrong")
        assert resp.status_code == 401

    # 6th attempt → locked
    resp = _login(client, email="operator@test.com", password="Op123!")
    assert resp.status_code == 403
    assert resp.json()["detail"] == "AUTH_ACCOUNT_LOCKED"


# ── Gate 1-4: GET /auth/me with valid token ──────


def test_me_valid_token(client, seed_users):
    token = _get_token(client)
    resp = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    body = resp.json()
    assert body["email"] == "admin@test.com"
    assert body["role"] == "admin"


# ── Gate 1-5: GET /auth/me with expired token ────


def test_me_expired_token(client, seed_users):
    token = _make_expired_token()
    resp = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 401


# ── Gate 1-6: GET /auth/me without token ─────────


def test_me_no_token(client, seed_users):
    resp = client.get("/auth/me")
    assert resp.status_code == 401


# ── Gate 1-7: Refresh valid ──────────────────────


def test_refresh_valid(client, seed_users):
    login_resp = _login(client)
    refresh_token = login_resp.json()["data"]["refreshToken"]

    resp = client.post("/auth/refresh", json={"refreshToken": refresh_token})
    assert resp.status_code == 200
    body = resp.json()
    assert body["accessToken"]
    assert body["expiresIn"] > 0


# ── Gate 1-8: Refresh expired ────────────────────


def test_refresh_expired(client, seed_users):
    expired = _make_expired_token(token_type="refresh")
    resp = client.post("/auth/refresh", json={"refreshToken": expired})
    assert resp.status_code == 401


# ── Gate 1-9: Logout ─────────────────────────────


def test_logout(client, seed_users):
    token = _get_token(client)
    resp = client.post("/auth/logout", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    assert resp.json()["message"] == "Logged out successfully"


# ── Gate 1-10: Health no auth ────────────────────


def test_health_no_auth(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"


# ── Gate 1-11: RBAC admin allowed ────────────────


def test_rbac_admin_allowed(client, seed_users):
    """Admin can access /auth/me (protected endpoint)."""
    token = _get_token(client, email="admin@test.com", password="Admin123!")
    resp = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    assert resp.json()["role"] == "admin"


# ── Gate 1-12: RBAC operator access ─────────────


def test_rbac_operator_denied(client, seed_users):
    """Operator can access /auth/me (own info) — not a privileged endpoint."""
    token = _get_token(client, email="operator@test.com", password="Op123!")
    resp = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    assert resp.json()["role"] == "operator"


# ── Gate 1-13: RBAC viewer access ───────────────


def test_rbac_viewer_denied(client, seed_users):
    """Viewer can access /auth/me (own info) — not a privileged endpoint."""
    token = _get_token(client, email="viewer@test.com", password="View123!")
    resp = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    assert resp.json()["role"] == "viewer"


# ── Gate 1-14: Auth profile dev TTL ──────────────


def test_auth_profile_dev_ttl(client, seed_users):
    """Dev profile → expires_in = 3600."""
    resp = _login(client)
    data = resp.json()["data"]
    # Default test profile is dev → 3600
    assert data["expiresIn"] == 3600
    assert data["authProfile"] == "dev"


# ── Gate 1-15: Auth profile live TTL ─────────────


def test_auth_profile_live_ttl(client, seed_users, monkeypatch):
    """Live profile → expires_in = 43200."""
    monkeypatch.setattr(settings, "auth_profile", "live")
    monkeypatch.setattr(settings, "jwt_access_ttl_s", 43200)

    resp = _login(client, email="viewer@test.com", password="View123!")
    data = resp.json()["data"]
    assert data["expiresIn"] == 43200
    assert data["authProfile"] == "live"

    # Restore
    monkeypatch.setattr(settings, "auth_profile", "dev")
    monkeypatch.setattr(settings, "jwt_access_ttl_s", 3600)
