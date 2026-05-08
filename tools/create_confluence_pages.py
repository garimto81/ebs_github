#!/usr/bin/env python3
"""create_confluence_pages.py — Bulk Confluence 페이지 생성 + frontmatter 자동 갱신.

For each docs/*.md without confluence-page-id frontmatter:
1. parent_id 자동 결정 (docs/ 폴더 path → root parent page-id)
2. POST /rest/api/content (placeholder body — sync_confluence 가 본문 push)
3. frontmatter 자동 갱신 (confluence-page-id, confluence-parent-id, confluence-url)

Usage:
    python tools/create_confluence_pages.py --tier external [--dry-run] [--limit N]
    python tools/create_confluence_pages.py --filter "2. Development/2.1 Frontend/Lobby/*"
    python tools/create_confluence_pages.py --list  # 미매핑 list 만

Frontmatter contract (after run):
    confluence-page-id: <NEW_ID>
    confluence-parent-id: <PARENT>
    confluence-url: https://...

Branch guard:
    Refuses to run unless current branch == main (override with EBS_FORCE_MIRROR=1).
"""
from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
import time
from pathlib import Path

import requests

if sys.platform == "win32":
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8")

REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS_ROOT = REPO_ROOT / "docs"

# Path → parent_id mapping (Phase A.3 정의)
PARENT_MAP = [
    ("1. Product/Game_Rules/", "3812360338"),
    ("1. Product/", "3811344758"),
    ("2. Development/2.1 Frontend/", "3811606750"),
    ("2. Development/2.2 Backend/", "3811770578"),
    ("2. Development/2.3 Game Engine/", "3811836049"),
    ("2. Development/2.4 Command Center/", "3811901565"),
    ("2. Development/2.5 Shared/", "3812032646"),
    ("4. Operations/", "3811573898"),
]

EXCLUDE_GLOBS = (
    "_archived-2026-04",
    "_archive",
    "_generated",
    "archive",
    "build",
    "node_modules",
)

SPACE_KEY = "WSOPLive"
BASE_URL = os.environ.get("CONFLUENCE_BASE_URL", "https://ggnetwork.atlassian.net/wiki")


def get_auth():
    email = os.environ.get("ATLASSIAN_EMAIL", "")
    token = os.environ.get("ATLASSIAN_API_TOKEN", "")
    if not email or not token:
        sys.exit("ERROR: ATLASSIAN_EMAIL / ATLASSIAN_API_TOKEN env missing.")
    return (email, token)


def current_branch() -> str:
    try:
        out = subprocess.check_output(
            ["git", "-C", str(REPO_ROOT), "rev-parse", "--abbrev-ref", "HEAD"],
            text=True,
        )
        return out.strip()
    except subprocess.CalledProcessError:
        return ""


def parse_frontmatter(text: str) -> tuple[dict, str, str]:
    """Return (frontmatter dict, raw_yaml, post_yaml_body)."""
    if not text.startswith("---\n"):
        return {}, "", text
    end = text.find("\n---\n", 4)
    if end == -1:
        return {}, "", text
    raw_yaml = text[4:end]
    body = text[end + 5 :]
    out: dict = {}
    for line in raw_yaml.splitlines():
        m = re.match(r"^([\w-]+):\s*(.*?)\s*$", line)
        if m:
            key, val = m.group(1), m.group(2)
            if (val.startswith('"') and val.endswith('"')) or (
                val.startswith("'") and val.endswith("'")
            ):
                val = val[1:-1]
            out[key] = val
    return out, raw_yaml, body


def determine_parent(rel_path: str) -> str | None:
    """rel_path = 'docs/2.1 Frontend/Lobby/Overview.md' → parent page-id."""
    rel = rel_path.replace("\\", "/")
    if rel.startswith("docs/"):
        rel = rel[5:]
    for prefix, parent in PARENT_MAP:
        if rel.startswith(prefix):
            return parent
    return None


def make_title(fm: dict, md_path: Path, body: str) -> str:
    """Determine Confluence page title with EBS · prefix when missing."""
    title = fm.get("title", "").strip()
    if not title:
        m = re.search(r"^#\s+(.+)$", body, re.MULTILINE)
        if m:
            title = m.group(1).strip()
    if not title:
        title = md_path.stem.replace("_", " ").replace("-", " ")
    # Strip any backticks from title
    title = title.replace("`", "")
    # Add EBS · prefix when not present
    if not title.startswith("EBS"):
        title = f"EBS · {title}"
    return title


def find_unmapped_targets(filter_glob: str | None = None, tier: str | None = None) -> list[Path]:
    """Walk docs/ for .md without confluence-page-id, optionally tier-filtered."""
    targets = []
    for md in DOCS_ROOT.rglob("*.md"):
        # Exclude
        if any(ex in md.parts for ex in EXCLUDE_GLOBS):
            continue
        rel = md.relative_to(REPO_ROOT).as_posix()
        if filter_glob:
            from fnmatch import fnmatch
            if not fnmatch(rel, f"docs/{filter_glob}") and not fnmatch(rel, filter_glob):
                continue
        try:
            text = md.read_text(encoding="utf-8")
        except Exception:
            continue
        fm, _yaml, _body = parse_frontmatter(text)
        if fm.get("confluence-page-id"):
            page_id = fm["confluence-page-id"]
            if page_id not in ("null", "None", "", "tbd"):
                continue
        if tier and fm.get("tier", "").strip() != tier:
            continue
        # Skip generated / known meta files
        if fm.get("tier") == "generated":
            continue
        targets.append(md)
    return targets


