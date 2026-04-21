#!/usr/bin/env python3
"""setup_team_worktrees.py — 팀별 sibling-dir worktree 일괄 생성 (idempotent).

목적:
  `docs/4. Operations/Multi_Session_Workflow.md` v4.1 + `feedback_worktree_policy`
  가 규정한 sibling-dir 패턴 (`C:/claude/ebs-team{N}-<slug>/`) 을 실제 환경에 적용.
  subdir 모드 세션의 shared HEAD 오염을 근본 차단.

Usage:
  python tools/setup_team_worktrees.py                      # 전 팀 (team1~4) 기본 slug
  python tools/setup_team_worktrees.py --team team2         # 특정 팀만
  python tools/setup_team_worktrees.py --team team2 --slug wsop-alignment
  python tools/setup_team_worktrees.py --list               # 현재 worktree 목록

기본 slug: "work" (날짜 무관 상시 worktree). 재호출 시 이미 존재하면 skip.

결과:
  ../ebs-team{N}-{slug}/  sibling dir 생성 + work/team{N}/{slug} 브랜치 체크아웃

Exit:
  0 — 모든 요청 성공 또는 skip
  1 — 일부 실패
  2 — 스크립트 오류 (git 명령 불가 등)
"""
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PARENT = REPO.parent


def _run(cmd: list[str], cwd: Path | None = None) -> tuple[int, str]:
    try:
        r = subprocess.run(cmd, cwd=cwd or REPO, capture_output=True, text=True, timeout=30)
        return r.returncode, (r.stdout + r.stderr).strip()
    except Exception as e:
        return 1, str(e)


def list_worktrees() -> None:
    code, out = _run(["git", "worktree", "list"])
    print(out)


def setup_one(team: str, slug: str) -> bool:
    """단일 팀 worktree 생성. 이미 있으면 True 반환 (idempotent)."""
    wt_path = PARENT / f"ebs-{team}-{slug}"
    branch = f"work/{team}/{slug}"

    if wt_path.exists():
        print(f"  ✓ {team} worktree 이미 존재: {wt_path}")
        return True

    # 브랜치가 이미 있는지 확인
    rc, _ = _run(["git", "rev-parse", "--verify", branch])
    branch_exists = (rc == 0)

    if branch_exists:
        # 기존 브랜치를 worktree 로 체크아웃
        rc, out = _run(["git", "worktree", "add", str(wt_path), branch])
    else:
        # 신규 브랜치 + worktree 동시 생성
        rc, out = _run(["git", "worktree", "add", "-b", branch, str(wt_path), "main"])

    if rc == 0:
        print(f"  ✅ {team}: {wt_path} (branch: {branch})")
        return True
    else:
        print(f"  ❌ {team}: 생성 실패 — {out[:200]}")
        return False


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--team", choices=("team1", "team2", "team3", "team4", "all"),
                    default="all", help="대상 팀")
    ap.add_argument("--slug", default="work", help="worktree slug (기본: work)")
    ap.add_argument("--list", action="store_true", help="현재 worktree 목록 출력 후 종료")
    args = ap.parse_args()

    if args.list:
        list_worktrees()
        return 0

    # git 가용성 확인
    rc, _ = _run(["git", "rev-parse", "--show-toplevel"])
    if rc != 0:
        print("[error] git repo 에서 실행되지 않았습니다.", file=sys.stderr)
        return 2

    teams = ("team1", "team2", "team3", "team4") if args.team == "all" else (args.team,)

    print(f"=== Sibling worktree setup (parent: {PARENT}) ===\n")
    success_count = 0
    for team in teams:
        if setup_one(team, args.slug):
            success_count += 1

    print(f"\n완료: {success_count}/{len(teams)} 팀")
    print("\n다음 단계:")
    print(f"  1. 팀 Claude Code 세션을 해당 경로에서 시작:")
    for team in teams:
        print(f"     cd {PARENT}/ebs-{team}-{args.slug} && claude")
    print(f"  2. 세션 시작 시 session_branch_init 이 이미 올바른 브랜치 확인")
    print(f"  3. 작업 완료는 /team 로 (10-Phase 자동 실행)")

    return 0 if success_count == len(teams) else 1


if __name__ == "__main__":
    sys.exit(main())
