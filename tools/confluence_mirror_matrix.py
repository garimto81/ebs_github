#!/usr/bin/env python3
"""confluence_mirror_matrix — 미러 상태 매트릭스 자동 생성기.

SG-031 Phase 3 Task 6 산출물. 전체 `docs/*.md` 를 스캔하여 frontmatter 의
`confluence-page-id` / `mirror` 필드 기반으로 미러 상태를 분류하고,
`docs/_generated/confluence-mirror-matrix.md` 로 출력한다.

Usage:
    python tools/confluence_mirror_matrix.py            # 매트릭스 생성
    python tools/confluence_mirror_matrix.py --stdout   # stdout 출력 (파일 미생성)
    python tools/confluence_mirror_matrix.py --check    # CI: coverage 임계값 검사

Status 분류:
    mirrored   — confluence-page-id 가 유효한 숫자 ID
    excluded   — mirror: none
    pending    — confluence-page-id: null / tbd / 0 등 placeholder
    uncovered  — frontmatter 자체 부재 또는 두 필드 모두 없음

집계:
    section 별 (1. Product / 2. Development/2.X / 3. Change Requests / 4. Operations / etc)
    상태 분포 + coverage %
"""
from __future__ import annotations

import argparse
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from collections import defaultdict

if sys.platform == "win32":
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8")

REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS_ROOT = REPO_ROOT / "docs"
OUT_PATH = DOCS_ROOT / "_generated" / "confluence-mirror-matrix.md"

PLACEHOLDER_IDS = {"null", "none", "tbd", "0", "123456", ""}


def parse_frontmatter(md: Path) -> dict[str, str]:
    text = md.read_text(encoding="utf-8", errors="replace")
    if not text.startswith("---\n"):
        return {}
    end = text.find("\n---\n", 4)
    if end == -1:
        return {}
    fm: dict[str, str] = {}
    for line in text[4:end].splitlines():
        m = re.match(r"^([\w-]+):\s*(.*?)\s*$", line)
        if not m:
            continue
        k, v = m.group(1), m.group(2)
        if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
            v = v[1:-1]
        fm[k] = v
    return fm


def classify(fm: dict[str, str]) -> tuple[str, str, str]:
    """Return (status, page_id, parent_id). status ∈ mirrored/excluded/pending/uncovered."""
    page_id = fm.get("confluence-page-id", "").strip()
    parent_id = fm.get("confluence-parent-id", "").strip()
    mirror_flag = fm.get("mirror", "").strip().lower()

    if mirror_flag == "none":
        return ("excluded", "", parent_id)
    if not page_id:
        return ("uncovered", "", parent_id)
    if page_id.lower() in PLACEHOLDER_IDS or not page_id.isdigit():
        return ("pending", page_id, parent_id)
    return ("mirrored", page_id, parent_id)


def section_of(rel: Path) -> str:
    """Map a doc to a top-level section label."""
    parts = rel.parts
    if not parts:
        return "(root)"
    head = parts[0]
    if len(parts) >= 2 and head == "2. Development":
        return f"2. Development/{parts[1]}"
    return head


def scan() -> list[tuple[Path, str, str, str]]:
    """Return [(rel_path, status, page_id, parent_id)] for all docs/*.md."""
    rows: list[tuple[Path, str, str, str]] = []
    for md in DOCS_ROOT.rglob("*.md"):
        rel = md.relative_to(DOCS_ROOT)
        if "_generated" in rel.parts or "_archive" in rel.parts or "archive" in rel.parts:
            continue
        fm = parse_frontmatter(md)
        status, pid, parent = classify(fm)
        rows.append((rel, status, pid, parent))
    rows.sort(key=lambda r: str(r[0]).lower())
    return rows


