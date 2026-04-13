# QA-GE-08 — Bet Structure (NL / FL / PL) 검증

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Master Plan §8.9 확장 — NL/FL/PL 3종 TC 상세화 |
| 2026-04-09 | TC 추가 | 코드 리뷰 발견: TC-G1-007-01d (Raise 음수 스택 방어) |

---

## 개요

Game Engine의 bet_structure 3종(No Limit, Fixed Limit, Pot Limit)에 대해 베팅 금액 유효성, 최소/최대 제한, raise 규칙을 검증한다.

---

## Bet Structure 매트릭스

| bet_structure | 코드 | 최소 베팅 | 최대 베팅 | Raise 규칙 | Cap |
|:------------:|:----:|----------|----------|-----------|-----|
| No Limit | 0 | BB | 전 스택 | min_raise = last_raise_increment | 없음 |
| Fixed Limit | 1 | small bet / big bet | small bet / big bet | 고정 금액만 | 1 bet + 3 raises (Heads-Up 제외) |
| Pot Limit | 2 | BB | 현재 Pot | min_raise = BB, max = pot + call + raise | 없음 |

---

## TC 목록

### TC-G1-007-01: No Limit — 기본 베팅 검증

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 1 |
| **우선순위** | P0 |
| **Players** | 6인 (P0~P5), stack=10000 each, BB=100, SB=50, Dealer=P0 |
| **Hole Cards** | N/A (베팅 로직 검증) |
| **Board** | N/A |
| **Actions** | PRE_FLOP: P3(UTG) Bet(200) → P4 Raise(400) → P5 Raise(800) → P0 Call(800) → P1 Fold → P2 Call(800) → P3 Call(800) → P4 Call(800) |
| **기대 결과** | 각 Raise는 최소 이전 raise increment 이상. P3 Bet(200) = 2x BB. P4 Raise(400) = increment 200. P5 Raise(800) = increment 400. 유효한 시퀀스 |
| **판정 기준** | 모든 Raise 수락. `last_raise_increment` 추적 정확 |
| **참조** | BS-06-02 §1, PRD-GAME-04 |

### TC-G1-007-01a: No Limit — 최소 베팅 미만 거부

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 1 |
| **우선순위** | P0 |
| **Players** | 6인, stack=10000 each, BB=100, Dealer=P0 |
| **Hole Cards** | N/A |
| **Board** | N/A |
| **Actions** | PRE_FLOP: P3(UTG) 시도 Bet(50) — BB(100) 미만 |
| **기대 결과** | Engine 거부. 에러: `InvalidBetAmount`, 최소 = 100 |
| **판정 기준** | `action.rejected == true`, `action.reason == "below_minimum"`, GameState 변동 없음 |
| **참조** | BS-06-02 §1 |

### TC-G1-007-01b: No Limit — 연속 Raise min_raise 추적

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 6인, stack=50000 each, BB=100, Dealer=P0 |
| **Hole Cards** | N/A |
| **Board** | N/A |
| **Actions** | PRE_FLOP: P3 Raise(300, increment=200) → P4 Raise(700, increment=400) → P5 시도 Raise(900) — min_raise = 700+400=1100 미만 |
| **기대 결과** | P3 Raise(300) 수락: BB(100) + increment(200) = 300. P4 Raise(700) 수락: 300 + increment(400) = 700. P5 Raise(900) 거부: 최소 = 700 + 400 = 1100 |
| **판정 기준** | P5 거부, `last_raise_increment == 400`, 최소 Raise = 1100 |
| **참조** | BS-06-02 §1 |

### TC-G1-007-01c: No Limit — Short All-In과 Re-Open

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 4인, P0(10000), P1(10000), P2(150), P3(10000), BB=100, Dealer=P0 |
| **Hole Cards** | N/A |
| **Board** | N/A |
| **Actions** | PRE_FLOP: P3 Raise(300) → P0 Call(300) → P1 Call(300) → P2 All-In(150, short) |
| **기대 결과** | P2의 All-In(150)은 min_raise(200) 미달. 액션이 P3에게 돌아와도 Re-Raise 불가 (re-open 안 됨). P3/P0/P1은 Call/Fold만 가능 |
| **판정 기준** | P2 All-In 수락 (All-In은 항상 수락). 이후 P3 액션 옵션에 Raise 없음 (`canRaise == false`) |
| **참조** | BS-06-02 §1 |

