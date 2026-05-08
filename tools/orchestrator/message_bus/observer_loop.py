"""v11 Phase C — Subscribe-based Observer Loop.

v10.3 의 polling 기반 orchestrator_monitor.py 를 push 기반으로 재구성.
broker 가 새 event publish 시 즉시 wake (long-poll). idle 시 무 cost.

Usage:
  python -m tools.orchestrator.message_bus.observer_loop
  python -m tools.orchestrator.message_bus.observer_loop --topic stream:S1
  python -m tools.orchestrator.message_bus.observer_loop --print-only

Latency: v10.3 평균 15s polling vs v11 ~50ms push.
"""
from __future__ import annotations

import argparse
import asyncio
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client

URL = "http://127.0.0.1:7383/mcp"


def _format_event(event):
    """Render single event line."""
    seq = event.get("seq", "?")
    topic = event.get("topic", "?")
    source = event.get("source", "?")
    ts = event.get("ts", "?")[:19]
    payload = event.get("payload", {})

    # Status badge for stream:S{N}
    if topic.startswith("stream:"):
        status = payload.get("status", "?")
        badge = {
            "DONE": "✅",
            "IN_PROGRESS": "🔄",
            "BLOCKED": "🚫",
        }.get(status, "•")
        return f"  {badge} seq={seq:4d} {ts} {source:12s} → {topic:20s} status={status}"

    # Cascade event
    if topic.startswith("cascade:"):
        impacted = len(payload.get("impacted", []))
        return f"  📡 seq={seq:4d} {ts} {source:12s} → {topic} ({impacted} docs)"

    # Default
    return f"  • seq={seq:4d} {ts} {source:12s} → {topic}"


async def observer_loop(topic: str = "*", print_only: bool = False, max_iter: int | None = None):
    """Subscribe loop. push 즉시 wake, idle 무 cost.

    Args:
        topic: 구독 토픽 (default "*" 모두)
        print_only: 단순 출력 (handler 없음)
        max_iter: 테스트용 최대 iteration (None = 무한)
    """
    last_seq = 0
    iter_count = 0
    start_ts = datetime.now(timezone.utc)

    print(f"=" * 70)
    print(f"v11 Observer Loop — push-based")
    print(f"  url:    {URL}")
    print(f"  topic:  {topic}")
    print(f"  start:  {start_ts.isoformat()}")
    print(f"=" * 70)

    async with streamablehttp_client(URL) as (read, write, _gs):
        async with ClientSession(read, write) as session:
            await session.initialize()
            while True:
                if max_iter and iter_count >= max_iter:
                    break

                result = await session.call_tool("subscribe", {
                    "topic": topic,
                    "from_seq": last_seq,
                    "timeout_sec": 30,
                })

                if not result.content:
                    iter_count += 1
                    continue

                data = json.loads(result.content[0].text)
                events = data.get("events", [])
                mode = data.get("mode", "?")

                for event in events:
                    last_seq = max(last_seq, event["seq"])
                    if print_only:
                        print(_format_event(event))
                    else:
                        _handle_event(event)

                if mode == "timeout" and not print_only:
                    # idle — 30s 동안 변화 없음. silent (long-poll 재시작)
                    pass
                iter_count += 1


def _handle_event(event):
    """이벤트 dispatcher. v10.3 의 render_dashboard 후속."""
    topic = event.get("topic", "")

    # Stream DONE → 의존 stream unblock signal
    if topic.startswith("stream:") and event.get("payload", {}).get("status") == "DONE":
        sid = topic.replace("stream:", "")
        pr = event.get("payload", {}).get("pr", "?")
        print(f"✅ {sid} DONE (PR #{pr}) — dependent streams unblock")
        return

    # Cascade fan-out → 영향 받는 stream 알림
    if topic.startswith("cascade:"):
        file_path = topic.replace("cascade:", "")
        impacted = event.get("payload", {}).get("impacted", [])
        editor = event.get("payload", {}).get("editor", "?")
        print(f"📡 cascade by {editor}: {file_path} → {len(impacted)} docs")
        return

    # 그 외 → 단순 출력
    print(_format_event(event))


def main():
    p = argparse.ArgumentParser(description="v11 push-based observer loop")
    p.add_argument("--topic", default="*", help="topic to subscribe (default: *)")
    p.add_argument("--print-only", action="store_true",
                   help="single-line print mode (no handler)")
    p.add_argument("--max-iter", type=int, default=None,
                   help="max iterations (default: infinite)")
    args = p.parse_args()

    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

    try:
        asyncio.run(observer_loop(
            topic=args.topic,
            print_only=args.print_only,
            max_iter=args.max_iter,
        ))
    except KeyboardInterrupt:
        print("\n[observer] stopped by user")


if __name__ == "__main__":
    main()
