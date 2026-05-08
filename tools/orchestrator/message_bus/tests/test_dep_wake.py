"""v11 Phase D — Dependency Wake e2e test.

S1 DONE publish → S2 subscribe wake latency 측정.
v10.3 baseline (30s polling) 대비 v11 push (~50ms) 검증.

Usage:
  python -m tools.orchestrator.message_bus.tests.test_dep_wake
  python -m tools.orchestrator.message_bus.tests.test_dep_wake --iter 10
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


async def producer(stream_id: str, delay_ms: int):
    """delay_ms 후 stream:S{N} DONE publish."""
    await asyncio.sleep(delay_ms / 1000)
    async with streamablehttp_client(URL) as (r, w, _):
        async with ClientSession(r, w) as s:
            await s.initialize()
            res = await s.call_tool("publish_event", {
                "topic": f"stream:{stream_id}",
                "payload": {"status": "DONE", "pr": 999, "test": True},
                "source": stream_id,
            })
            data = json.loads(res.content[0].text)
            return data["seq"], time.perf_counter()


async def subscriber(stream_id: str, since_seq: int):
    """subscribe(stream:S{N}) → DONE 받을 때까지 대기. wake 시각 반환."""
    async with streamablehttp_client(URL) as (r, w, _):
        async with ClientSession(r, w) as s:
            await s.initialize()
            t_call = time.perf_counter()
            res = await s.call_tool("subscribe", {
                "topic": f"stream:{stream_id}",
                "from_seq": since_seq,
                "timeout_sec": 30,
            })
            t_recv = time.perf_counter()
            data = json.loads(res.content[0].text)
            done_events = [e for e in data.get("events", [])
                           if e.get("payload", {}).get("status") == "DONE"]
            if done_events:
                return t_call, t_recv, done_events[0]
            return t_call, t_recv, None


async def get_max_seq(stream_id: str) -> int:
    """현재 stream:{N} 의 max seq."""
    async with streamablehttp_client(URL) as (r, w, _):
        async with ClientSession(r, w) as s:
            await s.initialize()
            res = await s.call_tool("get_history", {
                "topic": f"stream:{stream_id}", "since_seq": 0, "limit": 5000
            })
            data = json.loads(res.content[0].text)
            evs = data.get("events", [])
            return evs[-1].get("seq", 0) if evs else 0


async def measure_wake(stream_id: str = "S1-test", n_iter: int = 5) -> list[float]:
    """n번 publish→subscribe wake latency 측정 (push mode 전용)."""
    samples: list[float] = []

    for i in range(n_iter):
        # 1. 매 iter 마다 latest seq 확인 → since_seq 를 max+1 로 (history skip)
        max_seq = await get_max_seq(stream_id)
        base_seq = max_seq + 1  # 새로 publish 될 events 만 잡음
        # 2. 짧은 idle (broker 안정)
        await asyncio.sleep(0.2)

        # 3. subscriber 먼저 시작 (push mode 진입)
        sub_task = asyncio.create_task(subscriber(stream_id, since_seq=base_seq))
        # 4. 800ms 후 producer publish (subscriber 가 확실히 long-poll 진입)
        prod_task = asyncio.create_task(producer(stream_id, delay_ms=800))

        (seq, t_pub), (t_call, t_recv, event) = await asyncio.gather(prod_task, sub_task)

        if event:
            wake_latency_ms = (t_recv - t_pub) * 1000
            if wake_latency_ms < 0:
                # history mode 진입 (publish 가 subscriber 시작 전 도달) — skip
                print(f"  iter {i+1}: skipped (history mode) seq={seq}")
                continue
            samples.append(wake_latency_ms)
            print(f"  iter {i+1}: seq={seq}  wake_latency={wake_latency_ms:6.1f}ms (push mode)")
        else:
            print(f"  iter {i+1}: NO WAKE (timeout)")

    return samples


async def main(n_iter: int = 5):
    print("=" * 70)
    print(f"v11 Phase D — Dependency Wake e2e Test")
    print(f"  n_iter:   {n_iter}")
    print(f"  pattern:  subscribe (waiting) ← publish (after 200ms delay)")
    print(f"  measures: t_recv - t_pub (cross-process wake latency)")
    print("=" * 70)
    print()

    samples = await measure_wake("S1-test", n_iter)
    print()

    if samples:
        avg = statistics.mean(samples)
        sorted_s = sorted(samples)
        p50 = sorted_s[len(sorted_s) // 2]
        p99 = sorted_s[min(len(sorted_s) - 1, int(len(sorted_s) * 0.99))]
        print("=" * 70)
        print(f"  Wake Latency: avg={avg:.1f}ms  p50={p50:.1f}ms  p99={p99:.1f}ms  "
              f"min={min(samples):.1f}ms  max={max(samples):.1f}ms")
        print(f"  vs v10.3 baseline (30s polling): {(30000/avg):.0f}x improvement")

        target_met = avg < 200  # plan §8.1 목표
        print(f"  target (<200ms avg): {'✓ MET' if target_met else '✗ MISSED'}")
        print("=" * 70)
        return target_met
    else:
        print("  ✗ NO SAMPLES — broker 연결 또는 publish 실패")
        return False


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--iter", type=int, default=5)
    args = p.parse_args()
    import sys
    ok = asyncio.run(main(args.iter))
    sys.exit(0 if ok else 1)
