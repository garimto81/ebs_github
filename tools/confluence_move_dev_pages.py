#!/usr/bin/env python3
"""confluence_move_dev_pages — Bulk move 2.X · ... Confluence pages to section parents.

Title pattern → parent ID mapping:
  EBS · 2.1 Frontend · ...    → 3811606750 (2.1 Frontend)
  EBS · 2.2 Backend · ...     → 3811770578 (2.2 Backend)
  EBS · 2.3 Game Engine · ... → 3811836049 (2.3 Game Engine)
  EBS · 2.4 Command Center... → 3811901565 (2.4 Command Center)
  EBS · 2.5 Shared · ...      → 3812032646 (2.5 Shared)
  EBS · 4. Operations · ...   → 3811573898 (4. Operations)

Skips:
  - The section landing pages themselves (already moved via sync_confluence.py)
  - Pages already under correct parent (idempotent — moving to same parent is no-op)

SG-031 Phase 1d.
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, "C:/claude")
from lib.confluence.md2confluence import api_get, api_put_json, get_config

# Title prefix → parent ID
PARENT_MAP = [
    ("EBS · 2.1 Frontend ·", "3811606750"),
    ("EBS · 2.2 Backend ·",  "3811770578"),
    ("EBS · 2.3 Game Engine ·", "3811836049"),
    ("EBS · 2.4 Command Center ·", "3811901565"),
    ("EBS · 2.5 Shared ·", "3812032646"),
    ("EBS · 4. Operations ·", "3811573898"),
]

# Section landing IDs (skip — already managed by sync_confluence.py)
SKIP_IDS = {
    "3811377375",  # 2. Development
    "3811606750",  # 2.1 Frontend
    "3811770578",  # 2.2 Backend
    "3811836049",  # 2.3 Game Engine
    "3811901565",  # 2.4 Command Center
    "3812032646",  # 2.5 Shared
    "3811573898",  # 4. Operations
}


def find_target_parent(title: str) -> str | None:
    for prefix, parent_id in PARENT_MAP:
        if title.startswith(prefix):
            return parent_id
    return None


def cql_search_pages(cfg: dict) -> list[dict]:
    """Fetch all EBS-prefixed pages via REST v1 CQL with start-based pagination + retry."""
    import time
    import requests
    pages = []
    start = 0
    LIMIT = 100
    url = f"{cfg['base_url']}/rest/api/content/search"
    auth = (cfg['email'], cfg['token'])
    while True:
        params = {"cql": 'space = WSOPLive AND title ~ "EBS"', "limit": LIMIT, "start": start}
        # retry up to 3 times on transient errors
        for attempt in range(3):
            try:
                resp = requests.get(url, auth=auth, params=params, timeout=60)
                resp.raise_for_status()
                data = resp.json()
                break
            except (requests.exceptions.ConnectionError, requests.exceptions.Timeout) as e:
                if attempt == 2:
                    raise
                print(f"  [retry {attempt+1}] {e}")
                time.sleep(3)
        results = data.get("results", [])
        pages.extend(results)
        if len(results) < LIMIT:
            break
        start += LIMIT
        if start > 500:  # safety cap
            break
    return pages


def get_current_parent(page_info: dict) -> str | None:
    ancestors = page_info.get("ancestors", [])
    if ancestors:
        return ancestors[-1].get("id")
    return None


def move_one(cfg: dict, page_id: str, target_parent: str) -> tuple[str, bool, str]:
    try:
        info = api_get(cfg, f"/content/{page_id}", {"expand": "body.storage,version,space,ancestors"})
    except Exception as e:
        return ("FETCH_FAIL", False, str(e))

    title = info["title"]
    cur_parent = get_current_parent(info)
    if cur_parent == target_parent:
        return ("SKIP", True, f"already under {target_parent}")

    cur_ver = info["version"]["number"]
    payload = {
        "id": page_id,
        "type": "page",
        "title": title,
        "space": {"key": info["space"]["key"]},
        "version": {"number": cur_ver + 1, "message": "SG-031 Phase 1d — move under section parent"},
        "body": {"storage": info["body"]["storage"]},
        "ancestors": [{"id": target_parent}],
    }
    try:
        api_put_json(cfg, f"/content/{page_id}", payload)
        return ("MOVED", True, f"→ parent {target_parent}, v{cur_ver}→v{cur_ver+1}")
    except Exception as e:
        return ("PUT_FAIL", False, str(e))


def main():
    cfg = get_config()
    if not cfg["email"] or not cfg["token"]:
        print("ERROR: ATLASSIAN_EMAIL/TOKEN required.", file=sys.stderr)
        sys.exit(1)

    print("Fetching all EBS-prefixed pages via CQL...")
    pages = cql_search_pages(cfg)
    print(f"Found {len(pages)} pages")
    print()

    stats = {"MOVED": 0, "SKIP": 0, "FETCH_FAIL": 0, "PUT_FAIL": 0, "NO_MATCH": 0}
    failed: list[str] = []

    for page in pages:
        page_id = page["id"]
        title = page["title"]
        if page_id in SKIP_IDS:
            stats["SKIP"] += 1
            continue
        target = find_target_parent(title)
        if not target:
            stats["NO_MATCH"] += 1
            continue
        status, ok, msg = move_one(cfg, page_id, target)
        prefix = {"MOVED": "[MOVE]", "SKIP": "[SKIP]", "FETCH_FAIL": "[ERR ]", "PUT_FAIL": "[ERR ]"}.get(status, "[?   ]")
        print(f"  {prefix} {page_id}: {title[:55]} {msg}")
        stats[status] += 1
        if not ok:
            failed.append(page_id)

    print()
    print(f"Result: MOVED={stats['MOVED']} SKIP={stats['SKIP']} NO_MATCH={stats['NO_MATCH']} ERRORS={stats['FETCH_FAIL']+stats['PUT_FAIL']}")
    if failed:
        print(f"FAILED: {', '.join(failed)}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
