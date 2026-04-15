---
title: Event Catalog
owner: team3
tier: internal
legacy-id: BS-06-09
last-updated: 2026-04-15
---

# BS-06-09: 게임 엔진 이벤트 카탈로그

> **존재 이유**: `test/contract/spec_contract_test.dart`가 IE-02 등 엔트리를 직접 인용하는 이벤트 카탈로그.

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | Input/Internal/Output 3계층 이벤트 정의, payload 스키마, 유효 상태 매트릭스 |
| 2026-04-09 | IE-02 보강 → Call/AllIn amount 처리 주의사항 | Contract Test FAIL 근거: 외부 amount 무시, 엔진 내부 재계산 강제 명시 |
| 2026-04-10 | WSOP P1/P2 규정 반영 | Input Events에 IE-10 BombPotOptOut (Rule 28.3.2), IE-11 TableHand (Rule 71), IE-12 ManagerRuling (Rule 71/89/109/110), IE-13 DeckChangeRequest (Rule 78) 신설. Internal Transitions에 IT-DealCommunityRecovery (Rule 89) 신설. Output Events에 OE-HandTabled, OE-HandRetrieved, OE-MuckRetrieved, OE-FlopRecovered, OE-DeckIntegrityWarning 신설. CCR-DRAFT-team3-20260410-wsop-conformance P1-5/P1-7/P1-8/P2-10/P2-14 반영 |
| 2026-04-13 | GAP-B 보강 | OE-05 legalActions payload 상세 추가, Output Accumulation 순서 규칙 추가, OE-19 display_to_players 플래그 조건 보강 |

> **이 문서는 개발팀 전용 API 레퍼런스입니다.** 게임 엔진이 어떤 신호를 받고, 내부에서 어떻게 처리하고, 화면에 무엇을 보내는지를 정리한 목록입니다.

---

> **이 문서에서 사용하는 용어**
>
> | 용어 | 설명 |
> |------|------|
> | sealed class | 정해진 종류만 존재할 수 있는 프로그래밍 분류 체계 |
> | reducer | 현재 상태와 이벤트를 받아 새로운 상태를 만드는 함수 |
> | dispatch | 이벤트를 처리 함수에 전달하는 것 |
> | payload | 이벤트에 딸려오는 데이터 |
> | cascade | 하나의 이벤트가 연쇄적으로 다른 이벤트를 발생시키는 것 |
> | RFID | 무선 주파수로 카드를 자동 인식하는 기술 |
> | CC | Command Center, 운영자가 게임을 제어하는 화면 |

## 개요

게임 엔진의 모든 이벤트를 **3계층**(Input, Internal, Output)으로 분류하고, 각 이벤트의 payload 필드 스키마를 정의한다. 이 문서는 `game_event.dart` sealed class 계층의 **설계 근거**이며, 모든 reducer가 참조하는 이벤트 사전이다.

**3계층 분류**:

```
┌─────────────────────────────────────────────┐
│             Input Events                     │
│  CC 버튼 / RFID 감지 → 엔진에 전달          │
│  (sealed class GameEvent의 직계 멤버)        │
└──────────────────┬──────────────────────────┘
                   ↓ reduce(state, event)
┌─────────────────────────────────────────────┐
│           Internal Transitions               │
│  reducer 내부에서 조건 충족 시 자동 수행      │
│  (외부에서 dispatch하지 않음)                 │
└──────────────────┬──────────────────────────┘
                   ↓ 상태 변경 완료
┌─────────────────────────────────────────────┐
│            Output Events                     │
│  엔진 → UI/오버레이/통계 모듈에 알림         │
│  (ReduceResult.outputs 리스트)               │
└─────────────────────────────────────────────┘
```

---

## Input Events — CC/RFID → 엔진

Input Event는 `game_event.dart`의 sealed class 멤버로 정의된다. `reduce(HandState, GameEvent) → ReduceResult`의 두 번째 인자이다.

### IE-01: StartHand

