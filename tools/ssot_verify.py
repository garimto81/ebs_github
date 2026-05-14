#!/usr/bin/env python3
"""
ssot_verify.py v2 — EBS 문서 SSOT 일관성 + 9 카테고리 검증 도구

9가지 자동 검증:
  [1] derivative-of 체인     : 모든 .md 의 derivative-of 가 실제 파일을 가리키는지
  [2] Confluence page-id     : docs/1. Product/ 주요 문서가 numeric page-id 보유
  [3] llms.txt 커버리지       : docs/llms.txt 가 모든 Product 파일을 언급
  [4] Category Distribution  : 9 카테고리별 파일 분포 (informational)
  [5] Tier 누락               : frontmatter tier: 필드 없는 파일 검출
  [6] Backlog status 완전성  : B-*.md / SG-*.md 가 backlog-status 보유
  [7] CR-NNN impact 매핑     : CR-*.md 가 impacts 필드 보유
  [8] Contract derivative-of : tier:contract 파일이 derivative-of/related-spec 보유
  [9] Internal spec owner    : tier:internal 파일이 owner/stream 필드 보유

사용:
    python tools/ssot_verify.py
    python tools/ssot_verify.py --path C:/claude/ebs/docs
    python tools/ssot_verify.py --orphan        # orphan 노드 검출만
    python tools/ssot_verify.py --strict-tier   # tier 누락이 있으면 FAIL

Exit:
    0 — 모든 검증 PASS
    1 — 하나라도 FAIL
    2 — 도구 오류
"""

from __future__ import annotations

import argparse
import datetime as dt
import re
import sys
from dataclasses import dataclass, field
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

PRODUCT_ROOT_FILES = (
    "Foundation.md",
    "Lobby.md",
    "Command_Center.md",
    "Back_Office.md",
    "RIVE_Standards.md",
    # Product_SSOT_Policy.md → docs/_meta/ 이동 (PR #474)
)

GAME_RULES_FILES = (
    "Flop_Games.md",
    "Draw.md",
    "Seven_Card_Games.md",
    "Betting_System.md",
)

FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)

# 9 카테고리 분류 룰 (Product_SSOT_Policy.md §9.1 참조)
# 우선순위: 상위 카테고리부터 매칭 (A → I)
CATEGORY_DEFS = {
    "A": "SSOT 정본 (Product PRD + Dev Overview)",
    "B": "Contract spec",
    "C": "Change Request (CR-NNN)",
    "D": "Backlog 항목 (B-NNN, SG-NNN)",
    "E": "Operations 기록 (Cycle/Critic/Audit)",
    "F": "Internal spec",
    "G": "Generated",
    "H": "Archive (변경 금지)",
    "I": "Tier 누락",
}

# A 카테고리: SSOT 정본 파일명 (정확히 일치)
A_FILES = set(PRODUCT_ROOT_FILES) | set(GAME_RULES_FILES) | {
    "Overview.md",  # DEV-01~04 + Shared
}

# E 카테고리: Operations 기록 패턴 (정규식)
E_PATTERNS = [
    re.compile(r"Cycle_?\d+", re.IGNORECASE),
    re.compile(r"_Critic_", re.IGNORECASE),
    re.compile(r"_Audit_", re.IGNORECASE),
    re.compile(r"Conductor_Backlog/done/", re.IGNORECASE),
    re.compile(r"Critic_Reports/", re.IGNORECASE),
]


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


@dataclass
class CategoryStats:
    counts: dict[str, int] = field(default_factory=dict)
    files_by_cat: dict[str, list[Path]] = field(default_factory=dict)
    total: int = 0


@dataclass
class TierCheck:
    file: Path
    tier: Optional[str]


@dataclass
class BacklogCheck:
    file: Path
    status: Optional[str]
    close_date: Optional[str]
    is_valid: bool


@dataclass
class CRImpactCheck:
    file: Path
    impacts: Optional[list]
    status: Optional[str]


@dataclass
class ContractDerivCheck:
    file: Path
    has_link: bool  # derivative-of OR related-spec OR references