### TC-G1-007-02: Fixed Limit — 기본 베팅 검증

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 6인, stack=10000 each, small_bet=100, big_bet=200, SB=50, BB=100, Dealer=P0 |
| **Hole Cards** | N/A |
| **Board** | N/A |
| **Actions** | PRE_FLOP: P3 Raise(200 = BB + small_bet) → P4 Raise(300 = 200 + small_bet) → P5 Call(300) |
| **기대 결과** | PRE_FLOP/FLOP: 베팅/레이즈 = small_bet(100). TURN/RIVER: 베팅/레이즈 = big_bet(200) |
| **판정 기준** | 베팅 단위 고정, small_bet/big_bet 외 금액 거부 |
| **참조** | BS-06-02 §2, PRD-GAME-04 |

### TC-G1-007-02a: Fixed Limit — PRE_FLOP small bet

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 6인, stack=10000, small_bet=100, BB=100, Dealer=P0 |
| **Hole Cards** | N/A |
| **Board** | N/A |
| **Actions** | PRE_FLOP: P3 Raise(200) → P4 시도 Raise(500) |
| **기대 결과** | P3 Raise(200) 수락 (BB 100 + small_bet 100). P4 Raise(500) 거부 — 허용 금액 = 300 (200 + small_bet 100) |
| **판정 기준** | `action.rejected == true`, `expected_amount == 300` |
| **참조** | BS-06-02 §2 |

### TC-G1-007-02b: Fixed Limit — TURN big bet

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 6인, stack=10000, small_bet=100, big_bet=200, Dealer=P0 |
| **Hole Cards** | N/A |
| **Board** | TURN 진행 중 |
| **Actions** | TURN: P3 Bet(200) → P4 Raise(400) → P5 시도 Bet(100) |
| **기대 결과** | P3 Bet(200) 수락 (big_bet). P4 Raise(400) 수락 (200 + big_bet 200). P5 시도 Raise(100) 거부 — Call(400) 또는 Raise(600) 만 허용 |
| **판정 기준** | TURN/RIVER에서 big_bet 단위만 허용 |
| **참조** | BS-06-02 §2 |

### TC-G1-007-02c: Fixed Limit — 3 Raise Cap 도달

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 6인, stack=10000, small_bet=100, BB=100, Dealer=P0 |
| **Hole Cards** | N/A |
| **Board** | N/A |
| **Actions** | PRE_FLOP: P3 Raise(200, 1st) → P4 Raise(300, 2nd) → P5 Raise(400, 3rd = cap) → P0 시도 Raise(500, 4th) |
| **기대 결과** | 1 bet + 3 raises = cap. P0의 4th raise 거부. P0 옵션: Call(400) 또는 Fold만 |
| **판정 기준** | `raise_count == 3` 후 `canRaise == false`. Cap 도달 메시지 표시 |
| **참조** | BS-06-02 §2 |

### TC-G1-007-02d: Fixed Limit — Heads-Up Unlimited Raises

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 2인, P0(10000), P1(10000), small_bet=100, BB=100, Dealer=P0(=SB) |
| **Hole Cards** | N/A |
| **Board** | N/A |
| **Actions** | PRE_FLOP: P0 Raise(200) → P1 Raise(300) → P0 Raise(400) → P1 Raise(500) → P0 Raise(600) (5th raise) |
| **기대 결과** | Heads-Up에서는 raise cap 미적용. 5th raise 이상도 수락 |
| **판정 기준** | `canRaise == true` (스택 잔여 한도까지), raise_count 무제한 |
| **참조** | BS-06-02 §2 |

### TC-G1-007-03: Pot Limit — 기본 베팅 검증

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 6인, stack=10000 each, BB=100, SB=50, Dealer=P0 |
| **Hole Cards** | N/A |
| **Board** | N/A |
| **Actions** | PRE_FLOP: pot=150 (SB+BB). P3 Raise → max = pot(150) + call(100) + raise = 150+100+250 = 350. P3 Raise(350) |
| **기대 결과** | P3 max raise = 350. pot 계산: 현재 pot + call 금액 + 그 합계 |
| **판정 기준** | `maxBet == 350`, Raise(350) 수락 |
| **참조** | BS-06-02 §3, PRD-GAME-04 |

### TC-G1-007-03a: Pot Limit — 최대 베팅 = Pot 계산 정확성

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 6인, stack=10000 each, BB=100, SB=50, Dealer=P0 |
| **Hole Cards** | N/A |
| **Board** | FLOP 진행 중, pot=1200 |
| **Actions** | FLOP: P3 Bet → max = pot(1200). P3 Bet(1200) → P4 Raise → max = pot(1200) + call(1200) + raise = 1200+1200+2400 = 3600. P4 Raise(3600) |
| **기대 결과** | P3 max = 1200, P4 max = 3600. 각각 수락 |
| **판정 기준** | `P3.maxBet == 1200`, `P4.maxBet == 3600`, pot 재계산 정확 |
| **참조** | BS-06-02 §3 |