| 필드 | 타입 | 설명 |
|------|------|------|
| — | — | payload 없음 |

- **소스**: CC (NEW HAND 버튼)
- **유효 상태**: `IDLE`, `HAND_COMPLETE`
- **전제조건**: BS-06-01 핸드 시작 전제조건 4개 충족 (`pl_dealer != -1`, `num_blinds ∈ 0~3`, `num_seats >= 2`, `state == IDLE`)
- **결과**: → `SETUP_HAND` (블라인드 수납 + 홀카드 딜 시작)
- **참조**: BS-06-01 유저 스토리 #2

### IE-02: PlayerAction

| 필드 | 타입 | 설명 |
|------|------|------|
| `seat` | int | 액션 플레이어의 좌석 번호 |
| `action` | ActionType enum | fold / check / bet / call / raise / allIn |
| `amount` | int? | 베팅 금액 (bet/raise만 필수, 나머지 null) |

- **소스**: CC (6개 액션 버튼 + 금액 입력)
- **유효 상태**: `PRE_FLOP`, `FLOP`, `TURN`, `RIVER`
- **전제조건**: BS-06-02 전제조건 6개 (`hand_in_progress`, `action_on == seat`, `player.status == active` 등)
- **결과**: 상태 변경 (BS-06-02 액션 정의서), 이후 `action_on` 순환 (BS-06-10)
- **참조**: BS-06-02 전체, BS-06-10 액션 순환

> 참고: `amount` 검증은 `ActionValidator`가 처리. 유효하지 않은 금액은 `REJECTED` output event 발생.

> **주의 — Call/AllIn의 amount 처리**: Call과 AllIn의 금액은 엔진이 내부에서 재계산한다. IE-02의 `amount` 필드에 값이 전달되더라도 무시하고 `biggest_bet_amt - current_bet` (Call) 또는 `player.stack` (AllIn)으로 대체한다. 외부 전달값을 그대로 적용하면 명세 위반이다.

### IE-03: BoardCardRevealed

| 필드 | 타입 | 설명 |
|------|------|------|
| `cards` | List\<PlayingCard\> | 공개된 보드 카드 (1~3장) |

- **소스**: RFID (보드 카드 감지) 또는 CC (수동 입력)
- **유효 상태**: `PRE_FLOP` (→ FLOP, 3장), `FLOP` (→ TURN, 1장), `TURN` (→ RIVER, 1장)
- **전제조건**: `betting_round_complete == true` (현재 스트리트 베팅 완료)
- **결과**: `board_cards` 갱신, 다음 스트리트로 전이
- **참조**: BS-06-01 매트릭스 3

### IE-04: HoleCardDetected

| 필드 | 타입 | 설명 |
|------|------|------|
| `seat` | int | 해당 좌석 번호 |
| `card` | PlayingCard | 감지된 카드 |

- **소스**: RFID (홀카드 감지)
- **유효 상태**: `SETUP_HAND`
- **전제조건**: `hand_in_progress == true`, 해당 좌석의 홀카드 미완성
- **결과**: `player[seat].hole_cards` 갱신. 모든 플레이어 홀카드 완성 시 → `PRE_FLOP` 자동 전이
- **참조**: BS-06-01 유저 스토리 #3

### IE-05: ManualNextHand

| 필드 | 타입 | 설명 |
|------|------|------|
| — | — | payload 없음 |

- **소스**: CC (Next Hand 버튼 또는 overrideButton)
- **유효 상태**: `HAND_COMPLETE`
- **결과**: → `IDLE` (board_cards 리셋, action_on = -1)
- **참조**: BS-06-01 유저 스토리 #14

### IE-06: Undo

| 필드 | 타입 | 설명 |
|------|------|------|
| — | — | payload 없음 |

- **소스**: CC (UNDO 버튼)
- **유효 상태**: `SETUP_HAND` ~ `HAND_COMPLETE` (hand_in_progress 중)
- **전제조건**: `undo_depth < 5` (최대 5단계)
- **결과**: event log에서 마지막 이벤트 제거, 이전 상태 복원
- **참조**: BS-06-01 유저 스토리 #15, BS-06-08

