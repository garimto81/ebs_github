#!/usr/bin/env python3
"""auto_mirror_none — internal-only docs 에 mirror: none frontmatter 자동 부여.

SG-031 Phase 4 Task 7 (보강) — uncovered docs 의 명백한 internal-only 패턴을
auto-classify 하여 frontmatter 의 `mirror: none` 을 부여한다. 외부 인계 가치
있는 문서는 건드리지 않음 (사람이 confluence-page-id 부여).

Usage:
    python tools/auto_mirror_none.py --dry-run      # preview
    python tools/auto_mirror_none.py                # apply
    python tools/auto_mirror_none.py --rule <name>  # 특정 rule 만

Rules (path glob 기반, internal-only 로 명백한 것만):
    backlog       — */Backlog/B-*.md, */Backlog/NOTIFY-*.md, */Backlog/IMPL-*.md
    reports       — */Reports/*.md (날짜 prefix 보고서)
    orchestration — 4. Operations/orchestration/**/*.md
    handoffs      — 4. Operations/handoffs/**/*.md
    task-board    — 4. Operations/Task_Dispatch_Board/**/*.md
    cr-internal   — 3. Change Requests/INDEX.md, README.md
    examples-rm   — examples/README.md

이미 frontmatter 에 mirror 또는 confluence-page-id 가 있는 파일은 skip.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Callable

if sys.platform == "win32":
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8")

REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS_ROOT = REPO_ROOT / "docs"


# Rule predicates over relative path (POSIX form, relative to docs/)
RULES: dict[str, Callable[[str], bool]] = {
    "backlog": lambda r: "/Backlog/" in r and (
        "/B-" in r or "/NOTIFY-" in r or "/IMPL-" in r or "/SG-" in r
    ) and r.endswith(".md"),
    "archived-backlog": lambda r: "/Backlog/_archived" in r and r.endswith(".md"),
    "reports": lambda r: "/Reports/" in r and r.endswith(".md"),
    "orchestration": lambda r: r.startswith("4. Operations/orchestration/") and r.endswith(".md"),
    "handoffs": lambda r: r.startswith("4. Operations/handoffs/") and r.endswith(".md"),
    "task-board": lambda r: r.startswith("4. Operations/Task_Dispatch_Board/") and r.endswith(".md"),
    "cr-internal": lambda r: r in (
        "3. Change Requests/INDEX.md",
        "3. Change Requests/README.md",
    ),
    "examples-rm": lambda r: r == "examples/README.md",
}


def parse_frontmatter(text: str) -> tuple[dict[str, str], int]:
    """Return (fm_dict, fm_end_offset). offset is index after closing '---\\n', or 0 if no fm."""
    if not text.startswith("---\n"):
        return ({}, 0)
    end = text.find("\n---\n", 4)
    if end == -1:
        return ({}, 0)
    fm: dict[str, str] = {}
    for line in text[4:end].splitlines():
        m = re.match(r"^([\w-]+):\s*(.*?)\s*$", line)
        if not m:
            continue
        v = m.group(2).strip()
        if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
            v = v[1:-1]
        fm[m.group(1)] = v
    return (fm, end + len("\n---\n"))


def needs_classification(fm: dict[str, str]) -> bool:
    """True if doc has neither confluence-page-id nor mirror set."""
    pid = fm.get("confluence-page-id", "").strip()
    mn = fm.get("mirror", "").strip().lower()
    if mn:  # any mirror value (none/yes/etc) — already decided
        return False
    if pid and pid.isdigit():
        return False
    return True


def apply_mirror_none(text: str) -> str:
    """Insert/append `mirror: none` into frontmatter. Idempotent."""
    if not text.startswith("---\n"):
        # No frontmatter — create one
        return f"---\nmirror: none\n---\n\n{text}"
    fm, end = parse_frontmatter(text)
    if "mirror" in fm:
        return text  # already set
    # Insert before closing '---\n'
    closing = text.find("\n---\n", 4)
    insert_at = closing
    new_text = text[:insert_at] + "\nmirror: none" + text[insert_at:]
    return new_text


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dry-run", action="store_true", help="preview only")
    ap.add_argument("--rule", choices=list(RULES.keys()), help="apply only one rule")
    args = ap.parse_args()

    rules = [(name, fn) for name, fn in RULES.items() if not args.rule or name == args.rule]

    matched: list[tuple[str, str]] = []  # (rule, rel_path)
    for md in DOCS_ROOT.rglob("*.md"):
        rel = md.relative_to(DOCS_ROOT).as_posix()
        if "_generated" in rel or "_archive" in rel or rel.startswith("archive/"):
            continue
        text = md.read_text(encoding="utf-8", errors="replace")
        fm, _ = parse_frontmatter(text)
        if not needs_classification(fm):
            continue
        for rule_name, predicate in rules:
            if predicate(rel):
                matched.append((rule_name, rel))
                break

    print(f"[auto-mirror-none] matched: {len(matched)} files")
    by_rule: dict[str, int] = {}
    for rule_name, _ in matched:
        by_rule[rule_name] = by_rule.get(rule_name, 0) + 1
    for rule_name in sorted(by_rule.keys()):
        print(f"  {by_rule[rule_name]:4d}  {rule_name}")

    if args.dry_run:
        print()
        print("[dry-run] sample (first 10):")
        for rule_name, rel in matched[:10]:
            print(f"  [{rule_name}] {rel}")
        return 0

    # Apply
    changed = 0
    for rule_name, rel in matched:
        md = DOCS_ROOT / rel
        text = md.read_text(encoding="utf-8", errors="replace")
        new_text = apply_mirror_none(text)
        if new_text != text:
            md.write_text(new_text, encoding="utf-8")
            changed += 1

    print(f"[auto-mirror-none] applied: {changed} files modified")
    return 0


if __name__ == "__main__":
    sys.exit(main())
