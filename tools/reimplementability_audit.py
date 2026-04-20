#!/usr/bin/env python3
"""
reimplementability_audit.py — 계약 문서 재구현 가능성 집계 (2026-04-20 v2)

목적: **계약 문서**(Foundation, BS_Overview, APIs, Schema, Settings, SG 등) 의
      frontmatter `reimplementability` 필드를 읽어 외부 개발팀 인계 준비도를 집계.

프로젝트 의도 (2026-04-20): EBS = 개발팀 인계용 기획서 완결.

Scope discipline (2026-04-20 재정의):
  **audit 대상 = 계약 문서만**. README·Backlog·NOTIFY·archive 등은 대상 아님.
  모든 .md 에 frontmatter 강요 금지 (지표 숭배 오류). MISSING 수치가 높다고
  일괄 UNKNOWN 도배하는 행위는 금지 — 판정 근거 없이 통계만 오염시킴.

Frontmatter 표준:
---
reimplementability: PASS | UNKNOWN | FAIL | N/A
reimplementability_checked: YYYY-MM-DD
reimplementability_notes: "짧은 이유"
---

사용:
  python tools/reimplementability_audit.py                   # 계약 문서만 집계 (기본)
  python tools/reimplementability_audit.py --all-md          # legacy 전체 스캔
  python tools/reimplementability_audit.py --details FAIL    # FAIL 항목 상세
  python tools/reimplementability_audit.py --path docs/1.*   # 특정 경로
  python tools/reimplementability_audit.py --stale-days 30   # 30일 이상 미확인 경고
"""
from __future__ import annotations

import argparse
import datetime as dt
import fnmatch
import re
import sys
from collections import Counter
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable


import os


def _rel(p: "Path") -> str:
    try:
        return os.path.relpath(str(p))
    except ValueError:
        return str(p)


FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)^---\s*\n", re.S | re.M)
FIELD_RE = re.compile(r"^(reimplementability(?:_checked|_notes)?):\s*(.+?)\s*$", re.M)

VALID_STATES = {"PASS", "UNKNOWN", "FAIL", "N/A"}

REPO = Path(__file__).resolve().parents[1]

# -------------------------------------------------- Contract document patterns
#
# 계약 문서 = 외부 개발팀이 받아 해당 챕터 + 프로토타입 해당 컴포넌트만으로
# 재구현 가능해야 하는 문서. 이 목록 밖의 .md (README, Backlog, landing,
# Reports) 는 frontmatter 필드 강요 대상 아님.
CONTRACT_INCLUDE_GLOBS = [
    # Product 최상위 PRD·참조
    "docs/1. Product/Foundation.md",
    "docs/1. Product/Game_Rules/**/*.md",
    # Shared 계약
    "docs/2. Development/2.5 Shared/*.md",
    # Backend 계약
    "docs/2. Development/2.2 Backend/APIs/**/*.md",
    "docs/2. Development/2.2 Backend/Database/**/*.md",
    # Engine 계약
    "docs/2. Development/2.3 Game Engine/APIs/**/*.md",
    # Command Center 계약
    "docs/2. Development/2.4 Command Center/APIs/**/*.md",
    # Frontend 계약 (확정 챕터)
    "docs/2. Development/2.1 Frontend/Settings/**/*.md",
    "docs/2. Development/2.1 Frontend/Graphic_Editor/**/*.md",
    "docs/2. Development/2.1 Frontend/Lobby/**/*.md",
    # Operations 핵심 계약
    "docs/4. Operations/Roadmap.md",
    "docs/4. Operations/Spec_Gap_Triage.md",
    "docs/4. Operations/Spec_Gap_Registry.md",
    "docs/4. Operations/Conductor_Backlog/SG-*.md",
]

# 제외: 계약 INCLUDE 내부에 있어도 아래 패턴에 매치되면 audit 대상 아님
CONTRACT_EXCLUDE_GLOBS = [
    "**/README.md",
    "**/_*.md",             # _template_*.md, _archived-*.md 등
    "**/_archived-*/**",
    "**/_archived-2026-04/**",
    "**/Backlog/**",
    "docs/4. Operations/Conductor_Backlog/B-*.md",  # 일반 Backlog 항목
    "docs/_generated/**",
    "docs/images/**",
    "docs/examples/**",
    "docs/mockups/**",
]


@dataclass
class Entry:
    path: Path
    state: str = "MISSING"  # MISSING = no frontmatter field
    checked: str | None = None
    notes: str = ""

    @property
    def stale_days(self) -> int | None:
        if not self.checked:
            return None
        try:
            d = dt.date.fromisoformat(self.checked)
            return (dt.date.today() - d).days
        except ValueError:
            return None


def parse_frontmatter(text: str) -> dict[str, str]:
    m = FRONTMATTER_RE.match(text)
    if not m:
        return {}
    body = m.group(1)
    return {k: v.strip().strip('"').strip("'") for k, v in FIELD_RE.findall(body)}