### IE-07: MissDeal

| 필드 | 타입 | 설명 |
|------|------|------|
| — | — | payload 없음 |

- **소스**: CC (Miss Deal 버튼) 또는 엔진 자동 (카드 불일치 감지)
- **유효 상태**: `SETUP_HAND` (홀카드 수 불일치 시)
- **결과**: → `IDLE`, pot 복귀, stacks 복구, board_cards 리셋
- **참조**: BS-06-01 유저 스토리 #16, BS-06-08

### IE-08: RunItChoice

| 필드 | 타입 | 설명 |
|------|------|------|
| `times` | int | Run It 횟수 (2 또는 3) |

- **소스**: CC (플레이어 동의 후 운영자 입력)
- **유효 상태**: `SHOWDOWN` (all-in 상황, 2+ 플레이어)
- **전제조건**: 모든 관련 플레이어 동의
- **결과**: → `RUN_IT_MULTIPLE`, run_it_times_remaining 설정
- **참조**: BS-06-01 유저 스토리 #11, BS-06-07

### IE-09: BombPotConfig

| 필드 | 타입 | 설명 |
|------|------|------|
| `amount` | int | 전원 납부 금액 |

- **소스**: CC (Bomb Pot 설정)
- **유효 상태**: `IDLE` (StartHand 전에 설정)
- **결과**: `bomb_pot_enabled = true`, `bomb_pot_amount` 설정. 다음 StartHand 시 PRE_FLOP 스킵
- **참조**: BS-06-01 Bomb Pot 상태 전이 변형

### IE-10: BombPotOptOut (WSOP Rule 28.3.2)

| 필드 | 타입 | 설명 |
|------|------|------|
| `seat_index` | int | Opt-out 신청 플레이어 |

- **소스**: CC (플레이어 요청 대행)
- **유효 상태**: `SETUP_HAND` (`bomb_pot_enabled == true`)
- **전제조건**: `state.bomb_pot_opted_out`에 아직 포함되지 않은 seat
- **결과**: `seat.status = SEATED_OUT`, `state.bomb_pot_opted_out.add(seat_index)`. Button freeze로 position equity 보존
- **참조**: BS-06-01 §Bomb Pot Button Freeze & Opt-Out, WSOP Rule 28.3.2

### IE-11: TableHand (WSOP Rule 71)

| 필드 | 타입 | 설명 |
|------|------|------|
| `seat_index` | int | 카드를 공개하는 플레이어 |

- **소스**: CC (showdown 시점 플레이어 요청 대행)
- **유효 상태**: `SHOWDOWN`, `HAND_COMPLETE` 직전
- **전제조건**: `seat.holeCards`가 존재하고 not folded
- **결과**: `seat.cards_tabled = true`. 이후 엔진의 임의 muck 금지 (Rule 71 보호 활성)
- **참조**: BS-06-07 §핸드 보호 & 복구 §Tabled Hand 보호, WSOP Rule 71

### IE-12: ManagerRuling (WSOP Rules 71, 89, 109, 110)

| 필드 | 타입 | 설명 |
|------|------|------|
| `decision` | str | "retrieve_fold" \| "kill_hand" \| "muck_retrieve" \| "recover_four_card_flop" 중 하나 |
| `target_seat` | int? | 대상 seat (decision에 따라 필수 여부 상이) |
| `rationale` | str? | 운영자 사유 (감사 로그용, 필수 권장) |

- **소스**: CC (Floor/Manager 권한 필요)
- **유효 상태**: `EXCEPTION_*` 상태, `SHOWDOWN`, `HAND_COMPLETE` 직전
- **전제조건**: decision별 상이
  * `retrieve_fold`: UNDO 가능 (5단계 내), Fold 이벤트가 직전
  * `kill_hand`: 해당 seat의 cards_tabled == false (tabled hand는 Rule 71로 보호)
  * `muck_retrieve`: muck_log에 해당 카드 정보 존재, 해당 seat가 winning hand
  * `recover_four_card_flop`: `state.community.length == 4` 상태
