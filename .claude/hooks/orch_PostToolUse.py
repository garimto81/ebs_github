#!/usr/bin/env python3
"""PostToolUse hook (v11 Phase B + S11 Cycle 2 확장).

두 가지 책임:
1. Edit/Write/MultiEdit 완료 후 cascade lock 자동 release (Phase B)
2. Bash docker compose up 성공 후 pipeline:env-ready 자동 publish (S11 Cycle 2, Issue #240)

Placement: <worktree>/.claude/hooks/PostToolUse.py
Trigger: 모든 도구 직후 (settings.json 의 PostToolUse hook)

격리 보증:
- broker dead → silent skip (v10.3 호환)
- .team 없는 main session → no-op
- lock 미존재 → silent skip (release_lock 이 false 반환)
- docker 미일치 pattern → silent skip
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit(0)  # PyYAML 없음 → silent skip

import re

WRITE_TOOLS = {"Edit", "Write", "MultiEdit"}

# S11 Cycle 2 (Issue #240) - docker compose up 성공 감지 패턴
DOCKER_UP_RE = re.compile(
    r"docker\s+compose\s+(?:--project-name\s+\S+\s+|--?f\s+\S+\s+)*up",
    re.I,
)


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


def _broker_publish(topic, payload, source):
    """publish_event call. silent if broker dead or call fails. (S11 Cycle 2)"""
    try:
        import asyncio
        from mcp import ClientSession
        from mcp.client.streamable_http import streamablehttp_client

        async def _run():
            async with streamablehttp_client("http://127.0.0.1:7383/mcp") as (r, w, _gs):
                async with ClientSession(r, w) as s:
                    await s.initialize()
                    await s.call_tool("publish_event", {
                        "topic": topic, "payload": payload, "source": source,
                    })

        try:
            asyncio.run(asyncio.wait_for(_run(), timeout=2.0))
        except Exception:
            pass
    except Exception:
        pass


def _domain4_healthy_count():
    """Return (healthy_count, state_map) for 6 domain containers.

    S11 Cycle 2 (Issue #240) - env-ready signal payload helper.
    """
    import subprocess
    targets = ["ebs-bo", "ebs-engine", "ebs-lobby-web", "ebs-cc-web", "ebs-redis", "ebs-proxy"]
    healthy = 0
    states = {}
    for name in targets:
        try:
            r = subprocess.run(
                ["docker", "inspect", name, "--format",
                 "{{.State.Status}}|{{if .State.Health}}{{.State.Health.Status}}{{else}}n/a{{end}}"],
                capture_output=True, text=True, timeout=3,
            )
            if r.returncode == 0:
                s = r.stdout.strip()
                states[name] = s
                if s.startswith("running") and ("healthy" in s or "n/a" in s):
                    healthy += 1
            else:
                states[name] = "absent"
        except Exception:
            states[name] = "error"
    return healthy, states


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
    if tool_name not in WRITE_TOOLS and tool_name != "Bash":
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

    inputs = tool_input.get('tool_input', {}) or {}
    response = tool_input.get('tool_response', {}) or {}

    # Bash branch (S11 Cycle 2, Issue #240)
    if tool_name == "Bash":
        if team_id != "S11":
            sys.exit(0)
        command = inputs.get('command', '') if isinstance(inputs, dict) else ''
        exit_code = response.get('exit_code') if isinstance(response, dict) else None
        is_error = response.get('is_error') if isinstance(response, dict) else False
        if not DOCKER_UP_RE.search(command):
            sys.exit(0)
        if exit_code != 0 or is_error:
            sys.exit(0)  # build fail 은 post_build_fail 이 cascade:build-fail publish
        healthy, states = _domain4_healthy_count()
        _broker_publish(
            topic="pipeline:env-ready",
            payload={
                "trigger": "PostToolUse:Bash docker compose up",
                "command_excerpt": command[:120],
                "healthy_count": healthy,
                "max_count": 6,
                "states": states,
                "auto_published": True,
            },
            source="S11",
        )
        sys.exit(0)

    # WRITE_TOOLS branch (Phase B - cascade lock release)
    target = inputs.get('file_path') or inputs.get('path')
    if not target:
        sys.exit(0)
    target_rel = _relative_to_root(target)
    if not target_rel or not _is_cascade_resource(target_rel):
        sys.exit(0)

    _broker_release_lock(
        resource="cascade:" + target_rel,
        holder=team_id,
    )
    sys.exit(0)


if __name__ == "__main__":
    main()
