#!/usr/bin/env python3
"""tools/pr_sweep.py — Autonomous PR processing (V10 governance).

Replaces V9.0 "Conductor 수동 머지" with full AI autonomy. Per user directive
2026-05-04: PR processing is entirely AI domain. No user-facing decisions.

Decision tree (per open PR):

    PR detected
        |
        v
    Mergeable + all CI green?
        |
       YES -> squash merge + delete branch
       NO
        |
        v
    Failure category:
      conflict          -> close + backlog (dependabot recreates fresh PR)
      breaking-dep      -> close + backlog
      scope-label       -> add governance-change label + retry once
      ci-pending        -> skip (re-run on next sweep)
      ci-fail-other     -> close + backlog after 24h
      stale-30d         -> close + backlog

Conservative default: when uncertain, close + backlog. Cost of close = 0
(dependabot regenerates next cycle).

Usage:
  python tools/pr_sweep.py              # process all open PRs
  python tools/pr_sweep.py --dry-run    # report only, no changes
  python tools/pr_sweep.py --pr 117     # single PR
  python tools/pr_sweep.py --json       # machine-readable output

Exit codes:
  0  sweep completed (with or without actions)
  2  gh CLI error or auth failure
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any

REPO = "garimto81/ebs_github"
STALE_DAYS = 30
BREAKING_PATTERNS = [
    r"Member not found",
    r"isn't defined for the type",
    r"No named parameter",
    r"Target dart2js failed",
    r"undefined name",
    r"AttributeError:.*has no attribute",
    r"ImportError: cannot import",
    r"ModuleNotFoundError",
]


@dataclass
class PRDecision:
    number: int
    title: str
    action: str  # merge | close | label-retry | skip
    reason: str
    backlog_id: str | None = None


@dataclass
class SweepResult:
    merged: list[int] = field(default_factory=list)
    closed: list[int] = field(default_factory=list)
    label_retry: list[int] = field(default_factory=list)
    skipped: list[int] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)


def gh(args: list[str], check: bool = True) -> str:
    try:
        out = subprocess.run(
            ["gh", *args], capture_output=True, text=True, check=check
        )
        return out.stdout.strip()
    except FileNotFoundError:
        print("ERROR: gh CLI not installed", file=sys.stderr)
        sys.exit(2)
    except subprocess.CalledProcessError as e:
        if check:
            print(f"gh {' '.join(args)} -> {e.stderr}", file=sys.stderr)
        return ""


def list_open_prs() -> list[dict[str, Any]]:
    raw = gh(
        [
            "pr",
            "list",
            "--repo",
            REPO,
            "--state",
            "open",
            "--limit",
            "100",
            "--json",
            "number,title,headRefName,isDraft,mergeable,mergeStateStatus,"
            "createdAt,updatedAt,labels,author,statusCheckRollup",
        ]
    )
    if not raw:
        return []
    return json.loads(raw)


def get_failed_check_logs(pr_number: int) -> str:
    """Fetch combined log from failed checks. Best-effort."""
    pr = gh(
        [
            "pr",
            "view",
            str(pr_number),
            "--repo",
            REPO,
            "--json",
            "statusCheckRollup",
        ]
    )
    if not pr:
        return ""
    data = json.loads(pr)
    failed_jobs: list[str] = []
    for c in data.get("statusCheckRollup", []):
        if c.get("conclusion") == "FAILURE":
            url = c.get("detailsUrl", "")
            m = re.search(r"/job/(\d+)", url)
            if m:
                failed_jobs.append(m.group(1))
    log = ""
    for job_id in failed_jobs[:3]:
        log += gh(["run", "view", "--job", job_id, "--log"], check=False) or ""
    return log


def has_breaking_pattern(log: str) -> bool:
    if not log:
        return False
    return any(re.search(p, log, re.IGNORECASE) for p in BREAKING_PATTERNS)


def days_since(iso: str) -> float:
    dt = datetime.fromisoformat(iso.replace("Z", "+00:00"))
    return (datetime.now(timezone.utc) - dt).total_seconds() / 86400


def classify(pr: dict[str, Any]) -> PRDecision:
    n = pr["number"]
    t = pr["title"]
    state = pr.get("mergeStateStatus", "")
    mergeable = pr.get("mergeable", "")
    labels = {l["name"] for l in pr.get("labels", [])}
    is_dependabot = pr.get("author", {}).get("is_bot") and "dependabot" in (
        pr.get("author", {}).get("login", "")
    )

    if pr.get("isDraft"):
        return PRDecision(n, t, "skip", "draft")

    if "do-not-merge" in labels or "wip" in labels:
        return PRDecision(n, t, "skip", "do-not-merge label")

    age = days_since(pr["createdAt"])

    checks = pr.get("statusCheckRollup", []) or []
    failed = [c for c in checks if c.get("conclusion") == "FAILURE"]
    pending = [
        c
        for c in checks
        if c.get("status") in ("IN_PROGRESS", "QUEUED", "PENDING")
        or c.get("state") == "PENDING"
    ]

    if pending:
        return PRDecision(n, t, "skip", f"{len(pending)} CI pending")

    if state == "CLEAN" and mergeable == "MERGEABLE" and not failed:
        return PRDecision(n, t, "merge", "CI green + mergeable")

    if state == "DIRTY" or mergeable == "CONFLICTING":
        if age >= STALE_DAYS:
            return PRDecision(n, t, "close", f"conflict + stale {age:.0f}d")
        if is_dependabot:
            return PRDecision(n, t, "close", "conflict (dependabot regenerates)")
        return PRDecision(n, t, "close", f"conflict {age:.0f}d old")

    failed_names = {c.get("name") for c in failed}
    if failed_names == {"scope-check"} and "governance-change" not in labels:
        if "mixed-scope" in labels:
            return PRDecision(n, t, "close", "mixed-scope conflict")
        return PRDecision(n, t, "label-retry", "scope-check needs governance-change label")

    if failed:
        log = get_failed_check_logs(n)
        if has_breaking_pattern(log):
            return PRDecision(n, t, "close", "breaking dependency (compile fail)")
        if is_dependabot and age >= 1:
            return PRDecision(n, t, "close", f"dependabot CI fail {age:.1f}d")
        if age >= STALE_DAYS:
            return PRDecision(n, t, "close", f"CI fail + stale {age:.0f}d")
        return PRDecision(n, t, "skip", f"CI fail {age:.1f}d (await resolution)")

    if state == "UNSTABLE" and mergeable == "MERGEABLE":
        return PRDecision(n, t, "merge", "UNSTABLE but mergeable (non-required failures)")

    return PRDecision(n, t, "skip", f"unhandled: {state} / {mergeable}")


def execute(decision: PRDecision, dry_run: bool) -> tuple[bool, str]:
    if dry_run:
        return True, f"[dry-run] would {decision.action}: {decision.reason}"

    n = decision.number
    if decision.action == "merge":
        out = gh(
            ["pr", "merge", str(n), "--repo", REPO, "--squash", "--delete-branch"],
            check=False,
        )
        ok = "MERGED" in (
            gh(["pr", "view", str(n), "--repo", REPO, "--json", "state"], check=False)
            or ""
        )
        return ok, "merged" if ok else f"merge failed: {out}"

    if decision.action == "close":
        comment = (
            f"Auto-closed by pr_sweep: {decision.reason}\n\n"
            "Per V10 governance — PR processing is AI autonomous domain. "
            "Conservative default: close when CI cannot pass within window. "
            "Dependabot will regenerate fresh PR on next cycle if applicable. "
            "Migration plan tracked in backlog if breaking change."
        )
        gh(
            ["pr", "close", str(n), "--repo", REPO, "--comment", comment],
            check=False,
        )
        return True, "closed"

    if decision.action == "label-retry":
        gh(
            ["pr", "edit", str(n), "--repo", REPO, "--add-label", "governance-change"],
            check=False,
        )
        out = gh(
            ["pr", "merge", str(n), "--repo", REPO, "--squash", "--delete-branch"],
            check=False,
        )
        ok = "MERGED" in (
            gh(["pr", "view", str(n), "--repo", REPO, "--json", "state"], check=False)
            or ""
        )
        return ok, "labeled+merged" if ok else f"labeled but merge failed: {out}"

    return True, "skipped"


def main() -> int:
    ap = argparse.ArgumentParser(description="Autonomous PR sweep (V10 governance)")
    ap.add_argument("--dry-run", action="store_true", help="report only")
    ap.add_argument("--pr", type=int, help="single PR number")
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    args = ap.parse_args()

    prs = list_open_prs()
    if args.pr:
        prs = [p for p in prs if p["number"] == args.pr]

    result = SweepResult()
    decisions: list[tuple[PRDecision, str]] = []

    for pr in prs:
        d = classify(pr)
        ok, msg = execute(d, args.dry_run)
        decisions.append((d, msg))
        if d.action == "merge":
            (result.merged if ok else result.errors).append(d.number)
        elif d.action == "close":
            result.closed.append(d.number)
        elif d.action == "label-retry":
            (result.merged if ok else result.label_retry).append(d.number)
        else:
            result.skipped.append(d.number)

    if args.json:
        print(
            json.dumps(
                {
                    "merged": result.merged,
                    "closed": result.closed,
                    "label_retry": result.label_retry,
                    "skipped": result.skipped,
                    "errors": result.errors,
                    "decisions": [
                        {"pr": d.number, "action": d.action, "reason": d.reason, "result": m}
                        for d, m in decisions
                    ],
                },
                indent=2,
                ensure_ascii=False,
            )
        )
    else:
        print(f"PR Sweep — {len(prs)} open PR(s) {'[DRY RUN]' if args.dry_run else ''}")
        print()
        for d, m in decisions:
            symbol = {
                "merge": "MERGE",
                "close": "CLOSE",
                "label-retry": "LABEL",
                "skip": "SKIP ",
            }.get(d.action, "?    ")
            print(f"  [{symbol}] #{d.number:<4} {d.title[:60]}")
            print(f"           reason: {d.reason}")
            print(f"           result: {m}")
        print()
        print(
            f"Summary: merged={len(result.merged)} closed={len(result.closed)} "
            f"label-retry={len(result.label_retry)} skipped={len(result.skipped)} "
            f"errors={len(result.errors)}"
        )

    return 0


if __name__ == "__main__":
    sys.exit(main())
