# BS-06-01: Hold'em 핸드 라이프사이클

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-06 | 신규 작성 | 핸드 라이프사이클 FSM 정의 (3가지 game_class × 9-12 상태 × 20+ 유저 스토리) |
| 2026-04-06 | 구조 → Hold'em 전용 변환 | Draw/Stud 계열 제거, Flop CC FSM만 유지, Bomb Pot 상태 전이 변형 흡수 |
| 2026-04-07 | 내러티브 → 전체 → doc-critic 적용 | 다이어그램 앞으로 이동, 용어 설명 추가, 영향 요소 축소 |

---

## 개요

게임 엔진의 핸드 라이프사이클은 **IDLE에서 시작하여 HAND_COMPLETE로 끝나는 유한 상태 머신**이다. 이 문서는 Hold'em FSM의 각 상태의 진입/퇴출 조건, 상태변수 값, 트리거 소스를 명시하여 개발팀이 **상태 전이 로직을 정확히 구현**할 수 있도록 한다.

**핵심 원칙**:
- 한 핸드는 반드시 IDLE에서 시작하고 HAND_COMPLETE에서 끝남
- 각 상태는 `hand_in_progress`, `action_on`, 보드 카드 수, 최종 베팅 라운드 플래그로 고유하게 정의됨
- 상태 전이는 반드시 "현재 상태 + 트리거" 조합으로만 발생, 임의 전이 금지

유한 상태 머신이란 정해진 상태들 사이를 규칙에 따라 이동하는 구조다. 신호등이 빨강→노랑→초록으로 바뀌는 것처럼, Hold'em 핸드는 **IDLE** → **PRE_FLOP** → **FLOP** → **TURN** → **RIVER** → **SHOWDOWN** 순서로 진행된다.

### 상태 흐름 전체 다이어그램

```
                    ┌─ IDLE ─┐
                    │         │
              (app start or  (StartHand)
               prev complete) │
                    │         ├─→ SETUP_HAND
                    │         │    (blinds posted,
                    │         │     hole cards dealt)
                    │         │    │
                    │         └────┴─→ PRE_FLOP
                    │                (action_on = first_to_act)
                    │                │
                    │        (betting complete
                    │         or all fold)
                    │                │
                    ├─────────────────┤
                    │                 ├─→ FLOP (board=3)
                    │                 │   │
                    │        (betting complete
                    │         or all fold)
                    │                 │
                    ├─────────────────┤
                    │                 ├─→ TURN (board=4)
                    │                 │   │
                    │        (betting complete
                    │         or all fold)
                    │                 │
                    ├─────────────────┤
                    │                 ├─→ RIVER (board=5)
                    │                 │   │ (final_betting_round=true)
                    │                 │   │
                    │        (betting complete
                    │         or all fold)
                    │                 │
                    ├─────────────────┼─→ SHOWDOWN
                    │                 │   (hand eval)
                    │                 │   │
                    │                 │   ├─(run_it_times>0)
                    │                 │   │  └─→ RUN_IT_MULTIPLE
                    │                 │   │      (run[n])
                    │                 │   │      │
                    │                 │   └─────┘
                    │                 │   │
                    │                 │ (winner)
                    │                 │   │
                    └──────────────────────→ HAND_COMPLETE
                                      (payout, stats update)
                                      │
                          (ManualNextHand or
                           overrideButton)
                                      │
                                      └─→ IDLE
```

---

## 정의

**핸드 라이프사이클**은 하나의 포커 핸드가 딜 시작(SETUP_HAND)부터 우승자 결정(HAND_COMPLETE)까지 거치는 일련의 상태 변화를 추적하는 **프로세스이자 상태 머신**이다.

- **IDLE**: 핸드 진행 중 아님 (hand_in_progress=false)
- **SETUP_HAND, PRE_FLOP, ..., HAND_COMPLETE**: 핸드 진행 중 (hand_in_progress=true)

---

## 트리거

### 트리거 소스

