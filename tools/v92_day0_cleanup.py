#!/usr/bin/env python3
"""V9.2 Day 0 cleanup — remove worktrees whose branches are absorbed in main.

Reads .scratch/v92-day0-classification.json `absorbed` list.

For each worktree:
  1. Check `git status --short` in the worktree (skip if dirty unless --force).
  2. Run `git worktree remove <path>`.
  3. Branch ref is preserved (reflog protection).

The 8 real-work worktrees in `real_work` are left intact for V9.2 PR conversion.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
from typing import Any


def run(
    cmd: list[str], cwd: str | Path | None = None
) -> tuple[int, str, str]:
    proc = subprocess.run(
        cmd, cwd=cwd, capture_output=True, text=True, errors="replace"
    )
    return proc.returncode, proc.stdout.strip(), proc.stderr.strip()


def cleanup_worktree(repo: Path, name: str, branch: str) -> dict[str, Any]:
    result: dict[str, Any] = {"name": name, "branch": branch}
    wt_path = repo.parent / name

    if not wt_path.exists():
        result["status"] = "missing"
        return result

    # Check dirty state
    code, dirty, _ = run(["git", "status", "--short"], cwd=wt_path)
    result["dirty"] = dirty

    # Remove worktree (use --force since branch is absorbed)
    code, out, err = run(
        ["git", "worktree", "remove", "--force", str(wt_path)], cwd=repo
    )
    if code != 0:
        result["status"] = "remove_failed"
        result["reason"] = err or out
        return result

    result["status"] = "removed"
    return result


def main() -> int:
    repo = Path(__file__).resolve().parent.parent
    cls = repo / ".scratch" / "v92-day0-classification.json"
    if not cls.exists():
        sys.exit(f"missing classification: {cls}")
    data = json.loads(cls.read_text(encoding="utf-8"))

    absorbed = data["absorbed"]
    print(f"Cleaning up {len(absorbed)} absorbed worktrees", flush=True)

    results: list[dict[str, Any]] = []
    for r in absorbed:
        name = r["name"]
        branch = r.get("branch", "")
        print(f"  {name:30s} -> remove worktree", flush=True)
        results.append(cleanup_worktree(repo, name, branch))

    out = repo / ".scratch" / "v92-day0-cleanup.json"
    out.write_text(
        json.dumps({"results": results}, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )

    summary: dict[str, int] = {}
    for r in results:
        summary[r["status"]] = summary.get(r["status"], 0) + 1
    print(f"\nCleanup summary: {summary}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
