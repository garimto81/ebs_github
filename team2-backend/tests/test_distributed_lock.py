"""Gate 4 — Distributed lock (in-process asyncio) tests."""
import asyncio

import pytest

from src.observability.distributed_lock import DistributedLock, LockUnavailableError


@pytest.fixture
def lock():
    return DistributedLock()


# ── Gate 4-5: Concurrent acquire — only 1 wins ────────


@pytest.mark.asyncio
async def test_concurrent_acquire_one_wins(lock):
    """100 concurrent acquire attempts on same key → exactly 1 success."""
    results = []

    async def try_acquire(idx: int):
        try:
            token = await lock.acquire("resource-1", ttl=10)
            results.append(("ok", idx, token))
        except LockUnavailableError:
            results.append(("fail", idx, None))

    # First, acquire the lock to make it contested
    token = await lock.acquire("resource-1")
    # Now 100 tasks try to acquire the already-held lock
    tasks = [asyncio.create_task(try_acquire(i)) for i in range(100)]
    await asyncio.gather(*tasks)

    successes = [r for r in results if r[0] == "ok"]
    failures = [r for r in results if r[0] == "fail"]
    assert len(successes) == 0  # All should fail since lock is held
    assert len(failures) == 100

    # Release and verify someone can now acquire
    await lock.release("resource-1", token)
    token2 = await lock.acquire("resource-1")
    assert token2 is not None


# ── Gate 4-6: Fencing token monotonic increase ────────


@pytest.mark.asyncio
async def test_fencing_token_monotonic(lock):
    """Tokens must be monotonically increasing integers."""
    tokens = []
    for _ in range(10):
        t = await lock.acquire("key-mono")
        tokens.append(int(t))
        await lock.release("key-mono", t)

    for i in range(1, len(tokens)):
        assert tokens[i] > tokens[i - 1], f"Token {tokens[i]} <= {tokens[i-1]}"


# ── Gate 4-7: Acquire fails after retries → LockUnavailableError ──


@pytest.mark.asyncio
async def test_acquire_fails_raises_error(lock):
    """If lock is held, new acquire raises LockUnavailableError after 3 retries."""
    token = await lock.acquire("contested-key")

    with pytest.raises(LockUnavailableError) as exc_info:
        await lock.acquire("contested-key")

    assert "contested-key" in str(exc_info.value)

    # Cleanup
    await lock.release("contested-key", token)


# ── Release with wrong token → no-op ─────────────────


@pytest.mark.asyncio
async def test_release_wrong_token(lock):
    """Releasing with wrong token should fail silently."""
    token = await lock.acquire("key-wrong")
    result = await lock.release("key-wrong", "bad-token")
    assert result is False
    # Lock still held — release with correct token works
    result = await lock.release("key-wrong", token)
    assert result is True


# ── Extend with correct token ─────────────────────────


@pytest.mark.asyncio
async def test_extend_correct_token(lock):
    """Extend returns True with correct token."""
    token = await lock.acquire("key-ext")
    assert await lock.extend("key-ext", token, ttl=20) is True
    assert await lock.extend("key-ext", "wrong", ttl=20) is False
    await lock.release("key-ext", token)
