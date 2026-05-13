#!/usr/bin/env python3
"""
archive_records.py — Phase 2 Aggressive Cleanup 도구

사용자 결정 (Product_SSOT_Policy.md §9.5, 2026-05-13):
  1. Orphan 노드 전부 archive (doc-discovery graph 상 어디서도 참조 안 됨)
  2. 기록물 전부 archive (Cycle/Critic/Audit/Conductor_Backlog done)
  3. B-NNN done/abandoned 전부 archive (날짜 무관)
  4. Confluence sync 제외 등록

archive 후 구조:
  docs/_archive/
    ├── backlog-done/      D 카테고리 status=done|abandoned
    ├── cycles/             Cycle_NN/ 전체
    ├── critic-reports/     *_Critic_*.md
    ├── audit-reports/      *_Audit_*.md
    ├── conductor-done/     Conductor_Backlog/done/
    ├── cr-done/            CR-NNN status=done|rejected (선택)
    └── orphan/             graph orphan (참조되지 않는 파일)

사용:
  python tools/archive_records.py --dry-run          # archive 대상 list만 출력
  python tools/archive_records.py --dry-run --json   # JSON 출력
  python tools/archive_records.py --confirm          # 실제 git mv 실행
  python tools/archive_records.py --target records   # 기록물만 archive
  python tools/archive_records.py --target backlog   # D done만 archive
  python tools/archive_records.py --target orphan    # orphan만 archive

Exit:
  0 — OK
  1 — Archive 대상 식별 (dry-run 시 informational)
  2 — 도구 오류
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

try:
    import yaml  # type: ignore
except ImportError:
    print("ERROR: PyYAML 미설치. pip install pyyaml.", file=sys.stderr)
    sys.exit(2)

# ssot_verify의 분류 룰 재사용
THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))
from ssot_verify import (  # noqa: E402
    classify_file,
    read_frontmatter,
    iter_docs,
    CATEGORY_DEFS,
)


# ----------------------------------------------------------------------------
# Archive 매핑 (카테고리/패턴 → archive 하위 폴더)
# ----------------------------------------------------------------------------

ARCHIVE_ROOT = "_archive"

# 카테고리 E 하위 패턴별 archive 폴더 매핑
E_SUBFOLDER_PATTERNS = [
    (re.compile(r"Cycle_?\d+", re.IGNORECASE), "cycles"),
    (re.compile(r"_Critic_|Critic_Reports/", re.IGNORECASE), "critic-reports"),
    (re.compile(r"_Audit_", re.IGNORECASE), "audit-reports"),
    (re.compile(r"Conductor_Backlog/done/", re.IGNORECASE), "conductor-done"),
]


@dataclass
class ArchiveTarget:
    file: Path
    target: Path
    reason: str  # 'records' / 'backlog-done' / 'orphan' / 'cr-done'
    sub: str    # archive 하위 폴더명


# ----------------------------------------------------------------------------
# 링크 그래프 빌드 (orphan 검출)
# ----------------------------------------------------------------------------

MD_LINK_RE = re.compile(r"\]\(([^)]+\.md)(?:#[^)]*)?\)")
FRONTMATTER_LINK_KEYS = ("derivative-of", "references", "related-spec",
                          "supersedes", "impacts")


def collect_references(docs_root: Path) -> set[str]:
    """모든 .md 가 어떤 파일을 link 하는지 수집. resolved absolute path set."""
    refs: set[str] = set()
    for md in iter_docs(docs_root, skip_archive=False):
        # 1. frontmatter 의 link 필드
        fm = read_frontmatter(md) or {}
        for key in FRONTMATTER_LINK_KEYS:
            val = fm.get(key)
            if not val:
                continue
            items = val if isinstance(val, list) else [val]
            for item in items:
                s = str(item).strip()
                # impacts 의 [POL-NN (...)] 같은 형식은 file path 아니므로 skip
                if not s.endswith(".md"):
                    # 단, "Lobby.md" 같은 단순 파일명 포함 시 처리
                    continue
                try:
                    resolved = (md.parent / s).resolve()
                    refs.add(str(resolved))
                except (OSError, ValueError):
                    pass

        # 2. 본문 markdown link
        try:
            text = md.read_text(encoding="utf-8-sig")
        except OSError:
            continue
        for m in MD_LINK_RE.finditer(text):
            link = m.group(1).strip()
            # URL-encoded space 처리
            link = link.replace("%20", " ")
            try:
                resolved = (md.parent / link).resolve()
                refs.add(str(resolved))
            except (OSError, ValueError):
                pass

    return refs


# ----------------------------------------------------------------------------
# Archive 대상 식별
# ----------------------------------------------------------------------------

def determine_e_subfolder(rel_str: str) -> str:
    for pat, sub in E_SUBFOLDER_PATTERNS:
        if pat.search(rel_str):
            return sub
    return "operations-misc"


def identify_targets(docs_root: Path, targets: set[str]) -> list[ArchiveTarget]:
    """archive 대상 식별. targets = {'records', 'backlog', 'orphan', 'cr'}."""
    results: list[ArchiveTarget] = []
    archive_root = docs_root / ARCHIVE_ROOT

    # 카테고리 분류 (skip_archive=True — 이미 archive 폴더는 제외)
    e_files: list[Path] = []
    d_done_files: list[Path] = []
    cr_done_files: list[Path] = []
    all_active_files: list[Path] = []

    for md in iter_docs(docs_root, skip_archive=True):
        fm = read_frontmatter(md)
        cat = classify_file(md, docs_root, fm)

        if cat == "E":
            e_files.append(md)
        elif cat == "D":
            fm = fm or {}
            status = fm.get("backlog-status") or fm.get("status")
            if status in ("done", "abandoned"):
                d_done_files.append(md)
        elif cat == "C":
            fm = fm or {}
            status = fm.get("status")
            # 폴더 경로에 done/ 포함 시 자동 done 으로 판정
            rel = str(md.relative_to(docs_root)).replace("\\", "/")
            if status in ("done", "rejected") or "/done/" in rel:
                cr_done_files.append(md)

        if cat not in ("H", "G"):
            all_active_files.append(md)

    # 1. records (E 카테고리 전부)
    if "records" in targets:
        for md in e_files:
            rel_str = str(md.relative_to(docs_root)).replace("\\", "/")
            sub = determine_e_subfolder(rel_str)
            target = archive_root / sub / md.name
            results.append(ArchiveTarget(file=md, target=target, reason="records", sub=sub))

    # 2. backlog (D done/abandoned)
    if "backlog" in targets:
        for md in d_done_files:
            target = archive_root / "backlog-done" / md.name
            results.append(ArchiveTarget(file=md, target=target, reason="backlog-done", sub="backlog-done"))

    # 3. cr-done (C done/rejected)
    if "cr" in targets:
        for md in cr_done_files:
            target = archive_root / "cr-done" / md.name
            results.append(ArchiveTarget(file=md, target=target, reason="cr-done", sub="cr-done"))

    # 4. orphan (graph 상 link 없음)
    if "orphan" in targets:
        refs = collect_references(docs_root)
        already_archived = {t.file for t in results}
        for md in all_active_files:
            if md in already_archived:
                continue
            md_resolved = str(md.resolve())
            if md_resolved not in refs:
                # 자기 자신을 references 하는 _generated 인덱스 등 제외
                fm = read_frontmatter(md) or {}
                cat = classify_file(md, docs_root, fm)
                # A / B 카테고리는 SSOT 정본이라 orphan 이어도 archive 금지
                if cat in ("A", "B"):
                    continue
                target = archive_root / "orphan" / md.name
                results.append(ArchiveTarget(file=md, target=target, reason="orphan", sub="orphan"))

    return results


# ----------------------------------------------------------------------------
# 실행 (dry-run / confirm)
# ----------------------------------------------------------------------------

def print_summary(targets: list[ArchiveTarget], docs_root: Path) -> None:
    """archive 대상 요약 + 카테고리별 갯수."""
    by_reason: dict[str, list[ArchiveTarget]] = {}
    for t in targets:
        by_reason.setdefault(t.reason, []).append(t)

    print(f"=== Archive 대상 식별 결과 ===")
    print(f"docs root: {docs_root}")
    print(f"Total 이동 대상: {len(targets)} 파일")
    print()
    for reason, items in sorted(by_reason.items()):
        print(f"  [{reason}] {len(items)} 파일")
    print()

    # 상세 list (각 reason 별 head 10)
    for reason, items in sorted(by_reason.items()):
        print(f"--- [{reason}] (showing first 10) ---")
        for t in items[:10]:
            src_rel = str(t.file.relative_to(docs_root)).replace("\\", "/")
            tgt_rel = str(t.target.relative_to(docs_root)).replace("\\", "/")
            print(f"  {src_rel}")
            print(f"    → {tgt_rel}")
        if len(items) > 10:
            print(f"  ... and {len(items) - 10} more")
        print()


def print_json(targets: list[ArchiveTarget], docs_root: Path) -> None:
    out = {
        "docs_root": str(docs_root),
        "total": len(targets),
        "targets": [
            {
                "file": str(t.file.relative_to(docs_root)).replace("\\", "/"),
                "target": str(t.target.relative_to(docs_root)).replace("\\", "/"),
                "reason": t.reason,
                "sub": t.sub,
            }
            for t in targets
        ],
    }
    print(json.dumps(out, indent=2, ensure_ascii=False))


def execute_moves(targets: list[ArchiveTarget], docs_root: Path) -> int:
    """git mv 로 실제 이동. 실패 시 fail 카운트 반환."""
    fails = 0
    for t in targets:
        t.target.parent.mkdir(parents=True, exist_ok=True)
        src = str(t.file.relative_to(docs_root.parent))
        tgt = str(t.target.relative_to(docs_root.parent))
        try:
            result = subprocess.run(
                ["git", "mv", src, tgt],
                cwd=docs_root.parent,
                capture_output=True,
                text=True,
                timeout=10,
            )
            if result.returncode != 0:
                print(f"FAIL: {src} → {tgt}: {result.stderr.strip()}", file=sys.stderr)
                fails += 1
        except (subprocess.TimeoutExpired, OSError) as e:
            print(f"ERROR: {src}: {e}", file=sys.stderr)
            fails += 1
    return fails


# ----------------------------------------------------------------------------
# main
# ----------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Phase 2 Aggressive Cleanup — orphan + records + backlog-done archive"
    )
    default_docs = (THIS_DIR.parent / "docs").resolve()
    parser.add_argument("--path", type=Path, default=default_docs)
    parser.add_argument("--dry-run", action="store_true",
                        help="archive 대상만 출력, 실제 이동 안 함 (기본)")
    parser.add_argument("--confirm", action="store_true",
                        help="git mv 실제 실행")
    parser.add_argument("--json", action="store_true",
                        help="JSON 출력 (dry-run 시)")
    parser.add_argument("--target", choices=["records", "backlog", "orphan", "cr", "all"],
                        default="all",
                        help="archive 대상 카테고리 (기본: all)")
    args = parser.parse_args()

    docs_root: Path = args.path.resolve()
    if not docs_root.exists():
        print(f"ERROR: {docs_root} 없음", file=sys.stderr)
        return 2

    if args.target == "all":
        targets = {"records", "backlog", "orphan", "cr"}  # 사용자 결정 (2026-05-13): 전부
    else:
        targets = {args.target}

    archive_list = identify_targets(docs_root, targets)

    if args.json:
        print_json(archive_list, docs_root)
    else:
        print_summary(archive_list, docs_root)

    if args.confirm:
        if not archive_list:
            print("이동 대상 없음. 종료.")
            return 0
        print()
        print(f"실제 git mv 실행 중... (총 {len(archive_list)} 파일)")
        fails = execute_moves(archive_list, docs_root)
        if fails:
            print(f"FAIL: {fails} 파일 이동 실패", file=sys.stderr)
            return 1
        print(f"OK: {len(archive_list)} 파일 archive 완료. `git status` 로 확인 후 commit.")
        return 0

    return 1 if archive_list else 0


if __name__ == "__main__":
    sys.exit(main())
