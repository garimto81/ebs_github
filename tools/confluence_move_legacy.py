#!/usr/bin/env python3
"""confluence_move_legacy — Bulk move legacy Confluence pages to Legacy parent.

Moves all NOTIFY-*, IMPL-*, B-Q* pages (and other one-time broadcast pages)
to a single Legacy parent page.

SG-031 Phase 1c.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

# Reuse md2confluence helpers
sys.path.insert(0, "C:/claude")
from lib.confluence.md2confluence import api_get, api_put_json, get_config

LEGACY_PARENT_ID = "3812262096"  # EBS · Legacy

# Page IDs to move (extracted from CQL search 2026-05-04)
LEGACY_PAGE_IDS = [
    # NOTIFY broadcast (5)
    "3812066221",  # EBS · NOTIFY-ALL-SG025-026-PRODUCTION-LAUNCH
    "3811378066",  # EBS · NOTIFY-ALL-SG024-GOVERNANCE-EXPANSION
    "3811803968",  # EBS · NOTIFY-ALL-SG023-INTENT-PIVOT
    "3811902333",  # EBS · NOTIFY-ALL-PHASE2-START
    "3811640208",  # EBS · NOTIFY-conductor-B088-PR2bis-service-layer
    # IMPL audit (11)
    "3811803939",  # EBS · IMPL-011-tables-seats-delete-endpoint
    "3812000222",  # EBS · IMPL-010-tables-seats-create-endpoint
    "3811607330",  # EBS · IMPL-009-users-force-logout-endpoint
    "3811640179",  # EBS · IMPL-008-skins-deactivate-endpoint
    "3811836928",  # EBS · IMPL-007-cc-no-card-display-contract
    "3811836898",  # EBS · IMPL-006-websocket-ack-reject-publishers
    "3811902297",  # EBS · IMPL-005-team2-api-d2-routers
    "3811934935",  # EBS · IMPL-004-team1-settings-19-d3-mapping
    "3811803908",  # EBS · IMPL-003-team2-decks-db-session
    "3812000194",  # EBS · IMPL-002-team4-engine-connection-ui
    "3811902266",  # EBS · IMPL-001-team-backlog-retag
    # B-Q decision queue (13)
    "3811902238",  # B-Q8-vendor-rfi-rfq-reactivation
    "3811672617",  # B-Q7-quality-criteria-production
    "3811378035",  # B-Q6-timeline-mvp-launch-schedule
    "3811738342",  # B-Q3-team1-frontend-web-build-assets
    "3811705523",  # B-Q21-bo-healthcheck-dependency-aware
    "3811115930",  # B-Q20-coverage-final-6pp
    "3811574518",  # B-Q2-docker-lobby-web-cleanup
    "3811836869",  # B-Q19-list-hands-row-int-bug
    "3812066164",  # B-Q18-structure-update-same-tx-flush-bug
    "3812066108",  # B-Q13-desktop-routing-implementation
    "3811803879",  # B-Q14-settings-ui-implementation
    "3811902204",  # B-Q16-development-environment-standards
    "3811443578",  # B-Q17-engine-healthcheck-fix
    "3811902172",  # B-Q15-sg-008-b-endpoint-implementation
]


def move_one(cfg: dict, page_id: str) -> tuple[bool, str]:
    try:
        info = api_get(cfg, f"/content/{page_id}", {"expand": "body.storage,version,space"})
    except Exception as e:
        return False, f"FETCH FAIL: {e}"

    title = info["title"]
    cur_ver = info["version"]["number"]
    payload = {
        "id": page_id,
        "type": "page",
        "title": title,
        "space": {"key": info["space"]["key"]},
        "version": {"number": cur_ver + 1, "message": "SG-031 Phase 1c — move under Legacy parent"},
        "body": {"storage": info["body"]["storage"]},
        "ancestors": [{"id": LEGACY_PARENT_ID}],
    }
    try:
        api_put_json(cfg, f"/content/{page_id}", payload)
        return True, f"v{cur_ver}→v{cur_ver+1}: {title}"
    except Exception as e:
        return False, f"PUT FAIL: {title} — {e}"


def main():
    cfg = get_config()
    if not cfg["email"] or not cfg["token"]:
        print("ERROR: ATLASSIAN_EMAIL and ATLASSIAN_API_TOKEN required.", file=sys.stderr)
        sys.exit(1)

    print(f"Moving {len(LEGACY_PAGE_IDS)} pages under Legacy parent {LEGACY_PARENT_ID}...")
    success = 0
    failed: list[str] = []
    for pid in LEGACY_PAGE_IDS:
        ok, msg = move_one(cfg, pid)
        prefix = "[OK]  " if ok else "[FAIL]"
        print(f"  {prefix} {pid}: {msg}")
        if ok:
            success += 1
        else:
            failed.append(pid)
    print()
    print(f"Result: {success}/{len(LEGACY_PAGE_IDS)} moved")
    if failed:
        print(f"FAILED: {', '.join(failed)}")
        sys.exit(1)
    return 0


if __name__ == "__main__":
    sys.exit(main())
