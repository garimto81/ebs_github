#!/usr/bin/env python3
"""confluence_rename_pages — Rename a curated set of Confluence pages.

Why this script exists separately from md2confluence.py:
    md2confluence.py preserves the existing Confluence page title (it reads
    `info["title"]` from the live page and writes it back unchanged). That
    means content sync alone cannot rename a page — the new title must be
    pushed in a dedicated PUT /content/{id} call BEFORE the content sync,
    otherwise md2confluence will overwrite the new title with the old one.

Operations:
    - --plan      : Show the rename plan (current title → new title, page_id)
    - --dry-run   : Fetch current titles + validate, do not write
    - --execute   : PUT /content/{id} with new title (REAL CHANGE)

Target set (S11 Cycle 18 — user-explicit authorization, 2026-05-12):
    page_id        new title
    --------       -----------------
    3811967073     Back Office        (was: EBS · Back Office PRD — 보이지 않는 뼈대)
    3811901603     Command Center     (was: EBS · Command Center PRD — 운영자가 매 순간 머무는 조종석)
    3811672228     Lobby              (was: EBS · Lobby PRD — 모든 테이블을 내려다보는 관제탑)

NOT included (user-explicit exclusion):
    Foundation / RIVE_Standards / Product_SSOT_Policy / "1. Product"

Branch guard:
    Refuses to --execute unless current branch == main OR EBS_FORCE_MIRROR=1.

Environment:
    ATLASSIAN_EMAIL     - Confluence user email
    ATLASSIAN_API_TOKEN - Confluence API token
    CONFLUENCE_BASE_URL - Base URL (default: https://ggnetwork.atlassian.net/wiki)
"""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

import requests

# Ensure UTF-8 output on Windows
if sys.platform == "win32":
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8")
    os.environ.setdefault("PYTHONIOENCODING", "utf-8")


REPO_ROOT = Path(__file__).resolve().parent.parent


# Rename plan — user-explicit authorization 2026-05-12 (S11 Cycle 18).
# Every entry is destructive (external bookmarks may break) and must be
# user-approved. Document the approval in the PR when adding new entries.
RENAME_PLAN: list[tuple[str, str]] = [
    ("3811967073", "Back Office"),
    ("3811901603", "Command Center"),
    ("3811672228", "Lobby"),
]


def _get_win_env(name: str) -> str:
    try:
        import winreg
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment") as key:
            return winreg.QueryValueEx(key, name)[0]
    except Exception:
        return ""


def get_config() -> dict[str, str]:
    return {
        "base_url": (
            os.environ.get("CONFLUENCE_BASE_URL", "")
            or _get_win_env("CONFLUENCE_BASE_URL")
            or "https://ggnetwork.atlassian.net/wiki"
        ),
        "email": os.environ.get("ATLASSIAN_EMAIL", "") or _get_win_env("ATLASSIAN_EMAIL"),
        "token": os.environ.get("ATLASSIAN_API_TOKEN", "") or _get_win_env("ATLASSIAN_API_TOKEN"),
    }


def current_branch() -> str:
    try:
        out = subprocess.check_output(
            ["git", "-C", str(REPO_ROOT), "rev-parse", "--abbrev-ref", "HEAD"],
            text=True,
        )
        return out.strip()
    except subprocess.CalledProcessError:
        return ""


def fetch_page(cfg: dict[str, str], page_id: str) -> dict:
    url = f"{cfg['base_url']}/rest/api/content/{page_id}"
    resp = requests.get(
        url,
        auth=(cfg["email"], cfg["token"]),
        params={"expand": "version,space"},
        timeout=30,
    )
    resp.raise_for_status()
    return resp.json()


