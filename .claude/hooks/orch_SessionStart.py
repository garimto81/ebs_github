#!/usr/bin/env python3
"""
SessionStart hook (Layer 4 of 6-layer defense).

Auto-detects team identity from worktree path + .team file,
verifies consistency, and injects identity context into Claude session.

Placement: <worktree>/.claude/hooks/SessionStart.py
Trigger: Claude Code session start (via .claude/settings.local.json hooks config)
"""
import os
import re
import sys
import json
import subprocess
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.stderr.write("⛔ FATAL: PyYAML required. pip install pyyaml\n")
    sys.exit(1)


def detect_team():
    cwd = Path.cwd()

    # Layer 1: 경로 패턴 매칭 (project-stream-slug)
    match = re.search(r'-(?:s\d+|team\d+|[a-z]+)[-]?', str(cwd.name))
    if not match:
        return None  # main session, no team context

    # Layer 2: .team file (SSOT)
    team_file = cwd / '.team'
    if not team_file.exists():
        sys.stderr.write(
            f"⛔ FATAL: Worktree {cwd.name} has no .team file.\n"
            f"   Run: python <project>/tools/orchestrator/setup_stream_worktree.py\n"
        )
        sys.exit(1)

    try:
        team_data = yaml.safe_load(team_file.read_text(encoding='utf-8'))
    except yaml.YAMLError as e:
        sys.stderr.write(f"⛔ FATAL: .team file invalid yaml: {e}\n")
        sys.exit(1)

    # Layer 1↔2 cross-check
    expected_path = team_data.get('worktree_path', '').rstrip('/').replace('\\', '/')
    actual_path = str(cwd).rstrip('/').replace('\\', '/')
    if expected_path and actual_path != expected_path:
        sys.stderr.write(
            f"⛔ FATAL: .team worktree_path mismatch.\n"
            f"   Expected: {expected_path}\n"
            f"   Actual:   {actual_path}\n"
        )
        sys.exit(1)

    return team_data


def check_dependency_status(team_data):
    """blocked_by Stream의 PR 머지 상태를 GitHub에서 확인"""
    blocked_by = team_data.get('blocked_by', [])
    if not blocked_by:
        return ("READY", None)

    for upstream in blocked_by:
        try:
            result = subprocess.run([
                'gh', 'pr', 'list',
                '--label', f'stream:{upstream}',
                '--state', 'all',
                '--limit', '1',
                '--json', 'state,mergedAt'
            ], capture_output=True, text=True, timeout=30)

            if result.returncode != 0:
                # gh CLI 없거나 인증 실패 — 기본 READY (warning 출력)
                sys.stderr.write(f"⚠️ gh CLI unavailable, assuming READY\n")
                return ("READY", None)

            prs = json.loads(result.stdout)
            if not prs or prs[0].get('state') != 'MERGED':
                return ("BLOCKED", upstream)
        except (subprocess.TimeoutExpired, json.JSONDecodeError, Exception):
            return ("READY", None)

    return ("READY", None)


def update_start_here(team_data, status, blocker=None):
    """START_HERE.md 동적 갱신 (BLOCKED ↔ READY 상태 반영)"""
    start_here = Path.cwd() / 'START_HERE.md'
    if not start_here.exists():
        return  # 템플릿 없으면 skip

    content = start_here.read_text(encoding='utf-8')

    # 상태 표시 라인 갱신
    if status == "BLOCKED":
        marker = f"🚫 Status: BLOCKED by {blocker}"
    else:
        marker = f"✅ Status: READY"

    # 기존 상태 라인 치환 (있으면) 또는 추가
    if "Status:" in content:
        content = re.sub(r'(?:🚫|✅) Status:.*', marker, content)
    else:
        content = f"{marker}\n\n{content}"

    start_here.write_text(content, encoding='utf-8')


def emit_identity_context(team_data, status, blocker=None):
    """Claude 세션에 identity 강제 주입 (stdout)"""
    print(f"\n🎯 You are {team_data['team_id']} ({team_data['team_name']})")
    print(f"📂 Worktree: {team_data.get('worktree_path', Path.cwd())}")
    print(f"🌿 Branch:   {team_data.get('branch', '(unknown)')}")

    if status == "BLOCKED":
        print(f"\n🚫 BLOCKED by {blocker}")
        print(f"   This Stream is waiting. PreToolUse hook will block all Edit/Write.")
        print(f"   See: START_HERE.md")
        return

    print(f"\n✅ scope_owns:")
    for path in team_data.get('scope_owns', []):
        print(f"   - {path}")

    blocked_files = team_data.get('meta_files_blocked', [])
    if blocked_files:
        print(f"\n🚫 BLOCKED meta files:")
        for path in blocked_files:
            print(f"   - {path}")

    print(f"\n📋 First action: type '작업 시작' to auto-create issue + draft PR")


def main():
    team_data = detect_team()
    if not team_data:
        return  # main session

    status, blocker = check_dependency_status(team_data)
    update_start_here(team_data, status, blocker)
    emit_identity_context(team_data, status, blocker)


if __name__ == "__main__":
    main()
