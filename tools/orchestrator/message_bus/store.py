"""SQLite WAL event store with async single-writer queue.

Phase 1 PoC. Validates R1 (SQLite WAL contention) + R3 (RPS) + R4 (durability).
"""
from __future__ import annotations

import asyncio
import json
from collections.abc import Awaitable
from datetime import datetime, timezone
from pathlib import Path

import aiosqlite


class Store:
    """Async SQLite WAL store with single-writer queue pattern.

    All writes flow through a single asyncio Task to avoid SQLite WAL writer
    contention. Reads are concurrent (WAL allows reader+writer simultaneity).
    """

    def __init__(self, db_path: str | Path):
        self.db_path = Path(db_path)
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self.write_queue: asyncio.Queue = asyncio.Queue()
        self._writer_task: asyncio.Task | None = None
        self._db: aiosqlite.Connection | None = None
        self._closed = False

    async def initialize(self) -> None:
        self._db = await aiosqlite.connect(self.db_path)
        await self._db.execute("PRAGMA journal_mode=WAL;")
        await self._db.execute("PRAGMA synchronous=NORMAL;")
        await self._db.execute(
            """CREATE TABLE IF NOT EXISTS events (
                seq INTEGER PRIMARY KEY AUTOINCREMENT,
                topic TEXT NOT NULL,
                source TEXT NOT NULL,
                ts TEXT NOT NULL,
                payload TEXT NOT NULL
            )"""
        )
        await self._db.execute(
            "CREATE INDEX IF NOT EXISTS idx_events_topic_seq ON events(topic, seq);"
        )
        await self._db.commit()
        self._writer_task = asyncio.create_task(self._writer_loop(), name="store-writer")

    async def publish(self, topic: str, payload: dict, source: str) -> tuple[int, str]:
        """Enqueue a publish. Returns (seq, ts) once the writer commits."""
        ts = datetime.now(timezone.utc).isoformat()
        future: asyncio.Future[int] = asyncio.get_event_loop().create_future()
        await self.write_queue.put((topic, source, ts, json.dumps(payload), future))
        seq = await future
        return seq, ts

    async def _writer_loop(self) -> None:
        assert self._db is not None
        while not self._closed:
            try:
                topic, source, ts, payload_json, future = await self.write_queue.get()
            except asyncio.CancelledError:
                break
            try:
                cursor = await self._db.execute(
                    "INSERT INTO events (topic, source, ts, payload) VALUES (?, ?, ?, ?)",
                    (topic, source, ts, payload_json),
                )
                await self._db.commit()
                seq = cursor.lastrowid
                if not future.done():
                    future.set_result(seq)
            except Exception as e:
                if not future.done():
                    future.set_exception(e)

    async def get_history(
        self, topic: str, since_seq: int = 0, limit: int = 50
    ) -> list[dict]:
        assert self._db is not None
        if topic == "*":
            cursor = await self._db.execute(
                "SELECT seq, topic, source, ts, payload FROM events "
                "WHERE seq >= ? ORDER BY seq LIMIT ?",
                (since_seq, limit),
            )
        else:
            cursor = await self._db.execute(
                "SELECT seq, topic, source, ts, payload FROM events "
                "WHERE topic=? AND seq >= ? ORDER BY seq LIMIT ?",
                (topic, since_seq, limit),
            )
        rows = await cursor.fetchall()
        return [
            {
                "seq": r[0],
                "topic": r[1],
                "source": r[2],
                "ts": r[3],
                "payload": json.loads(r[4]),
            }
            for r in rows
        ]

    async def get_max_seq(self) -> int:
        assert self._db is not None
        cursor = await self._db.execute("SELECT COALESCE(MAX(seq), 0) FROM events")
        row = await cursor.fetchone()
        return row[0] if row else 0

    async def close(self) -> None:
        self._closed = True
        if self._writer_task and not self._writer_task.done():
            self._writer_task.cancel()
            try:
                await self._writer_task
            except asyncio.CancelledError:
                pass
        if self._db:
            await self._db.close()
