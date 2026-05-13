#!/usr/bin/env python3
"""
ssot_verify.py — EBS 문서 SSOT 일관성 검증 도구

3가지 자동 검증:
  1. derivative-of 체인     : docs/*.md frontmatter 의 derivative-of 가
                              실제 존재하는 파일을 가리키는지 확인
  2. Confluence page-id     : docs/1. Product/ 주요 문서가 confluence-page-id
                              필드를 가지며 숫자값인지 확인
  3. llms.txt 커버리지       : docs/llms.txt 가 docs/1. Product/ 의 주요
                              파일명을 모두 포함하는지 확인

사용:
    python tools/ssot_verify.py
    python tools/ssot_verify.py --path C:/claude/ebs/docs

Exit:
    0 — 모든 검증 PASS
    1 — 하나라도 FAIL
"""

from __future__ import annotations

import argparse
import datetime as dt
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

try:
    import yaml  # type: ignore
except ImportError:
    print("ERROR: PyYAML 미설치. pip install pyyaml 실행 필요.", file=sys.stderr)
    sys.exit(2)


# ----------------------------------------------------------------------------
# 검증 대상 정의 (docs/1. Product/ 기준)
# ----------------------------------------------------------------------------

# Confluence page-id 필수 파일 (Product 폴더 루트)
PRODUCT_ROOT_FILES = (
    "Foundation.md",
    "Lobby.md",
    "Command_Center.md",
    "Back_Office.md",
    "RIVE_Standards.md",
    "Product_SSOT_Policy.md",
)

# Game_Rules 하위 검증 파일 (archive/ 제외)
GAME_RULES_FILES = (
    "Flop_Games.md",
    "Draw.md",
    "Seven_Card_Games.md",
    "Betting_System.md",
)

FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)


# ----------------------------------------------------------------------------
# 데이터 클래스
# ----------------------------------------------------------------------------

@dataclass
class DerivCheck:
    file: Path
    derivative_of: str
    resolved: Path
    exists: bool


@dataclass
class ConfluenceCheck:
    file: Path
    page_id: Optional[str]
    is_numeric: bool


@dataclass
class CoverageCheck:
    file: Path
    relative_name: str
    covered: bool


# ----------------------------------------------------------------------------
# Frontmatter 파싱
# ----------------------------------------------------------------------------

def read_frontmatter(path: Path) -> Optional[dict]:
    """파일의 frontmatter(YAML)를 dict 로 반환. 없거나 파싱 실패 시 None."""
    try:
        text = path.read_text(encoding="utf-8-sig")
    except OSError:
        return None

    match = FRONTMATTER_RE.match(text)
    if not match:
        return None

    raw = match.group(1)
    try:
        data = yaml.safe_load(raw)
    except yaml.YAMLError:
        return None

    return data if isinstance(data, dict) else None


# ----------------------------------------------------------------------------
# 검증 1: derivative-of
# ----------------------------------------------------------------------------

def check_derivative_chain(docs_root: Path) -> list[DerivCheck]:
    """docs/ 하위 모든 .md 의 derivative-of 검증."""
    results: list[DerivCheck] = []

    for md in sorted(docs_root.rglob("*.md")):
        # _generated, _archive, _journey, archive 폴더 제외
        rel_parts = md.relative_to(docs_root).parts
        if any(p.startswith("_") or p == "archive" for p in rel_parts):
            continue

        fm = read_frontmatter(md)
        if not fm:
            continue

        deriv = fm.get("derivative-of")
        if not deriv:
            continue

        # 파일 기준 상대 경로로 해석
        deriv_path = (md.parent / str(deriv)).resolve()
        results.append(
            DerivCheck(
                file=md,
                derivative_of=str(deriv),
                resolved=deriv_path,
                exists=deriv_path.exists(),
            )
        )

    return results


# ----------------------------------------------------------------------------
# 검증 2: confluence-page-id
# ----------------------------------------------------------------------------

def check_confluence_ids(product_root: Path) -> list[ConfluenceCheck]:
    """docs/1. Product/ 주요 파일의 confluence-page-id 검증."""
    results: list[ConfluenceCheck] = []

    targets: list[Path] = []
    for name in PRODUCT_ROOT_FILES:
        targets.append(product_root / name)
    for name in GAME_RULES_FILES:
        targets.append(product_root / "Game_Rules" / name)

    for path in targets:
        if not path.exists():
            results.append(
                ConfluenceCheck(file=path, page_id=None, is_numeric=False)
            )
            continue

        fm = read_frontmatter(path) or {}
        page_id = fm.get("confluence-page-id")
        page_id_str = str(page_id) if page_id is not None else None
        is_numeric = bool(page_id_str and page_id_str.isdigit())

        results.append(
            ConfluenceCheck(file=path, page_id=page_id_str, is_numeric=is_numeric)
        )

    return results


# ----------------------------------------------------------------------------
# 검증 3: llms.txt coverage
# ----------------------------------------------------------------------------

def check_llms_coverage(docs_root: Path, product_root: Path) -> tuple[bool, list[CoverageCheck]]:
    """docs/llms.txt 존재 + docs/1. Product/ 의 주요 파일 포함 여부."""
    llms_path = docs_root / "llms.txt"
    results: list[CoverageCheck] = []

    if not llms_path.exists():
        return False, results

    llms_text = llms_path.read_text(encoding="utf-8-sig")

    # docs/1. Product/*.md (archive 제외) + Game_Rules/*.md
    targets: list[Path] = []
    for md in sorted(product_root.glob("*.md")):
        targets.append(md)
    game_rules = product_root / "Game_Rules"
    if game_rules.exists():
        for md in sorted(game_rules.glob("*.md")):
            targets.append(md)

    for path in targets:
        # 'archive' 경로 제외
        if "archive" in path.relative_to(docs_root).parts:
            continue

        # 파일명 단독 검사 (llms.txt 가 파일명 또는 상대 경로 어느 형식이든 매칭)
        covered = path.name in llms_text
        results.append(
            CoverageCheck(
                file=path,
                relative_name=str(path.relative_to(docs_root)).replace("\\", "/"),
                covered=covered,
            )
        )

    return True, results


