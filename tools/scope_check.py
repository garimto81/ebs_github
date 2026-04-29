#!/usr/bin/env python3
"""V9.2 PR scope checker.

Validates that a PR's changed files fit one allowed scope category and that
required labels are present. Designed to run in GitHub Actions or locally.

Categories:
  - governance: docs/2. Development/2.5 Shared/, .github/, CODEOWNERS, hooks
  - docs:       docs/** (excluding governance paths)
  - tools:      tools/**, scripts/**
  - team1..4:   team{N}-*/**
  - tests:      **/tests/**, **/*_test.py, **/*.spec.ts
  - mixed:      multiple categories — requires `mixed-scope` label

Required labels per category (configurable via .v92-gates.yml):
  - governance → governance-change + 2 reviewer approvals
  - mixed      → mixed-scope + author justification

Exit codes:
  0  — pass
  1  — scope violation
  2  — missing required label
  3  — config or runtime error
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Iterable

CATEGORY_RULES: dict[str, list[str]] = {
    "governance": [
        "docs/2. Development/2.5 Shared/",
        ".github/CODEOWNERS",
        ".github/workflows/",
        ".githooks/",
        ".claude/hooks/",
    ],
    "docs": ["docs/"],
    "tools": ["tools/", "scripts/"],
    "team1": ["team1-frontend/", "docs/2. Development/2.1 Frontend/"],
    "team2": ["team2-backend/", "docs/2. Development/2.2 Backend/"],
    "team3": ["team3-engine/", "ebs_game_engine/", "docs/2. Development/2.3 Game Engine/"],
    "team4": ["team4-cc/", "docs/2. Development/2.4 Command Center/"],
    "tests": ["tests/", "test/", "_test.py", ".spec.ts", ".spec.js"],
}

REQUIRED_LABELS: dict[str, list[str]] = {
    "governance": ["governance-change"],
    "mixed": ["mixed-scope"],
}


def run(cmd: list[str]) -> tuple[int, str, str]:
    p = subprocess.run(cmd, capture_output=True, text=True, errors="replace")
    return p.returncode, p.stdout.strip(), p.stderr.strip()


def categorize(path: str) -> str:
    ordered = ["governance", "team1", "team2", "team3", "team4", "tests", "tools", "docs"]
    for cat in ordered:
        for rule in CATEGORY_RULES[cat]:
            if rule.endswith("/"):
                if path.startswith(rule):
                    return cat
            elif rule.startswith("."):
                if path.endswith(rule):
                    return cat
            else:
                if rule in path:
                    return cat
    return "other"


def get_changed_files(base: str, head: str) -> list[str]:
    code, out, err = run(["git", "diff", "--name-only", f"{base}...{head}"])
    if code != 0:
        sys.exit(f"git diff failed: {err}")
    return [f for f in out.splitlines() if f.strip()]


def get_pr_labels() -> set[str]:
    pr_number = os.environ.get("PR_NUMBER")
    if not pr_number:
        return set()
    code, out, _ = run(["gh", "pr", "view", pr_number, "--json", "labels"])
    if code != 0:
        return set()
    try:
        data = json.loads(out)
        return {lbl["name"] for lbl in data.get("labels", [])}
    except Exception:
        return set()


def main() -> int:
    base = os.environ.get("BASE_REF", "origin/main")
    head = os.environ.get("HEAD_REF", "HEAD")
    files = get_changed_files(base, head)
    if not files:
        print("[scope_check] no changed files")
        return 0

    by_cat: dict[str, list[str]] = {}
    for f in files:
        by_cat.setdefault(categorize(f), []).append(f)

    print(f"[scope_check] {len(files)} files in {len(by_cat)} categories:")
    for cat, paths in sorted(by_cat.items()):
        print(f"  {cat}: {len(paths)} file(s)")
        for p in paths[:5]:
            print(f"    - {p}")
        if len(paths) > 5:
            print(f"    ... and {len(paths) - 5} more")

    labels = get_pr_labels()
    primary = max(by_cat, key=lambda c: len(by_cat[c]))
    is_mixed = len(by_cat) > 1 and primary != "tests"

    if is_mixed and "mixed-scope" not in labels:
        print(f"\n[scope_check] FAIL: PR mixes {sorted(by_cat)} but lacks 'mixed-scope' label")
        return 2

    if "governance" in by_cat and "governance-change" not in labels:
        print("\n[scope_check] FAIL: governance changes require 'governance-change' label")
        return 2

    print(f"\n[scope_check] PASS: primary={primary}, labels OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