- **결과**: decision에 따른 복구/판정 수행
  * `retrieve_fold`: `session.undo()` 호출, `OutputEvent.HandRetrieved` 발행
  * `kill_hand`: `seat.status = FOLDED`, `OutputEvent.HandKilled` 발행
  * `muck_retrieve`: muck_log에서 카드 복원, `OutputEvent.MuckRetrieved` 발행
  * `recover_four_card_flop`: 4장 shuffle, 1장 burn 보존, `OutputEvent.FlopRecovered` 발행
- **참조**: BS-06-07 §핸드 보호 & 복구, BS-06-08 §Four-Card Flop 복구

### IE-13: DeckChangeRequest (WSOP Rule 78)

| 필드 | 타입 | 설명 |
|------|------|------|
| `reason` | str | "level_change" \| "dealer_push" \| "card_damage" \| "staff_request" \| "player_request_damage" 중 하나 |
| `requested_by` | str | 요청자 식별 ("BO", "Staff", "Manager", etc.) |

- **소스**: BO (자동) 또는 CC (수동)
- **유효 상태**: `HAND_COMPLETE` (현재 핸드 종료 후에만 허용)
- **전제조건**: Bomb pot / Run It Multiple 진행 중 아님
- **결과**: DeckFSM 상태 전이 트리거 (REGISTERED → UNREGISTERED). `OutputEvent.DeckChangeStarted` 발행
- **참조**: BS-06-08 §Deck Change 절차, WSOP Rule 78, DATA-03 DeckFSM

---

## Input Event 유효 상태 매트릭스

모든 `(state, event)` 조합의 처리를 정의한다. **불법 전이는 `REJECT`로 명시**.

| Event \ State | IDLE | SETUP | PRE_FLOP | FLOP | TURN | RIVER | SHOWDOWN | RUN_IT | COMPLETE |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **StartHand** | ✓ | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | ✓ |
| **PlayerAction** | REJECT | REJECT | ✓ | ✓ | ✓ | ✓ | REJECT | REJECT | REJECT |
| **BoardCardRevealed** | REJECT | REJECT | ✓→FLOP | ✓→TURN | ✓→RIVER | REJECT | REJECT | ✓ | REJECT |
| **HoleCardDetected** | REJECT | ✓ | IGNORE | IGNORE | IGNORE | IGNORE | IGNORE | IGNORE | IGNORE |
| **ManualNextHand** | IGNORE | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | ✓ |
| **Undo** | REJECT | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **MissDeal** | REJECT | ✓ | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT |
| **RunItChoice** | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | ✓ | REJECT | REJECT |
| **BombPotConfig** | ✓ | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT |
| **BombPotOptOut** | REJECT | ✓ | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT |
| **TableHand** | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | ✓ | REJECT | ✓ |
| **ManagerRuling** | REJECT | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **DeckChangeRequest** | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | ✓ |

> `✓` = 정상 처리, `REJECT` = 거부 (OutputEvent.Rejected 발생), `IGNORE` = 조용히 무시 (stray read 등), `✓→X` = 보드 카드 수에 따른 조건부 전이
>
> **ManagerRuling 특이사항**: decision별로 유효 상태가 달라진다. 매트릭스의 `✓`는 "엔진이 이벤트를 수신할 수 있음"을 의미하며, 실제 처리는 decision에 따라 거부될 수 있다. 예: `retrieve_fold`는 직전 Fold 이벤트가 있어야만 수행됨.

---

## Internal Transitions — 엔진 자동 (reducer 내부)

외부에서 dispatch하지 않는다. `reduce()` 내부에서 조건 충족 시 연쇄 수행된다.

