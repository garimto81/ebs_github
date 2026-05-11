"""Chat CLI — watch / send / history.

Usage:
  python tools/chat_server/cli.py watch
  python tools/chat_server/cli.py watch room:design
  python tools/chat_server/cli.py send --channel room:design "hello @S3"
  python tools/chat_server/cli.py history room:design --last 50

Note: send sets source='user' (CLI assumes human operator).
"""
from __future__ import annotations

import argparse
import asyncio
import re
import sys
from datetime import datetime, timezone

from tools.chat_server.broker_client import BrokerClient

MENTION_RE = re.compile(r"@([A-Za-z][\w-]*)")


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _parse_mentions(body: str) -> list[str]:
    return [f"@{m}" for m in MENTION_RE.findall(body)]


# ── Thin async wrappers (mockable in tests) ──

async def _broker_publish(topic: str, payload: dict, source: str) -> dict:
    return await BrokerClient().publish(topic=topic, payload=payload, source=source)


async def _broker_subscribe(topic: str, from_seq: int, timeout_sec: int) -> dict:
    return await BrokerClient().subscribe(
        topic=topic, from_seq=from_seq, timeout_sec=timeout_sec
    )


async def _broker_history(topic: str, since_seq: int, limit: int) -> dict:
    return await BrokerClient().get_history(
        topic=topic, since_seq=since_seq, limit=limit
    )


# ── Commands ──

def cmd_send(args) -> int:
    topic = f"chat:{args.channel}"
    body = args.body
    mentions = _parse_mentions(body)
    payload = {
        "kind": "msg",
        "from": "user",
        "to": [m.lstrip("@") for m in mentions],
        "body": body,
        "reply_to": args.reply_to,
        "thread_id": None,
        "mentions": mentions,
        "ts": _now_iso(),
    }
    r = asyncio.run(_broker_publish(topic=topic, payload=payload, source="user"))
    print(f"published seq={r.get('seq')}")
    return 0


def cmd_history(args) -> int:
    topic = f"chat:{args.channel}"
    r = asyncio.run(_broker_history(topic=topic, since_seq=0, limit=args.last))
    for e in r.get("events", []):
        p = e["payload"]
        ts = (p.get("ts") or e.get("ts", ""))[:19]
        print(f"{ts} [{p.get('from','?')}] {p.get('body','')}")
    return 0


def cmd_watch(args) -> int:
    topic = f"chat:{args.channel}" if args.channel else "chat:*"
    last_seq = 0
    print(f"watching {topic} (Ctrl-C to exit)")
    while True:
        try:
            r = asyncio.run(
                _broker_subscribe(topic=topic, from_seq=last_seq, timeout_sec=30)
            )
            for e in r.get("events", []):
                last_seq = max(last_seq, e["seq"])
                p = e["payload"]
                ts = (p.get("ts") or e.get("ts", ""))[:19]
                ch = e["topic"].replace("chat:", "")
                print(f"{ts} #{ch} [{p.get('from','?')}] {p.get('body','')}")
            last_seq = r.get("next_seq", last_seq)
        except KeyboardInterrupt:
            return 0
        except Exception as e:
            print(f"error: {e}; retrying...", file=sys.stderr)
            asyncio.run(asyncio.sleep(5))


# ── Entry ──

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="chat-cli")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_watch = sub.add_parser("watch", help="Tail chat messages")
    p_watch.add_argument("channel", nargs="?", default=None,
                         help="e.g., 'room:design' (omit for all)")
    p_watch.set_defaults(func=cmd_watch)

    p_send = sub.add_parser("send", help="Send a message")
    p_send.add_argument("--channel", required=True)
    p_send.add_argument("--reply-to", type=int, default=None)
    p_send.add_argument("body")
    p_send.set_defaults(func=cmd_send)

    p_history = sub.add_parser("history", help="Print recent messages")
    p_history.add_argument("channel")
    p_history.add_argument("--last", type=int, default=50)
    p_history.set_defaults(func=cmd_history)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
