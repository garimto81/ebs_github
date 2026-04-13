# QA-GE-01: FSM 상태 전이 상세 테스트 케이스

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Hold'em FSM 14개 TC 상세 (정상 11 + 무효 3) v1.0.0 |
| 2026-04-09 | TC 추가 | 코드 리뷰 발견: TC-G1-002-15 (StreetAdvance 무효 전이 미차단) |

---

## 개요

Hold'em FSM 9개 상태 간 전이를 검증한다. Master Plan §8.1 (정상 전이 11개) + §8.2 (무효 전이 3개) = 14개 TC를 실행 수준으로 확장한다.

### FSM 상태 정의

| 상태 | 설명 | hand_in_progress | board 카드 수 |
|------|------|:----------------:|:------------:|
| **IDLE** | 핸드 대기 | false | 0 |
| **SETUP_HAND** | 블라인드 + 홀카드 딜 | true | 0 |
| **PRE_FLOP** | 첫 베팅 라운드 | true | 0 |
| **FLOP** | 3장 커뮤니티 | true | 3 |
| **TURN** | 4장 커뮤니티 | true | 4 |
| **RIVER** | 5장 커뮤니티 (final_betting_round=true) | true | 5 |
| **SHOWDOWN** | 핸드 평가 + 팟 분배 | true | 5 |
| **RUN_IT_MULTIPLE** | 복수 보드 처리 | true | 가변 |
| **HAND_COMPLETE** | 핸드 정리 | true→false | 5 |

---

## 정상 전이 매트릭스

| From | To | 조건 | TC ID | Phase |
|------|-----|------|-------|:-----:|
| IDLE | SETUP_HAND | StartHand(), pl_dealer != -1, seats >= 2 | TC-G1-002-01 | P0 |
| SETUP_HAND | PRE_FLOP | blinds posted + hole cards dealt | TC-G1-002-02 | P0 |
| PRE_FLOP | FLOP | 베팅 라운드 완료 | TC-G1-002-03 | P0 |
| FLOP | TURN | 베팅 라운드 완료 | TC-G1-002-04 | P0 |
| TURN | RIVER | 베팅 라운드 완료 | TC-G1-002-05 | P0 |
| RIVER | SHOWDOWN | 베팅 라운드 완료 | TC-G1-002-06 | P0 |
| SHOWDOWN | HAND_COMPLETE | 승자 결정 + 팟 분배 완료 | TC-G1-002-07 | P0 |
| HAND_COMPLETE | IDLE | 핸드 정리 완료 | TC-G1-002-08 | P0 |
| PRE_FLOP~RIVER | SHOWDOWN | 1인 제외 전원 Fold | TC-G1-002-09 | P0 |
| PRE_FLOP~RIVER | RUN_IT_MULTIPLE | All-In + Run It Twice | TC-G1-002-10 | P1 |
| RUN_IT_MULTIPLE | SHOWDOWN | 복수 보드 처리 완료 | TC-G1-002-11 | P1 |

---

## 무효 전이 매트릭스

| From | To (시도) | 기대 | TC ID | Phase |
|------|----------|------|-------|:-----:|
| IDLE | FLOP | 거부 — SETUP_HAND 필수 | TC-G1-002-12 | P1 |
| SHOWDOWN | PRE_FLOP | 거부 — HAND_COMPLETE 경유 필수 | TC-G1-002-13 | P1 |
| HAND_COMPLETE | SHOWDOWN | 거부 — 역방향 금지 | TC-G1-002-14 | P1 |

---

## TC 상세

### TC-G1-002-01: IDLE → SETUP_HAND

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 1 |
| **우선순위** | P0 |
| **Players** | P0~P5, stack=10000, BB=100, SB=50, Dealer=P0 |
| **Hole Cards** | — (딜 전) |
| **Board** | — |
| **Actions** | `StartHand` (CC 수동) |
| **기대 결과** | game_phase=SETUP_HAND, hand_in_progress=true, hand_number 1 증가 |
| **판정 기준** | `state.phase == Phase.setupHand`, `state.handInProgress == true` |
| **참조** | BS-06-01 §IDLE→SETUP_HAND |

