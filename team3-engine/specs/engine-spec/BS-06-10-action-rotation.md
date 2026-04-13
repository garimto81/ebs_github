# BS-06-10: 액션 순환 알고리즘

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | next_active_player, first_to_act, 라운드 완료 판정 pseudocode 정의 |
| 2026-04-09 | 조건 1 보강 → active players 정의 명확화 | GAP-GE-001: "active = SeatStatus.active만 (allIn 제외)" 명시, 1 active + N allIn 분기 추가 |
| 2026-04-13 | GAP-D 보강 | Edge Case TC 3건 추가 (Dead Button, 4인 All-in, Straddle+BB Option) |

---

> **이 문서에서 사용하는 용어**
>
> | 용어 | 설명 |
> |------|------|
> | Straddle | UTG 플레이어가 자발적으로 BB의 2배를 미리 내는 추가 블라인드 |
> | Dead Button | 이전 핸드의 딜러가 자리를 떠나 딜러 좌석이 비어있는 상황 |
> | NL/PL/FL | No Limit / Pot Limit / Fixed Limit 베팅 구조 |
> | Pseudocode | 실제 프로그래밍 언어가 아닌 참고용 가상 코드 |

## 개요

베팅 라운드에서 "다음 플레이어는 누구인가"와 "라운드는 언제 끝나는가"를 결정하는 알고리즘을 정의한다. BS-06-02에서 `next_active_player(action_on)`이 6회 이상 호출되지만 구현이 없었다. 이 문서는 해당 함수의 **step-by-step pseudocode**를 제공한다.

**핵심 함수 3개**:
1. `determine_first_to_act(phase, config)` — 스트리트 시작 시 첫 액션 플레이어 결정
2. `next_active_player(current, players)` — 다음 액션 플레이어 결정
3. `is_betting_round_complete(state)` — 현재 라운드 종료 여부 판정

---

## 정의

**포지션**: 좌석 배치에서 딜러 기준 시계방향 순서. 딜러 왼쪽부터 SB, BB, UTG, ...

| 포지션 약어 | 의미 | 딜러 기준 위치 |
|-----------|------|-------------|
| **BTN** | Button (Dealer) | 딜러 자신 |
| **SB** | Small Blind | 딜러 +1 |
| **BB** | Big Blind | 딜러 +2 |
| **UTG** | Under the Gun | 딜러 +3 |
| **HJ** | Hijack | BTN -2 |
| **CO** | Cutoff | BTN -1 |

> 참고: 좌석 수에 따라 중간 포지션은 가변. 핵심은 SB/BB/UTG/BTN의 상대적 위치.

**액션 가능 상태**: `player.status == active` (not folded, not allIn, not sittingOut, not busted)

---

## 알고리즘 1: determine_first_to_act

스트리트 시작 시 `action_on`을 결정한다.

### Pseudocode

```
function determine_first_to_act(phase, dealer_seat, players, blind_config):

  num_active = count(p for p in players if p.status == active)

  // 1. PRE_FLOP: 특수 규칙
  if phase == PRE_FLOP:

    // 1a. Heads-up (2인): Dealer(=SB)가 먼저
    if num_active == 2:
      return dealer_seat  // Dealer = BTN = SB

    // 1b. Straddle 적용: Straddle 다음 좌석
    if blind_config.straddle_enabled:
      straddle_seat = blind_config.straddle_seat
      return next_active_after(straddle_seat, players)

    // 1c. 일반 (3인+): UTG (BB 다음 좌석)
    bb_seat = blind_config.bb_seat
    return next_active_after(bb_seat, players)

  // 2. POST_FLOP (FLOP, TURN, RIVER): SB부터
  else:

    // 2a. Heads-up (2인): BB가 먼저
    if num_active == 2:
      return blind_config.bb_seat

    // 2b. 일반: SB (또는 SB가 폴드/올인이면 그 다음)
    sb_seat = blind_config.sb_seat
    return next_active_from(sb_seat, players)
      // sb_seat 자신이 active면 sb_seat 반환
      // sb_seat이 폴드/올인이면 시계방향 다음 active

  // 3. SHOWDOWN, RUN_IT_MULTIPLE, HAND_COMPLETE:
  //    action_on = -1 (액션 없음)
  return -1
```

### 포지션 예시 (6인 테이블)