3가지 입력 장치가 게임 상태를 변경한다:
- **CC 버튼** — Command Center, 운영자가 게임을 조작하는 화면의 액션 버튼
- **RFID** — 카드에 내장된 무선 칩을 자동으로 읽는 장치
- **게임 엔진** — 조건 충족 시 자동으로 다음 상태로 전이하는 시스템

| 소스 | 발동 주체 | 처리 시간 | 신뢰도 |
|------|---------|---------|--------|
| **CC 버튼** | 운영자 (수동) | 즉시 (<50ms) | 낮음 |
| **RFID 감지** | 시스템 (자동) | 변동 (50~150ms) | 높음 |
| **게임 엔진 자동** | 게임 엔진 (자동) | 결정론적 | 최고 |

> 참고: CC 버튼 예시 — NEW HAND, DEAL, CHECK, BET, FOLD, CALL, RAISE, ALL-IN. RFID 예시 — 홀카드 감지, 보드 카드 감지, 카드 갱신. 게임 엔진 예시 — 베팅 완료→다음 라운드 공개, 올인→런아웃, 쇼다운 진행.

### 상태별 진입 트리거 요약

| 상태 | 진입 트리거 | 발동 조건 |
|------|-----------|---------|
| IDLE | 앱 시작 OR 이전 핸드 HAND_COMPLETE | 초기 상태 또는 cycle |
| SETUP_HAND | SendStartHand() | 모든 precondition 충족 |
| PRE_FLOP | 홀카드 완전 딜 완료 | 게임 엔진 자동 |
| FLOP | 베팅 완료 + Flop 버튼 또는 자동 진행 | 최종 베팅액 동일 |
| TURN | 보드 4번째 카드 감지 | 게임 엔진 감지 |
| RIVER | 보드 5번째 카드 감지 | 게임 엔진 감지 |
| SHOWDOWN | 최종 베팅 라운드 완료 + 2+ 플레이어 | 게임 엔진 자동 진행 |
| RUN_IT_MULTIPLE | run_it_times > 0 (SHOWDOWN 진행 중) | 플레이어 동의 후 게임 엔진 자동 |
| HAND_COMPLETE | 우승자 결정 또는 모든 플레이어 폴드 | 팟 분배 완료 |

---

## 전제조건

### 핸드 시작 전제조건 (StartHand 호출 가능)

| 필드 | 조건 | 설명 |
|------|------|------|
| **pl_dealer** | != -1 | 딜러 위치 할당됨 |
| **num_blinds** | 0~3 | 블라인드 타입 정의됨 |
| **num_seats** | 2+ | 최소 2명 이상 플레이어 |
| **current state** | IDLE | 현재 상태가 IDLE |

### 핸드 진행 중 불변 조건

- `hand_in_progress == true`: 항상 true (SETUP_HAND부터 HAND_COMPLETE 직전까지)
- `action_on` != -1: 현재 액션 플레이어가 할당됨 (SHOWDOWN, RUN_IT_MULTIPLE 제외)
- `dealer_seat`: 핸드 내 불변 (버튼 이동은 다음 핸드)
- `board_cards` 수: 감소하지 않음

---

## 유저 스토리

> 참고: 런아웃 — 모든 플레이어 올인 후 남은 보드 카드를 자동 공개하는 절차. Run It Multiple — 올인 상황에서 보드를 여러 번 전개하여 팟을 분할하는 방식. Dead money — 폴드한 플레이어가 팟에 남긴 금액.

