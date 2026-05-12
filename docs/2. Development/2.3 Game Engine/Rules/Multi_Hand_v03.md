---
title: Multi-Hand v03 — straddle_seat 이동 + ante_override + run_it_twice 분할 pot (Cycle 6)
owner: team3 (S8 Cycle 6)
tier: contract
legacy-id: API-04.6
last-updated: 2026-05-12
last-synced: 2026-05-12
reimplementability: PENDING
reimplementability_checked: 2026-05-12
reimplementability_notes: "v02 SSOT (Multi_Hand_State.md) 위에 v03 룰 3종 추가. derivative-of 우선순위 위반 없음."
related-issue: 310
related-cycle: 6
related-spec: ./Multi_Hand_State.md
derivative-of: ./Multi_Hand_State.md
if-conflict: derivative-of takes precedence
---

# Multi-Hand v03 — straddle_seat 이동 + ante_override + run_it_twice 분할 pot

## 개요

Cycle 5 v02 (`Multi_Hand_State.md`) 의 dealer/SB/BB rotation 위에 다음 3개 룰을 추가한다.

| 룰 | 효과 | 발동 조건 |
|------|------|----------|
| straddle_seat | hand-to-hand rotation 시 straddleSeat 도 같이 회전 | `straddleEnabled=true && straddleSeat != null` |
| ante_override | 다음 hand 의 ante amount 일회성/영구 변경 | `AnteOverride` 이벤트 수신 |
| run_it_twice | river 이후 all-in 시 pot 1/2 분할 + 각 board 별 winner 산정 | `runItTimes=2`, eligible 2+ seats |

