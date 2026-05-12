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


def _get_history_sync(topic: str, since_seq: int, limit: int = 50) -> dict:
    """Sync wrapper for broker_client.get_history."""
    from tools.chat_server.broker_client import BrokerClient
    client = BrokerClient(url="http://127.0.0.1:7383/mcp")
    return asyncio.run(
        client.get_history(topic=topic, since_seq=since_seq, limit=limit)
    )


def _has_reply_from(team_id: str, mention_seq: int, mention_topic: str) -> bool:
    """team_id 가 mention_seq 에 대해 reply 했는지 broker history 로 확인.

    Reply 조건: kind in (reply, msg) AND reply_to == mention_seq AND from == team_id.
    """
    try:
        r = _get_history_sync(topic=mention_topic, since_seq=mention_seq, limit=50)
    except Exception:
        return False  # 확인 불가 → unanswered 처리 (재 inject)
    for e in r.get("events", []):
        p = e.get("payload", {})
        if (
            p.get("reply_to") == mention_seq
            and p.get("from") == team_id
        ):
            return True
    return False


def inject_chat_mentions(team_id: str, state_file: Path) -> list[dict]:
    """Fetch unanswered chat mentions for team_id.

    Spec (Inter_Session_Chat_Workflow.md §3): mention 받으면 다음 발언 차례에
    reply 필수. 응답 X = 매 cycle 재 inject (응답 보장).

    Algorithm:
      1. last_seen + 1 부터 subscribe (chat:*)
      2. mentions = events where @{team_id} ∈ payload.mentions
      3. 각 mention 에 대해 broker get_history 로 reply 여부 확인
      4. unanswered = 응답 안 한 mentions
      5. last_seen update:
         - unanswered 있으면 → min(unanswered.seq) - 1 (재 inject 유지)
         - unanswered 없으면 → next_seq (정상 진행)
      6. return unanswered (stderr inject 대상)

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
    all_mentions = [
        e for e in events
        if my_marker in (e.get("payload", {}).get("mentions") or [])
    ]

    if not all_mentions:
        _write_last_seen(state_file, next_seq)
        return []

    # 각 mention 에 대해 응답 여부 확인 (broker get_history 별도 query)
    unanswered = [
        m for m in all_mentions
        if not _has_reply_from(team_id, m["seq"], m["topic"])
    ]

    if unanswered:
        # 재 inject 보장 위해 가장 낮은 seq - 1 로 last_seen 후퇴
        new_last = min(m["seq"] for m in unanswered) - 1
        _write_last_seen(state_file, max(new_last, 0))
    else:
        _write_last_seen(state_file, next_seq)

    return unanswered


import time


async def _subscribe_async(topic: str, from_seq: int, timeout_sec: int) -> dict:
    from tools.chat_server.broker_client import BrokerClient
    client = BrokerClient(url="http://127.0.0.1:7383/mcp")
    return await client.subscribe(
        topic=topic, from_seq=from_seq, timeout_sec=timeout_sec
    )


async def _publish_async(topic: str, payload: dict, source: str) -> dict:
    from tools.chat_server.broker_client import BrokerClient
    client = BrokerClient(url="http://127.0.0.1:7383/mcp")
    return await client.publish(topic=topic, payload=payload, source=source)


async def consensus_silent_ok(
    question_seq: int,
    topic: str,
    from_team: str,
    ttl_sec: int = 30,
    question_mentions: list[str] | None = None,
) -> tuple[str, list[dict]]:
    """Silent OK 30s consensus model.

    Logic:
      - If question_mentions contains '@user' → return ('user_mention_pending', []).
      - Otherwise poll for replies up to ttl_sec.
      - If reply received → ('answered', replies).
      - If no reply by deadline → publish decision('ASSUMED ...') + ('silent_ok', []).
    """
    if question_mentions and "@user" in question_mentions:
        return ("user_mention_pending", [])

    deadline = time.time() + ttl_sec
    while time.time() < deadline:
        remaining = max(1, int(deadline - time.time()))
        try:
            r = await _subscribe_async(
                topic=topic, from_seq=question_seq + 1, timeout_sec=remaining
            )
        except Exception as e:
            logger.debug(f"consensus subscribe error (silent): {e}")
            return ("error", [])

        replies = [
            e for e in r.get("events", [])
            if e.get("payload", {}).get("reply_to") == question_seq
        ]
        if replies:
            return ("answered", replies)

    # silent OK — publish decision
    try:
        await _publish_async(
            topic=topic,
            payload={
                "kind": "decision",
                "from": from_team,
                "to": ["*"],
                "body": "[ASSUMED] proceeding. raise blocker if disagree.",
                "reply_to": question_seq,
                "thread_id": None,
                "mentions": [],
                "ts": _now_iso(),
            },
            source=from_team,
        )
    except Exception as e:
        logger.debug(f"consensus decision publish failed (silent): {e}")
    return ("silent_ok", [])