| # | As a | When | Then |
|:-:|------|------|------|
| 1 | 운영자 | 앱 시작 | 상태 = IDLE, hand_in_progress=false |
| 2 | 운영자 | NEW HAND 버튼 클릭 + precondition 충족 | 상태 = SETUP_HAND, blinds 자동 수납, 카드 딜 시작 |
| 3 | 시스템 | 모든 플레이어 홀카드 딜 완료 | 상태 = PRE_FLOP |
| 4 | 운영자 | PRE_FLOP에서 CHECK/BET/CALL/RAISE/FOLD 액션 | action_on 다음 플레이어로 순환, biggest_bet_amt 갱신 |
| 5 | 운영자 | PRE_FLOP 베팅 완료 (모든 액션 동일) | 상태 = FLOP, 보드 3장 공개 대기 |
| 6 | 시스템 | RFID가 보드 카드 3장 감지 또는 운영자가 board_cards 수동 입력 | board_cards 배열 갱신, 오버레이 보드 업데이트 |
| 7 | 운영자 | PRE_FLOP에서 전원 폴드 (1명 제외) | 상태 = HAND_COMPLETE, 우승자 결정 |
| 8 | 운영자 | FLOP에서 all-in 발생, 보드 완성 불가능 | 상태 = SHOWDOWN, 남은 보드 자동 런아웃 |
| 9 | 운영자 | RIVER 베팅 완료, 2+ 플레이어 남음 | 상태 = SHOWDOWN, 핸드 평가 시작 |
| 10 | 운영자 | SHOWDOWN에서 우승자 1명 확정 | 상태 = HAND_COMPLETE, 팟 분배, 통계 업데이트 |
| 11 | 운영자 | SHOWDOWN에서 run_it_times=2 적용, 첫 런 완료 | 상태 = RUN_IT_MULTIPLE, run_it_times_remaining=1, 두 번째 보드 공개 |
| 12 | 시스템 | RUN_IT_MULTIPLE에서 남은 런 = 0 | 상태 = HAND_COMPLETE, 전체 런 결과 합산, 팟 분배 |
| 13 | 운영자 | NEW HAND 버튼 + Bomb Pot 설정 | PRE_FLOP 스킵, FLOP 직행 (Bomb Pot 상태 전이 변형, 아래 참조) |
| 14 | 운영자 | HAND_COMPLETE + manual "Next Hand" 또는 overrideButton=true | 상태 = IDLE, board_cards 리셋, action_on=-1 |
| 15 | 운영자 | 핸드 진행 중 UNDO 버튼 (최대 5단계) | 이전 상태 복원, action_on 복원 |
| 16 | 시스템 | 미스딜 감지 (카드 불일치 또는 운영자 지시) | 상태 = IDLE, pot 복귀, stacks 복구 |

---

## 경우의 수 매트릭스

### 매트릭스 1: Hold'em 상태 상세

| 상태 | hand_in_progress | action_on | board_cards 수 | final_betting_round |
|------|:--------:|:-----:|:--------:|:--------:|
| **IDLE** | false | -1 | 0 | false |
| **SETUP_HAND** | true | -1 | 0 | false |
| **PRE_FLOP** | true | first_to_act | 0 | false |
| **FLOP** | true | first_to_act | 3 | false |
| **TURN** | true | first_to_act | 4 | false |
| **RIVER** | true | first_to_act | 5 | **true** |
| **SHOWDOWN** | true | -1 | 5 | true |
| **RUN_IT_MULTIPLE** | true | -1 | varies | true |
| **HAND_COMPLETE** | false | -1 | varies | true |

### 매트릭스 2: 상태별 Entry/Exit 조건

| 상태 | Entry 조건 | Exit 조건 | 다음 상태(들) |
|------|-----------|-----------|-------------|
| **IDLE** | 앱 시작 또는 HAND_COMPLETE | StartHand() called | SETUP_HAND |
| **SETUP_HAND** | SendStartHand() 응답 | blinds posted + hole cards dealt | PRE_FLOP |
| **PRE_FLOP** | hole cards dealt | 베팅 완료 또는 all fold | FLOP 또는 HAND_COMPLETE 또는 SHOWDOWN |
| **FLOP** | 베팅 완료 후 3번째 board card detected | 베팅 완료 또는 all fold | TURN 또는 HAND_COMPLETE 또는 SHOWDOWN |
| **TURN** | 4번째 board card detected | 베팅 완료 또는 all fold | RIVER 또는 HAND_COMPLETE 또는 SHOWDOWN |
| **RIVER** | 5번째 board card detected | 베팅 완료 또는 all fold | SHOWDOWN 또는 HAND_COMPLETE |
| **SHOWDOWN** | 최종 베팅 완료 + 2+ players | 우승자 결정 또는 run_it 선택 | HAND_COMPLETE 또는 RUN_IT_MULTIPLE |
| **RUN_IT_MULTIPLE** | run_it_times > 0 (SHOWDOWN 중) | 남은 런 = 0 | HAND_COMPLETE |
| **HAND_COMPLETE** | 우승자 결정 또는 모두 폴드 | ManualNextHand() 또는 overrideButton=true | IDLE |

