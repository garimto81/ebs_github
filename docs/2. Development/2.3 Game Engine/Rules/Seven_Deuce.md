---
title: Seven-Deuce Side Bet — 7-2 offsuit winner 보너스 (Cycle 7 v04)
owner: team3 (S8 Cycle 7)
tier: contract
legacy-id: BS-06-05
last-updated: 2026-05-12
last-synced: 2026-05-12
reimplementability: PASS
reimplementability_checked: 2026-05-12
reimplementability_notes: "isSevenDeuce + checkSevenDeuceBonus 헬퍼 코드 file:line + _awardPotFull wire 사양 + OE-13 SevenDeuceBonusAwarded payload + dart test 케이스 명세. Engine 헬퍼만 존재 — 본 spec 이 wire 지점 SSOT."
related-issue: 327
related-cycle: 7
related-spec: Engine_Defaults.md, Bomb_Pot.md
---

# Seven-Deuce Side Bet — 7-2 offsuit winner 보너스

## 개요

`sevenDeuceEnabled == true` + `sevenDeuceAmount > 0` 상태에서 showdown winner 가 7-2 offsuit hole cards 를 보유한 경우, 각 non-folded 패자가 `sevenDeuceAmount` 만큼을 winner 에게 추가 지불한다. action 유도 + 거지패 fun bet.