```
좌석 배치 (시계방향):
  Seat 1 (BTN/Dealer)
  Seat 2 (SB)
  Seat 3 (BB)
  Seat 4 (UTG)    ← PRE_FLOP first_to_act (일반)
  Seat 5 (HJ)
  Seat 6 (CO)

PRE_FLOP 액션 순서: 4 → 5 → 6 → 1 → 2 → 3
POST_FLOP 액션 순서: 2 → 3 → 4 → 5 → 6 → 1
```

### Heads-up 예시 (2인)

```
  Seat 1 (BTN = SB = Dealer)
  Seat 3 (BB)

PRE_FLOP: Seat 1(SB) → Seat 3(BB)
POST_FLOP: Seat 3(BB) → Seat 1(SB)
```

### Straddle 예시 (UTG 플레이어가 자발적으로 BB의 2배를 미리 내는 추가 블라인드)

```
  Seat 1 (BTN), Seat 2 (SB), Seat 3 (BB)
  Seat 4 (UTG = Straddle, 2×BB 납부)
  Seat 5, Seat 6

PRE_FLOP 액션 순서: 5 → 6 → 1 → 2 → 3 → 4(Last, check option)
POST_FLOP: 일반 규칙 (SB부터)
```

---

## 알고리즘 2: next_active_player

현재 액션 플레이어의 다음 액션 플레이어를 결정한다.

### Pseudocode

```
function next_active_player(current_seat, players, num_seats):

  // 시계방향으로 순회
  for i in 1..num_seats:
    candidate = (current_seat + i) % num_seats
    // 좌석이 존재하고 액션 가능한 상태인지 확인
    if players[candidate] != null
       && players[candidate].status == active:
      return candidate

  // 한 바퀴 돌아도 active 플레이어 없음 (모두 폴드/올인)
  return -1  // action_on 해제
```

### 스킵 조건

| player.status | 스킵 여부 | 이유 |
|:---:|:---:|------|
| **active** | ❌ (액션 대상) | 액션 가능 |
| **folded** | ✓ (스킵) | 이미 포기 |
| **allIn** | ✓ (스킵) | 추가 액션 불가 |
| **sittingOut** | ✓ (스킵) | 자리 비움, 자동 폴드 처리 |
| **busted** | ✓ (스킵) | 토너먼트 탈락 |

---

## 알고리즘 3: is_betting_round_complete

현재 베팅 라운드가 종료되었는지 판정한다. `true`이면 다음 스트리트로 전이한다.

### Pseudocode

```
function is_betting_round_complete(state):

  // 조건 1: active 플레이어가 1명 이하 → 조건부 종료
  // "active" = SeatStatus.active만 (allIn 제외)
  active_players = [p for p in state.players if p.status == active]
  allin_players = [p for p in state.players if p.status == allIn]

  if len(active_players) == 0:
    return true  // 전원 allIn 또는 fold → 즉시 종료

  if len(active_players) == 1 and len(allin_players) == 0:
    return true  // 1명만 남음 (나머지 전원 fold) → 즉시 종료

  if len(active_players) == 1 and len(allin_players) >= 1:
    // 1명 active + N명 allIn: active 플레이어가 call/fold 기회를 가진 후 종료
    p = active_players[0]
    if p in state.acted_this_round and p.current_bet == state.biggest_bet_amt:
      return true  // 이미 액션 완료 + 금액 매칭
    return false   // 아직 액션 기회 필요

  // 조건 2: 모든 active 플레이어가 동일 금액을 베팅했는가?
  for p in active_players:
    if p.current_bet != state.biggest_bet_amt:
      return false  // 아직 콜하지 않은 플레이어 있음

  // 조건 3: 모든 active 플레이어가 최소 1회 액션했는가?
  // ⚠️ PRE_FLOP BB 체크 옵션 보호:
  //    BB는 블라인드 포스팅으로 current_bet == biggest_bet_amt를 이미 충족(조건 2 pass)하지만,
  //    acted_this_round에 포함되지 않으므로 all_players_acted = false.
  //    이 조건이 BB가 액션 기회를 갖기 전에 라운드가 종료되는 것을 막는다.
  // ⚠️ acted_this_round 초기화 규칙:
  //    각 스트리트(PRE_FLOP 포함) 시작 시 반드시 {} (빈 셋)으로 초기화한다.
  //    블라인드/앤티 포스팅은 "액션"이 아니므로 절대 acted_this_round에 포함하지 않는다.
  if not state.all_players_acted:
    return false

  return true
```

### 경계 케이스

