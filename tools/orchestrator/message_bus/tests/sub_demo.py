"""PoC subscriber demo. Long-polls subscribe tool.

Usage:
  python -m tools.orchestrator.message_bus.tests.sub_demo --topic test
"""
from __future__ import annotations

import argparse
import asyncio
import time

from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client


async def subscribe_loop(url: str, topic: str, max_events: int) -> None:
    received = 0
    next_seq = 0
    async with streamablehttp_client(url) as (read, write, get_session_id):
        async with ClientSession(read, write) as session:
            await session.initialize()
            print(f"[sub] connected to {url}, topic={topic}")
            while received < max_events:
                t0 = time.perf_counter()
                result = await session.call_tool(
                    "subscribe",
                    {"topic": topic, "from_seq": next_seq, "timeout_sec": 30},
                )
                t1 = time.perf_counter()
                if not result.content:
                    print("[sub] empty content")
                    continue
                import json as _json

                data = _json.loads(result.content[0].text)
                if data.get("mode") == "timeout":
                    print(f"[sub] timeout (no events in 30s, t={t1-t0:.1f}s)")
                    continue
                for evt in data["events"]:
                    received += 1
                    print(
                        f"[sub] mode={data['mode']} seq={evt['seq']} "
                        f"source={evt['source']} latency={(t1-t0)*1000:.1f}ms "
                        f"payload={evt['payload']}"
                    )
                next_seq = data["next_seq"]
    print(f"[sub] done. received={received}")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--url", default="http://127.0.0.1:7383/mcp")
    p.add_argument("--topic", default="test")
    p.add_argument("--max-events", type=int, default=1)
    args = p.parse_args()
    asyncio.run(subscribe_loop(args.url, args.topic, args.max_events))


if __name__ == "__main__":
    main()
