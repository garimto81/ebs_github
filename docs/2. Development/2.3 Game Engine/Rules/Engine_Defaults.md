---
title: Engine Defaults — Settings 9 keys 정합
owner: team3 (S8 Cycle 4)
tier: contract
legacy-id: API-04.4
last-updated: 2026-05-12
last-synced: 2026-05-12  # Foundation §B.1 / spec_drift_check --settings 정합
reimplementability: PASS
reimplementability_checked: 2026-05-12
reimplementability_notes: "9 keys × default × Engine 매핑 표 + 코드 file:line. spec_drift_check engine D2 9→0 KPI 충족"
related-issue: 265
related-cycle: 4
---

# Engine Defaults — Settings 9 keys 정합 (Cycle 4)

## 개요

`spec_drift_check --settings` 결과 D2 (기획 有 / 코드 無) 분류된 9 keys 중 **Engine 영역 default** 명시. team1 frontend settings 영역과 별개로, Engine harness 가 노출하는 **실제 default 값**을 본 문서가 SSOT 로 보유한다.

> **목적**: Engine harness response (`Session.toJson()`) ↔ 기획서 (`Game_Rules/Betting_System.md` 등) 간 default 일치 보장. spec_drift_check engine D2 9→0.

> **연관 Issue**: [#265](https://github.com/garimto81/ebs_github/issues/265) S8 Cycle 4 P2.

---

## 1. 9 keys × Engine default 매핑표

| # | snake_case (spec) | Engine camelCase (code) | Default | 타입 | 위치 (코드) | 의미 |
|---|-------------------|------------------------|---------|------|-------------|------|
| 1 | `all_in` | `Seat.isAllIn` / `SeatStatus.allIn` | `false` (좌석 기본 status=active) | `bool` (derived) | `lib/core/state/seat.dart:32` + `seat.dart:3` enum | 좌석이 all-in 상태인지 — game state 동적값 |
| 2 | `allow_rabbit` | (Engine 미구현) | **N/A — out-of-scope** | — | — | Rabbit Hunt 기능 — team4 Overlay UX 영역, Engine 책임 외 |
| 3 | `allow_run_it_twice` | `runItTimes != null` (활성 조건) | `null` (비활성) → `false` (effective) | `int?` | `lib/core/state/game_state.dart:52, 86` | run-it-twice/multiple 활성 여부. `runItTimes` 설정 시 활성 |
| 4 | `ante_override` | `anteAmount` + `anteType` | `null` + `null` | `int? + int?` | `lib/core/state/game_state.dart:32-33, 76-77` | ante 명시 override. null = blind 표 기반 |
| 5 | `bomb_pot_amount` | `bombPotAmount` | `null` (with `bombPotEnabled=false`) | `int?` | `lib/core/state/game_state.dart:45, 83` | bomb pot 금액. null = 비활성 |
| 6 | `run_it_times` | `runItTimes` | `null` (1회 runout) | `int?` | `lib/core/state/game_state.dart:52, 86` | 다중 runout 횟수. null = 1회 |
| 7 | `seven_deuce_amount` | `sevenDeuceAmount` | `null` (with `sevenDeuceEnabled=false`) | `int?` | `lib/core/state/game_state.dart:49, 85` | 7-2 side bet 금액. null = 비활성 |
| 8 | `straddle_seat` | `straddleSeat` | `null` (with `straddleEnabled=false`) | `int?` | `lib/core/state/game_state.dart:37, 79` | straddle 좌석. null = 비활성 |
| 9 | `_blindsFormatOptions` | (Engine 외부 — UI) | **N/A — frontend 영역** | — | team1 settings screens | 블라인드 표시 포맷 — frontend rendering 결정 |

### 1.1 분류 요약

| 분류 | 개수 | keys |
|------|:----:|------|
| Engine 직접 매핑 (GameState) | 6 | `all_in`, `allow_run_it_twice`, `ante_override`, `bomb_pot_amount`, `run_it_times`, `seven_deuce_amount`, `straddle_seat` (`all_in` 은 derived, 나머지 6개는 config) |
| Engine out-of-scope (frontend UI / Overlay) | 2 | `allow_rabbit`, `_blindsFormatOptions` |
| 합계 | 9 | — |

**effective default 일관 규칙**: 7개 config 모두 `null` (또는 동반 enabled bool `false`) → "기능 비활성" 시그널. `Session.toJson()` 응답에서 `null` 그대로 노출.

---

## 2. Engine harness 검증 — POST /api/session response 매핑

`team3-engine/ebs_game_engine/lib/harness/session.dart` 의 `toJson()` 구현이 본 default 를 노출:

```dart
// session.dart toJson() 핵심 발췌
{
  'anteType': state.anteType,           // null
  'anteAmount': state.anteAmount,       // null
  'straddleEnabled': state.straddleEnabled,  // false
  'straddleSeat': state.straddleSeat,   // null
  'bombPotEnabled': state.bombPotEnabled,    // false
  'bombPotAmount': state.bombPotAmount, // null
  'sevenDeuceEnabled': state.sevenDeuceEnabled,  // false
  'sevenDeuceAmount': state.sevenDeuceAmount,    // null
  'runItTimes': state.runItTimes,       // null
  'isAllInRunout': Engine.isAllInRunout(state),  // derived bool
}
```

검증 명령:
```bash
# harness 기동
cd team3-engine/ebs_game_engine
dart run bin/harness.dart

# 다른 터미널에서
curl -s -X POST http://localhost:8080/api/session \
  -H "Content-Type: application/json" \
  -d '{"variant":"nlh","seatCount":4,"stacks":[1000,1000,1000,1000],"blinds":{"sb":5,"bb":10}}' \
  | jq '{anteType, anteAmount, straddleEnabled, straddleSeat, bombPotEnabled, bombPotAmount, sevenDeuceEnabled, sevenDeuceAmount, runItTimes, isAllInRunout}'
```

기대 결과: 모든 optional 필드 `null`, enabled bool `false`.

---

## 3. 정합 정책 (Foundation §B.1 정렬)

> Foundation §B.1 — *"Engine 은 22 게임 룰 전체를 코드 내장 상수로 보유. 매 핸드 외부에서 주입받는 입력이 아니며, 룰 변경은 Engine 재배포로만 가능하다."*

본 문서는 Engine 영역 default 의 SSOT (Single Source of Truth):

| 충돌 시 우선순위 | 근거 |
|-----------------|------|
| 1. Engine 코드 `GameState` 클래스 | 정본 (이 문서가 derive) |
| 2. 본 Rules/Engine_Defaults.md | Engine 코드 derive snapshot |
| 3. 기획서 (`Game_Rules/Betting_System.md`) | 사용자/외부 인계 표현 — 본 문서와 정합 강제 |
| 4. team1 frontend settings | UI 표현. Engine SSOT 따름 |

**spec_drift_check engine D2 0 유지 규칙**: Engine `GameState` 필드 추가/제거 시 본 문서 §1 표 동시 갱신. 신규 setting key 추가 시 Engine 영역 (config) vs out-of-scope (UI/Overlay) 분류 명시.

---

## 4. 다음 단계 (cascade pipeline)

| 단계 | 책임 | 입력 |
|------|------|------|
| `Game_Rules/Betting_System.md` 갱신 | conductor (BLOCKED meta) | 본 문서 §1 표 — Engine 영역 6개 default 명시 |
| `team1 frontend settings/Outputs.md` 보강 | team1 stream | `_blindsFormatOptions` UI 옵션 spec |
| `team4 Overlay/Rabbit_Hunt.md` 신설 (선택) | team4 stream | `allow_rabbit` 기능 PRD (Engine 외부) |
| Engine harness 검증 자동화 | S8 (다음 cycle) | curl 시나리오 → integration-tests/ |

---

## 5. 연관 문서

- `Overlay_Output_Events.md` (API-04) — OutputEvent 카탈로그
- `OutputEvent_Serialization.md` (API-04.1) — JSON envelope
- `OutputEventBuffer_Boundary.md` (API-04.3) — buffer 경계
- `Harness_REST_API.md` (API-04.2) — Session JSON 구조 §4
- `Game_Rules/Betting_System.md` (BLOCKED meta) — 외부 인계 사용자용 spec
- 정본 코드: `team3-engine/ebs_game_engine/lib/core/state/game_state.dart`
- 정본 코드: `team3-engine/ebs_game_engine/lib/harness/session.dart` (`toJson()`)
- spec_drift_check: `tools/spec_drift_check.py --settings`
