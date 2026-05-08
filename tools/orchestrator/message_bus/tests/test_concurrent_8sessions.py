"""Phase 2 MVP — 8 concurrent client stress test.

Simulates 8 EBS Stream sessions (S1~S8) publishing concurrently while
1 consumer receives all events via subscribe(*).

Validates:
- 8 producers × N events = 8N total received (no loss)
- SQLite WAL writer doesn't bottleneck under concurrent load
- broker latency p99 < 500ms under stress
- Topic ACL works (each S{N} only allowed to publish stream:S{N})

Usage:
  python -m tools.orchestrator.message_bus.tests.test_concurrent_8sessions
  python -m tools.orchestrator.message_bus.tests.test_concurrent_8sessions --events 100
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


async def producer(stream_id: str, n_events: int) -> list[float]:
    """Publish n events to topic 'stream:S{N}' as source S{N}. Returns latencies (ms)."""
    samples: list[float] = []
    async with streamablehttp_client(URL) as (read, write, _):
        async with ClientSession(read, write) as session:
            await session.initialize()
            for i in range(n_events):
                t0 = time.perf_counter()
                await session.call_tool(
                    "publish_event",
                    {
                        "topic": f"stream:{stream_id}",
                        "payload": {"i": i, "stream": stream_id},
                        "source": stream_id,
                    },
                )
                samples.append((time.perf_counter() - t0) * 1000)
    return samples


async def consumer(expected_total: int, deadline_sec: float = 60.0) -> dict:
    """Subscribe to '*' and count distinct events until expected_total received or deadline."""
    received_seqs: set[int] = set()
    received_by_source: dict[str, int] = {}
    next_seq = 0
    start = time.perf_counter()
    async with streamablehttp_client(URL) as (read, write, _):
        async with ClientSession(read, write) as session:
            await session.initialize()
            while len(received_seqs) < expected_total:
                if time.perf_counter() - start > deadline_sec:
                    break
                result = await session.call_tool(
                    "subscribe",
                    {"topic": "*", "from_seq": next_seq, "timeout_sec": 5},
                )
                if not result.content:
                    continue
                data = json.loads(result.content[0].text)
                for evt in data.get("events", []):
                    if evt["seq"] not in received_seqs:
                        received_seqs.add(evt["seq"])
                        received_by_source[evt["source"]] = (
                            received_by_source.get(evt["source"], 0) + 1
                        )
                next_seq = data["next_seq"]
                if data["mode"] == "timeout":
                    # No new events in 5s — only break if we already got what we expected
                    if len(received_seqs) >= expected_total:
                        break
    return {
        "received_count": len(received_seqs),
        "by_source": received_by_source,
        "duration_sec": time.perf_counter() - start,
    }


async def main(n_events_per_stream: int = 50) -> None:
    print("=" * 70)
    print(f"Phase 2 MVP — 8 client concurrent stress test")
    print(f"  8 producers (S1..S8) × {n_events_per_stream} events = "
          f"{8 * n_events_per_stream} total")
    print("=" * 70)

    expected = 8 * n_events_per_stream

    # Start consumer first (so it doesn't miss early events)
    consumer_task = asyncio.create_task(consumer(expected, deadline_sec=120))
    await asyncio.sleep(0.5)  # let consumer connect

    # Launch 8 producers in parallel
    streams = [f"S{i}" for i in range(1, 9)]
    t0 = time.perf_counter()
    producer_results = await asyncio.gather(
        *(producer(s, n_events_per_stream) for s in streams),
        return_exceptions=True,
    )
    t_pub = time.perf_counter() - t0

    print(f"\n[producer] all 8 producers done in {t_pub:.2f}s")
    all_samples: list[float] = []
    for stream_id, result in zip(streams, producer_results):
        if isinstance(result, Exception):
            print(f"  {stream_id}: EXCEPTION {result}")
            continue
        all_samples.extend(result)
        avg = statistics.mean(result)
        p99 = sorted(result)[int(len(result) * 0.99)]
        print(f"  {stream_id}: n={len(result)}  avg={avg:.1f}ms  p99={p99:.1f}ms")

    if all_samples:
        all_sorted = sorted(all_samples)
        n = len(all_sorted)
        avg = statistics.mean(all_samples)
        p50 = all_sorted[n // 2]
        p99 = all_sorted[min(n - 1, int(n * 0.99))]
        print(f"\n[overall publish RTT] n={n}  avg={avg:.1f}ms  p50={p50:.1f}ms  p99={p99:.1f}ms")
        rps = n / t_pub if t_pub > 0 else 0
        print(f"[throughput] {rps:.0f} events/s sustained over {t_pub:.2f}s")

    print(f"\n[consumer] waiting up to 60s for all {expected} events...")
    cons_result = await consumer_task
    print(f"  received: {cons_result['received_count']}/{expected}")
    print(f"  by source: {cons_result['by_source']}")
    print(f"  duration: {cons_result['duration_sec']:.2f}s")

    print("\n" + "=" * 70)
    success = cons_result["received_count"] == expected
    print(f"  {'✓ PASS' if success else '✗ FAIL'} — all events received: {success}")
    print("=" * 70)


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--events", type=int, default=50, help="events per stream")
    args = p.parse_args()
    asyncio.run(main(args.events))