@dataclass
class InternalOwnerCheck:
    file: Path
    owner: Optional[str]
    stream: Optional[str]


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


def iter_docs(docs_root: Path, skip_archive: bool = True):
    """docs/ 하위 .md 파일 iterator. _generated, _archive, _journey, archive 제외 옵션."""
    for md in sorted(docs_root.rglob("*.md")):
        rel_parts = md.relative_to(docs_root).parts
        if skip_archive and any(
            p.startswith("_") or p == "archive" for p in rel_parts
        ):
            continue
        yield md


# ----------------------------------------------------------------------------
# 카테고리 분류 (9 카테고리)
# ----------------------------------------------------------------------------

def classify_file(md: Path, docs_root: Path, fm: Optional[dict]) -> str:
    """파일을 9 카테고리(A~I) 중 하나로 분류."""
    rel = md.relative_to(docs_root)
    rel_str = str(rel).replace("\\", "/")
    parts = rel.parts
    name = md.name
    tier = (fm or {}).get("tier", "")

    # H: Archive (변경 금지)
    if any(p.startswith("_") for p in parts) or "archive" in parts:
        return "H"
    if tier in ("deprecated", "frozen", "archive"):
        return "H"

    # G: Generated (CI auto)
    if tier == "generated":
        return "G"
    # landing index 파일
    if name in ("1. Product.md", "2. Development.md", "3. Change Requests.md",
                "4. Operations.md") or rel_str.endswith("_generated/full-index.md"):
        return "G"

    # A: SSOT 정본 (Product PRD + Dev Overview)
    if parts[0] == "1. Product" and name in A_FILES:
        return "A"
    if (parts[0] == "2. Development" and name == "Overview.md"):
        return "A"

    # B: Contract spec
    if tier == "contract":
        return "B"

    # C: Change Request (CR-NNN)
    if parts[0] == "3. Change Requests" and name.startswith("CR-"):
        return "C"

    # D: Backlog 항목 (B-NNN, SG-NNN)
    if "Backlog" in parts and (name.startswith("B-") or name.startswith("SG-")):
        return "D"

    # E: Operations 기록 (Cycle/Critic/Audit/Conductor_Backlog done)
    if parts[0] == "4. Operations":
        for pat in E_PATTERNS:
            if pat.search(rel_str):
                return "E"
        if tier in ("operations", "audit", "log"):
            return "E"

    # I: Tier 누락
    if not tier:
        return "I"

    # F: Internal spec (그 외 tier 있는 파일)
    return "F"


# ----------------------------------------------------------------------------
# 검증 1: derivative-of
# ----------------------------------------------------------------------------

def check_derivative_chain(docs_root: Path) -> list[DerivCheck]:
    """docs/ 하위 모든 .md 의 derivative-of 검증."""
    results: list[DerivCheck] = []
    for md in iter_docs(docs_root):
        fm = read_frontmatter(md)
        if not fm:
            continue
        deriv = fm.get("derivative-of")
        if not deriv:
            continue
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
    results: list[ConfluenceCheck] = []
    targets: list[Path] = []
    for n in PRODUCT_ROOT_FILES:
        targets.append(product_root / n)
    for n in GAME_RULES_FILES:
        targets.append(product_root / "Game_Rules" / n)

    for path in targets:
        if not path.exists():
            results.append(ConfluenceCheck(file=path, page_id=None, is_numeric=False))
            continue
        fm = read_frontmatter(path) or {}
        page_id = fm.get("confluence-page-id")
        page_id_str = str(page_id) if page_id is not None else None
        is_numeric = bool(page_id_str and page_id_str.isdigit())
        results.append(ConfluenceCheck(file=path, page_id=page_id_str, is_numeric=is_numeric))
    return results


# ----------------------------------------------------------------------------
# 검증 3: llms.txt coverage
# ----------------------------------------------------------------------------

