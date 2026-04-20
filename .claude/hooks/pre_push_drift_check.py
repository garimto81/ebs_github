#!/usr/bin/env python3
"""Pre-push drift check — git push 전에 신규 spec drift 를 경고.

Type D1/D3 가 누적되어 기획서 정본성이 훼손되는 것을 방지.

이 hook 은 **차단(blocking) 하지 않는다** — 경고만 stdout 으로 출력한다.
사용자가 실제 push 를 원하면 그대로 진행된다.

트리거:
  PreToolUse matcher="Bash" 에서 command 가 `git push` 로 시작하는 경우만 동작.
  다른 Bash 명령은 silently pass.

동작:
  1. `tools/spec_drift_check.py --all --format=json` 실행
  2. Registry baseline 과 비교 (선택적 — baseline 없으면 경고만)
  3. 신규 drift 가 있으면 stdout 에 경고 + SG 승격 권고
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

# hook 은 stdin JSON 을 받는다 (Claude Code PreToolUse 스펙)
# { "tool_name": "Bash", "tool_input": {"command": "..."} }


def main() -> int:
    try:
        payload = json.loads(sys.stdin.read() or "{}")
    except json.JSONDecodeError:
        return 0

    tool_input = payload.get("tool_input", {})
    command = tool_input.get("command", "")

    # git push 명령만 감지
    if not _is_git_push(command):
        return 0

    project_dir = os.environ.get("CLAUDE_PROJECT_DIR")
    if not project_dir:
        return 0
    repo = Path(project_dir)
    scanner = repo / "tools" / "spec_drift_check.py"
    if not scanner.exists():
        return 0

    try:
        res = subprocess.run(
            ["python", str(scanner), "--all", "--format=json"],
            capture_output=True,
            text=True,
            timeout=30,
            cwd=str(repo),
        )
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return 0

    if res.returncode != 0:
        return 0

    try:
        reports = json.loads(res.stdout)
    except json.JSONDecodeError:
        return 0

    total_d1 = sum(len(r.get("d1", [])) for r in reports)
    total_d3 = sum(len(r.get("d3", [])) for r in reports)

    # baseline 비교 (선택적)
    baseline_path = repo / "logs" / "drift_report.json"
    baseline_d1 = baseline_d3 = 0
    if baseline_path.exists():
        try:
            baseline = json.loads(baseline_path.read_text(encoding="utf-8"))
            baseline_d1 = sum(len(r.get("d1", [])) for r in baseline)
            baseline_d3 = sum(len(r.get("d3", [])) for r in baseline)
        except (json.JSONDecodeError, OSError):
            pass

    new_d1 = total_d1 - baseline_d1
    new_d3 = total_d3 - baseline_d3

    if new_d1 > 0 or new_d3 > 0:
        print("=" * 60, file=sys.stderr)
        print("[pre_push_drift_check] 신규 spec drift 감지", file=sys.stderr)
        print("=" * 60, file=sys.stderr)
        if new_d1 > 0:
            print(f"  D1 (값 불일치): +{new_d1} (total {total_d1})", file=sys.stderr)
        if new_d3 > 0:
            print(f"  D3 (문서 누락): +{new_d3} (total {total_d3})", file=sys.stderr)
        print("", file=sys.stderr)
        print("권장: push 후 SG 승격 또는 기획 정정 PR 생성", file=sys.stderr)
        print("  python tools/spec_drift_check.py --all", file=sys.stderr)
        print("  docs/4. Operations/Spec_Gap_Registry.md 갱신", file=sys.stderr)
        print("=" * 60, file=sys.stderr)

    # 항상 exit 0 — non-blocking
    return 0


def _is_git_push(command: str) -> bool:
    """`git push`, `git push origin main`, `git -c ... push` 등 감지."""
    tokens = command.strip().split()
    if not tokens:
        return False
    # git 인자 skip 후 'push' 찾기
    i = 0
    while i < len(tokens):
        if tokens[i] == "git":
            # 이어지는 -c x=y, --option 등 skip
            j = i + 1
            while j < len(tokens) and tokens[j].startswith("-"):
                # -c key=val 는 2토큰이 아니라 1토큰 — shell 분리에 따라 달라짐. 보수적으로 처리
                if tokens[j] in ("-c", "--git-dir", "--work-tree"):
                    j += 2
                else:
                    j += 1
            if j < len(tokens) and tokens[j] == "push":
                return True
        i += 1
    return False


if __name__ == "__main__":
    sys.exit(main())
