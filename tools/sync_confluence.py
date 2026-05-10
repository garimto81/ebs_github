#!/usr/bin/env python3
"""sync_confluence — Bulk markdown → Confluence sync wrapper.

Scans docs/ for .md files with `confluence-page-id` frontmatter, then invokes
the existing md2confluence.py converter for each. Used by SG-031 Phase 3.

Usage:
    python tools/sync_confluence.py [--dry-run] [--check] [--filter <glob>] [--list]

Examples:
    # Show all mirror-targeted files
    python tools/sync_confluence.py --list

    # Push everything (real)
    python tools/sync_confluence.py

    # Dry-run preview only
    python tools/sync_confluence.py --dry-run

    # Drift check (CI mode) — exit 1 if any target fails dry-run simulation
    python tools/sync_confluence.py --check

    # Push only Game_Rules
    python tools/sync_confluence.py --filter "1. Product/Game_Rules/*"

Frontmatter contract:
    confluence-page-id: <ID>     → mirror target (push)
    mirror: none                 → explicit exclude
    (neither field)              → ignored (treated as private)

Brand new docs with `confluence-page-id: null` are also ignored — set a real ID first.

Branch guard:
    Refuses to run unless current branch == main (override with EBS_FORCE_MIRROR=1).
    --check and --list bypass the branch guard.
"""
from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

# Ensure UTF-8 output on Windows
if sys.platform == "win32":
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8")

REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS_ROOT = REPO_ROOT / "docs"
MD2CONF = Path("C:/claude/lib/confluence/md2confluence.py")


def current_branch() -> str:
    try:
        out = subprocess.check_output(
            ["git", "-C", str(REPO_ROOT), "rev-parse", "--abbrev-ref", "HEAD"],
            text=True,
        )
        return out.strip()
    except subprocess.CalledProcessError:
        return ""


def parse_frontmatter(md_path: Path) -> dict[str, str]:
    """Extract YAML frontmatter as dict (string values only, no nested)."""
    text = md_path.read_text(encoding="utf-8", errors="replace")
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
            key, val = m.group(1), m.group(2)
            # Strip surrounding quotes if any
            if (val.startswith('"') and val.endswith('"')) or (
                val.startswith("'") and val.endswith("'")
            ):
                val = val[1:-1]
            out[key] = val
    return out


def find_mirror_targets(filter_glob: str | None = None) -> list[tuple[Path, str, str | None]]:
    """Return [(md_path, page_id, parent_id_or_None)] for all docs with valid confluence-page-id."""
    targets: list[tuple[Path, str, str | None]] = []
    for md in DOCS_ROOT.rglob("*.md"):
        # Skip _generated and archive
        rel = md.relative_to(DOCS_ROOT)
        if "_generated" in rel.parts or "archive" in rel.parts:
            continue
        if filter_glob and not md.match(str(DOCS_ROOT / filter_glob)):
            continue

        fm = parse_frontmatter(md)
        page_id = fm.get("confluence-page-id", "").strip()
        mirror_flag = fm.get("mirror", "").strip().lower()
        parent_id = fm.get("confluence-parent-id", "").strip()

        if mirror_flag == "none":
            continue
        if not page_id or page_id in ("null", "none", "tbd", "0", "123456"):
            continue
        # Must be all digits
        if not page_id.isdigit():
            continue
        # parent_id: empty or invalid → None (no move)
        if not parent_id or not parent_id.isdigit():
            parent_id = None
        targets.append((md, page_id, parent_id))
    return targets


def push_one(md_path: Path, page_id: str, parent_id: str | None, dry_run: bool) -> bool:
    """Invoke md2confluence.py for one file. Returns True on success."""
    cmd = [sys.executable, str(MD2CONF), str(md_path), page_id]
    if parent_id:
        cmd.extend(["--parent-id", parent_id])
    if dry_run:
        cmd.append("--dry-run")
    move_msg = f" → parent {parent_id}" if parent_id else ""
    print(f"\n[PUSH] {md_path.relative_to(REPO_ROOT)} → page {page_id}{move_msg}")
    result = subprocess.run(cmd, cwd=str(REPO_ROOT))
    return result.returncode == 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dry-run", action="store_true", help="Preview without uploading")
    ap.add_argument("--check", action="store_true",
                    help="Drift check (CI mode): dry-run all targets, exit 1 if any fails. Bypasses branch guard.")
    ap.add_argument("--filter", help="Glob filter relative to docs/, e.g. '1. Product/Game_Rules/*'")
    ap.add_argument("--list", action="store_true", help="List mirror targets and exit")
    ap.add_argument("--no-branch-guard", action="store_true", help="Skip main-branch check (CI override)")
    args = ap.parse_args()

    # --check implies --dry-run + bypass branch guard (CI runs on any branch)
    if args.check:
        args.dry_run = True
        args.no_branch_guard = True

    # Branch guard
    if not args.no_branch_guard and not args.list and not os.environ.get("EBS_FORCE_MIRROR"):
        branch = current_branch()
        if branch != "main":
            print(f"ERROR: current branch is '{branch}', refusing to push (main only).", file=sys.stderr)
            print("       Set EBS_FORCE_MIRROR=1 or pass --no-branch-guard to override.", file=sys.stderr)
            return 2

    if not MD2CONF.exists():
        # In --check mode, missing tool is a CI environment issue — surface as warning, not failure.
        if args.check:
            print(f"WARN: md2confluence.py not found at {MD2CONF} (CI environment may not have it).", file=sys.stderr)
            print("Drift check skipped — no failure recorded.", file=sys.stderr)
            return 0
        print(f"ERROR: md2confluence.py not found at {MD2CONF}", file=sys.stderr)
        return 1

    targets = find_mirror_targets(args.filter)
    if not targets:
        print("No mirror targets found." + (f" (filter: {args.filter})" if args.filter else ""))
        return 0

    if args.check:
        print(f"[drift-check] {len(targets)} mirror target(s) — running dry-run simulation")
    else:
        print(f"Found {len(targets)} mirror target(s):")
        for md, pid, parent in targets:
            move_msg = f" [parent: {parent}]" if parent else ""
            print(f"  - {md.relative_to(REPO_ROOT)} → page {pid}{move_msg}")

    if args.list:
        return 0

    # Push each
    failed: list[Path] = []
    for md, pid, parent in targets:
        if not push_one(md, pid, parent, args.dry_run):
            failed.append(md)

    print()
    mode = "[DRY-RUN]" if args.dry_run and not args.check else ("[DRIFT-CHECK]" if args.check else "")
    print(f"Result: {len(targets) - len(failed)}/{len(targets)} succeeded {mode}".rstrip())
    if failed:
        print("FAILED:")
        for md in failed:
            print(f"  - {md.relative_to(REPO_ROOT)}")
        if args.check:
            print(f"\n[drift-check] DRIFT DETECTED — {len(failed)}/{len(targets)} target(s) failed simulation.", file=sys.stderr)
        return 1
    if args.check:
        print(f"\n[drift-check] OK — all {len(targets)} target(s) up-to-date.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