### 매트릭스 3: 보드 카드 수 기반 상태 전이

| 현재 상태 | board_cards 감지 | 가능한 전이 | 조건 |
|---------|:--------:|-----------|------|
| PRE_FLOP (0장) | 0장 감지 | 변화 없음 | 정상 (카드 미감지) |
| PRE_FLOP (0장) | 1~2장 감지 | error log | 부분 감지 또는 카드 오인식 |
| PRE_FLOP (0장) | 3장 감지 | → FLOP | 정상 Flop 카드 감지 |
| FLOP (3장) | +1장 감지 | → TURN | 정상 Turn 카드 감지 |
| TURN (4장) | +1장 감지 | → RIVER | 정상 River 카드 감지 |
| RIVER (5장) | no change | 변화 없음 | 정상 (카드 완성) |

### 매트릭스 4: 특수 상황별 상태 전이 오버라이드

| 특수 상황 | 조건 | 정상 경로 | 오버라이드 경로 |
|---------|------|---------|-------------|
| **All Fold** | 1명 남음 | 다음 라운드 → SHOWDOWN | → HAND_COMPLETE (즉시) |
| **All-in + board 불완성** | all-in at FLOP, board<5 | → TURN/RIVER | → SHOWDOWN (runout 자동) |
| **Bomb Pot** | bomb_pot > 0, state=SETUP | SETUP→PRE_FLOP | SETUP→FLOP 직행 (PRE_FLOP 스킵) |
| **Run It Twice** | run_it_times=2, SHOWDOWN | → HAND_COMPLETE | → RUN_IT_MULTIPLE → HAND_COMPLETE |
| **Miss Deal** | 카드 불일치 감지 | (current) | → IDLE (blinds/stacks 복구) |
| **UNDO (5단계)** | undo_depth <= 5 | (current) | 이전 상태 복원 |
| **Player Sit Out** | player.status='sitting_out' | (normal action) | 자동 폴드, action_on 다음 |

---

## Bomb Pot 상태 전이 변형

Bomb Pot이란 모든 플레이어가 동일 금액을 먼저 내고, **PRE_FLOP** 베팅 없이 바로 **FLOP**부터 시작하는 특수 방식이다. **PRE_FLOP** 베팅 라운드를 **완전히 스킵**하는 특수 상태 전이이다.

### 활성화 조건

| 필드 | 조건 | 설명 |
|------|------|------|
| **bomb_pot_enabled** | true | Bomb Pot 활성화됨 |
| **bomb_pot_amount** | > 0 | 전원 납부 금액 설정됨 |
| **num_active_players** | 2+ | 최소 2명 이상 |

### 상태 전이

```
[IDLE]
  ↓ NEW HAND (Bomb Pot 모드)
[SETUP_HAND]
  ├─ 모든 플레이어 bomb_pot_amount 자동 수납
  ├─ PRE_FLOP 스킵
  ↓
[FLOP] ← PRE_FLOP 없이 직행
  ├─ 보드 3장 공개 대기 (RFID 또는 수동)
  ↓ (이후 표준 흐름)
[TURN] → [RIVER] → [SHOWDOWN] → [HAND_COMPLETE]
```

### Short Contribution 처리

