#!/usr/bin/env python3
"""WSOP LIVE Confluence ↔ EBS v10 디렉토리 정렬 검증.

참조 소스: C:/claude/wsoplive/docs/confluence-mirror/WSOP Live 홈/
EBS 대상: docs/ 홈 레벨 및 2.N 팀 하위번호.

검증 항목:
1. 홈 레벨 N. 이름 패턴 — WSOP LIVE 상위 섹션과 대응 (EBS 고유 divergence 는 justify 주석 허용)
2. 2.N {팀명}/ 하위번호 패턴 — WSOP LIVE 6.N 패턴 준수

CLI:
    python tools/wsop_alignment_check.py

이탈 발견 시 상세 리포트 + exit 1.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS_ROOT = REPO_ROOT / "docs"
WSOPLIVE_ROOT = Path("C:/claude/wsoplive/docs/confluence-mirror")

EXPECTED_HOME_SECTIONS = ["1. Product", "2. Development", "3. Change Requests", "4. Operations"]
ALLOWED_EXTRA_HOME = {"mockups", "images", "_generated", "README.md"}
JUSTIFIED_REMOVALS = {
    "0. EBS Rules": "1. Product/ 로 흡수 (Game Rules + PokerGFX Reference)",
    "4. PokerGFX Reference": "1. Product/References/PokerGFX_Reference.md 단일 파일로 흡수",
    "5. Roadmap": "4. Operations/Roadmap.md 로 통합",
    "9. 회의록": "실제 파일 0개, 필요 시 미래 4. Operations/Meetings/ 로 추가",
}

EXPECTED_DEV_SUBSECTIONS = [
    "2.1 Frontend",
    "2.2 Backend",
    "2.3 Game Engine",
    "2.4 Command Center",
    "2.5 Shared",
]

SECTION_NUM_RE = re.compile(r"^\d+\. .+")
SUBSECTION_NUM_RE = re.compile(r"^\d+\.\d+ .+")


def check_home_level() -> list[str]:
    """홈 레벨 4개 섹션 + 허용 추가 항목만 존재하는지 검증."""
    issues: list[str] = []
    if not DOCS_ROOT.exists():
        issues.append(f"[FATAL] docs/ 디렉토리 없음: {DOCS_ROOT}")
        return issues

    actual = {p.name for p in DOCS_ROOT.iterdir() if not p.name.startswith(".")}

    for expected in EXPECTED_HOME_SECTIONS:
        if expected not in actual:
            issues.append(f"[ISSUE] 홈 레벨 필수 섹션 누락: {expected}")

    for name in actual:
        if name in EXPECTED_HOME_SECTIONS:
            continue
        if name in ALLOWED_EXTRA_HOME:
            continue
        if SECTION_NUM_RE.match(name):
            issues.append(f"[ISSUE] 홈 레벨 알 수 없는 번호 섹션: {name} — layout-v10.md 업데이트 필요")
        elif name.endswith(".md") or (DOCS_ROOT / name).is_file():
            pass
        else:
            issues.append(f"[WARN] 홈 레벨 알 수 없는 폴더: {name}")

    for removed, reason in JUSTIFIED_REMOVALS.items():
        if removed in actual:
            issues.append(f"[ISSUE] 제거되었어야 할 섹션 존재: {removed} — 사유: {reason}")

    return issues


def check_dev_subsections() -> list[str]:
    """2. Development/ 하위 5개 섹션 검증."""
    issues: list[str] = []
    dev = DOCS_ROOT / "2. Development"
    if not dev.exists():
        issues.append(f"[FATAL] 2. Development/ 디렉토리 없음: {dev}")
        return issues
    actual = {p.name for p in dev.iterdir() if p.is_dir()}
    for expected in EXPECTED_DEV_SUBSECTIONS:
        if expected not in actual:
            issues.append(f"[ISSUE] 2. Development/ 필수 하위섹션 누락: {expected}")
    for name in actual:
        if name in EXPECTED_DEV_SUBSECTIONS:
            continue
        if SUBSECTION_NUM_RE.match(name):
            issues.append(f"[ISSUE] 알 수 없는 2.N 서브섹션: {name}")
    return issues


def check_wsoplive_reference() -> list[str]:
    """WSOP LIVE 참조 레포 존재 및 구조 일치 (informational)."""
    issues: list[str] = []
    if not WSOPLIVE_ROOT.exists():
        issues.append(f"[INFO] WSOP LIVE 레포 접근 불가: {WSOPLIVE_ROOT} — 정렬 검증 제한적")
        return issues
    wsop_home = WSOPLIVE_ROOT / "WSOP Live 홈"
    if not wsop_home.exists():
        issues.append(f"[INFO] WSOP Live 홈 폴더 없음 — 참조 레포 구조 변경 가능성")
        return issues
    wsop_sections = [p.name for p in wsop_home.iterdir() if p.is_dir()]
    issues.append(f"[INFO] WSOP LIVE 상위 섹션 {len(wsop_sections)} 개 발견 (참조용)")
    return issues


def main() -> int:
    parser = argparse.ArgumentParser(description="WSOP LIVE ↔ EBS v10 정렬 검증")
    parser.parse_args()

    print("=== WSOP LIVE 정렬 검증 ===")
    all_issues: list[str] = []
    all_issues.extend(check_home_level())
    all_issues.extend(check_dev_subsections())
    all_issues.extend(check_wsoplive_reference())

    errors = [i for i in all_issues if i.startswith("[ISSUE]") or i.startswith("[FATAL]")]
    warnings = [i for i in all_issues if i.startswith("[WARN]")]
    infos = [i for i in all_issues if i.startswith("[INFO]")]

    for msg in errors + warnings + infos:
        print(msg)

    print(f"\n[요약] 에러 {len(errors)} / 경고 {len(warnings)} / 참조 {len(infos)}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
