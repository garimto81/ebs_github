#!/usr/bin/env python3
"""V9.2 Day 0 conflict classifier.

Parse finalize.json and split conflict worktrees into:
  - absorbed: only add/add or modify/delete conflicts (main wins, work tree branch is stale)
  - content: at least one CONFLICT (content) — real merge conflict, branch carries unmerged work
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path


def classify(reason: str) -> str:
    if not reason:
        return "unknown"
    has_content = bool(re.search(r"CONFLICT \(content\)", reason))
    has_add = bool(re.search(r"CONFLICT \(add/add\)", reason))
    has_mod_del = bool(re.search(r"CONFLICT \(modify/delete\)", reason))

    if has_content:
        return "content"
    if has_add or has_mod_del:
        return "absorbed"
    return "unknown"


def main() -> int:
    repo = Path(__file__).resolve().parent.parent
    fin = repo / ".scratch" / "v92-day0-finalize.json"
    data = json.loads(fin.read_text(encoding="utf-8"))

    rows = []
    for r in data["results"]:
        status = r["status"]
        sub = ""
        if status == "conflict":
            sub = classify(r.get("reason", ""))
        rows.append(
            {
                "name": r["name"],
                "branch": r.get("branch"),
                "status": status,
                "conflict_kind": sub,
            }
        )

    # Categories
    absorbed = [r for r in rows if r["status"] == "empty_after_squash"]
    absorbed += [r for r in rows if r["status"] == "conflict" and r["conflict_kind"] == "absorbed"]
    real_work = [r for r in rows if r["status"] == "conflict" and r["conflict_kind"] == "content"]
    other = [r for r in rows if r["status"] not in ("empty_after_squash", "conflict")]

    print(f"=== Absorbed (already in main, worktree stale): {len(absorbed)} ===")
    for r in absorbed:
        print(f"  {r['name']:30s} ({r['status']}/{r['conflict_kind']})")

    print(f"\n=== Real in-flight (content conflict, preserve): {len(real_work)} ===")
    for r in real_work:
        print(f"  {r['name']:30s}")

    print(f"\n=== Other ({len(other)}) ===")
    for r in other:
        print(f"  {r['name']:30s} status={r['status']}")

    out = {
        "absorbed": absorbed,
        "real_work": real_work,
        "other": other,
    }
    (repo / ".scratch" / "v92-day0-classification.json").write_text(
        json.dumps(out, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
