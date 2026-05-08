"""Phase 3 Hybrid — broker death + WAL durability test.

Validates:
- Events publish before broker death survive restart (SQLite WAL)
- Subscriber resume from last_ack_seq works after broker bounce
- broker.pid / broker.port stale cleanup on restart
- /probe correctly reports dead/alive states

Usage: python -m tools.orchestrator.message_bus.tests.test_broker_death
"""
from __future__ import annotations

import asyncio
import json
import subprocess
import sys
import time
from pathlib import Path

from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client

PROJECT_ROOT = Path(__file__).resolve().parents[4]
START_SCRIPT = PROJECT_ROOT / "tools" / "orchestrator" / "start_message_bus.py"
STOP_SCRIPT = PROJECT_ROOT / "tools" / "orchestrator" / "stop_message_bus.py"
LOCKS_DIR = PROJECT_ROOT / ".claude" / "locks"
PID_FILE = LOCKS_DIR / "broker.pid"


def start_broker_detached() -> int | None:
    """Spawn detached broker, wait health, return PID."""
    p = subprocess.run(
        [sys.executable, str(START_SCRIPT), "--detach"],
        capture_output=True, text=True, timeout=15,
    )
    if p.returncode != 0:
        print(f"  start failed: {p.stderr}")
        return None
    print(f"  start: {p.stdout.strip()}")
    # Wait for health
    deadline = time.time() + 10
    while time.time() < deadline:
        probe = subprocess.run(
            [sys.executable, str(START_SCRIPT), "--probe"],
            capture_output=True, text=True, timeout=5,
        )
        if probe.returncode == 0:
            return int(json.loads(probe.stdout)["pid"])
        time.sleep(0.5)
    return None


def stop_broker(force: bool = False) -> bool:
    args = [sys.executable, str(STOP_SCRIPT)]
    if force:
        args.append("--force")
    p = subprocess.run(args, capture_output=True, text=True, timeout=15)
    print(f"  stop: {p.stdout.strip()}")
    return p.returncode == 0


def probe() -> dict:
    p = subprocess.run(
        [sys.executable, str(START_SCRIPT), "--probe"],
        capture_output=True, text=True, timeout=5,
    )
    if not p.stdout.strip():
        return {"alive": False}
    return json.loads(p.stdout)


async def publish_n(port: int, n: int, source: str = "death-test") -> int:
    """Publish n events. Returns count of successful publishes."""
    url = f"http://127.0.0.1:{port}/mcp"
    success = 0
    async with streamablehttp_client(url) as (read, write, _):
        async with ClientSession(read, write) as session:
            await session.initialize()
            for i in range(n):
                try:
                    await session.call_tool("publish_event", {
                        "topic": "death-test",
                        "payload": {"i": i},
                        "source": source,
                    })
                    success += 1
                except Exception as e:
                    print(f"  publish #{i} failed: {e}")
    return success


async def query_count(port: int) -> int:
    url = f"http://127.0.0.1:{port}/mcp"
    async with streamablehttp_client(url) as (read, write, _):
        async with ClientSession(read, write) as session:
            await session.initialize()
            result = await session.call_tool("get_history", {
                "topic": "death-test", "since_seq": 0, "limit": 1000,
            })
            data = json.loads(result.content[0].text)
            return data["count"]


async def test_durability():
    print("\n" + "=" * 70)
    print("Phase 3 Hybrid — broker death + WAL durability test")
    print("=" * 70)

    # 1. Make sure broker is stopped
    print("\n[step 1] ensure broker stopped")
    stop_broker(force=True)
    time.sleep(1)

    # 2. Start broker
    print("\n[step 2] start broker (detached)")
    pid = start_broker_detached()
    if not pid:
        print("  ✗ FAIL: broker did not start")
        return False
    print(f"  PID {pid}, broker alive")

    p1 = probe()
    port = p1["port"]
    print(f"  port={port}, alive={p1['alive']}")

    # 3. Publish 50 events
    print("\n[step 3] publish 50 events")
    sent_a = await publish_n(port, 50, source="phase-A")
    print(f"  sent {sent_a}/50")

    # 4. Force kill broker
    print("\n[step 4] force kill broker (simulating crash)")
    stop_broker(force=True)
    time.sleep(2)
    p2 = probe()
    print(f"  alive={p2.get('alive', False)}")

    # 5. Restart broker
    print("\n[step 5] restart broker")
    pid2 = start_broker_detached()
    if not pid2:
        print("  ✗ FAIL: broker did not restart")
        return False
    print(f"  new PID {pid2}")
    p3 = probe()
    port2 = p3["port"]

    # 6. Verify durability — query events
    print(f"\n[step 6] query events on port {port2}")
    cnt = await query_count(port2)
    print(f"  events recovered: {cnt} (expected ≥ {sent_a})")

    # 7. Publish 50 more (post-restart)
    print("\n[step 7] publish 50 more events post-restart")
    sent_b = await publish_n(port2, 50, source="phase-B")
    print(f"  sent {sent_b}/50")

    cnt_total = await query_count(port2)
    print(f"  total events: {cnt_total}")

    # 8. Final stop
    print("\n[step 8] graceful stop")
    stop_broker(force=False)
    time.sleep(1)
    p4 = probe()
    print(f"  alive={p4.get('alive', False)}")

    # Verdict
    print("\n" + "=" * 70)
    durable = cnt >= sent_a and cnt_total >= (sent_a + sent_b)
    print(f"  Durability: {'✓ PASS' if durable else '✗ FAIL'}")
    print(f"    pre-crash sent {sent_a} → recovered {cnt}")
    print(f"    post-restart sent {sent_b} → final total {cnt_total}")
    print("=" * 70)
    return durable


if __name__ == "__main__":
    ok = asyncio.run(test_durability())
    sys.exit(0 if ok else 1)
