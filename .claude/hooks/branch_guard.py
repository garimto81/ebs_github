#!/usr/bin/env python3
"""PreToolUse hook (Bash 대상): 팀 세션의 위험 git 명령 차단.

차단 대상:
1. 팀 세션 → main 직접 push
2. 팀 세션 → main 위에서 commit
3. 팀 subdir 세션 → git checkout/switch 로 HEAD 이동 (공유 .git/HEAD 조작 방지)

Phase 2 추가: subdir 팀 세션이 git checkout/switch 로 다른 worktree 의 HEAD 를
조작해 Conductor 를 오염시키는 문제 차단. sibling worktree 세션은 허용 (자체 HEAD 소유).
Phase 4 추가: Conductor 가 team 브랜치에서 commit 시 warn-once (차단 X).
"""
from __future__ import annotations

import hashlib
import os
import re
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from _common import detect_team, read_payload, emit, PROJECT  # noqa: E402

# --- 위험 패턴 ---
PUSH_MAIN_RE = re.compile(r"\bgit\s+push\b.*\bmain\b", re.IGNORECASE)
COMMIT_RE = re.compile(r"\bgit\s+commit\b", re.IGNORECASE)
# checkout/switch 로 브랜치 이동 (path 복원 `--` 은 허용)
CHECKOUT_BRANCH_RE = re.compile(
    r"\bgit\s+(checkout|switch)\b(?!.*\s--\s)", re.IGNORECASE
)
# 예외: `git checkout -- <path>` 나 `git checkout .` (path 복원)
CHECKOUT_PATH_RE = re.compile(
    r"\bgit\s+checkout\b(\s+--\s|\s+\.\s*$|\s+[^\s-][^\s]*\.(vue|ts|py|dart|md|json)$)",
    re.IGNORECASE,
)

# --- warn-once override ---
OVERRIDE_DIR = PROJECT / ".claude" / ".branch-guard-overrides"
OVERRIDE_TTL_SEC = 300


def _override_key(sid: str, cmd: str) -> Path:
    h = hashlib.sha1(f"{sid}:{cmd}".encode("utf-8")).hexdigest()[:16]
    return OVERRIDE_DIR / f"{h}.flag"


def _has_override(sid: str, cmd: str) -> bool:
    f = _override_key(sid, cmd)
    if not f.exists():
        return False
    if time.time() - f.stat().st_mtime > OVERRIDE_TTL_SEC:
        try:
            f.unlink()
        except Exception:
            pass
        return False
    return True


def _set_override(sid: str, cmd: str) -> None:
    OVERRIDE_DIR.mkdir(parents=True, exist_ok=True)
    _override_key(sid, cmd).touch()


def _session_id() -> str:
    """세션 ID (pid + 시작 시각 기반)."""
    sid_file = PROJECT / ".claude" / ".session-id"
    if sid_file.exists():
        s = sid_file.read_text(encoding="utf-8").strip()
        if s:
            return s
    return f"pid-{os.getpid()}"


def _current_branch() -> str:
    try:
        r = subprocess.run(["git", "branch", "--show-current"],
                           capture_output=True, text=True, timeout=5,
                           cwd=PROJECT)
        return r.stdout.strip()
    except Exception:
        return ""


def _is_sibling_worktree(cwd: str | None) -> bool:
    """sibling-dir worktree 세션인지 판단 (cwd 가 ebs-team{N}-... 패턴)."""
    c = (cwd or os.getcwd()).replace("\\", "/").lower()
    return bool(re.search(r"/ebs-team[1-4][-/]", c + "/"))


def main() -> int:
    payload = read_payload()
    tool = payload.get("tool_name") or payload.get("tool")
    if tool != "Bash":
        return 0
    cmd = (payload.get("tool_input") or {}).get("command", "")
    if not cmd:
        return 0

    team = detect_team(payload.get("cwd"))
    sid = _session_id()

    # Rule 1: team session push main → block
    if team != "conductor" and PUSH_MAIN_RE.search(cmd):
        emit(
            decision="block",
            reason=(
                f"[branch-guard] {team} session attempting to push main directly. "
                f"Use work/{team}/{{date}}-{{slug}} branch + /team-merge."
            ),
        )

    # Rule 2 & 3: commit on wrong branch
    if COMMIT_RE.search(cmd):
        cur = _current_branch()
        # Rule 2: team session committing on main → block
        if team != "conductor" and cur == "main":
            emit(
                decision="block",
                reason=(
                    f"[branch-guard] {team} session committing on main. "
                    f"Switch to work/{team}/* branch first."
                ),
            )
        # Rule 3: Conductor committing on team branch → warn-once
        if team == "conductor" and cur.startswith("work/team"):
            if not _has_override(sid, f"conductor-commit-{cur}"):
                _set_override(sid, f"conductor-commit-{cur}")
                emit(
                    decision="block",
                    reason=(
                        f"[branch-guard] Conductor committing on team branch: {cur}\n"
                        f"  · 의도적이면 동일 명령을 다시 실행하세요 (override 5분).\n"
                        f"  · 권장: cd sibling worktree or switch to main."
                    ),
                )

    # Rule 4: subdir team session doing git checkout/switch → block
    # (sibling worktree 세션은 자체 HEAD 소유하므로 허용)
    if team != "conductor" and not _is_sibling_worktree(payload.get("cwd")):
        if CHECKOUT_BRANCH_RE.search(cmd) and not CHECKOUT_PATH_RE.search(cmd):
            emit(
                decision="block",
                reason=(
                    f"[branch-guard] {team} subdir session blocked from "
                    f"`git checkout/switch <branch>`.\n"
                    f"  · 이유: 공유 .git/HEAD 조작이 Conductor worktree 오염.\n"
                    f"  · 해결: 세션 시작 시 session_branch_init 이 배치한 브랜치 유지,\n"
                    f"    or use sibling worktree (`ebs-team{{N}}-<slug>/`).\n"
                    f"  · 파일 복원만 필요하면 `git checkout -- <path>` 로."
                ),
            )

    return 0


if __name__ == "__main__":
    sys.exit(main())
