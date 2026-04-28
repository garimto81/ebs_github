"""One-shot: Overview.md 의 lifecycle 발췌 9 섹션에 Lifecycle 도메인 cross-ref 추가.

B-349 §5 (2026-04-28).
사용 후 본 스크립트는 cleanup PR 에서 삭제 (_underscore prefix).
"""
from __future__ import annotations
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
TARGET = REPO_ROOT / "docs" / "2. Development" / "2.3 Game Engine" / "Behavioral_Specs" / "Overview.md"

# (section_header, cross_ref_message)
SECTIONS = [
    ("## 1.1 게임 Enum",
     "Lifecycle 도메인 마스터 §2.5 game Enum"),
    ("### 1.2.4 event_game_type",
     "Lifecycle 도메인 마스터 §2.6 event_game_type Enum + §3.9 Mix Type 별 Rotation 매트릭스 + §5.13 Mixed Game Transition pseudocode"),
    ("### 1.4.5 BoardRevealStage",
     "Lifecycle 도메인 마스터 §2.3 BoardRevealStage Enum — 단, 보드 카드 감지 로직은 BS-06-12 권위 (Triggers 도메인 §3.5 T4-T8 atomic flop)"),
    ("### 1.5.2 PlayerStatus",
     "Lifecycle 도메인 마스터 §2.4 PlayerStatus Enum"),
    ("## 1.9 게임 페이즈 Enum",
     "Lifecycle 도메인 마스터 §2.2 game_phase Enum + §2.1 Hold'em FSM 상태 흐름 다이어그램"),
    ("## 2.1 GameState (최상위 핸드 상태)",
     "Lifecycle 도메인 마스터 §5.1 GameState 28 필드 (`bomb_pot_opted_out` / `mixed_game_sequence` / `tournament_heads_up` 등 WSOP Rule 28.3.2/87/88/100.b 의존 state 포함)"),
    ("## 2.2 Player (플레이어 상태)",
     "Lifecycle 도메인 마스터 §5.2 Player 15 필드 (`missed_sb` / `missed_bb` / `cards_tabled` 등 WSOP Rule 71/86 의존 state 포함)"),
    ("## 7.4 HandState → GameSession 매핑",
     "Lifecycle 도메인 마스터 §5.4 GameSession ↔ HandState 매핑 + §2.7 GamePhase → Street 매핑"),
    ("## 7.5 엔진 초기화 흐름",
     "Lifecycle 도메인 마스터 §5.15 엔진 초기화 흐름 5 단계 (Live 진입 → GameEngine 인스턴스 → createInitialState → activeHand → StartHand)"),
]

CROSSREF_TEMPLATE = "\n> ℹ️ **B-349 §5 cross-ref (2026-04-28)**: 본 섹션은 `Behavioral_Specs/Lifecycle_and_State_Machine.md` 에 통합되었습니다. **권위**: {ref}. 본 Overview 의 항목은 SSOT 가 아닌 reference 로 유지 — 충돌 시 도메인 마스터 우선.\n"


def main() -> int:
    text = TARGET.read_text(encoding="utf-8")
    inserted = 0
    skipped = 0

    for header, ref in SECTIONS:
        # header 다음 줄 또는 다음 빈 줄 직후에 cross-ref 삽입
        # pattern: 섹션 헤더 라인 + 다음 줄 (빈 줄)
        pattern = re.compile(
            re.escape(header) + r"\n",
            flags=re.MULTILINE,
        )
        match = pattern.search(text)
        if not match:
            print(f"  SKIP (header not found): {header}")
            skipped += 1
            continue

        # 이미 cross-ref 있으면 skip (idempotent)
        # header 직후 ~3 줄 안에 "B-349 §5 cross-ref" 가 있으면 이미 처리된 섹션
        end = match.end()
        next_chunk = text[end:end + 200]
        if "B-349 §5 cross-ref" in next_chunk:
            print(f"  SKIP (already cross-ref): {header}")
            skipped += 1
            continue

        # 헤더 라인 직후 (헤더 줄 끝 + \n 직후) 에 삽입
        crossref = CROSSREF_TEMPLATE.format(ref=ref)
        text = text[:end] + crossref + text[end:]
        inserted += 1
        print(f"  INSERT: {header}")

    if inserted == 0 and skipped == len(SECTIONS):
        print(f"\nAll {len(SECTIONS)} sections already cross-ref'd. No changes.")
        return 0

    TARGET.write_text(text, encoding="utf-8")
    print(f"\nWrote {inserted} cross-ref insertions ({skipped} skipped).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
