#!/usr/bin/env python3
"""Legacy ID → 신규 경로 검색.

모든 docs/**/*.md 의 frontmatter 에서 `legacy-id` 필드를 스캔하여
주어진 legacy ID 와 매칭되는 파일을 찾는다.

CLI:
    python tools/find_by_legacy.py BS-04-04
    python tools/find_by_legacy.py API-01
    python tools/find_by_legacy.py IMPL-03

매치 없으면 exit 1.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS_ROOT = REPO_ROOT / "docs"

LEGACY_RE = re.compile(r"^legacy-id:\s*(.+)$", re.MULTILINE)


def extract_legacy_id(path: Path) -> str | None:
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return None
    if not text.startswith("---"):
        return None
    end = text.find("\n---", 3)
    if end < 0:
        return None
    block = text[:end]
    m = LEGACY_RE.search(block)
    if not m:
        return None
    return m.group(1).strip()


def main() -> int:
    parser = argparse.ArgumentParser(description="legacy-id 로 신규 문서 경로 찾기")
    parser.add_argument("legacy_id", help="예: BS-04-04, API-01, IMPL-03")
    args = parser.parse_args()

    target = args.legacy_id.strip()
    print(f"[검색] legacy-id={target}")

    if not DOCS_ROOT.exists():
        print(f"[FATAL] docs/ 디렉토리 없음: {DOCS_ROOT}", file=sys.stderr)
        return 2

    matches: list[Path] = []
    for path in DOCS_ROOT.rglob("*.md"):
        if "_generated" in path.parts:
            continue
        lid = extract_legacy_id(path)
        if lid == target:
            matches.append(path)

    if not matches:
        print(f"[결과] 매치 없음: {target}")
        return 1

    print(f"[결과] 매치 {len(matches)} 개")
    for p in matches:
        print(f"  {p.relative_to(REPO_ROOT).as_posix()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