| ID | 이름 | 트리거 조건 | 결과 | 참조 |
|:--:|------|-----------|------|------|
| IT-01 | **BlindsAutoPost** | StartHand 처리 시 자동 | SB/BB/Ante 수납, pot 갱신, biggest_bet_amt 설정 | BS-06-03 |
| IT-02 | **DealComplete** | SETUP_HAND에서 모든 홀카드 감지 완료 | → PRE_FLOP, action_on = first_to_act | BS-06-01 #3 |
| IT-03 | **BettingRoundComplete** | 모든 active 플레이어 current_bet == biggest_bet_amt && 최소 1회 순환 완료 | → 다음 스트리트 대기 (board card 필요), current_bet 리셋 | BS-06-10 |
| IT-04 | **AllFoldDetected** | PlayerAction(Fold) 후 num_active_players == 1 | → HAND_COMPLETE, 남은 1인에게 팟 지급 | BS-06-01 #7 |
| IT-05 | **AllInDetected** | 모든 active 플레이어 status == allIn (또는 active 1명 + 나머지 allIn) | → SHOWDOWN, 남은 보드 자동 공개 대기 | BS-06-01 #8 |
| IT-06 | **ShowdownEvaluation** | SHOWDOWN 진입 시 자동 | 핸드 평가, 승자 결정, 팟 분배 | BS-06-05, BS-06-07 |
| IT-07 | **RunItComplete** | RUN_IT_MULTIPLE에서 run_it_times_remaining == 0 | → HAND_COMPLETE, 전체 런 합산 분배 | BS-06-01 #12 |
| IT-08 | **BombPotSkip** | StartHand 시 bomb_pot_enabled == true | SETUP → FLOP 직행 (PRE_FLOP 스킵) | BS-06-01 Bomb Pot |
| IT-09 | **ButtonFreezeBombPot** | HAND_COMPLETE 시 `bomb_pot_enabled == true` | `_endHand`의 dealer +1 이동 스킵, `state.bomb_pot_enabled = false`로 클리어 (WSOP Rule 28.3.2) | BS-06-01 §Bomb Pot Button Freeze |
| IT-10 | **ButtonFreezeMixedGame** | HAND_COMPLETE 시 `game_transition_pending == true` | `_endHand`의 dealer +1 이동 스킵, `current_game_index += 1`, 다음 게임으로 전환. `OutputEvent.GameTransitioned` 발행 (New Blind Type: Mixed Omaha) | BS-06-00-REF Ch1.9 Mixed Game |
| IT-11 | **HeadsUpButtonAdjust** | HAND_COMPLETE 시 3명+ → 2명 전환 감지 | 이전 BB 플레이어가 남아있으면 해당 seat을 dealer로 설정 (연속 BB 방지, WSOP Rule 87) | BS-06-03 §Heads-up 전환 |
| IT-12 | **MissedBlindMark** | HAND_COMPLETE 시 SITTING_OUT 플레이어가 SB/BB 포지션 | `seat.missed_sb` 또는 `seat.missed_bb = true` 설정 (WSOP Rule 86) | BS-06-03 §Missed Blind |
| IT-13 | **BoxedCardMisdealCheck** | DealHoleCards/DealCommunity 후 boxed card 감지 | `state.boxed_card_count += 1`. 2 이상이면 Misdeal 트리거 (WSOP Rule 88) | BS-06-08 §Boxed Card |
| IT-14 | **DealCommunityRecovery** | Flop 감지 시 `community.length > 3` | 4장 shuffle → 1장 burn 보존, 3장 flop, `OutputEvent.FlopRecovered` 발행 (WSOP Rule 89) | BS-06-08 §Four-Card Flop 복구 |
| IT-15 | **IncompleteAllInNoReopen** | PlayerAction(AllIn) 처리 시 `raise_increment < min_full_raise_increment` | `actedThisRound` 보존, `lastAggressor`/`minRaise` 불변, `currentBet`만 갱신 (WSOP Rule 96) | BS-06-02 §6.1 |
| IT-16 | **UnderRaiseAdjust** | PlayerAction(Raise) 처리 시 `requested_raise < min_raise_total` | 50% 이상이면 min_raise_total로 보정, 50% 미만이면 Call로 변환 (WSOP Rule 95) | BS-06-02 §5.1 |

