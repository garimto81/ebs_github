#!/usr/bin/env python3
"""confluence_purge_a2 — A2 clean slate: trash everything except 19 preserved pages.

A2 (사용자 결정 2026-05-04): 옛 트리 + 잉여물 + Legacy 모두 trash.
새 트리 = drift_check 18 + Game Rules parent (자식 4의 부모) = 19 preserved.
References parent (3811443856) = 빈 잔재 → trash.

전략:
1. 폴더 3184328827 자식 페이지 전체 fetch (pagination)
2. 각 페이지의 descendants 재귀 fetch
3. PRESERVE 외 모든 ID 를 trash list 에 추가
4. trash 순서 = bottom-up (자식 먼저 trash) — Confluence cascade 보장 강화
5. 일괄 trash (v1 PUT status=trashed)

SG-031 Phase 2 — A2 clean slate.
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, "C:/claude")
import requests

from lib.confluence.md2confluence import api_get, get_config

# 보존 19 페이지 (drift_check 18 + Game Rules parent)
PRESERVE_IDS = {
    # drift_check 18
    "3625189547",  # Foundation
    "3811344758",  # 1. Product (landing)
    "3811967073",  # Back Office PRD
    "3811901603",  # Command Center PRD
    "3811672228",  # Lobby PRD
    "3811377375",  # 2. Development (landing)
    "3811573898",  # 4. Operations (landing)
    "3811869217",  # Phase Plan 2027
    "3812262096",  # Legacy parent (자식 30 자체는 trash 대상)
    "3811410570",  # Game Rules — Betting System
    "3810853753",  # Game Rules — Draw
    "3811443642",  # Game Rules — Flop Games
    "3811771012",  # Game Rules — Seven Card Games
    "3811606750",  # 2.1 Frontend
    "3811770578",  # 2.2 Backend
    "3811836049",  # 2.3 Game Engine
    "3811901565",  # 2.4 Command Center
    "3812032646",  # 2.5 Shared
    # Game Rules parent (4 자식의 부모)
    "3812360338",  # 1. Product · Game Rules
}


def fetch_descendants(cfg: dict, page_id: str, depth: int = 0, max_depth: int = 10) -> list[dict]:
    """Recursively fetch all descendants of a page."""
    if depth > max_depth:
        return []
    auth = (cfg["email"], cfg["token"])
    out: list[dict] = []
    start = 0
    while True:
        url = f"{cfg['base_url']}/rest/api/content/{page_id}/child/page"
        resp = requests.get(url, auth=auth, params={"limit": 100, "start": start}, timeout=30)
        if not resp.ok:
            print(f"  [WARN] fetch children of {page_id}: HTTP {resp.status_code}")
            break
        data = resp.json()
        results = data.get("results", [])
        for r in results:
            out.append({"id": r["id"], "title": r["title"], "depth": depth})
            # recurse
            out.extend(fetch_descendants(cfg, r["id"], depth + 1, max_depth))
        if len(results) < 100:
            break
        start += 100
    return out


def fetch_folder_children(cfg: dict, folder_id: str) -> list[dict]:
    """Fetch all direct children of a folder via folder API."""
    auth = (cfg["email"], cfg["token"])
    out: list[dict] = []
    start = 0
    while True:
        url = f"{cfg['base_url']}/rest/api/content/{folder_id}/child/page"
        resp = requests.get(url, auth=auth, params={"limit": 100, "start": start}, timeout=30)
        if not resp.ok:
            return out
        data = resp.json()
        results = data.get("results", [])
        for r in results:
            out.append({"id": r["id"], "title": r["title"], "depth": 0})
        if len(results) < 100:
            break
        start += 100
    return out


def trash_page(cfg: dict, page_id: str) -> tuple[bool, str]:
    """Trash via v1 PUT status=trashed (verified to work in v5)."""
    try:
        info = api_get(cfg, f"/content/{page_id}")
        title = info.get("title", "?")
        ver = info["version"]["number"]
    except requests.HTTPError as e:
        if e.response.status_code in (404, 403):
            return True, f"already gone: {page_id}"
        return False, f"FETCH FAIL {page_id}: {e}"
    except Exception as e:
        return False, f"FETCH FAIL {page_id}: {e}"

    payload = {
        "id": page_id,
        "type": "page",
        "title": title,
        "status": "trashed",
        "version": {"number": ver + 1, "message": "SG-031 A2 — clean slate purge"},
    }
    url = f"{cfg['base_url']}/rest/api/content/{page_id}"
    try:
        resp = requests.put(
            url,
            auth=(cfg["email"], cfg["token"]),
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=30,
        )
        if resp.status_code in (200, 204):
            return True, f"trashed: {title[:60]}"
        return False, f"HTTP {resp.status_code}: {resp.text[:120]}"
    except Exception as e:
        return False, str(e)


def main():
    cfg = get_config()
    if not cfg["email"] or not cfg["token"]:
        print("ERROR: ATLASSIAN_EMAIL/TOKEN required", file=sys.stderr)
        return 2

    FOLDER_ID = "3184328827"
    print(f"[1/4] Folder {FOLDER_ID} 직속 자식 fetch...")
    direct = fetch_folder_children(cfg, FOLDER_ID)
    print(f"  found {len(direct)} direct children")

    print(f"\n[2/4] 각 자식의 descendants 재귀 fetch...")
    all_pages: dict[str, dict] = {}
    for child in direct:
        all_pages[child["id"]] = child
        descendants = fetch_descendants(cfg, child["id"])
        for d in descendants:
            all_pages[d["id"]] = d
    print(f"  total pages discovered = {len(all_pages)}")

    # 분류
    to_trash = []
    to_preserve = []
    for pid, info in all_pages.items():
        if pid in PRESERVE_IDS:
            to_preserve.append(info)
        else:
            to_trash.append(info)
    print(f"\n[3/4] Preserve = {len(to_preserve)}, Trash = {len(to_trash)}")
    print(f"  preserved sample:")
    for p in to_preserve[:5]:
        print(f"    [KEEP] {p['id']}  {p['title'][:60]}")

    # bottom-up trash (가장 깊은 노드부터)
    to_trash.sort(key=lambda x: -x.get("depth", 0))

    print(f"\n[4/4] Trashing {len(to_trash)} pages (bottom-up)...")
    success = 0
    failed: list[tuple[str, str]] = []
    for i, info in enumerate(to_trash, 1):
        ok, msg = trash_page(cfg, info["id"])
        if ok:
            success += 1
            if i <= 10 or i % 20 == 0:
                print(f"  [{i:3d}/{len(to_trash)}] [OK] {info['id']}: {msg}")
        else:
            print(f"  [{i:3d}/{len(to_trash)}] [FAIL] {info['id']}: {msg}")
            failed.append((info["id"], msg))

    print()
    print(f"Result: {success}/{len(to_trash)} trashed, {len(failed)} failed")
    if failed:
        print("FAILED list:")
        for pid, msg in failed:
            print(f"  {pid}: {msg}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
