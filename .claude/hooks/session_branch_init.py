#!/usr/bin/env python3
"""SessionStart hook: 팀 세션이면 work/{team}/{date}-{slug} 브랜치 자동 체크아웃.

Conductor 세션은 main 유지. 충돌 시(작업 중인 변경 존재) 침묵 통과.
bypass 모드 시에도 안전하게 동작 (실패 시 침묵).

v4.1 (2026-04-21): subdir 팀 세션 보호 추가.
  subdir 모드(cwd 가 `C:/claude/ebs/team{N}-*/`) 는 main worktree 의 shared HEAD 를
  공유하므로 여기서 `git checkout` 하면 Conductor HEAD 가 오염된다. 이를 방지하기
  위해 subdir 팀 세션은 브랜치 자동 전환을 **건너뛰고** 사용자에게 sibling-dir
  worktree 사용을 권고한다.
"""
from __future__ import annotations

import datetime
import os
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from _common import detect_team, read_payload, PROJECT  # noqa: E402


def _is_sibling_worktree(cwd: str | None) -> bool:
    """sibling-dir worktree 세션인지 판단 (cwd 가 ebs-team{N}-... 패턴).

    branch_guard._is_sibling_worktree 와 정합. True 면 자체 HEAD 소유 → 브랜치 전환 안전.
    False 면 subdir 모드로 간주되어 shared HEAD 오염 위험.
    """
    c = (cwd or os.getcwd()).replace("\\", "/").lower()
    return bool(re.search(r"/ebs-team[1-4][-/]", c + "/"))


def _git(*args: str) -> tuple[int, str]:
    try:
        r = subprocess.run(["git", *args], cwd=PROJECT, capture_output=True, text=True, timeout=10)
        return r.returncode, (r.stdout + r.stderr).strip()
    except Exception as e:
        return 1, str(e)


def _current_branch() -> str:
    code, out = _git("branch", "--show-current")
    return out if code == 0 else ""


def _has_uncommitted() -> bool:
    code, out = _git("status", "--porcelain")
    return bool(out.strip()) if code == 0 else False


def main() -> int:
    payload = read_payload()
    cwd = payload.get("cwd")
    team = detect_team(cwd)
    if team == "conductor":
        sys.stderr.write(f"[session-branch] conductor session, staying on {_current_branch()}\n")
        return 0

    # v4.1: subdir 팀 세션은 shared HEAD 오염 방지를 위해 자동 브랜치 전환 금지
    if not _is_sibling_worktree(cwd):
        sys.stderr.write(
            f"[session-branch] {team}: subdir mode detected (cwd={cwd}).\n"
            f"  · 브랜치 자동 전환을 건너뜁니다 — shared HEAD 오염 방지 (v4.1).\n"
            f"  · 권장: sibling worktree 사용.\n"
            f"    python tools/setup_team_worktrees.py --team {team}\n"
            f"    cd C:/claude/ebs-{team}-<slug>/\n"
            f"  · 상세: docs/4. Operations/Multi_Session_Workflow.md\n"
        )
        return 0

    cur = _current_branch()
    if cur.startswith(f"work/{team}/"):
        sys.stderr.write(f"[session-branch] {team}: already on {cur}\n")
        return 0

    if cur != "main":
        sys.stderr.write(f"[session-branch] {team}: not on main ({cur}), skipping auto-branch\n")
        return 0

    stashed = False
    if _has_uncommitted():
        sys.stderr.write(f"[session-branch] {team}: stashing uncommitted changes on main...\n")
        code, out = _git("stash", "push", "-m", f"auto-stash-{team}-{datetime.date.today().strftime('%Y%m%d')}")
        if code == 0:
            stashed = True
        else:
            sys.stderr.write(f"[session-branch] {team}: stash failed ({out}), staying on main\n")
            return 0

    today = datetime.date.today().strftime("%Y%m%d")
    slug = "session"
    branch = f"work/{team}/{today}-{slug}"

    code, out = _git("rev-parse", "--verify", branch)
    if code == 0:
        _git("checkout", branch)
        sys.stderr.write(f"[session-branch] {team}: switched to existing {branch}\n")
    else:
        _git("checkout", "-b", branch)
        sys.stderr.write(f"[session-branch] {team}: created and switched to {branch}\n")

    if stashed:
        code, out = _git("stash", "pop")
        if code == 0:
            sys.stderr.write(f"[session-branch] {team}: restored stashed changes on {branch}\n")
        else:
            sys.stderr.write(f"[session-branch] {team}: stash pop failed ({out}), changes remain in stash\n")

    # v4.0: stale manifest 정리 (다른 /team 호출이 남긴 유령 lease)
    _try_cleanup_stale_manifests()

    return 0


def _try_cleanup_stale_manifests() -> None:
    """stale session-manifest 자동 정리 (v4.0). 실패 시 침묵."""
    try:
        skill_script = Path.home() / ".claude" / "skills" / "team" / "scripts" / "team_manifest.py"
        if skill_script.exists():
            subprocess.run(
                [sys.executable, str(skill_script), "cleanup-stale"],
                cwd=PROJECT, capture_output=True, timeout=5,
            )
    except Exception:
        pass


if __name__ == "__main__":
    sys.exit(main())
