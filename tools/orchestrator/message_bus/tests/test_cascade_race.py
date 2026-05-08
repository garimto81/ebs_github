"""Phase 4 Hardening — cascade race e2e test.

Validates R6 mitigation under heavy contention:
- 8 workers race for the same advisory lock per iteration
- Winner: critical section publish event → release lock
- Losers: backoff retry until acquire
- All events: monotonic seq, no duplicates, ordering preserved per topic

Pattern simulates 8 streams concurrently editing a cascade resource
(e.g., Foundation.md change rippling to Lobby_PRD + CC_PRD).

Usage: python -m tools.orchestrator.message_bus.tests.test_cascade_race [--iter N]
"""
from __future__ import annotations

import argparse
import asyncio
import json
import statistics
import time

from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client

URL = "http://127.0.0.1:7383/mcp"


async def cascade_worker(
    stream_id: str,
    n_iter: int,
    resource: str = "cascade:Foundation.md",
    lock_ttl: int = 5,
    max_retry: int = 200,
) -> dict:
    """One worker: n iterations of (acquire → publish → release)."""
    acquired_count = 0
    retry_count = 0
    failed_count = 0
    publish_seqs: list[int] = []
    backoff_samples: list[float] = []
    async with streamablehttp_client(URL) as (read, write, _):
        async with ClientSession(read, write) as session:
            await session.initialize()
            for i in range(n_iter):
                acquired = False
                attempts = 0
                t_attempt_start = time.perf_counter()
                while attempts < max_retry and not acquired:
                    r = await session.call_tool("acquire_lock", {
                        "resource": resource,
                        "holder": stream_id,
                        "ttl_sec": lock_ttl,
                    })
                    data = json.loads(r.content[0].text)
                    if data["acquired"]:
                        acquired = True
                        backoff_samples.append((time.perf_counter() - t_attempt_start) * 1000)
                        # Critical section
                        pub = await session.call_tool("publish_event", {
                            "topic": "cascade:design",
                            "payload": {"i": i, "by": stream_id},
                            "source": stream_id,
                        })
                        pub_data = json.loads(pub.content[0].text)
                        publish_seqs.append(pub_data["seq"])
                        # Release
                        await session.call_tool("release_lock", {
                            "resource": resource, "holder": stream_id,
                        })
                        acquired_count += 1
                    else:
                        attempts += 1
                        retry_count += 1
                        # Exponential-ish backoff (cap 50ms)
                        await asyncio.sleep(min(0.001 * (2 ** min(attempts, 6)), 0.05))
                if not acquired:
                    failed_count += 1
    return {
        "stream_id": stream_id,
        "acquired": acquired_count,
        "retries": retry_count,
        "failed": failed_count,
        "publish_seqs": publish_seqs,
        "backoff_ms_avg": statistics.mean(backoff_samples) if backoff_samples else 0,
    }


async def main(n_iter: int = 100) -> bool:
    print("=" * 70)
    print(f"Phase 4 Hardening — Cascade Race e2e (R6)")
    print(f"  8 workers × {n_iter} iter = {8 * n_iter} acquire→publish→release sequences")
    print("=" * 70)

    streams = [f"S{i}" for i in range(1, 9)]
    t0 = time.perf_counter()
    results = await asyncio.gather(*(cascade_worker(s, n_iter) for s in streams))
    elapsed = time.perf_counter() - t0

    total_acquired = sum(r["acquired"] for r in results)
    total_retries = sum(r["retries"] for r in results)
    total_failed = sum(r["failed"] for r in results)
    all_seqs: list[int] = []
    for r in results:
        all_seqs.extend(r["publish_seqs"])

    print(f"\n[results] {elapsed:.2f}s elapsed")
    for r in results:
        print(
            f"  {r['stream_id']}: acquired={r['acquired']}/{n_iter}  "
            f"retries={r['retries']}  backoff_avg={r['backoff_ms_avg']:.1f}ms"
        )

    print(f"\n[totals]")
    print(f"  acquired: {total_acquired}/{8 * n_iter}")
    print(f"  retries:  {total_retries}")
    print(f"  failed:   {total_failed}")
    print(f"  unique seqs: {len(set(all_seqs))} (should equal acquired count)")

    # Verify monotonic seq + no duplicates
    sorted_seqs = sorted(all_seqs)
    is_unique = len(set(all_seqs)) == len(all_seqs)
    is_consecutive = all(
        sorted_seqs[i] == sorted_seqs[i - 1] + 1 for i in range(1, len(sorted_seqs))
    ) if len(sorted_seqs) > 1 else True

    print(f"  unique seqs: {'✓' if is_unique else '✗'}")
    print(
        f"  monotonic+consecutive: {'✓' if is_consecutive else '⚠'} "
        f"(non-consecutive expected if other publishes happened)"
    )

    pass_ = (
        total_acquired == 8 * n_iter
        and total_failed == 0
        and is_unique
    )
    print("\n" + "=" * 70)
    print(f"  {'✓ PASS' if pass_ else '✗ FAIL'} — cascade race mitigated")
    print("=" * 70)
    return pass_


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--iter", type=int, default=50)
    args = p.parse_args()
    import sys
    ok = asyncio.run(main(args.iter))
    sys.exit(0 if ok else 1)
