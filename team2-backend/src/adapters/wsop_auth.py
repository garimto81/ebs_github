"""WSOP LIVE OAuth 2.0 outbound 인증 adapter.

docs/2. Development/2.5 Shared/Authentication.md "방향별 인증 2-스택" 참조.

WSOP LIVE 방향:
  POST /auth/token?grant_type=client_credentials
  Authorization: Basic base64(client_id:client_secret)
  응답: {access_token, token_type="Bearer", expires_in}

환경변수:
  WSOP_LIVE_AUTH_URL (예: https://auth.wsoplive.example/auth/token)
  WSOP_LIVE_CLIENT_ID
  WSOP_LIVE_CLIENT_SECRET
"""

from __future__ import annotations

import asyncio
import base64
import os
import time
from dataclasses import dataclass, field

import httpx


@dataclass
class _TokenCache:
    access_token: str = ""
    expires_at: float = 0.0  # unix epoch seconds
    lock: asyncio.Lock = field(default_factory=asyncio.Lock)


class WsopAuthClient:
    """Client-credentials OAuth client with in-memory token cache.

    Per-worker 캐시 (Redis 공유 불필요 — stateless). 만료 30초 전 선제 재발급.
    """

    # 만료 시간 30초 전에 선제 재발급
    REFRESH_MARGIN_SEC: float = 30.0

    def __init__(
        self,
        auth_url: str | None = None,
        client_id: str | None = None,
        client_secret: str | None = None,
        http_client: httpx.AsyncClient | None = None,
    ) -> None:
        self.auth_url = auth_url or os.environ.get("WSOP_LIVE_AUTH_URL", "")
        self.client_id = client_id or os.environ.get("WSOP_LIVE_CLIENT_ID", "")
        self.client_secret = client_secret or os.environ.get("WSOP_LIVE_CLIENT_SECRET", "")
        self._http = http_client
        self._cache = _TokenCache()

    async def get_access_token(self) -> str:
        """유효한 access_token 반환. 만료 임박 시 재발급."""
        now = time.time()
        if self._cache.access_token and (self._cache.expires_at - now) > self.REFRESH_MARGIN_SEC:
            return self._cache.access_token

        async with self._cache.lock:
            # 재검사 (다른 태스크가 이미 갱신했을 수 있음)
            now = time.time()
            if self._cache.access_token and (self._cache.expires_at - now) > self.REFRESH_MARGIN_SEC:
                return self._cache.access_token
            await self._refresh()
            return self._cache.access_token

    async def _refresh(self) -> None:
        if not self.auth_url or not self.client_id or not self.client_secret:
            raise RuntimeError(
                "WSOP LIVE OAuth credentials not configured. "
                "Set WSOP_LIVE_AUTH_URL / CLIENT_ID / CLIENT_SECRET."
            )

        basic = base64.b64encode(
            f"{self.client_id}:{self.client_secret}".encode()
        ).decode()
        headers = {
            "Authorization": f"Basic {basic}",
            "Content-Type": "application/x-www-form-urlencoded",
        }
        params = {"grant_type": "client_credentials"}

        owns_client = self._http is None
        client = self._http or httpx.AsyncClient(timeout=10.0)
        try:
            resp = await client.post(self.auth_url, headers=headers, params=params)
            resp.raise_for_status()
            body = resp.json()
        finally:
            if owns_client:
                await client.aclose()

        self._cache.access_token = body["access_token"]
        expires_in = float(body.get("expires_in", 3600))
        self._cache.expires_at = time.time() + expires_in