def check_llms_coverage(docs_root: Path, product_root: Path) -> tuple[bool, list[CoverageCheck]]:
    llms_path = docs_root / "llms.txt"
    results: list[CoverageCheck] = []
    if not llms_path.exists():
        return False, results
    llms_text = llms_path.read_text(encoding="utf-8-sig")

    targets: list[Path] = []
    for md in sorted(product_root.glob("*.md")):
        targets.append(md)
    game_rules = product_root / "Game_Rules"
    if game_rules.exists():
        for md in sorted(game_rules.glob("*.md")):
            targets.append(md)

    for path in targets:
        if "archive" in path.relative_to(docs_root).parts:
            continue
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
# 검증 4: 카테고리 분포
# ----------------------------------------------------------------------------

def check_category_distribution(docs_root: Path) -> CategoryStats:
    stats = CategoryStats()
    for cat in CATEGORY_DEFS:
        stats.counts[cat] = 0
        stats.files_by_cat[cat] = []
    for md in iter_docs(docs_root, skip_archive=False):
        fm = read_frontmatter(md)
        cat = classify_file(md, docs_root, fm)
        stats.counts[cat] += 1
        stats.files_by_cat[cat].append(md)
        stats.total += 1
    return stats


# ----------------------------------------------------------------------------
# 검증 5: Tier 누락
# ----------------------------------------------------------------------------

def check_tier_missing(docs_root: Path, cat_stats: CategoryStats) -> list[TierCheck]:
    """카테고리 I (Tier 누락) 파일 목록."""
    results: list[TierCheck] = []
    for md in cat_stats.files_by_cat["I"]:
        fm = read_frontmatter(md) or {}
        results.append(TierCheck(file=md, tier=fm.get("tier")))
    return results


# ----------------------------------------------------------------------------
# 검증 6: Backlog status (D)
# ----------------------------------------------------------------------------

def check_backlog_status(docs_root: Path, cat_stats: CategoryStats) -> list[BacklogCheck]:
    """D 카테고리 파일의 backlog-status + close-date 검증."""
    results: list[BacklogCheck] = []
    for md in cat_stats.files_by_cat["D"]:
        fm = read_frontmatter(md) or {}
        status = fm.get("backlog-status") or fm.get("status")
        close_date = fm.get("close-date")
        # done 인 경우 close-date 필수
        if status in ("done", "abandoned"):
            is_valid = close_date is not None
        else:
            is_valid = status in ("open", "in-progress", "in_progress", "blocked", None)
        results.append(BacklogCheck(
            file=md,
            status=str(status) if status else None,
            close_date=str(close_date) if close_date else None,
            is_valid=is_valid,
        ))
    return results


# ----------------------------------------------------------------------------
# 검증 7: CR-NNN impact 매핑 (C)
# ----------------------------------------------------------------------------

def check_cr_impacts(docs_root: Path, cat_stats: CategoryStats) -> list[CRImpactCheck]:
    """C 카테고리(CR-NNN) 의 impacts 필드 검증."""
    results: list[CRImpactCheck] = []
    for md in cat_stats.files_by_cat["C"]:
        fm = read_frontmatter(md) or {}
        impacts = fm.get("impacts")
        status = fm.get("status")
        results.append(CRImpactCheck(
            file=md,
            impacts=impacts if isinstance(impacts, list) else None,
            status=str(status) if status else None,
        ))
    return results


# ----------------------------------------------------------------------------
# 검증 8: Contract derivative-of (B)
# ----------------------------------------------------------------------------

def check_contract_derivative(docs_root: Path, cat_stats: CategoryStats) -> list[ContractDerivCheck]:
    """B 카테고리(Contract) 의 derivative-of / related-spec / related / references 검증."""
    results: list[ContractDerivCheck] = []
    for md in cat_stats.files_by_cat["B"]:
        fm = read_frontmatter(md) or {}
        has_link = bool(
            fm.get("derivative-of")
            or fm.get("related-spec")
            or fm.get("references")
            or fm.get("related")
        )
        results.append(ContractDerivCheck(file=md, has_link=has_link))
    return results


# ----------------------------------------------------------------------------
# 검증 9: Internal spec owner (F)
# ----------------------------------------------------------------------------