사전 조건:
- game_phase == IDLE
- pl_dealer != -1 (딜러 위치 지정됨)
- 활성 좌석 >= 2

---

### TC-G1-002-02: SETUP_HAND → PRE_FLOP

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 1 |
| **우선순위** | P0 |
| **Players** | P0~P5, stack=10000, BB=100, SB=50, Dealer=P0 |
| **Hole Cards** | P0: `As Ks`, P1: `Qh Jh`, P2: `Td 9d`, P3: `8c 7c`, P4: `6s 5s`, P5: `4h 3h` |
| **Board** | — |
| **Actions** | `BlindsPosted` (Engine 자동) → `HoleCardsDealt` (Engine 자동) |
| **기대 결과** | game_phase=PRE_FLOP, action_on=UTG (P3), pot=150 (SB50+BB100) |
| **판정 기준** | `state.phase == Phase.preFlop`, `state.actionOn == 3`, `state.pot == 150` |
| **참조** | BS-06-01 §SETUP_HAND→PRE_FLOP, BS-06-03 |

사전 조건:
- TC-G1-002-01 완료 상태
- SB=P1 (Dealer 좌측), BB=P2

---

### TC-G1-002-03: PRE_FLOP → FLOP

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 1 |
| **우선순위** | P0 |
| **Players** | P0~P5, stack=10000, BB=100, SB=50, Dealer=P0 |
| **Hole Cards** | P0: `As Ks`, P1: `Qh Jh`, P2: `Td 9d`, P3: `8c 7c`, P4: `6s 5s`, P5: `4h 3h` |
| **Board** | `Ah 7d 2c` |
| **Actions** | P3 Call(100), P4 Call(100), P5 Call(100), P0 Call(100), P1 Call(50), P2 Check (CC 수동 각각) → `DealFlop` (Engine 자동) |
| **기대 결과** | game_phase=FLOP, board 카드 3장, pot=600, action_on=P1 (SB) |
| **판정 기준** | `state.phase == Phase.flop`, `state.board.length == 3`, `state.pot == 600` |
| **참조** | BS-06-01 §PRE_FLOP→FLOP |

---

### TC-G1-002-04: FLOP → TURN

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 1 |
| **우선순위** | P0 |
| **Players** | P0~P5, stack=9900, BB=100, SB=50, Dealer=P0 |
| **Hole Cards** | TC-G1-002-03과 동일 |
| **Board** | `Ah 7d 2c Ts` |
| **Actions** | 전원 Check (CC 수동 각각) → `DealTurn` (Engine 자동) |
| **기대 결과** | game_phase=TURN, board 카드 4장, pot=600 (변동 없음) |
| **판정 기준** | `state.phase == Phase.turn`, `state.board.length == 4` |
| **참조** | BS-06-01 §FLOP→TURN |

---

### TC-G1-002-05: TURN → RIVER

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 1 |
| **우선순위** | P0 |
| **Players** | P0~P5, stack=9900, BB=100, SB=50, Dealer=P0 |
| **Hole Cards** | TC-G1-002-03과 동일 |
| **Board** | `Ah 7d 2c Ts 3s` |
| **Actions** | 전원 Check (CC 수동 각각) → `DealRiver` (Engine 자동) |
| **기대 결과** | game_phase=RIVER, board 카드 5장, final_betting_round=true, pot=600 |
| **판정 기준** | `state.phase == Phase.river`, `state.board.length == 5`, `state.finalBettingRound == true` |
| **참조** | BS-06-01 §TURN→RIVER |

---

### TC-G1-002-06: RIVER → SHOWDOWN

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 1 |
| **우선순위** | P0 |
| **Players** | P0~P5, stack=9900, BB=100, SB=50, Dealer=P0 |
| **Hole Cards** | P0: `As Ks`, P1: `Qh Jh`, P2: `Td 9d`, P3: `8c 7c`, P4: `6s 5s`, P5: `4h 3h` |
| **Board** | `Ah 7d 2c Ts 3s` |
| **Actions** | 전원 Check (CC 수동 각각) → `EnterShowdown` (Engine 자동) |
| **기대 결과** | game_phase=SHOWDOWN, 핸드 평가 실행, winner=P0 (Pair of Aces, K kicker) |
| **판정 기준** | `state.phase == Phase.showdown`, `state.winners.contains(0)` |
| **참조** | BS-06-01 §RIVER→SHOWDOWN, BS-06-05 |

