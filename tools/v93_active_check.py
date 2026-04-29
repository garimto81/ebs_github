#!/usr/bin/env python3
"""V9.3 Mode A trigger detection (M5).

Detects whether the current session is in:
  - Mode A (single session, sibling_worktree_count == 0):
    Conductor 단독 활동. ceremony 면제. governance 외에는 main 직접 가능.
  - Mode v92_active (sibling_worktree_count >= 1):
    Hub-and-Spoke + AI 자율 머지 SOP 전체 적용.

Output: JSON with mode, sibling count, recommendation.

Usage:
  python tools/v93_active_check.py [--json]
  python tools/v93_active_check.py --explain
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


def run(cmd: list[str], cwd: str | Path | None = None) -> tuple[int, str, str]:
    p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, errors="replace")
    return p.returncode, p.stdout.strip(), p.stderr.strip()


def list_worktrees() -> list[dict[str, str]]:
    code, out, _ = run(["git", "worktree", "list", "--porcelain"])
    if code != 0:
        return []
    items: list[dict[str, str]] = []
    cur: dict[str, str] = {}
    for line in out.splitlines():
        if line.startswith("worktree "):
            if cur:
                items.append(cur)
            cur = {"path": line.split(" ", 1)[1]}
        elif line.startswith("HEAD "):
            cur["head"] = line.split(" ", 1)[1]
        elif line.startswith("branch "):
            cur["branch"] = line.split(" ", 1)[1].replace("refs/heads/", "")
    if cur:
        items.append(cur)
    return items


def detect_mode() -> dict:
    worktrees = list_worktrees()
    siblings = [
        w
        for w in worktrees
        if Path(w["path"]).name.startswith("ebs-")
        and Path(w["path"]).name != "ebs"
    ]
    main_repo = [w for w in worktrees if Path(w["path"]).name == "ebs"]

    sibling_count = len(siblings)
    if sibling_count == 0:
        mode = "mode_a_single_session"
        ceremony = "skipped"
        recommendation = (
            "Conductor 단독. main 직접 commit 허용 (governance 변경 외). "
            "PR 경로 옵션이지만 강제 아님."
        )
    else:
        mode = "v92_active"
        ceremony = "full_hub_and_spoke"
        recommendation = (
            f"{sibling_count} sibling worktree 활성. "
            "Hub-and-Spoke + AI 자율 머지 SOP 전체 적용. "
            "모든 변경은 work/* 또는 infra/* 브랜치 + PR 경로."
        )

    return {
        "mode": mode,
        "sibling_worktree_count": sibling_count,
        "main_repo_count": len(main_repo),
        "siblings": [
            {"name": Path(w["path"]).name, "branch": w.get("branch", "")}
            for w in siblings
        ],
        "ceremony": ceremony,
        "recommendation": recommendation,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--explain", action="store_true")
    args = parser.parse_args()

    result = detect_mode()

    if args.json:
        print(json.dumps(result, indent=2, ensure_ascii=False))
        return 0

    print(f"[v93_active_check] mode = {result['mode']}")
    print(f"  sibling_worktree_count: {result['sibling_worktree_count']}")
    print(f"  ceremony:               {result['ceremony']}")
    if result["siblings"]:
        print("  active siblings:")
        for s in result["siblings"]:
            print(f"    - {s['name']:30s} ({s['branch']})")
    print(f"\n  → {result['recommendation']}")

    if args.explain:
        print("\n=== V9.3 Mode A boundary ===")
        print("  sibling_worktree_count == 0 → Mode A (ceremony 면제)")
        print("  sibling_worktree_count >= 1 → v92_active (Hub-and-Spoke 강제)")
        print("\n  policy: docs/2. Development/2.5 Shared/team-policy.json")
        print("    governance_model.single_session_mode_a")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
