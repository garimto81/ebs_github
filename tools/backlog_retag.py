#!/usr/bin/env python3
"""
Backlog 3-Type Retag Tool (2026-04-20)

목적: 기존 Backlog 항목을 프로젝트 의도 재정의 (개발팀 인계용 기획서 완결) 관점에서
      Spec_Gap / Prototype_Scenario / Implementation 3 Type 으로 분류 제안.

Type 정의:
  - spec_gap         : 기획 공백 (Type B). 기획자가 결정을 내려야 할 항목.
  - prototype_scenario: 프로토타입 검증 시나리오. 통합 성공 기준.
  - implementation    : 기획 확정 후 구현 작업 (Type A).
  - archive           : CCR 폐기 (2026-04-17) 이후 역사 보존 대상.

사용:
  python tools/backlog_retag.py --scan docs/4. Operations/Conductor_Backlog/
  python tools/backlog_retag.py --scan "docs/2. Development/2.1 Frontend/Backlog/" --dry-run

출력: 각 항목별 제안 Type + 신뢰도 + 이유. 자동 이동은 수행하지 않음 (manual review 필수).
"""
from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


# 파일명 휴리스틱 (신뢰도 0.5~0.8)
ARCHIVE_PATTERNS = [
    re.compile(r"^NOTIFY-CCR-", re.I),
    re.compile(r"^NOTIFY-LEGACY-CCR-", re.I),
    re.compile(r"-DONE-\d{4}-\d{2}-\d{2}\.md$"),
]

SPEC_GAP_KEYWORDS = [
    "검토-요청", "명세", "카탈로그", "재편", "정렬", "프로토콜", "표준", "SSOT",
    "stale", "audit", "drift", "Confluence", "align", "결정",
]

PROTOTYPE_SCENARIO_KEYWORDS = [
    "E2E", "통합-테스트", "시나리오", "검증", "browser-e2e", "Playwright",
    "부하-테스트", "운영-검증", "확인", "실재",
]

IMPL_KEYWORDS = [
    "구현", "추가", "개발", "지원", "마이그레이션", "설정", "cleanup", "audit",
    "wiring", "fix", "테이블", "라우터", "엔드포인트",
]


@dataclass
class Proposal:
    path: Path
    suggested_type: str
    confidence: float
    reasons: list[str]

    def format_line(self) -> str:
        return (
            f"[{self.suggested_type:22}] "
            f"({self.confidence:.2f}) "
            f"{self.path.name}  "
            f"-- {', '.join(self.reasons)}"
        )


def classify(path: Path) -> Proposal:
    name = path.name
    content = ""
    try:
        content = path.read_text(encoding="utf-8", errors="ignore")[:2000]
    except OSError:
        pass

    reasons: list[str] = []

    if any(p.search(name) for p in ARCHIVE_PATTERNS):
        reasons.append("filename matches CCR/DONE archive pattern")
        return Proposal(path, "archive", 0.90, reasons)

    # 키워드 점수
    def score(keywords: list[str]) -> tuple[int, list[str]]:
        hits = [k for k in keywords if k in name or k in content]
        return len(hits), hits

    gap_score, gap_hits = score(SPEC_GAP_KEYWORDS)
    scen_score, scen_hits = score(PROTOTYPE_SCENARIO_KEYWORDS)
    impl_score, impl_hits = score(IMPL_KEYWORDS)

    scores = {
        "spec_gap": (gap_score, gap_hits),
        "prototype_scenario": (scen_score, scen_hits),
        "implementation": (impl_score, impl_hits),
    }
    best = max(scores.items(), key=lambda kv: kv[1][0])
    best_type, (best_score, best_hits) = best

    if best_score == 0:
        reasons.append("no keyword match; default to implementation (review)")
        return Proposal(path, "implementation", 0.30, reasons)

    reasons.append(f"keyword hits: {', '.join(best_hits[:4])}")
    # 단순 신뢰도: 최대 점수 / (최대 점수 + 차점 점수 + 1)
    others = sorted((v[0] for k, v in scores.items() if k != best_type), reverse=True)
    runner_up = others[0] if others else 0
    confidence = round(best_score / (best_score + runner_up + 1), 2)
    return Proposal(path, best_type, confidence, reasons)


def scan(root: Path) -> Iterable[Proposal]:
    for md in sorted(root.glob("*.md")):
        if md.name.startswith("_"):
            continue  # templates
        if md.name in {"README.md"}:
            continue
        yield classify(md)


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description="Backlog 3-Type retag proposal tool")
    ap.add_argument("--scan", required=True, help="Backlog directory to scan")
    ap.add_argument("--dry-run", action="store_true", help="Propose only (no file moves)")
    ap.add_argument("--summary", action="store_true", help="Only print aggregate counts")
    args = ap.parse_args(argv)

    root = Path(args.scan)
    if not root.is_dir():
        print(f"ERROR: {root} is not a directory", file=sys.stderr)
        return 2

    proposals = list(scan(root))
    if not proposals:
        print(f"No .md items found in {root}")
        return 0

    if args.summary:
        counts: dict[str, int] = {}
        for p in proposals:
            counts[p.suggested_type] = counts.get(p.suggested_type, 0) + 1
        total = len(proposals)
        print(f"# Retag summary for {root}  (total={total})")
        for t in ("spec_gap", "prototype_scenario", "implementation", "archive"):
            n = counts.get(t, 0)
            print(f"  {t:22} {n:4}  ({n / total * 100:.0f}%)")
        return 0

    print(f"# Retag proposals for {root}  (total={len(proposals)})")
    print("# Review manually before moving files. Conductor notifies team decision_owner for team-owned Backlog.")
    print()
    for p in proposals:
        print(p.format_line())
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
