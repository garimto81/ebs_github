#!/usr/bin/env python3
"""PostToolUse hook (v11 Phase B 신규).

Edit/Write 완료 후 cascade lock 자동 release.
PreToolUse 가 acquire_lock 으로 잡은 cascade:{file} 을 풀어준다.

Placement: <worktree>/.claude/hooks/PostToolUse.py
Trigger: Edit/Write/MultiEdit 직후 (settings.local.json 의 PostToolUse hook)

격리 보증:
- broker dead → silent skip (v10.3 호환)
- .team 없는 main session → no-op
- lock 미존재 → silent skip (release_lock 이 false 반환)
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit(0)  # PyYAML 없음 → silent skip

WRITE_TOOLS = {"Edit", "Write", "MultiEdit"}


def _broker_alive():
    import socket
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(1.0)
    try:
        s.connect(("127.0.0.1", 7383))
        return True
    except OSError:
        return False
    finally:
        s.close()


def _broker_release_lock(resource, holder):
    """release_lock 호출. silent if broker dead or call fails."""
    try:
        import asyncio
        from mcp import ClientSession
        from mcp.client.streamable_http import streamablehttp_client

        async def _run():
            async with streamablehttp_client("http://127.0.0.1:7383/mcp") as (r, w, _gs):
                async with ClientSession(r, w) as s:
                    await s.initialize()
                    await s.call_tool("release_lock", {
                        "resource": resource, "holder": holder,
                    })

        try:
            asyncio.run(asyncio.wait_for(_run(), timeout=2.0))
        except Exception:
            pass
    except Exception:
        pass


def _relative_to_root(target):
    cwd = Path.cwd()
    try:
        p = Path(target).resolve()
        return str(p.relative_to(cwd)).replace("\\", "/")
    except (ValueError, OSError):
        return None


def _is_cascade_resource(target_rel):
    return target_rel.startswith("docs/1. Product/") and target_rel.endswith(".md")


def main():
    # stdin 에서 tool input 읽기
    try:
        tool_input = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    tool_name = tool_input.get('tool_name', '')
    if tool_name not in WRITE_TOOLS:
        sys.exit(0)

    # .team 식별 (없으면 main session — no-op)
    cwd = Path.cwd()
    team_file = cwd / '.team'
    if not team_file.exists():
        sys.exit(0)
    try:
        team_data = yaml.safe_load(team_file.read_text(encoding='utf-8'))
    except Exception:
        sys.exit(0)
    team_id = team_data.get('team_id')
    if not team_id:
        sys.exit(0)

    # broker probe
    if not _broker_alive():
        sys.exit(0)  # silent skip

    # 대상 파일 — cascade resource 인지 확인
    inputs = tool_input.get('tool_input', {})
    target = inputs.get('file_path') or inputs.get('path')
    if not target:
        sys.exit(0)
    target_rel = _relative_to_root(target)
    if not target_rel or not _is_cascade_resource(target_rel):
        sys.exit(0)  # cascade lock 대상 아님 → release 불필요

    # cascade lock release
    _broker_release_lock(
        resource="cascade:" + target_rel,
        holder=team_id,
    )
    sys.exit(0)


if __name__ == "__main__":
    main()
