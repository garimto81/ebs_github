# QA-GE-02: Game Engine QA 체크리스트 (BS-06 기반)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | BS-06 engine-spec 19개 파일 기반 QA 체크리스트 + 구현 대조 v1.0.0 |
| 2026-04-09 | Contract Test 증분 반영 | GE-00-09~12 추가 (EventLog/cursor), GE-02-06 상태 변경 (❌), GE-02-06a/18 추가 (Call enforcement, UNDO 제한) |
| 2026-04-09 | 무결성 검증 | 용어 정의 추가, KI-12~14 매핑 추가, Phase 1 수치 정정 (~85%→~76%) |

---

## 개요

`ebs_game_engine/` (Dart 3.11, Docker) 기준. BS-06 행동 명세의 모든 요구사항을 추출하여 구현 코드와 1:1 대조한다.

> 레포: `C:\claude\ebs\ebs_game_engine\` | 언어: Pure Dart | 아키텍처: Event Sourcing
> 테스트: `dart test` | 시나리오: YAML fixtures (30개) | API: HTTP REST (harness)

**용어**

| 약어 | 의미 |
|------|------|
| **BS-06** | 게임 엔진 행동 명세 문서군 (19개 파일). 각 섹션이 하나의 기능 영역 |
| **KI** | Known Issue — 코드 리뷰에서 발견된 알려진 버그 (KI-01~14) |
| **Event Sourcing** | 상태 변경을 이벤트 객체로 기록하는 아키텍처 패턴 |
| **Coalescence** | 동시 입력(RFID 카드 인식 등) 병합 처리 |
| **SB/BB** | Small Blind / Big Blind — 의무 베팅 (소액/대액) |
| **Ante** | 참가비 — 핸드 시작 전 모든(또는 특정) 플레이어가 내는 금액 |
| **All-In** | 보유 금액 전부를 거는 행위 |
| **Side Pot** | All-In 플레이어의 스택 차이로 분리되는 별도 팟 |
| **FSM** | Finite State Machine — 게임 진행 상태를 관리하는 유한 상태 기계 |
| **NL/FL/PL** | No Limit / Fixed Limit / Pot Limit — 베팅 구조 유형 |
| **Hi/Lo** | 최고핸드와 최저핸드가 팟을 나누는 게임 방식 |

> 이 문서는 개발팀/QA 엔지니어 대상 기술 체크리스트입니다.

**범례**

| 기호 | 의미 |
|------|------|
| ✅ | 구현 완료 |
| ⚠️ | 부분 구현 / 로직 불완전 |
| ❌ | 미구현 |
| — | N/A (게임 엔진 범위 외) |

> **테스트 열**: 게임 엔진은 UI 앱이 아니므로 Playwright 대신 `dart test` 파일 / YAML 시나리오 커버리지를 기록한다.

---

## SECTION 0 — Reference (BS-06-00-REF)

| # | 요구사항 | 구현 | 근거 | 테스트 |
|---|----------|:----:|------|:------:|
| GE-00-01 | 7종 Ante Type enum (0-6) 정의 | ✅ | engine.dart:L193-313 — 6종 ante type case 처리 | ✅ phase1_ante_straddle_test |
| GE-00-02 | HandCategory enum (10등급: highCard~royalFlush) | ✅ | hand_evaluator.dart:L3-30 — HandCategory enum | ✅ hand_evaluator_test |
| GE-00-03 | SeatStatus enum (active, folded, allIn, sittingOut, eliminated) | ✅ | seat.dart — SeatStatus enum 5종 | ✅ game_state_extended_test |
| GE-00-04 | Street enum (setupHand~runItMultiple) 7종 | ✅ | game_state.dart:L9 — Street enum | ✅ core_logic_test |
| GE-00-05 | ActionType sealed class (fold, check, bet, call, raise, allIn) | ✅ | action.dart — sealed class 6종 | ✅ betting_rules_test |
| GE-00-06 | GameEvent sealed class (Input 이벤트 계층) | ✅ | event.dart — sealed class 정의 | ✅ output_event_test |
| GE-00-07 | OutputEvent sealed class (10종 출력 이벤트) | ✅ | output_event.dart:L6-69 — 10종 정의 | ✅ output_event_test |
| GE-00-08 | ReduceResult 구조 (state + outputs) | ✅ | reduce_result.dart — 정의 | ✅ output_event_test:L113-148 |
| GE-00-09 | EventLog 데이터 구조 (events + maxUndoDepth=5) | ⚠️ | event_log.dart — 클래스 정의 있으나 Session에서 **미사용** (dead code) | ⚠️ contract/spec_contract_test |
| GE-00-10 | log event_type enum 17종 (Ch1.8.1) | ⚠️ | event.dart — sealed class 존재하나 enum 매핑 코드 없음 | ❌ |
| GE-00-11 | Event Log 스코프: 핸드 로그 vs 스트리트 히스토리 (Ch7.6.3) | ❌ | _street_bet_history 미구현 | ❌ |
| GE-00-12 | cursor 기반 Event Sourcing 재생 (Ch7.6.5) | ✅ | session.dart — stateAt(cursor) | ✅ harness/session_h2_test |

---

## SECTION 1 — Lifecycle FSM (BS-06-01)

| # | 요구사항 | 구현 | 근거 | 테스트 |
|---|----------|:----:|------|:------:|
| GE-01-01 | IDLE → SETUP_HAND 전이 (`hand_in_progress=true`) | ✅ | engine.dart:L117-119 — HandStart reduce | ✅ phase2_core_logic_test |
| GE-01-02 | SETUP_HAND: blinds 자동 포스팅 + 홀카드 딜 전 상태 | ⚠️ | engine.dart:L116-409 — 블라인드 처리하나 명시적 SETUP_HAND 상태 구분 없이 preflop 직진 | ⚠️ |
| GE-01-03 | PRE_FLOP 진입: 홀카드 딜 완료 후 전이 | ⚠️ | engine.dart:L453-474 — 수동 StreetAdvance 이벤트 의존, 자동 감지 없음 | ⚠️ |
| GE-01-04 | FLOP/TURN/RIVER 진입: 보드 카드 + StreetAdvance | ⚠️ | engine.dart:L419-422 — DealCommunity는 카드만 추가, 상태 전이는 StreetAdvance 의존 | ⚠️ |
| GE-01-05 | RIVER 상태에서 `final_betting_round` 표시 | ⚠️ | game_state.dart에 명시적 필드 없음 — Street 값으로만 구분 | ⚠️ |
| GE-01-06 | 베팅 완료 → actionOn=-1 (다음 스트리트 준비 신호) | ✅ | engine.dart:L444-445 — `isRoundComplete()` 체크 후 actionOn 리셋 | ✅ betting_rules_test |
| GE-01-07 | 모두 올인 → runout 자동 감지 | ✅ | engine.dart:L79-83 — `isAllInRunout()` | ✅ phase2_core_logic_test |
| GE-01-08 | Run It Twice: RUN_IT_MULTIPLE 상태 진입 | ✅ | engine.dart:L537-541 — RunItChoice → street: runItMultiple | ✅ phase5_extras_test |
| GE-01-09 | SHOWDOWN 진입: 최종 베팅 완료 + 2인 이상 | ⚠️ | 자동 감지 없음 — harness에서 조건 확인 필요 | ⚠️ |
| GE-01-10 | HAND_COMPLETE: 승자 결정 + `handInProgress=false` | ✅ | engine.dart:L487-504 — `_endHand()` | ✅ phase2_core_logic_test |
| GE-01-11 | 전원 Fold → 즉시 HAND_COMPLETE (1인 잔류) | ✅ | engine.dart:L437-441 — `activeCount <= 1` | ✅ scenarios/02-nlh-preflop-all-fold |
| GE-01-12 | Bomb Pot: PRE_FLOP 스킵 → FLOP 직행 | ✅ | engine.dart:L316-361 — bombPotEnabled 분기 | ✅ scenarios/19-nlh-bomb-pot |
| GE-01-13 | Heads-up: Dealer=SB, SB가 PRE_FLOP 선행 | ✅ | engine.dart:L144-151 — 2인 sbIdx=dealerSeat | ✅ scenarios/13-nlh-heads-up-blinds |
| GE-01-14 | Miss Deal: 상태 → IDLE, pot/stacks 복구 | ✅ | engine.dart:L507-528 — MisDeal 처리 | ⚠️ 스택 완전 복구 검증 필요 |
| GE-01-15 | Dealer 순환: 다음 활성 플레이어로 이동 | ✅ | engine.dart:L488-496 — sittingOut 스킵 | ✅ scenarios/23-nlh-dealer-rotation |
| GE-01-16 | 무효 전이 차단 (PRE_FLOP→RIVER 직행 등) | ❌ | KI-09: StreetAdvance 무효 전이 미차단 | ❌ |

---

## SECTION 2 — Betting Actions (BS-06-02)

| # | 요구사항 | 구현 | 근거 | 테스트 |
|---|----------|:----:|------|:------:|
| GE-02-01 | Fold: player.status → folded | ✅ | betting_rules.dart — Fold 처리 | ✅ betting_rules_test |
| GE-02-02 | Check 조건: biggest_bet == player.currentBet | ✅ | betting_rules.dart — 유효성 검증 | ✅ betting_rules_test |
| GE-02-03 | Bet 범위 (NL): [BB, stack] | ✅ | no_limit.dart — 범위 계산 | ✅ bet_limit_test |
| GE-02-04 | Bet 범위 (PL): [BB, pot] | ✅ | pot_limit.dart — maxRaise 계산 | ✅ bet_limit_test |
| GE-02-05 | Bet 범위 (FL): small_bet/big_bet 고정 | ✅ | fixed_limit.dart — 고정 금액 | ✅ bet_limit_test |
| GE-02-06 | Call 금액: biggest_bet - player.currentBet (자동 계산) | ❌ | betting_rules.dart:L125 — **Call.amount를 그대로 사용**. 명세: 외부 amount 무시, 엔진 재계산 강제 (BS-06-02 §4) | ❌ contract/spec_contract_test FAIL |
| GE-02-06a | Call 금액 enforcement: applyAction에서 Call.amount 무시 | ❌ | Contract Test FAIL: Call(50) 전달 시 50 적용됨 (명세: 100이어야 함) | ❌ contract/spec_contract_test FAIL |
| GE-02-07 | Raise 최소액 (NL): biggest_bet + max(BB, last_raise_increment) | ✅ | no_limit.dart — minRaise 계산 | ✅ bet_limit_test |
| GE-02-08 | Raise 최대액 (PL): pot + call + bet + call | ✅ | pot_limit.dart — maxRaise | ✅ bet_limit_test |
| GE-02-09 | Raise cap (FL): 1 bet + 3 raises, Heads-up 무제한 | ✅ | fixed_limit.dart — cap 검증 | ✅ bet_limit_test |
| GE-02-10 | All-In: stack > 0, status=active | ✅ | betting_rules.dart — allIn 검증 | ✅ phase3_betting_refinement_test |
| GE-02-11 | Short Call: call > stack → allIn + side pot | ⚠️ | engine.dart:L161 — min(call, stack) 처리, side pot 자동화 불명확 | ⚠️ |
| GE-02-12 | BB Check Option (PRE_FLOP): biggest_bet==BB && actionOn==BB | ⚠️ | betting_round.dart — `bbOptionPending` 필드 있으나 활용 불완전 | ⚠️ |
| GE-02-13 | 액션 후 next player: fold/allIn 제외 순회 | ✅ | street_machine.dart — `nextToAct()` | ✅ street_machine_test |
| GE-02-14 | 라운드 완료: 모두 동액 + 최소 1회 액션 | ✅ | betting_rules.dart — `isRoundComplete()` | ✅ betting_rules_test |
| GE-02-15 | Straddle: 2×BB, 최소 레이즈 기준 변경 | ✅ | engine.dart:L363-382 — straddle 처리 | ✅ phase1_ante_straddle_test |
| GE-02-16 | Raise toAmount > stack 시 방어 | ❌ | KI-05: betting_rules.dart:L139 — 음수 stack 발생 가능 | ❌ |
| GE-02-17 | legalActions() API: 현재 유효한 액션 목록 반환 | ✅ | betting_rules.dart — legalActions() 구현 | ✅ betting_rules_test |
| GE-02-18 | UNDO 최대 5단계 제한 (Ch7.6.7) | ❌ | session.dart — Session.undo()는 **무제한**. EventLog.maxUndoSteps=5 미적용 | ❌ contract/spec_contract_test FAIL |

---

## SECTION 3 — Blinds & Ante (BS-06-03)

| # | 요구사항 | 구현 | 근거 | 테스트 |
|---|----------|:----:|------|:------:|
| GE-03-01 | 포스팅 순서: SB → BB → [Ante] → [Straddle] | ✅ | engine.dart:L154-313 — 순서 준수 | ✅ phase1_ante_straddle_test |
| GE-03-02 | Ante Type 0 (std): 전원 동일 금액 | ✅ | engine.dart:L195-206 | ✅ scenarios/16-nlh-standard-ante |
| GE-03-03 | Ante Type 1 (button): Dealer만 대납 | ✅ | engine.dart:L207-218 | ✅ phase1_ante_straddle_test |
| GE-03-04 | Ante Type 2 (bb): BB만 대납 | ✅ | engine.dart:L219-230 | ✅ scenarios/17-nlh-bb-ante |
| GE-03-05 | Ante Type 3 (bb_bb1st): BB 대납 + BB 먼저 행동 | ✅ | engine.dart:L231-243 — bbActsFirst=true | ⚠️ 액션 순서 통합 검증 필요 |
| GE-03-06 | Ante Type 4 (live): currentBet에 포함 (콜액 감소) | ✅ | engine.dart:L245-260 — currentBet += post | ✅ phase1_ante_straddle_test |
| GE-03-07 | Ante Type 5 (tb): SB+BB 분할 처리 | ✅ | engine.dart:L261-284 — halfAnte 계산 | ✅ phase1_ante_straddle_test |
| GE-03-08 | Ante Type 6 (tb_tb1st): TB 분할 + SB 먼저 | ✅ | engine.dart:L285-309 — sbActsFirst=true | ⚠️ 액션 순서 검증 필요 |
| GE-03-09 | 칩 부족 → 자동 allIn: min(required, stack) | ✅ | engine.dart:L161,198,211 — min() 처리 | ✅ phase1_ante_straddle_test |
| GE-03-10 | sittingOut 플레이어 Ante 면제 | ✅ | engine.dart:L196 — isActive/isAllIn 체크 | ⚠️ sitout 전용 테스트 필요 |
| GE-03-11 | Heads-up: Dealer=SB 위치 규칙 | ✅ | engine.dart:L145-151 | ✅ scenarios/13-nlh-heads-up-blinds |
| GE-03-12 | 팟 초기값: SB+BB+Ante+[Straddle] 합산 | ✅ | engine.dart:L155-382 — 누적 처리 | ✅ pot_test |
| GE-03-13 | Dead Button: 빈 좌석 건너뛰기 | ⚠️ | engine.dart:L488-496 — sittingOut 스킵하나 dead button 명시 규칙 없음 | ⚠️ scenarios/22-nlh-dead-button |
| GE-03-14 | Bomb Pot: 전원 동일 금액 + PRE_FLOP 스킵 | ✅ | engine.dart:L316-361 | ✅ scenarios/19-nlh-bomb-pot |

---

## SECTION 4 — Coalescence (BS-06-04)

| # | 요구사항 | 구현 | 근거 | 테스트 |
|---|----------|:----:|------|:------:|
| GE-04-01 | 3가지 트리거 소스: CC / RFID / Engine 자동 | — | Engine 자동만 구현, CC/RFID 통합은 Core 범위 외 | — |
| GE-04-02 | 우선순위: RFID > CC > Engine | ❌ | coalescence 로직 미구현 | ❌ |
| GE-04-03 | ±100ms 시간 윈도우 내 이벤트 병합 | ❌ | 미구현 | ❌ |
| GE-04-04 | state_applied=true → CC 우선 예외 | ❌ | game_state에 필드 없음 | ❌ |
| GE-04-05 | runout_in_progress=true → Engine 우선 예외 | ❌ | game_state에 필드 없음 | ❌ |
| GE-04-06 | RFID 중복 제거 (100ms 내 동일 UID 폐기) | ❌ | 미구현 | ❌ |
| GE-04-07 | 모달 활성 중 RFID 대기 | ❌ | modalActive 필드 없음 | ❌ |
| GE-04-08 | UNDO 진행 중 모든 입력 차단 | ❌ | UNDO 미구현 | ❌ |

> **참고**: Coalescence는 게임 엔진 core가 아닌 harness/CC 통합 계층의 요구사항. Core 엔진은 단일 이벤트 처리에 집중하며, coalescence는 상위 계층에서 구현 예정.

---

## SECTION 5 — Hand Evaluation (BS-06-05)

| # | 요구사항 | 구현 | 근거 | 테스트 |
|---|----------|:----:|------|:------:|
| GE-05-01 | standard_high evaluator (Hold'em 전용) | ✅ | hand_evaluator.dart:L96-322 | ✅ hand_evaluator_test |
| GE-05-02 | HandRank 9등급 분류 (0=HighCard ~ 8=StraightFlush) | ✅ | hand_evaluator.dart:L226-261 — 9등급 분류 | ✅ hand_evaluator_test |
| GE-05-03 | Best 5 of 7: C(7,5) 조합 선택 | ✅ | hand_evaluator.dart:L101-116 — bestHand | ✅ hand_evaluator_test |
| GE-05-04 | Tiebreaker: 동일 HandRank 시 kicker 순차 비교 | ✅ | hand_evaluator.dart:L63-94 — compareTo | ✅ hand_evaluator_test |
| GE-05-05 | Pair: pair rank > kicker1 > kicker2 > kicker3 | ✅ | hand_evaluator.dart:L75-82 | ✅ hand_evaluator_test |
| GE-05-06 | TwoPair: highPair > lowPair > kicker | ✅ | hand_evaluator.dart:L251-254 | ✅ hand_evaluator_test |
| GE-05-07 | Straight: 최고 카드 비교 | ✅ | hand_evaluator.dart:L246 — straightHigh kicker | ✅ hand_evaluator_test |
| GE-05-08 | Flush: 5장 순차 비교 | ✅ | hand_evaluator.dart:L243 | ✅ hand_evaluator_test |
| GE-05-09 | FullHouse: trips > pair | ✅ | hand_evaluator.dart:L239-241 | ✅ hand_evaluator_test |
| GE-05-10 | Quads: quads > kicker | ✅ | hand_evaluator.dart:L237-238 | ✅ hand_evaluator_test |
| GE-05-11 | StraightFlush / RoyalFlush 구분 | ✅ | hand_evaluator.dart:L230-235 — straightHigh==14 체크 | ✅ hand_evaluator_test |
| GE-05-12 | Omaha 평가: 정확히 hole 2 + community 3 사용 | ✅ | hand_evaluator.dart:L119-136 — bestOmaha | ✅ omaha_test |
| GE-05-13 | Hi-Lo 평가: 8-or-better Lo 판정 | ✅ | hand_evaluator.dart:L141-172 — evaluateLo | ✅ omaha_hilo_test |
| GE-05-14 | Hi/Lo Odd Chip: Hi에게 할당 (WSOP Rule 73) | ❌ | KI-02: showdown.dart:L77 — Lo에게 할당됨 | ❌ |
| GE-05-15 | Split Pot Odd Chip: dealer-left 가장 가까운 플레이어 | ⚠️ | showdown.dart — _splitPot()에서 처리하나 정확성 검증 필요 | ⚠️ |
| GE-05-16 | Run It Twice: 각 런별 독립 평가 + 합산 | ⚠️ | RunItChoice 이벤트 정의만, 실제 합산 로직 미완성 | ⚠️ |
| GE-05-17 | All-in Runout: 보드 자동 완성 후 평가 | ✅ | engine.dart:L79-83 — isAllInRunout() | ✅ scenarios/26-nlh-all-in-runout |

---

## SECTION 6 — Side Pot (BS-06-06)

| # | 요구사항 | 구현 | 근거 | 테스트 |
|---|----------|:----:|------|:------:|
| GE-06-01 | SidePot 구조 정의 (amount, eligible) | ✅ | pot.dart:L1-5 — SidePot sealed class | ✅ pot_test |
| GE-06-02 | calculateSidePots() 알고리즘 (tier 분리) | ✅ | pot.dart:L19-40 — tier-based 계산 | ✅ pot_test:L17-29 |
| GE-06-03 | Eligible set: contributors - folded | ✅ | pot.dart:L34 — `eligible = contributors.difference(folded)` | ✅ pot_test:L31-41 |
| GE-06-04 | Fold 플레이어 데드 머니 해당 Pot에 잔류 | ✅ | pot.dart:L22 — folded param 추적 | ✅ pot_test |
| GE-06-05 | 역순 판정 (smallest eligible set first) | ✅ | showdown.dart:L31-32 — sortedPots.sort() | ✅ showdown_test:L68-96 |
| GE-06-06 | engine.dart에서 calculateSidePots() 호출 | ❌ | KI-03: 호출 지점 없음, currentBet Street마다 리셋으로 누적 기여액 소실 | ❌ |
| GE-06-07 | Odd chip: dealer-left 가장 가까운 플레이어에게 | ✅ | showdown.dart:L120+ — _splitPot() dealerSeat 기준 | ✅ showdown_test |
| GE-06-08 | Hi/Lo split pot 분배 (50/50) | ✅ | showdown.dart:L74-98 — _awardHiLo() | ⚠️ Hi/Lo variant 통합 테스트 필요 |
| GE-06-09 | 2인 simple side pot (동일 스택) | ✅ | pot_test:L43-51 — heads-up 1개 pot | ✅ scenarios/04-nlh-split-pot |
| GE-06-10 | 3인 cascade side pot (모두 다른 스택) | ✅ | pot_test:L17-29 — 3개 pot 정확 | ✅ scenarios/03-nlh-3way-side-pot |
| GE-06-11 | No-Low scoop: Lo qualifier 미충족 → Hi 전체 수령 | ✅ | showdown.dart — no-low 케이스 | ✅ scenarios/09-omaha-hilo-no-qualifier |

---

## SECTION 7 — Showdown (BS-06-07)

| # | 요구사항 | 구현 | 근거 | 테스트 |
|---|----------|:----:|------|:------:|
| GE-07-01 | getRevealOrder(): last aggressor first → 시계방향 | ✅ | showdown_order.dart:L10-46 — lastAgg 기반 | ⚠️ 전용 테스트 필요 |
| GE-07-02 | Muck 권리: showdown 시 패자가 카드 숨기기 가능 | ⚠️ | event.dart:L74-78 — MuckDecision 정의, enforce 지점 불명확 | ⚠️ |
| GE-07-03 | Venue Canvas: 홀카드 절대 미공개 | ✅ | showdown_order.dart:L59 — CanvasType.venue return false | ✅ |
| GE-07-04 | Broadcast Canvas: 홀카드 항상 표시 | ✅ | showdown_order.dart:L59-72 — broadcast 케이스 | ✅ |
| GE-07-05 | 6가지 card_reveal_type enum (0-5) | ✅ | card_reveal_config.dart:L11-29 — RevealType enum | ✅ output_event_test |
| GE-07-06 | 4가지 show_type enum (0-3) | ✅ | card_reveal_config.dart:L32-44 — ShowType enum | ✅ |
| GE-07-07 | 2가지 fold_hide_type enum (0-1) | ✅ | card_reveal_config.dart:L47-53 — FoldHideType enum | ✅ |
| GE-07-08 | 48개 조합 유효성 매트릭스 검증 | ❌ | 구조 정의만, 48개 교차 검증 로직 없음 | ❌ |
| GE-07-09 | WRONG_CARD 감지 이벤트 | ✅ | output_event.dart:L82-87 — CardMismatchDetected | ✅ output_event_test |
| GE-07-10 | lastAggressor 추적 (betting_round에서) | ✅ | betting_round.dart:L5 + betting_rules.dart:L140,156,178 — 업데이트 | ✅ |

---

## SECTION 8 — Exceptions (BS-06-08)

| # | 요구사항 | 구현 | 근거 | 테스트 |
|---|----------|:----:|------|:------:|
| GE-08-01 | All Fold 감지 (activeCount <= 1) | ✅ | engine.dart:L328-332 — activeCount 체크 | ✅ scenarios/02,20 |
| GE-08-02 | All Fold → 1인에게 팟 지급 | ✅ | engine.dart:L328 → actionOn=-1 → _awardPot() | ✅ scenarios/20-nlh-all-fold-preflop |
| GE-08-03 | All-in Runout 감지 | ✅ | engine.dart:L80-84 — `active.isEmpty && allIn >= 2` | ✅ scenarios/26-nlh-all-in-runout |
| GE-08-04 | All-in Runout → 보드 자동 딜 트리거 | ⚠️ | 감지 로직 있으나 자동 보드 완성 harness 의존 | ⚠️ |
| GE-08-05 | Bomb Pot: PRE_FLOP 스킵 + 전원 contribution | ✅ | engine.dart:L241-259 — bombPotEnabled 분기 | ✅ scenarios/19 |
| GE-08-06 | Run It Twice: RunItChoice event 처리 | ⚠️ | event.dart:L60-62 정의, engine.dart 핸들러 불완전 | ⚠️ scenarios/30-nlh-run-it-twice |
| GE-08-07 | Run It Twice: 2회차 독립 판정 + 결과 합산 | ❌ | _handleRunItChoice() 미완성 | ❌ |
| GE-08-08 | Miss Deal: pot=0 + stacks 원상 복구 | ⚠️ | engine.dart:L507-528 — 스켈레톤 존재, 완전 복구 검증 필요 | ⚠️ scenarios/21-nlh-misdeal |
| GE-08-09 | Timeout Fold: 시간 초과 → 자동 Fold/Check | ✅ | event.dart — TimeoutFold 이벤트 정의 | ✅ scenarios/24-nlh-timeout-fold |
| GE-08-10 | Muck Decision: 쇼다운 시 패자 카드 숨기기 | ✅ | event.dart:L74-78 — MuckDecision 이벤트 | ✅ scenarios/25-nlh-muck-decision |
| GE-08-11 | RFID Failure: 5회 재시도 → 수동 입력 모드 | ❌ | 미구현 (CC/harness 계층) | — |
| GE-08-12 | Card Mismatch: UNDO 또는 수동 입력 전환 | ✅ | output_event.dart — CardMismatchDetected 정의 | ⚠️ |
| GE-08-13 | Network Disconnect: state 보존 + 재연결 | ❌ | 미구현 | — |

---

## SECTION 9 — Event Catalog (BS-06-09)

| # | 요구사항 | 구현 | 근거 | 테스트 |
|---|----------|:----:|------|:------:|
| GE-09-01 | IE-01 HandStart event | ✅ | event.dart:L9-13 — HandStart | ✅ |
| GE-09-02 | IE-02 PlayerAction event (seat, action) | ✅ | event.dart:L31-35 — PlayerAction | ✅ |
| GE-09-03 | IE-03 DealCommunity event | ✅ | event.dart:L20-22 | ✅ |
| GE-09-04 | IE-04 DealHoleCards event | ✅ | event.dart:L15-18 | ✅ |
| GE-09-05 | IE-05 ManualNextHand event | ✅ | event.dart:L65-67 | ✅ |
| GE-09-06 | IE-06 Undo event | ❌ | event.dart에 Undo 이벤트 없음 | ❌ |
| GE-09-07 | IE-07 MisDeal event | ✅ | event.dart:L51-53 | ✅ scenarios/21 |
| GE-09-08 | IE-08 RunItChoice event | ✅ | event.dart:L60-63 | ✅ scenarios/30 |
| GE-09-09 | IE-09 BombPotConfig event | ✅ | event.dart:L55-58 | ✅ scenarios/19 |
| GE-09-10 | IT-01 Blinds 자동 포스팅 (internal) | ✅ | engine.dart:L160-169 — _startHand() | ✅ |
| GE-09-11 | IT-02 BettingRoundComplete 감지 (internal) | ✅ | betting_rules.dart:L189-212 | ✅ |
| GE-09-12 | IT-03 AllFoldDetected (internal) | ✅ | engine.dart:L328-332 | ✅ |
| GE-09-13 | IT-04 AllInRunout 감지 (internal) | ⚠️ | isAllInRunout() 있으나 자동 SHOWDOWN 전이 미연결 | ⚠️ |
| GE-09-14 | OE-01~10 OutputEvent 10종 정의 | ✅ | output_event.dart:L6-69 — 10종 전부 | ✅ output_event_test |
| GE-09-15 | ReduceResult (state + outputs 쌍) | ✅ | reduce_result.dart | ✅ output_event_test |
| GE-09-16 | Input → Internal → Output cascading 규칙 | ⚠️ | 구조 존재, 일부 cascading 미완성 | ⚠️ |

---

## SECTION 10 — Action Rotation (BS-06-10)

| # | 요구사항 | 구현 | 근거 | 테스트 |
|---|----------|:----:|------|:------:|
| GE-10-01 | determine_first_to_act() PRE_FLOP Heads-up: Dealer(SB) 선행 | ✅ | street_machine.dart:L39-43 — `if (n==2) return sbSeat` | ✅ scenarios/13 |
| GE-10-02 | determine_first_to_act() PRE_FLOP 3인+: UTG | ✅ | street_machine.dart:L48-49 — nextActiveSeat(bbSeat) | ✅ |
| GE-10-03 | determine_first_to_act() POST_FLOP: SB/dealer-left | ✅ | street_machine.dart:L52-53 | ✅ |
| GE-10-04 | determine_first_to_act() Straddle: 다음 사람 | ✅ | street_machine.dart:L44-46 — straddleEnabled 분기 | ✅ |
| GE-10-05 | next_active_player(): 시계방향, fold/allIn 스킵 | ✅ | street_machine.dart:L57-64 — modulo 순환 | ✅ street_machine_test |
| GE-10-06 | is_betting_round_complete(): active <= 1 | ✅ | betting_rules.dart:L190-193 | ✅ betting_rules_test |
| GE-10-07 | is_betting_round_complete(): 모두 동액 | ✅ | betting_rules.dart:L209-211 | ✅ betting_rules_test |
| GE-10-08 | is_betting_round_complete(): 최소 1회 순환 (actedThisRound) | ✅ | betting_rules.dart:L203,209 | ✅ |
| GE-10-09 | is_betting_round_complete(): BB option pending → false | ✅ | betting_rules.dart:L208 — bbOptionPending 체크 | ✅ |
| GE-10-10 | Raise 후 action 재개 (actedThisRound 리셋) | ✅ | betting_rules.dart:L165 — `actedThisRound = {seatIndex}` | ✅ |
| GE-10-11 | Dead Button 처리 | ⚠️ | sittingOut 스킵은 있으나 명시적 dead button 규칙 없음 | ⚠️ |

---

## SECTION 11 — Short Deck (BS-06-11)

| # | 요구사항 | 구현 | 근거 | 테스트 |
|---|----------|:----:|------|:------:|
| GE-11-01 | 36장 덱 (2~5 제거) | ✅ | deck.dart:L20-29 — Deck.shortDeck() | ✅ short_deck_test:L13-14 |
| GE-11-02 | game_id=1: Straight > Trips | ✅ | hand_evaluator.dart:L34-45 — shortDeck6PlusOrder | ✅ short_deck_test:L23-27 |
| GE-11-03 | game_id=2: Trips > Straight (Triton) | ✅ | hand_evaluator.dart:L47-59 — shortDeckTritonOrder | ✅ short_deck_test:L30-37 |
| GE-11-04 | evaluator = standard_high_modified 라우팅 | ✅ | short_deck.dart:L25 — categoryOrder 참조 | ✅ |
| GE-11-05 | Short Deck Wheel (A-6-7-8-9) 인식 | ❌ | KI-01: hand_evaluator.dart:L278-294 — A-2-3-4-5만 처리 | ❌ |
| GE-11-06 | Short Deck Steel Wheel (A-6-7-8-9 동일 수트) | ❌ | KI-01 파생: Straight Flush 미인식 | ❌ |
| GE-11-07 | 덱 크기 검증 (36장 != 52장) | ⚠️ | Deck.shortDeck()는 36장 생성, 검증 로직은 없음 | ⚠️ |

---

## SECTION 12 — Pineapple (BS-06-12)

| # | 요구사항 | 구현 | 근거 | 테스트 |
|---|----------|:----:|------|:------:|
| GE-12-01 | 3장 홀카드 딜 | ✅ | pineapple.dart — holeCardCount=3 | ✅ pineapple_test |
| GE-12-02 | DISCARD_PHASE FSM 상태 | ⚠️ | requiresDiscard=true 정의만, FSM 상태 미구현 | ⚠️ |
| GE-12-03 | discard_pending 상태변수 | ❌ | 게임 엔진 상태 관리 없음 | ❌ |
| GE-12-04 | 비동기 discard 완료 추적 | ❌ | 미구현 | ❌ |
| GE-12-05 | DISCARD_TIMEOUT 30초 → 수동 입력 | ❌ | 미구현 | ❌ |
| GE-12-06 | Discard 후 evaluator = standard_high | ✅ | pineapple.dart:L38-42 — evaluateHi | ✅ |
| GE-12-07 | PineappleDiscard event 정의 | ✅ | event.dart — PineappleDiscard | ✅ scenarios/10 |

---

## SECTION 13 — Omaha (BS-06-13)

| # | 요구사항 | 구현 | 근거 | 테스트 |
|---|----------|:----:|------|:------:|
| GE-13-01 | Omaha 4장 (holeCardCount=4) | ✅ | omaha.dart:L14 | ✅ omaha_test |
| GE-13-02 | 5-Card Omaha (holeCardCount=5) | ✅ | five_card_omaha.dart:L17 | ✅ scenarios/12 |
| GE-13-03 | 6-Card Omaha (holeCardCount=6) | ✅ | six_card_omaha.dart:L17 | ✅ |
| GE-13-04 | Must-Use 2+3: C(n,2) × C(5,3) 평가 | ✅ | hand_evaluator.dart:L120-137 — bestOmaha | ✅ omaha_test |
| GE-13-05 | Hi-Lo split: hilo_8or_better evaluator | ✅ | omaha_hilo.dart:L38-40 — evaluateLo | ✅ omaha_hilo_test |
| GE-13-06 | Lo qualifier 미충족 → Hi scoop | ✅ | hand_evaluator.dart:L142-173 — null 반환 | ✅ scenarios/09 |
| GE-13-07 | Hi/Lo Odd Chip → Hi 우선 | ❌ | KI-02 영향: showdown.dart Hi/Lo 분배 | ❌ |
| GE-13-08 | Omaha 5 Hi-Lo variant | ✅ | five_card_omaha_hilo.dart | ✅ |
| GE-13-09 | Omaha 6 Hi-Lo variant | ✅ | six_card_omaha_hilo.dart | ✅ |

---

## SECTION 14 — Courchevel (BS-06-14)

| # | 요구사항 | 구현 | 근거 | 테스트 |
|---|----------|:----:|------|:------:|
| GE-14-01 | SETUP에서 board_1 카드 공개 (preflopCommunityCount=1) | ⚠️ | courchevel.dart:L26 — 필드 정의만, RFID 감지 미연결 | ⚠️ scenarios/11 |
| GE-14-02 | FLOP 추가 2장만 (3장 감지 시 에러) | ❌ | 검증 로직 없음 | ❌ |
| GE-14-03 | Must-Use 2+3 (Omaha 5 기준) | ✅ | courchevel.dart:L29-31 — mustUseHole=2, mustUseCommunity=3 | ✅ |
| GE-14-04 | Hi-Lo variant (game_id=11) | ✅ | courchevel_hilo.dart — hiLo 파라미터 | ✅ |
| GE-14-05 | Courchevel preflop 카드 강제 사용 | ❌ | KI-07: courchevel.dart:L35 — bestOmaha가 C(5,3) 자유 선택, 강제 없음 | ❌ |

---

## SECTION 15 — Draw Lifecycle (BS-06-21)

| # | 요구사항 | 구현 | 근거 | 테스트 |
|---|----------|:----:|------|:------:|
| GE-15-01 | DRAW_ROUND FSM 상태 추가 | ❌ | Draw 게임 전체 미구현 | ❌ |
| GE-15-02 | POST_DRAW_BET 상태 추가 | ❌ | 미구현 | ❌ |
| GE-15-03 | draw_count 설정 (1회 또는 3회) | ❌ | 미구현 | ❌ |
| GE-15-04 | STAND PAT 처리 (교환 0장) | ❌ | 미구현 | ❌ |
| GE-15-05 | 덱 소진 시 reshuffle (discard pile 재사용) | ❌ | 미구현 | ❌ |
| GE-15-06 | All-in 플레이어 교환 스킵 | ❌ | 미구현 | ❌ |
| GE-15-07 | All Fold → SHOWDOWN 스킵, HAND_COMPLETE 직행 | ❌ | 미구현 | ❌ |

---

## SECTION 16 — Draw Evaluation (BS-06-22)

| # | 요구사항 | 구현 | 근거 | 테스트 |
|---|----------|:----:|------|:------:|
| GE-16-01 | draw5: standard_high evaluator | ❌ | Draw 게임 미구현 | ❌ |
| GE-16-02 | deuce7_draw / triple: lowball_27 (A=High) | ❌ | 미구현 | ❌ |
| GE-16-03 | a5_triple: lowball_a5 (A=Low) | ❌ | 미구현 | ❌ |
| GE-16-04 | badugi: 4장 게임, 고유 suit×rank 평가 | ❌ | 미구현 | ❌ |
| GE-16-05 | badeucy: hilo_badugi_27 split | ❌ | 미구현 | ❌ |
| GE-16-06 | badacey: hilo_badugi_a5 split | ❌ | 미구현 | ❌ |

---

## SECTION 17 — Stud Lifecycle (BS-06-31)

| # | 요구사항 | 구현 | 근거 | 테스트 |
|---|----------|:----:|------|:------:|
| GE-17-01 | 3RD~7TH Street FSM 상태 | ❌ | Stud 게임 전체 미구현 | ❌ |
| GE-17-02 | Bring-in: 최저 door card 결정 | ❌ | 미구현 | ❌ |
| GE-17-03 | Street별 카드 배분 (2down+1up → +1up × 3 → +1down) | ❌ | 미구현 | ❌ |
| GE-17-04 | First to Act: 3RD=bring-in, 4~7TH=visible hand | ❌ | 미구현 | ❌ |
| GE-17-05 | 4TH pair visible → big bet 선택 활성화 | ❌ | 미구현 | ❌ |
| GE-17-06 | 7TH 덱 부족 → 커뮤니티 카드 1장 공개 | ❌ | 미구현 | ❌ |
| GE-17-07 | Ante + Bring-in 시스템 (Blind 비활성) | ❌ | 미구현 | ❌ |
| GE-17-08 | Razz bring-in 역순 (최고 door card) | ❌ | 미구현 | ❌ |

---

## SECTION 18 — Stud Evaluation (BS-06-32)

| # | 요구사항 | 구현 | 근거 | 테스트 |
|---|----------|:----:|------|:------:|
| GE-18-01 | stud7: standard_high (best 5 of 7) | ❌ | Stud 게임 미구현 | ❌ |
| GE-18-02 | stud7_hilo8: hilo_8or_better split | ❌ | 미구현 | ❌ |
| GE-18-03 | razz: lowball_a5 (A=Low) | ❌ | 미구현 | ❌ |
| GE-18-04 | C(7,5)=21 조합 best hand 선택 | ❌ | 미구현 | ❌ |
| GE-18-05 | 8-or-better Lo qualifier | ❌ | 미구현 | ❌ |
| GE-18-06 | Razz wheel (A-2-3-4-5) = 최고 | ❌ | 미구현 | ❌ |

---

## Gap Analysis

### 심각도별 미구현 항목

| 심각도 | # | 항목 | KI | 설명 |
|:------:|---|------|:--:|------|
| **CRITICAL** | GE-06-06 | Side Pot engine 호출 누락 | KI-03 | calculateSidePots()가 engine.dart에서 호출되지 않음 + currentBet 리셋 |
| **CRITICAL** | GE-05-14 | Hi/Lo Odd Chip Lo 할당 | KI-02 | WSOP Rule 73 위반 — Hi에게 할당해야 함 |
| **CRITICAL** | GE-11-05 | Short Deck Wheel 미인식 | KI-01 | A-6-7-8-9 스트레이트 미인식 |
| **HIGH** | GE-01-16 | 무효 상태 전이 미차단 | KI-09 | PRE_FLOP→RIVER 직행 등 허용 |
| **HIGH** | GE-02-16 | Raise 스택 초과 음수 | KI-05 | toAmount > stack 시 방어 없음 |
| **HIGH** | GE-14-05 | Courchevel preflop 강제 | KI-07 | board_1 카드 포함 조합만 유효해야 함 |
| **HIGH** | GE-08-07 | Run It Twice 합산 미구현 | — | 2회차 독립 판정 + 합산 로직 없음 |
| **HIGH** | GE-09-06 | Undo event 미정의 | — | Event Sourcing에서 핵심 기능 누락 |
| **MEDIUM** | GE-04-02~08 | Coalescence 전체 미구현 | — | 트리거 우선순위, 시간 윈도우, RFID debounce (CC 통합 시 구현) |
| **MEDIUM** | GE-12-03~05 | Pineapple DISCARD_PHASE | — | FSM 상태 및 추적 로직 미구현 |
| **LOW** | GE-15-01~07 | Draw 게임 전체 | — | Phase 3 범위 (22종 확장 시) |
| **LOW** | GE-17-01~08 | Stud 게임 전체 | — | Phase 3 범위 (22종 확장 시) |
| **LOW** | GE-16-01~06 | Draw evaluator 전체 | — | Phase 3 범위 |
| **LOW** | GE-18-01~06 | Stud evaluator 전체 | — | Phase 3 범위 |

### Known Issue 전체 매핑

| KI | 심각도 | 체크리스트 항목 | 상태 |
|:--:|:------:|----------------|:----:|
| KI-01 | Critical | GE-11-05, GE-11-06 | Gap Analysis |
| KI-02 | Critical | GE-05-14, GE-13-07 | Gap Analysis |
| KI-03 | Critical | GE-06-06 | Gap Analysis |
| KI-04 | Major | GE-01-02 (순수함수 위반은 FSM 전반에 영향) | 체크리스트 내 ⚠️ |
| KI-05 | Major | GE-02-16 | Gap Analysis |
| KI-06 | Major | — (server.dart, harness 전용) | 게임 엔진 Core 범위 외 |
| KI-07 | Major | GE-14-05 | Gap Analysis |
| KI-08 | Major | — (server.dart, harness 전용) | 게임 엔진 Core 범위 외 |
| KI-09 | Important | GE-01-16 | Gap Analysis |
| KI-10 | Important | §0~18 전반 (테스트 ❌ 항목) | 체크리스트 테스트 열 참조 |
| KI-11 | Important | GE-02-12 관련 (dead field) | 체크리스트 내 ⚠️ |
| KI-12 | Critical | GE-02-06 (Call.amount 외부값 적용) | Gap Analysis + GAP-GE-003 |
| KI-13 | Major | GE-09-06 관련 (Session.undo 무제한) | Gap Analysis + GAP-GE-004 |
| KI-14 | Major | GE-00-09 관련 (EventLog dead code) | Gap Analysis + GAP-GE-005 |

---

## 현재 상태 요약

> **BS-06 기준 완전 구현율: 58.7%** (115/196 항목 ✅)
> **부분 포함 구현율: 64.5%** ((115 + 23×0.5) / 196)

### 영역별 통계

| 섹션 | BS 원본 | 전체 | ✅ | ⚠️ | ❌ |
|------|---------|:----:|:--:|:--:|:--:|
| §0 Reference | BS-06-00 | 8 | 8 | 0 | 0 |
| §1 Lifecycle | BS-06-01 | 16 | 10 | 5 | 1 |
| §2 Betting | BS-06-02 | 17 | 13 | 2 | 2 |
| §3 Blinds/Ante | BS-06-03 | 14 | 11 | 2 | 1 |
| §4 Coalescence | BS-06-04 | 8 | 0 | 0 | 7 |
| §5 Evaluation | BS-06-05 | 17 | 13 | 2 | 2 |
| §6 Side Pot | BS-06-06 | 11 | 8 | 1 | 2 |
| §7 Showdown | BS-06-07 | 10 | 7 | 2 | 1 |
| §8 Exceptions | BS-06-08 | 13 | 7 | 3 | 3 |
| §9 Events | BS-06-09 | 16 | 12 | 2 | 2 |
| §10 Rotation | BS-06-10 | 11 | 10 | 1 | 0 |
| §11 Short Deck | BS-06-11 | 7 | 4 | 1 | 2 |
| §12 Pineapple | BS-06-12 | 7 | 3 | 1 | 3 |
| §13 Omaha | BS-06-13 | 9 | 7 | 0 | 2 |
| §14 Courchevel | BS-06-14 | 5 | 2 | 1 | 2 |
| §15 Draw Life | BS-06-21 | 7 | 0 | 0 | 7 |
| §16 Draw Eval | BS-06-22 | 6 | 0 | 0 | 6 |
| §17 Stud Life | BS-06-31 | 8 | 0 | 0 | 8 |
| §18 Stud Eval | BS-06-32 | 6 | 0 | 0 | 6 |
| **합계** | | **196** | **115** | **23** | **57** |

### Phase별 진행

| Phase | 대상 | 상태 |
|:-----:|------|:----:|
| **Phase 1 POC** | §0~5 (Hold'em Core + NL) | **~76%** (55/72, §4 Coalescence 제외 — CC 통합 계층) — Critical 3건 수정 필요 |
| **Phase 2 Hold'em** | §6~10 + §11~14 (변형 + 예외) | **~65%** — Side Pot 통합, Run It Twice 완성 필요 |
| **Phase 3 22종** | §15~18 (Draw + Stud) | **0%** — 미착수 |

### 핵심 미구현 (CRITICAL+HIGH)

1. **KI-01**: Short Deck Wheel (A-6-7-8-9) 미인식 → `hand_evaluator.dart` 수정
2. **KI-02**: Hi/Lo odd chip Lo 할당 → `showdown.dart` 수정
3. **KI-03**: Side Pot engine 호출 누락 → `engine.dart` + `pot.dart` 통합
4. **KI-05**: Raise 스택 초과 음수 → `betting_rules.dart` 방어 추가
5. **KI-07**: Courchevel preflop 카드 강제 → `courchevel.dart` 평가 제약
6. **KI-09**: 무효 상태 전이 미차단 → `engine.dart` StreetAdvance 검증
7. Run It Twice 2회차 합산 → `engine.dart` 핸들러 완성
8. Undo event → `event.dart` 추가 + `engine.dart` 핸들러