> **목적**: 7-2 offsuit (강도 최저 hole cards) 로 이긴 경우 보너스. all-in/aggressive play 유도.
>
> **연관 Issue**: [#327](https://github.com/garimto81/ebs_github/issues/327) S8 Cycle 7 v04.

---

## 1. 7-2 offsuit 정의

| 조건 | 검사 |
|------|------|
| hole cards 수 | 정확히 2 (NLH / PLH variant 한정) |
| Rank 집합 | `{Rank.seven, Rank.two}` 일치 |
| Suit | `cards[0].suit != cards[1].suit` (offsuit) |

> 모든 조건 충족 시 `Showdown.isSevenDeuce(holeCards) == true`. variant 가 holdem 계열이 아닌 경우 (5-card draw, stud 등) 7-2 룰은 미적용 — `holeCards.length != 2` 분기에서 자동 제외.

---

## 2. 보너스 산출 알고리즘

### 2.1 winner 수령액

```
nonFoldedCount = seats.where(!s.isFolded && s.holeCards.isNotEmpty).count
for each winner W in PotAwarded.awards (with amount > 0):
  if Showdown.isSevenDeuce(W.holeCards):
    bonus[W] = sevenDeuceAmount * (nonFoldedCount - 1)
```

### 2.2 패자 deduction 알고리즘 (신규 — 본 spec 이 wire 정의)

> Engine 의 기존 helper `checkSevenDeuceBonus` 는 winner 의 보너스 수령액만 반환. 본 spec 이 패자 → winner 자금 이동을 wire 한다.

```
totalBonus = sum(bonus.values)  // winner 들이 받는 총액
nonFoldedLosers = seats.where(s => !s.isFolded && s.holeCards.notEmpty && bonus[s.index]==null)

if totalBonus > 0 and nonFoldedLosers.isNotEmpty:
  perLoser = sevenDeuceAmount  // 각 패자가 winner 1명당 amount 지불
  // 여러 winner 동시 발생 시:
  //   각 패자는 (winner 수 × amount) 만큼 차감
  //   = sevenDeuceAmount * bonus.keys.length
  loserDeduction = sevenDeuceAmount * bonus.keys.length

  for each loser L:
    actual = min(L.stack, loserDeduction)
    L.stack -= actual
    // shortfall: stack 부족 시 받는 winner 들에게 균등 차감 (proportional)
    if actual < loserDeduction:
      shortfall = loserDeduction - actual
      // winner 들의 bonus 를 shortfall 만큼 비례 차감
```

> **Shortfall 처리 (간소화 v04)**: 패자 stack 이 부족하면 받는 winner 들의 bonus 를 비례 차감. side-pot 식 정확한 분배 대신 v04 는 ¼ 정밀도로 단순화 — 정확한 short-stack edge case 는 v05 이후 보강 (현재 issue #327 범위 밖).

### 2.3 wire 지점 (impl PR 변경 사양)

**기존**: `lib/engine.dart::_awardPotFull` (line 671-682) 는 PotAwarded event 의 awards 를 그대로 seat.stack 에 합산 후 pot clear 만 함. seven_deuce 처리 없음.

**변경 사양** (impl PR 에서 적용):

```dart
static ReduceResult _awardPotFull(GameState state, PotAwarded event) {
  final newState = state.copyWith();
  final outputs = <OutputEvent>[];

  // 1) 기본 award 적용
  for (final entry in event.awards.entries) {
    newState.seats[entry.key].stack += entry.value;
  }

  // 2) seven_deuce 활성 시 보너스 계산 + 적용
  if (newState.sevenDeuceEnabled &&
      newState.sevenDeuceAmount != null &&
      newState.sevenDeuceAmount! > 0) {
    final bonus = Showdown.checkSevenDeuceBonus(
      seats: newState.seats,
      awards: event.awards,
      sevenDeuceAmount: newState.sevenDeuceAmount!,
    );
    if (bonus.isNotEmpty) {
      _applySevenDeuceTransfer(newState, bonus, newState.sevenDeuceAmount!);
      for (final entry in bonus.entries) {
        outputs.add(SevenDeuceBonusAwarded(
          seatIndex: entry.key,
          bonusAmount: entry.value,
        ));
      }
    }
  }

  // 3) Pot clear (기존 동작)
  newState.pot.main = 0;
  newState.pot.sides = [];

  outputs.add(WinnerDetermined(awards: event.awards));
  return ReduceResult(state: newState, outputs: outputs);
}

/// 7-2 보너스를 winner 들에게 적용하고 패자 stack 에서 deduction.
/// short-stack edge case: 패자 stack 부족 시 winner bonus 를 비례 차감.
static void _applySevenDeuceTransfer(
  GameState newState,
  Map<int, int> bonus,
  int sevenDeuceAmount,
) {
  final losers = <int>[];
  for (var i = 0; i < newState.seats.length; i++) {
    if (!newState.seats[i].isFolded &&
        newState.seats[i].holeCards.isNotEmpty &&
        !bonus.containsKey(i)) {
      losers.add(i);
    }
  }
  if (losers.isEmpty) return;

  final perLoser = sevenDeuceAmount * bonus.length;
  var collected = 0;
  for (final lIdx in losers) {
    final actual = newState.seats[lIdx].stack < perLoser
        ? newState.seats[lIdx].stack
        : perLoser;
    newState.seats[lIdx].stack -= actual;
    collected += actual;
  }

  // bonus 합계 vs 실수령 collected — shortfall 비례 차감
  final totalBonus = bonus.values.reduce((a, b) => a + b);
  if (collected >= totalBonus) {
    for (final entry in bonus.entries) {
      newState.seats[entry.key].stack += entry.value;
    }
  } else {
    // 비례 차감
    final ratio = collected / totalBonus;
    var given = 0;
    final entries = bonus.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final isLast = (i == entries.length - 1);
      final share = isLast ? (collected - given) : (entries[i].value * ratio).floor();
      newState.seats[entries[i].key].stack += share;
      given += share;
    }
  }
}
```

> **변경 라인 추정**: `lib/engine.dart::_awardPotFull` (line 671) 함수 본문 11줄 → 약 50줄로 확장 + 신규 helper `_applySevenDeuceTransfer` 약 35줄 추가. `lib/core/rules/showdown.dart` 의 `checkSevenDeuceBonus` 와 `isSevenDeuce` 는 그대로 재사용.

---

## 3. 코드 위치 (file:line SSOT)

| 책임 | 위치 | 상태 |
|------|------|:----:|
| `Showdown.isSevenDeuce(holeCards)` | `team3-engine/ebs_game_engine/lib/core/rules/showdown.dart:152-158` | ✅ 구현 |
| `Showdown.checkSevenDeuceBonus(...)` | `team3-engine/ebs_game_engine/lib/core/rules/showdown.dart:161-178` | ✅ 구현 (winner 보너스 계산만) |
| `GameState.sevenDeuceEnabled / sevenDeuceAmount` | `team3-engine/ebs_game_engine/lib/core/state/game_state.dart:48-49` | ✅ 필드 존재 |
| `Session.toJson()` sevenDeuce* 노출 | `team3-engine/ebs_game_engine/lib/harness/session.dart:103-104` | ✅ 구현 |
| `SevenDeuceBonusAwarded` OutputEvent (OE-13) | `team3-engine/ebs_game_engine/lib/core/actions/output_event.dart:114-119` | ✅ 정의 |
| **`_awardPotFull` wire** (winner 보너스 적용 + 패자 deduction + OE-13 emit) | `team3-engine/ebs_game_engine/lib/engine.dart:671-682` | ❌ **MISSING — 본 spec 의 wire 사양으로 impl PR 에서 적용** |
| `_applySevenDeuceTransfer` helper | (신규 — `lib/engine.dart` 내) | ❌ 신규 |

---

## 4. 검증 시나리오 (dart test 명세 — impl PR 에서 실행)

### 4.1 NLH 6-seat, winner=7-2 offsuit, 4 non-folded

```
state: NLH, seat0=[7♥,2♦], seat1=[A♠,K♠], seat2=[Q♦,Q♣], seat3=[J♥,J♣],
       seat4=folded, seat5=folded, sevenDeuceEnabled=true, sevenDeuceAmount=20
PotAwarded({0: 1000})
expected:
  seat0.stack += 1000 + 20*3 = 1060  (20 from each of seat1/2/3)
  seat1.stack -= 20
  seat2.stack -= 20
  seat3.stack -= 20
  outputs include SevenDeuceBonusAwarded(seatIndex=0, bonusAmount=60)
```

### 4.2 winner=7-2 suited → 보너스 NO

```
state: seat0=[7♥,2♥] (suited), PotAwarded({0: 1000}), sevenDeuceEnabled=true
expected: seat0.stack += 1000 only. SevenDeuceBonusAwarded NOT emitted.
```

### 4.3 winner non-72 → 보너스 NO

```
state: seat0=[A♠,K♠], PotAwarded({0: 1000}), sevenDeuceEnabled=true, sevenDeuceAmount=20
expected: seat0.stack += 1000. SevenDeuceBonusAwarded NOT emitted.
```

### 4.4 sevenDeuceEnabled=false → 보너스 NO (기능 비활성)

```
state: seat0=[7♥,2♦], PotAwarded({0:1000}), sevenDeuceEnabled=false
expected: 기본 award 만. SevenDeuceBonusAwarded NOT emitted.
```

### 4.5 short-stack 패자 비례 차감 edge case

```
state: 3 seats, seat0=[7♥,2♦] winner, seat1.stack=15, seat2.stack=200,
       sevenDeuceAmount=20, nonFoldedCount=3 → bonus[0]=40
       perLoser = 20*1 = 20
expected:
  seat1: stack -= 15 (부족), collected += 15
  seat2: stack -= 20, collected += 20
  total collected = 35 vs totalBonus 40 → shortfall 5
  ratio = 35/40 = 0.875
  seat0.stack += 35 (전체 collected, winner 1명이므로 isLast=true)
```

### 4.6 split pot 양쪽이 7-2 winner

```
state: seat0=[7♥,2♦], seat1=[7♣,2♠] (둘 다 7-2 offsuit, 동일 hand strength),
       PotAwarded({0: 500, 1: 500}), nonFoldedCount=4, sevenDeuceAmount=20
expected:
  bonus = {0: 60, 1: 60}  // 각자 (4-1) × 20
  perLoser = 20 × 2 = 40
  seat2/seat3 각 -40
  seat0.stack += 500 + 60
  seat1.stack += 500 + 60
  SevenDeuceBonusAwarded emit × 2
```

### 4.7 Harness `POST /api/session` response

```http
POST /api/session
  → sevenDeuceEnabled: false (default)
  → sevenDeuceAmount: null (default)

(activation: 별도 enable 이벤트는 v04 범위 외 — initial state 또는 향후 SevenDeuceConfig event 추가)
```

> **참고**: 현재 `sevenDeuceEnabled / sevenDeuceAmount` 활성화 경로는 initial state 만 (HandStart 시점 외부 주입 미정의). v05 에서 `SevenDeuceConfig` event 도입 고려 — issue #327 범위 외.

---

## 5. 정합 정책

| 충돌 시 우선순위 | 근거 |
|-----------------|------|
| 1. `lib/engine.dart::_awardPotFull` 실제 구현 (impl PR 적용 후) | 정본 |
| 2. 본 `Rules/Seven_Deuce.md` | wire 사양 SSOT |
| 3. `lib/core/rules/showdown.dart::checkSevenDeuceBonus` | helper 정본 |
| 4. 기획서 `Game_Rules/Betting_System.md` §7-6 | 사용자/외부 인계 표현 |
| 5. UI 표현 | Engine SSOT 따름 |

---

## 6. 미해결 (v05 이후)

| 항목 | 우선순위 | 비고 |
|------|:--------:|------|
| `SevenDeuceConfig` event 도입 | MEDIUM | 현재 활성화 경로가 initial state 만 — `BombPotConfig` 패턴 따라 dynamic enable 필요 |
| short-stack 정확 분배 (side-pot 식) | LOW | v04 비례 차감은 1-chip 정밀도 부정확. 정확 분배 v05 이후 |
| variant 별 7-2 정의 (Omaha 4-card 등) | LOW | 현재 holdem 2-card 한정. Omaha 4-card 에서 7-2 정의 별도 결정 필요 |
| audit log / spec_drift_check 통합 | LOW | spec_drift_check 가 sevenDeuceEnabled wire 검증하도록 보강 |

---

## 7. Changelog

| 날짜 | 버전 | 변경 내용 | 변경 유형 | 결정 근거 |
|------|------|-----------|----------|----------|
| 2026-05-12 | v1.0 | 최초 작성 (issue #327 Cycle 7 v04 — helper 만 존재하던 7-2 룰의 wire 사양 SSOT 화) | - | Cycle 7 v04 deeper game 룰 명세 |
