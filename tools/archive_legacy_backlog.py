#!/usr/bin/env python3
"""IMPL-001: 4팀 Backlog 정리 — NOTIFY-CCR / DONE 파일 archive 이동 자동화.

실행:
  python tools/archive_legacy_backlog.py --dry-run        # 계획만 출력
  python tools/archive_legacy_backlog.py                   # 실제 이동

대상 경로 (4 팀 Backlog):
  - docs/2. Development/2.1 Frontend/Backlog/
  - docs/2. Development/2.2 Backend/Backlog/
  - docs/2. Development/2.3 Game Engine/Backlog/
  - docs/2. Development/2.4 Command Center/Backlog/

이동 규칙 (backlog_retag.py 와 동일):
  - NOTIFY-CCR-*.md         → _archived-2026-04/notify-ccr/
  - NOTIFY-LEGACY-CCR-*.md  → _archived-2026-04/notify-legacy/
  - *-DONE-YYYY-MM-DD.md    → _archived-2026-04/done/

Git: `git mv` 사용으로 히스토리 보존.
"""
from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

TEAM_BACKLOG_DIRS = [
    Path("docs/2. Development/2.1 Frontend/Backlog"),
    Path("docs/2. Development/2.2 Backend/Backlog"),
    Path("docs/2. Development/2.3 Game Engine/Backlog"),
    Path("docs/2. Development/2.4 Command Center/Backlog"),
]

PATTERNS = [
    (re.compile(r"^NOTIFY-LEGACY-CCR-", re.I), "_archived-2026-04/notify-legacy"),
    (re.compile(r"^NOTIFY-CCR-", re.I), "_archived-2026-04/notify-ccr"),
    (re.compile(r"-DONE-\d{4}-\d{2}-\d{2}\.md$"), "_archived-2026-04/done"),
]


def classify(name: str) -> str | None:
    for pat, target_rel in PATTERNS:
        if pat.search(name):
            return target_rel
    return None


def git_mv(src: Path, dst: Path, dry_run: bool) -> bool:
    """Use git mv if possible, fall back to shutil.move."""
    if dry_run:
        return True
    dst.parent.mkdir(parents=True, exist_ok=True)
    try:
        subprocess.run(
            ["git", "mv", str(src), str(dst)],
            check=True,
            capture_output=True,
        )
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        try:
            shutil.move(str(src), str(dst))
            return True
        except OSError as e:
            print(f"  ✗ move failed: {e}", file=sys.stderr)
            return False


def process_dir(backlog_dir: Path, dry_run: bool) -> tuple[int, int]:
    if not backlog_dir.is_dir():
        print(f"  (not a directory, skipping)")
        return 0, 0

    moved = 0
    skipped = 0
    for md in sorted(backlog_dir.glob("*.md")):
        if md.name.startswith("_"):
            continue  # 템플릿/README 스킵
        if md.name == "README.md":
            continue
        target_rel = classify(md.name)
        if target_rel is None:
            skipped += 1
            continue

        target_dir = backlog_dir / target_rel
        target_path = target_dir / md.name

        action = "DRY-RUN" if dry_run else "MOVE"
        print(f"  [{action}] {md.name}  →  {target_rel}/")

        if git_mv(md, target_path, dry_run):
            moved += 1
    return moved, skipped


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args(argv)

    total_moved = 0
    total_skipped = 0
    for d in TEAM_BACKLOG_DIRS:
        print(f"\n# {d}")
        m, s = process_dir(d, args.dry_run)
        total_moved += m
        total_skipped += s
        print(f"  moved: {m}  skipped: {s}")

    print(
        f"\n=== Total: moved {total_moved}, "
        f"skipped (kept in-place) {total_skipped} ==="
    )
    if args.dry_run:
        print("NOTE: dry-run 결과. 실제 이동하려면 --dry-run 없이 재실행.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
