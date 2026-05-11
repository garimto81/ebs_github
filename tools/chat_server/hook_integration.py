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


import json


def _subscribe_sync(topic: str, from_seq: int, timeout_sec: int = 1) -> dict:
    """Sync wrapper for broker_client.subscribe. Raises on error (caller handles)."""
    from tools.chat_server.broker_client import BrokerClient
    client = BrokerClient(url="http://127.0.0.1:7383/mcp")
    return asyncio.run(
        client.subscribe(topic=topic, from_seq=from_seq, timeout_sec=timeout_sec)
    )


def _read_last_seen(state_file: Path) -> int:
    try:
        return json.loads(state_file.read_text(encoding="utf-8"))["last_seq"]
    except (FileNotFoundError, json.JSONDecodeError, KeyError):
        return 0


def _write_last_seen(state_file: Path, last_seq: int) -> None:
    state_file.parent.mkdir(parents=True, exist_ok=True)
    state_file.write_text(json.dumps({"last_seq": last_seq}), encoding="utf-8")


def inject_chat_mentions(team_id: str, state_file: Path) -> list[dict]:
    """Fetch chat mentions for team_id since last seen.

    Returns list of events whose payload.mentions contains '@{team_id}'.
    Side effect: updates state_file with new next_seq.
    Silent (returns []) on broker error.
    """
    last = _read_last_seen(state_file)
    try:
        r = _subscribe_sync(topic="chat:*", from_seq=last + 1, timeout_sec=1)
    except Exception as e:
        logger.debug(f"chat subscribe failed (silent): {e}")
        return []

    events = r.get("events", [])
    next_seq = r.get("next_seq", last)
    my_marker = f"@{team_id}"
    my_mentions = [
        e for e in events
        if my_marker in (e.get("payload", {}).get("mentions") or [])
    ]
    _write_last_seen(state_file, next_seq)
    return my_mentions
