#!/usr/bin/env python3
"""V9.2 Day 0 batch finalize — squash-merge clean worktrees into main.

Strategy:
  1. For each candidate branch, attempt rebase onto origin/main.
  2. If clean rebase: squash-merge into main with conventional commit.
  3. If conflict: abort, mark as "needs-manual" for V9.2 path handling.

Reads classification from .scratch/v92-day0-analysis.json.
Writes finalize result to .scratch/v92-day0-finalize.json.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
from typing import Any


def run(
    cmd: list[str], cwd: str | Path | None = None, check: bool = False
) -> tuple[int, str, str]:
    proc = subprocess.run(
        cmd, cwd=cwd, capture_output=True, text=True, errors="replace"
    )
    if check and proc.returncode != 0:
        sys.exit(
            f"command failed ({proc.returncode}): {cmd}\nstdout: {proc.stdout}\nstderr: {proc.stderr}"
        )
    return proc.returncode, proc.stdout.strip(), proc.stderr.strip()


def squash_merge_branch(
    repo: Path, branch: str, name: str
) -> dict[str, Any]:
    """Attempt squash-merge of `branch` into current main.

    Returns dict with 'status' (merged|empty|conflict|error), 'commit', 'reason'.
    """
    result: dict[str, Any] = {"name": name, "branch": branch}

    # Pre-check: is branch already an ancestor of HEAD?
    code, _, _ = run(["git", "merge-base", "--is-ancestor", branch, "HEAD"], cwd=repo)
    if code == 0:
        result["status"] = "already_in_main"
        return result

    # Check if changes still exist relative to main
    code, mb, _ = run(["git", "merge-base", "HEAD", branch], cwd=repo)
    if code != 0:
        result["status"] = "error"
        result["reason"] = f"merge-base failed: {mb}"
        return result

    code, diff_out, _ = run(["git", "diff", "--name-only", mb, branch], cwd=repo)
    if code != 0 or not diff_out.strip():
        result["status"] = "empty"
        result["reason"] = "no diff vs merge-base"
        return result

    # Attempt squash merge (no commit)
    code, out, err = run(
        ["git", "merge", "--squash", "--no-commit", branch], cwd=repo
    )
    if code != 0:
        # Conflict — abort
        run(["git", "merge", "--abort"], cwd=repo)
        run(["git", "reset", "--hard", "HEAD"], cwd=repo)
        result["status"] = "conflict"
        result["reason"] = err or out
        return result

    # Verify staged changes exist
    code, staged, _ = run(["git", "diff", "--cached", "--name-only"], cwd=repo)
    if not staged.strip():
        # Reset just in case
        run(["git", "reset", "--hard", "HEAD"], cwd=repo)
        result["status"] = "empty_after_squash"
        return result

    # Get original branch tip subject for commit message
    code, subject, _ = run(
        ["git", "log", "-1", "--format=%s", branch], cwd=repo
    )
    files_changed = staged.splitlines()
    file_count = len(files_changed)

    commit_msg = (
        f"chore(v92-day0): batch finalize {name}\n\n"
        f"Original tip: {subject}\n"
        f"Branch: {branch}\n"
        f"Files: {file_count}\n"
        f"\n"
        f"V9.2 Day 0 migration — V8.0 path one-shot batch.\n"
        f"User mandate (2026-04-29 D2)."
    )

    code, out, err = run(
        ["git", "commit", "-m", commit_msg], cwd=repo
    )
    if code != 0:
        run(["git", "reset", "--hard", "HEAD"], cwd=repo)
        result["status"] = "commit_failed"
        result["reason"] = err or out
        return result

    code, head, _ = run(["git", "rev-parse", "HEAD"], cwd=repo)
    result["status"] = "merged"
    result["commit"] = head[:10]
    result["files_count"] = file_count
    result["files"] = files_changed[:10]
    return result


def main() -> int:
    repo = Path(__file__).resolve().parent.parent
    analysis_path = repo / ".scratch" / "v92-day0-analysis.json"
    if not analysis_path.exists():
        sys.exit(f"missing analysis: {analysis_path}. Run v92_day0_analyze.py first.")

    data = json.loads(analysis_path.read_text(encoding="utf-8"))
    candidates = [
        w for w in data["worktrees"]
        if w.get("category") in ("clean", "conflict-risk")
    ]
    print(f"Targeting {len(candidates)} clean worktrees for batch finalize", flush=True)

    results: list[dict[str, Any]] = []
    for c in candidates:
        branch = c.get("branch")
        name = c.get("name", branch)
        if not branch or branch == "(detached)":
            results.append({"name": name, "status": "skip", "reason": "detached"})
            continue
        print(f"\n--- finalizing {name} ({branch}) ---", flush=True)
        r = squash_merge_branch(repo, branch, name)
        print(json.dumps(r, ensure_ascii=False), flush=True)
        results.append(r)

    out_path = repo / ".scratch" / "v92-day0-finalize.json"
    out_path.write_text(
        json.dumps({"results": results}, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    print(f"\nFinalize results saved to {out_path}", flush=True)

    summary: dict[str, int] = {}
    for r in results:
        summary[r["status"]] = summary.get(r["status"], 0) + 1
    print(f"Summary: {summary}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
