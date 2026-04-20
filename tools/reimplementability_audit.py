#!/usr/bin/env python3
"""
reimplementability_audit.py — 기획서 챕터 재구현 가능성 집계 (2026-04-20)

목적: `docs/**.md` 파일 frontmatter 의 `reimplementability` 필드를 읽어
      프로젝트 전체의 "개발팀 인계 준비도" 를 집계.

프로젝트 의도 (2026-04-20): EBS = 개발팀 인계용 기획서 완결. 프로토타입 완벽 동작 ↔ 기획서 완벽.

Frontmatter 표준:
---
reimplementability: PASS | UNKNOWN | FAIL | N/A
reimplementability_checked: YYYY-MM-DD
reimplementability_notes: "짧은 이유"
---

사용:
  python tools/reimplementability_audit.py                  # 전체 집계
  python tools/reimplementability_audit.py --details FAIL   # FAIL 항목 상세
  python tools/reimplementability_audit.py --path docs/1.*  # 특정 경로
  python tools/reimplementability_audit.py --stale-days 30  # 30일 이상 미확인 경고
"""
from __future__ import annotations

import argparse
import datetime as dt
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


def scan(roots: list[Path]) -> Iterable[Entry]:
    for root in roots:
        for md in sorted(root.rglob("*.md")):
            if "_generated" in md.parts or "archive" in md.parts:
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


def summary(entries: list[Entry]) -> None:
    counts = Counter(e.state for e in entries)
    total = len(entries)
    if total == 0:
        print("No markdown files found.")
        return
    print(f"# Reimplementability audit  (docs total = {total})\n")
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
        print(f"⚠ MISSING {missing}건 — frontmatter 에 `reimplementability` 필드 미기재. "
              f"`reimplementability: UNKNOWN` 으로 최소 선언 권고.")
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
    args = ap.parse_args(argv)

    roots = [Path(p) for p in args.path if Path(p).is_dir()]
    if not roots:
        print("No valid roots.", file=sys.stderr)
        return 2

    entries = list(scan(roots))
    if args.stale_days:
        stale_warn(entries, args.stale_days)
        return 0
    if args.details:
        details(entries, args.details)
        return 0
    summary(entries)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