| 상황 | 판정 | 이유 |
|------|:---:|------|
| PRE_FLOP, BB만 남음 (나머지 폴드) | `true` → HAND_COMPLETE | active == 1 |
| PRE_FLOP, 리프 없이 BB 체크 | `true` → FLOP 대기 | biggest_bet == BB, BB.current_bet == BB, 순환 완료 |
| 레이즈 발생 후 | `false` | 레이즈 이후 모든 active가 다시 액션해야 함 |
| 전원 올인 (active == 0) | `true` → SHOWDOWN | 베팅 불가, 보드 자동 공개 |
| 1 active + N allIn, active 미액션 | `false` | active 플레이어에게 call/fold 기회 부여 |
| 1 active + N allIn, active 액션 완료 | `true` | active가 액션 + 금액 매칭 완료 |
| BB check option 후 레이즈 | `false` | BB가 체크했어도 누군가 레이즈하면 BB 재액션 필요 |

### all_players_acted 판정 상세

```
function update_all_players_acted(state, acted_seat):

  // 액션한 좌석을 기록
  state.acted_this_round.add(acted_seat)

  // 레이즈 발생 시: acted 기록 리셋 (레이즈 플레이어만 남김)
  if action_was_raise:
    state.acted_this_round = {acted_seat}
    state.last_raiser = acted_seat

  // 모든 active 플레이어가 acted_this_round에 포함되면 완료
  state.all_players_acted =
    active_players.every(p => state.acted_this_round.contains(p.seat))
```

---

## 레이즈 후 액션 재개 규칙

BS-06-02 :316~318에서 정의된 `first_actor_after_raise`의 상세 알고리즘이다.

### Pseudocode

```
function handle_raise_action_restart(state, raiser_seat):

  // 레이즈 이후 모든 비폴드 비올인 플레이어에게
  // 다시 액션 기회를 부여한다.
  // action_on = 레이즈 플레이어의 다음 active 플레이어
  state.action_on = next_active_player(raiser_seat, state.players)

  // acted_this_round 리셋
  state.acted_this_round = {raiser_seat}

  // 라운드 완료 조건: 레이즈 플레이어에게 다시 턴이
  // 돌아오면 (모든 다른 active가 call/fold 완료) 라운드 종료
```

### 예시: 6인 PRE_FLOP에서 레이즈

```
초기: action_on = Seat 4 (UTG)
  Seat 4: Raise 100  → acted = {4}, action_on = 5
  Seat 5: Call        → acted = {4,5}, action_on = 6
  Seat 6: Fold        → acted = {4,5,6}, action_on = 1
  Seat 1: Call        → acted = {4,5,6,1}, action_on = 2
  Seat 2: Fold        → acted = {4,5,6,1,2}, action_on = 3
  Seat 3: Call        → acted = {4,5,6,1,2,3}
  → all active players acted → betting_round_complete = true
```

### BB Check Option 후 레이즈 복귀

```
PRE_FLOP, biggest_bet == BB:
  Seat 4 (UTG): Call    → action_on = 5
  Seat 5: Call           → action_on = 6
  Seat 6: Call           → action_on = 1 (BTN)
  Seat 1: Call           → action_on = 2 (SB)
  Seat 2 (SB): Call      → action_on = 3 (BB)
  Seat 3 (BB): Check     → all_players_acted = true
  → betting_round_complete = true

만약 Seat 3 (BB)가 Raise:
  Seat 3: Raise 200     → acted = {3}, action_on = 4
  모든 active 플레이어가 다시 액션해야 함
```

---

## Dead Button 처리

| 필드 | 조건 | 액션 순서 영향 |
|------|------|-------------|
| `button_dead` | true (이전 딜러 좌석이 빈 경우) | SB = 딜러+1, BB = 딜러+2. 딜러 좌석 자체는 액션에서 제외 |
| `missing_sb` | SB 좌석이 비어있거나 sitting_out | SB 포스팅 생략, BB만 포스팅. PRE_FLOP first_to_act 변경 없음 |
| `missing_bb` | BB 좌석이 비어있거나 sitting_out | BB 포스팅 생략. biggest_bet_amt = 0 → 전원 CHECK/BET 가능 |

### Dead Button 시 포지션 결정

```
function resolve_dead_button(dealer_seat, players):

  // 딜러 좌석이 비어있으면 button_dead = true
  // 하지만 딜러 좌석 자체는 이동하지 않음 (다음 핸드에서 이동)

  // SB = 딜러 다음 첫 번째 occupied seat (active 불문)
  sb_seat = next_occupied_after(dealer_seat, players)

  // BB = SB 다음 첫 번째 occupied seat
  bb_seat = next_occupied_after(sb_seat, players)

  // first_to_act = BB 다음 active seat (PRE_FLOP)
  return (sb_seat, bb_seat)
```

