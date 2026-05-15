#!/usr/bin/env python3
"""confluence_page_id_audit — Bi-directional Confluence ↔ Git frontmatter mapping audit.

S11 Cycle-21: Detects page-id drift between git frontmatter and live Confluence pages.

Audit directions:
  1. Git→Confluence: for each .md with confluence-page-id, verify the live page exists
     and matches the declared space/title.
  2. Confluence→Git: for pages under EBS roots, verify each maps to a git .md.

Auto-correct (safe, frontmatter only):
  - confluence-page-id pointing to non-existent page when a same-title page found → update
  - confluence-url mismatch (wrong page-id in URL) → update

Report only (user decision):
  - Duplicate pages (same title in multiple spaces)
  - Unmapped Confluence pages (live page with no git .md)
  - New .md creation

EBS root pages:
  - WSOPLive:  3184328827 (EBS)
  - Personal space: 3833167989 (EBS)

Usage:
    python tools/confluence_page_id_audit.py [--dry-run]
    python tools/confluence_page_id_audit.py [--dry-run] [--roots 3184328827,3833167989]

Exit codes:
    0 — no drift found
    1 — drift detected
    2 — config / network error
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path

if sys.platform == "win32":
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8")

try:
    import requests
except ImportError:
    print("ERROR: requests not installed. pip install requests", file=sys.stderr)
    sys.exit(2)

REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS_ROOT = REPO_ROOT / "docs"

# EBS root page IDs (not entire space — scoped descent)
DEFAULT_EBS_ROOTS = ["3184328827", "3833167989"]


# ─────────────────────────────────────────────────────────────────────────────
# API helpers
# ─────────────────────────────────────────────────────────────────────────────

def get_config() -> tuple[str, tuple[str, str]]:
    """Return (base_url, (email, token)) from environment."""
    base = os.environ.get("ATLASSIAN_URL", "https://ggnetwork.atlassian.net")
    email = os.environ.get("ATLASSIAN_EMAIL", "")
    token = os.environ.get("ATLASSIAN_API_TOKEN", "")
    if not email or not token:
        print("ERROR: ATLASSIAN_EMAIL / ATLASSIAN_API_TOKEN not set", file=sys.stderr)
        sys.exit(2)
    return base, (email, token)


def api_get(base: str, auth: tuple, endpoint: str, params: dict | None = None) -> dict:
    url = f"{base}{endpoint}"
    resp = requests.get(url, auth=auth, params=params or {}, timeout=30)
    if not resp.ok:
        raise RuntimeError(f"GET {url} → {resp.status_code}: {resp.text[:200]}")
    return resp.json()


def get_page_by_id(base: str, auth: tuple, page_id: str) -> dict | None:
    """Fetch page by ID, return None if 404."""
    try:
        return api_get(base, auth, f"/wiki/rest/api/content/{page_id}",
                       {"expand": "ancestors,space,version"})
    except RuntimeError:
        return None


def fetch_descendants(base: str, auth: tuple, root_id: str) -> list[dict]:
    """Fetch all descendant pages under root_id using REST API child/page (BFS)."""
    result: list[dict] = []
    queue: list[str] = [root_id]
    visited: set[str] = {root_id}

    # Fetch root info
    root_info = get_page_by_id(base, auth, root_id)
    if root_info:
        result.append(root_info)

    while queue:
        pid = queue.pop(0)
        start = 0
        limit = 100
        while True:
            try:
                data = api_get(
                    base, auth,
                    f"/wiki/rest/api/content/{pid}/child/page",
                    {"limit": limit, "start": start,
                     "expand": "ancestors,space,version"},
                )
            except RuntimeError as e:
                print(f"  WARN: {e}", file=sys.stderr)
                break
            children = data.get("results", [])
            for c in children:
                cid = c["id"]
                if cid not in visited:
                    visited.add(cid)
                    result.append(c)
                    queue.append(cid)
            if len(children) < limit:
                break
            start += limit

    return result


# ─────────────────────────────────────────────────────────────────────────────
# Git frontmatter scanner
# ─────────────────────────────────────────────────────────────────────────────

def parse_frontmatter(md_path: Path) -> dict[str, str]:
    """Extract YAML frontmatter as flat string dict."""
    try:
        text = md_path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return {}
    if not text.startswith("---\n"):
        return {}
    end = text.find("\n---\n", 4)
    if end == -1:
        return {}
    fm = text[4:end]
    out: dict[str, str] = {}
    for line in fm.splitlines():
        m = re.match(r'^([\w-]+):\s*(.*?)\s*$', line)
        if m:
            key = m.group(1)
            val = m.group(2).strip('"').strip("'")
            out[key] = val
    return out


def scan_git_frontmatter(docs_root: Path) -> list[dict]:
    """Return all .md entries that have a non-empty confluence-page-id."""
    entries: list[dict] = []
    for md_path in sorted(docs_root.rglob("*.md")):
        fm = parse_frontmatter(md_path)
        pid = fm.get("confluence-page-id", "").strip()
        if not pid or pid.lower() in ("null", "none", ""):
            continue
        entries.append({
            "path": str(md_path.relative_to(docs_root)),
            "abs_path": md_path,
            "page_id": pid,
            "parent_id": fm.get("confluence-parent-id", ""),
            "confluence_url": fm.get("confluence-url", ""),
            "title": fm.get("title", md_path.stem),
            "fm": fm,
        })
    return entries


# ─────────────────────────────────────────────────────────────────────────────
# Frontmatter patcher
# ─────────────────────────────────────────────────────────────────────────────

def patch_frontmatter_field(md_path: Path, field: str, new_value: str) -> bool:
    """In-place update a frontmatter field. Returns True if file changed."""
    try:
        text = md_path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return False
    if not text.startswith("---\n"):
        return False
    end = text.find("\n---\n", 4)
    if end == -1:
        return False
    fm_block = text[4:end]
    rest = text[end + 5:]

    new_lines: list[str] = []
    found = False
    for line in fm_block.splitlines():
        m = re.match(r'^(' + re.escape(field) + r'):\s*(.*?)\s*$', line)
        if m:
            new_lines.append(f"{field}: {new_value}")
            found = True
        else:
            new_lines.append(line)
    if not found:
        new_lines.append(f"{field}: {new_value}")

    new_text = "---\n" + "\n".join(new_lines) + "\n---\n" + rest
    if new_text == text:
        return False
    md_path.write_text(new_text, encoding="utf-8")
    return True


# ─────────────────────────────────────────────────────────────────────────────
# Main audit
# ─────────────────────────────────────────────────────────────────────────────

def run_audit(dry_run: bool, ebs_roots: list[str]) -> dict:
    base, auth = get_config()

    print(f"\n{'='*70}")
    print(f"  Confluence ↔ Git frontmatter mapping audit")
    print(f"  Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"  EBS roots: {', '.join(ebs_roots)}")
    print(f"  Dry-run: {dry_run}")
    print(f"{'='*70}\n")

    # ── Step 1: Scan git frontmatter ─────────────────────────────────────────
    print("📂 Step 1: Scanning git frontmatter...")
    git_entries = scan_git_frontmatter(DOCS_ROOT)
    print(f"  Found {len(git_entries)} .md files with confluence-page-id")

    git_by_page_id: dict[str, dict] = {}
    dup_ids: set[str] = set()
    for e in git_entries:
        pid = e["page_id"]
        if pid in git_by_page_id:
            dup_ids.add(pid)
        else:
            git_by_page_id[pid] = e

    print(f"  Duplicate page-ids in git: {len(dup_ids)}\n")

    # ── Step 2: Fetch Confluence EBS trees ───────────────────────────────────
    print("🌐 Step 2: Fetching Confluence EBS sub-trees...")
    conf_pages: list[dict] = []
    for root_id in ebs_roots:
        root_info = get_page_by_id(base, auth, root_id)
        root_title = root_info["title"] if root_info else "?"
        space_key = root_info.get("space", {}).get("key", "?") if root_info else "?"
        print(f"  Root {root_id} ({space_key}/{root_title})...", end=" ", flush=True)
        pages = fetch_descendants(base, auth, root_id)
        conf_pages.extend(pages)
        print(f"→ {len(pages)} pages")

    print(f"  Total EBS Confluence pages: {len(conf_pages)}\n")

    # Build lookups
    conf_by_id: dict[str, dict] = {p["id"]: p for p in conf_pages}
    conf_by_title_norm: dict[str, list[dict]] = {}
    for p in conf_pages:
        t = _norm_title(p["title"])
        conf_by_title_norm.setdefault(t, []).append(p)

    # ── Step 3: Git → Confluence verification ────────────────────────────────
    print("🔍 Step 3: Git → Confluence verification...")

    results: dict[str, list] = {
        "ok": [],
        "page_id_mismatch": [],
        "url_mismatch": [],
        "page_not_found": [],
        "duplicate_confluence": [],
        "duplicate_git": [],
        "unmapped_confluence": [],
        "auto_corrected": [],
    }

    for e in git_entries:
        pid = e["page_id"]
        path = e["path"]

        # Duplicate in git?
        if pid in dup_ids:
            results["duplicate_git"].append({
                "page_id": pid,
                "path": path,
            })

        # Direct ID lookup (fast path)
        live = conf_by_id.get(pid)

        if live is None:
            # Not in EBS sub-trees → try direct API (might be outside EBS roots)
            live = get_page_by_id(base, auth, pid)

        if live is None:
            # Page doesn't exist anywhere → title match
            title_norm = _norm_title(e["title"])
            candidates = conf_by_title_norm.get(title_norm, [])
            if candidates:
                results["page_id_mismatch"].append({
                    "path": path,
                    "git_page_id": pid,
                    "git_title": e["title"],
                    "live_candidates": [
                        {
                            "id": c["id"],
                            "title": c["title"],
                            "space": c.get("space", {}).get("key", "?"),
                            "version": c.get("version", {}).get("number", "?"),
                        }
                        for c in candidates
                    ],
                })
            else:
                results["page_not_found"].append({
                    "path": path,
                    "page_id": pid,
                    "title": e["title"],
                })
            continue

        # Page exists — check URL consistency
        live_space_key = live.get("space", {}).get("key", "")
        git_url = e.get("confluence_url", "")
        if git_url and pid not in git_url:
            live_url = _make_url(base, live_space_key, pid, live["title"])
            results["url_mismatch"].append({
                "path": path,
                "page_id": pid,
                "git_url": git_url,
                "live_url": live_url,
                "live_title": live["title"],
            })
        else:
            results["ok"].append({
                "path": path,
                "page_id": pid,
                "title": live["title"],
                "space": live_space_key,
            })

        # Duplicate title across spaces?
        title_norm = _norm_title(live["title"])
        same_title = conf_by_title_norm.get(title_norm, [])
        if len(same_title) > 1:
            results["duplicate_confluence"].append({
                "path": path,
                "git_page_id": pid,
                "title": live["title"],
                "pages": [
                    {
                        "id": p["id"],
                        "space": p.get("space", {}).get("key", "?"),
                        "version": p.get("version", {}).get("number", "?"),
                    }
                    for p in same_title
                ],
            })

    # ── Step 4: Confluence → Git (unmapped) ──────────────────────────────────
    print(f"\n🔍 Step 4: Confluence → Git (unmapped pages)...")
    for page in conf_pages:
        pid = page["id"]
        if pid not in git_by_page_id:
            results["unmapped_confluence"].append({
                "page_id": pid,
                "title": page["title"],
                "space": page.get("space", {}).get("key", "?"),
                "version": page.get("version", {}).get("number", "?"),
                "ancestors": [a["title"] for a in page.get("ancestors", [])],
            })

    # ── Step 5: Auto-correct single-candidate page_id_mismatches ─────────────
    print(f"\n✏️  Step 5: Auto-correct (single-candidate mismatches)...")
    for item in results["page_id_mismatch"]:
        candidates = item["live_candidates"]
        entry = next((e for e in git_entries if e["path"] == item["path"]), None)
        if entry is None:
            continue

        if len(candidates) == 1:
            new_pid = candidates[0]["id"]
            new_space = candidates[0]["space"]
            new_title = candidates[0]["title"]
            new_url = _make_url(base, new_space, new_pid, new_title)

            print(f"  {'[DRY-RUN] ' if dry_run else ''}→ {item['path']}")
            print(f"    page-id:  {item['git_page_id']} → {new_pid}")
            print(f"    space:    {new_space}")
            print(f"    url:      {new_url}")

            if not dry_run:
                changed = patch_frontmatter_field(
                    entry["abs_path"], "confluence-page-id", new_pid
                )
                patch_frontmatter_field(entry["abs_path"], "confluence-url", new_url)
                if changed:
                    results["auto_corrected"].append({
                        "path": item["path"],
                        "old_page_id": item["git_page_id"],
                        "new_page_id": new_pid,
                        "space": new_space,
                        "new_url": new_url,
                    })
        else:
            print(f"  SKIP multi-candidate ({len(candidates)}): {item['path']}")

    # ── Step 6: Auto-correct URL mismatches ──────────────────────────────────
    print(f"\n✏️  Step 6: Auto-correct URL mismatches...")
    for item in results["url_mismatch"]:
        entry = next((e for e in git_entries if e["path"] == item["path"]), None)
        if entry is None:
            continue
        print(f"  {'[DRY-RUN] ' if dry_run else ''}→ {item['path']}")
        print(f"    url: {item['git_url']}")
        print(f"       → {item['live_url']}")
        if not dry_run:
            patch_frontmatter_field(entry["abs_path"], "confluence-url", item["live_url"])
            results["auto_corrected"].append({
                "path": item["path"],
                "type": "url_mismatch",
                "old_url": item["git_url"],
                "new_url": item["live_url"],
            })

    return results


def _norm_title(title: str) -> str:
    """Normalize title for comparison (lowercase, strip, collapse spaces)."""
    return re.sub(r'\s+', ' ', title.strip().lower())


def _make_url(base: str, space_key: str, page_id: str, title: str) -> str:
    safe_title = re.sub(r'[^\w\s-]', '', title).replace(' ', '+')
    return f"{base}/wiki/spaces/{space_key}/pages/{page_id}/{safe_title}"


# ─────────────────────────────────────────────────────────────────────────────
# Output
# ─────────────────────────────────────────────────────────────────────────────

def print_summary(results: dict) -> None:
    print(f"\n{'='*70}")
    print("  AUDIT SUMMARY")
    print(f"{'='*70}")
    print(f"  ✅ OK (verified):                    {len(results['ok'])}")
    print(f"  🔄 Auto-corrected:                   {len(results['auto_corrected'])}")
    print(f"  ⚠️  page_id_mismatch (candidates):    {len(results['page_id_mismatch'])}")
    print(f"  🔗 URL mismatch (corrected):          {len(results['url_mismatch'])}")
    print(f"  ❌ Page not found in Confluence:     {len(results['page_not_found'])}")
    print(f"  📋 Duplicate title in Confluence:    {len(results['duplicate_confluence'])}")
    print(f"  📋 Duplicate page-id in git:         {len(results['duplicate_git'])}")
    print(f"  🆕 Unmapped Confluence pages:        {len(results['unmapped_confluence'])}")
    print(f"{'='*70}")

    if results["auto_corrected"]:
        print("\n🔄 AUTO-CORRECTED:")
        for item in results["auto_corrected"]:
            print(f"  {item['path']}")
            if "old_page_id" in item:
                print(f"    page-id: {item['old_page_id']} → {item['new_page_id']}")
            if "old_url" in item:
                print(f"    url: ...→ {item.get('new_url','')}")

    if results["page_id_mismatch"]:
        print("\n⚠️  PAGE-ID MISMATCH (live candidates found — review required):")
        for item in results["page_id_mismatch"]:
            print(f"  {item['path']}  git={item['git_page_id']}")
            for c in item["live_candidates"]:
                print(f"    → id={c['id']} space={c['space']} title={c['title']} v{c['version']}")

    if results["page_not_found"]:
        print("\n❌ PAGE NOT FOUND IN CONFLUENCE:")
        for item in results["page_not_found"]:
            print(f"  {item['path']}  id={item['page_id']}  title={item['title']}")

    if results["duplicate_confluence"]:
        print("\n📋 DUPLICATE TITLES IN CONFLUENCE (user decision — which to delete?):")
        seen: set[str] = set()
        for item in results["duplicate_confluence"]:
            key = item["title"]
            if key in seen:
                continue
            seen.add(key)
            print(f"  title='{item['title']}'")
            for p in item["pages"]:
                marker = " ← git" if p["id"] == item["git_page_id"] else ""
                print(f"    id={p['id']} space={p['space']} v{p['version']}{marker}")

    if results["unmapped_confluence"]:
        print("\n🆕 UNMAPPED CONFLUENCE PAGES (no git .md — user decision):")
        for item in results["unmapped_confluence"]:
            anc = " > ".join(item["ancestors"][-2:]) if item["ancestors"] else ""
            print(f"  id={item['page_id']} space={item['space']} title={item['title']}")
            if anc:
                print(f"    under: {anc}")

    print()


def save_report(results: dict, output_path: Path) -> None:
    def clean(obj):
        if isinstance(obj, dict):
            return {k: clean(v) for k, v in obj.items()
                    if k not in ("abs_path", "fm")}
        if isinstance(obj, list):
            return [clean(i) for i in obj]
        return obj

    report = {
        "generated_at": datetime.now().isoformat(),
        "summary": {k: len(v) for k, v in results.items()},
        "details": clean(results),
    }
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"📄 Report saved: {output_path}")


# ─────────────────────────────────────────────────────────────────────────────
# Entry point
# ─────────────────────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Confluence ↔ Git page-id mapping audit (S11/Cycle-21)"
    )
    parser.add_argument("--dry-run", action="store_true",
                        help="Preview changes without writing files")
    parser.add_argument("--roots", default=",".join(DEFAULT_EBS_ROOTS),
                        help="Comma-separated EBS root page IDs")
    parser.add_argument(
        "--output",
        default="docs/4. Operations/confluence-page-id-audit.json",
        help="JSON report path (relative to repo root)",
    )
    args = parser.parse_args()

    ebs_roots = [r.strip() for r in args.roots.split(",") if r.strip()]
    output_path = REPO_ROOT / args.output

    try:
        results = run_audit(dry_run=args.dry_run, ebs_roots=ebs_roots)
    except RuntimeError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 2

    print_summary(results)
    save_report(results, output_path)

    drift_count = sum(
        len(results[k])
        for k in ("page_id_mismatch", "page_not_found", "url_mismatch", "duplicate_confluence")
    )
    return 1 if drift_count > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
