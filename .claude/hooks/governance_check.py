#!/usr/bin/env python3
"""governance_check.py — IMPR-3: Mode A/B 거버넌스 자동 감지 및 강제 (PreToolUse hook).

설계:
  - **Mode 감지**: `git worktree list` 스캔으로 활성 sibling worktree 확인.
    team1~4 worktree 가 하나라도 있으면 Mode B (Multi-Session). conductor 단독이면 Mode A.
  - **Mode A 제약 강제**: team-policy.json v7.1 `mode_a_limits` 위반 패턴을 PreToolUse 단계에서
    block. 위반 카테고리:
        external_messaging  — vendor 외부 메일 발송 (gh issue/pr comment 외부)
        destructive_system  — DB drop, prod 배포, volume 삭제, rm -rf 시스템 경로
        git_config          — remote URL 변경, force push to main, no-verify
  - **Mode B**: 본 hook 은 침묵 통과 (active_edits_preedit.py 가 decision_owner 검증 담당).

독립성:
  - 기존 hook 무수정. _common.py 만 import.
  - settings.json 등록 없이도 단독 dry-run 가능 (`python .claude/hooks/governance_check.py --self-test`).

표준 PreToolUse payload:
  {"tool_name": "Bash", "tool_input": {"command": "..."}, "permission_mode": "..."}

Exit:
  0 — 통과
  block — emit decision="block" + reason (Claude harness 가 차단)

stdlib only — subprocess/re/json/sys/pathlib.
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

# _common.py 호환 (settings.json 등록 시 같은 dir 에 위치 가정)
HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

try:
    from _common import detect_team, is_bypass_mode, read_payload, emit
except ImportError:  # 단독 실행 fallback
    def detect_team(cwd=None): return "conductor"
    def is_bypass_mode(payload=None): return False
    def read_payload(): return {}
    def emit(decision=None, reason="", warning=False):
        if decision == "block":
            sys.stderr.write(f"[BLOCK] {reason}\n")
            sys.exit(2)
        sys.exit(0)


REPO_ROOT = Path(__file__).resolve().parents[2]
TEAM_PATTERN = re.compile(r"\b(?:work/team[1-4]/|/ebs-team[1-4][-/])", re.IGNORECASE)

# ---------------------------------------------------------------- Mode 감지


def _git_worktree_list() -> str:
    """git worktree list 출력. 실패 시 빈 문자열."""
    try:
        result = subprocess.run(
            ["git", "worktree", "list"],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            check=False,
            timeout=5,
        )
        if result.returncode != 0:
            return ""
        return result.stdout
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return ""


def detect_mode() -> tuple[str, list[str]]:
    """반환: ('A' | 'B', active_team_branches).

    Mode B 조건: git worktree list 에 work/team{1-4}/ 또는 /ebs-team{1-4}/ 패턴이 존재.
    Conductor 자신의 worktree (work/conductor/* 또는 main) 만 있으면 Mode A.
    """
    output = _git_worktree_list()
    if not output:
        return "A", []

    team_branches: list[str] = []
    for line in output.splitlines():
        if TEAM_PATTERN.search(line):
            # `<path> <sha> [<branch>]` 형식에서 branch 추출
            m = re.search(r"\[([^\]]+)\]", line)
            if m:
                team_branches.append(m.group(1))
            else:
                team_branches.append(line.strip())

    return ("B" if team_branches else "A"), team_branches


# ---------------------------------------------------------------- Mode A 위반 감지

# 카테고리별 정규식. 매칭 시 block + 카테고리명을 reason 에 포함.
MODE_A_VIOLATIONS: list[tuple[str, re.Pattern]] = [
    # destructive_system — 데이터/볼륨 파괴
    ("destructive_system",
     re.compile(r"\bdocker\s+(?:compose\s+)?down\b[^\n]*(?<!\w)-v(?!\w)",
                re.IGNORECASE)),
    ("destructive_system",
     re.compile(r"\bdocker\s+volume\s+rm\b", re.IGNORECASE)),
    ("destructive_system",
     re.compile(r"\bdropdb\b|\bDROP\s+DATABASE\b|\bDROP\s+TABLE\b", re.IGNORECASE)),
    ("destructive_system",
     re.compile(r"\brm\s+-rf\s+(?:/|[A-Z]:[\\/]|~)", re.IGNORECASE)),
    # external_messaging — 외부 가시 채널
    ("external_messaging",
     re.compile(r"\bgh\s+(?:issue|pr)\s+(?:create|comment)\b", re.IGNORECASE)),
    ("external_messaging",
     re.compile(r"\bcurl\s+-X\s*(?:POST|PUT|DELETE)\s+https?://(?!localhost|127\.|10\.10\.)",
                re.IGNORECASE)),
    # git_config — 거버넌스 우회
    ("git_config",
     re.compile(r"\bgit\s+config\s+(?:--global\s+)?remote\.", re.IGNORECASE)),
    ("git_config",
     re.compile(r"\bgit\s+push\b[^\n]*(?<!\w)--force(?![-\w])", re.IGNORECASE)),
    ("git_config",
     re.compile(r"\bgit\s+push\s+origin\s+main\b", re.IGNORECASE)),
    ("git_config",
     re.compile(r"\bgit\s+commit\s+(?:.*\s)?--no-verify\b", re.IGNORECASE)),
]

# whitelist: 명시적으로 허용되는 정상 패턴
MODE_A_WHITELIST: list[re.Pattern] = [
    re.compile(r"\bgh\s+pr\s+create\s+--fill\s+--base\s+main\s+--label\s+auto-merge\b",
               re.IGNORECASE),  # team_v5_merge.py 정상 호출
    # 참고: `docker compose down --remove-orphans` 등 -v 없는 down 은 violation 정규식이
    # `-v` 를 요구하므로 자동 통과. 별도 whitelist 항목 불필요.
]


def check_violation(command: str) -> tuple[str, str] | None:
    """Mode A 위반 패턴 감지.

    반환: (category, matched_substring) 또는 None.
    whitelist 통과 시 None.
    """
    for wl in MODE_A_WHITELIST:
        if wl.search(command):
            return None
    for category, pattern in MODE_A_VIOLATIONS:
        m = pattern.search(command)
        if m:
            return category, m.group(0)
    return None


# ---------------------------------------------------------------- 메인 hook


def evaluate(payload: dict) -> tuple[str | None, str]:
    """hook 본 로직. 반환: (decision, reason). decision=None 이면 통과."""
    if is_bypass_mode(payload):
        return None, ""

    tool = payload.get("tool_name", "")
    if tool != "Bash":
        return None, ""

    command = (payload.get("tool_input", {}) or {}).get("command", "")
    if not command:
        return None, ""

    mode, team_branches = detect_mode()
    if mode == "B":
        # Mode B 는 active_edits_preedit 가 decision_owner 검증 담당. 본 hook 은 침묵.
        return None, ""

    # Mode A: 위반 패턴 검사
    violation = check_violation(command)
    if violation is None:
        return None, ""

    category, snippet = violation
    reason = (
        f"[Mode A 거버넌스 차단] 카테고리={category}. "
        f"매칭={snippet!r}. "
        f"team-policy.json v7.1 mode_a_limits 위반. "
        f"사용자 명시 승인이 필요합니다 (Conductor 자율 금지)."
    )
    return "block", reason


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()
    payload = read_payload()
    decision, reason = evaluate(payload)
    if decision == "block":
        emit(decision="block", reason=reason)
        return 2
    return 0


def self_test() -> int:
    """dry-run 자체 검증: 9개 시나리오."""
    samples = [
        ("Bash", "ls -la", None),
        ("Bash", "git status", None),
        ("Bash", "python tools/active_work_claim.py list", None),
        ("Bash", "docker compose down -v", "destructive_system"),
        ("Bash", "docker volume rm ebs-data", "destructive_system"),
        ("Bash", "psql -c 'DROP TABLE users'", "destructive_system"),
        ("Bash", "rm -rf /home/x", "destructive_system"),
        ("Bash", "gh issue create --title 'x'", "external_messaging"),
        ("Bash", "git push origin main", "git_config"),
        ("Bash", "git push --force origin work/x", "git_config"),
        ("Bash", "git push --force-with-lease origin work/x", None),  # whitelist via lease
        ("Bash", "git commit --no-verify -m x", "git_config"),
        ("Bash", "gh pr create --fill --base main --label auto-merge", None),  # whitelist
        ("Bash", "docker compose down --remove-orphans", None),  # whitelist
        ("Write", None, None),  # non-Bash: skip
    ]
    failed = 0
    for tool, command, expect_category in samples:
        payload = {"tool_name": tool, "tool_input": {"command": command} if command else {}}
        # Mode 강제 — self_test 는 Mode A 가정 (worktree 무관)
        # check_violation 만 호출하여 카테고리 검증
        if tool != "Bash" or not command:
            actual = None
        else:
            v = check_violation(command)
            actual = v[0] if v else None
        ok = (actual == expect_category)
        status = "PASS" if ok else "FAIL"
        if not ok:
            failed += 1
        print(f"[{status}] tool={tool} cmd={command!r} expected={expect_category} got={actual}")
    print()
    mode, branches = detect_mode()
    print(f"current mode: {mode} (team_branches={branches})")
    if failed:
        print(f"\n{failed} test(s) FAILED", file=sys.stderr)
        return 1
    print("\nall tests PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