---

## Output Events — 엔진 → UI/외부

`ReduceResult.outputs: List<OutputEvent>`로 반환된다. UI가 구독하여 화면 갱신, 애니메이션, 사운드를 트리거한다.

| ID | 이름 | payload | 용도 |
|:--:|------|---------|------|
| OE-01 | **StateChanged** | `{prevPhase, newPhase, handState}` | 상태 전이 알림 → 오버레이 갱신 |
| OE-02 | **ActionProcessed** | `{seat, action, amount, newStack}` | 액션 처리 완료 → CC 버튼 갱신, 애니메이션 |
| OE-03 | **PotUpdated** | `{mainPot, sidePots[]}` | 팟 금액 변경 → 오버레이 팟 표시 |
| OE-04 | **BoardUpdated** | `{cards[], street}` | 보드 카드 공개 → 오버레이 카드 표시 |
| OE-05 | **ActionOnChanged** | `{seat, legalActions[], timeBank?}` | 액션 턴 이동 → CC 버튼 활성/비활성 |

> **OE-05 `legalActions` payload 상세:**
>
> ```json
> legalActions: [
>   { "action": "fold" },
>   { "action": "check" },
>   { "action": "call", "amount": 100 },
>   { "action": "bet", "min": 20, "max": 1000 },
>   { "action": "raise", "min": 140, "max": 1000 },
>   { "action": "allIn", "amount": 500 }
> ]
> ```
>
> 각 액션의 min/max는 BetLimit(NL/PL/FL) 규칙에 따라 엔진이 계산. fold는 항상 포함 (active 상태만). check는 `biggest_bet_amt == 0`일 때만.

| OE-06 | **WinnerDetermined** | `{winners[], potDistribution[]}` | 우승자 확정 → 팟 분배 애니메이션 |
| OE-07 | **Rejected** | `{event, reason, details}` | 불법 이벤트 거부 → CC 경고 메시지 |
| OE-08 | **UndoApplied** | `{restoredState, undoDepthRemaining}` | UNDO 완료 → UI 전체 갱신 |
| OE-09 | **HandCompleted** | `{handNumber, winners[], stats}` | 핸드 종료 → 통계 업데이트, 기록 저장 |
| OE-10 | **EquityUpdated** | `{equities[]}` | 승률 재계산 완료 → 오버레이 승률 표시 |
| OE-11 | **HandTabled** (Rule 71) | `{seat_index, cards}` | 플레이어 카드 공개 → 오버레이에 표시, 엔진의 임의 muck 보호 활성 |
| OE-12 | **HandRetrieved** (Rule 110) | `{seat, manager_rationale}` | Folded hand 복구 완료 → CC에 복구 알림, 감사 로그 |
| OE-13 | **HandKilled** (Rule 71 예외) | `{seat, manager_rationale}` | Manager 판정에 의한 수동 kill → 감사 로그 |
| OE-14 | **MuckRetrieved** (Rule 109) | `{seat, cards, rationale}` | Muck 카드 재판정 복구 → showdown 재평가 트리거 |
| OE-15 | **FlopRecovered** (Rule 89) | `{original_cards, new_flop, reserved_burn}` | Four-card flop 복구 완료 → 오버레이 새 flop 표시 |
| OE-16 | **DeckIntegrityWarning** (Rule 78) | `{failure_count, suggested_action}` | RFID 3회 연속 실패 → CC에 덱 교체 제안 |
| OE-17 | **DeckChangeStarted** (Rule 78) | `{reason, requested_by}` | Deck change 절차 시작 → DeckFSM 전이 알림 |
| OE-18 | **GameTransitioned** (Mixed Omaha) | `{from_game, to_game, button_frozen}` | Mixed 게임 전환 → CC/Overlay에 전환 알림, button freeze 표시 |
| OE-19 | **PotUpdated** 확장 필드 | `{main, sides, total, display_to_players}` | **OE-03 PotUpdated에 `display_to_players: bool` 플래그 추가 (WSOP Rule 101)**. NL/FL/Spread 게임에서 플레이어 UI 숨김 여부 판단 |

