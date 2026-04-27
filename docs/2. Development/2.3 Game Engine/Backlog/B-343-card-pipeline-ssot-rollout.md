---
id: B-343
title: "Card Pipeline SSOT (BS-06-12) rollout — Lifecycle/Triggers/OutputEvents 정렬 + 테스트 추가"
status: PENDING
priority: P1
created: 2026-04-27
source: docs/2. Development/2.3 Game Engine/Backlog.md
related-spec: "Behavioral_Specs/Card_Pipeline_Overview.md (BS-06-12, 본 PR 신규)"
---

# [B-343] Card Pipeline SSOT (BS-06-12) rollout (P1)

## 배경

`Behavioral_Specs/Card_Pipeline_Overview.md` (BS-06-12) 가 신규 SSOT 로 도입되어 다음 두 변경을 결정적으로 정의함:

1. **턴 기반 홀카드 호출** — 기존 `HoleCardsDealt` (전원 일괄) → `SeatHoleCardCalled` (각 좌석 ACTION_TURN 진입 시 1회)
2. **Atomic Flop 감지** — 1·2장 인식 시 외부 미발행 (`BoardState.FLOP_PARTIAL` PENDING). 정확히 3장 충족 시점에만 `FlopRevealed` 1회

본 BS-06-12 가 권위가 되면서 다음 3 문서가 정합성 보강을 필요로 함. 또한 신규 동작을 검증할 테스트가 부재함.

## 수정 대상

### 문서 (cross-ref 정렬)

| 파일 | 작업 | 검증 |
|------|------|------|
| `Behavioral_Specs/Holdem/Lifecycle.md` | §매트릭스 3 BS-06-12 참조 footnote (이번 PR 1차 처리 완료) | grep 으로 "error log" 잔존 여부 확인 |
| `Behavioral_Specs/Triggers.md` | §2.3 `HoleCardsDealt` deprecated 주석 + `SeatHoleCardCalled` 추가 | §7 매트릭스에 `SeatHoleCardCalled` 행 추가 |
| `APIs/Overlay_Output_Events.md` | §6.0 카탈로그 OE-05/OE-06 emit-trigger 컬럼 갱신 | 카탈로그 항목 수 21 → 21 (no schema change) 확인 |
| `Behavioral_Specs/Holdem/Coalescence.md` | `CardCoalescer` ↔ `FlopAggregator` 직렬 흐름 명시 | §"RFID burst 처리" 절 보강 |

### 코드 (`team3-engine/ebs_game_engine/`)

- `lib/core/cards/turn_sync_dealer.dart` 신규 — `dealtSeats` 가드 + `onActionOnChanged` 트리거 (BS-06-12 §2.3 의사코드 기반)
- `lib/core/cards/flop_aggregator.dart` 신규 — `buffer.length == 3` 가드 + `pending_since` timeout
- `lib/core/state/hand_fsm.dart` — 위 두 컴포넌트 wiring. 기존 `_dispatchHoleCardsDealt` (bulk) deprecate
- `lib/core/state/game_state.dart` — `BoardState` enum 추가 (`AWAITING_FLOP`, `FLOP_PARTIAL`, `FLOP_READY`, `FLOP_DONE`, `AWAITING_TURN`, `TURN_DONE`, `AWAITING_RIVER`, `RIVER_DONE`)
- `bin/harness.dart` — `/api/session/:id/event` 처리 시 위 신규 reducer 통합

### 테스트

- `test/phase4_flop_atomic_test.dart` 신규
  - 1장 push → OutputEventBuffer 비어있음 검증
  - 2장 push → 동일
  - 3장 push → `FlopRevealed` 1개 발행, 카드 순서 보존
  - 30초 timeout simulation → `FlopPartialAlert` 발행, 상태 유지
  - 중복 카드 push → `DUPLICATE_BOARD_CARD` + buffer 영향 없음
- `test/phase5_turn_sync_dealer_test.dart` 신규
  - PRE_FLOP 진입 시 first_to_act 만 `SeatHoleCardCalled`
  - 같은 좌석 재진입 (UNDO 등) 시 `dealtSeats` 가드로 무시
  - Bomb Pot 모드: SETUP_HAND 종료 시 active 좌석 일괄 release (legacy 동작 유지)
  - All-in Runout: `action_on == -1` 진입 시 잔여 좌석 일괄 release
  - Mix Game: `variant.holeCardCount` 별 분기 (NLH=2, Omaha=4)

## 수락 기준

- [ ] `dart analyze` 0 errors (현 baseline 유지)
- [ ] `dart test test/phase4_flop_atomic_test.dart -v` 모든 케이스 PASS
- [ ] `dart test test/phase5_turn_sync_dealer_test.dart -v` 모든 케이스 PASS
- [ ] `Lifecycle.md`, `Triggers.md`, `Overlay_Output_Events.md`, `Coalescence.md` 4개 문서가 BS-06-12 cross-ref 포함
- [ ] BS-06-12 §9 Open Items 리스트 (B-343~B-348) 본 PR 또는 후속 PR 로 closed
- [ ] CC subscriber (team4) 가 `FlopPartialAlert` 핸들러 추가 (B-348 cross-team — 별도 PR 가능)

## 관련

- BS-06-12 (`Behavioral_Specs/Card_Pipeline_Overview.md`) — 본 SSOT
- B-344 (Triggers.md 정렬), B-345 (OutputEvents §6.0 정렬), B-346 (flop test), B-347 (turn sync test), B-348 (team4 CC handler)
- 기존 관련: B-307 (Coalescence RFID burst — 본 SSOT 가 흐름 단순화), B-310 (ReduceResult 아키텍처 — `TurnSyncDealer`/`FlopAggregator` 가 reducer 결과로 흡수)
