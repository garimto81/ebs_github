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


def fetch_folder_descendants(cfg: dict, folder_id: str) -> dict[str, str]:
    """Fetch all pages anywhere under folder (recursive). Return {id: title}."""
    import requests
    auth = (cfg["email"], cfg["token"])

    def children(pid: str) -> list[dict]:
        out = []
        start = 0
        while True:
            url = f"{cfg['base_url']}/rest/api/content/{pid}/child/page"
            try:
                resp = requests.get(url, auth=auth, params={"limit": 100, "start": start}, timeout=30)
                if not resp.ok:
                    break
                data = resp.json()
                results = data.get("results", [])
                out.extend(results)
                if len(results) < 100:
                    break
                start += 100
            except Exception:
                break
        return out

    all_pages: dict[str, str] = {}

    def recurse(pid: str, depth: int = 0):
        if depth > 10:
            return
        for c in children(pid):
            cid = c["id"]
            if cid in all_pages:
                continue
            all_pages[cid] = c["title"]
            recurse(cid, depth + 1)

    recurse(folder_id)
    return all_pages


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--filter", help="Glob filter")
    ap.add_argument("--reverse", action="store_true",
                    help="Also report Confluence-only pages (orphans not in local frontmatter)")
    ap.add_argument("--folder-id", default="3184328827",
                    help="Folder ID for reverse drift check")
    args = ap.parse_args()

    cfg = get_config()
    if not cfg["email"] or not cfg["token"]:
        print("ERROR: ATLASSIAN_EMAIL/TOKEN required", file=sys.stderr)
        return 2

    targets = find_mirror_targets(args.filter)
    if not targets:
        print("No mirror targets found.")
        return 0

    print(f"[Forward drift] Checking {len(targets)} mirror target(s)...\n")
    drift_count = 0
    declared_ids: set[str] = set()
    for md, page_id, expected_parent in targets:
        declared_ids.add(page_id)
        try:
            live_parent, title = get_live_parent(cfg, page_id)
        except Exception as e:
            print(f"  [ERR ] {page_id}: {e}")
            drift_count += 1
            continue

        if expected_parent and live_parent != expected_parent:
            print(f"  [DRIFT] {page_id} ({title[:50]})")
            print(f"          expected parent: {expected_parent}")
            print(f"          live parent:     {live_parent}")
            drift_count += 1
        else:
            parent_msg = f" (parent {live_parent})" if live_parent else " (folder root)"
            print(f"  [OK   ] {page_id} ({title[:50]}){parent_msg}")

    print()
    print(f"Forward drift: {len(targets) - drift_count}/{len(targets)} aligned, drift={drift_count}")

    # Reverse drift — Confluence-only orphans
    orphan_count = 0
    if args.reverse:
        print(f"\n[Reverse drift] Folder {args.folder_id} descendants vs frontmatter...")
        live = fetch_folder_descendants(cfg, args.folder_id)
        # Confluence-side IDs not declared by any local frontmatter
        # Plus Game Rules parent (3812360338) is a structural parent (auto-allowed)
        STRUCTURAL_ALLOWED = {"3812360338"}  # Game Rules parent
        orphans = [(pid, title) for pid, title in live.items()
                   if pid not in declared_ids and pid not in STRUCTURAL_ALLOWED]
        for pid, title in orphans:
            print(f"  [ORPHAN] {pid}  {title[:60]}")
            orphan_count += 1
        print()
        print(f"Reverse drift: {orphan_count} Confluence-only orphans")

    total = drift_count + orphan_count
    print(f"\nTotal violations: forward={drift_count} + reverse={orphan_count} = {total}")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