> **OE-19 `display_to_players` 플래그 (WSOP Rule 101):**
> - `true` (기본): 팟 금액을 플레이어 UI에 표시
> - `false`: 특정 게임(Spread Limit 등)에서 팟 크기를 플레이어에게 숨김. Overlay(방송)에는 항상 표시.
> - 엔진은 GameState의 `pot_display_rule` 설정값에 따라 자동 결정

### Output Accumulation 순서

`reduce()` 는 Input Event 처리 중 발생하는 **모든 OutputEvent를 순서대로 accumulate**한다.

- 발행 순서 = Internal Transition 발동 순서 = OutputEvent 배열 인덱스 순서
- 예시: `PlayerAction(seat:3, action:fold)` → `[ActionProcessed, StateChanged, ActionOnChanged]` (이 순서)
- 동일 타입 OutputEvent가 1회 reduce에서 복수 발행될 수 있음 (예: `PotUpdated` 연속)
- Consumer(UI)는 배열 순서대로 처리하면 최종 상태에 도달함

---

## ReduceResult 구조

> 아래는 개발자 참고용 코드입니다.

```
ReduceResult {
  state: HandState         // 최종 상태
  outputs: List<OutputEvent>  // UI에 전달할 이벤트 목록
}
```

하나의 `reduce()` 호출이 여러 Internal Transition을 연쇄 수행하면, 각 전이마다 해당하는 OutputEvent가 `outputs`에 순서대로 추가된다.

예: `reduce(state, PlayerAction(seat:3, action:fold))` → AllFoldDetected 연쇄 시:
1. `OE-02 ActionProcessed(seat:3, fold)`
2. `OE-03 PotUpdated(...)`
3. `OE-05 ActionOnChanged(seat:-1)`
4. `OE-01 StateChanged(RIVER → HAND_COMPLETE)`
5. `OE-06 WinnerDetermined(...)`
6. `OE-09 HandCompleted(...)`

---

## ActionType Enum

| 값 | 이름 | BS-06-02 정의 | amount 필수 |
|:--:|------|-------------|:-----------:|
| 0 | fold | 포기 | ❌ |
| 1 | check | 체크 | ❌ |
| 2 | bet | 첫 베팅 | ✓ |
| 3 | call | 콜 | ❌ (자동 계산) |
| 4 | raise | 레이즈 | ✓ |
| 5 | allIn | 올인 | ❌ (자동: player.stack) |

> 참고: call의 금액은 `biggest_bet_amt - player.current_bet`로 자동 계산. allIn의 금액은 `player.stack`으로 자동 계산. 외부에서 amount를 넘기더라도 무시.

---

## Cascading 규칙

하나의 Input Event가 여러 Internal Transition을 연쇄 발동할 수 있다. reducer는 연쇄가 종료될 때까지 한 번의 `reduce()` 호출 내에서 처리한다.

### 연쇄 패턴

| Input Event | 가능한 연쇄 | 최대 깊이 |
|------------|-----------|:--------:|
| StartHand | → IT-01(BlindsAutoPost) → IT-08?(BombPotSkip) | 2 |
| PlayerAction(Fold) | → IT-04?(AllFoldDetected) → OE-09(HandCompleted) | 2 |
| PlayerAction(Call/Check) | → IT-03?(BettingRoundComplete) | 1 |
| PlayerAction(AllIn) | → IT-05?(AllInDetected) | 1 |
| BoardCardRevealed | → IT-06?(ShowdownEvaluation, RIVER 후) | 1 |
| HoleCardDetected | → IT-02?(DealComplete, 모든 홀카드 완성 시) | 1 |
| RunItChoice | → IT-07?(RunItComplete) | 1 |

> 참고: `?`는 조건부 발동. 연쇄 깊이가 3 이상인 경우는 없다.
