"""Hook integration helpers — called from .claude/hooks/.

These are synchronous (hook 환경) wrappers around the async broker_client.
Broker dead 시 silent skip (hook 동작 막지 않음).
"""
from __future__ import annotations

import asyncio
import logging
from datetime import datetime, timezone
from pathlib import Path

logger = logging.getLogger("chat-hook")


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _publish_sync(topic: str, payload: dict, source: str) -> None:
    """Sync wrapper for broker_client.publish. Silent skip on error."""
    try:
        from tools.chat_server.broker_client import BrokerClient
        client = BrokerClient(url="http://127.0.0.1:7383/mcp")
        asyncio.run(client.publish(topic=topic, payload=payload, source=source))
    except Exception as e:
        logger.debug(f"chat publish failed (silent): {e}")


def _resolve_owner_streams(paths: list[str]) -> list[str]:
    """Map impacted paths → owner stream ids.

    Heuristic: docs/2. Development/2.1 Frontend/Lobby/* → S2
               docs/2. Development/2.4 Command Center/*  → S3
               docs/2. Development/2.2 Backend/*         → S7
               etc.
    Fallback: empty list if no match.
    """
    mapping = [
        ("2.1 Frontend/Lobby", "S2"),
        ("2.4 Command Center", "S3"),
        ("2.2 Backend", "S7"),
        ("Engine", "S8"),
    ]
    owners: set[str] = set()
    for p in paths:
        for needle, stream in mapping:
            if needle in p:
                owners.add(stream)
    return sorted(owners)


def emit_chat_advisory(
    target_rel: str, impacted: list[str], editor_team: str
) -> None:
    """Publish a chat:room:design advisory when cascade impact detected.

    Called from orch_PreToolUse.py at the cascade-advisory point.
    Silent (no exception) when broker dead or no impact.
    """
    if not impacted:
        return
    owners = _resolve_owner_streams(impacted)
    if editor_team in owners:
        owners.remove(editor_team)
    body_lines = [
        f"[AUTO] Editing `{target_rel}` impacts {len(impacted)} docs:"
    ]
    for p in impacted[:5]:
        body_lines.append(f"- {p}")
    if len(impacted) > 5:
        body_lines.append(f"... +{len(impacted) - 5} more")
    mentions = [f"@{s}" for s in owners]

    try:
        _publish_sync(
            topic="chat:room:design",
            payload={
                "kind": "system",
                "from": editor_team,
                "to": owners,
                "body": "\n".join(body_lines),
                "reply_to": None,
                "thread_id": None,
                "mentions": mentions,
                "ts": _now_iso(),
            },
            source=editor_team,
        )
    except Exception as e:
        logger.debug(f"emit_chat_advisory silent skip: {e}")
