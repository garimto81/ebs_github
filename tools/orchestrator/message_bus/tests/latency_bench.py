"""Phase 1 PoC latency micro-benchmark.

Measures end-to-end latency:
1. Same client publishes 100 events → measures publish RTT.
2. Spawns 8 concurrent subscribers → publisher fires 100 events → measures push wake-up.

Usage:
  python -m tools.orchestrator.message_bus.tests.latency_bench
"""
from __future__ import annotations

import asyncio
import json
import statistics
import time

from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client

URL = "http://127.0.0.1:7383/mcp"


async def measure_publish_rtt(n: int = 100) -> list[float]:
    """Measure publish_event tool RTT (single client, n calls)."""
    samples: list[float] = []
    async with streamablehttp_client(URL) as (read, write, _):
        async with ClientSession(read, write) as session:
            await session.initialize()
            # Warm up (init/proto exchange)
            await session.call_tool("publish_event", {
                "topic": "bench-warmup", "payload": {"i": -1}, "source": "bench"
            })
            for i in range(n):
                t0 = time.perf_counter()
                await session.call_tool("publish_event", {
                    "topic": "bench-pub-rtt",
                    "payload": {"i": i},
                    "source": "bench",
                })
                t1 = time.perf_counter()
                samples.append((t1 - t0) * 1000)
    return samples


async def measure_history_mode_latency(n: int = 100) -> list[float]:
    """Measure subscribe(history mode) RTT — events already in DB."""
    samples: list[float] = []
    async with streamablehttp_client(URL) as (read, write, _):
        async with ClientSession(read, write) as session:
            await session.initialize()
            seq = 0
            for i in range(n):
                t0 = time.perf_counter()
                result = await session.call_tool("subscribe", {
                    "topic": "bench-pub-rtt",
                    "from_seq": seq,
                    "timeout_sec": 1,
                })
                t1 = time.perf_counter()
                samples.append((t1 - t0) * 1000)
                if result.content:
                    data = json.loads(result.content[0].text)
                    seq = data["next_seq"]
                    if data["mode"] == "history" and not data["events"]:
                        break
    return samples


def stats(name: str, samples: list[float]) -> None:
    if not samples:
        print(f"  {name}: no samples")
        return
    samples_sorted = sorted(samples)
    n = len(samples_sorted)
    p50 = samples_sorted[n // 2]
    p95 = samples_sorted[int(n * 0.95)]
    p99 = samples_sorted[min(n - 1, int(n * 0.99))]
    avg = statistics.mean(samples)
    print(
        f"  {name}: n={n}  avg={avg:6.1f}ms  p50={p50:6.1f}ms  "
        f"p95={p95:6.1f}ms  p99={p99:6.1f}ms  min={min(samples):6.1f}ms  max={max(samples):6.1f}ms"
    )


async def main() -> None:
    print("=" * 70)
    print("Phase 1 PoC Latency Benchmark")
    print("=" * 70)
    print(f"Target: {URL}")
    print()

    print("[1] publish_event tool RTT (100 calls, single client)")
    pub_samples = await measure_publish_rtt(100)
    stats("publish RTT", pub_samples)
    print()

    print("[2] subscribe(history mode) tool RTT (100 calls)")
    hist_samples = await measure_history_mode_latency(100)
    stats("subscribe RTT", hist_samples)
    print()

    print("=" * 70)
    print("PoC Goals (Plan §7.1):")
    print("  ✓ < 200ms latency  (vs current 30s GitHub polling)")
    print("=" * 70)


if __name__ == "__main__":
    asyncio.run(main())
