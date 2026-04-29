#!/usr/bin/env python3
"""V9.2 Day 0 — attempt rebase of real-work worktrees onto origin/main.

Conservative: any rebase conflict triggers `git rebase --abort` and the
worktree is left in its original state. Real work is never destroyed.
"""
from __future__ import annotations

import json
import subprocess
from pathlib import Path
from typing import Any


def run(
    cmd: list[str], cwd: str | Path | None = None
) -> tuple[int, str, str]:
    proc = subprocess.run(
        cmd, cwd=cwd, capture_output=True, text=True, errors="replace"
    )
    return proc.returncode, proc.stdout.strip(), proc.stderr.strip()


def rebase_worktree(repo: Path, name: str, branch: str) -> dict[str, Any]:
    result: dict[str, Any] = {"name": name, "branch": branch}
    wt_path = repo.parent / name
    if not wt_path.exists():
        result["status"] = "missing"
        return result

    code, head_before, _ = run(["git", "rev-parse", "HEAD"], cwd=wt_path)
    result["head_before"] = head_before[:10]

    # Make sure we have latest origin/main locally
    run(["git", "fetch", "origin", "main"], cwd=wt_path)

    code, out, err = run(
        ["git", "rebase", "origin/main"], cwd=wt_path
    )
    if code == 0:
        code, head_after, _ = run(["git", "rev-parse", "HEAD"], cwd=wt_path)
        result["status"] = "rebased"
        result["head_after"] = head_after[:10]
        return result

    # Conflict — abort
    abort_code, _, abort_err = run(["git", "rebase", "--abort"], cwd=wt_path)
    result["status"] = "conflict_aborted"
    result["abort_ok"] = abort_code == 0
    snippet = (err or out).splitlines()[:5]
    result["reason"] = " | ".join(snippet)
    return result


def main() -> int:
    repo = Path(__file__).resolve().parent.parent
    cls_path = repo / ".scratch" / "v92-day0-classification.json"
    data = json.loads(cls_path.read_text(encoding="utf-8"))

    real = data["real_work"]
    print(f"Attempting rebase on {len(real)} real-work worktrees", flush=True)

    results: list[dict[str, Any]] = []
    for r in real:
        name = r["name"]
        branch = r.get("branch", "")
        print(f"  {name:30s} ({branch})", flush=True)
        res = rebase_worktree(repo, name, branch)
        print(f"    -> {res.get('status')} {res.get('reason', '')}", flush=True)
        results.append(res)

    out = repo / ".scratch" / "v92-day0-rebase.json"
    out.write_text(
        json.dumps({"results": results}, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )

    summary: dict[str, int] = {}
    for r in results:
        summary[r["status"]] = summary.get(r["status"], 0) + 1
    print(f"\nRebase summary: {summary}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
