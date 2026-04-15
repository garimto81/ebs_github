#!/usr/bin/env python3
"""문서 재설계 v10 마이그레이션 스크립트.

path-mapping.csv 를 입력으로 받아 Phase 2 (Conductor 영역) 또는 Phase 3 (팀별 영역)
파일을 git mv 로 이동하고, frontmatter 주입/갱신과 상대 링크 자동 치환을 수행한다.

사용 예:
    python tools/migrate_docs_v10.py --phase=2 --dry-run
    python tools/migrate_docs_v10.py --phase=3 --team=team1
    python tools/migrate_docs_v10.py --phase=3 --team=team2

안전장치:
    - git status --porcelain 이 clean 이 아니면 중단 (충돌 방지)
    - --dry-run 모드에서는 실제 이동 없이 계획만 출력
    - 파일 미존재 시 WARNING 으로 건너뜀 (중단 아님)
"""
from __future__ import annotations

import argparse
import csv
import re
import subprocess
import sys
from pathlib import Path
from typing import Iterable

REPO_ROOT = Path(__file__).resolve().parent.parent
MAPPING_CSV = REPO_ROOT / "contracts" / "migration" / "path-mapping.csv"

FRONTMATTER_FENCE = "---"


def run_git(args: list[str], check: bool = True) -> subprocess.CompletedProcess[str]:
    """git 명령 실행. 공백 포함 경로 안전."""
    return subprocess.run(
        ["git", *args],
        cwd=REPO_ROOT,
        check=check,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )


def assert_clean_tree() -> None:
    """작업 트리가 clean 인지 확인. dirty 면 중단."""
    result = run_git(["status", "--porcelain"], check=False)
    if result.stdout.strip():
        print("[FATAL] git 작업 트리가 clean 이 아닙니다. 먼저 커밋 또는 stash 하세요.", file=sys.stderr)
        print(result.stdout, file=sys.stderr)
        sys.exit(2)


def load_mapping(csv_path: Path) -> list[dict[str, str]]:
    """path-mapping.csv 를 로드."""
    if not csv_path.exists():
        print(f"[FATAL] 매핑 파일 미존재: {csv_path}", file=sys.stderr)
        sys.exit(2)
    with csv_path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        return list(reader)


def filter_rows(
    rows: list[dict[str, str]],
    phase: str,
    team: str | None,
) -> list[dict[str, str]]:
    """Phase / team 기준으로 필터링."""
    out = []
    for row in rows:
        if row["phase"] != phase:
            continue
        if team and row["owner"] != team:
            continue
        if row["old_path"] == row["new_path"]:
            continue
        out.append(row)
    return out


def split_frontmatter(text: str) -> tuple[dict[str, str], str]:
    """마크다운 텍스트에서 frontmatter 블록을 추출. 없으면 빈 dict."""
    if not text.startswith(FRONTMATTER_FENCE):
        return {}, text
    lines = text.splitlines(keepends=True)
    if len(lines) < 2:
        return {}, text
    end_idx = None
    for i in range(1, len(lines)):
        if lines[i].rstrip() == FRONTMATTER_FENCE:
            end_idx = i
            break
    if end_idx is None:
        return {}, text
    fm_lines = lines[1:end_idx]
    body = "".join(lines[end_idx + 1 :])
    fm: dict[str, str] = {}
    for line in fm_lines:
        if ":" in line:
            key, _, value = line.partition(":")
            fm[key.strip()] = value.strip()
    return fm, body


def render_frontmatter(fm: dict[str, str]) -> str:
    """dict 를 frontmatter 블록 문자열로 직렬화."""
    body = "\n".join(f"{k}: {v}" for k, v in fm.items())
    return f"{FRONTMATTER_FENCE}\n{body}\n{FRONTMATTER_FENCE}\n"


def derive_legacy_id(old_path: str) -> str | None:
    """old_path 파일명에서 legacy ID 추출 (BS-02-01, API-04 등)."""
    stem = Path(old_path).stem
    patterns = [
        r"(BS-\d{2}-\d{2})",
        r"(BS-\d{2}-\d[A-Z])",
        r"(API-\d{2})",
        r"(DATA-\d{2})",
        r"(IMPL-\d{2})",
        r"(BO-\d{2})",
        r"(PRD-GAME-\d{2})",
        r"(CCR-\d{3})",
        r"(UI-\d{2})",
    ]
    for pat in patterns:
        m = re.search(pat, stem)
        if m:
            return m.group(1)
    return None


def inject_frontmatter(
    file_path: Path, owner: str, legacy_id: str | None, title_hint: str
) -> None:
    """파일에 frontmatter 주입 또는 기존 frontmatter 필드 업데이트."""
    if not file_path.exists() or not file_path.suffix == ".md":
        return
    text = file_path.read_text(encoding="utf-8")
    fm, body = split_frontmatter(text)
    fm.setdefault("title", title_hint)
    fm["owner"] = owner
    fm.setdefault("tier", "internal")
    if legacy_id:
        fm["legacy-id"] = legacy_id
    fm["last-updated"] = "2026-04-15"
    new_text = render_frontmatter(fm) + body if body.startswith("\n") else render_frontmatter(fm) + "\n" + body.lstrip("\n")
    file_path.write_text(new_text, encoding="utf-8")


