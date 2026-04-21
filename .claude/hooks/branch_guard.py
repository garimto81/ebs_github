#!/usr/bin/env python3
"""PreToolUse hook (Bash 대상): 팀 세션의 위험 git 명령 차단.

차단 대상:
1. 팀 세션 → main 직접 push
2. 팀 세션 → main 위에서 commit
3. 팀 subdir 세션 → git checkout/switch 로 HEAD 이동 (공유 .git/HEAD 조작 방지)

Phase 2 추가: subdir 팀 세션이 git checkout/switch 로 다른 worktree 의 HEAD 를
조작해 Conductor 를 오염시키는 문제 차단. sibling worktree 세션은 허용 (자체 HEAD 소유).
Phase 4 추가: Conductor 가 team 브랜치에서 commit 시 warn-once (차단 X).

Phase 5 (v3.1, 2026-04-21) 추가:
- Session-pinned branch tracking: `.claude/.session-branches/<sid>` 에 각 세션의 의도한
  브랜치(정상 상태) 를 기록. branch_guard 가 실제 HEAD 와 pinned 값을 대조해
  "다른 세션이 shared HEAD 를 움직인 결과" 를 구분하여 override 재발급 제거.
- git index lock 대기 (100ms × 30회 retry): 다른 세션의 `git add/commit` 이 index.lock
  을 쥐고 있을 때 차단 대신 짧게 대기.
- override key 를 sid 만 의존 (cur 독립): 다른 세션이 branch 를 바꿔도 override 유지.
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

# --- Phase 5: Session-pinned branch tracking ---
SESSION_BRANCH_DIR = PROJECT / ".claude" / ".session-branches"
SESSION_PIN_TTL_SEC = 3600  # 1 hour

# --- Phase 5: git index lock 대기 ---
INDEX_LOCK = PROJECT / ".git" / "index.lock"
LOCK_WAIT_INTERVALS_MS = 100
LOCK_WAIT_MAX_RETRIES = 30  # 총 3초


def _override_key(sid: str, kind: str) -> Path:
    """Phase 5: kind(예: 'conductor-commit-on-team-branch') 기반. cur 독립.

    다른 세션이 shared HEAD 를 움직여도 override 유지.
    """
    h = hashlib.sha1(f"{sid}:{kind}".encode("utf-8")).hexdigest()[:16]
    return OVERRIDE_DIR / f"{h}.flag"


def _wait_for_index_lock() -> None:
    """git index.lock 이 있으면 짧게 대기. 다른 세션 commit 과의 race 완화.

    Phase 5 (v3.1): 차단 대신 대기. 실패 시 침묵 통과 (hook 은 방해하지 않음).
    """
    retries = 0
    while INDEX_LOCK.exists() and retries < LOCK_WAIT_MAX_RETRIES:
        time.sleep(LOCK_WAIT_INTERVALS_MS / 1000)
        retries += 1


def _pin_session_branch(sid: str, branch: str) -> None:
    """현재 세션의 의도한 브랜치 기록. branch_guard 가 대조 기준으로 사용."""
    try:
        SESSION_BRANCH_DIR.mkdir(parents=True, exist_ok=True)
        f = SESSION_BRANCH_DIR / f"{sid}.pin"
        f.write_text(branch, encoding="utf-8")
    except Exception:
        pass


def _get_pinned_branch(sid: str) -> str | None:
    """세션이 기록한 의도 브랜치. 없거나 stale 면 None."""
    f = SESSION_BRANCH_DIR / f"{sid}.pin"
    if not f.exists():
        return None
    if time.time() - f.stat().st_mtime > SESSION_PIN_TTL_SEC:
        try:
            f.unlink()
        except Exception:
            pass
        return None
    try:
        return f.read_text(encoding="utf-8").strip() or None
    except Exception:
        return None


def _has_override(sid: str, kind: str) -> bool:
    f = _override_key(sid, kind)
    if not f.exists():
        return False
    if time.time() - f.stat().st_mtime > OVERRIDE_TTL_SEC:
        try:
            f.unlink()
        except Exception:
            pass
        return False
    return True


def _set_override(sid: str, kind: str) -> None:
    OVERRIDE_DIR.mkdir(parents=True, exist_ok=True)
    _override_key(sid, kind).touch()


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
        # Phase 5: git index lock 기다리기 (다른 세션 commit 과 race 완화)
        _wait_for_index_lock()
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
        # Phase 5 개선:
        # (a) override key 를 cur 독립 ('conductor-commit-on-team-branch') 로 변경 →
        #     다른 세션이 branch 를 다른 team work 브랜치로 바꿔도 override 유지
        # (b) pinned branch 가 main 인데 cur 이 team branch 면 "다른 세션이 HEAD 움직임"
        #     이 확실 → 경고문에 그 사실 명시 (사용자가 원인 바로 파악)
        if team == "conductor" and cur.startswith("work/team"):
            override_kind = "conductor-commit-on-team-branch"
            pinned = _get_pinned_branch(sid)
            cause_hint = ""
            if pinned == "main":
                cause_hint = (
                    "\n  · 감지: 이 세션은 main 에 pinned 되어 있으나 현재 HEAD 는 "
                    f"{cur} — 다른 세션의 checkout 때문일 가능성이 높음.\n"
                    "  · `git checkout main` 으로 복귀 후 재시도 권장."
                )
            if not _has_override(sid, override_kind):
                _set_override(sid, override_kind)
                emit(
                    decision="block",
                    reason=(
                        f"[branch-guard] Conductor committing on team branch: {cur}\n"
                        f"  · 의도적이면 동일 명령을 다시 실행하세요 (override 5분).\n"
                        f"  · 권장: cd sibling worktree or switch to main."
                        f"{cause_hint}"
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

    # Phase 5: Conductor 가 main 에서 commit 시 pinned branch=main 으로 기록
    # (다음 호출에서 HEAD 가 움직였으면 "다른 세션 탓" 힌트를 줄 수 있음)
    if team == "conductor" and COMMIT_RE.search(cmd):
        cur_for_pin = _current_branch()
        if cur_for_pin == "main":
            _pin_session_branch(sid, "main")

    return 0


if __name__ == "__main__":
    sys.exit(main())
