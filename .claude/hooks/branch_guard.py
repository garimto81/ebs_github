#!/usr/bin/env python3
"""PreToolUse hook (Bash 대상): 팀 세션이 main으로 직접 push/commit 시 block.

bypass 모드에선 warning으로 완화.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from _common import detect_team, is_bypass_mode, read_payload, emit  # noqa: E402

# 위험 명령 패턴
PUSH_MAIN_RE = re.compile(r"\bgit\s+push\b.*\bmain\b", re.IGNORECASE)
COMMIT_ON_MAIN_RE = re.compile(r"\bgit\s+commit\b", re.IGNORECASE)


def main() -> int:
    payload = read_payload()
    tool = payload.get("tool_name") or payload.get("tool")
    if tool != "Bash":
        return 0
    cmd = (payload.get("tool_input") or {}).get("command", "")
    if not cmd:
        return 0

    team = detect_team(payload.get("cwd"))
    if team == "conductor":
        return 0

    bypass = is_bypass_mode(payload)
    reason = None

    if PUSH_MAIN_RE.search(cmd):
        reason = (
            f"[branch-guard] {team} session attempting to push main directly. "
            f"Use work/{team}/{{date}}-{{slug}} branch + /team-merge instead."
        )
    elif COMMIT_ON_MAIN_RE.search(cmd):
        # commit 자체는 허용하되 현재 main 위에 있는지 확인
        import subprocess
        try:
            r = subprocess.run(["git", "branch", "--show-current"],
                               capture_output=True, text=True, timeout=5)
            if r.stdout.strip() == "main":
                reason = (
                    f"[branch-guard] {team} session committing on main. "
                    f"Switch to work/{team}/* branch first."
                )
        except Exception:
            pass

    if reason:
        if bypass:
            emit(warning=True, reason=reason)
        else:
            emit(decision="block", reason=reason)
    return 0


if __name__ == "__main__":
    sys.exit(main())
