---
title: Equity Calculator — Overlay 9 카테고리 #4 정본 SSOT (Cycle 17 Wave 2.3 cascade)
owner: team3 (S8 Cycle 17)
tier: contract
legacy-id: API-04.8
last-updated: 2026-05-13
last-synced: 2026-05-13
reimplementability: PENDING
reimplementability_checked: 2026-05-13
reimplementability_notes: "PR #393 §8-1 사용자 표 9 카테고리 v1.0.0 cascade. Type B (기획 공백) 해소용 신규 정본. derivative-of 우선순위 위반 없음."
related-issue: 393
related-cycle: 17
related-spec: ../APIs/Harness_REST_API.md
derivative-of: ../../1. Product/Game_Rules/Betting_System.md
if-conflict: derivative-of takes precedence
cascade-from: cascade:overlay-9-categories
cascade-emits: cascade:engine-equity-spec
---

# Equity Calculator — Overlay 9 카테고리 #4 정본 SSOT

## 개요

[Betting_System.md §8-1](../../1.%20Product/Game_Rules/Betting_System.md) 의 "실시간 승률 통계 (Equity)" Monte Carlo 계산 spec 을 Game Engine 구현 차원에서 정본화한다. PR [#393](https://github.com/garimto81/ebs_github/pull/393) Cascade Note (Type B 기획 공백 — S8 trigger) 해소.

| 항목 | 값 |
|------|------|
| **외부 PRD §** | Betting_System.md §8-1 (Equity 계산 spec) |
| **Overlay Rive 변수** | `equity_percent` (Number, 0.0~100.0, 1자리 소수) |
| **Engine endpoint** | `GET /api/session/:id/equity` (Harness_REST_API.md §2.8) |
| **계산 방식** | Monte Carlo simulation (남은 board 카드 random sampling) |
| **기본 iteration N** | 10,000 (PR #393 §8-1-2 권고) — 단, harness legacy 호환 시 5,000 (§9 transition) |
| **데이터 소스** | RFID hole cards + RFID board cards + 활성 player 목록 (`is_folded=false`) |

> **WHY 정본 SSOT 필요**: 외부 PRD (`Betting_System.md §8-1`) 는 알고리즘 6단계와 갱신 트리거를 정의하나, Engine 측 코드 위치 / OutputEvent / Variant 별 평가 룰 / Run It Twice 분기 / Hi-Lo Split 처리 / position 계산 룰은 미정의. 본 정본이 engine 구현 SSOT.

---

## 1. Equity 정의

### 1.1 룰

> **Equity** = 현재 시점에서 핸드를 끝까지 보았을 때 이길 확률.
> "이길" = Hi 1위 (단일 우승) 또는 Lo 자격 시 분할 (Hi-Lo Split). Tie = 1/n_winners.

| 게임 계열 | 평가 기준 |
|----------|----------|
| Flop Games (Hold'em / Omaha / Pineapple / Short Deck) | Hi only (Hi-Lo Split variant 제외) |
| Hi-Lo Split (Omaha Hi-Lo / Stud Hi-Lo / etc) | Hi 1위 + Lo 자격자 (8-or-better 등 variant 룰) 분리 평가 |
| Draw (5CD / 2-7TD / Badugi) | Draw 진행 중에는 Equity 미산정 (draw 라운드 중 미정 카드 너무 많음) |
| Seven Card Games | 3rd Street 이후 공개 카드 기반 (Bring-in 기준) |

### 1.2 활성 player 정의

| 상태 | Equity 계산 포함 |
|------|:----------------:|
| `is_folded=false && is_sittingOut=false` | ✓ 포함 |
| `is_folded=true` (Fold) | ✗ 제외 |
| `is_sittingOut=true` | ✗ 제외 |
| `is_allIn=true` | ✓ 포함 (eligible Side Pot 별로 별도 평가) |

---

## 2. Monte Carlo 알고리즘 (6 단계)

### 2.1 단계 정의 (Betting_System.md §8-1-2 정합)

| 단계 | 동작 | Engine 구현 위치 (예정) |
|------|------|------------------------|
| 1. 입력 수집 | hole cards + board cards + 활성 player 목록 | `EquityCalculator._collectInputs(state)` |
| 2. 남은 카드 풀 산정 | 52 (Short Deck=36) − 알려진 카드 | `EquityCalculator._remainingDeck(state)` |
| 3. Monte Carlo 시뮬레이션 | 남은 board random sampling × N (기본 10,000) | `EquityCalculator._simulate(state, N)` |
| 4. 핸드 평가 | 각 sample 의 활성 player 최종 핸드 평가 (variant 룰) | `Evaluator.evaluate(hand, board, variant)` |
| 5. 승률 집계 | win_count[i] / N → Equity (0.0~1.0) | `EquityCalculator._aggregate(results)` |
| 6. 출력 | `equity_percent[i]` (0~100 float, 1자리 소수) | `Engine.computeEquity(state) → Map<int, double>` |

### 2.2 Pseudo-code

```
function computeEquity(state, N=10000):
    activeSeats = state.seats.filter(s => !s.isFolded && !s.isSittingOut)
    if activeSeats.length < 2:
        return {}                       // 1명 이하 → equity 정의 불가

    known = activeSeats.flatMap(s => s.holeCards) + state.community
    deck = fullDeck(state.variant) - known
    boardMissing = 5 - state.community.length    // Flop=2, Turn=1, River=0
    winCount = {seatIdx: 0.0 for each seat}

    for i in 0..N-1:
        sample = randomDraw(deck, boardMissing)
        finalBoard = state.community + sample
        scores = {}
        for s in activeSeats:
            scores[s.idx] = Evaluator.evaluate(s.holeCards, finalBoard, state.variant)
        winners = topScoreSeats(scores)
        for w in winners:
            winCount[w] += 1.0 / winners.length    // tie = 1/n_winners

    return {seatIdx: (winCount[seatIdx] / N) * 100.0 for each seat}
```

### 2.3 N (iteration) 결정 룰

| 시점 | 권고 N | 사유 |
|------|:------:|------|
| Pre-Flop (board=0) | 10,000 | 분산 가장 큼. PR #393 권고 |
| Flop (board=3) | 10,000 | 남은 turn+river=2장. 표본 공간 ≤ C(45,2)=990 → 사실상 결정적이지만 sample 안정성 위해 유지 |
| Turn (board=4) | 1,000 | 남은 river=1장. 표본 공간 ≤ 44 → N=44 로도 결정적 |
| River (board=5) | 1 | 결정적 (남은 카드 없음). single deterministic evaluation |
| Fold 발생 시 | 동일 N (현재 street 기준) | activeSeats 변경 → 재계산 트리거 |

> **WHY River=1**: River 이후 community 완성 → Monte Carlo 불필요. 직접 `Evaluator.evaluate` 1회 호출이면 충분.

---

## 3. 갱신 트리거 (Betting_System.md §8-1-3 정합)

### 3.1 트리거 매트릭스

| 시점 | Equity 재계산 | OutputEvent 발행 |
|------|:-------------:|:----------------:|
| Pre-Flop (hole cards 배분 직후) | ✓ | `EquityUpdated` |
| Flop (board 3장 공개) | ✓ | `EquityUpdated` |
| Turn (board 4장 공개) | ✓ | `EquityUpdated` |
| River (board 5장 공개) | ✓ (결정적) | `EquityUpdated` |
| 베팅 액션 — Fold | ✓ (활성 player 변경) | `EquityUpdated` |
| 베팅 액션 — Check/Bet/Raise/Call/All-in (Fold 외) | ✗ | (없음) |
| Run It Twice 활성 (RunItChoice dispatch) | ✓ (board A/B 별도 산정) | `EquityUpdated` (board별 dual payload) |
| Showdown (모든 Fold 발생 또는 River 종료) | ✗ (final result = `WinnerDetermined`) | (없음) |

### 3.2 OutputEvent

| Event | Payload | 발행 시점 |
|-------|---------|----------|
| `EquityUpdated` | `{equity: Map<int, double>, street: Street, boardIdx: int?}` | §3.1 갱신 트리거 매칭 시 |

`boardIdx` 필드:
- 일반 hand: `null`
- Run It Twice 활성: `0` (board 1) 또는 `1` (board 2) — board 별 별도 emit

---

## 4. Run It Twice 분기 처리

[Multi_Hand_v03.md §3](./Multi_Hand_v03.md) 의 RunItChoice 처리 후, board A / board B 각각 Equity 별도 산정.

### 4.1 처리 흐름

```
RunItChoice(times=2) dispatch 후 (river 이후):
  ↓
state.runItBoard2Cards 생성 (Multi_Hand_v03.md §3.3)
  ↓
EquityCalculator.computeForBoard(state, boardIdx=0)  # board 1 (state.community)
  → EquityUpdated(equity_A, boardIdx=0)
  ↓
EquityCalculator.computeForBoard(state, boardIdx=1)  # board 2 (state.runItBoard2Cards)
  → EquityUpdated(equity_B, boardIdx=1)
```

### 4.2 board 별 Equity 의미

| boardIdx | community 카드 | Equity 의미 |
|:--------:|---------------|-------------|
| 0 | `state.community` (legacy board) | board 1 에서 이길 확률 |
| 1 | `state.runItBoard2Cards` | board 2 에서 이길 확률 |

> **Overlay 표시**: `equity_percent` 가 2개 (player당) → RIVE_Standards Ch.2 #4 에 dual board 시각화 필요. Cycle 17 cascade 항목 (S2/S3 trigger).

### 4.3 미지원 (Cycle 17 범위 밖)

| 항목 | 사유 |
|------|------|
| `runItTimes=3` (RIT-3) Equity 3분할 | Multi_Hand_v03.md §3.8 의 Cycle 6+ deferred 항목 — 동일 후속 |
| Flop 단계 RIT 트리거 시 Equity 산정 | turn/river 모두 분할 패턴 — Multi_Hand_v03.md §7 후속 |

---

## 5. Hi-Lo Split variant 처리

### 5.1 분리 평가 룰

| 단계 | 동작 |
|------|------|
| 1. Hi 평가 | 5장 최강 핸드 (variant 룰: Omaha=must-use 2+3, Hold'em=any5) |
| 2. Lo 자격 검사 | Lo qualifier (8-or-better / no qualifier) — variant 별 |
| 3. Lo 평가 (자격자 존재 시) | 5장 최약 핸드 (A-5 lowball / 2-7 lowball) |
| 4. Equity 분배 | Hi winner 50% + Lo winner 50%. Lo 자격자 없으면 Hi 가 100% (scoop) |

### 5.2 sample 별 Equity 점수

```
for each sample:
    hiWinner = topHiScore(activeSeats, finalBoard, variant)
    loQualifiers = activeSeats.filter(s => qualifiesLo(s, finalBoard, variant))
    if loQualifiers.empty:
        winCount[hiWinner] += 1.0          # scoop → Hi 100%
    else:
        loWinner = topLoScore(loQualifiers, finalBoard, variant)
        winCount[hiWinner] += 0.5
        winCount[loWinner] += 0.5
```

### 5.3 변수 매핑

Overlay Rive `equity_percent` 는 Hi+Lo 합산값. 별도 `equity_hi_percent` / `equity_lo_percent` 변수는 Cycle 18+ cascade (RIVE_Standards 동기화 후속).

---

## 6. CALL 액션 visual_indicator=null flag (PR #393 cascade 권고)

### 6.1 룰

PR #393 §8-2 / Command_Center.md §16.9 정합 — Overlay 카테고리 #3 (액션 인디케이터) 시각 표식은 **4 종 액션 (체크 / 벳 / 레이즈 / 폴드)** 만 표시. CALL 액션은 별도 시각 indicator 없이 "Bet 매칭" 으로 통합.

| 액션 | visual_indicator | 의미 |
|------|:----------------:|------|
| Check | `"check"` | 패스 표식 |
| Bet | `"bet"` | 첫 베팅 표식 |
| Raise | `"raise"` | 더 걸기 표식 |
| Fold | `"fold"` | 포기 표식 |
| **Call** | **`null`** | **시각 표식 없음 — Bet 매칭으로 통합** (PR #393 cascade) |
| All-in | `"all_in"` | 전 칩 표식 + Player Dashboard emphasis (#1) |

### 6.2 Engine 구현

`PlayerAction` event 의 시리얼라이제이션에서 visual_indicator 필드를 다음과 같이 산정:

```dart
String? visualIndicatorOf(ActionType type) {
  switch (type) {
    case ActionType.check:  return "check";
    case ActionType.bet:    return "bet";
    case ActionType.raise:  return "raise";
    case ActionType.fold:   return "fold";
    case ActionType.allIn:  return "all_in";
    case ActionType.call:   return null;       // PR #393 cascade
  }
}
```

### 6.3 OutputEvent payload 확장

`PlayerActionPerformed` event payload 에 `visual_indicator` 필드 추가 (Overlay 직접 매핑용):

```jsonc
{
  "type": "PlayerActionPerformed",
  "seat_idx": 3,
  "action_type": "call",
  "amount": 200,
  "visual_indicator": null,    // PR #393 cascade — Call 은 null
  "last_action_enum": "call"   // S3 CC lastAction enum 정합
}
```

> **WHY null vs "call" 문자열**: Overlay Rive 변수가 `null` 을 받으면 indicator 시각 element 자체를 hidden 처리 → "Bet 매칭" 시각 통합 의도와 정합. 문자열 `"call"` 은 indicator 표시를 유도하므로 cascade 룰 위반.

---

## 7. 포지션 계산 룰 (PR #393 cascade 권고)

### 7.1 표준 6+ player 테이블 룰

PR #393 §8-1 / Foundation.md Ch.2 Scene 1 v2.0 정합 — Player Dashboard (#1) 의 포지션 표시 (SB/BB/D) 계산.

| 포지션 | seat index 산식 (`dealerSeat=d`) | 비고 |
|--------|----------------------------------|------|
| **D** (Dealer / Button) | `d` | 매 hand `dealerSeat` 자체 |
| **SB** (Small Blind) | `(d + 1) % activeSeatCount` | next non-sittingOut active seat |
| **BB** (Big Blind) | `(d + 2) % activeSeatCount` | next non-sittingOut after SB |
| **UTG** (Under The Gun) | `(d + 3) % activeSeatCount` | Pre-Flop 첫 행동자 |
| **MP** / **CO** / **HJ** | 6+ player 시 산정 | variant 별 분류 (engine 외부) |

> **active seat 정의**: `is_sittingOut=false` (Multi_Hand_State.md §1.2 정합). Fold 와 무관 — 포지션은 hand 시작 시점 결정 후 hand 내 불변.

### 7.2 Heads-up (2인) 특수 룰

Betting_System.md §2-3 정합 — 헤즈업에서는 dealer = SB.

| 포지션 | seat index 산식 |
|--------|----------------|
| **D = SB** (Dealer / Small Blind 통합) | `dealerSeat` |
| **BB** | `(d + 1) % 2` |

Pre-Flop 첫 행동자 = SB (dealer). Flop 이후 첫 행동자 = BB.

### 7.3 Straddle 활성 시 행동 순서

[Multi_Hand_v03.md §1](./Multi_Hand_v03.md) 정합 — straddle 활성 시 행동 순서 변경 (포지션 표시는 D/SB/BB 그대로, UTG = straddle 마지막).

### 7.4 OutputEvent payload — Player Dashboard 데이터

`HandStart` event 직후 emit 되는 `PositionsAssigned` event:

```jsonc
{
  "type": "PositionsAssigned",
  "dealer_seat": 1,
  "sb_seat": 2,
  "bb_seat": 3,
  "utg_seat": 4,
  "positions": {
    "1": "D",
    "2": "SB",
    "3": "BB",
    "4": "UTG"
  }
}
```

> Overlay Rive `position_label[i]` (Text) 변수 직접 매핑. PR #393 §1 Player Dashboard 4 필드 (Name + 국적 + 포지션 + 칩스택) 의 #3 정합.

---

## 8. Harness REST endpoint — GET /api/session/:id/equity

### 8.1 정합 (기존 endpoint)

[Harness_REST_API.md §2.8](../APIs/Harness_REST_API.md) 에 endpoint 이미 존재 (Cycle 17 이전부터):

```
GET /api/session/:id/equity
→ 200 { "equity": { "0": 0.68, "3": 0.21, "5": 0.11 } }
→ 200 { "equity": {} }  if activeSeats < 2
```

### 8.2 v17 확장 (본 정본 cascade)

본 SSOT 의 §2 (Monte Carlo) + §4 (Run It Twice) + §5 (Hi-Lo Split) 정합 위해 응답 스키마 확장:

```jsonc
GET /api/session/:id/equity?board=0&n=10000

{
  "equity": {
    "0": 68.0,           // float 0~100 (1자리 소수)
    "3": 21.0,
    "5": 11.0
  },
  "board_idx": 0,        // 0=board1, 1=board2 (Run It Twice 활성 시 별도 호출 필요)
  "iterations": 10000,
  "street": "flop",
  "active_seats": [0, 3, 5],
  "calculated_at": "2026-05-13T17:30:00Z"
}
```

### 8.3 Query parameters

| param | 타입 | 기본값 | 의미 |
|-------|------|--------|------|
| `board` | int | `0` | Run It Twice 활성 시 board index (0/1). 일반 hand 는 무시 |
| `n` | int | §2.3 룰 기준 자동 결정 | Monte Carlo iteration. 명시 시 override |

### 8.4 응답 스키마 변경 (backward compatible)

| 필드 | v16 이전 | v17 (본 정본) | 변경 유형 |
|------|---------|--------------|----------|
| `equity` value type | `double` (0.0~1.0) | **`double` (0.0~100.0)** | **Breaking** — 단위 변경 |
| `board_idx` | (없음) | `int` (0 or 1) | Additive |
| `iterations` | (없음) | `int` | Additive |
| `street` | (없음) | `string` | Additive |
| `active_seats` | (없음) | `int[]` | Additive |
| `calculated_at` | (없음) | `string` (ISO8601) | Additive |

> **Breaking 변경 사유**: PR #393 §8-1-2 step 6 = "equity_percent[i] (0~100 float, 1자리 소수)" 명시. 기존 0.0~1.0 단위는 `equity_percent` 명명과 충돌. Overlay Rive 직접 매핑 위해 단위 통일 필요.
>
> **이행 계획 (Cycle 17 → 18)**:
> 1. Cycle 17: 새 응답 스키마 default. legacy 호환 위해 `?format=ratio` query param 로 0.0~1.0 응답 유지 (deprecated 표기)
> 2. Cycle 18: legacy `?format=ratio` 제거 (1 cycle deprecation window)

---

## 9. 입력 / 출력 계약

### 9.1 함수 signature

```dart
class EquityCalculator {
  static Map<int, double> compute(
    GameState state, {
    int? iterations,           // null → §2.3 자동 결정
    int boardIdx = 0,          // Run It Twice 시 0 or 1
  });
}
```

### 9.2 사전 조건 (Precondition)

| 조건 | 미충족 시 동작 |
|------|---------------|
| `state.seats.where((s) => !s.isFolded && !s.isSittingOut).length >= 2` | `{}` 반환 (empty map) |
| `state.variant != null` | `ArgumentError` — variant 필수 |
| `state.community.length in [0, 3, 4, 5]` | `StateError` — 비정상 street |
| `boardIdx == 1 && state.runItBoard2Cards == null` | `StateError` — RIT 미활성 |

### 9.3 사후 조건 (Postcondition)

| 조건 | 검증 |
|------|------|
| `sum(result.values) ≈ 100.0` (±0.1) | tie 분배 후 총합 보존 |
| `result.keys ⊆ activeSeats` | folded/sittingOut seat 미포함 |
| `result.values all >= 0.0 && <= 100.0` | 백분율 범위 |

---

## 10. Variant matrix — 22종 게임 × Equity 평가 룰

### 10.1 매핑 테이블

| # | 게임 | Hi 룰 | Lo 룰 | Deck | 평가 방식 |
|:-:|------|-------|-------|------|----------|
| 0 | Texas Hold'em | any 5 of 7 | — | 52 | Standard Hi |
| 1 | 6+ Hold'em (S>T) | any 5 of 7 | — | **36** | Short Deck Hi (변형 hand rank) |
| 2 | 6+ Hold'em (T>S) | any 5 of 7 | — | 36 | Short Deck Hi |
| 3 | Pineapple | any 5 of 8 (3 hole + 5 board) | — | 52 | Standard Hi |
| 4 | Omaha | **must-use 2 hole + 3 board** | — | 52 | Omaha Hi |
| 5 | Omaha Hi-Lo | 2+3 Hi | 2+3 Lo (8-or-better) | 52 | Hi-Lo Split |
| 6 | Five Card Omaha | must-use 2+3 (5 hole) | — | 52 | Omaha Hi (5 hole variant) |
| 7 | Five Card Omaha Hi-Lo | 2+3 Hi | 2+3 Lo (8-or-better) | 52 | Hi-Lo Split |
| 8 | Six Card Omaha | must-use 2+3 (6 hole) | — | 52 | Omaha Hi (6 hole) |
| 9 | Six Card Omaha Hi-Lo | 2+3 Hi | 2+3 Lo (8-or-better) | 52 | Hi-Lo Split |
| 10 | Courchevel | must-use 2+3 + 1 flop preflop reveal | — | 52 | Omaha Hi (Courchevel) |
| 11 | Courchevel Hi-Lo | 2+3 Hi | 2+3 Lo | 52 | Hi-Lo Split |
| 12 | Five Card Draw | 5 hole best | — | 52 | Draw — **Equity 미산정** (§10.2) |
| 13 | 2-7 Single Draw | — | 5 hole worst (2-7) | 52 | Draw — Equity 미산정 |
| 14 | 2-7 Triple Draw | — | 5 hole worst (2-7) | 52 | Draw — Equity 미산정 |
| 15 | A-5 Triple Draw | — | 5 hole worst (A-5) | 52 | Draw — Equity 미산정 |
| 16 | Badugi | — | 4 hole rainbow lowball | 52 | Draw — Equity 미산정 |
| 17 | Badeucy | mixed | mixed | 52 | Draw — Equity 미산정 |
| 18 | Badacey | mixed | mixed | 52 | Draw — Equity 미산정 |
| 19 | 7-Card Stud | 5 of 7 hole | — | 52 | 3rd Street+ (공개 카드 기반) |
| 20 | 7-Card Stud Hi-Lo | 5 of 7 Hi | 5 of 7 Lo (8-or-better) | 52 | Hi-Lo Split |
| 21 | Razz | — | 5 of 7 worst (A-5) | 52 | Stud Lo |

### 10.2 Draw 계열 Equity 미산정 사유

Draw 게임은 draw 라운드 중 미공개 hole cards 가 player 별로 다름 (replace 카드 미지). Monte Carlo 표본 공간이 폭증하고 player 의 전략(어떤 카드를 버릴지)에 따라 결과가 결정 → Engine 차원에서 Equity 신뢰성 없음.

> **대안 표시**: Draw 진행 중에는 Equity 대신 `hand_strength_text` (예: "Drawing to Flush") 만 표시 — RIVE_Standards Ch.15 정합. Cycle 18+ cascade.

### 10.3 Seven Card 계열 처리

3rd Street 부터 공개 카드 발생 → Equity 산정 가능. 단, 비공개 hole cards (1장 또는 2장) 는 random sampling.

---

## 11. 검증 (Cycle 17 예정)

### 11.1 테스트 매트릭스

| 항목 | 위치 | 예상 케이스 수 |
|------|------|:--------------:|
| `dart test test/equity_calculator_test.dart` | `team3-engine/ebs_game_engine/test/equity_calculator_test.dart` | 20+ (variant × street) |
| `dart test test/harness/equity_endpoint_test.dart` | `team3-engine/ebs_game_engine/test/harness/equity_endpoint_test.dart` | 6 (legacy/v17 호환, RIT board0/1, headsup, activeSeats<2) |
| Full regression (`dart test`) | — | EXIT=0 |

### 11.2 정합 검증 케이스

| 케이스 | 검증 |
|--------|------|
| Pre-Flop Hold'em 6인 → equity 합 ≈ 100% | §9.3 sum 검증 |
| Flop Omaha 4인 → must-use 2+3 정확성 | §10.1 variant 룰 |
| Run It Twice board0/1 별도 호출 | §4 boardIdx 분기 |
| Hi-Lo Split Omaha → scoop vs split | §5.2 sample 별 분배 |
| Fold 발생 후 재호출 → activeSeats 갱신 | §3.1 트리거 |
| Headsup 2인 → equity 100% 합산 | §1.2 minimum 충족 |

---

## 12. 코드 위치 (file:line SSOT)

| 책임 | 코드 위치 (예정 — Cycle 17 구현) |
|------|---------------------------------|
| `EquityCalculator` 클래스 | `lib/equity/equity_calculator.dart` |
| `EquityCalculator.compute` 정적 메서드 | `lib/equity/equity_calculator.dart` |
| Variant 별 Evaluator 분기 | `lib/equity/evaluator_dispatch.dart` |
| Hi-Lo Split 분리 평가 | `lib/equity/hilo_split.dart` |
| `EquityUpdated` event class | `lib/core/actions/event.dart` |
| `PositionsAssigned` event class | `lib/core/actions/event.dart` |
| `visual_indicator` serializer | `lib/core/actions/event_serializer.dart` |
| harness 라우팅 (`GET /equity` v17 응답) | `lib/harness/server.dart` |

> 본 SSOT 작성 시점(2026-05-13)에는 구현 미완. Cycle 17 구현 PR 에서 위 경로 생성 + 본 SSOT 의 `reimplementability: PENDING` → `PASS` 갱신.

---

## 13. 미해결 (Cycle 17 이후 후속)

| 항목 | 우선순위 | 비고 |
|------|:--------:|------|
| Draw 계열 `hand_strength_text` 산정 | MID | RIVE_Standards Ch.15 정합 — Cycle 18 cascade |
| RIT-3 Equity 3분할 | LOW | Multi_Hand_v03.md §7 후속 의존 |
| `equity_hi_percent` / `equity_lo_percent` 분리 변수 | LOW | RIVE_Standards 동기화 후속 |
| Out 개수 계산 (`outs_count` 변수) | LOW | Foundation.md v2.0 에서 "아웃츠 → Equity 흡수" 결정 → 별도 변수 deferred |
| `Calculation latency budget` SLA | MID | N=10,000 × 6 player @ Hold'em 기준 99p latency 측정 필요 |

---

## 14. Cross-stream 핸드오프

S8 (Game Engine) 의 권한은 `docs/2. Development/2.3 Game Engine/**` 만. 본 정본의 cascade 는 다음 stream 으로 전파:

| stream | trigger 작업 |
|--------|-------------|
| **S2 Lobby** | RIVE_Standards Ch.2 #4 `equity_percent` (Number) 변수 정합. RIT 활성 시 dual board 시각화 |
| **S3 CC** | Action Indicator 4종 (Check/Bet/Raise/Fold) ↔ `visual_indicator` field 정합. CALL = `null` 처리 |
| **S7 Backend** | `equity_percent` 가 DB 영속화 대상인지 결정 (현재 transient 가정). `BlindStructure` 테이블 추가는 별개 cascade (PR #393 §8-2) |
| **S10-A** | Type B (기획 공백) → Type A (engine 정본 작성) 분류 갱신 |

**broker MCP cascade emit**:

```
cascade:engine-equity-spec
  ↓ payload
{
  "stream": "S8",
  "spec_file": "docs/2. Development/2.3 Game Engine/Rules/Equity_Calculator.md",
  "derivative_of": "docs/1. Product/Game_Rules/Betting_System.md#8-1",
  "pr_origin": 393,
  "type_classification": "B→A",   // 기획 공백 → engine 정본 작성
  "downstream_triggers": ["S2", "S3", "S7", "S10-A"]
}
```

---

## 15. Changelog

| 날짜 | 버전 | 변경 내용 | 변경 유형 | 결정 근거 |
|------|------|-----------|----------|----------|
| 2026-05-13 | v1.0 | 최초 작성 (PR #393 Cycle 17 Wave 2.3 cascade) | - | Betting_System.md §8-1 Type B 기획 공백 해소. Monte Carlo 6단계 / RIT 분기 / Hi-Lo Split / CALL visual_indicator=null / 포지션 계산 룰 정본화 |
