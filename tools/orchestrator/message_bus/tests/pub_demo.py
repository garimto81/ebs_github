"""PoC publisher demo. Calls publish_event tool against running broker.

Usage:
  python -m tools.orchestrator.message_bus.tests.pub_demo \\
      --topic test --source S1 --payload '{"hello":"world"}'
"""
from __future__ import annotations

import argparse
import asyncio
import json
import sys
import time

from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client


async def publish(url: str, topic: str, source: str, payload: dict) -> None:
    t0 = time.perf_counter()
    async with streamablehttp_client(url) as (read, write, get_session_id):
        async with ClientSession(read, write) as session:
            await session.initialize()
            t_init = time.perf_counter()
            result = await session.call_tool(
                "publish_event",
                {"topic": topic, "payload": payload, "source": source},
            )
            t_done = time.perf_counter()
    init_ms = (t_init - t0) * 1000
    pub_ms = (t_done - t_init) * 1000
    print(f"[pub] init={init_ms:.1f}ms publish={pub_ms:.1f}ms total={pub_ms+init_ms:.1f}ms")
    print(f"[pub] result: {result.content[0].text if result.content else result}")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--url", default="http://127.0.0.1:7383/mcp")
    p.add_argument("--topic", default="test")
    p.add_argument("--source", default="poc-pub")
    p.add_argument("--payload", default='{"msg":"hello"}')
    args = p.parse_args()
    payload = json.loads(args.payload)
    asyncio.run(publish(args.url, args.topic, args.source, payload))


if __name__ == "__main__":
    main()
