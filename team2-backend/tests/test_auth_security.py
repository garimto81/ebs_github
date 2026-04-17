"""Auth security fixes — CCR-048 Refresh TTL + live Set-Cookie.

Gaps identified by SSOT audit 2026-04-17:
- Refresh TTL 7d (604800s) vs SSOT 48h (172800s) for staging/prod/live (CCR-048)
- `delivery="cookie"` 분기에서 실제 Set-Cookie 헤더 미발행
"""
import os
from unittest.mock import patch

import pytest

from src.security.jwt import _REFRESH_TTL_MAP, get_refresh_ttl


# ── CCR-048 Refresh TTL ────────────────────────────


def test_refresh_ttl_dev_24h():
    assert _REFRESH_TTL_MAP["dev"] == 86400


def test_refresh_ttl_staging_48h():
    """CCR-048: staging refresh TTL must be 48h (172800s), not 7d."""
    assert _REFRESH_TTL_MAP["staging"] == 172800


def test_refresh_ttl_prod_48h():
    assert _REFRESH_TTL_MAP["prod"] == 172800


def test_refresh_ttl_live_48h():
    assert _REFRESH_TTL_MAP["live"] == 172800


# ── Live Set-Cookie header emission ────────────────


def _login(client, email, password):
    return client.post("/auth/login", json={"email": email, "password": password})


def test_login_live_sets_refresh_cookie_header(client, seed_users):
    """SSOT Auth_and_Session.md §2 — live profile MUST set HttpOnly cookie.

    Previous impl returned `refresh_token=""` without Set-Cookie header,
    silently dropping the refresh token in live deployments.
    """
    with patch("src.app.config.settings.auth_profile", "live"):
        resp = _login(client, "admin@test.com", "Admin123!")
    assert resp.status_code == 200
    cookies = resp.headers.get_list("set-cookie")
    cookie_str = " ".join(cookies).lower()
    assert "refresh_token=" in cookie_str, f"no refresh_token cookie: {cookies}"
    assert "httponly" in cookie_str
    assert "samesite=strict" in cookie_str
    assert "path=/auth/refresh" in cookie_str or "path=/api/v1/auth/refresh" in cookie_str


def test_login_non_live_returns_body_token(client, seed_users):
    """Dev/staging/prod: refresh_token in body (backward compat)."""
    resp = _login(client, "admin@test.com", "Admin123!")
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["refresh_token_delivery"] == "body"
    assert data["refresh_token"]  # non-empty


def test_login_live_empty_body_refresh_token(client, seed_users):
    """Live: body.refresh_token is empty (cookie-only delivery)."""
    with patch("src.app.config.settings.auth_profile", "live"):
        resp = _login(client, "admin@test.com", "Admin123!")
    data = resp.json()["data"]
    assert data["refresh_token_delivery"] == "cookie"
    assert data["refresh_token"] == ""
