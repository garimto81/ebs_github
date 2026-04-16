"""Distributed lock — Phase 1: in-process asyncio.Lock.

Phase 3 will swap to Redis SET NX EX with identical interface.
"""
import asyncio


class LockUnavailableError(Exception):
    """Raised when lock cannot be acquired after retries."""

    def __init__(self, key: str):
        self.key = key
        super().__init__(f"Lock unavailable: {key}")


class DistributedLock:
    """Phase 1: in-process asyncio lock with fencing tokens.

    Phase 3: Redis SET NX EX (same interface).
    """

    _RETRY_DELAYS = (0.01, 0.05, 0.2)  # 10ms, 50ms, 200ms

    def __init__(self):
        self._locks: dict[str, asyncio.Lock] = {}
        self._owners: dict[str, str] = {}  # key → fencing_token
        self._counter: int = 0

    def _get_lock(self, key: str) -> asyncio.Lock:
        if key not in self._locks:
            self._locks[key] = asyncio.Lock()
        return self._locks[key]

    async def acquire(self, key: str, ttl: int = 10) -> str:
        """Acquire lock. Returns fencing_token. Raises LockUnavailableError."""
        lock = self._get_lock(key)

        for i, delay in enumerate(self._RETRY_DELAYS):
            acquired = lock.locked()
            if not acquired:
                try:
                    # Try non-blocking acquire
                    if lock.locked():
                        raise RuntimeError("busy")
                    await asyncio.wait_for(lock.acquire(), timeout=delay)
                    self._counter += 1
                    token = str(self._counter)
                    self._owners[key] = token
                    return token
                except (asyncio.TimeoutError, RuntimeError):
                    if i < len(self._RETRY_DELAYS) - 1:
                        await asyncio.sleep(delay)
                    continue
            else:
                if i < len(self._RETRY_DELAYS) - 1:
                    await asyncio.sleep(delay)
                continue

        raise LockUnavailableError(key)

    async def release(self, key: str, token: str) -> bool:
        """Release lock if token matches. Returns True if released."""
        if key not in self._locks:
            return False
        if self._owners.get(key) != token:
            return False
        lock = self._locks[key]
        if lock.locked():
            lock.release()
            del self._owners[key]
            return True
        return False

    async def extend(self, key: str, token: str, ttl: int) -> bool:
        """Extend lock TTL. Phase 1: no-op (in-process has no TTL expiry)."""
        return self._owners.get(key) == token
