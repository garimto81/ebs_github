#!/usr/bin/env python3
"""confluence_delete_readme — Delete the orphan README page (3811999808).

사용자 지적 (2026-05-04): 단방향 미러 원칙 위반 — 로컬에 대응 파일 없는 Confluence-only 잉여 페이지.
폴더 진입점은 폴더 3184328827 그 자체로 충분 (4 자식: 1. Product / 2. Development / 4. Operations / Legacy).

SG-031 Phase 1 — 외부 인계 baseline iterate.
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, "C:/claude")
import requests

from lib.confluence.md2confluence import api_get, get_config

README_PAGE_ID = "3811999808"


def delete_page(cfg: dict, page_id: str) -> tuple[bool, str]:
    """Try multiple deletion strategies (v1 DELETE → v1 PUT trashed → v2 DELETE)."""
    try:
        info = api_get(cfg, f"/content/{page_id}")
        title = info.get("title", "?")
    except Exception as e:
        return False, f"FETCH FAIL: {e}"

    base = cfg["base_url"]
    auth = (cfg["email"], cfg["token"])

    # Strategy 1 — REST v2 hard delete (api/v2/pages/{id})
    v2_url = f"{base}/api/v2/pages/{page_id}"
    try:
        resp = requests.delete(v2_url, auth=auth, timeout=30)
        if resp.status_code in (204, 200):
            return True, f"deleted via v2: {title}"
        v2_err = f"v2 DELETE HTTP {resp.status_code}: {resp.text[:200]}"
    except Exception as e:
        v2_err = f"v2 DELETE exc: {e}"

    # Strategy 2 — REST v1 PUT status=trashed
    v1_url = f"{base}/rest/api/content/{page_id}"
    try:
        # need version+1
        ver = info["version"]["number"]
        payload = {
            "id": page_id,
            "type": "page",
            "title": title,
            "status": "trashed",
            "version": {"number": ver + 1},
        }
        resp = requests.put(v1_url, auth=auth, json=payload, headers={"Content-Type": "application/json"}, timeout=30)
        if resp.status_code in (200, 204):
            return True, f"trashed via v1 PUT: {title}"
        v1put_err = f"v1 PUT HTTP {resp.status_code}: {resp.text[:200]}"
    except Exception as e:
        v1put_err = f"v1 PUT exc: {e}"

    # Strategy 3 — REST v1 DELETE
    try:
        resp = requests.delete(v1_url, auth=auth, timeout=30)
        if resp.status_code in (204, 200):
            return True, f"deleted via v1: {title}"
        v1del_err = f"v1 DELETE HTTP {resp.status_code}: {resp.text[:200]}"
    except Exception as e:
        v1del_err = f"v1 DELETE exc: {e}"

    return False, f"All strategies failed:\n  {v2_err}\n  {v1put_err}\n  {v1del_err}"


def main():
    cfg = get_config()
    if not cfg["email"] or not cfg["token"]:
        print("ERROR: ATLASSIAN_EMAIL/TOKEN required", file=sys.stderr)
        return 2
    print(f"Deleting orphan README page {README_PAGE_ID}...")
    ok, msg = delete_page(cfg, README_PAGE_ID)
    print(f"  {'[OK]' if ok else '[FAIL]'} {msg}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
