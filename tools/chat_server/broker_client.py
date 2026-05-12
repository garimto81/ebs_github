"""Async MCP client wrapper for the broker (StreamableHTTP).

본 wrapper 는 chat-server 가 broker 의 7 tools 를 호출하는 단일 진입점.
publisher_id 는 항상 'chat-server' 로 고정 (source='user' 발급 권한).
"""
from __future__ import annotations

import json
import os
from contextlib import asynccontextmanager

from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client


PUBLISHER_ID = "chat-server"


def _extract_result(r) -> dict:
    """Extract result dict from CallToolResult.

    FastMCP only populates `structuredContent` when the tool function has a
    typed return model. Broker tools currently return `dict` (untyped), so the
    result lands in `content[0].text` as a JSON string. Try structured first,
    fall back to parsing the first text content.
    """
    if getattr(r, "structuredContent", None):
        return r.structuredContent
    content = getattr(r, "content", None) or []
    for item in content:
        text = getattr(item, "text", None)
        if not text:
            continue
        try:
            parsed = json.loads(text)
        except (TypeError, ValueError):
            continue
        if isinstance(parsed, dict):
            return parsed
    return {}


class BrokerClient:
    def __init__(self, url: str | None = None):
        # Default host-friendly. Docker container overrides via BROKER_URL env
        # (compose.yml → http://host.docker.internal:7383/mcp). 호스트에서
        # 실행되는 CLI / hooks / pytest 가 default 로 connect 가능.
        self.url = url or os.environ.get(
            "BROKER_URL", "http://127.0.0.1:7383/mcp"
        )

    @asynccontextmanager
    async def session(self):
        """Open MCP session (one-shot)."""
        async with streamablehttp_client(self.url) as (read, write, _):
            async with ClientSession(read, write) as session:
                await session.initialize()
                yield session

    async def publish(
        self, topic: str, payload: dict, source: str
    ) -> dict:
        """Publish via broker (publisher_id auto-injected)."""
        async with self.session() as s:
            r = await s.call_tool(
                "publish_event",
                {
                    "topic": topic,
                    "payload": payload,
                    "source": source,
                    "publisher_id": PUBLISHER_ID,
                },
            )
            return _extract_result(r)

    async def subscribe(
        self, topic: str, from_seq: int = 0, timeout_sec: int = 30
    ) -> dict:
        async with self.session() as s:
            r = await s.call_tool(
                "subscribe",
                {"topic": topic, "from_seq": from_seq, "timeout_sec": timeout_sec},
            )
            return _extract_result(r)

    async def get_history(
        self, topic: str = "*", since_seq: int = 0, limit: int = 50
    ) -> dict:
        async with self.session() as s:
            r = await s.call_tool(
                "get_history",
                {"topic": topic, "since_seq": since_seq, "limit": limit},
            )
            return _extract_result(r)

    async def discover_peers(self) -> dict:
        async with self.session() as s:
            r = await s.call_tool("discover_peers", {})
            return _extract_result(r)
