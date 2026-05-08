"""EBS Message Bus — FastMCP server entry (Phase 2 MVP).

7 Tools:
  publish_event, subscribe, broadcast, unsubscribe,
  discover_peers, get_history, acquire_lock (+ release_lock helper)

Transport: StreamableHTTP at http://127.0.0.1:7383/mcp
Storage: SQLite WAL at .claude/message_bus/events.db

Architecture:
- No lifespan — module-level singletons + lazy init + asyncio.Lock.
- Single broker process = single shared Store/Dispatcher across MCP sessions.
- Topic ACL applied (topics.check_publish_acl).
"""
from __future__ import annotations

import asyncio
import logging
import logging.handlers
import sys
from pathlib import Path

from mcp.server.fastmcp import FastMCP

# Allow running as script
sys.path.insert(0, str(Path(__file__).resolve().parents[3]))

from tools.orchestrator.message_bus.dispatcher import EventDispatcher
from tools.orchestrator.message_bus.store import Store
from tools.orchestrator.message_bus.topics import check_publish_acl

DEFAULT_PORT = 7383
DEFAULT_HOST = "127.0.0.1"

PROJECT_ROOT = Path(__file__).resolve().parents[3]
LOG_FILE = PROJECT_ROOT / ".claude" / "message_bus" / "broker.log"

# Setup observability logger (Phase 4)
logger = logging.getLogger("ebs-message-bus")
logger.setLevel(logging.INFO)
if not logger.handlers:
    LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    fh = logging.handlers.RotatingFileHandler(
        LOG_FILE, maxBytes=10 * 1024 * 1024, backupCount=3, encoding="utf-8"
    )
    fh.setFormatter(
        logging.Formatter("%(asctime)s [%(levelname)s] %(message)s")
    )
    logger.addHandler(fh)


# Module-level singletons (lazy init on first tool call).
_store: Store | None = None
_dispatcher: EventDispatcher | None = None
_init_lock: asyncio.Lock | None = None


async def _ensure_initialized() -> None:
    global _store, _dispatcher, _init_lock
    if _init_lock is None:
        _init_lock = asyncio.Lock()
    async with _init_lock:
        if _store is None:
            db_path = PROJECT_ROOT / ".claude" / "message_bus" / "events.db"
            store = Store(db_path=db_path)
            await store.initialize()
            _store = store
            _dispatcher = EventDispatcher()
            logger.info(f"broker initialized, db={db_path}")


mcp = FastMCP(
    name="ebs-message-bus",
    instructions=(
        "Inter-session message bus for EBS multi-session worktrees. "
        "7 tools: publish_event, subscribe, broadcast, unsubscribe, "
        "discover_peers, get_history, acquire_lock."
    ),
    host=DEFAULT_HOST,
    port=DEFAULT_PORT,
)


# ─── Tool 1: publish_event ────────────────────────────────────────────

@mcp.tool()
async def publish_event(topic: str, payload: dict, source: str = "unknown") -> dict:
    """Publish an event to a topic.

    Args:
        topic: Topic (e.g., "stream:S1", "cascade:design"). ACL applies.
        payload: JSON-serializable payload.
        source: Sender id (e.g., "S1", "S3-cc").

    Returns:
        {seq, ts, topic, recipients}
    """
    allowed, reason = check_publish_acl(topic, source)
    if not allowed:
        logger.warning(f"ACL denied topic={topic} source={source}: {reason}")
        raise ValueError(f"ACL denied: {reason}")
    await _ensure_initialized()
    assert _store is not None and _dispatcher is not None
    seq, ts = await _store.publish(topic, payload, source)
    recipients = await _dispatcher.notify(topic, seq, source, ts, payload)
    logger.info(f"publish topic={topic} source={source} seq={seq} recipients={recipients}")
    return {"seq": seq, "ts": ts, "topic": topic, "recipients": recipients}


# ─── Tool 2: subscribe (long-poll) ────────────────────────────────────