def update_frontmatter_with_pageid(md: Path, page_id: str, parent_id: str, url: str) -> None:
    """Edit md frontmatter to add confluence-page-id / parent-id / url."""
    text = md.read_text(encoding="utf-8")
    fm, raw_yaml, body = parse_frontmatter(text)
    if not raw_yaml:
        # No frontmatter — prepend minimal one
        new_yaml = (
            f"title: {fm.get('title', md.stem)}\n"
            f"confluence-page-id: {page_id}\n"
            f"confluence-parent-id: {parent_id}\n"
            f"confluence-url: {url}\n"
        )
        md.write_text(f"---\n{new_yaml}---\n\n{text}", encoding="utf-8")
        return
    # Replace or append within existing frontmatter
    new_lines = []
    seen_keys = set()
    for line in raw_yaml.splitlines():
        m = re.match(r"^([\w-]+):", line)
        if m and m.group(1) in ("confluence-page-id", "confluence-parent-id", "confluence-url"):
            seen_keys.add(m.group(1))
            if m.group(1) == "confluence-page-id":
                new_lines.append(f"confluence-page-id: {page_id}")
            elif m.group(1) == "confluence-parent-id":
                new_lines.append(f"confluence-parent-id: {parent_id}")
            elif m.group(1) == "confluence-url":
                new_lines.append(f"confluence-url: {url}")
            continue
        new_lines.append(line)
    if "confluence-page-id" not in seen_keys:
        new_lines.append(f"confluence-page-id: {page_id}")
    if "confluence-parent-id" not in seen_keys:
        new_lines.append(f"confluence-parent-id: {parent_id}")
    if "confluence-url" not in seen_keys:
        new_lines.append(f"confluence-url: {url}")
    new_yaml = "\n".join(new_lines)
    md.write_text(f"---\n{new_yaml}\n---\n{body}", encoding="utf-8")


def create_page(auth, title: str, parent_id: str) -> tuple[str, str] | None:
    """POST /rest/api/content. Return (page_id, url) or None on fail."""
    payload = {
        "type": "page",
        "title": title,
        "space": {"key": SPACE_KEY},
        "ancestors": [{"id": parent_id}],
        "body": {
            "storage": {
                "value": "<p><em>Page placeholder — sync_confluence 가 본문 push 대기.</em></p>",
                "representation": "storage",
            }
        },
    }
    url_endpoint = f"{BASE_URL}/rest/api/content"
    resp = requests.post(url_endpoint, auth=auth, json=payload, timeout=30)
    if resp.ok:
        data = resp.json()
        page_id = data["id"]
        web_url = f"{BASE_URL}{data['_links'].get('webui', '/spaces/' + SPACE_KEY + '/pages/' + page_id)}"
        return page_id, web_url
    # Title duplicate handling
    if resp.status_code == 400 and "title" in resp.text.lower():
        # Append parent suffix to differentiate
        new_title = f"{title} ({parent_id[-4:]})"
        payload["title"] = new_title
        resp2 = requests.post(url_endpoint, auth=auth, json=payload, timeout=30)
        if resp2.ok:
            data = resp2.json()
            return data["id"], f"{BASE_URL}{data['_links'].get('webui', '')}"
    print(f"  [FAIL] {resp.status_code}: {resp.text[:300]}")
    return None


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dry-run", action="store_true", help="List + parent only, no API calls")
    ap.add_argument("--filter", help="Glob filter relative to docs/, e.g. '2. Development/2.1 Frontend/Lobby/*'")
    ap.add_argument("--tier", choices=["external", "internal", "contract"], help="Filter by frontmatter tier")
    ap.add_argument("--limit", type=int, default=0, help="Max pages to create (0 = unlimited)")
    ap.add_argument("--list", action="store_true", help="List unmapped targets and exit")
    ap.add_argument("--no-branch-guard", action="store_true")
    args = ap.parse_args()

    if not args.no_branch_guard and not args.list and not os.environ.get("EBS_FORCE_MIRROR"):
        branch = current_branch()
        if branch != "main":
            print(f"ERROR: branch '{branch}' — main only. (--no-branch-guard 또는 EBS_FORCE_MIRROR=1)", file=sys.stderr)
            return 2

    targets = find_unmapped_targets(args.filter, args.tier)
    if not targets:
        print("No unmapped targets found." + (f" (filter: {args.filter})" if args.filter else ""))
        return 0

    print(f"Found {len(targets)} unmapped target(s):")
    for md in targets[:30]:
        rel = md.relative_to(REPO_ROOT).as_posix()
        parent = determine_parent(rel)
        print(f"  - {rel} → parent {parent}")
    if len(targets) > 30:
        print(f"  ... (+{len(targets) - 30} more)")

    if args.list:
        return 0

    if args.limit > 0:
        targets = targets[: args.limit]

    auth = get_auth()
    created = 0
    failed = []
    for i, md in enumerate(targets, 1):
        rel = md.relative_to(REPO_ROOT).as_posix()
        parent_id = determine_parent(rel)
        if not parent_id:
            print(f"[{i}/{len(targets)}] SKIP {rel} — no parent mapping")
            continue
        text = md.read_text(encoding="utf-8")
        fm, _yaml, body = parse_frontmatter(text)
        title = make_title(fm, md, body)
        print(f"[{i}/{len(targets)}] {rel} → '{title}' (parent {parent_id})")
        if args.dry_run:
            print("  [DRY] would create")
            continue
        result = create_page(auth, title, parent_id)
        if not result:
            failed.append(rel)
            continue
        page_id, web_url = result
        update_frontmatter_with_pageid(md, page_id, parent_id, web_url)
        print(f"  [OK] page_id={page_id} | {web_url}")
        created += 1
        # Rate limit
        time.sleep(0.3)

    print(f"\nResult: {created}/{len(targets)} created" + (" [DRY-RUN]" if args.dry_run else ""))
    if failed:
        print("FAILED:")
        for r in failed:
            print(f"  - {r}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