# ----------------------------------------------------------------------------
# 출력 포매팅
# ----------------------------------------------------------------------------

def _fmt_row(cols: list[str], widths: list[int]) -> str:
    parts = []
    for c, w in zip(cols, widths):
        parts.append(c.ljust(w))
    return " | ".join(parts)


def _print_section_header(num: int, title: str) -> None:
    print()
    print(f"[{num}] {title}")
    print("-" * 80)


def print_derivative_table(rows: list[DerivCheck], docs_root: Path) -> int:
    """derivative-of 표 출력. fail 개수 반환."""
    widths = [38, 50, 12]
    print(_fmt_row(["File", "derivative-of", "Status"], widths))
    fails = 0

    for r in rows:
        file_short = str(r.file.relative_to(docs_root)).replace("\\", "/")
        if len(file_short) > widths[0]:
            file_short = "..." + file_short[-(widths[0] - 3):]

        deriv_short = r.derivative_of
        if len(deriv_short) > widths[1]:
            deriv_short = "..." + deriv_short[-(widths[1] - 3):]

        status = "EXISTS" if r.exists else "MISSING"
        if not r.exists:
            fails += 1

        print(_fmt_row([file_short, deriv_short, status], widths))

    return fails


def print_confluence_table(rows: list[ConfluenceCheck], docs_root: Path) -> int:
    widths = [38, 20, 10]
    print(_fmt_row(["File", "confluence-page-id", "Status"], widths))
    fails = 0

    for r in rows:
        try:
            file_short = str(r.file.relative_to(docs_root)).replace("\\", "/")
        except ValueError:
            file_short = r.file.name
        if len(file_short) > widths[0]:
            file_short = "..." + file_short[-(widths[0] - 3):]

        page_id = r.page_id if r.page_id is not None else "MISSING"
        ok = r.is_numeric
        if not ok:
            fails += 1

        status = "OK" if ok else "FAIL"
        print(_fmt_row([file_short, page_id, status], widths))

    return fails


def print_coverage_table(rows: list[CoverageCheck]) -> int:
    widths = [50, 12]
    print(_fmt_row(["File", "Status"], widths))
    fails = 0

    for r in rows:
        name = r.relative_name
        if len(name) > widths[0]:
            name = "..." + name[-(widths[0] - 3):]
        status = "COVERED" if r.covered else "MISSING"
        if not r.covered:
            fails += 1
        print(_fmt_row([name, status], widths))

    return fails


# ----------------------------------------------------------------------------
# main
# ----------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        description="EBS 문서 SSOT 일관성 검증 (derivative-of / Confluence ID / llms.txt)"
    )
    default_docs = (Path(__file__).resolve().parent.parent / "docs").resolve()
    parser.add_argument(
        "--path",
        type=Path,
        default=default_docs,
        help=f"docs 루트 경로 (기본: {default_docs})",
    )
    args = parser.parse_args()

    docs_root: Path = args.path.resolve()
    if not docs_root.exists() or not docs_root.is_dir():
        print(f"ERROR: docs 루트가 존재하지 않습니다: {docs_root}", file=sys.stderr)
        return 2

    product_root = docs_root / "1. Product"
    if not product_root.exists():
        print(f"ERROR: '1. Product' 폴더가 없습니다: {product_root}", file=sys.stderr)
        return 2

    timestamp = dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print("=== EBS SSOT Verification ===")
    print(f"Timestamp: {timestamp}")
    print(f"Docs Root: {docs_root}")

    # [1] derivative-of
    _print_section_header(1, "derivative-of Chain Verification")
    deriv_rows = check_derivative_chain(docs_root)
    deriv_fails = print_derivative_table(deriv_rows, docs_root)
    deriv_total = len(deriv_rows)
    deriv_pass = deriv_total - deriv_fails

    # [2] confluence-page-id
    _print_section_header(2, "Confluence page-id Verification (docs/1. Product/)")
    conf_rows = check_confluence_ids(product_root)
    conf_fails = print_confluence_table(conf_rows, docs_root)
    conf_total = len(conf_rows)
    conf_pass = conf_total - conf_fails

    # [3] llms.txt coverage
    _print_section_header(3, "llms.txt Coverage Verification")
    llms_exists, cov_rows = check_llms_coverage(docs_root, product_root)
    if not llms_exists:
        print("FAIL: docs/llms.txt 파일이 존재하지 않습니다.")
        cov_fails = 1
        cov_total = 1
        cov_pass = 0
    else:
        cov_fails = print_coverage_table(cov_rows)
        cov_total = len(cov_rows)
        cov_pass = cov_total - cov_fails

    # Summary
    print()
    print("=== Summary ===")
    deriv_mark = "OK" if deriv_fails == 0 else "FAIL"
    conf_mark = "OK" if conf_fails == 0 else "FAIL"
    cov_mark = "OK" if cov_fails == 0 else "FAIL"
    print(
        f"derivative-of: {deriv_pass}/{deriv_total} {deriv_mark}  |  "
        f"Confluence ID: {conf_pass}/{conf_total} {conf_mark}  |  "
        f"llms.txt: {cov_pass}/{cov_total} {cov_mark}"
    )

    overall_fail = deriv_fails + conf_fails + cov_fails
    overall = "PASS" if overall_fail == 0 else "FAIL"
    print(f"OVERALL: {overall}")

    return 0 if overall_fail == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
