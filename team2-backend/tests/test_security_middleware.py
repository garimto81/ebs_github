"""Tests for src/middleware/security.py (G-C3)."""
from __future__ import annotations

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.middleware.security import (
    CSRFMiddleware,
    RateLimitMiddleware,
    SecurityHeadersMiddleware,
    _SlidingWindow,
)


@pytest.fixture()
def tiny_app():
    app = FastAPI()

    @app.get("/health")
    def health():
        return {"ok": True}

    @app.get("/api/v1/tables")
    def tables():
        return {"data": []}

    @app.post("/auth/login")
    def login():
        return {"accessToken": "t"}

    @app.post("/api/v1/tables")
    def create_table():
        return {"data": {"id": 1}}

    return app


class TestSecurityHeaders:
    def test_default_headers_set(self, tiny_app):
        tiny_app.add_middleware(SecurityHeadersMiddleware)
        client = TestClient(tiny_app)
        resp = client.get("/health")
        assert resp.headers["X-Content-Type-Options"] == "nosniff"
        assert resp.headers["X-Frame-Options"] == "DENY"
        assert "Referrer-Policy" in resp.headers

    def test_hsts_when_force_https(self, tiny_app):
        tiny_app.add_middleware(SecurityHeadersMiddleware, enable_hsts=True)
        client = TestClient(tiny_app)
        resp = client.get("/health")
        assert "Strict-Transport-Security" in resp.headers

    def test_csp_from_policy(self, tiny_app):
        tiny_app.add_middleware(
            SecurityHeadersMiddleware,
            csp_policy="default-src 'self'",
        )
        client = TestClient(tiny_app)
        resp = client.get("/health")
        assert resp.headers["Content-Security-Policy"] == "default-src 'self'"


class TestRateLimit:
    def test_health_exempt(self, tiny_app):
        tiny_app.add_middleware(RateLimitMiddleware)
        client = TestClient(tiny_app)
        for _ in range(50):
            resp = client.get("/health")
            assert resp.status_code == 200

    def test_auth_login_rate_limit_10_per_min(self, tiny_app):
        window = _SlidingWindow()
        tiny_app.add_middleware(RateLimitMiddleware, window=window)
        client = TestClient(tiny_app)
        allowed = 0
        blocked = 0
        for _ in range(15):
            resp = client.post("/auth/login")
            if resp.status_code == 200:
                allowed += 1
            elif resp.status_code == 429:
                blocked += 1
                assert resp.headers["Retry-After"]
                assert resp.headers["X-RateLimit-Limit"] == "10"
                assert resp.headers["X-RateLimit-Remaining"] == "0"
        assert allowed == 10
        assert blocked == 5

    def test_rate_limit_headers_on_success(self, tiny_app):
        window = _SlidingWindow()
        tiny_app.add_middleware(RateLimitMiddleware, window=window)
        client = TestClient(tiny_app)
        resp = client.get("/api/v1/tables")
        assert resp.status_code == 200
        assert resp.headers["X-RateLimit-Limit"] == "100"
        assert int(resp.headers["X-RateLimit-Remaining"]) == 99


class TestCSRF:
    def test_no_cookie_path_bypassed(self, tiny_app):
        """Bearer 토큰 경로 (쿠키 없음) 는 CSRF 검증 skip."""
        tiny_app.add_middleware(CSRFMiddleware)
        client = TestClient(tiny_app)
        resp = client.post("/api/v1/tables")
        assert resp.status_code == 200

    def test_cookie_without_csrf_header_rejected(self, tiny_app):
        tiny_app.add_middleware(CSRFMiddleware)
        client = TestClient(tiny_app)
        resp = client.post(
            "/api/v1/tables",
            cookies={"ebs_refresh": "r", "ebs_csrf": "abc"},
        )
        assert resp.status_code == 401
        assert resp.json()["error"]["code"] == "CSRF_TOKEN_MISMATCH"

    def test_csrf_mismatch_rejected(self, tiny_app):
        tiny_app.add_middleware(CSRFMiddleware)
        client = TestClient(tiny_app)
        resp = client.post(
            "/api/v1/tables",
            cookies={"ebs_refresh": "r", "ebs_csrf": "abc"},
            headers={"X-CSRF-Token": "xyz"},
        )
        assert resp.status_code == 401

    def test_csrf_match_allowed(self, tiny_app):
        tiny_app.add_middleware(CSRFMiddleware)
        client = TestClient(tiny_app)
        resp = client.post(
            "/api/v1/tables",
            cookies={"ebs_refresh": "r", "ebs_csrf": "abc"},
            headers={"X-CSRF-Token": "abc"},
        )
        assert resp.status_code == 200

    def test_get_method_bypassed(self, tiny_app):
        tiny_app.add_middleware(CSRFMiddleware)
        client = TestClient(tiny_app)
        resp = client.get(
            "/api/v1/tables",
            cookies={"ebs_refresh": "r", "ebs_csrf": "abc"},
        )
        assert resp.status_code == 200
