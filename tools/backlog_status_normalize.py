#!/usr/bin/env python3
"""
backlog_status_normalize.py — P5 Iteration 1

D 카테고리(Backlog) 의 frontmatter `status` 정규화:
  - 필드명 통일: status → backlog-status
  - 값 정규화: DONE → done, PENDING → open, IN_PROGRESS → in-progress, BLOCKED → blocked
  - done 상태에 close-date 없으면 git log 마지막 수정일 자동 채움

사용:
  python tools/backlog_status_normalize.py --dry-run
  python tools/backlog_status_normalize.py --confirm
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))
from ssot_verify import iter_docs, read_frontmatter, classify_file  # noqa: E402

DOCS_ROOT = (THIS_DIR.parent / "docs").resolve()
REPO_ROOT = THIS_DIR.parent

FRONTMATTER_BLOCK_RE = re.compile(r"^(---\s*\n)(.*?)(\n---\s*\n)", re.DOTALL)

# 값 정규화 매핑 (uppercase / underscore → lowercase / hyphen)
STATUS_MAP = {
    "DONE": "done",
    "PENDING": "open",
    "OPEN": "open",
    "ACTIVE": "open",
    "IN_PROGRESS": "in-progress",
    "IN-PROGRESS": "in-progress",
    "INPROGRESS": "in-progress",
    "PROGRESS": "in-progress",
    "BLOCKED": "blocked",
    "WAITING": "blocked",
    "ABANDONED": "abandoned",
    "REJECTED": "abandoned",
    "CANCELLED": "abandoned",
    "CANCELED": "abandoned",
    "CLOSED": "done",
    "COMPLETED": "done",
}


def get_git_modified_date(path: Path) -> str:
    """git log 의 최근 commit date (YYYY-MM-DD) 반환. 실패 시 today."""
    try:
        rel = str(path.relative_to(REPO_ROOT))
        result = subprocess.run(
            ["git", "log", "-1", "--format=%ad", "--date=short", "--", rel],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            timeout=5,
        )
        date = result.stdout.strip()
        if re.match(r"\d{4}-\d{2}-\d{2}", date):
            return date
    except (subprocess.TimeoutExpired, OSError):
        pass
    return "2026-05-14"


def normalize_status(text: str, path: Path) -> tuple[str, bool]:
    """frontmatter 의 status / backlog-status 필드 정규화. (new_text, modified)."""
    m = FRONTMATTER_BLOCK_RE.match(text)
    if not m:
        return text, False
    head, body, tail = m.group(1), m.group(2), m.group(3)

    modified = False
    new_body = body

    # 1. status: → backlog-status: (필드명 통일)
    # 단, 이미 backlog-status 가 있으면 status 제거
    has_backlog_status = bool(re.search(r"^backlog-status\s*:", body, re.MULTILINE))
    has_status = bool(re.search(r"^status\s*:", body, re.MULTILINE))

    if has_status and not has_backlog_status:
        new_body = re.sub(
            r"^status(\s*:)", r"backlog-status\1", new_body, flags=re.MULTILINE
        )
        modified = True
    elif has_status and has_backlog_status:
        # status 라인 제거 (backlog-status 가 우선)
        new_body = re.sub(r"^status\s*:.*\n", "", new_body, flags=re.MULTILINE)
        modified = True

    # 2. 값 정규화 (대문자 → 소문자)
    def replace_value(m):
        nonlocal modified
        key = m.group(1)
        val = m.group(2).strip()
        # 따옴표 제거
        if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
            val = val[1:-1]
        upper = val.upper()
        new_val = STATUS_MAP.get(upper)
        if new_val and new_val != val:
            modified = True
            return f"{key}: {new_val}"
        return m.group(0)

    new_body = re.sub(
        r"^(backlog-status)\s*:\s*(\S+.*?)$",
        replace_value,
        new_body,
        flags=re.MULTILINE,
    )

    # 3. done/abandoned 상태에 close-date 없으면 추가
    status_match = re.search(r"^backlog-status\s*:\s*(\S+)", new_body, re.MULTILINE)
    if status_match:
        status_val = status_match.group(1).strip().lower()
        has_close_date = bool(re.search(r"^close-date\s*:", new_body, re.MULTILINE))
        if status_val in ("done", "abandoned") and not has_close_date:
            git_date = get_git_modified_date(path)
            new_body = new_body.rstrip() + f"\nclose-date: {git_date}"
            modified = True

    if not modified:
        return text, False
    return head + new_body + tail + text[m.end():], True


def main() -> int:
    parser = argparse.ArgumentParser(description="P5 Backlog status normalize")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--confirm", action="store_true")
    args = parser.parse_args()
    if not args.dry_run and not args.confirm:
        args.dry_run = True

    changes = []
    for md in iter_docs(DOCS_ROOT):
        fm = read_frontmatter(md)
        cat = classify_file(md, DOCS_ROOT, fm)
        if cat != "D":
            continue
        text = md.read_text(encoding="utf-8")
        new_text, modified = normalize_status(text, md)
        if modified:
            changes.append((md, new_text))

    print(f"P5 Backlog status 정규화 대상: {len(changes)} 파일")
    for md, _ in changes[:20]:
        rel = str(md.relative_to(DOCS_ROOT)).replace("\\", "/")
        print(f"  {rel}")
    if len(changes) > 20:
        print(f"  ... and {len(changes) - 20} more")

    if args.confirm:
        print()
        success = 0
        for md, new_text in changes:
            md.write_text(new_text, encoding="utf-8")
            success += 1
        print(f"OK: {success}/{len(changes)} 파일 수정 완료.")
        return 0

    return 1 if changes else 0


if __name__ == "__main__":
    sys.exit(main())
