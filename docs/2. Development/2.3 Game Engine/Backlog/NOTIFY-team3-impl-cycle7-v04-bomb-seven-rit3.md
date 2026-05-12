---
title: NOTIFY team3-impl — Cycle 7 v04 Engine 코드 변경 인계 (bomb_pot + seven_deuce + run_it_three)
type: notify
from: S8 (Cycle 7 spec)
to: team3-impl (engine code 변경 권한 보유 stream)
status: pending
priority: P1
created: 2026-05-12
related-issue: 327
related-cycle: 7
related-specs:
  - docs/2. Development/2.3 Game Engine/Rules/Bomb_Pot.md
  - docs/2. Development/2.3 Game Engine/Rules/Seven_Deuce.md
  - docs/2. Development/2.3 Game Engine/Rules/Run_It_Three.md
---

# NOTIFY team3-impl — Cycle 7 v04 Engine 코드 변경 인계

## 배경

S8 Cycle 7 v04 (#327) 의 KPI = "dart test 신규 케이스 PASS". S8 scope_owns 는 `docs/2. Development/2.3 Game Engine/**` 한정이므로 engine 코드 (`team3-engine/**`) 변경은 별도 stream 의 impl PR 로 분리.

본 NOTIFY 는 spec 3종을 받아 impl 을 수행할 stream 에 정확한 file:line + diff 사양을 인계한다.

---

## 1. bomb_pot — 변경 사항 (영향 적음)

> 본 룰은 Engine 에 **이미 90% 구현됨** (engine.dart:387-436). 본 NOTIFY 의 작업은:

| Task | 위치 | 작업 |
|------|------|------|
| dart test 작성 | `team3-engine/ebs_game_engine/test/v04_bomb_pot_test.dart` (신규) | `Rules/Bomb_Pot.md` §3 시나리오 5개 작성 + PASS |
| Engine 추가 변경 | 없음 (현재 구현이 spec 과 일치) | 단, ManualNextHand 의 `bombPotEnabled=false` reset 동작 보존 확인 |

---

## 2. seven_deuce — 변경 사항 (대규모)

### 2.1 `lib/engine.dart::_awardPotFull` 확장

**현재 (line 671-682)** — 11줄:

```dart
static ReduceResult _awardPotFull(GameState state, PotAwarded event) {
  final newState = state.copyWith();
  for (final entry in event.awards.entries) {
    newState.seats[entry.key].stack += entry.value;
  }
  newState.pot.main = 0;
  newState.pot.sides = [];
  return ReduceResult(state: newState, outputs: [
    WinnerDetermined(awards: event.awards),
  ]);
}
```

**변경 후** — 약 50줄. 정확한 diff 는 `Rules/Seven_Deuce.md` §2.3 참조.

### 2.2 신규 helper `_applySevenDeuceTransfer`

`lib/engine.dart` 내 신규 static method. 약 35줄. `Rules/Seven_Deuce.md` §2.3 참조.

### 2.3 변경 영향 범위

| 파일 | 변경 |
|------|------|
| `lib/engine.dart` | `_awardPotFull` 확장 (+40줄) + `_applySevenDeuceTransfer` 신규 (+35줄) |
| `lib/core/rules/showdown.dart` | 변경 없음 (helper 재사용) |
| `lib/harness/session.dart` | 변경 없음 (이미 sevenDeuce* 노출) |

### 2.4 dart test

`test/v04_seven_deuce_test.dart` (신규) — `Rules/Seven_Deuce.md` §4 시나리오 7개 작성.

---

## 3. run_it_three — 변경 사항 (중간 규모)

### 3.1 `lib/core/state/game_state.dart` 필드 추가

**현재** (line 52-54):
```dart
final int? runItTimes;
final List<Card>? runItBoard2Cards;
```

**변경 후**:
```dart
final int? runItTimes;
final List<Card>? runItBoard2Cards;
final List<Card>? runItBoard3Cards;  // v04 #327
```

추가 변경:
- 생성자 named param `this.runItBoard3Cards`
- `copyWith` named param `List<Card>? runItBoard3Cards`
- `copyWith` 본문 `runItBoard3Cards: runItBoard3Cards ?? this.runItBoard3Cards`

### 3.2 `lib/engine.dart::_handleRunItChoiceFull` 확장

**현재** (line 754-793) — `times == 2 && canSplit` 만 board2 deal. `times == 3` 은 legacy state 전환만.

**변경**: `times == 3 && community.length == 5` 조건도 board2 + board3 deal. `Rules/Run_It_Three.md` §1.2 알고리즘 참조.

### 3.3 `lib/engine.dart::runItAwards` 분기 + `_runItAwards3` helper

**현재** (line 811): `if (state.runItTimes != 2 || state.runItBoard2Cards == null) return null;` — RIT3 reject.

**변경**: RIT2 / RIT3 분기. 신규 `_runItAwards3` helper 도입. `Rules/Run_It_Three.md` §2.2 참조.

### 3.4 `lib/harness/session.dart` JSON key 추가

**현재** (line 105-106):
```dart
'runItTimes': state.runItTimes,
'runItBoard2Cards': state.runItBoard2Cards?.map((c) => c.notation).toList(),
```

**변경**:
```dart
'runItTimes': state.runItTimes,
'runItBoard2Cards': state.runItBoard2Cards?.map((c) => c.notation).toList(),
'runItBoard3Cards': state.runItBoard3Cards?.map((c) => c.notation).toList(),
```

### 3.5 dart test

`test/v04_run_it_three_test.dart` (신규) — `Rules/Run_It_Three.md` §4 시나리오 7개 작성.

---

## 4. 의존성 / 순서

| 순서 | 작업 |
|:----:|------|
| 1 | `game_state.dart` `runItBoard3Cards` 필드 추가 |
| 2 | `engine.dart::_handleRunItChoiceFull` RIT3 분기 + `_runItAwards3` |
| 3 | `engine.dart::_awardPotFull` seven_deuce wire + helper |
| 4 | `harness/session.dart` JSON key 추가 |
| 5 | 3개 v04 test 파일 작성 |
| 6 | `dart test` regression (740+ tests) PASS 확인 |
| 7 | `dart analyze` 0 issue 확인 |

---

## 5. 검증 명령 (KPI 충족 확인)

```bash
cd team3-engine/ebs_game_engine
dart test test/v04_bomb_pot_test.dart
dart test test/v04_seven_deuce_test.dart
dart test test/v04_run_it_three_test.dart
dart test  # 전체 regression
dart analyze lib/
```

기대:
- v04 신규 19 케이스 (5 + 7 + 7) ALL PASS
- 전체 regression PASS (기존 740+ 보존)
- analyze 0 issue

---

## 6. impl PR 권장 제목 / 본문

```
feat(team3-impl/cycle7): v04 bomb_pot + seven_deuce wire + run_it_three [#327]

S8 Cycle 7 v04 spec 3종 (Bomb_Pot.md / Seven_Deuce.md / Run_It_Three.md)
의 engine 코드 구현. spec PR 은 별도 S8 PR 참조.

## 변경 요약
- lib/core/state/game_state.dart: runItBoard3Cards 필드 추가
- lib/engine.dart:
  - _awardPotFull: sevenDeuce 활성 시 winner 보너스 + 패자 deduction + OE-13 emit
  - _handleRunItChoiceFull: times=3 분기 → board2+board3 deal
  - runItAwards: RIT2/RIT3 분기 + _runItAwards3 helper 신규
- lib/harness/session.dart: runItBoard3Cards JSON key 추가
- test/v04_bomb_pot_test.dart (신규, 5 cases)
- test/v04_seven_deuce_test.dart (신규, 7 cases)
- test/v04_run_it_three_test.dart (신규, 7 cases)

KPI: dart test 신규 19 cases PASS + regression PASS.
broker MCP publish: cascade:engine-v04-ready.
issue #327 close 조건 충족.
```

---

## 7. 진행 상태

| 항목 | 상태 | 일자 |
|------|:----:|------|
| Spec 3종 작성 (S8) | ✅ 완료 | 2026-05-12 |
| 본 NOTIFY 작성 (S8) | ✅ 완료 | 2026-05-12 |
| impl stream 할당 | ⏳ pending | TBD |
| Engine 코드 변경 | ⏳ pending | TBD |
| dart test 작성 + PASS | ⏳ pending | TBD |
| Harness response 검증 | ⏳ pending | TBD |
| broker cascade:engine-v04-ready | ⏳ pending | TBD |
| issue #327 close | ⏳ pending | TBD |