def _match_any_glob(rel_path: str, patterns: list[str]) -> bool:
    """상대 경로가 임의 glob 패턴과 매치되는지. Windows 대응으로 / 통일."""
    norm = rel_path.replace("\\", "/")
    for pat in patterns:
        if fnmatch.fnmatch(norm, pat):
            return True
        # ** 처리 보강: fnmatch 는 ** 를 * 로 취급하지 않음. 수동 대응.
        # 패턴이 ** 포함 시 앞뒤 분할 후 prefix/suffix 매치
        if "**" in pat:
            parts = pat.split("**")
            if len(parts) == 2:
                prefix, suffix = parts
                prefix = prefix.rstrip("/")
                suffix = suffix.lstrip("/")
                if norm.startswith(prefix) and fnmatch.fnmatch(norm[len(prefix):].lstrip("/"), suffix):
                    return True
    return False


def _is_contract(md: Path) -> bool:
    try:
        rel = str(md.relative_to(REPO)).replace("\\", "/")
    except ValueError:
        rel = str(md).replace("\\", "/")
    if _match_any_glob(rel, CONTRACT_EXCLUDE_GLOBS):
        return False
    return _match_any_glob(rel, CONTRACT_INCLUDE_GLOBS)


def scan(roots: list[Path], contracts_only: bool = True) -> Iterable[Entry]:
    for root in roots:
        for md in sorted(root.rglob("*.md")):
            if "_generated" in md.parts or "archive" in md.parts:
                continue
            if contracts_only and not _is_contract(md):
                continue
            try:
                text = md.read_text(encoding="utf-8", errors="ignore")
            except OSError:
                continue
            fields = parse_frontmatter(text)
            state = fields.get("reimplementability", "").upper() or "MISSING"
            if state not in VALID_STATES and state != "MISSING":
                state = f"INVALID({state})"
            yield Entry(
                path=md,
                state=state,
                checked=fields.get("reimplementability_checked") or None,
                notes=fields.get("reimplementability_notes", ""),
            )


def summary(entries: list[Entry], contracts_only: bool) -> None:
    counts = Counter(e.state for e in entries)
    total = len(entries)
    scope = "contract docs" if contracts_only else "all .md"
    if total == 0:
        print(f"No {scope} found.")
        return
    print(f"# Reimplementability audit  ({scope} total = {total})\n")
    print(f"| State     | Count | Ratio |")
    print(f"|-----------|------:|------:|")
    for state in ("PASS", "UNKNOWN", "FAIL", "N/A", "MISSING"):
        n = counts.get(state, 0)
        if n == 0:
            continue
        print(f"| {state:9} | {n:5} | {n/total*100:4.0f}% |")
    invalid = {s: n for s, n in counts.items() if s.startswith("INVALID")}
    for s, n in invalid.items():
        print(f"| {s:9} | {n:5} | {n/total*100:4.0f}% |")
    print()
    missing = counts.get("MISSING", 0)
    fail = counts.get("FAIL", 0)
    if missing:
        if contracts_only:
            print(f"⚠ MISSING {missing}건 — 계약 문서인데 frontmatter 에 `reimplementability` 필드가 없음. "
                  f"신규 계약 문서 생성 시 frontmatter 필수.")
        else:
            print(f"ℹ MISSING {missing}건 — non-contract docs 포함. `--contracts-only` 기본 모드 권장.")
    if fail:
        print(f"❌ FAIL {fail}건 — 기획 공백/모순. `Conductor_Backlog/Spec_Gaps/` 추적 필요.")


def details(entries: list[Entry], state_filter: str) -> None:
    filtered = [e for e in entries if e.state == state_filter.upper()]
    if not filtered:
        print(f"No entries with state={state_filter}")
        return
    print(f"# Entries: state = {state_filter.upper()}  (n={len(filtered)})\n")
    for e in filtered:
        stale = f" [{e.stale_days}d old]" if e.stale_days is not None else ""
        note = f" — {e.notes}" if e.notes else ""
        print(f"- {_rel(e.path)}{stale}{note}")


def stale_warn(entries: list[Entry], days: int) -> None:
    stale = [e for e in entries if e.stale_days is not None and e.stale_days >= days]
    if not stale:
        print(f"No entries older than {days} days.")
        return
    print(f"# Stale entries (>= {days} days since last check)  (n={len(stale)})\n")
    for e in sorted(stale, key=lambda x: -(x.stale_days or 0)):
        print(f"- [{e.stale_days:4}d] {e.state:8} {_rel(e.path)}")


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--path", nargs="*", default=["docs"], help="경로 (기본 docs/)")
    ap.add_argument("--details", help="특정 상태 상세 (PASS/UNKNOWN/FAIL/N/A/MISSING)")
    ap.add_argument("--stale-days", type=int, help="N일 이상 미확인 경고")
    ap.add_argument(
        "--contracts-only",
        dest="contracts_only",
        action="store_true",
        default=True,
        help="계약 문서만 스캔 (기본값). Foundation, APIs, Schema, Settings, SG 등",
    )
    ap.add_argument(
        "--all-md",
        dest="contracts_only",
        action="store_false",
        help="legacy 전체 .md 스캔 (MISSING 수치가 noise 로 커짐)",
    )
    args = ap.parse_args(argv)

    roots = [Path(p) for p in args.path if Path(p).is_dir()]
    if not roots:
        print("No valid roots.", file=sys.stderr)
        return 2

    entries = list(scan(roots, contracts_only=args.contracts_only))
    if args.stale_days:
        stale_warn(entries, args.stale_days)
        return 0
    if args.details:
        details(entries, args.details)
        return 0
    summary(entries, contracts_only=args.contracts_only)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