def check_internal_owner(docs_root: Path, cat_stats: CategoryStats) -> list[InternalOwnerCheck]:
    """F 카테고리(Internal spec) 의 owner / stream 필드 검증."""
    results: list[InternalOwnerCheck] = []
    for md in cat_stats.files_by_cat["F"]:
        fm = read_frontmatter(md) or {}
        owner = fm.get("owner")
        stream = fm.get("stream")
        results.append(InternalOwnerCheck(
            file=md,
            owner=str(owner) if owner else None,
            stream=str(stream) if stream else None,
        ))
    return results


# ----------------------------------------------------------------------------
# 출력 포매팅 (공통)
# ----------------------------------------------------------------------------

def _fmt_row(cols: list[str], widths: list[int]) -> str:
    parts = [c.ljust(w) for c, w in zip(cols, widths)]
    return " | ".join(parts)


def _print_section_header(num: int, title: str) -> None:
    print()
    print(f"[{num}] {title}")
    print("-" * 80)


def _shorten(s: str, w: int) -> str:
    if len(s) > w:
        return "..." + s[-(w - 3):]
    return s


def print_derivative_table(rows: list[DerivCheck], docs_root: Path) -> int:
    widths = [38, 50, 12]
    print(_fmt_row(["File", "derivative-of", "Status"], widths))
    fails = 0
    for r in rows:
        file_short = _shorten(str(r.file.relative_to(docs_root)).replace("\\", "/"), widths[0])
        deriv_short = _shorten(r.derivative_of, widths[1])
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
            file_short = _shorten(str(r.file.relative_to(docs_root)).replace("\\", "/"), widths[0])
        except ValueError:
            file_short = r.file.name
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
        name = _shorten(r.relative_name, widths[0])
        status = "COVERED" if r.covered else "MISSING"
        if not r.covered:
            fails += 1
        print(_fmt_row([name, status], widths))
    return fails


def print_category_distribution(stats: CategoryStats) -> None:
    widths = [3, 50, 8]
    print(_fmt_row(["ID", "Category", "Count"], widths))
    for cat, label in CATEGORY_DEFS.items():
        cnt = stats.counts.get(cat, 0)
        print(_fmt_row([cat, _shorten(label, widths[1]), str(cnt)], widths))
    print(_fmt_row(["", "TOTAL", str(stats.total)], widths))


def print_tier_missing(rows: list[TierCheck], docs_root: Path, head: int = 20) -> int:
    """Tier 누락 파일 목록. head 만 출력. fails 반환."""
    fails = len(rows)
    if fails == 0:
        print("No tier-missing files. PASS.")
        return 0
    print(f"Tier missing files: {fails} (showing first {min(head, fails)})")
    for r in rows[:head]:
        rel = _shorten(str(r.file.relative_to(docs_root)).replace("\\", "/"), 70)
        print(f"  - {rel}")
    if fails > head:
        print(f"  ... and {fails - head} more")
    return fails


def print_backlog_check(rows: list[BacklogCheck], docs_root: Path, head: int = 20) -> int:
    fails = sum(1 for r in rows if not r.is_valid)
    if not rows:
        print("No D-category files. SKIP.")
        return 0
    print(f"Backlog files: {len(rows)} total, {fails} invalid (showing first {min(head, fails)})")
    shown = 0
    for r in rows:
        if r.is_valid or shown >= head:
            continue
        rel = _shorten(str(r.file.relative_to(docs_root)).replace("\\", "/"), 60)
        status_s = r.status or "MISSING"
        close_s = r.close_date or "—"
        print(f"  - {rel}  [status={status_s}, close-date={close_s}]")
        shown += 1
    return fails


def print_cr_impacts(rows: list[CRImpactCheck], docs_root: Path, head: int = 20) -> int:
    fails = sum(1 for r in rows if r.impacts is None)
    if not rows:
        print("No C-category files. SKIP.")
        return 0
    print(f"CR files: {len(rows)} total, {fails} missing impacts (showing first {min(head, fails)})")
    shown = 0
    for r in rows:
        if r.impacts is not None or shown >= head:
            continue
        rel = _shorten(str(r.file.relative_to(docs_root)).replace("\\", "/"), 70)
        print(f"  - {rel}")
        shown += 1
    return fails


