# BS-06-09: 게임 엔진 이벤트 카탈로그

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | Input/Internal/Output 3계층 이벤트 정의, payload 스키마, 유효 상태 매트릭스 |
| 2026-04-09 | IE-02 보강 → Call/AllIn amount 처리 주의사항 | Contract Test FAIL 근거: 외부 amount 무시, 엔진 내부 재계산 강제 명시 |

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

> `✓` = 정상 처리, `REJECT` = 거부 (OutputEvent.Rejected 발생), `IGNORE` = 조용히 무시 (stray read 등), `✓→X` = 보드 카드 수에 따른 조건부 전이

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
| OE-06 | **WinnerDetermined** | `{winners[], potDistribution[]}` | 우승자 확정 → 팟 분배 애니메이션 |
| OE-07 | **Rejected** | `{event, reason, details}` | 불법 이벤트 거부 → CC 경고 메시지 |
| OE-08 | **UndoApplied** | `{restoredState, undoDepthRemaining}` | UNDO 완료 → UI 전체 갱신 |
| OE-09 | **HandCompleted** | `{handNumber, winners[], stats}` | 핸드 종료 → 통계 업데이트, 기록 저장 |
| OE-10 | **EquityUpdated** | `{equities[]}` | 승률 재계산 완료 → 오버레이 승률 표시 |

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
