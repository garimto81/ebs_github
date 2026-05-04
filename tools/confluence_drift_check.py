#!/usr/bin/env python3
"""confluence_drift_check — Verify local frontmatter ↔ Confluence ancestors alignment.

For each docs/*.md with confluence-page-id + (optional) confluence-parent-id,
check that the live Confluence page is under the declared parent. Reports drift.

SG-031 Phase 2 — drift gate baseline.

Usage:
    python tools/confluence_drift_check.py [--filter <glob>]

Exit codes:
    0 — no drift
    1 — drift detected (use for CI gate)
    2 — config / network error
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, "C:/claude")
from lib.confluence.md2confluence import api_get, get_config

# Reuse frontmatter parser from sync_confluence.py
sys.path.insert(0, str(Path(__file__).resolve().parent))
from sync_confluence import parse_frontmatter, find_mirror_targets


def get_live_parent(cfg: dict, page_id: str) -> tuple[str | None, str]:
    """Return (parent_id_or_None, title) from live Confluence."""
    info = api_get(cfg, f"/content/{page_id}", {"expand": "ancestors,version"})
    title = info["title"]
    ancestors = info.get("ancestors", [])
    if ancestors:
        return (ancestors[-1]["id"], title)
    return (None, title)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--filter", help="Glob filter")
    args = ap.parse_args()

    cfg = get_config()
    if not cfg["email"] or not cfg["token"]:
        print("ERROR: ATLASSIAN_EMAIL/TOKEN required", file=sys.stderr)
        return 2

    targets = find_mirror_targets(args.filter)
    if not targets:
        print("No mirror targets found.")
        return 0

    print(f"Checking drift for {len(targets)} mirror target(s)...\n")
    drift_count = 0
    for md, page_id, expected_parent in targets:
        try:
            live_parent, title = get_live_parent(cfg, page_id)
        except Exception as e:
            print(f"  [ERR ] {page_id}: {e}")
            drift_count += 1
            continue

        # Compare expected vs live parent
        # If frontmatter has no parent-id, expected_parent is None — accept anything
        # If frontmatter has parent-id, must match exactly
        if expected_parent and live_parent != expected_parent:
            print(f"  [DRIFT] {page_id} ({title[:50]})")
            print(f"          expected parent: {expected_parent}")
            print(f"          live parent:     {live_parent}")
            drift_count += 1
        else:
            parent_msg = f" (parent {live_parent})" if live_parent else " (folder root)"
            print(f"  [OK   ] {page_id} ({title[:50]}){parent_msg}")

    print()
    print(f"Result: {len(targets) - drift_count}/{len(targets)} aligned, drift={drift_count}")
    return 1 if drift_count else 0


if __name__ == "__main__":
    sys.exit(main())
