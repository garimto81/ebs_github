#!/usr/bin/env python3
"""팀 작업 브랜치 → main 통합 도구.

흐름:
1. fetch origin
2. 작업 브랜치에서 git rebase main
3. main 체크아웃 + git merge --ff-only work/...
4. 작업 브랜치 삭제 (--delete-branch 시)
5. 원격 push (--push 시, conductor만 권장)

Usage:
    python tools/team_merge.py                    # rebase + ff merge (push 안 함)
    python tools/team_merge.py --push             # + main push
    python tools/team_merge.py --delete-branch    # + 로컬 브랜치 삭제
    python tools/team_merge.py --abort            # rebase 중단 시
"""
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent


def run(*args: str, check: bool = True) -> tuple[int, str]:
    r = subprocess.run(["git", *args], cwd=PROJECT, capture_output=True, text=True)
    out = (r.stdout + r.stderr).strip()
    if check and r.returncode != 0:
        print(f"[git {' '.join(args)}] FAIL\n{out}", file=sys.stderr)
        sys.exit(r.returncode)
    return r.returncode, out


def current_branch() -> str:
    _, out = run("branch", "--show-current")
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--push", action="store_true", help="merge 후 origin main으로 push")
    ap.add_argument("--delete-branch", action="store_true", help="merge 후 작업 브랜치 삭제")
    ap.add_argument("--abort", action="store_true", help="진행 중인 rebase 중단")
    ap.add_argument("--remote", default="origin", help="기본 원격 (default: origin)")
    args = ap.parse_args()

    if args.abort:
        run("rebase", "--abort", check=False)
        print("rebase aborted")
        return 0

    branch = current_branch()
    if not branch.startswith("work/"):
        print(f"ERROR: 현재 브랜치가 work/* 가 아님 ({branch}). 작업 브랜치에서 실행하세요.",
              file=sys.stderr)
        return 1

    print(f"=== team_merge: {branch} → main ===")

    # 1) fetch
    print("[1/5] git fetch ...")
    run("fetch", args.remote, check=False)

    # 2) rebase main
    print(f"[2/5] git rebase {args.remote}/main ...")
    code, out = run("rebase", f"{args.remote}/main", check=False)
    if code != 0:
        print(f"\nrebase 충돌 발생. 수동으로 해결 후 `git rebase --continue`,\n"
              f"중단하려면 `python tools/team_merge.py --abort`\n\n{out}",
              file=sys.stderr)
        return code

    # 3) checkout main
    print("[3/5] git checkout main ...")
    run("checkout", "main")

    # 4) ff merge
    print(f"[4/5] git merge --ff-only {branch} ...")
    code, out = run("merge", "--ff-only", branch, check=False)
    if code != 0:
        print(f"ff merge 실패 (예상 외): {out}", file=sys.stderr)
        run("checkout", branch, check=False)
        return code

    # 5) push (선택)
    if args.push:
        print(f"[5/5] git push {args.remote} main ...")
        run("push", args.remote, "main")
    else:
        print("[5/5] push 생략 (--push 미지정)")

    if args.delete_branch:
        print(f"브랜치 삭제: {branch}")
        run("branch", "-d", branch, check=False)

    print(f"\n완료: {branch} → main")
    return 0


if __name__ == "__main__":
    sys.exit(main())
