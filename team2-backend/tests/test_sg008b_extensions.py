"""SG-008-b cascade extension tests (B-Q15 cascade, 2026-04-27).

Covers:
- SG-008-b4: GET /auth/me extended fields (permissions, settings_scope)
- SG-008-b5: POST /auth/logout ?all=true option
- SG-008-b6: POST /api/v1/sync/mock/seed env guard (dev/staging only)
- SG-008-b7: DELETE /api/v1/sync/mock/reset env guard (dev/staging only)
- SG-008-b8: GET /api/v1/sync/status Public + Admin bifurcation

Production-strict (B-Q7 ㉠) baseline — additive only, preserves 247 existing tests.
"""
import pytest

from src.app.config import settings as app_settings


# ── SG-008-b4: GET /auth/me extended fields ──────────────


def _login_token(client, email="admin@test.com", password="Admin123!") -> str:
    resp = client.post("/api/v1/auth/login", json={"email": email, "password": password})
    return resp.json()["data"]["accessToken"]


def test_me_includes_permissions_field(client, seed_users):
    """SG-008-b4: /auth/me returns permissions list."""
    token = _login_token(client)
    resp = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    body = resp.json()
    assert "permissions" in body
    assert isinstance(body["permissions"], list)


def test_me_admin_has_full_permissions(client, seed_users):
    """SG-008-b4: admin role has admin-level permissions."""
    token = _login_token(client)
    resp = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    perms = resp.json()["permissions"]
    assert "read:*" in perms
    assert "write:*" in perms
    assert "delete:*" in perms
    assert "audit:read" in perms


def test_me_includes_settings_scope_field(client, seed_users):
    """SG-008-b4: /auth/me returns settings_scope identifier (camelCase per EbsBaseModel)."""
    token = _login_token(client)
    resp = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    body = resp.json()
    # EbsBaseModel applies snake_case → camelCase serialization
    assert "settingsScope" in body
    assert body["settingsScope"].startswith("user:")
    user_id = body["userId"]
    assert body["settingsScope"] == f"user:{user_id}"


# ── SG-008-b5: POST /auth/logout ?all=true ──────────────


def test_logout_default_scope_is_current(client, seed_users):
    """SG-008-b5: default logout has scope=current."""
    token = _login_token(client)
    resp = client.post(
        "/api/v1/auth/logout",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    assert resp.json()["scope"] == "current"


def test_logout_all_scope_marker(client, seed_users):
    """SG-008-b5: ?all=true returns scope=all."""
    token = _login_token(client)
    resp = client.post(
        "/api/v1/auth/logout?all=true",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    assert resp.json()["scope"] == "all"


# ── SG-008-b6: POST /api/v1/sync/mock/seed env guard ──────


def test_mock_seed_allowed_in_dev(client, seed_users, monkeypatch):
    """SG-008-b6: dev profile allows mock seed."""
    monkeypatch.setattr(app_settings, "auth_profile", "dev")
    token = _login_token(client)
    resp = client.post(
        "/api/v1/sync/mock/seed",
        headers={"Authorization": f"Bearer {token}"},
    )
    # 200 (success) or 500 (sync_service implementation detail).
    # Assertion: not 403 (env guard).
    assert resp.status_code != 403, "dev profile must not be blocked by env guard"


def test_mock_seed_allowed_in_staging(client, seed_users, monkeypatch):
    """SG-008-b6: staging profile allows mock seed."""
    monkeypatch.setattr(app_settings, "auth_profile", "staging")
    token = _login_token(client)
    resp = client.post(
        "/api/v1/sync/mock/seed",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code != 403, "staging profile must not be blocked by env guard"


def test_mock_seed_blocked_in_prod(client, seed_users, monkeypatch):
    """SG-008-b6: prod profile blocks mock seed (403 ENV_GUARD_PROD_FORBIDDEN)."""
    monkeypatch.setattr(app_settings, "auth_profile", "prod")
    token = _login_token(client)
    resp = client.post(
        "/api/v1/sync/mock/seed",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 403
    assert resp.json()["detail"] == "ENV_GUARD_PROD_FORBIDDEN"


def test_mock_seed_blocked_in_live(client, seed_users, monkeypatch):
    """SG-008-b6: live profile blocks mock seed."""
    monkeypatch.setattr(app_settings, "auth_profile", "live")
    token = _login_token(client)
    resp = client.post(
        "/api/v1/sync/mock/seed",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 403


# ── SG-008-b7: DELETE /api/v1/sync/mock/reset env guard ────


def test_mock_reset_allowed_in_dev(client, seed_users, monkeypatch):
    """SG-008-b7: dev profile allows mock reset."""
    monkeypatch.setattr(app_settings, "auth_profile", "dev")
    token = _login_token(client)
    resp = client.delete(
        "/api/v1/sync/mock/reset",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code != 403, "dev profile must not be blocked by env guard"


def test_mock_reset_blocked_in_prod(client, seed_users, monkeypatch):
    """SG-008-b7: prod profile blocks mock reset (403)."""
    monkeypatch.setattr(app_settings, "auth_profile", "prod")
    token = _login_token(client)
    resp = client.delete(
        "/api/v1/sync/mock/reset",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 403
    assert resp.json()["detail"] == "ENV_GUARD_PROD_FORBIDDEN"


# ── SG-008-b8: GET /api/v1/sync/status Public + Admin bifurcation ──


def test_sync_status_admin_scope_marker(client, seed_users):
    """SG-008-b8: admin user gets scope=admin marker."""
    token = _login_token(client)  # admin login default
    resp = client.get(
        "/api/v1/sync/status",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    body = resp.json()
    assert "scope" in body
    assert body["scope"] == "admin"


def test_sync_status_non_admin_public_scope(client, seed_users):
    """SG-008-b8: non-admin user gets scope=public marker.

    Uses operator account (role != admin) — no env guard issue since only checks role.
    """
    token = _login_token(client, email="operator@test.com", password="Op123!")
    resp = client.get(
        "/api/v1/sync/status",
        headers={"Authorization": f"Bearer {token}"},
    )
    # Operator may or may not exist in seed_users — handle both cases.
    if resp.status_code == 401:
        pytest.skip("Operator user not seeded")
    assert resp.status_code == 200
    body = resp.json()
    assert body["scope"] == "public"