| 조건 | 처리 |
|------|------|
| 모든 플레이어 stack ≥ bomb_pot_amount | 전원 동일 금액 수납 |
| 일부 플레이어 stack < bomb_pot_amount | 해당 플레이어는 최대 스택만 수납, Dead money로 팟에 분배 |
| 1명만 남음 | Bomb Pot 불필요, 즉시 HAND_COMPLETE |

---

## 비활성 조건

다음 조건이 참이면 이 핸드 라이프사이클 FSM은 **비활성 상태**이며, 상태 전이가 발생하지 않는다:

- `hand_in_progress == false` **AND** `state == IDLE`
- 앱 대기 중 (테이블 선택 이전)
- 이전 핸드 완료 후 운영자가 "Next Hand" 명령 미발생

---

## 영향 받는 요소

| 요소 | 상태 전이 시 영향 |
|------|-----------------|
| CC 버튼 | 상태별 활성/비활성 버튼 변경 |
| RFID 감지 | 카드 감지 대상 변경 |
| 오버레이 | 화면 표시 요소 변경 |
| 통계 | 핸드 종료 시 플레이어 통계 업데이트 |
| 팟 관리 | 베팅 라운드별 팟 금액 누적 |
| 게임 저장 | 상태 전이마다 핸드 기록 저장 |

---

## 구현 가이드

아래는 위 상태 전이를 프로그래밍 언어로 표현한 참고 코드다.

```
// Pseudocode: Hold'em state transitions
// 이벤트 payload 상세: BS-06-09 이벤트 카탈로그 참조

switch (current_state) {
  case IDLE:
    if (event == StartHand) → next_state = SETUP_HAND
  case SETUP_HAND:
    if (event == dealt_all_hole_cards) → next_state = PRE_FLOP
    if (bomb_pot_enabled) → next_state = FLOP  // PRE_FLOP 스킵
  case PRE_FLOP:
    if (event == betting_complete) → next_state = FLOP
    else if (event == all_fold) → next_state = HAND_COMPLETE
    else if (event == all_in && num_active == 0) → next_state = SHOWDOWN
  case FLOP:
    if (event == betting_complete) → next_state = TURN  // board 4장 대기
    else if (event == all_fold) → next_state = HAND_COMPLETE
    else if (event == all_in && num_active == 0) → next_state = SHOWDOWN
  case TURN:
    if (event == betting_complete) → next_state = RIVER  // board 5장 대기
    else if (event == all_fold) → next_state = HAND_COMPLETE
    else if (event == all_in && num_active == 0) → next_state = SHOWDOWN
  case RIVER:
    if (event == betting_complete) → next_state = SHOWDOWN
    else if (event == all_fold) → next_state = HAND_COMPLETE
  case SHOWDOWN:
    if (run_it_times > 0) → next_state = RUN_IT_MULTIPLE
    else → next_state = HAND_COMPLETE
  case RUN_IT_MULTIPLE:
    if (run_it_times_remaining == 0) → next_state = HAND_COMPLETE
  case HAND_COMPLETE:
    if (event == ManualNextHand) → next_state = IDLE
}
```

---

## 예외 처리

> 참고: `card_verify_mode` — 카드 검증 모드. `undo_stack` — UNDO 이력 스택. `card_rescan` — 카드 재스캔 필요 플래그.

### Miss Deal

- **감지**: SETUP_HAND 중 홀카드 수 != 2 (Hold'em 기준)
- **처리**:
  1. game_state → IDLE
  2. pot 내 모든 칩 원래 스택으로 복귀
  3. board_cards 리셋
  4. blinds 재포스트 요청 (운영자)

### Card Rescan

- **트리거**: RFID 미감지 또는 card_verify_mode=true
- **처리**: game_state 유지, card_rescan=true 설정, RFID 재감지 대기

### UNDO (최대 5단계)

- **트리거**: 운영자 UNDO 버튼
- **처리**: undo_stack에서 이전 (state, action_on, board_cards) 복원
