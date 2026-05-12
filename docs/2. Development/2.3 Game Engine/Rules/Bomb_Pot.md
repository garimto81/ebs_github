---
title: Bomb Pot — 강제 ante + preflop 스킵 (Cycle 7 v04)
owner: team3 (S8 Cycle 7)
tier: contract
legacy-id: BS-06-04
last-updated: 2026-05-12
last-synced: 2026-05-12
reimplementability: PASS
reimplementability_checked: 2026-05-12
reimplementability_notes: "BombPotConfig event + _startHandFull bomb 분기 + 코드 file:line + dart test 케이스 명세 + harness toJson 검증. Engine 90% 구현 (v03 이전); 본 spec 은 contract SSOT 화."
related-issue: 327
related-cycle: 7
related-spec: Engine_Defaults.md, Multi_Hand_State.md
---

# Bomb Pot — 강제 ante + preflop 스킵

## 개요

Bomb Pot 은 다음 핸드 시작 시 모든 active seat 으로부터 `bombPotAmount` 만큼 ante 를 강제로 받고 preflop 을 건너뛰어 직접 flop 으로 진입하는 룰. operator/dealer 가 `BombPotConfig(amount)` event 로 다음 핸드 1회 활성화한다.

> **목적**: action 증가 + pot 크기 부풀리기. 캐주얼/홈게임 표준 룰.
>
> **연관 Issue**: [#327](https://github.com/garimto81/ebs_github/issues/327) S8 Cycle 7 v04.

---

## 1. BombPotConfig 이벤트 동작 규칙

```
[hand_end / idle state] --(BombPotConfig amount=N)--> [bombPotEnabled=true, bombPotAmount=N]
[next hand start (HandStart)] --(bomb 분기)--> [모든 active seat ante N → pot, street=flop]
```

### 1.1 입력 / 출력 계약

| 항목 | 입력 (pre) | 출력 (post) |
|------|-----------|-------------|
| `bombPotEnabled` | `false` | `true` |
| `bombPotAmount` | `null` | `N` (amount, > 0 필수) |
| `amount <= 0` | reject | state 변경 없음 (no-op) |

### 1.2 다음 핸드 시작 시 분기 (HandStart 처리)

`bombPotEnabled == true` 이고 `bombPotAmount > 0` 일 때 `_startHandFull` 의 ante 단계 후 분기:

```
for each seat where (isActive || isAllIn):
  post = min(bombPotAmount, seat.stack)
  seat.stack -= post
  pot.main += post
  if seat.stack == 0 and seat.status != allIn:
    seat.status = allIn

betting.currentBet = 0
betting.minRaise = bbAmount
betting.lastRaise = 0
betting.lastAggressor = -1
betting.actedThisRound.clear()
betting.bbOptionPending = false

for each seat: seat.currentBet = 0
street = flop
actionOn = StreetMachine.firstToAct(flop state)
```

> **중요**: bomb pot 분기는 SB/BB blind 미부과 + preflop 미진행 + 직접 flop. 표준 hold'em 의 preflop betting round 가 통째로 스킵된다.

### 1.3 다음 핸드 자동 reset

Cycle 5 v02 `Multi_Hand_State.md` §1.1: `ManualNextHand` 처리 시 `bombPotEnabled = false` 로 reset. 즉 bomb pot 은 **단발성** — operator 가 매번 새 `BombPotConfig` 를 발행해야 한다.

### 1.4 OutputEvent

| Event | Payload | 비고 |
|-------|---------|------|
| `StateChanged` | `fromState=<prev>`, `toState=flop` | bomb 분기 진입 시 |
| `PotUpdated` (간접) | bomb pot 누적 후 mainPot 갱신 | `_startHandFull` 후속 처리 |

> 별도 `BombPotActivated` OutputEvent **없음** — `StateChanged` 의 `toState=flop` 이 idle→flop 직진을 시그널한다.

---

## 2. 코드 위치 (file:line SSOT)

| 책임 | 위치 |
|------|------|
| `BombPotConfig` event class | `team3-engine/ebs_game_engine/lib/core/actions/event.dart:55-58` |
| `_handleBombPotConfigFull` reducer | `team3-engine/ebs_game_engine/lib/engine.dart:734-740` |
| `_startHandFull` bomb 분기 | `team3-engine/ebs_game_engine/lib/engine.dart:387-436` |
| `GameState.bombPotEnabled / bombPotAmount` 필드 | `team3-engine/ebs_game_engine/lib/core/state/game_state.dart:44-45` |
| `Session.toJson()` bombPot* 노출 | `team3-engine/ebs_game_engine/lib/harness/session.dart:100-101` |
| 다음 핸드 reset (`Multi_Hand_State.md` §1.1) | `team3-engine/ebs_game_engine/lib/engine.dart:884-...` (`_handleManualNextHandFull`) |

---

## 3. 검증 시나리오 (dart test 명세 — impl PR 에서 실행)

### 3.1 4-seat 표준 bomb pot

```
state: 4 seats, stacks=[1000,1000,1000,1000], bbAmount=10, street=idle, handInProgress=false
1. Engine.applyFull(state, BombPotConfig(50))
   → state.bombPotEnabled == true, state.bombPotAmount == 50
2. Engine.applyFull(state, HandStart(dealerSeat=0, blinds={1:5, 2:10}))
   → 모든 4 seats: stack=950, pot.main=200, street=flop, actionOn=(dealer+1 first active)
```

### 3.2 short-stack all-in by bomb

```
state: 4 seats, stacks=[1000,1000,1000,30], bombPotAmount=50
HandStart → seat 3: post=30, stack=0, status=allIn. pot.main=180
```

### 3.3 BombPotConfig amount<=0 reject

```
Engine.applyFull(state, BombPotConfig(0)).state == state  (no change)
Engine.applyFull(state, BombPotConfig(-5)).state == state
```

### 3.4 자동 reset 검증

```
state: bombPotEnabled=true, bombPotAmount=50, street=idle, handInProgress=false
Engine.applyFull(state, ManualNextHand())
  → state.bombPotEnabled == false
  → state.bombPotAmount: 보존(=50) 또는 null 중 하나. Multi_Hand_State.md §1.1 의 "bombPotEnabled=false" 만 강제 (amount 는 미정의 — 다음 BombPotConfig 가 덮어쓰므로 무관).
```

### 3.5 Harness `POST /api/session` response 검증

```http
POST /api/session
  → bombPotEnabled: false (default)
  → bombPotAmount: null (default)

POST /api/session/{id}/event {"type":"bomb_pot_config","amount":50}
  → bombPotEnabled: true
  → bombPotAmount: 50
```

---

## 4. 정합 정책 (Engine_Defaults.md §3 정렬)

| 충돌 시 우선순위 | 근거 |
|-----------------|------|
| 1. `lib/engine.dart:387-436` 의 실제 구현 | 정본 (이 문서가 derive) |
| 2. 본 `Rules/Bomb_Pot.md` | Engine 코드 derive snapshot |
| 3. 기획서 `Game_Rules/Betting_System.md` §7-6 | 사용자/외부 인계 표현 — 본 문서와 정합 강제 |
| 4. team1/team4 UI 표현 | Engine SSOT 따름 |

---

## 5. 미해결 (v04 이후 후속)

| 항목 | 우선순위 | 비고 |
|------|:--------:|------|
| `bombPotMultiplier` 도입 (예: 2BB / 5BB / 10BB) | LOW | 현재는 raw amount. multiplier 옵션은 별도 ProductPM 결정 |
| `BombPotActivated` 전용 OutputEvent 추가 | LOW | 현재 `StateChanged(toState=flop)` 으로 대체. UX 가독성 필요 시 별도 OE 신설 |
| 연속 bomb pot mode ("매 핸드 bomb") | LOW | 자동 round-robin 옵션. 현재는 매번 `BombPotConfig` 재발행 필요 |

---

## 6. Changelog

| 날짜 | 버전 | 변경 내용 | 변경 유형 | 결정 근거 |
|------|------|-----------|----------|----------|
| 2026-05-12 | v1.0 | 최초 작성 (issue #327 Cycle 7 v04 — engine 기존 구현의 contract SSOT 화) | - | Cycle 7 v04 deeper game 룰 명세 |
