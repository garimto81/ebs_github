#!/usr/bin/env python3
"""V9.2 safe-merge checklist runner.

Runs pre-merge gate checks on a PR before allowing squash merge:
  1. scope_check.py PASS (single category or mixed-scope labeled)
  2. CI status checks all green
  3. CODEOWNERS reviewers approved (warning only on free-tier)
  4. governance-change PR requires 2+ approvals (warning)

Usage:
  PR_NUMBER=75 python tools/team_v92_safe_merge.py [--merge]

Without --merge: dry-run, prints checklist result.
With --merge: invokes `gh pr merge --squash --delete-branch` after all gates pass.
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys


def run(cmd: list[str]) -> tuple[int, str, str]:
    p = subprocess.run(cmd, capture_output=True, text=True, errors="replace")
    return p.returncode, p.stdout.strip(), p.stderr.strip()


def gate_scope(pr: str) -> bool:
    code, out, _ = run(
        ["python", "tools/scope_check.py"]
    )
    print(out)
    return code == 0


def gate_checks(pr: str) -> bool:
    code, out, _ = run(["gh", "pr", "checks", pr, "--json", "name,state,conclusion"])
    if code != 0:
        print(f"[gate_checks] gh pr checks failed: {out}")
        return False
    try:
        checks = json.loads(out)
    except Exception:
        return False
    pending = [c for c in checks if c.get("state") == "IN_PROGRESS"]
    failed = [c for c in checks if c.get("conclusion") in ("FAILURE", "CANCELLED")]
    if pending:
        print(f"[gate_checks] {len(pending)} pending checks")
        return False
    if failed:
        names = ", ".join(c["name"] for c in failed)
        print(f"[gate_checks] FAIL: {names}")
        return False
    print(f"[gate_checks] PASS: {len(checks)} checks green")
    return True


def gate_reviews(pr: str) -> tuple[bool, list[str]]:
    code, out, _ = run(
        ["gh", "pr", "view", pr, "--json", "reviewDecision,labels,reviews"]
    )
    if code != 0:
        return True, ["gh pr view failed (warning only)"]
    try:
        data = json.loads(out)
    except Exception:
        return True, ["json parse failed (warning only)"]
    decision = data.get("reviewDecision")
    labels = {l["name"] for l in data.get("labels", [])}
    approvals = sum(1 for r in data.get("reviews", []) if r.get("state") == "APPROVED")
    warnings: list[str] = []
    if "governance-change" in labels and approvals < 2:
        warnings.append(f"governance-change PR has {approvals}/2 approvals")
    if decision != "APPROVED":
        warnings.append(f"reviewDecision={decision}")
    return True, warnings  # warning only


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--merge", action="store_true")
    parser.add_argument("--pr", default=os.environ.get("PR_NUMBER", ""))
    args = parser.parse_args()
    pr = args.pr
    if not pr:
        sys.exit("PR_NUMBER required (env or --pr)")

    print(f"[safe_merge] gating PR #{pr}")
    ok_scope = gate_scope(pr)
    ok_checks = gate_checks(pr)
    ok_reviews, warnings = gate_reviews(pr)
    for w in warnings:
        print(f"[gate_reviews] warning: {w}")

    if not (ok_scope and ok_checks):
        print("[safe_merge] FAIL: gates not satisfied")
        return 1
    print("[safe_merge] all gates pass")

    if args.merge:
        code, out, err = run(
            ["gh", "pr", "merge", pr, "--squash", "--delete-branch"]
        )
        if code != 0:
            print(f"[safe_merge] merge failed: {err or out}")
            return 1
        print(f"[safe_merge] merged PR #{pr}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