---

### TC-G1-002-07: SHOWDOWN → HAND_COMPLETE

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 1 |
| **우선순위** | P0 |
| **Players** | TC-G1-002-06 후속 |
| **Hole Cards** | TC-G1-002-06과 동일 |
| **Board** | `Ah 7d 2c Ts 3s` |
| **Actions** | `AwardPot` (Engine 자동) → `UpdateStatistics` (Engine 자동) |
| **기대 결과** | game_phase=HAND_COMPLETE, P0.stack=10500 (+600), pots=[] (분배 완료), statistics 업데이트 |
| **판정 기준** | `state.phase == Phase.handComplete`, `state.pots.isEmpty`, `players[0].stack == 10500` |
| **참조** | BS-06-05, BS-06-07 |

---

### TC-G1-002-08: HAND_COMPLETE → IDLE

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 1 |
| **우선순위** | P0 |
| **Players** | TC-G1-002-07 후속 |
| **Hole Cards** | — (정리됨) |
| **Board** | — (정리됨) |
| **Actions** | `ManualNextHand` (CC 수동) |
| **기대 결과** | game_phase=IDLE, hand_in_progress=false, board=[], hole_cards 전원 초기화, pot=0 |
| **판정 기준** | `state.phase == Phase.idle`, `state.handInProgress == false`, `state.board.isEmpty`, `state.pot == 0` |
| **참조** | BS-06-01 §HAND_COMPLETE→IDLE |

사전 조건:
- game_phase == HAND_COMPLETE
- 팟 분배 완료

---

### TC-G1-002-09: All Fold → SHOWDOWN 직행

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 1 |
| **우선순위** | P0 |
| **Players** | P0~P5, stack=10000, BB=100, SB=50, Dealer=P0 |
| **Hole Cards** | P0: `7s 2d`, P1: `9c 8c`, P2: `Jh Th`, P3: `4h 3h`, P4: `6s 5s`, P5: `As Ks` |
| **Board** | — (Flop 도달 전) |
| **Actions** | SETUP_HAND 완료 (Engine 자동) → PRE_FLOP: P3 Fold, P4 Fold, P5 Raise(300), P0 Fold, P1 Fold, P2 Fold (CC 수동 각각) |
| **기대 결과** | game_phase=HAND_COMPLETE (Showdown 스킵), winner=P5 (마지막 생존), pot=450 (SB50+BB100+Raise300) |
| **판정 기준** | `state.winners == [5]`, `state.board.isEmpty` (보드 미공개), `players[5].stack == 10300` |
| **참조** | BS-06-01 §AllFolded |

> 1인 제외 전원 Fold 시 Showdown 없이 즉시 HAND_COMPLETE로 전이. 보드 미공개.

---

### TC-G1-002-10: All-In at FLOP → RUN_IT_MULTIPLE

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | P0, P1, stack=5000, BB=100, SB=50, Dealer=P0 (Heads-up: Dealer=SB) |
| **Hole Cards** | P0: `As Ad`, P1: `Ks Kd` |
| **Board** | Board 1: `7c 4d 2s Jh 8c`, Board 2: `7c 4d 2s Qh 3s` |
| **Actions** | SETUP_HAND (Engine 자동) → PRE_FLOP: P0 Call, P1 Check (CC 수동) → FLOP (`7c 4d 2s`): P1 AllIn(4900), P0 Call(4900) (CC 수동) → `SetRunItTimes(2)` (CC 수동) |
| **기대 결과** | game_phase=RUN_IT_MULTIPLE, run_count=2, 2개 보드 생성 |
| **판정 기준** | `state.phase == Phase.runItMultiple`, `state.runCount == 2`, `state.boards.length == 2` |
| **참조** | BS-06-08 |

사전 조건:
- 전원 All-In 상태
- Run It Twice 활성화 (CC 수동 설정)

---