def pascal_snake_from_hint(new_path: str) -> str:
    """new_path 의 파일명(확장자 제외) 에서 공백을 _ 로 변환한 title hint."""
    stem = Path(new_path).stem
    return stem.replace("_", " ")


def rewrite_relative_links(file_path: Path, old_to_new: dict[str, str]) -> int:
    """파일 내부 마크다운 상대 링크를 new_path 로 치환. 변경 횟수 반환."""
    if not file_path.exists() or file_path.suffix != ".md":
        return 0
    text = file_path.read_text(encoding="utf-8")
    original = text
    link_pattern = re.compile(r"\]\(([^)]+)\)")
    count = 0

    def replace(match: re.Match[str]) -> str:
        nonlocal count
        url = match.group(1)
        if url.startswith(("http://", "https://", "#", "mailto:")):
            return match.group(0)
        for old, new in old_to_new.items():
            old_norm = old.replace("\\", "/")
            if old_norm in url:
                count += 1
                return match.group(0).replace(old_norm, new.replace("\\", "/"))
        return match.group(0)

    text = link_pattern.sub(replace, text)
    if text != original:
        file_path.write_text(text, encoding="utf-8")
    return count


def git_mv(src: Path, dst: Path, dry_run: bool) -> bool:
    """git mv 실행. 성공 True, 실패 False."""
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dry_run:
        print(f"  [DRY] git mv '{src.relative_to(REPO_ROOT)}' '{dst.relative_to(REPO_ROOT)}'")
        return True
    try:
        run_git(["mv", str(src), str(dst)])
        return True
    except subprocess.CalledProcessError as e:
        print(f"  [ERR] git mv 실패: {src} → {dst}\n    {e.stderr}", file=sys.stderr)
        return False


def main() -> int:
    parser = argparse.ArgumentParser(description="v10 문서 마이그레이션 스크립트")
    parser.add_argument("--phase", choices=["2", "3"], required=True, help="Phase 번호")
    parser.add_argument(
        "--team",
        choices=["conductor", "team1", "team2", "team3", "team4"],
        default=None,
        help="Phase 3 에서만 사용 (팀 필터)",
    )
    parser.add_argument("--dry-run", action="store_true", help="실제 이동 없이 계획만 출력")
    parser.add_argument(
        "--skip-clean-check",
        action="store_true",
        help="git clean 검사 생략 (위험, 테스트용)",
    )
    args = parser.parse_args()

    print(f"=== 마이그레이션 Phase {args.phase}" + (f" team={args.team}" if args.team else "") + " ===")
    if args.dry_run:
        print("[모드] DRY-RUN (실제 이동 없음)")

    if not args.dry_run and not args.skip_clean_check:
        assert_clean_tree()

    rows = load_mapping(MAPPING_CSV)
    filtered = filter_rows(rows, args.phase, args.team)
    print(f"[집계] 총 {len(rows)} 행 중 {len(filtered)} 행 매칭")

    if not filtered:
        print("[종료] 처리할 항목 없음.")
        return 0

    old_to_new: dict[str, str] = {r["old_path"]: r["new_path"] for r in filtered}

    success = 0
    skipped = 0
    failed = 0
    moved_files: list[tuple[Path, dict[str, str]]] = []

    for row in filtered:
        old = REPO_ROOT / row["old_path"].replace("/", "\\") if sys.platform == "win32" else REPO_ROOT / row["old_path"]
        old = REPO_ROOT / row["old_path"]
        new = REPO_ROOT / row["new_path"]

        if not old.exists():
            print(f"[SKIP] 원본 미존재: {row['old_path']}")
            skipped += 1
            continue

        if new.exists():
            print(f"[SKIP] 대상 이미 존재: {row['new_path']} (머지 필요)")
            skipped += 1
            continue

        ok = git_mv(old, new, args.dry_run)
        if ok:
            success += 1
            moved_files.append((new, row))
        else:
            failed += 1

    if not args.dry_run:
        print("\n=== frontmatter 주입 + 링크 치환 ===")
        for new_path, row in moved_files:
            title_hint = pascal_snake_from_hint(row["new_path"])
            legacy_id = derive_legacy_id(row["old_path"])
            inject_frontmatter(new_path, row["owner"], legacy_id, title_hint)

        link_updates = 0
        for new_path, _ in moved_files:
            link_updates += rewrite_relative_links(new_path, old_to_new)
        print(f"  frontmatter 주입: {len(moved_files)} 파일")
        print(f"  링크 치환: {link_updates} 건")

    print("\n=== 요약 ===")
    print(f"  성공: {success}")
    print(f"  건너뜀: {skipped}")
    print(f"  실패: {failed}")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
