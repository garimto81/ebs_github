---
title: Run It Three — all-in 3분할 runout (Cycle 7 v04)
owner: team3 (S8 Cycle 7)
tier: contract
legacy-id: BS-06-08
last-updated: 2026-05-12
last-synced: 2026-05-12
reimplementability: PASS
reimplementability_checked: 2026-05-12
reimplementability_notes: "RunItChoice(times=3) 분기 + runItBoard3Cards 필드 신설 + runItAwards 3-way split 사양 + dart test 케이스 명세. Engine 에 RIT2 패턴 존재 — 본 spec 이 RIT3 확장 사양."
related-issue: 327
related-cycle: 7
related-spec: Engine_Defaults.md, Multi_Hand_State.md
related-prior: docs/2. Development/2.3 Game Engine/Rules/Multi_Hand_v03.md §3 (RIT2 baseline)
---

# Run It Three — all-in 3분할 runout

## 개요

전원 all-in 후 river 트리거 시점에 RIT2 와 동일한 위험 분산 메커니즘을 3-board 로 확장. pot 을 1/3 씩 3 board 에 배분하고, 각 board 별 winners 산출 후 awards 합산.

> **목적**: variance 분산 강화. 큰 pot 의 swing 완화. RIT2 의 자연 확장.
>
> **연관 Issue**: [#327](https://github.com/garimto81/ebs_github/issues/327) S8 Cycle 7 v04.

---

## 1. RunItChoice(times=3) 처리 사양

### 1.1 river-trigger 조건 (RIT2 와 동일)

```
preconditions:
  - event.times == 3
  - variantRegistry.containsKey(state.variantName)
  - state.community.length == 5  (river deal 완료 시점)
  - 모든 active seats all-in OR fold (RIT 는 all-in runout 상황에서만 의미)
```

조건 미충족 시 v02 legacy 동작 (state.runItTimes=3, street=runItMultiple 전환만, board 추가 안 함).

### 1.2 board 2 + board 3 deal 알고리즘

```
RIT3 baseline:
  board1 = state.community  (flop 3 + turn + river 5 cards 유지)

board2 생성:
  board2 = []
  for i in 0..2: board2.add(state.community[i])  // flop 3장 공유
  while board2.length < 5: board2.add(newState.deck.draw())  // 새 turn/river

board3 생성:
  board3 = []
  for i in 0..2: board3.add(state.community[i])  // flop 3장 공유
  while board3.length < 5: board3.add(newState.deck.draw())  // 새 turn/river

// 결과:
//   board1 = [F1, F2, F3, T1, R1]
//   board2 = [F1, F2, F3, T2, R2]
//   board3 = [F1, F2, F3, T3, R3]
// flop 3장은 공유 (표준 RIT 컨벤션), turn/river 만 분기
```

> **카드 소비 순서**: deck draw 순서는 board2 turn → board2 river → board3 turn → board3 river. deck 의 결정성 (test reproducibility) 보존.

### 1.3 GameState 필드 추가

| 필드 | 타입 | 기본값 | 의미 |
|------|------|:------:|------|
| `runItBoard3Cards` | `List<Card>?` | `null` | RIT3 board3 의 5 community cards. `times=3` 분기 통과 시에만 set |

> 기존 `runItBoard2Cards` (v03) 와 병존. `times=2` → board2 만 set, `times=3` → board2 + board3 둘 다 set.

### 1.4 OutputEvent

| Event | Payload | 비고 |
|-------|---------|------|
| `StateChanged` | `fromState=river`, `toState=runItMultiple` | RIT2 와 동일 |

> 별도 `RunItBoardDealt` OE 없음 — board2/board3 카드는 `Session.toJson()` response 에서 노출 (§3).

---

## 2. runItAwards 3-way split 알고리즘

### 2.1 baseline (RIT2)

기존 `Engine.runItAwards` (engine.dart:811-857) 는 `runItTimes==2` 한정. v04 에서 3분기 추가.

### 2.2 변경 사양 (impl PR 에서 적용)

```dart
static Map<int, int>? runItAwards(GameState state) {
  // v03 RIT2
  if (state.runItTimes == 2 && state.runItBoard2Cards != null) {
    return _runItAwards2(state);
  }
  // v04 RIT3
  if (state.runItTimes == 3 && state.runItBoard2Cards != null &&
      state.runItBoard3Cards != null) {
    return _runItAwards3(state);
  }
  return null;
}

static Map<int, int> _runItAwards3(GameState state) {
  final variant = variantRegistry[state.variantName]!();

  final sidePots = state.pot.sides.isEmpty
      ? <SidePot>[SidePot(state.pot.main, _eligibleSeatIndices(state))]
      : List<SidePot>.of(state.pot.sides);

  // pot 3-way split:
  //   board1Pot = ceil(amount/3) + 잔여 → odd chips
  //   board2Pot = amount / 3
  //   board3Pot = amount / 3
  //   total = amount (보존)
  final board1Pots = <SidePot>[];
  final board2Pots = <SidePot>[];
  final board3Pots = <SidePot>[];
  for (final sp in sidePots) {
    final third = sp.amount ~/ 3;
    final remainder = sp.amount - third * 3;  // 0, 1, or 2
    // odd chips → board1 (RIT2 와 동일 컨벤션)
    board1Pots.add(SidePot(third + remainder, Set<int>.of(sp.eligible)));
    board2Pots.add(SidePot(third, Set<int>.of(sp.eligible)));
    board3Pots.add(SidePot(third, Set<int>.of(sp.eligible)));
  }

  final board1Awards = Showdown.evaluate(
    seats: state.seats,
    community: state.community,
    pots: board1Pots,
    variant: variant,
    dealerSeat: state.dealerSeat,
  );
  final board2Awards = Showdown.evaluate(
    seats: state.seats,
    community: state.runItBoard2Cards!,
    pots: board2Pots,
    variant: variant,
    dealerSeat: state.dealerSeat,
  );
  final board3Awards = Showdown.evaluate(
    seats: state.seats,
    community: state.runItBoard3Cards!,
    pots: board3Pots,
    variant: variant,
    dealerSeat: state.dealerSeat,
  );

  final merged = <int, int>{};
  for (final e in board1Awards.entries) {
    merged[e.key] = (merged[e.key] ?? 0) + e.value;
  }
  for (final e in board2Awards.entries) {
    merged[e.key] = (merged[e.key] ?? 0) + e.value;
  }
  for (final e in board3Awards.entries) {
    merged[e.key] = (merged[e.key] ?? 0) + e.value;
  }
  return merged;
}
```

### 2.3 odd chip 분배 컨벤션

```
pot amount = 100, 3-way split:
  board1Pot = 34  (33 + 1 remainder, 또는 100 - 33 - 33 = 34)
  board2Pot = 33
  board3Pot = 33
  total = 100

pot amount = 101, 3-way split:
  board1Pot = 35  (33 + 2 remainder)
  board2Pot = 33
  board3Pot = 33
  total = 101

pot amount = 99, 3-way split:
  board1Pot = 33  (33 + 0)
  board2Pot = 33
  board3Pot = 33
  total = 99
```

> **컨벤션**: board1 이 odd chip 흡수 (RIT2 와 동일). 이유: board1 은 deck draw 순서 가장 앞 → "원래 community" 로 간주.

---

## 3. 코드 위치 (file:line SSOT)

| 책임 | 위치 | 상태 |
|------|------|:----:|
| `RunItChoice` event class | `team3-engine/ebs_game_engine/lib/core/actions/event.dart:60-63` | ✅ `times: 2 or 3` 주석 존재 |
| `GameState.runItTimes` | `team3-engine/ebs_game_engine/lib/core/state/game_state.dart:52` | ✅ 필드 존재 |
| `GameState.runItBoard2Cards` (RIT2) | `team3-engine/ebs_game_engine/lib/core/state/game_state.dart:54` | ✅ 필드 존재 |
| **`GameState.runItBoard3Cards` (RIT3)** | `team3-engine/ebs_game_engine/lib/core/state/game_state.dart` (신규 line) | ❌ **MISSING — 신규 필드** |
| `_handleRunItChoiceFull` RIT2 분기 | `team3-engine/ebs_game_engine/lib/engine.dart:754-793` | ✅ RIT2 구현 |
| **`_handleRunItChoiceFull` RIT3 분기** | (확장) | ❌ **MISSING — `event.times == 3 && community.length == 5` 분기 추가** |
| `Engine.runItAwards` (RIT2) | `team3-engine/ebs_game_engine/lib/engine.dart:811-857` | ✅ RIT2 구현 |
| **`Engine._runItAwards3` helper** | (신규) | ❌ **MISSING — 신규 helper** |
| `Session.toJson()` `runItTimes` / `runItBoard2Cards` | `team3-engine/ebs_game_engine/lib/harness/session.dart:105-106` | ✅ 노출 |
| **`Session.toJson()` `runItBoard3Cards`** | (확장) | ❌ **MISSING — JSON key 추가** |

---

## 4. 검증 시나리오 (dart test 명세 — impl PR 에서 실행)

### 4.1 RIT3 board2 + board3 생성

```
state: NLH, 3 seats all-in, community=[F1,F2,F3,T1,R1] (5 cards), pot.main=300,
       runItTimes=null, variantName='nlh'
Engine.applyFull(state, RunItChoice(3))
expected:
  state.runItTimes == 3
  state.runItBoard2Cards.length == 5
  state.runItBoard3Cards.length == 5
  state.runItBoard2Cards.sublist(0,3) == state.community.sublist(0,3)  // flop 공유
  state.runItBoard3Cards.sublist(0,3) == state.community.sublist(0,3)
  state.runItBoard2Cards[3..4] != state.runItBoard3Cards[3..4]  // turn/river 별개
  state.street == Street.runItMultiple
```

### 4.2 RIT3 분할 pot — 표준 split

```
state: pot.main=300, eligible={0,1,2}, seat0/1/2 hole cards 동일하지 않음
state.runItBoard2Cards / runItBoard3Cards set
Engine.runItAwards(state):
expected:
  board1Pot=100, board2Pot=100, board3Pot=100
  각 board winners 산출 후 sum
  totalAwards.values.sum == 300
```

### 4.3 RIT3 odd chip — board1 흡수

```
state: pot.main=101, 3-way split
expected:
  board1Pot=35, board2Pot=33, board3Pot=33
  totalAwards.values.sum == 101
```

### 4.4 RIT3 모든 board 같은 winner

```
state: seat0=[A♠,A♣], seat1=[K♠,K♣], seat2=[Q♠,Q♣], all-in,
       community=[2♥,3♥,4♥,5♥,6♥] (seat0 wins all boards 보장 못 함; nuts 시나리오)
state: seat0=[A♠,A♣] 단독, seat1 fold, seat2 fold (1 winner)
expected:
  bot1Award[0] = board1Pot
  board2Award[0] = board2Pot
  board3Award[0] = board3Pot
  merged[0] = total pot
```

### 4.5 RIT3 board 별 winner 다름

```
state: seat0/seat1 both all-in, hole cards:
       seat0=[A♠,A♦] (high pair)
       seat1=[7♠,8♠] (draw)
       community=[F1,F2,F3,T1,R1]
runItChoice(3) → 보드 3개 random outcome
expected:
  awards 합산이 pot 보존 (sum == pot.main)
  board 별로 winner 가 다를 수 있음 — variance 분산 효과
```

### 4.6 side-pot 있는 RIT3

```
state: 3 all-in seats with different stacks 끼리 side-pot 형성
       pot.main=100, pot.sides=[SidePot(200, {0,1}), SidePot(50, {0})]
runItChoice(3) split:
  main 100 → 34/33/33 (board1 흡수)
  side[0] 200 → 67/67/66 → 또는 (200/3=66, remainder=2) → 68/66/66
  side[1] 50 → 17/17/16
expected:
  각 side-pot 도 동일 3-way split. eligible set 보존.
  totalAwards.values.sum == 350
```

### 4.7 Harness `POST /api/session` response

```http
GET /api/session/{id}  (RIT3 이후)
expected response keys:
  runItTimes: 3
  runItBoard2Cards: ["...", "...", "...", "...", "..."]  // 5 cards notation
  runItBoard3Cards: ["...", "...", "...", "...", "..."]  // 5 cards notation
```

---

## 5. 정합 정책

| 충돌 시 우선순위 | 근거 |
|-----------------|------|
| 1. `lib/engine.dart::_handleRunItChoiceFull` + `_runItAwards3` 실제 구현 (impl PR) | 정본 |
| 2. 본 `Rules/Run_It_Three.md` | 사양 SSOT |
| 3. `Multi_Hand_v03.md` §3 RIT2 baseline | 직전 cycle 패턴 |
| 4. 기획서 `Game_Rules/Betting_System.md` §7-6 | 사용자/외부 인계 표현 |

---

## 6. 미해결 (v05 이후)

| 항목 | 우선순위 | 비고 |
|------|:--------:|------|
| `times` 일반화 (N=4, N=5 등) | LOW | 현재 hard-coded 2/3. ARM (Anti-Run Multiple) 일반화는 N 무한대 가능성 — 별도 설계 |
| RIT 거부 (operator 정책) | LOW | 현재 무조건 허용. table policy `runItPolicy: forbidden/allowed/forced` 도입 가능 |
| pre-flop / turn-trigger RIT | LOW | 현재 river-trigger 한정. WSOP 룰에서는 all-in 시점 어디서든 가능 — 별도 확장 |
| RIT 진행 중 ManualNextHand 보존 | LOW | RIT 끝나기 전 next-hand 호출 시 동작 정의 필요 |

---

## 7. Changelog

| 날짜 | 버전 | 변경 내용 | 변경 유형 | 결정 근거 |
|------|------|-----------|----------|----------|
| 2026-05-12 | v1.0 | 최초 작성 (issue #327 Cycle 7 v04 — RIT2 패턴의 3-way 확장 사양) | - | Cycle 7 v04 deeper game 룰 명세 |