def rename_page(cfg: dict[str, str], page_id: str, new_title: str) -> dict:
    """PUT /content/{id} with a title-only change.

    Confluence requires the FULL representation (id, type, title, space,
    version+1, body). Omitting body would blank the page, so we fetch the
    current storage body and re-PUT it unchanged. md2confluence.py will run
    afterwards in the same cycle to push the actual content updates — this
    step only ratchets the title.
    """
    url = f"{cfg['base_url']}/rest/api/content/{page_id}"
    full = requests.get(
        url,
        auth=(cfg["email"], cfg["token"]),
        params={"expand": "body.storage,version,space"},
        timeout=30,
    )
    full.raise_for_status()
    full_data = full.json()
    storage_value = full_data["body"]["storage"]["value"]
    space_key = full_data["space"]["key"]
    cur_ver = full_data["version"]["number"]

    payload = {
        "id": page_id,
        "type": "page",
        "title": new_title,
        "space": {"key": space_key},
        "version": {"number": cur_ver + 1},
        "body": {"storage": {"value": storage_value, "representation": "storage"}},
    }
    resp = requests.put(
        url,
        auth=(cfg["email"], cfg["token"]),
        json=payload,
        headers={"Content-Type": "application/json"},
        timeout=30,
    )
    if not resp.ok:
        print(f"  API Error {resp.status_code}: {resp.text[:500]}", file=sys.stderr)
    resp.raise_for_status()
    return resp.json()


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument("--plan", action="store_true", help="Show the rename plan and exit")
    mode.add_argument("--dry-run", action="store_true",
                      help="Fetch current titles + validate, do not write")
    mode.add_argument("--execute", action="store_true",
                      help="PUT /content/{id} (REAL CHANGE — destructive)")
    ap.add_argument("--no-branch-guard", action="store_true",
                    help="Skip main-branch check (CI override). Ignored for --plan/--dry-run.")
    args = ap.parse_args()

    if args.plan:
        print("Rename plan (S11 Cycle 18 — user-explicit authorization):")
        print()
        for page_id, new_title in RENAME_PLAN:
            print(f"  - page {page_id} -> '{new_title}'")
        print()
        print("Excluded (per user explicit instruction):")
        print("  - Foundation, RIVE_Standards, Product_SSOT_Policy, '1. Product'")
        return 0

    cfg = get_config()
    if not cfg["email"] or not cfg["token"]:
        print(
            "ERROR: ATLASSIAN_EMAIL and ATLASSIAN_API_TOKEN required.",
            file=sys.stderr,
        )
        return 1

    if args.execute and not args.no_branch_guard and not os.environ.get("EBS_FORCE_MIRROR"):
        branch = current_branch()
        if branch != "main":
            print(
                f"ERROR: current branch is '{branch}', refusing --execute (main only).",
                file=sys.stderr,
            )
            print(
                "       Set EBS_FORCE_MIRROR=1 or pass --no-branch-guard to override.",
                file=sys.stderr,
            )
            return 2

    mode_label = "[DRY-RUN]" if args.dry_run else "[EXECUTE]"
    print(f"{mode_label} Renaming {len(RENAME_PLAN)} Confluence page(s)\n")

    failed: list[str] = []
    for page_id, new_title in RENAME_PLAN:
        try:
            info = fetch_page(cfg, page_id)
            cur_title = info["title"]
            cur_ver = info["version"]["number"]
            if cur_title == new_title:
                print(f"  [SKIP] {page_id} already titled '{new_title}' (v{cur_ver})")
                continue

            print(f"  page {page_id} (v{cur_ver})")
            print(f"    current : {cur_title}")
            print(f"    new     : {new_title}")

            if args.dry_run:
                print(f"    [DRY] would PUT title")
                continue

            result = rename_page(cfg, page_id, new_title)
            new_ver = result["version"]["number"]
            print(f"    [OK] renamed -> v{new_ver}")
        except requests.HTTPError as e:
            failed.append(page_id)
            print(f"  [FAIL] {page_id}: HTTP {e.response.status_code} {e.response.text[:200]}")
        except Exception as e:
            failed.append(page_id)
            print(f"  [FAIL] {page_id}: {e}")

    print()
    print(f"Result: {len(RENAME_PLAN) - len(failed)}/{len(RENAME_PLAN)} succeeded {mode_label}")
    if failed:
        print("FAILED:")
        for pid in failed:
            print(f"  - {pid}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
