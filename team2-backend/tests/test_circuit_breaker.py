"""Gate 4 — Circuit Breaker FSM tests."""
import asyncio

import pytest

from src.observability.circuit_breaker import CircuitBreaker, CircuitOpenError


@pytest.fixture
def cb():
    """Circuit breaker: 50% failure ratio, window=20, open=0.3s (fast tests)."""
    return CircuitBreaker(failure_ratio=0.5, window_size=20, open_duration_s=0.3)


async def _success():
    return "ok"


async def _failure():
    raise RuntimeError("boom")


def _trip_open(cb: CircuitBreaker):
    """Helper: fill window with failures to trip OPEN. Synchronous setup."""
    # Directly manipulate internal state for deterministic setup
    for _ in range(cb.window_size):
        cb._record_failure()
    import time
    cb.state = "OPEN"
    cb._opened_at = time.monotonic()


# ── Gate 4-8: 20 calls, 10 failures → OPEN ────────────


@pytest.mark.asyncio
async def test_failures_trip_open(cb):
    """Window of 20: 10 success + 10 failure → ratio=0.5 → OPEN."""
    # 10 successes
    for _ in range(10):
        await cb.call(_success)
    assert cb.state == "CLOSED"

    # 10 failures
    for _ in range(10):
        try:
            await cb.call(_failure)
        except (RuntimeError, CircuitOpenError):
            pass

    assert cb.state == "OPEN"


# ── Gate 4-9: OPEN → wait → HALF_OPEN → success ──────


@pytest.mark.asyncio
async def test_open_to_half_open(cb):
    """After open_duration_s, state transitions to HALF_OPEN on next call."""
    _trip_open(cb)
    assert cb.state == "OPEN"

    # Wait for open duration
    await asyncio.sleep(0.35)

    # Next call should transition OPEN→HALF_OPEN→(success)→CLOSED
    result = await cb.call(_success)
    assert result == "ok"
    assert cb.state == "CLOSED"


# ── Gate 4-10: HALF_OPEN success → CLOSED ─────────────


@pytest.mark.asyncio
async def test_half_open_success_closes(cb):
    """Success during HALF_OPEN → CLOSED."""
    _trip_open(cb)
    await asyncio.sleep(0.35)

    result = await cb.call(_success)
    assert result == "ok"
    assert cb.state == "CLOSED"


# ── Gate 4-11: HALF_OPEN failure → OPEN again ─────────


@pytest.mark.asyncio
async def test_half_open_failure_reopens(cb):
    """Failure during HALF_OPEN → back to OPEN."""
    _trip_open(cb)
    await asyncio.sleep(0.35)

    with pytest.raises(RuntimeError):
        await cb.call(_failure)
    assert cb.state == "OPEN"


# ── Gate 4-12: State attribute readable ────────────────


@pytest.mark.asyncio
async def test_state_attribute(cb):
    """State is directly readable for monitoring/metrics."""
    assert cb.state == "CLOSED"
    _trip_open(cb)
    assert cb.state == "OPEN"
    assert isinstance(cb.state, str)


# ── CircuitOpenError during OPEN ──────────────────────


@pytest.mark.asyncio
async def test_circuit_open_rejects_calls(cb):
    """While OPEN, calls raise CircuitOpenError immediately."""
    _trip_open(cb)
    assert cb.state == "OPEN"

    with pytest.raises(CircuitOpenError):
        await cb.call(_success)
