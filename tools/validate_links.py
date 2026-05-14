#!/usr/bin/env python3
"""마크다운 상대 링크 무결성 검증.

docs/**/*.md, team{N}-*/README.md 의 마크다운 링크 `[text](relative/path)` 를 추출하여
실제 파일 존재 여부를 확인. 깨진 링크 발견 시 exit 1.

CLI:
    python tools/validate_links.py                  # 전체 스코프
    python tools/validate_links.py --scope=conductor
    python tools/validate_links.py --scope=team1

pre-commit / CI 양쪽에서 사용.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from urllib.parse import unquote

REPO_ROOT = Path(__file__).resolve().parent.parent

LINK_PATTERN = re.compile(r"\[([^\]]*)\]\(([^)]+)\)")
INLINE_CODE_PATTERN = re.compile(r"`[^`]*`")

LINK_EXCLUDE_DIRS = {"archive", "_archive", "References"}


def is_link_excluded(path: Path) -> bool:
    """링크 검증 제외 대상.

    제외:
    - archive/ 또는 _archive/ — 역사 기록, 자산 stale 허용
    - References/ — 외부 PRD/UI 역설계 자료 (PokerGFX 등). 자산 일부는 별도 레포 (ebs_reverse) 또는 외부 mockup 폴더에 위치
    """
    return any(part in LINK_EXCLUDE_DIRS for part in path.parts)


def scope_paths(scope: str) -> list[Path]:
    """스코프 별 스캔 대상 파일 리스트."""
    if scope == "all":
        targets: list[Path] = []
        docs = REPO_ROOT / "docs"
        if docs.exists():
            for p in docs.rglob("*.md"):
                if "_generated" in p.parts:
                    continue
                targets.append(p)
        for team_dir in REPO_ROOT.glob("team*-*"):
            readme = team_dir / "README.md"
            if readme.exists():
                targets.append(readme)
        return targets
    if scope == "conductor":
        base = REPO_ROOT / "docs"
        return [p for p in base.rglob("*.md") if "_generated" not in p.parts]
    if scope.startswith("team"):
        team_num = scope[4:]
        team_dirs = list(REPO_ROOT.glob(f"team{team_num}-*"))
        targets = []
        for td in team_dirs:
            targets.extend(td.rglob("*.md"))
        dev_dir = REPO_ROOT / "docs" / "2. Development"
        if dev_dir.exists():
            for sub in dev_dir.glob(f"2.{team_num} */"):
                targets.extend(sub.rglob("*.md"))
        return targets
    return []


def extract_links(path: Path) -> list[tuple[int, str, str]]:
    """파일에서 (라인 번호, 앵커 텍스트, URL) 추출. fenced code block 내부는 스킵."""
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return []
    out = []
    in_fence = False
    for lineno, line in enumerate(text.splitlines(), 1):
        stripped = line.lstrip()
        if stripped.startswith("```") or stripped.startswith("~~~"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        scrubbed = INLINE_CODE_PATTERN.sub("", line)
        for match in LINK_PATTERN.finditer(scrubbed):
            out.append((lineno, match.group(1), match.group(2)))
    return out


def is_external(url: str) -> bool:
    """외부 링크 / 앵커 / 메일은 검증 스킵."""
    return url.startswith(("http://", "https://", "#", "mailto:", "ftp://"))


def resolve_target(source: Path, url: str) -> Path:
    """상대 URL 을 대상 Path 로 해석."""
    clean = unquote(url.split("#")[0].split("?")[0])
    if not clean:
        return source
    if clean.startswith("/"):
        return REPO_ROOT / clean.lstrip("/")
    return (source.parent / clean).resolve()


def main() -> int:
    parser = argparse.ArgumentParser(description="마크다운 상대 링크 무결성 검증")
    parser.add_argument(
        "--scope",
        default="all",
        help="all | conductor | team1 | team2 | team3 | team4",
    )
    args = parser.parse_args()

    targets = scope_paths(args.scope)
    print(f"[스캔] scope={args.scope} — {len(targets)} 파일")

    broken: list[tuple[Path, int, str, str]] = []
    total_links = 0
    skipped_archive = 0
    for src in targets:
        if is_link_excluded(src):
            skipped_archive += 1
            continue
        links = extract_links(src)
        total_links += len(links)
        for lineno, text, url in links:
            if is_external(url):
                continue
            target = resolve_target(src, url)
            if not target.exists():
                broken.append((src, lineno, text, url))

    print(f"[결과] 링크 {total_links} 개 중 깨진 것 {len(broken)} 개 (archive 스킵 {skipped_archive} 파일)")
    if broken:
        print("\n[깨진 링크]")
        for src, lineno, text, url in broken[:50]:
            rel = src.relative_to(REPO_ROOT).as_posix()
            print(f"  {rel}:{lineno} → [{text}]({url})")
        if len(broken) > 50:
            print(f"  ... (+{len(broken) - 50} more)")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
