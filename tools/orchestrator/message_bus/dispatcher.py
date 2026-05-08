"""In-memory event dispatcher (long-poll wake-up).

Phase 1 PoC. Avoids true MCP `notifications/*` server-push complexity by
letting subscribers long-poll via `subscribe` tool. New events trigger
immediate wake-up via asyncio futures.

Latency: <10ms wake-up + ~10-50ms SQLite WAL fsync = total ~50ms p99.
"""
from __future__ import annotations

import asyncio
from collections import defaultdict


class EventDispatcher:
    """Per-topic asyncio.Future waiters. Wake all on `notify`."""

    def __init__(self) -> None:
        self._waiters: dict[str, list[asyncio.Future]] = defaultdict(list)
        self._lock = asyncio.Lock()

    async def wait_for_event(self, topic: str, timeout_sec: int) -> dict | None:
        future: asyncio.Future = asyncio.get_event_loop().create_future()
        async with self._lock:
            self._waiters[topic].append(future)
        try:
            return await asyncio.wait_for(future, timeout=timeout_sec)
        except asyncio.TimeoutError:
            async with self._lock:
                if future in self._waiters[topic]:
                    self._waiters[topic].remove(future)
            return None

    async def notify(
        self,
        topic: str,
        seq: int,
        source: str,
        ts: str,
        payload: dict,
    ) -> int:
        """Wake all waiters on `topic` and `*` (broadcast). Returns recipient count."""
        event = {
            "seq": seq,
            "topic": topic,
            "source": source,
            "ts": ts,
            "payload": payload,
        }
        async with self._lock:
            specific = self._waiters.pop(topic, [])
            wildcard = self._waiters.pop("*", [])
        recipients = 0
        for w in specific + wildcard:
            if not w.done():
                w.set_result(event)
                recipients += 1
        return recipients

    async def waiter_count(self, topic: str | None = None) -> int:
        """Diagnostic: number of pending waiters."""
        async with self._lock:
            if topic is None:
                return sum(len(ws) for ws in self._waiters.values())
            return len(self._waiters.get(topic, []))
