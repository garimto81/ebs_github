#!/usr/bin/env python3
"""IMPL-007 (D7 회의 2026-04-22) — CC 카드 비노출 정적 검증.

CC widget 트리에서 hole card 의 **값** (rank/suit) 을 렌더링하는 패턴을 검출.
데이터 layer (provider/state/dispatcher) 의 `holeCards` 필드는 Overlay 송출용으로
허용 — 본 가드는 widget 디렉토리만 스캔.

검출 규칙:
  CC widget 파일에서 다음 패턴 발견 시 FAIL:
    - HoleCard 의 .rank / .suit 직접 접근 (Text/Container 위젯 내부)
    - _buildHoleCards(...) / _buildMiniCard(...) 함수 호출
    - cards[i].rank / holeCards[X].rank 패턴

허용:
  - seat.holeCards.isNotEmpty (count check)
  - seat.holeCards.length (count display)
  - holeCardBack 위젯 (face-down 만 표시)

Usage:
  python tools/check_cc_no_holecard.py [--path team4-cc/src/lib/features/command_center/widgets]
  exit 0 = PASS, exit 1 = FAIL

References:
  - docs/1. Product/Foundation.md §5.4 Command Center
  - docs/4. Operations/Critic_Reports/Meeting_Analysis_2026_04_22.md D7
  - docs/4. Operations/Conductor_Backlog/IMPL-007-cc-no-card-display-contract.md
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# 위반 패턴 (regex)
FORBIDDEN_PATTERNS: list[tuple[str, str]] = [
    (r"_buildHoleCards\s*\(", "함수 호출 _buildHoleCards(...) — hole card 값 렌더링"),
    (r"_buildMiniCard\s*\(", "함수 호출 _buildMiniCard(...) — hole card 값 렌더링"),
    (r"\bcard\.rank\b", "card.rank 직접 접근 — hole card 값 노출"),
    (r"\bcard\.suit\b", "card.suit 직접 접근 — hole card 값 노출"),
    (r"holeCards\[\d+\]\.(rank|suit)", "hole cards 배열 요소 직접 접근 — 값 노출"),
    (r"cards\[\w+\]\.(rank|suit)", "cards 배열 요소 직접 접근 — 값 노출"),
]

# 허용 패턴 (false positive 방지)
ALLOWED_PATTERNS: list[str] = [
    r"holeCards\.isEmpty",
    r"holeCards\.isNotEmpty",
    r"holeCards\.length",
    r"holeCardsCount",
    r"_buildHoleCardBack",  # face-down 표시는 허용
]


def is_dart_file(p: Path) -> bool:
    return p.suffix == ".dart" and not p.name.endswith(".g.dart")


def scan_file(path: Path) -> list[tuple[int, str, str]]:
    """파일 한 개 스캔. 위반 라인 list 반환: (line_no, pattern_desc, line_content)."""
    violations: list[tuple[int, str, str]] = []
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        text = path.read_text(encoding="latin-1")

    for line_no, line in enumerate(text.splitlines(), start=1):
        # 주석 라인은 스킵
        stripped = line.strip()
        if stripped.startswith("//") or stripped.startswith("///") or stripped.startswith("/*"):
            continue

        # 허용 패턴 우선 체크 (false positive 회피)
        if any(re.search(p, line) for p in ALLOWED_PATTERNS):
            # 허용 패턴이 있으면 같은 라인의 forbidden 도 무시 (count check 등)
            # 단, 별도 forbidden 이 있으면 검사
            pass

        for pattern, desc in FORBIDDEN_PATTERNS:
            if re.search(pattern, line):
                # ALLOWED 가 같은 라인에 있으면 false positive 가능 — 단, _build* 함수 호출은
                # 명확한 violation 이므로 통과 안 시킴
                if re.search(r"_buildHoleCards|_buildMiniCard", line):
                    violations.append((line_no, desc, line.rstrip()))
                elif not any(re.search(p, line) for p in ALLOWED_PATTERNS):
                    violations.append((line_no, desc, line.rstrip()))

    return violations


def main() -> int:
    parser = argparse.ArgumentParser(description="IMPL-007 CC 카드 비노출 정적 검증")
    parser.add_argument(
        "--path",
        default="team4-cc/src/lib/features/command_center/widgets",
        help="스캔할 디렉토리 (default: CC widgets)",
    )
    parser.add_argument(
        "--quiet", action="store_true", help="PASS 시 stdout 침묵"
    )
    args = parser.parse_args()

    target = Path(args.path)
    if not target.exists():
        print(f"FATAL: 경로 없음 — {target}", file=sys.stderr)
        return 2

    dart_files = sorted(p for p in target.rglob("*.dart") if is_dart_file(p))
    if not dart_files:
        print(f"WARN: {target} 에 .dart 파일 없음", file=sys.stderr)
        return 0

    total_violations = 0
    file_violations: dict[Path, list[tuple[int, str, str]]] = {}

    for f in dart_files:
        v = scan_file(f)
        if v:
            file_violations[f] = v
            total_violations += len(v)

    if total_violations == 0:
        if not args.quiet:
            print(
                f"✅ PASS — {len(dart_files)} 파일 스캔, hole card 값 노출 0건 (D7 준수)"
            )
        return 0

    print(f"❌ FAIL — {total_violations} 위반 / {len(file_violations)} 파일")
    for f, vlist in file_violations.items():
        print(f"\n  {f}:")
        for line_no, desc, content in vlist:
            print(f"    L{line_no}: {desc}")
            print(f"           > {content}")

    print(
        "\n참조: docs/4. Operations/Conductor_Backlog/IMPL-007-cc-no-card-display-contract.md"
    )
    print("       docs/1. Product/Foundation.md §5.4")
    return 1


if __name__ == "__main__":
    sys.exit(main())
