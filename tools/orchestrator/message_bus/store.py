"""SQLite WAL event store with async single-writer queue.

Phase 1 PoC + Phase 2 MVP additions.
- events table (Phase 1)
- locks table (Phase 2 — advisory locks for cascade race)
- discover_peers query (Phase 2)
"""
from __future__ import annotations

import asyncio
import json
from datetime import datetime, timezone
from pathlib import Path

import aiosqlite


def _utcnow_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


class Store:
    """Async SQLite WAL store with single-writer queue pattern.

    All writes (events + locks) flow through a single asyncio Task to avoid
    SQLite WAL writer contention. Reads concurrent (WAL allows reader+writer).
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
        # Phase 2: advisory locks
        await self._db.execute(
            """CREATE TABLE IF NOT EXISTS locks (
                resource TEXT PRIMARY KEY,
                holder TEXT NOT NULL,
                acquired_at TEXT NOT NULL,
                expires_at TEXT NOT NULL
            )"""
        )
        await self._db.commit()
        self._writer_task = asyncio.create_task(self._writer_loop(), name="store-writer")

    # ─── events ─────────────────────────────────────────

    async def publish(self, topic: str, payload: dict, source: str) -> tuple[int, str]:
        """Enqueue a publish. Returns (seq, ts) once the writer commits."""
        ts = _utcnow_iso()
        future: asyncio.Future[int] = asyncio.get_event_loop().create_future()
        await self.write_queue.put(
            ("publish", (topic, source, ts, json.dumps(payload)), future)
        )
        seq = await future
        return seq, ts

    async def _writer_loop(self) -> None:
        assert self._db is not None
        while not self._closed:
            try:
                op, args, future = await self.write_queue.get()
            except asyncio.CancelledError:
                break
            try:
                if op == "publish":
                    topic, source, ts, payload_json = args
                    cursor = await self._db.execute(
                        "INSERT INTO events (topic, source, ts, payload) VALUES (?, ?, ?, ?)",
                        (topic, source, ts, payload_json),
                    )
                    await self._db.commit()
                    if not future.done():
                        future.set_result(cursor.lastrowid)
                elif op == "acquire_lock":
                    resource, holder, ttl_sec = args
                    result = await self._do_acquire_lock(resource, holder, ttl_sec)
                    if not future.done():
                        future.set_result(result)
                elif op == "release_lock":
                    resource, holder = args
                    result = await self._do_release_lock(resource, holder)
                    if not future.done():
                        future.set_result(result)
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

    # ─── peer discovery ─────────────────────────────────

    async def discover_peers(self) -> list[dict]:
        """Return list of distinct sources with last_seen + event_count."""
        assert self._db is not None
        cursor = await self._db.execute(
            "SELECT source, MAX(ts) AS last_seen, COUNT(*) AS event_count "
            "FROM events GROUP BY source ORDER BY last_seen DESC"
        )
        rows = await cursor.fetchall()
        return [
            {"source": r[0], "last_seen": r[1], "event_count": r[2]}
            for r in rows
        ]

    # ─── advisory locks (Phase 2 R6 mitigation) ─────────

    async def acquire_lock(self, resource: str, holder: str, ttl_sec: int) -> dict:
        """Try to acquire advisory lock. Returns {acquired, holder, expires_at}."""
        future: asyncio.Future[dict] = asyncio.get_event_loop().create_future()
        await self.write_queue.put(("acquire_lock", (resource, holder, ttl_sec), future))
        return await future

    async def release_lock(self, resource: str, holder: str) -> bool:
        """Release a lock. Returns True if released, False if not held by holder."""
        future: asyncio.Future[bool] = asyncio.get_event_loop().create_future()
        await self.write_queue.put(("release_lock", (resource, holder), future))
        return await future

    async def _do_acquire_lock(
        self, resource: str, holder: str, ttl_sec: int
    ) -> dict:
        assert self._db is not None
        now_iso = _utcnow_iso()
        from datetime import timedelta
        expires_at = (datetime.now(timezone.utc) + timedelta(seconds=ttl_sec)).isoformat()

        # Read existing
        cursor = await self._db.execute(
            "SELECT holder, expires_at FROM locks WHERE resource=?", (resource,)
        )
        row = await cursor.fetchone()

        if row is None:
            # New acquisition
            await self._db.execute(
                "INSERT INTO locks (resource, holder, acquired_at, expires_at) "
                "VALUES (?, ?, ?, ?)",
                (resource, holder, now_iso, expires_at),
            )
            await self._db.commit()
            return {"acquired": True, "holder": holder, "expires_at": expires_at, "renewed": False}

        existing_holder, existing_expires = row
        existing_expires_dt = datetime.fromisoformat(existing_expires)
        now_dt = datetime.now(timezone.utc)

        if existing_expires_dt <= now_dt or existing_holder == holder:
            # Expired OR same holder renewal → update
            await self._db.execute(
                "UPDATE locks SET holder=?, acquired_at=?, expires_at=? WHERE resource=?",
                (holder, now_iso, expires_at, resource),
            )
            await self._db.commit()
            return {
                "acquired": True,
                "holder": holder,
                "expires_at": expires_at,
                "renewed": existing_holder == holder,
            }

        # Held by someone else, not expired
        return {
            "acquired": False,
            "holder": existing_holder,
            "expires_at": existing_expires,
            "renewed": False,
        }

    async def _do_release_lock(self, resource: str, holder: str) -> bool:
        assert self._db is not None
        cursor = await self._db.execute(
            "DELETE FROM locks WHERE resource=? AND holder=?", (resource, holder)
        )
        await self._db.commit()
        return cursor.rowcount > 0

    # ─── lifecycle ──────────────────────────────────────

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