---

## 유저 스토리

| # | As a | When | Then |
|:-:|------|------|------|
| 1 | 운영자 | 6인 NL PRE_FLOP 시작 | action_on = Seat 4 (UTG, 딜러+3) |
| 2 | 운영자 | 2인 Heads-up PRE_FLOP | action_on = Dealer(SB), POST_FLOP에서는 BB |
| 3 | 운영자 | UTG Straddle 적용 시 PRE_FLOP | action_on = Straddle 다음 좌석 |
| 4 | 운영자 | Seat 4 Fold 후 (Seat 5, 6 active) | action_on = Seat 5 (시계방향 다음 active) |
| 5 | 운영자 | Seat 4 Raise 후 | 모든 active에게 재액션 기회, action_on = Seat 5 |
| 6 | 운영자 | PRE_FLOP 전원 콜, BB 체크 | betting_round_complete = true |
| 7 | 운영자 | Seat 2~6 폴드, Seat 1만 남음 | active == 1, → HAND_COMPLETE |
| 8 | 운영자 | Dead Button (딜러 좌석 빔) | SB/BB 정상 결정, 딜러 좌석 스킵 |
| 9 | 운영자 | BB Raise 후 전원 콜 | BB에게 돌아오면 라운드 완료 |
| 10 | 운영자 | 전원 올인 (active == 0) | action_on = -1, → SHOWDOWN |

---

## 경우의 수 매트릭스

### 매트릭스 1: first_to_act 결정

| phase | num_players | straddle | 결과 |
|:-----:|:-----------:|:--------:|------|
| PRE_FLOP | 2 (heads-up) | ❌ | Dealer(SB) |
| PRE_FLOP | 2 (heads-up) | ✓ | Straddle 다음 |
| PRE_FLOP | 3~10 | ❌ | BB 다음 (UTG) |
| PRE_FLOP | 3~10 | ✓ | Straddle 다음 |
| FLOP/TURN/RIVER | 2 (heads-up) | — | BB |
| FLOP/TURN/RIVER | 3~10 | — | SB (또는 SB 이후 첫 active) |
| SHOWDOWN | any | — | -1 (액션 없음) |

### 매트릭스 2: 라운드 완료 조건

| active 수 | biggest_bet | all_acted | 판정 |
|:---------:|:----------:|:---------:|------|
| 0 | any | — | ✓ complete (→ SHOWDOWN) |
| 1 | any | — | ✓ complete (→ HAND_COMPLETE) |
| 2+ | X | false | ❌ not complete |
| 2+ | X | true, 전원 current_bet == X | ✓ complete |
| 2+ | X | true, 일부 current_bet < X | ❌ not complete |

---

### Edge Case 테스트 케이스

#### TC-ROTATION-01: Dead Button 상황

| 항목 | 값 |
|------|-----|
| **사전 조건** | 4인 테이블, Seat 1 (Dealer) 탈락, Dead Button Rule 적용 |
| **입력** | HandStart(dealerSeat=1) — Seat 1은 빈 자리 |
| **기대 결과** | Button은 Seat 1에 유지 (Dead Button), SB = Seat 2, BB = Seat 3, UTG = Seat 0 |
| **판정 기준** | firstToAct(state) == 0 (UTG), state.dealerSeat == 1 |

#### TC-ROTATION-02: 4인 All-in 후 남은 1 Active

| 항목 | 값 |
|------|-----|
| **사전 조건** | 5인 테이블, Seat 0~3 All-in, Seat 4 Active |
| **입력** | PlayerAction(seat=4, action=Call) |
| **기대 결과** | is_betting_round_complete = true (1 active, allIn 존재, acted + bet 매칭) |
| **판정 기준** | BettingRules.isRoundComplete(state) == true |

#### TC-ROTATION-03: Straddle + BB Option 동시 적용

| 항목 | 값 |
|------|-----|
| **사전 조건** | 6인 테이블, Straddle 활성 (Seat 3), 전원 Call |
| **입력** | 전원 Call (Seat 4, 5, 0, 1, 2 순서로) → BB(Seat 2)에게 Option |
| **기대 결과** | BB는 Check/Raise 선택 가능, Straddle 이후에도 BB Option 보존 |
| **판정 기준** | actionOn == bb_seat, legalActions에 Check 포함 |
