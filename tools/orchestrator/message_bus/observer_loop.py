"""v11 Phase C + S11 Cycle 3 - Subscribe-based Observer Loop + action dispatch.

broker push -> long-poll subscribe. idle 무 cost.

Usage:
  python -m tools.orchestrator.message_bus.observer_loop
  python -m tools.orchestrator.message_bus.observer_loop --topic stream:S1
  python -m tools.orchestrator.message_bus.observer_loop --print-only
  python -m tools.orchestrator.message_bus.observer_loop --action-mode

Latency: v10.3 polling 15s avg vs v11 push ~50ms.

S11 Cycle 3 (autonomous chain) - --action-mode payload.next_action 디스패치.
inbox-drop / shell / noop 3 type. shell 은 allowlist 격리.
"""
from __future__ import annotations

import argparse
import asyncio
import json
import sys
import os
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path

from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client

URL = "http://127.0.0.1:7383/mcp"

# S11 Cycle 3 - action dispatch config
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent
INBOX_DIR = PROJECT_ROOT / "docs" / "4. Operations" / "handoffs" / "inbox"
SHELL_ALLOWLIST_ROOT = PROJECT_ROOT / "tools" / "orchestrator" / "actions"
_SLUG_RE = re.compile(r"[^a-zA-Z0-9._-]+")


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


def _slugify(s, maxlen=40):
    return _SLUG_RE.sub("-", s).strip("-")[:maxlen] or "event"


def _dispatch_inbox_drop(event, action):
    try:
        INBOX_DIR.mkdir(parents=True, exist_ok=True)
        import json as _json
        seq = event.get("seq", 0)
        topic = event.get("topic", "unknown")
        source = event.get("source", "?")
        ts_raw = event.get("ts", "")
        ts_safe = _slugify(ts_raw, 25) or "no-ts"
        topic_slug = _slugify(topic)
        target = action.get("target") or "all"
        fname = f"{ts_safe}_{topic_slug}_seq{seq:06d}_to-{_slugify(target, 10)}.md"
        path = INBOX_DIR / fname
        payload_json = _json.dumps(event.get("payload", {}), indent=2, ensure_ascii=False)
        now_iso = datetime.now(timezone.utc).isoformat()
        body_lines = [
            "---",
            f"owner: S11",
            f"source: {source}",
            f"topic: {topic}",
            f"seq: {seq}",
            f"ts: {ts_raw}",
            f"target: {target}",
            "action_type: inbox-drop",
            f"observer_dropped_at: {now_iso}",
            "---",
            "",
            f"# {topic} (seq={seq}) -> {target}",
            "",
            f"**Source**: `{source}`  ",
            f"**Timestamp**: {ts_raw}  ",
            "",
            "## Payload",
            "",
            "```json",
            payload_json,
            "```",
            "",
            "---",
            "Auto-dropped by `observer_loop --action-mode` (S11 Cycle 3).",
            "",
        ]
        path.write_text("\n".join(body_lines), encoding="utf-8")
        return path
    except Exception as e:
        print(f"  warn inbox-drop failed: {e}")
        return None


def _dispatch_shell(event, action):
    cmd = action.get("command")
    if not cmd:
        return None
    try:
        cmd_path = (PROJECT_ROOT / cmd).resolve() if not os.path.isabs(cmd) else Path(cmd).resolve()
        try:
            cmd_path.relative_to(SHELL_ALLOWLIST_ROOT.resolve())
        except ValueError:
            print(f"  BLOCK shell (outside allowlist {SHELL_ALLOWLIST_ROOT}): {cmd}")
            return None
        if not cmd_path.exists():
            print(f"  BLOCK shell (missing): {cmd_path}")
            return None
        import json as _json
        result = subprocess.run(
            [str(cmd_path)],
            input=_json.dumps({"event": event, "action": action}),
            capture_output=True, text=True, timeout=30,
            cwd=str(PROJECT_ROOT),
        )
        print(f"  shell exec: {cmd} exit={result.returncode}")
        if result.stdout:
            print(f"    stdout: {result.stdout[:200]}")
        return cmd_path
    except subprocess.TimeoutExpired:
        print(f"  BLOCK shell timeout: {cmd}")
        return None
    except Exception as e:
        print(f"  warn shell failed: {e}")
        return None


def _dispatch_action(event):
    action = (event.get("payload") or {}).get("next_action")
    if not isinstance(action, dict):
        return
    atype = action.get("type", "noop")
    if atype == "noop":
        return
    if atype == "inbox-drop":
        result = _dispatch_inbox_drop(event, action)
        if result:
            try:
                rel = result.relative_to(PROJECT_ROOT)
            except ValueError:
                rel = result
            print(f"  inbox-drop: {rel}")
    elif atype == "shell":
        _dispatch_shell(event, action)
    else:
        print(f"  warn unknown action type: {atype}")


async def observer_loop(topic="*", print_only=False, max_iter=None, action_mode=False):
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
                    if action_mode:
                        _dispatch_action(event)

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
    p = argparse.ArgumentParser(description="v11 observer loop + S11 Cycle 3 action dispatch")
    p.add_argument("--topic", default="*", help="topic to subscribe (default: *)")
    p.add_argument("--print-only", action="store_true",
                   help="single-line print mode (no handler)")
    p.add_argument("--max-iter", type=int, default=None,
                   help="max iterations (default: infinite)")
    p.add_argument("--action-mode", action="store_true",
                   help="dispatch payload.next_action (S11 Cycle 3)")
    args = p.parse_args()

    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

    try:
        asyncio.run(observer_loop(
            topic=args.topic,
            print_only=args.print_only,
            max_iter=args.max_iter,
            action_mode=args.action_mode,
        ))
    except KeyboardInterrupt:
        print("\n[observer] stopped by user")


if __name__ == "__main__":
    main()