### TC-G1-002-11: RUN_IT_MULTIPLE → SHOWDOWN

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | TC-G1-002-10 후속 |
| **Hole Cards** | P0: `As Ad`, P1: `Ks Kd` |
| **Board** | Board 1: `7c 4d 2s Jh 8c`, Board 2: `7c 4d 2s Qh 3s` |
| **Actions** | `CompleteMultipleBoards` (Engine 자동) |
| **기대 결과** | game_phase=SHOWDOWN, Board 1 winner=P0 (AA), Board 2 winner=P0 (AA), pot 각 보드 50% 분배 |
| **판정 기준** | `state.phase == Phase.showdown`, `state.boardResults.length == 2`, 각 보드별 winner 독립 판정 |
| **참조** | BS-06-08 |

> 각 보드별 독립 핸드 평가 후 팟을 보드 수로 균등 분할. 홀수 칩은 Board 1 우선.

---

### TC-G1-002-12: 무효 전이 — IDLE → FLOP (거부)

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | P0~P5, stack=10000, BB=100, SB=50, Dealer=P0 |
| **Hole Cards** | — |
| **Board** | — |
| **Actions** | IDLE 상태에서 `DealFlop` 강제 호출 시도 (테스트 코드) |
| **기대 결과** | 전이 거부, game_phase=IDLE 유지, 에러 반환 |
| **판정 기준** | `state.phase == Phase.idle` (변경 없음), `throws InvalidTransitionException` |
| **참조** | BS-06-01 §무효 전이 |

> SETUP_HAND를 거치지 않고 FLOP 직행 불가.

---

### TC-G1-002-13: 무효 전이 — SHOWDOWN → PRE_FLOP (거부)

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | P0~P5, stack=10000 |
| **Hole Cards** | — |
| **Board** | `Ah 7d 2c Ts 3s` |
| **Actions** | SHOWDOWN 상태에서 `StartPreFlop` 강제 호출 시도 (테스트 코드) |
| **기대 결과** | 전이 거부, game_phase=SHOWDOWN 유지, 에러 반환 |
| **판정 기준** | `state.phase == Phase.showdown` (변경 없음), `throws InvalidTransitionException` |
| **참조** | BS-06-01 §무효 전이 |

> HAND_COMPLETE를 경유하지 않고 PRE_FLOP 역행 불가.

---

### TC-G1-002-14: 무효 전이 — HAND_COMPLETE → SHOWDOWN (거부)

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | P0~P5, stack=10000 |
| **Hole Cards** | — |
| **Board** | `Ah 7d 2c Ts 3s` |
| **Actions** | HAND_COMPLETE 상태에서 `EnterShowdown` 강제 호출 시도 (테스트 코드) |
| **기대 결과** | 전이 거부, game_phase=HAND_COMPLETE 유지, 에러 반환 |
| **판정 기준** | `state.phase == Phase.handComplete` (변경 없음), `throws InvalidTransitionException` |
| **참조** | BS-06-01 §무효 전이 |

> 역방향 전이 (HAND_COMPLETE → SHOWDOWN) 금지. IDLE 경유 필수.

---

## 코드 리뷰 발견 TC (2026-04-09)

### TC-G1-002-15: StreetAdvance 무효 전이 — PRE_FLOP → RIVER 직행 거부

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Known Issue** | KI-09 — `engine.dart`에서 `StreetAdvance` 이벤트가 `event.next`를 직접 사용, 순서 검증 없음 |
| **Players** | P0~P5, stack=10000 |
| **Actions** | PRE_FLOP 상태에서 `StreetAdvance(Street.river)` 강제 발행 (테스트 코드) |
| **기대 결과** | 전이 거부 또는 에러. game_phase=PRE_FLOP 유지. 현재 구현: RIVER로 점프 허용 |
| **판정 기준** | `throws InvalidTransitionException` 또는 `state.street == Street.preflop` (변경 없음) |
| **참조** | BS-06-01 §정상 전이 순서, `engine.dart` L188 |

> **버그 원인**: `Engine.apply`의 `StreetAdvance` 핸들러가 `StreetMachine.nextStreet()` 검증을 거치지 않고 `event.next`를 직접 사용.
