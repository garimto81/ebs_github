#!/usr/bin/env python3
"""V9.2 Day 0 Migration Analyzer.

Scan all sibling worktrees, classify by mergeability:
  - merged: HEAD is ancestor of origin/main (already integrated)
  - clean: ahead of origin/main, no file overlap with peers
  - conflict-risk: overlapping files with peers or older base
Output JSON for batch finalize.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any


def run(cmd: list[str], cwd: str | Path | None = None) -> tuple[int, str, str]:
    proc = subprocess.run(
        cmd, cwd=cwd, capture_output=True, text=True, errors="replace"
    )
    return proc.returncode, proc.stdout.strip(), proc.stderr.strip()


def list_worktrees(repo: Path) -> list[dict[str, str]]:
    code, out, _ = run(["git", "worktree", "list", "--porcelain"], cwd=repo)
    if code != 0:
        sys.exit(f"git worktree list failed: {code}")
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
        elif line.startswith("detached"):
            cur["detached"] = "true"
    if cur:
        items.append(cur)
    return items


def classify_worktree(repo: Path, wt: dict[str, str]) -> dict[str, Any]:
    path = wt["path"]
    branch = wt.get("branch", "(detached)")
    head = wt.get("head", "")
    name = Path(path).name

    if name == "ebs":
        return {**wt, "category": "main_repo", "skip": True}

    # Ancestor check: is HEAD already in origin/main?
    code, _, _ = run(
        ["git", "merge-base", "--is-ancestor", head, "origin/main"], cwd=repo
    )
    if code == 0:
        return {
            **wt,
            "name": name,
            "category": "merged",
            "skip": True,
            "reason": "HEAD is ancestor of origin/main",
        }

    # Ahead/behind vs origin/main
    code, out, _ = run(
        ["git", "rev-list", "--left-right", "--count", f"origin/main...{head}"],
        cwd=repo,
    )
    if code != 0:
        return {**wt, "name": name, "category": "error", "skip": True, "reason": out}

    parts = out.split()
    behind, ahead = int(parts[0]), int(parts[1])

    # Changed files vs merge-base with origin/main
    code, mb, _ = run(["git", "merge-base", head, "origin/main"], cwd=repo)
    base = mb if code == 0 else "origin/main"
    code, files_out, _ = run(
        ["git", "diff", "--name-only", base, head], cwd=repo
    )
    files = [f for f in files_out.splitlines() if f.strip()]

    # Recent commits
    code, log_out, _ = run(
        ["git", "log", "--oneline", f"{base}..{head}"], cwd=repo
    )
    commits = log_out.splitlines() if code == 0 else []

    return {
        **wt,
        "name": name,
        "branch": branch,
        "head": head,
        "ahead": ahead,
        "behind": behind,
        "files": files,
        "files_count": len(files),
        "commits_count": len(commits),
        "commits": commits[:5],
        "merge_base": base,
        "category": "candidate",
    }


def cross_overlap(candidates: list[dict[str, Any]]) -> dict[str, list[str]]:
    """For each candidate, list other candidates that share files."""
    overlaps: dict[str, list[str]] = {}
    by_file: dict[str, list[str]] = {}
    for c in candidates:
        for f in c.get("files", []):
            by_file.setdefault(f, []).append(c["name"])
    for c in candidates:
        peers: set[str] = set()
        for f in c.get("files", []):
            peers.update(p for p in by_file.get(f, []) if p != c["name"])
        overlaps[c["name"]] = sorted(peers)
    return overlaps


def main() -> int:
    repo = Path(__file__).resolve().parent.parent
    if not (repo / ".git").exists():
        sys.exit(f"not a git repo: {repo}")

    run(["git", "fetch", "origin", "main"], cwd=repo)
    worktrees = list_worktrees(repo)
    classified = [classify_worktree(repo, wt) for wt in worktrees]

    candidates = [c for c in classified if c.get("category") == "candidate"]
    overlaps = cross_overlap(candidates)
    for c in candidates:
        c["overlaps_with"] = overlaps[c["name"]]
        c["category"] = "clean" if not overlaps[c["name"]] else "conflict-risk"

    summary = {
        "total": len(classified),
        "main_repo": sum(1 for c in classified if c.get("category") == "main_repo"),
        "merged": sum(1 for c in classified if c.get("category") == "merged"),
        "clean": sum(1 for c in classified if c.get("category") == "clean"),
        "conflict_risk": sum(1 for c in classified if c.get("category") == "conflict-risk"),
        "error": sum(1 for c in classified if c.get("category") == "error"),
    }

    out = {
        "summary": summary,
        "worktrees": classified,
    }
    print(json.dumps(out, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