@mcp.tool()
async def subscribe(
    topic: str, from_seq: int = 0, timeout_sec: int = 30
) -> dict:
    """Subscribe to a topic (long-poll).

    Args:
        topic: Topic to subscribe ("*" matches all topics).
        from_seq: Last seq seen (0 = from start).
        timeout_sec: Long-poll timeout in seconds.

    Returns:
        {events, next_seq, mode: "history"|"push"|"timeout"}
    """
    await _ensure_initialized()
    assert _store is not None and _dispatcher is not None
    history = await _store.get_history(topic, since_seq=from_seq, limit=50)
    if history:
        return {
            "events": history,
            "next_seq": history[-1]["seq"] + 1,
            "mode": "history",
        }
    event = await _dispatcher.wait_for_event(topic, timeout_sec)
    if event:
        return {
            "events": [event],
            "next_seq": event["seq"] + 1,
            "mode": "push",
        }
    return {"events": [], "next_seq": from_seq, "mode": "timeout"}


# ─── Tool 3: broadcast ────────────────────────────────────────────────

@mcp.tool()
async def broadcast(payload: dict, source: str = "unknown") -> dict:
    """Publish to '*' broadcast topic. All subscribers (any topic via '*' wait) receive."""
    await _ensure_initialized()
    assert _store is not None and _dispatcher is not None
    topic = "*"
    seq, ts = await _store.publish(topic, payload, source)
    recipients = await _dispatcher.notify(topic, seq, source, ts, payload)
    return {"seq": seq, "ts": ts, "topic": topic, "recipients": recipients}


# ─── Tool 4: unsubscribe ──────────────────────────────────────────────

@mcp.tool()
async def unsubscribe(subscription_id: str = "") -> dict:
    """Unsubscribe (no-op for stateless long-poll PoC; future MVP will track sessions).

    PoC behavior: returns ok=True. Subscriptions are ephemeral (per-call).
    Phase 4 hardening: track subscription_id from subscribe responses + cancel future.
    """
    return {"ok": True, "subscription_id": subscription_id, "note": "stateless long-poll; no persistent subscription"}


# ─── Tool 5: discover_peers ───────────────────────────────────────────

@mcp.tool()
async def discover_peers() -> dict:
    """List distinct sources with last_seen + event_count from event log."""
    await _ensure_initialized()
    assert _store is not None
    peers = await _store.discover_peers()
    return {"peers": peers, "count": len(peers)}


# ─── Tool 6: get_history ──────────────────────────────────────────────

@mcp.tool()
async def get_history(topic: str = "*", since_seq: int = 0, limit: int = 50) -> dict:
    """Catch-up query: events since `since_seq`. Default returns first 50 of all."""
    await _ensure_initialized()
    assert _store is not None
    events = await _store.get_history(topic, since_seq=since_seq, limit=limit)
    return {"events": events, "count": len(events)}


# ─── Tool 7: acquire_lock (advisory, R6) ──────────────────────────────

@mcp.tool()
async def acquire_lock(resource: str, holder: str, ttl_sec: int = 60) -> dict:
    """Try to acquire an advisory lock on a resource.

    Args:
        resource: Lock name (e.g., "cascade:Lobby_PRD.md").
        holder: Holder identity (e.g., "S2").
        ttl_sec: TTL in seconds (default 60).

    Returns:
        {acquired: bool, holder: str, expires_at: ISO8601, renewed: bool}
        If acquired=False, holder/expires_at indicate the current owner.
    """
    await _ensure_initialized()
    assert _store is not None
    return await _store.acquire_lock(resource, holder, ttl_sec)


# ─── Tool 7b: release_lock (helper) ───────────────────────────────────

@mcp.tool()
async def release_lock(resource: str, holder: str) -> dict:
    """Release an advisory lock. Only the holder can release."""
    await _ensure_initialized()
    assert _store is not None
    released = await _store.release_lock(resource, holder)
    return {"released": released}


def run() -> None:
    """Run the FastMCP server with StreamableHTTP transport."""
    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    mcp.run(transport="streamable-http")


if __name__ == "__main__":
    run()
