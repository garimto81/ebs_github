"""EBS Message Bus — FastMCP server entry (Phase 1 PoC).

Tools (PoC):
- publish_event(topic, payload, source) → {seq, ts, topic}
- subscribe(topic, from_seq, timeout_sec) → {events, next_seq, mode}

Transport: StreamableHTTP at http://127.0.0.1:7383/mcp
Storage: SQLite WAL at .claude/message_bus/events.db

Architecture note (PoC):
- No lifespan — use lazy module-level singletons + asyncio.Lock for init.
- Each MCP client session shares the same Store/Dispatcher (broker = one process).
- Process exit naturally tears down (no explicit cleanup required for PoC).
"""
from __future__ import annotations

import asyncio
import sys
from pathlib import Path

from mcp.server.fastmcp import FastMCP

# Allow running as script
sys.path.insert(0, str(Path(__file__).resolve().parents[3]))

from tools.orchestrator.message_bus.dispatcher import EventDispatcher
from tools.orchestrator.message_bus.store import Store

DEFAULT_PORT = 7383
DEFAULT_HOST = "127.0.0.1"


# Module-level singletons (lazy-initialized on first tool call).
# Single broker process = single shared instance across all MCP sessions.
_store: Store | None = None
_dispatcher: EventDispatcher | None = None
_init_lock: asyncio.Lock | None = None  # created on first event-loop entry


async def _ensure_initialized() -> None:
    """Idempotent lazy init. First tool call wins; subsequent ones see existing instances."""
    global _store, _dispatcher, _init_lock
    if _init_lock is None:
        # Bind lock to current event loop (FastMCP creates one main loop)
        _init_lock = asyncio.Lock()
    async with _init_lock:
        if _store is None:
            db_path = (
                Path(__file__).resolve().parents[3]
                / ".claude"
                / "message_bus"
                / "events.db"
            )
            store = Store(db_path=db_path)
            await store.initialize()
            _store = store
            _dispatcher = EventDispatcher()


mcp = FastMCP(
    name="ebs-message-bus",
    instructions=(
        "Inter-session message bus for EBS multi-session worktrees. "
        "Use publish_event to broadcast, subscribe to long-poll for new events."
    ),
    host=DEFAULT_HOST,
    port=DEFAULT_PORT,
)


@mcp.tool()
async def publish_event(topic: str, payload: dict, source: str = "unknown") -> dict:
    """Publish an event to a topic.

    Args:
        topic: Topic name (e.g., "stream:S1", "cascade:design", "*" for broadcast).
        payload: JSON-serializable payload.
        source: Sender identifier (e.g., stream id like "S1", "S2").

    Returns:
        {seq: int, ts: ISO8601, topic: str}
    """
    await _ensure_initialized()
    assert _store is not None and _dispatcher is not None
    seq, ts = await _store.publish(topic, payload, source)
    recipients = await _dispatcher.notify(topic, seq, source, ts, payload)
    return {"seq": seq, "ts": ts, "topic": topic, "recipients": recipients}


@mcp.tool()
async def subscribe(
    topic: str, from_seq: int = 0, timeout_sec: int = 30
) -> dict:
    """Subscribe to a topic with long-poll semantics.

    Behavior:
    1. If history exists since from_seq → return immediately ("history" mode).
    2. Else wait for new event up to timeout_sec ("push" mode if event arrives).
    3. On timeout return empty list ("timeout" mode).

    Args:
        topic: Topic to subscribe ("*" matches all topics).
        from_seq: Last seq seen (0 = from start).
        timeout_sec: Long-poll timeout in seconds (default 30).

    Returns:
        {events: list, next_seq: int, mode: "history"|"push"|"timeout"}
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


def run() -> None:
    """Run the FastMCP server with StreamableHTTP transport."""
    if sys.platform == "win32":
        # R5 mitigation: avoid ProactorEventLoop quirks with asyncio + http
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    mcp.run(transport="streamable-http")


if __name__ == "__main__":
    run()
