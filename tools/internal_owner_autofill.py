#!/usr/bin/env python3
"""
internal_owner_autofill.py — P5 Iteration 2

F 카테고리(Internal spec) 의 owner/stream 필드 자동 추가.
경로 기반 stream 추론:
  2.1 Frontend/*  → S2 (Lobby)
  2.2 Backend/*   → S7 (Backend)
  2.3 Game Engine/* → S8 (Engine)
  2.4 Command Center/* → S3 (CC)
  2.5 Shared/*    → conductor
  4. Operations/* → conductor

사용:
  python tools/internal_owner_autofill.py --dry-run
  python tools/internal_owner_autofill.py --confirm
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))
from ssot_verify import iter_docs, read_frontmatter, classify_file  # noqa: E402

DOCS_ROOT = (THIS_DIR.parent / "docs").resolve()

FRONTMATTER_BLOCK_RE = re.compile(r"^(---\s*\n)(.*?)(\n---\s*\n)", re.DOTALL)

# 경로 → stream 매핑 (Product_SSOT_Policy §3 Stream 책임 매트릭스 기반)
PATH_STREAM_MAP = [
    ("2. Development/2.1 Frontend/", "S2"),
    ("2. Development/2.2 Backend/", "S7"),
    ("2. Development/2.3 Game Engine/", "S8"),
    ("2. Development/2.4 Command Center/", "S3"),
    ("2. Development/2.5 Shared/", "conductor"),
    ("4. Operations/", "conductor"),
]


def determine_owner(md: Path) -> str:
    rel = str(md.relative_to(DOCS_ROOT)).replace("\\", "/")
    for prefix, owner in PATH_STREAM_MAP:
        if rel.startswith(prefix):
            return owner
    return "conductor"


def inject_owner(text: str, owner: str) -> tuple[str, bool]:
    m = FRONTMATTER_BLOCK_RE.match(text)
    if not m:
        new_fm = f"---\nowner: {owner}\n---\n\n"
        return new_fm + text, True
    head, body, tail = m.group(1), m.group(2), m.group(3)
    # 이미 owner 또는 stream 있으면 skip
    if re.search(r"^(owner|stream)\s*:", body, re.MULTILINE):
        return text, False
    new_body = body.rstrip() + f"\nowner: {owner}"
    return head + new_body + tail + text[m.end():], True


def main() -> int:
    parser = argparse.ArgumentParser(description="P5 Internal owner autofill")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--confirm", action="store_true")
    args = parser.parse_args()
    if not args.dry_run and not args.confirm:
        args.dry_run = True

    changes = []
    for md in iter_docs(DOCS_ROOT):
        fm = read_frontmatter(md)
        cat = classify_file(md, DOCS_ROOT, fm)
        if cat != "F":
            continue
        fm = fm or {}
        if fm.get("owner") or fm.get("stream"):
            continue
        owner = determine_owner(md)
        changes.append((md, owner))

    print(f"P5 Internal owner 자동 추가 대상: {len(changes)} 파일")
    for path, owner in changes:
        rel = str(path.relative_to(DOCS_ROOT)).replace("\\", "/")
        print(f"  {rel} → owner: {owner}")

    if args.confirm:
        success = 0
        for path, owner in changes:
            text = path.read_text(encoding="utf-8")
            new_text, modified = inject_owner(text, owner)
            if modified:
                path.write_text(new_text, encoding="utf-8")
                success += 1
        print(f"\nOK: {success}/{len(changes)} 파일 수정 완료.")
        return 0
    return 1 if changes else 0


if __name__ == "__main__":
    sys.exit(main())