### TC-G1-007-03b: Pot Limit — Pot 초과 베팅 거부

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 6인, stack=10000 each, BB=100, SB=50, Dealer=P0 |
| **Hole Cards** | N/A |
| **Board** | FLOP 진행 중, pot=1200 |
| **Actions** | FLOP: P3 시도 Bet(1500) — pot(1200) 초과 |
| **기대 결과** | 거부. 에러: `InvalidBetAmount`, 최대 = 1200 |
| **판정 기준** | `action.rejected == true`, `action.reason == "exceeds_pot_limit"`, `maxAllowed == 1200` |
| **참조** | BS-06-02 §3 |

### TC-G1-007-03c: Pot Limit — 연속 Raise 시 Pot 재계산

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 6인, stack=50000 each, BB=100, SB=50, Dealer=P0 |
| **Hole Cards** | N/A |
| **Board** | FLOP 진행 중, pot=500 |
| **Actions** | FLOP: P3 Bet(500, max) → P4 Raise → max = pot(500) + call(500) + bet(500) + raise = 500+500+500+500 = 2000. 실제: pot(500)+bet(500)=1000, call(500)+raise=1000+1000=2000. P4 Raise(2000) → P5 Raise → max 재계산 |
| **기대 결과** | P3 max=500. P4: pot=500+500=1000, call=500, max=1000+500+1500=3000. 실제 계산: pot(1000)+call(500)=1500, total=1500+1500=3000. 매 Raise마다 pot 재계산 |
| **판정 기준** | 연속 raise 시 `maxBet` 값이 매번 정확히 재계산 |
| **참조** | BS-06-02 §3 |

---

## 검증 요약

| TC ID | bet_structure | 핵심 검증 | Phase | 우선순위 |
|-------|:------------:|----------|:-----:|:--------:|
| TC-G1-007-01 | NL | 기본 베팅 시퀀스 | 1 | P0 |
| TC-G1-007-01a | NL | BB 미만 거부 | 1 | P0 |
| TC-G1-007-01b | NL | min_raise increment 추적 | 2 | P1 |
| TC-G1-007-01c | NL | Short All-In re-open 규칙 | 2 | P1 |
| TC-G1-007-02 | FL | small_bet / big_bet 전환 | 2 | P1 |
| TC-G1-007-02a | FL | PRE_FLOP small bet 강제 | 2 | P1 |
| TC-G1-007-02b | FL | TURN big bet 강제 | 2 | P1 |
| TC-G1-007-02c | FL | 3 raise cap | 2 | P1 |
| TC-G1-007-02d | FL | Heads-Up unlimited raises | 2 | P1 |
| TC-G1-007-03 | PL | Pot 기반 max 계산 | 2 | P1 |
| TC-G1-007-03a | PL | Pot 계산 정확성 | 2 | P1 |
| TC-G1-007-03b | PL | Pot 초과 거부 | 2 | P1 |
| TC-G1-007-03c | PL | 연속 raise pot 재계산 | 2 | P1 |
| TC-G1-007-01d | NL | Raise 스택 초과 시 거부/clamp | 1 | P0 |

---

## 코드 리뷰 발견 TC (2026-04-09)

### TC-G1-007-01d: NL Raise — 스택 초과 금액 거부

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 1 |
| **우선순위** | P0 |
| **Known Issue** | KI-05 — `betting_rules.dart` L139 `Raise` 핸들러에 스택 범위 검증 없음 |
| **Players** | 3인, P0(500), P1(5000), P2(5000), BB=100 |
| **Actions** | P1 Bet(200), P0 Raise(toAmount=1000) — P0 stack(500) < toAmount-currentBet(1000) |
| **기대 결과** | 거부 (예외 또는 clamp to All-In). 현재 구현: `seat.stack = 500 - 1000 = -500` 음수 |
| **판정 기준** | `throws IllegalActionException` 또는 `seat.stack >= 0` |
| **참조** | BS-06-02 §Raise Validation, `betting_rules.dart` L139-155 |

> **버그 원인**: `legalActions()`는 `raiseMax = stack + seatBet`으로 올바르게 제한하지만, `applyAction()`은 `legalActions()` 결과를 참조하지 않고 직접 차감. public API이므로 외부 호출 시 corruption 가능.
