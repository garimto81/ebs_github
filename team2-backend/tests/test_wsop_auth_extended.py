"""wsop_auth.py adapter unit tests (Session 2.5 — B-Q10 cascade, 2026-04-27).

Targets src/adapters/wsop_auth.py (0% → 70% goal — completely untested adapter).

Strict rule: production code 0 modification, tests/ only.
"""
import asyncio
import base64
import time
from unittest.mock import AsyncMock, MagicMock

import pytest

from src.adapters.wsop_auth import WsopAuthClient


# ── Init ────────────────────────────────────────


def test_init_uses_explicit_args():
    """Constructor uses explicit args (line 50-52)."""
    client = WsopAuthClient(
        auth_url="https://override/token",
        client_id="cid-x",
        client_secret="cs-x",
    )
    assert client.auth_url == "https://override/token"
    assert client.client_id == "cid-x"
    assert client.client_secret == "cs-x"


def test_init_falls_back_to_env(monkeypatch):
    """Constructor reads env vars when explicit args absent (line 50-52)."""
    monkeypatch.setenv("WSOP_LIVE_AUTH_URL", "https://env/token")
    monkeypatch.setenv("WSOP_LIVE_CLIENT_ID", "env-cid")
    monkeypatch.setenv("WSOP_LIVE_CLIENT_SECRET", "env-cs")
    client = WsopAuthClient()
    assert client.auth_url == "https://env/token"
    assert client.client_id == "env-cid"
    assert client.client_secret == "env-cs"


# ── get_access_token caching ────────────────────


@pytest.mark.asyncio
async def test_get_access_token_returns_cached_when_valid():
    """Cached token returned when expires_at far in future (line 58-60)."""
    client = WsopAuthClient(auth_url="x", client_id="x", client_secret="x")
    client._cache.access_token = "cached-token"
    client._cache.expires_at = time.time() + 3600
    result = await client.get_access_token()
    assert result == "cached-token"


@pytest.mark.asyncio
async def test_get_access_token_refreshes_when_empty():
    """Empty cache → _refresh called (line 67-68)."""
    client = WsopAuthClient(auth_url="x", client_id="x", client_secret="x")

    async def _mock_refresh():
        client._cache.access_token = "fresh-token"
        client._cache.expires_at = time.time() + 3600

    client._refresh = _mock_refresh
    result = await client.get_access_token()
    assert result == "fresh-token"


@pytest.mark.asyncio
async def test_get_access_token_double_check_in_lock():
    """Concurrent calls: lock + recheck → only 1 refresh (line 62-66)."""
    client = WsopAuthClient(auth_url="x", client_id="x", client_secret="x")
    refresh_count = 0

    async def _mock_refresh():
        nonlocal refresh_count
        refresh_count += 1
        await asyncio.sleep(0.01)
        client._cache.access_token = f"token-{refresh_count}"
        client._cache.expires_at = time.time() + 3600

    client._refresh = _mock_refresh
    results = await asyncio.gather(
        client.get_access_token(),
        client.get_access_token(),
    )
    # Both calls get same token (lock + recheck prevents double refresh)
    assert results[0] == results[1]
    assert refresh_count == 1


# ── _refresh paths ──────────────────────────────


@pytest.mark.asyncio
async def test_refresh_raises_when_unconfigured():
    """_refresh raises RuntimeError when auth_url/client_id/client_secret missing (line 71-75)."""
    client = WsopAuthClient(auth_url="", client_id="", client_secret="")
    with pytest.raises(RuntimeError, match="WSOP LIVE OAuth credentials not configured"):
        await client._refresh()


@pytest.mark.asyncio
async def test_refresh_uses_provided_http_client():
    """_refresh uses provided http_client + does not close it (line 86-94)."""
    mock_response = MagicMock()
    mock_response.json.return_value = {"access_token": "new-tok", "expires_in": 1800}
    mock_response.raise_for_status = MagicMock()

    mock_http = AsyncMock()
    mock_http.post = AsyncMock(return_value=mock_response)

    client = WsopAuthClient(
        auth_url="https://test/token",
        client_id="cid",
        client_secret="cs",
        http_client=mock_http,
    )
    await client._refresh()

    assert client._cache.access_token == "new-tok"
    mock_http.post.assert_called_once()
    # owns_client=False — should NOT close
    mock_http.aclose.assert_not_called()


@pytest.mark.asyncio
async def test_refresh_basic_auth_header_format():
    """_refresh constructs Basic base64(client_id:client_secret) header (line 77-83)."""
    mock_response = MagicMock()
    mock_response.json.return_value = {"access_token": "tok", "expires_in": 1000}
    mock_response.raise_for_status = MagicMock()

    mock_http = AsyncMock()
    mock_http.post = AsyncMock(return_value=mock_response)

    client = WsopAuthClient(
        auth_url="https://test/token",
        client_id="user",
        client_secret="pass",
        http_client=mock_http,
    )
    await client._refresh()

    expected_basic = base64.b64encode(b"user:pass").decode()
    call_kwargs = mock_http.post.call_args.kwargs
    assert call_kwargs["headers"]["Authorization"] == f"Basic {expected_basic}"
    assert call_kwargs["headers"]["Content-Type"] == "application/x-www-form-urlencoded"
    assert call_kwargs["params"] == {"grant_type": "client_credentials"}


@pytest.mark.asyncio
async def test_refresh_default_expires_in_3600():
    """Default expires_in = 3600 if response omits (line 97)."""
    mock_response = MagicMock()
    mock_response.json.return_value = {"access_token": "no-exp-tok"}  # no expires_in
    mock_response.raise_for_status = MagicMock()

    mock_http = AsyncMock()
    mock_http.post = AsyncMock(return_value=mock_response)

    client = WsopAuthClient(
        auth_url="https://test/token",
        client_id="cid",
        client_secret="cs",
        http_client=mock_http,
    )
    before = time.time()
    await client._refresh()
    after = time.time()

    # expires_at ≈ time.time() + 3600
    assert before + 3600 <= client._cache.expires_at <= after + 3600 + 1
