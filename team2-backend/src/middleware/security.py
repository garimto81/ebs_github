"""Security middleware — G-C3 (2026-04-15).

NFR.md §9.4 SSOT 기반 구현:
- Security headers (HSTS/X-Frame-Options/X-Content-Type-Options/Referrer-Policy/CSP)
- Rate limiting (in-memory sliding window, Phase 1)
- CSRF double-submit token (HttpOnly cookie refresh 경로)

Phase 2+ Redis 공유 rate limit + 분산 환경 CSRF store 로 확장.
"""
from __future__ import annotations

import os
import time
from collections import defaultdict, deque
from threading import Lock
from typing import Callable, Mapping

from fastapi import Request
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp

__all__ = [
    "SecurityHeadersMiddleware",
    "RateLimitMiddleware",
    "CSRFMiddleware",
    "RATE_LIMIT_CATEGORIES",
]

# ──────────────────────────────────────────────────────────────────
# Rate limit categories (NFR.md §9.4)
# ──────────────────────────────────────────────────────────────────

RATE_LIMIT_CATEGORIES: dict[str, tuple[int, int]] = {
    # path_prefix → (max_requests, window_seconds)
    "/auth/login": (10, 60),
    "/auth/refresh": (10, 60),
    "/auth/password-reset": (10, 60),
    "/api/v1/sync": (5, 60),
    "/api/": (100, 60),       # 일반 API (가장 넓은 매칭, 마지막 체크)
    "_public_": (30, 60),     # 매칭 없음 기본값 (public)
}

# ──────────────────────────────────────────────────────────────────
# Security Headers
# ──────────────────────────────────────────────────────────────────

DEFAULT_SECURITY_HEADERS: Mapping[str, str] = {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Referrer-Policy": "strict-origin-when-cross-origin",
}


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """정적 보안 헤더 주입. HSTS/CSP 는 환경변수 기반."""

    def __init__(
        self,
        app: ASGIApp,
        *,
        enable_hsts: bool | None = None,
        csp_policy: str | None = None,
        extra_headers: Mapping[str, str] | None = None,
    ) -> None:
        super().__init__(app)
        self.enable_hsts = (
            enable_hsts
            if enable_hsts is not None
            else os.environ.get("FORCE_HTTPS", "false").lower() == "true"
        )
        self.csp_policy = csp_policy or os.environ.get("CSP_POLICY", "")
        self.extra_headers = dict(extra_headers or {})

    async def dispatch(self, request: Request, call_next: Callable):
        response = await call_next(request)
        for k, v in DEFAULT_SECURITY_HEADERS.items():
            response.headers.setdefault(k, v)
        if self.enable_hsts:
            response.headers.setdefault(
                "Strict-Transport-Security",
                "max-age=31536000; includeSubDomains; preload",
            )
        if self.csp_policy:
            response.headers.setdefault("Content-Security-Policy", self.csp_policy)
        for k, v in self.extra_headers.items():
            response.headers[k] = v
        return response


# ──────────────────────────────────────────────────────────────────
# Rate limiter (in-memory sliding window)
# ──────────────────────────────────────────────────────────────────


class _SlidingWindow:
    """per-key sliding window counter. Phase 1 in-memory 전용."""

    def __init__(self) -> None:
        self._buckets: dict[str, deque[float]] = defaultdict(deque)
        self._lock = Lock()

    def check(self, bucket_key: str, max_requests: int, window_sec: int) -> tuple[bool, int, float]:
        """(allowed, remaining, reset_at_unix).

        allowed=False 면 bucket 에 현재 요청을 기록하지 않는다.
        """
        now = time.time()
        cutoff = now - window_sec
        with self._lock:
            q = self._buckets[bucket_key]
            while q and q[0] < cutoff:
                q.popleft()
            if len(q) >= max_requests:
                reset_at = q[0] + window_sec if q else now + window_sec
                return False, 0, reset_at
            q.append(now)
            remaining = max_requests - len(q)
            reset_at = q[0] + window_sec if q else now + window_sec
            return True, remaining, reset_at


