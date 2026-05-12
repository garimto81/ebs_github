"""Phase 2 MVP — advisory lock contention test.

Validates R6 (cascade race condition mitigation):
- 8 clients race to acquire same lock → exactly 1 wins
- After release, next client can acquire
- Expired lock auto-replaced
- TTL respected

Usage: python -m tools.orchestrator.message_bus.tests.test_lock_contention
"""
from __future__ import annotations

import asyncio
import json
import time

from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client

URL = "http://127.0.0.1:7383/mcp"


async def try_acquire(holder: str, resource: str, ttl_sec: int = 30) -> dict:
    async with streamablehttp_client(URL) as (read, write, _):
        async with ClientSession(read, write) as session:
            await session.initialize()
            result = await session.call_tool(
                "acquire_lock",
                {"resource": resource, "holder": holder, "ttl_sec": ttl_sec},
            )
            return json.loads(result.content[0].text)


async def try_release(holder: str, resource: str) -> dict:
    async with streamablehttp_client(URL) as (read, write, _):
        async with ClientSession(read, write) as session:
            await session.initialize()
            result = await session.call_tool(
                "release_lock", {"resource": resource, "holder": holder}
            )
            return json.loads(result.content[0].text)


async def test_8_concurrent_acquire():
    """8 clients race for the same lock — exactly 1 wins."""
    print("\n[test 1] 8 concurrent acquire on same resource")
    resource = "cascade:Lobby.md"
    results = await asyncio.gather(
        *(try_acquire(f"S{i}", resource, ttl_sec=10) for i in range(1, 9))
    )
    winners = [r for r in results if r["acquired"]]
    losers = [r for r in results if not r["acquired"]]
    print(f"  acquired by: {[r['holder'] for r in winners]}")
    print(f"  rejected: {len(losers)} ({[r['holder'] for r in losers]} attempted)")
    assert len(winners) == 1, f"Expected 1 winner, got {len(winners)}"
    print(f"  ✓ PASS — exactly 1 winner")
    # Cleanup
    await try_release(winners[0]["holder"], resource)


async def test_release_then_acquire():
    """After release, next client can acquire."""
    print("\n[test 2] release + reacquire")
    resource = "cascade:Command_Center.md"
    r1 = await try_acquire("S1", resource, ttl_sec=60)
    assert r1["acquired"], "S1 should acquire fresh lock"
    print(f"  S1 acquired: {r1}")
    r2_blocked = await try_acquire("S2", resource, ttl_sec=60)
    assert not r2_blocked["acquired"], "S2 should be blocked"
    print(f"  S2 blocked (held by {r2_blocked['holder']})")
    rel = await try_release("S1", resource)
    assert rel["released"], "S1 release should succeed"
    print(f"  S1 released: {rel}")
    r3 = await try_acquire("S2", resource, ttl_sec=60)
    assert r3["acquired"], "S2 should acquire after release"
    print(f"  S2 acquired after release: {r3}")
    print(f"  ✓ PASS — release-reacquire works")
    await try_release("S2", resource)


async def test_renew():
    """Same holder reacquiring renews TTL."""
    print("\n[test 3] same holder renew")
    resource = "cascade:BO_PRD.md"
    r1 = await try_acquire("S1", resource, ttl_sec=60)
    assert r1["acquired"] and not r1["renewed"], "first acquire is not renew"
    r2 = await try_acquire("S1", resource, ttl_sec=60)
    assert r2["acquired"] and r2["renewed"], "second acquire by same holder is renew"
    print(f"  ✓ PASS — renew flag works")
    await try_release("S1", resource)


async def test_ttl_expiry():
    """Expired lock can be acquired by another holder."""
    print("\n[test 4] TTL expiry (3s)")
    resource = "cascade:test_ttl.md"
    r1 = await try_acquire("S1", resource, ttl_sec=2)
    assert r1["acquired"], "fresh acquire"
    print(f"  S1 acquired with 2s TTL")
    print(f"  waiting 2.5s for expiry...")
    await asyncio.sleep(2.5)
    r2 = await try_acquire("S2", resource, ttl_sec=10)
    assert r2["acquired"], f"S2 should acquire after S1 expired, got: {r2}"
    print(f"  S2 acquired after expiry: {r2}")
    print(f"  ✓ PASS — TTL expiry works")
    await try_release("S2", resource)


async def main():
    print("=" * 70)
    print("Phase 2 MVP — Advisory Lock Contention Test (R6)")
    print("=" * 70)
    t0 = time.perf_counter()
    await test_8_concurrent_acquire()
    await test_release_then_acquire()
    await test_renew()
    await test_ttl_expiry()
    elapsed = time.perf_counter() - t0
    print(f"\n{'=' * 70}")
    print(f"  All 4 tests passed in {elapsed:.1f}s")
    print(f"{'=' * 70}")


if __name__ == "__main__":
    asyncio.run(main())