def render(rows: list[tuple[Path, str, str, str]]) -> str:
    by_section: dict[str, list[tuple[Path, str, str, str]]] = defaultdict(list)
    for r in rows:
        by_section[section_of(r[0])].append(r)

    total = len(rows)
    mirrored = sum(1 for r in rows if r[1] == "mirrored")
    excluded = sum(1 for r in rows if r[1] == "excluded")
    pending = sum(1 for r in rows if r[1] == "pending")
    uncovered = sum(1 for r in rows if r[1] == "uncovered")
    covered = mirrored + excluded
    pct = (100.0 * covered / total) if total else 0.0

    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%MZ")
    lines: list[str] = []
    lines.append("---")
    lines.append("title: Confluence Mirror Matrix")
    lines.append("auto-generated: true")
    lines.append("source: tools/confluence_mirror_matrix.py")
    lines.append(f"generated-at: {now}")
    lines.append("mirror: none")
    lines.append("---")
    lines.append("")
    lines.append("# Confluence Mirror Matrix")
    lines.append("")
    lines.append("> **Auto-generated** by `tools/confluence_mirror_matrix.py` — do NOT edit manually.")
    lines.append("> Owner: SG-031 Phase 3 Task 6.")
    lines.append("")
    lines.append("## Summary")
    lines.append("")
    lines.append(f"- **Total docs**: {total}")
    lines.append(f"- **Mirrored** (confluence-page-id, valid): {mirrored}")
    lines.append(f"- **Excluded** (mirror: none): {excluded}")
    lines.append(f"- **Pending** (placeholder ID — null/tbd/0): {pending}")
    lines.append(f"- **Uncovered** (no frontmatter decision): {uncovered}")
    lines.append(f"- **Coverage** (mirrored + excluded): {covered}/{total} = **{pct:.1f}%**")
    lines.append("")
    lines.append("## Per-section coverage")
    lines.append("")
    lines.append("| Section | Total | Mirrored | Excluded | Pending | Uncovered | Coverage |")
    lines.append("|---|---:|---:|---:|---:|---:|---:|")
    for section in sorted(by_section.keys()):
        srows = by_section[section]
        sm = sum(1 for r in srows if r[1] == "mirrored")
        se = sum(1 for r in srows if r[1] == "excluded")
        sp = sum(1 for r in srows if r[1] == "pending")
        su = sum(1 for r in srows if r[1] == "uncovered")
        st = len(srows)
        sc = sm + se
        spct = (100.0 * sc / st) if st else 0.0
        lines.append(f"| {section} | {st} | {sm} | {se} | {sp} | {su} | {spct:.1f}% |")
    lines.append("")
    lines.append("## Detail")
    lines.append("")
    for section in sorted(by_section.keys()):
        lines.append(f"### {section}")
        lines.append("")
        lines.append("| File | Status | Page ID | Parent ID |")
        lines.append("|---|---|---|---|")
        for rel, status, pid, parent in by_section[section]:
            lines.append(f"| `{rel.as_posix()}` | {status} | {pid or '—'} | {parent or '—'} |")
        lines.append("")
    return "\n".join(lines) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--stdout", action="store_true", help="stdout 출력 (파일 미생성)")
    ap.add_argument("--check", action="store_true", help="CI: coverage 임계값 검사 (현재는 informational)")
    ap.add_argument("--min-coverage", type=float, default=0.0,
                    help="--check 와 함께. coverage < 임계값이면 exit 1 (기본 0 = 검사 안 함)")
    args = ap.parse_args()

    rows = scan()
    output = render(rows)

    total = len(rows)
    covered = sum(1 for r in rows if r[1] in ("mirrored", "excluded"))
    pct = (100.0 * covered / total) if total else 0.0

    if args.stdout:
        sys.stdout.write(output)
    else:
        OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
        OUT_PATH.write_text(output, encoding="utf-8")
        print(f"[matrix] wrote {OUT_PATH.relative_to(REPO_ROOT)} — {total} docs, coverage {pct:.1f}%")

    if args.check:
        if args.min_coverage > 0 and pct < args.min_coverage:
            print(f"[matrix] FAIL — coverage {pct:.1f}% < threshold {args.min_coverage:.1f}%", file=sys.stderr)
            return 1
        print(f"[matrix] OK — coverage {pct:.1f}% (threshold {args.min_coverage:.1f}%)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