def _classify_category(path: str) -> tuple[str, int, int]:
    """URL path → (category, max, window_sec)."""
    for prefix, (max_req, window) in RATE_LIMIT_CATEGORIES.items():
        if prefix == "_public_":
            continue
        if path.startswith(prefix):
            return prefix, max_req, window
    max_req, window = RATE_LIMIT_CATEGORIES["_public_"]
    return "_public_", max_req, window


def _bucket_key(category: str, request: Request) -> str:
    """사용자 인증 시 user_id, 아니면 client IP."""
    # JWT middleware 가 request.state.user_id 를 세팅한다고 가정
    user_id = getattr(request.state, "user_id", None)
    if user_id is not None and category.startswith("/api/"):
        return f"{category}:user:{user_id}"
    client_host = request.client.host if request.client else "unknown"
    return f"{category}:ip:{client_host}"


class RateLimitMiddleware(BaseHTTPMiddleware):
    """NFR.md §9.4 Rate Limiting — in-memory sliding window."""

    EXEMPT_PATHS = ("/health", "/metrics", "/docs", "/openapi.json", "/redoc")

    def __init__(self, app: ASGIApp, *, window: _SlidingWindow | None = None) -> None:
        super().__init__(app)
        self._window = window or _SlidingWindow()

    async def dispatch(self, request: Request, call_next: Callable):
        path = request.url.path
        if any(path.startswith(p) for p in self.EXEMPT_PATHS):
            return await call_next(request)

        category, max_req, window_sec = _classify_category(path)
        key = _bucket_key(category, request)
        allowed, remaining, reset_at = self._window.check(key, max_req, window_sec)
        if not allowed:
            retry_after = max(1, int(reset_at - time.time()))
            error_code = (
                "AUTH_RATE_LIMITED"
                if category.startswith("/auth/")
                else "API_RATE_LIMITED"
            )
            return JSONResponse(
                status_code=429,
                content={
                    "error": {
                        "code": error_code,
                        "message": f"Rate limit exceeded for {category}",
                    }
                },
                headers={
                    "Retry-After": str(retry_after),
                    "X-RateLimit-Limit": str(max_req),
                    "X-RateLimit-Remaining": "0",
                    "X-RateLimit-Reset": str(int(reset_at)),
                },
            )

        response = await call_next(request)
        response.headers["X-RateLimit-Limit"] = str(max_req)
        response.headers["X-RateLimit-Remaining"] = str(remaining)
        response.headers["X-RateLimit-Reset"] = str(int(reset_at))
        return response


# ──────────────────────────────────────────────────────────────────
# CSRF double-submit (Cookie refresh 경로 전용)
# ──────────────────────────────────────────────────────────────────


class CSRFMiddleware(BaseHTTPMiddleware):
    """HttpOnly Cookie 기반 refresh 환경(live)에서만 활성화.

    Access Token Bearer 헤더 기반 요청은 CSRF 취약하지 않으므로 통과.
    Cookie 가 제출된 mutation 요청은 헤더 X-CSRF-Token 이 쿠키 값과 일치해야 한다.
    """

    COOKIE_NAME = "ebs_refresh"
    HEADER_NAME = "X-CSRF-Token"
    MUTATION_METHODS = frozenset({"POST", "PUT", "PATCH", "DELETE"})
    # HttpOnly refresh 쿠키와 쌍으로 내려가는 non-HttpOnly 토큰
    CSRF_COOKIE_NAME = "ebs_csrf"

    async def dispatch(self, request: Request, call_next: Callable):
        if request.method not in self.MUTATION_METHODS:
            return await call_next(request)
        # refresh 쿠키 없으면 Bearer 경로 — 통과
        refresh_cookie = request.cookies.get(self.COOKIE_NAME)
        if not refresh_cookie:
            return await call_next(request)

        csrf_cookie = request.cookies.get(self.CSRF_COOKIE_NAME)
        csrf_header = request.headers.get(self.HEADER_NAME)
        if not csrf_cookie or not csrf_header or csrf_cookie != csrf_header:
            return JSONResponse(
                status_code=401,
                content={
                    "error": {
                        "code": "CSRF_TOKEN_MISMATCH",
                        "message": "CSRF double-submit token missing or mismatched",
                    }
                },
            )
        return await call_next(request)
