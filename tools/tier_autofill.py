#!/usr/bin/env python3
"""
tier_autofill.py — Phase 4 tier 누락 자동 추가

경로 기반 tier 자동 추론:
  Backlog/NOTIFY-*.md             → tier:internal + backlog-status:open
  Backlog/B-*.md                  → tier:internal + backlog-status:open
  Conductor_Backlog/SG-*.md       → tier:internal + backlog-status:open
  Behavioral_Specs/*.md           → tier:contract (Behavioral_Specs 형제 = contract)
  4. Operations/*.md              → tier:operations
  *.md (그 외)                     → tier:internal

사용:
  python tools/tier_autofill.py --dry-run
  python tools/tier_autofill.py --confirm

Exit: 0 OK / 1 변경 있음 / 2 오류
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


def determine_tier_fields(md: Path) -> dict[str, str]:
    """파일 경로 기반 tier + 추가 frontmatter 결정."""
    rel = str(md.relative_to(DOCS_ROOT)).replace("\\", "/")
    name = md.name

    out: dict[str, str] = {}

    # NOTIFY-*, B-*, SG-* 백로그
    if name.startswith("NOTIFY-") or name.startswith("B-") or name.startswith("SG-"):
        out["tier"] = "internal"
        out["backlog-status"] = "open"
        return out

    # Behavioral_Specs 하위
    if "Behavioral_Specs/" in rel:
        out["tier"] = "contract"
        return out

    # 4. Operations 폴더
    if rel.startswith("4. Operations/"):
        out["tier"] = "operations"
        return out

    # 그 외
    out["tier"] = "internal"
    return out


def inject_frontmatter_fields(text: str, fields: dict[str, str]) -> tuple[str, bool]:
    """frontmatter 에 필드 추가. 이미 있는 키는 skip."""
    m = FRONTMATTER_BLOCK_RE.match(text)
    if not m:
        # frontmatter 없음 — 신규 생성
        lines = [f"{k}: {v}" for k, v in fields.items()]
        new_fm = "---\n" + "\n".join(lines) + "\n---\n\n"
        return new_fm + text, True

    head, body, tail = m.group(1), m.group(2), m.group(3)
    additions = []
    for key, value in fields.items():
        if re.search(rf"^{re.escape(key)}\s*:", body, re.MULTILINE):
            continue
        additions.append(f"{key}: {value}")
    if not additions:
        return text, False

    new_body = body.rstrip() + "\n" + "\n".join(additions)
    return head + new_body + tail + text[m.end():], True


def main() -> int:
    parser = argparse.ArgumentParser(description="Phase 4 tier autofill")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--confirm", action="store_true")
    args = parser.parse_args()
    if not args.dry_run and not args.confirm:
        args.dry_run = True

    changes = []
    for md in iter_docs(DOCS_ROOT):
        fm = read_frontmatter(md)
        cat = classify_file(md, DOCS_ROOT, fm)
        if cat != "I":
            continue
        fields = determine_tier_fields(md)
        changes.append((md, fields))

    print(f"Phase 4 (tier autofill) 변경 대상: {len(changes)} 파일")
    print()
    for path, fields in changes:
        rel = str(path.relative_to(DOCS_ROOT)).replace("\\", "/")
        print(f"  {rel}")
        for k, v in fields.items():
            print(f"    + {k}: {v}")

    if args.confirm:
        print()
        print("실제 파일 수정 중...")
        success = 0
        for path, fields in changes:
            text = path.read_text(encoding="utf-8")
            new_text, modified = inject_frontmatter_fields(text, fields)
            if modified:
                path.write_text(new_text, encoding="utf-8")
                success += 1
        print(f"OK: {success}/{len(changes)} 파일 수정 완료.")
        return 0

    return 1 if changes else 0


if __name__ == "__main__":
    sys.exit(main())
