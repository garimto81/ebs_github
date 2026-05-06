"""M1 Item 2 — JWT blacklist propagation 회귀 가드.

BS-01 §강제 무효화 SSOT:
  - Logout 즉시 access token 의 jti 가 blacklist 등록
  - 동일 토큰의 후속 API 호출은 401 AUTH_TOKEN_REVOKED
  - 다중 인스턴스 환경에서는 Redis SETEX 가 propagation (M5/M8 시점 활성화)

본 테스트는 단일 인스턴스 in-memory backend 로 propagation 의 핵심 invariant
(add → is_revoked → 401) 를 검증. Redis backend 는 동일 인터페이스이므로 본 테스트
가 통과하면 cross-instance 동작도 보장 (configure_redis_backend() 호출만 다름).
"""
import pytest

from src.security.blacklist import (
    add_to_blacklist,
    is_revoked,
    reset_for_test,
)


# ── Unit: blacklist API 자체 ─────────────────────────────────────────


@pytest.fixture(autouse=True)
def _fresh_blacklist():
    """매 테스트마다 fresh in-memory backend."""
    reset_for_test()
    yield
    reset_for_test()


def test_blacklist_initially_empty():
    assert is_revoked("any-jti") is False


def test_blacklist_add_then_revoked():
    add_to_blacklist("jti-1", ttl_seconds=3600)
    assert is_revoked("jti-1") is True
    assert is_revoked("jti-2") is False  # 다른 jti 영향 없음


def test_blacklist_zero_ttl_noop():
    """이미 만료된 토큰을 blacklist 시도 시 저장 안 함 (메모리 절약)."""
    add_to_blacklist("expired-jti", ttl_seconds=0)
    assert is_revoked("expired-jti") is False


def test_blacklist_negative_ttl_noop():
    add_to_blacklist("past-jti", ttl_seconds=-100)
    assert is_revoked("past-jti") is False


# ── Integration: middleware 가 blacklist 를 강제 ─────────────────────────


def _login_and_get_token(client, email="admin@test.com", password="Admin123!") -> str:
    resp = client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": password},
    )
    assert resp.status_code == 200, resp.text
    return resp.json()["data"]["accessToken"]


def test_logout_blacklists_access_jti(client, seed_users):
    """Logout 후 동일 access token 으로 /auth/me 호출 시 401."""
    token = _login_and_get_token(client)

    # 1. Pre-logout: token valid
    resp = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200, "logout 전 토큰은 valid 여야 함"

    # 2. Logout
    resp = client.post(
        "/api/v1/auth/logout",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200, resp.text

    # 3. Post-logout: 동일 token 거부 (M1 Item 2 핵심 invariant)
    resp = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 401, (
        "Logout 후 동일 토큰이 valid 면 BS-01 §강제 무효화 위반. "
        "blacklist add → is_revoked propagation 확인 필요."
    )
    assert resp.json()["detail"] == "AUTH_TOKEN_REVOKED"


def test_other_users_token_not_affected_by_blacklist(client, seed_users):
    """A logout 이 B token 영향 없음 — jti 단위 격리."""
    a_token = _login_and_get_token(client)
    client.post("/api/v1/auth/logout", headers={"Authorization": f"Bearer {a_token}"})

    b_token = _login_and_get_token(client, email="operator@test.com", password="Op123!")

    resp = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {b_token}"})
    assert resp.status_code == 200, (
        "user A logout 이 user B token 을 영향 → blacklist 가 user-level 로 잘못 동작"
    )