> **연관 Issue**: [#310](https://github.com/garimto81/ebs_github/issues/310) S8 Cycle 6 multi-hand v03 룰.

> **WHY v02 위에 incremental**: rotation SSOT 인 `Multi_Hand_State.md` 의 §1.2 SB/BB 알고리즘은 그대로 유지되고, straddle 이 활성된 경우에만 straddleSeat 도 dealer offset 만큼 회전 (정합 위반 없음).

---

## 1. straddle_seat 활성 시 SB/BB 이동

### 1.1 룰

`ManualNextHand` 처리 시점에 `straddleEnabled == true` 이고 `straddleSeat != null` 이면:

| 조건 | 동작 |
|------|------|
| 활성 seat ≥ 3 | dealer/SB/BB 표준 회전 (v02 §1.2 동일) + `straddleSeat` 은 next non-sittingOut seat 으로 회전 |
| heads-up (활성 seat = 2) | straddle 무효화 (`straddleEnabled=false`, `straddleSeat=null`) — dealer=SB 표준 룰 적용 |
| 활성 seat ≤ 1 | rotation 자체 무효 (v02 §1.2 동일) |

### 1.2 의도

`straddleSeat` 은 raw seat index. hand-to-hand rotation 시에도 "특정 active seat" 라는 의미가 유지되도록 dealer 와 동일한 방식으로 1칸 회전. heads-up 진입 시 straddle 무효화 (PokerGFX/WSOP 표준).

### 1.3 입력 / 출력 계약

| 항목 | 입력 (pre) | 출력 (post) |
|------|-----------|-------------|
| `dealerSeat` | d | next non-sittingOut after d (v02 동일) |
| `sbSeat` | (이전) | v02 §1.2 적용 결과 |
| `bbSeat` | (이전) | v02 §1.2 적용 결과 |
| `straddleEnabled` | `true` | `true` (heads-up 진입 시 `false`) |
| `straddleSeat` | s | next non-sittingOut after s (활성 seat ≥ 3) / `null` (heads-up) |

### 1.4 round-robin 시나리오

```
seats: 6 active, hand 1 dealer=0 SB=1 BB=2 straddle=3
  ↓ POST /next-hand
hand 2: dealer=1 SB=2 BB=3 straddle=4
  ↓ POST /next-hand
hand 3: dealer=2 SB=3 BB=4 straddle=5
  ↓ POST /next-hand
hand 4: dealer=3 SB=4 BB=5 straddle=0
```

### 1.5 heads-up 진입 시나리오

```
seats: 3 active (0/1/2), hand 1 dealer=0 SB=1 BB=2 straddle=null
  ↓ seat 0 sittingOut + POST /next-hand
hand 2: dealer=1 (=SB) BB=2 straddle=null (heads-up; straddleEnabled 무효)
```

---

## 2. ante_override (정상 cycle vs override)

### 2.1 룰

새 이벤트 `AnteOverride { int amount, int? type }` 도입. 다음 hand 의 ante amount 및 (선택) type 을 변경:

| 입력 | 동작 |
|------|------|
| `AnteOverride(amount=A, type=T)` 가 직전 hand 종료 후 dispatch | `state.anteAmount=A`, `state.anteType = T ?? state.anteType` |
| `AnteOverride` 없음 | 기존 `anteAmount` / `anteType` 유지 (정상 cycle) |
| `amount <= 0` | event 무시 (validation) |

### 2.2 동작 흐름

```
hand N 종료
  ↓
[AnteOverride(amount=100, type=2)]  ← optional dispatch
  ↓
[ManualNextHand]
  ↓
hand N+1 시작 → HandStart 처리 시 anteAmount=100 으로 ante 처리
  ↓
hand N+1 종료
  ↓
[ManualNextHand]  ← AnteOverride 없음
  ↓
hand N+2 → anteAmount=100 그대로 유지 (override 는 영구적, but 다음 override 까지)
```

> **WHY 영구적**: blind level 증가/감소 시 외부 컨트롤러가 명시적으로 dispatch 하는 모델. 자동 reset 모델은 별도 룰 (Tournament Mode) 로 분리.

### 2.3 입력 / 출력 계약

| 항목 | 입력 (pre) | 출력 (post) |
|------|-----------|-------------|
| `anteAmount` | a | `event.amount` (양수만 허용; 0 또는 음수 → 무시) |
| `anteType` | t | `event.type ?? t` |

### 2.4 OutputEvent

| Event | Payload | 비고 |
|-------|---------|------|
| (none) | — | ante 변경은 street 전환 없음. internal state 만 갱신 (다음 HandStart 시 ante 처리에서 자연스럽게 반영) |

---

## 3. run_it_twice 분할 pot 정합

### 3.1 룰

river 이후 (community.length == 5) 에 `RunItChoice { times: 2 }` 가 dispatch 되면:

1. `runItBoard2Cards` 필드에 board 2 community 5장 생성 (flop 3장 공유 + 새 turn/river deal)
2. pot/seat 은 **건드리지 않음** (legacy 호환)
3. 별도 helper `Engine.runItAwards(state)` 로 board1/board2 winners 합산 결과 산출
4. 외부 코드가 helper 결과를 명시 `PotAwarded` event 로 적용

### 3.2 분할 알고리즘 (helper 내부)

```
totalPot = state.pot.main + sum(state.pot.sides[*].amount)
board2Pot = totalPot ~/ 2
board1Pot = totalPot - board2Pot     # 홀수 chip 흡수 (WSOP Rule 73)
```

### 3.3 board 별 community 카드 deal

| board | community 구성 |
|-------|----------------|
| board 1 | `state.community` (river 까지 dealt) — 변경 없음 |
| board 2 | `state.community` 의 flop 3장 공유 + `deck.draw()` 로 새 turn/river 2장 deal → `runItBoard2Cards` 보존 |

> **WHY flop 공유**: PokerGFX/WSOP 표준 패턴. flop 까지는 결정된 카드, turn/river 만 새로 deal. flop 시점 트리거는 후속 issue (Cycle 6 범위 밖).

### 3.4 winner 산출 (helper `Engine.runItAwards`)

```
board1Awards = Showdown.evaluate(seats, community=state.community, pots=board1Pots, variant, dealerSeat)
board2Awards = Showdown.evaluate(seats, community=state.runItBoard2Cards, pots=board2Pots, variant, dealerSeat)

return merge(board1Awards, board2Awards)   # seat index 별 합산
```

### 3.5 OutputEvent

| Event | Payload | 비고 |
|-------|---------|------|
| `StateChanged` | `fromState=<prev>`, `toState=runItMultiple` | RunItChoice 처리 직후 (기존 동작) |
| `WinnerDetermined` | `awards={seatIdx: totalAmount}` | 외부에서 `PotAwarded(runItAwards)` 적용 시 emit |

### 3.6 입력 / 출력 계약

| 항목 | 입력 (pre) | 출력 (post — RunItChoice) | 출력 (post — PotAwarded) |
|------|-----------|---------------------------|--------------------------|
| `runItTimes` | `null` 또는 1 | 2 (v03 범위) | 변경 없음 |
| `community` | river 까지 dealt (5장) | 변경 없음 | 변경 없음 |
| `runItBoard2Cards` | `null` | board 2 community (length = 5) | 변경 없음 |
| `pot.main` | T | 변경 없음 | 0 |
| `seat.stack` (winners) | 기존 | 변경 없음 | + 분할 award |

### 3.7 사용 예시 (harness / scenario)

```dart
// 1) RunItChoice 발동
state = Engine.apply(state, const RunItChoice(2));
// 2) Helper 로 awards 계산
final awards = Engine.runItAwards(state)!;
// 3) PotAwarded 로 실제 지급
state = Engine.apply(state, PotAwarded(awards));
```

> **legacy 호환**: 외부가 awards 를 미리 알면 step 2 생략 후 직접 `PotAwarded(custom)` 가능. 기존 scenario YAML 패턴 (`run_it_choice + pot_awarded` 명시) 그대로 동작.

### 3.8 미지원 (Cycle 6 범위 밖)

| 항목 | 사유 |
|------|------|
| `runItTimes=3` (RIT-3) | board 분할 알고리즘 동일 패턴이나 별도 issue 로 분리 |
| flop 단계 트리거 RIT (community<5) | turn/river 모두 분할하는 표준 패턴 — 별도 룰 필요. 현재는 v02 legacy 동작 (state 전환만) |

---

## 4. POST /api/session response 검증

### 4.1 next-hand response 필드 (v03 추가)

`POST /api/session/{sessionId}/next-hand` 응답에 다음 필드 추가:

```jsonc
{
  "sessionId": "...",
  "handNumber": 2,           // v02 동일
  "dealerSeat": 1,           // v02 동일
  "sbSeat": 2,               // v02 동일
  "bbSeat": 3,               // v02 동일
  "straddleEnabled": true,   // v03 NEW
  "straddleSeat": 4,         // v03 NEW (heads-up 진입 시 null)
  "anteAmount": 100,         // v03 NEW (override 후 값 반영)
  "anteType": 2,             // v03 NEW
  "runItTimes": null,        // v03 NEW
  "street": "idle",
  "seats": [...],
  "pot": {"main":0,"total":0,"sides":[]}
}
```

### 4.2 정합 케이스

| 케이스 | 검증 |
|--------|------|
| straddle 활성 + non-headsup → next-hand | `straddleSeat` 회전 결과 정합 |
| straddle 활성 + headsup 진입 | `straddleEnabled=false`, `straddleSeat=null` |
| `AnteOverride` 후 next-hand | `anteAmount` = override 값 |
| `runItTimes=2` 후 showdown | `WinnerDetermined.awards` 합산 = totalPot |

---

## 5. 검증 (Cycle 6)

| 항목 | 결과 | 위치 |
|------|:----:|------|
| `dart test test/multi_hand_v03_test.dart` (18 cases) | ✅ ALL PASS | `team3-engine/ebs_game_engine/test/multi_hand_v03_test.dart` |
| `dart test test/harness/next_hand_v03_endpoint_test.dart` (3 cases) | ✅ ALL PASS | `team3-engine/ebs_game_engine/test/harness/next_hand_v03_endpoint_test.dart` |
| `dart test test/harness/next_hand_endpoint_test.dart` (4 cases, v02 회귀) | ✅ ALL PASS | `team3-engine/ebs_game_engine/test/harness/next_hand_endpoint_test.dart` |
| Full regression (`dart test`) | ✅ EXIT=0 (전체 PASS) | — |
| `dart analyze lib/engine.dart lib/core/state/game_state.dart lib/core/actions/event.dart lib/harness/*.dart` | ✅ 0 신규 issue (기존 unused_import warning 1 만 존재) | — |

> **재실행 명령**:
> ```bash
> cd team3-engine/ebs_game_engine
> dart test test/multi_hand_v03_test.dart
> dart test
> ```

---

## 6. 코드 위치 (file:line SSOT)

| 책임 | 코드 위치 |
|------|----------|
| `AnteOverride` event class | `lib/core/actions/event.dart` |
| `_handleAnteOverrideFull` reducer | `lib/engine.dart` |
| `_handleManualNextHandFull` (v03 straddle 추가) | `lib/engine.dart` |
| `_handleRunItChoiceFull` (v03 분할 pot 처리) | `lib/engine.dart` |
| `runItBoard2Cards` 신규 필드 | `lib/core/state/game_state.dart` |
| harness 라우팅 (`POST /next-hand` response 확장) | `lib/harness/server.dart` |

---

## 7. 미해결 (Cycle 6 이후 후속)

| 항목 | 우선순위 | 비고 |
|------|:--------:|------|
| `runItTimes=3` (RIT-3) | LOW | board 3개 분할. 별도 issue 필요 |
| flop 단계 RIT 트리거 | LOW | turn+river 모두 분할하는 표준 패턴 |
| Tournament Mode (blind level 자동 증가) | LOW | `AnteOverride` 의 자동화 버전 |
| Double Straddle (UTG+1 straddle) | LOW | 다중 straddleSeats 지원 |

---

## 8. Game_Rules cross-stream 핸드오프

S8 (Game Engine) 의 권한은 `docs/2. Development/2.3 Game Engine/**` 만. `docs/1. Product/Game_Rules/Betting_System.md §7-5 straddle_seat 명세` 보강은 Game Rules 소유 stream 의 책임이다.

**핸드오프 메시지** (broker MCP cascade 또는 GitHub Issue):

```
TO: stream owning docs/1. Product/Game_Rules/**
FROM: S8 Engine
SUBJECT: Betting_System.md §7-5 straddle_seat 보강 요청 (cascade:engine-v03-ready 의존)

요청 사항:
  §7-5 에 다음 룰 명세 추가:
    - straddle_seat = "임의 active seat" (UTG straddle / Mississippi straddle / Button straddle 모두 포함)
    - hand-to-hand rotation 시 다음 active seat 으로 1칸 회전
    - heads-up 진입 시 straddle 무효화
    - amount = 2 × bbAmount (현재 engine 구현과 일치)

이 SSOT (Multi_Hand_v03.md) 가 derivative-of 우선순위 위반 없는 정본 명세.
```

---

## 9. Changelog

| 날짜 | 버전 | 변경 내용 | 변경 유형 | 결정 근거 |
|------|------|-----------|----------|----------|
| 2026-05-12 | v1.0 | 최초 작성 (issue #310 Cycle 6) | - | v02 SSOT 위에 straddle_seat 이동 / ante_override / run_it_twice 분할 pot 3종 추가 |
