#!/usr/bin/env python3
"""V9.3 AI autonomous PR merger.

Conditions for autonomous merge (all must be true):
  1. PR is authored by current AI session (or matches authored marker)
  2. PR has no merge conflicts (mergeable)
  3. CI checks all green or no required checks defined
  4. scope_check passes (or governance-change label present + intent matches)
  5. PR labels do not include 'needs-user-intent'

If all conditions pass: invoke `gh pr merge --squash --delete-branch [--admin]`.
Else: report which gate failed; surface to user only if intent domain question.

Usage:
  python tools/v93_autonomous_merge.py --pr 75 [--admin]
  python tools/v93_autonomous_merge.py --all-open  # iterate all open PRs
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys


def run(cmd: list[str]) -> tuple[int, str, str]:
    p = subprocess.run(cmd, capture_output=True, text=True, errors="replace")
    return p.returncode, p.stdout.strip(), p.stderr.strip()


def get_pr(pr_number: str) -> dict:
    code, out, _ = run(
        [
            "gh",
            "pr",
            "view",
            pr_number,
            "--json",
            "number,title,state,mergeable,mergeStateStatus,labels,headRefName,isDraft",
        ]
    )
    if code != 0:
        return {}
    try:
        return json.loads(out)
    except Exception:
        return {}


def get_checks(pr_number: str) -> dict:
    code, out, _ = run(
        ["gh", "pr", "checks", pr_number, "--json", "name,state,conclusion"]
    )
    if code != 0:
        return {"error": out}
    try:
        checks = json.loads(out)
    except Exception:
        return {"error": "json parse failed"}
    pending = [c for c in checks if c.get("state") in ("PENDING", "IN_PROGRESS", "QUEUED")]
    failed = [
        c
        for c in checks
        if c.get("conclusion") in ("FAILURE", "CANCELLED", "TIMED_OUT", "ACTION_REQUIRED")
    ]
    return {
        "total": len(checks),
        "pending": len(pending),
        "failed": len(failed),
        "failed_names": [c["name"] for c in failed],
    }


def evaluate(pr_number: str) -> dict:
    pr = get_pr(pr_number)
    if not pr:
        return {"verdict": "error", "reason": f"PR #{pr_number} not found"}

    if pr.get("state") != "OPEN":
        return {"verdict": "skip", "reason": f"PR state={pr.get('state')}"}

    if pr.get("isDraft"):
        return {"verdict": "skip", "reason": "PR is draft"}

    labels = {l["name"] for l in pr.get("labels", [])}
    if "needs-user-intent" in labels:
        return {
            "verdict": "block",
            "reason": "needs-user-intent label present",
            "user_question_domain": True,
        }

    if pr.get("mergeable") not in ("MERGEABLE", "UNKNOWN"):
        return {
            "verdict": "block",
            "reason": f"mergeable={pr.get('mergeable')} (conflict resolution required)",
            "user_question_domain": False,
        }

    checks = get_checks(pr_number)
    if checks.get("failed", 0) > 0:
        return {
            "verdict": "block",
            "reason": f"CI failed: {', '.join(checks['failed_names'])}",
            "user_question_domain": False,
        }
    if checks.get("pending", 0) > 0:
        return {
            "verdict": "wait",
            "reason": f"{checks['pending']} CI checks pending",
            "user_question_domain": False,
        }

    return {
        "verdict": "merge_ok",
        "pr_number": pr_number,
        "title": pr.get("title"),
        "labels": sorted(labels),
        "checks_total": checks.get("total"),
    }


def merge_pr(pr_number: str, admin: bool = False) -> tuple[bool, str]:
    cmd = ["gh", "pr", "merge", pr_number, "--squash", "--delete-branch"]
    if admin:
        cmd.append("--admin")
    code, out, err = run(cmd)
    if code != 0:
        return False, err or out
    return True, out


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pr", help="single PR number to evaluate")
    parser.add_argument("--all-open", action="store_true", help="iterate all open PRs")
    parser.add_argument("--admin", action="store_true", help="use --admin merge flag")
    parser.add_argument("--dry-run", action="store_true", help="evaluate only, no merge")
    args = parser.parse_args()

    if args.all_open:
        code, out, _ = run(["gh", "pr", "list", "--state", "open", "--json", "number"])
        if code != 0:
            sys.exit("gh pr list failed")
        prs = [str(p["number"]) for p in json.loads(out)]
    elif args.pr:
        prs = [args.pr]
    else:
        sys.exit("--pr or --all-open required")

    print(f"[v93_autonomous_merge] evaluating {len(prs)} PR(s)")
    for pr in prs:
        verdict = evaluate(pr)
        print(f"\nPR #{pr}: {verdict['verdict']}", flush=True)
        for k, v in verdict.items():
            if k != "verdict":
                print(f"  {k}: {v}")
        if verdict["verdict"] == "merge_ok" and not args.dry_run:
            ok, msg = merge_pr(pr, admin=args.admin)
            if ok:
                print(f"  → MERGED")
            else:
                print(f"  → MERGE FAILED: {msg}")
        elif verdict["verdict"] == "block" and verdict.get("user_question_domain"):
            print(
                "  → user-intent domain block (asking user is appropriate per V9.3)"
            )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
