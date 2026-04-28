"""JWT blacklist — revocation propagation.

BS-01 §강제 무효화 / §자동 잠금 정책 SSOT 와 정합:
  - Logout (DELETE /auth/session, POST /auth/logout) → access jti blacklist
  - 비밀번호 변경 / 역할 박탈 / Admin kick → 해당 user 의 모든 활성 jti blacklist
  - live 환경 (12h access TTL): Redis blacklist:jti:{jti} 캐시 (TTL=잔여 access 수명) 필수
  - dev/test/staging/prod (≤2h access TTL): in-memory dict (per-process) 충분 — 단일
    인스턴스 또는 짧은 TTL 자연 만료 의존

M1 D+1 (PR 2): in-memory backend 도입 + Redis 인터페이스 골격. 실제 Redis 연결은
M5 Quickstart_Local_Cluster.md + M8 Production_Deployment.md 시점에 settings.redis_url
활성화 + configure_redis_backend() 호출로 전환.

스레드 안전: in-memory backend 는 dict 연산이 GIL 하 atomic. asyncio FastAPI 의
single-thread event loop 에서 race 없음. multi-worker 시 per-worker 분리됨 — Phase 2
이후 Redis backend 로 cross-worker 정합 보장.
"""
from __future__ import annotations

import time
from typing import Any


class _InMemoryBlacklist:
    """Per-process dict + monotonic TTL. fakeredis 대체 (테스트용)."""

    def __init__(self) -> None:
        self._entries: dict[str, float] = {}  # jti → epoch expiry seconds

    def add(self, jti: str, ttl_seconds: int) -> None:
        if ttl_seconds <= 0:
            return  # 이미 만료된 토큰은 blacklist 불필요
        self._entries[jti] = time.time() + ttl_seconds

    def is_revoked(self, jti: str) -> bool:
        exp = self._entries.get(jti)
        if exp is None:
            return False
        if time.time() >= exp:
            # Lazy GC — TTL 만료된 항목 즉시 정리
            self._entries.pop(jti, None)
            return False
        return True

    def clear(self) -> None:
        self._entries.clear()

    def size(self) -> int:
        return len(self._entries)


class _RedisBlacklist:
    """Redis SETEX 'blacklist:jti:{jti}' — 다중 인스턴스 propagation.

    SET key value EX ttl 은 Redis atomic. EXISTS 도 단일 명령어 atomic.
    두 명령은 별도이므로 race 가능 (add 직후 is_revoked 호출 사이 정확 만료 timing) —
    실용적으로 무시 (TTL 정밀도가 초 단위, 정확 boundary 1초 race 는 user-visible 영향 없음).
    """

    def __init__(self, redis_client: Any) -> None:
        self._r = redis_client

    def add(self, jti: str, ttl_seconds: int) -> None:
        if ttl_seconds <= 0:
            return
        try:
            self._r.set(f"blacklist:jti:{jti}", "1", ex=ttl_seconds)
        except Exception:
            # Fail-open: Redis 다운 시에도 logout 자체는 성공시킴.
            # M6 Troubleshooting_Runbook §T3 "Redis 다운" 시 fallback 로직 정의.
            pass

    def is_revoked(self, jti: str) -> bool:
        try:
            return bool(self._r.exists(f"blacklist:jti:{jti}"))
        except Exception:
            # Fail-open: Redis 다운 시 검증 통과 (가용성 우선).
            # 보안 강화 모드는 fail-closed 옵션으로 M8 Production_Deployment 시점 결정.
            return False


# ── Module-level singleton ─────────────────────────────────────────
# 기본은 in-memory. settings.redis_url 활성 시 configure_redis_backend() 호출.

_backend: _InMemoryBlacklist | _RedisBlacklist = _InMemoryBlacklist()


def get_backend() -> _InMemoryBlacklist | _RedisBlacklist:
    return _backend


def configure_redis_backend(redis_client: Any) -> None:
    """Phase 2+ Redis 활성화 시 호출 (FastAPI startup event 등에서)."""
    global _backend
    _backend = _RedisBlacklist(redis_client)


def add_to_blacklist(jti: str, ttl_seconds: int) -> None:
    """Mark a token jti as revoked. Idempotent."""
    _backend.add(jti, ttl_seconds)


def is_revoked(jti: str) -> bool:
    """Return True if jti has been revoked and is still within TTL."""
    return _backend.is_revoked(jti)


def reset_for_test() -> None:
    """테스트 fixture 가 호출. 항상 fresh in-memory backend 로 reset."""
    global _backend
    _backend = _InMemoryBlacklist()