def print_contract_derivative(rows: list[ContractDerivCheck], docs_root: Path, head: int = 20) -> int:
    fails = sum(1 for r in rows if not r.has_link)
    if not rows:
        print("No B-category files. SKIP.")
        return 0
    print(f"Contract files: {len(rows)} total, {fails} missing derivative-of/related-spec (showing first {min(head, fails)})")
    shown = 0
    for r in rows:
        if r.has_link or shown >= head:
            continue
        rel = _shorten(str(r.file.relative_to(docs_root)).replace("\\", "/"), 70)
        print(f"  - {rel}")
        shown += 1
    return fails


def print_internal_owner(rows: list[InternalOwnerCheck], docs_root: Path, head: int = 20) -> int:
    fails = sum(1 for r in rows if not r.owner and not r.stream)
    if not rows:
        print("No F-category files. SKIP.")
        return 0
    print(f"Internal files: {len(rows)} total, {fails} missing owner/stream (showing first {min(head, fails)})")
    shown = 0
    for r in rows:
        if (r.owner or r.stream) or shown >= head:
            continue
        rel = _shorten(str(r.file.relative_to(docs_root)).replace("\\", "/"), 70)
        print(f"  - {rel}")
        shown += 1
    return fails


# ----------------------------------------------------------------------------
# main
# ----------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        description="EBS 문서 SSOT 일관성 + 9 카테고리 검증"
    )
    default_docs = (Path(__file__).resolve().parent.parent / "docs").resolve()
    parser.add_argument(
        "--path",
        type=Path,
        default=default_docs,
        help=f"docs 루트 경로 (기본: {default_docs})",
    )
    parser.add_argument(
        "--strict-tier",
        action="store_true",
        help="Tier 누락(I)이 있으면 FAIL (기본: 경고만)",
    )
    parser.add_argument(
        "--strict-internal",
        action="store_true",
        help="Internal owner 누락 시 FAIL (기본: 경고만)",
    )
    parser.add_argument(
        "--strict-backlog",
        action="store_true",
        help="Backlog status 누락 시 FAIL (기본: 경고만)",
    )
    parser.add_argument(
        "--orphan",
        action="store_true",
        help="Category I (tier 누락) 파일만 출력 (다른 검증 SKIP)",
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
    print("=== EBS SSOT Verification v2 (9 카테고리) ===")
    print(f"Timestamp: {timestamp}")
    print(f"Docs Root: {docs_root}")

    # --orphan 모드: 카테고리 분포 + tier 누락만
    if args.orphan:
        _print_section_header(4, "Category Distribution")
        cat_stats = check_category_distribution(docs_root)
        print_category_distribution(cat_stats)

        _print_section_header(5, "Tier 누락 (Category I) — orphan 모드")
        tier_rows = check_tier_missing(docs_root, cat_stats)
        fails = print_tier_missing(tier_rows, docs_root, head=200)
        return 1 if fails > 0 else 0

    # 전체 9 검증 실행
    # [1] derivative-of
    _print_section_header(1, "derivative-of Chain Verification")
    deriv_rows = check_derivative_chain(docs_root)
    deriv_fails = print_derivative_table(deriv_rows, docs_root)
    deriv_total = len(deriv_rows)

    # [2] confluence-page-id
    _print_section_header(2, "Confluence page-id Verification (docs/1. Product/)")
    conf_rows = check_confluence_ids(product_root)
    conf_fails = print_confluence_table(conf_rows, docs_root)
    conf_total = len(conf_rows)

    # [3] llms.txt coverage
    _print_section_header(3, "llms.txt Coverage Verification")
    llms_exists, cov_rows = check_llms_coverage(docs_root, product_root)
    if not llms_exists:
        print("FAIL: docs/llms.txt 파일이 존재하지 않습니다.")
        cov_fails = 1
        cov_total = 1
    else:
        cov_fails = print_coverage_table(cov_rows)
        cov_total = len(cov_rows)

    # [4] Category Distribution
    _print_section_header(4, "Category Distribution (9 Categories)")
    cat_stats = check_category_distribution(docs_root)
    print_category_distribution(cat_stats)

    # [5] Tier 누락
    _print_section_header(5, "Tier 누락 (Category I)")
    tier_rows = check_tier_missing(docs_root, cat_stats)
    tier_fails = print_tier_missing(tier_rows, docs_root)
    tier_strict_fail = tier_fails if args.strict_tier else 0

    # [6] Backlog status (D)
    _print_section_header(6, "Backlog Status 완전성 (Category D)")
    backlog_rows = check_backlog_status(docs_root, cat_stats)
    backlog_fails = print_backlog_check(backlog_rows, docs_root)
    backlog_strict_fail = backlog_fails if args.strict_backlog else 0

    # [7] CR-NNN impact 매핑 (C)
    _print_section_header(7, "CR-NNN Impact 매핑 (Category C)")
    cr_rows = check_cr_impacts(docs_root, cat_stats)
    cr_fails = print_cr_impacts(cr_rows, docs_root)
    # CR impacts 는 정보용 (informational), 무조건 strict 아님

    # [8] Contract derivative-of (B)
    _print_section_header(8, "Contract derivative-of 완전성 (Category B)")
    contract_rows = check_contract_derivative(docs_root, cat_stats)
    contract_fails = print_contract_derivative(contract_rows, docs_root)
    # Contract derivative-of 는 informational (Phase 3 후 strict 가능)

    # [9] Internal spec owner (F)
    _print_section_header(9, "Internal Spec owner 명시 (Category F)")
    internal_rows = check_internal_owner(docs_root, cat_stats)
    internal_fails = print_internal_owner(internal_rows, docs_root)
    internal_strict_fail = internal_fails if args.strict_internal else 0

    # Summary
    print()
    print("=== Summary ===")
    deriv_mark = "OK" if deriv_fails == 0 else "FAIL"
    conf_mark = "OK" if conf_fails == 0 else "FAIL"
    cov_mark = "OK" if cov_fails == 0 else "FAIL"
    tier_mark = "OK" if tier_fails == 0 else f"INFO ({tier_fails})"
    backlog_mark = "OK" if backlog_fails == 0 else f"INFO ({backlog_fails})"
    cr_mark = "OK" if cr_fails == 0 else f"INFO ({cr_fails})"
    contract_mark = "OK" if contract_fails == 0 else f"INFO ({contract_fails})"
    internal_mark = "OK" if internal_fails == 0 else f"INFO ({internal_fails})"

    print(f"[1] derivative-of: {deriv_total - deriv_fails}/{deriv_total} {deriv_mark}")
    print(f"[2] Confluence ID: {conf_total - conf_fails}/{conf_total} {conf_mark}")
    print(f"[3] llms.txt:      {cov_total - cov_fails}/{cov_total} {cov_mark}")
    print(f"[4] Categories:    {cat_stats.total} files distributed across 9 categories (informational)")
    print(f"[5] Tier missing:  {tier_mark}")
    print(f"[6] Backlog status:{backlog_mark}")
    print(f"[7] CR impacts:    {cr_mark}")
    print(f"[8] Contract link: {contract_mark}")
    print(f"[9] Internal owner:{internal_mark}")

    # Strict fail = [1] + [2] + [3] + 옵션별 strict
    strict_fail = (
        deriv_fails + conf_fails + cov_fails
        + tier_strict_fail + backlog_strict_fail + internal_strict_fail
    )
    overall = "PASS" if strict_fail == 0 else "FAIL"
    print(f"OVERALL: {overall}")
    print()
    print("Note: [5]~[9] are informational by default. Use --strict-tier / --strict-backlog / --strict-internal to enforce.")

    return 0 if strict_fail == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
