---
title: Blinds and Ante
owner: team3
tier: internal
legacy-id: BS-06-03
last-updated: 2026-04-15
---

# BS-06-03: Hold'em 블라인드 및 앤티

> **존재 이유**: 블라인드/앤티 7종 구현 타겟 — CCR 초안·구현 코드 공동 참조.

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-06 | 신규 작성 | Ante 7종 + Blind 4가지 조합, Heads-up 규칙, Dead Button, Bomb Pot 포함 |
| 2026-04-06 | 구조 → Hold'em 전용 변환 | Stud Bring-in 제거, Draw 전용 블라인드 규칙 제거, Straddle 추가 블라인드 섹션 흡수 |
| 2026-04-09 | doc-critic 개선: 용어 해설 추가 | 문서 서두 용어 해설 테이블, 포스팅 순서 알고리즘 -= 연산자 안내 추가 |
| 2026-04-10 | WSOP 규정 반영 | §Heads-up 특수 규칙에 "전환 시 Button 조정 (Rule 87)" 및 "딜링 순서" 하위 섹션 추가, §Missed Blind 복귀 규정 (Rule 86) 신설. CCR-DRAFT-team3-20260410-wsop-conformance 참조 |
| 2026-04-13 | GAP-C 보강 | 포스팅 순서 통합 알고리즘 Pseudocode 추가, ManagerRuling 패널티 처리 상세화 |

---

> **이 문서에서 사용하는 용어**
>
> | 용어 | 설명 |
> |------|------|
> | CC | Command Center, 운영자가 게임을 제어하는 화면 |
> | FSM | 게임 진행 단계를 정의한 상태 흐름도 (Finite State Machine) |
> | Pseudocode | 실제 프로그래밍 언어가 아닌 가상 코드. 로직을 이해하기 위한 참고용 |

## 개요

게임 시작 시(SETUP_HAND 상태) **강제 베팅**을 자동으로 수거하는 시스템을 정의한다. 7가지 Ante 유형 × 4가지 블라인드 조합(0~3개) = 28가지 경우의 수를 다룬다. 포스팅 순서, 금액 계산, Dead Money 처리, Straddle 추가 블라인드를 포함한다. 이 단계 완료 시 `hand_in_progress = true`로 전환되고, 팟 초기값과 `action_on`이 확정된다.

**핵심 목표**: 모든 Ante/Blind 조합에서 팟이 정확히 형성되고, 액션 순서가 일관되며, 플레이어별 칩 차감이 올바르게 기록된다.

---

## 정의

**강제 베팅**: 운영자가 CC 버튼을 누르지 않아도 게임 규칙에 의해 **자동으로 수거**되는 의무 납부금. 포커 팟을 생성하여 게임을 활성화한다.

- **Ante**: 핸드 시작 전 전원(또는 특정 플레이어)이 납부하는 추가 의무금
- **Blind**: 딜러 위치 기준 2~3명이 **순차적으로** 납부하는 강제 베팅
- **Straddle**: UTG 또는 Button 위치 플레이어가 자발적으로 납부하는 **추가 블라인드** (2× BB)

**속성**:
- **Dead Money vs Live Money**: Ante/Blind는 일반적으로 Dead이지만, Live Ante는 예외
- **자동 처리**: 운영자 입력 불필요, 게임 엔진이 자동 처리
- **팟 초기값**: 모든 강제 베팅 합계 = `pot_initial`

---

## 트리거

| 트리거 유형 | 조건 | 발동 주체 | 처리 시간 |
|-----------|------|---------|---------|
| **NEW HAND 버튼** | 운영자가 CC "NEW HAND" 클릭 + 모든 precondition 충족 | 운영자 (수동) | 즉시 (<50ms) |
| **게임 엔진 자동** | SendStartHand() 응답 수신 후 SETUP_HAND 진입 | 게임 엔진 (자동) | 계산 기반 |
| **상태 추적** | hand_in_progress = true, 강제 베팅 수거 완료 시점 | 게임 엔진 (자동) | 상태 전이와 동시 |

---

## 전제조건

다음 모든 조건이 참이어야 NEW HAND 진행 가능:

1. **hand_in_progress == false** — 이전 핸드 완료 또는 초기 상태
2. **pl_dealer != -1** — 딜러 위치 할당됨 (0~num_seats-1)
3. **num_blinds ∈ {0, 1, 2, 3}** — 블라인드 타입 정의됨
4. **ante_type ∈ {0, 1, 2, 3, 4, 5, 6}** — Ante 유형 정의됨
5. **num_seats ≥ 2** — 최소 2명 플레이어
6. **게임 상태 ∈ {IDLE, HAND_COMPLETE}** — 진행 중인 핸드 없음

### 플레이어 칩 전제조건

| 조건 | 설명 | 예외 |
|------|------|------|
| **player.stack >= 강제베팅액** | 모든 플레이어가 Ante/Blind 납부 가능 | 칩 부족 시 자동 All-in, 나머지는 Side Pot |
| **player.status == active** | 플레이어 상태가 활성 | Sitout 플레이어는 강제 베팅 면제 |
| **num_active_players ≥ 2** | 활성 플레이어 2명 이상 | 1명 이하면 게임 진행 불가 |

---

## Ante 7종 정의

### Type 0: Standard Ante (std_ante)

**납부자**: 모든 활성 플레이어
**금액**: `ante_amount` (동일)
**처리**: Dead Money

```
예: 6인 테이블, BB=1000, ante=100
→ 팟 += 600 (100×6)
→ 모든 플레이어 stack -= 100
→ current_bet 불변 (베팅으로 인정 안 됨)
```

**특징**: 가장 단순하고 전통적인 형태.

---

### Type 1: Button Ante (button_ante)

**납부자**: 딜러 버튼 위치 플레이어 **1명만**
**금액**: 전원분을 대신 납부 (`ante_amount × num_seats`)
**처리**: Dead Money

```
예: 6인 테이블, BB=1000, button_ante=100, 딜러 위치=BTN
→ BTN 플레이어 stack -= 600 (100×6)
→ 팟 += 600
→ 나머지 5명: 변화 없음
```

**특징**: Short Deck(6+) 게임에서 주로 사용.

---

### Type 2: BB Ante (bb_ante)

**납부자**: Big Blind 위치 플레이어 **1명이 전원분 대납**
**금액**: `ante_amount × num_seats`
**처리**: Dead Money
**액션 순서**: 일반 규칙 (UTG first to act)

```
예: 6인 테이블, BB=1000, ante=100
→ BB 플레이어 stack -= 600
→ 팟 += 1500 (BB 1000 + Ante 600)
→ action_on = first_to_act (UTG)
```

**특징**: 2018년 이후 대부분 토너먼트의 표준.

---

### Type 3: BB Ante (BB 1st) (bb_ante_bb1st)

**납부자**: Big Blind 위치 플레이어 **1명이 전원분 대납**
**금액**: `ante_amount × num_seats`
**처리**: Dead Money
**액션 순서**: **BB가 PRE_FLOP에서 먼저 행동** (Option 취득)

```
예: 6인 테이블, BB=1000, ante=100
→ BB 플레이어 stack -= 600
→ 팟 += 600
→ 블라인드 포스팅: SB 500, BB 1000
→ action_on = BB (UTG가 아닌 BB!)
→ BB는 Check/Raise 선택 (Option 취득)
```

**특징**: 일부 토너먼트에서 사용. BB에게 추가 이점 부여.

---

### Type 4: Live Ante (live_ante)

**납부자**: 모든 활성 플레이어
**금액**: `ante_amount` (동일)
**처리**: **Live Money** (첫 라운드 베팅에 포함됨)
**콜 시 처리**: Ante는 이미 "베팅"으로 인정되므로 콜액 감소

```
예: 6인 테이블, BB=1000, live_ante=100
→ 팟 += 600 (ante)
→ 모든 플레이어 current_bet = 100 (Ante가 베팅)
→ SB=500, BB=1000 포스팅 후:
  - SB의 current_bet = 500
  - BB의 current_bet = 1000
→ UTG 플레이어 차례, biggest_bet = 1000
→ UTG가 콜하려면: 1000 - 100(이미 베팅됨) = 900만 추가 납부
```

**특징**: 캐시 게임에서 사용.

---

### Type 5: TB Ante (tb_ante)

> TB = **Two Blinds** — SB와 BB 2명이 전원분 Ante를 나누어 부담하는 방식.

**납부자**: Small Blind + Big Blind **2명이 나눔**
**금액**: `ante_amount × num_seats`를 SB와 BB가 합산 처리
**처리**: Dead Money
**액션 순서**: 일반 규칙 (UTG first to act)

```
예: 6인 테이블, bb_ante_amount=600 (전체 ante)
→ TB(SB+BB)가 합산하여 처리
→ 팟 += 600(Ante 합산) + 1500(Blind) = 2100
→ action_on = first_to_act (UTG)
```

**특징**: 극히 드문 형식.

---

### Type 6: TB Ante (TB 1st) (tb_ante_tb1st)

> Type 5와 동일하되, **SB/BB가 PRE_FLOP에서 먼저 행동**하는 변형.

**납부자**: Small Blind + Big Blind **2명이 나눔**
**금액**: `ante_amount × num_seats`
**처리**: Dead Money
**액션 순서**: **SB/BB가 먼저 행동**

```
예: 6인 테이블
→ 포스팅: SB=500, BB=1000 (Ante 합산)
→ action_on = SB (먼저 행동)
→ SB는 Check/Raise 선택 후 BB로 진행
```

**특징**: 역시 드문 형식.

---

## 블라인드 구조 (num_blinds)

### num_blinds = 0: No Blind (Ante Only)

**해당 상황**: Ante만 사용하는 특수 구조

**포스팅 순서**:
1. Ante 수거 후
2. action_on = 딜러 좌측 첫 플레이어

**팟**: Ante만 존재, Blind 없음

---

### num_blinds = 1: Big Blind Only

**해당 상황**: 드물게 사용

**포스팅 순서**:
1. BB 위치 플레이어가 `big_blind` 납부
2. Ante 수거 (설정된 ante_type에 따라)
3. action_on = first_to_act (UTG)

**금액**:
```
팟 = big_blind + ante_total
```

---

### num_blinds = 2: Small Blind + Big Blind (표준)

**해당 상황**: 대부분의 Hold'em 게임

**포스팅 순서**:
1. SB 위치 플레이어가 `small_blind` 납부
   - `player[SB].stack -= small_blind`
   - `player[SB].current_bet = small_blind`
2. BB 위치 플레이어가 `big_blind` 납부
   - `player[BB].stack -= big_blind`
   - `player[BB].current_bet = big_blind`
3. Ante 수거 (ante_type 규칙 적용)
4. `biggest_bet_amt = big_blind` (액션 기준)
5. `action_on = first_to_act` (일반적으로 UTG)

**금액**:
```
팟 = small_blind + big_blind + ante_total
```

**특수 — Heads-up (2인 테이블)**:
```
Dealer Position = SB Position
Opponent = BB Position

포스팅:
1. Dealer(SB) 납부
2. Opponent(BB) 납부
3. action_on = Dealer(SB) [PRE_FLOP에서 먼저 행동!]
   (다른 라운드는 BB가 먼저)

이유: Heads-up에서 SB가 버튼이자 먼저 행동하는 예외 규칙
```

---

### num_blinds = 3: Small Blind + Big Blind + Third Blind

**해당 상황**: 일부 토너먼트, Straddle 있는 캐시 게임

**포스팅 순서**:
1. SB 위치 플레이어가 `small_blind` 납부
2. BB 위치 플레이어가 `big_blind` 납부
3. **Third Blind**(보통 UTG+1 또는 SB 왼쪽) 플레이어가 `third_blind` 납부
   - 금액: 보통 2×BB
4. Ante 수거
5. `biggest_bet_amt = max(bb, third_blind)`
6. `action_on = 첫 액션 플레이어`

**금액**:
```
팟 = small_blind + big_blind + third_blind + ante_total
```

---

## Straddle — 추가 블라인드

Straddle은 UTG 또는 Button 위치 플레이어가 **자발적으로** 납부하는 추가 블라인드이다. 2× BB 금액으로 베팅 순서와 최소 레이즈 기준을 변경한다.

### 활성화 조건

| 필드 | 조건 | 설명 |
|------|------|------|
| **straddle_enabled** | true | Straddle이 활성화됨 |
| **straddle_position** | UTG 또는 Button | 중간 위치는 불가 |
| **player.stack** | ≥ 2× BB | 스택 부족 시 옵션 회색 처리 |

### 포스팅 절차

1. SB/BB 포스팅 완료 후
2. Straddle 위치 플레이어에게 Straddle 옵션 제시
3. Straddle 선택 시 자동 수납: `player[straddle].stack -= straddle_amount`
4. `biggest_bet_amt = straddle_amount` (기존 BB 대신 Straddle이 기준)
5. `action_on` 변경: Straddle 양옆부터 시작 (Straddle 플레이어가 마지막)

### 액션 순서 변경

```
표준 (Straddle 없음):
  SB → BB → UTG → UTG+1 → ... → BTN → SB → BB (PRE_FLOP)

UTG Straddle 적용:
  SB → BB → [UTG Straddle 포스팅] → UTG+1 → ... → BTN → SB → BB → UTG(Last)
  (Straddle 플레이어가 마지막 액션 = Option 취득)
```

### Straddle 경우의 수

| Straddle Enabled | Position | Stack | 결과 |
|:--------:|:--------:|:--------:|----------|
| ❌ | UTG | ≥ 2BB | Straddle 옵션 없음, 표준 PRE_FLOP |
| ✅ | UTG | ≥ 2BB | Straddle 선택 가능 |
| ✅ | UTG | < 2BB | 스택 부족, 옵션 회색 처리 |
| ✅ | Button | ≥ 2BB | Button Straddle 선택 가능 |
| ✅ | (Middle) | ≥ 2BB | 중간 위치는 Straddle 불가 |

### Re-Straddle

Straddle 이후 다음 플레이어가 추가 Straddle(4× BB)을 선택할 수 있는 경우:
- `re_straddle_enabled = true`일 때만 허용
- 금액: 이전 Straddle × 2
- 마지막 Straddle 플레이어가 최종 Option 취득

> 참고: Straddle과 Bomb Pot은 동시 활성화 불가능 (PRE_FLOP 진행 방식 충돌)

---

## Heads-up (2인) 특수 규칙

### 위치 변경

| 구분 | 일반 테이블(3명+) | Heads-up (2인) |
|------|:----:|:----:|
| **Dealer 위치** | BTN | SB (Dealer = SB) |
| **SB 납부자** | Dealer 왼쪽 | Dealer 자신 |
| **BB 납부자** | SB 왼쪽 | 상대방 |
| **PRE_FLOP first to act** | UTG | **SB(Dealer)** |

### Heads-up 액션 순서

```
PRE_FLOP:
  1. SB(Dealer) 먼저 행동
  2. BB(상대) 두 번째

FLOP, TURN, RIVER:
  1. BB(상대) 먼저 행동
  2. SB(Dealer) 두 번째
```

### 헤즈업 전환 시 Button 조정 (WSOP Rule 87)

**원칙**: 3명+ → 2명 전환(플레이어 탈락 등) 시, 직전 핸드에서 BB였던 플레이어가 다음 핸드에도 연속으로 BB가 되지 않도록 button 위치를 조정한다. 이는 WSOP Official Live Action Rules Rule 87의 "헤즈업 플레이를 시작할 때 두 참가자 모두 연속으로 빅 블라인드가 없도록 버튼을 조정해야 할 수 있습니다" 조항에 근거한다.

#### 전환 감지

```
HAND_COMPLETE 시점:
    num_active_next = count(seats where status != SITTING_OUT and stack > 0)
    if num_active_next == 2 and state.num_active_prev_hand >= 3:
        apply_heads_up_button_adjustment()
```

#### Button 조정 규칙

```
apply_heads_up_button_adjustment():
    prev_bb = state.prev_hand_bb_seat  // 직전 핸드 BB 위치
    remaining = [seats[i] for i in active_seats]

    if prev_bb in remaining:
        # 이전 BB 플레이어가 살아있음 → 다음 핸드에서 Dealer(=SB)로 전환
        new_dealer_seat = prev_bb
    else:
        # 이전 BB가 이미 탈락 → 정상 회전
        new_dealer_seat = (state.dealer_seat + 1) % n

    state.dealer_seat = new_dealer_seat
```

**의존 State**: `state.prev_hand_bb_seat: int?` 필드가 필요하다 (BS-06-00-REF Ch1 Seat/Game state 참조). HAND_COMPLETE 시 현재 `bbSeat`를 이 필드에 복사한다.

#### 예시

3인 토너먼트, 직전 핸드에서 P3이 BB였고, 해당 핸드에서 P1이 탈락한 상황:

**직전 핸드**:
- dealer=P1, sb=P2, bb=P3
- 결과: P1 탈락, P2/P3 생존
- `state.prev_hand_bb_seat = P3`

**다음 핸드 (헤즈업 시작)**:
- 조정 전 (정상 회전): dealer=P2, sb=P2, bb=P3 → **P3이 연속 BB (규정 위반)**
- 조정 후 (Rule 87): dealer=P3(=SB), bb=P2 → P2가 BB, P3은 SB
- 결과적으로 P3의 연속 BB 상황 방지

### 딜링 순서 보충 (Rule 87)

WSOP Rule 87은 "마지막 카드는 버튼으로 처리됩니다"를 명시한다. 헤즈업에서 카드 딜링은 실질적으로 다음 순서를 따른다:

1. 첫 번째 hole card: **BB(상대방)** 에게 먼저
2. 두 번째 hole card: BB → **SB(Dealer)**
3. 결과적으로 마지막 카드가 Dealer에게 도달

**Engine 구현**: 논리적 딜링 순서는 `DealHoleCards` 이벤트의 `cards` 맵 순서로 표현한다. 물리적 RFID 스캔 순서는 Team 4 CC의 hardware layer 담당이며, 엔진은 논리적 순서만 보장한다.

---

## Missed Blind 복귀 규정 (WSOP Rule 86)

**원칙**: 플레이어가 SB 또는 BB 포지션을 놓친 후(sit out, 자리 이탈 등) 복귀할 때는 missed blind를 포스팅해야 한다. 이는 WSOP Official Live Action Rules Rule 86에 근거한다.

### Missed Blind 감지

HAND_COMPLETE 시점에 각 seat를 점검하여 missed 플래그를 설정한다:

```
HAND_COMPLETE 시점:
    for seat in state.seats:
        if seat.status == SITTING_OUT:
            if seat.index == sb_index:
                seat.missed_sb = true
            if seat.index == bb_index:
                seat.missed_bb = true
```

**의존 State**: `seat.missed_sb: bool`, `seat.missed_bb: bool` 필드가 필요하다 (BS-06-00-REF Ch1 Seat state 참조).

### 복귀 옵션

플레이어가 `SitIn { seat_index }` 이벤트로 복귀 신청 시, missed 상태에 따라 옵션이 결정된다:

| missed_sb | missed_bb | 복귀 옵션 | 설명 |
|:---------:|:---------:|----------|------|
| false | false | 즉시 복귀 | 포스팅 의무 없음 |
| true  | false | 다음 SB 포지션까지 대기 또는 즉시 SB+BB 포스트 | SB는 dead, BB는 live bet |
| false | true  | 다음 BB 포지션까지 대기 또는 즉시 BB 포스트 | BB는 live bet |
| true  | true  | SB+BB 동시 포스트 (SB dead, BB live) 또는 다음 BB까지 대기 | 양쪽 포스팅 의무 |

### 의도적 회피 처벌

Rule 86은 "의도적으로 blind를 피하는" 경우 두 블라인드 모두 몰수 + 패널티 부과를 규정한다. 단, EBS 엔진은 의도 감지가 불가능하므로 다음과 같이 처리한다:

- Lobby 측에서 seat 이동 기능 사용 시 Staff 수동 감시
- Staff App에서 "missed blind intentional" 플래그 수동 설정 허용
- Missed blind 포스팅 없이 복귀 시도 시 엔진은 경고만 표시 (차단하지 않음)
- 패널티 부과는 운영자 재량으로 ManagerRuling 이벤트 (IE-12)로 기록한다. Staff가 수동 감지 후 CC에서 ManagerRuling(penalty_type, seat_index)를 전송하면, 엔진은 감사 로그에 기록하고 OutputEvent(HandKilled 또는 Rejected)를 발행한다.

### 리셋 조건

`missed_sb = false`, `missed_bb = false` 리셋 시점:

- 해당 blind 포지션에 도달하여 정상 포스팅 완료
- 수동 포스팅 (다음 핸드 시작 전 `SitIn` + `PostBlinds` 옵션 포함)
- Tournament 새 level 시작 (선택적, House 규정에 따름)

---

## Dead Button (빈 좌석 처리)

**상황**: 테이블에 빈 좌석이 있고 Button이 그곳에 위치한 경우

**규칙**:
1. **Button 건너뛰기**: Button이 빈 좌석이므로 "위치"로는 존재하지 않음
2. **SB 미포스팅 가능**: SB는 빈 좌석일 수 있으므로 건너뛸 수 있음
3. **BB는 항상 존재**: 제자리 또는 다음 활성 플레이어
4. **액션 순서**: Button → SB(빈 경우) → BB → UTG (순환)

```
예: 좌석 0(비어있음)=Button, 좌석 1(P1)=SB, 좌석 2(비어있음), 좌석 3(P3)=BB
→ SB = 좌석 1
→ BB = 좌석 3
→ 액션 순서: 좌석 3 → 좌석 4 → ... → 좌석 1
```

---

## Bomb Pot (특수 모드)

**조건**: `bomb_pot_active == true` AND `bomb_pot_amount > 0`

**절차**:
1. **NEW HAND 버튼 클릭**
2. **모든 활성 플레이어가 `bomb_pot_amount`를 팟에 자동 입금**
   ```
   팟 += bomb_pot_amount × num_active_players
   ```
3. **PRE_FLOP 베팅 라운드 스킵** → 직접 FLOP 진행
4. **Flop 카드 3장 공개** (RFID 또는 수동)
5. **이후 표준 베팅 라운드 진행** (FLOP → TURN → RIVER → SHOWDOWN)

**특징**: 캐시 게임에서 이벤트성 진행. PRE_FLOP 베팅 없이 즉각 보드 진행으로 스릴 증가.

---

## 유저 스토리

| # | As a | When | Then |
|:-:|------|------|------|
| 1 | 운영자 | 10인 NL Hold'em, NEW HAND 버튼, BB=1000, BB Ante=1000 | SB=500, BB=1000, Ante 10명×1000=10000 포스팅 → action_on=UTG |
| 2 | 운영자 | 6인 테이블 Button Ante, BB=100 | BTN 플레이어만 6×100=600 납부, 다른 플레이어 변화 없음 |
| 3 | 운영자 | Live Ante=100, BB=1000, 누군가 500 Bet | UTG 콜하려면 500-100(Ante 포함)=400만 추가 |
| 4 | 운영자 | Heads-up 2인 게임, NEW HAND | Dealer(SB)=500 납부, Opponent(BB)=1000 납부 → SB가 PRE_FLOP 먼저 행동 |
| 5 | 운영자 | 3명 테이블 num_blinds=3 (Third Blind) | SB=50, BB=100, UTG+1(Third)=200 포스팅 → biggest_bet=200 |
| 6 | 운영자 | Dead Button 상황, BTN=빈 좌석 | SB 포스팅 스킵 또는 다음 활성 플레이어로 이동 |
| 7 | 운영자 | Bomb Pot 모드, 새 핸드 시작 | 모든 플레이어 bomb_pot_amount 자동 납부 → PRE_FLOP 스킵 |
| 8 | 운영자 | TB Ante, 6인 테이블 | SB+BB가 Ante 6×100=600을 합산 처리, 팟+=600 |
| 9 | 운영자 | Standard Ante, 8인, ante=50 | 모든 플레이어 50×8=400 납부 (동일 금액) |
| 10 | 운영자 | 블라인드 변경 (토너먼트 레벨 상승) | 이전 핸드 완료 후 새 SB/BB 값으로 다음 핸드 진행 |
| 11 | 운영자 | 칩 부족 플레이어, SB 500 필요한데 350만 보유 | 350 자동 납부 (All-in), Side Pot 발생 |
| 12 | 운영자 | Straddle 게임, UTG 플레이어 200(2× BB) 자발적 포스팅 | BB Ante 처리 후 Straddle 추가 → action_on = UTG (마지막) |
| 13 | 운영자 | 3인 테이블, BB Ante, 1명이 Sitout | Sitout 플레이어 Ante 제외, 2명만 Ante 수거 |
| 14 | 운영자 | 토너먼트 진행 중, "Blinds Up" | 현재 핸드 완료 후 다음 핸드부터 새 BB/SB 적용 |
| 15 | 운영자 | 블라인드 포스팅 실패 (시스템 에러) | UNDO 버튼으로 이전 상태 복귀, 강제 베팅 재시도 |
| 16 | 시스템 | 강제 베팅 수거 완료, action_on 결정 | 팟 값 확정, hand_in_progress=true, 베팅 라운드 시작 가능 |

---

## 경우의 수 매트릭스

### Matrix 1: Ante Type × Blind Count

| Ante Type | 납부자 | Dead/Live | num_blinds=0 |
|:---------:|-------|:---------:|:----:|
| **0** (std) | 전원 | Dead | 전원 |
| **1** (button) | BTN 1명 | Dead | BTN 대납 |
| **2** (bb_ante) | BB 1명 | Dead | BB 대납 |
| **3** (bb_1st) | BB 1명 | Dead | BB 대납 + BB먼저 |
| **4** (live) | 전원 | **Live** | 전원(라이브) |
| **5** (tb) | SB+BB | Dead | SB+BB 나눔 |
| **6** (tb_1st) | SB+BB | Dead | SB+BB 나눔 + 먼저 |

> 참고: num_blinds 1~3 조합은 위 패턴에서 SB/BB/Third Blind를 추가하여 확장된다. 전체 28가지 조합이 존재한다.

### Matrix 2: 팟 초기값 계산 공식

| 요소 | 계산식 |
|------|-------|
| **SB 기여** | small_blind (if num_blinds ≥ 2) |
| **BB 기여** | big_blind (if num_blinds ≥ 1) |
| **Third 기여** | third_blind (if num_blinds == 3) |
| **Ante 기여** | ante_amount × count (ante_type별) |
| **Straddle 기여** | straddle_amount (if straddle active) |
| **총 팟** | SB + BB + Third + Ante + Straddle |

**예시 1** (6인 NL Hold'em, BB Ante):
```
SB = 500
BB = 1000
ante_type = 2 (BB Ante)
ante_amount = 1000
num_seats = 6

pot_initial = 500 + 1000 + (1000 × 6) = 8500
```

**예시 2** (6인 NL Hold'em, Straddle):
```
SB = 500
BB = 1000
Straddle = 2000 (UTG)

pot_initial = 500 + 1000 + 2000 = 3500
biggest_bet_amt = 2000 (Straddle 기준)
```

---

## 포스팅 순서 알고리즘

> `-=`는 '왼쪽 값에서 오른쪽 값을 빼고 저장'하는 연산입니다. 예: `stack -= 100`은 stack에서 100을 뺀 결과를 stack에 다시 저장합니다.

```pseudo
1. 현재 dealer_seat을 기준으로 좌측 방향(시계 방향)으로 이동
2. SB 위치 플레이어 찾기 (dealer 왼쪽)
3. SB 납부: player[SB].stack -= small_blind
4. BB 위치 플레이어 찾기 (SB 왼쪽)
5. BB 납부: player[BB].stack -= big_blind
6. (if num_blinds == 3)
   - 3rd 위치 플레이어 (BB 왼쪽 또는 지정)
   - Third 납부: player[3rd].stack -= third_blind
7. Ante 수거 (ante_type별로)
   - std_ante: 모든 플레이어 -ante_amount
   - button_ante: player[BTN].stack -= (ante_amount × num_seats)
   - bb_ante: player[BB].stack -= (ante_amount × num_seats)
   - live_ante: 모든 플레이어 -ante_amount + current_bet 갱신
   - tb_ante: player[SB], player[BB]가 나눔
8. (if straddle_enabled && straddle 선택)
   - player[straddle].stack -= straddle_amount
   - biggest_bet_amt = straddle_amount
9. biggest_bet_amt = max(BB, Third, Straddle)
10. first_to_act = UTG (또는 다른 규칙 if bb_1st, tb_1st, straddle)
11. acted_this_round = {}  // ⚠️ 반드시 빈 셋으로 초기화. 블라인드/앤티 포스팅은 액션이 아님.
                           //    BB.current_bet = big_blind이지만 acted_this_round에 BB 포함 금지.
                           //    이 규칙 위반 시 BB 체크 옵션이 소실됨 (is_betting_round_complete 조건 3 참조)
```

### 포스팅 순서 알고리즘 (Pseudocode)

모든 Ante 타입에 대한 통합 포스팅 순서:

```
function postBlindsAndAntes(state, anteType):
  // Step 1: Ante 포스팅 (type에 따라 분기)
  switch anteType:
    case 0 (Standard):
      for each active seat in clockwise order:
        post(seat, ante_amount, as_dead_money=true)
    case 1 (Button):
      post(dealer_seat, ante_amount, as_dead_money=true)
    case 2 (BB Ante):
      // BB가 전원분 대납
      post(bb_seat, ante_amount * active_count, as_dead_money=true)
    case 3 (BB 1st):
      // BB Ante와 동일하되 BB가 먼저 행동 (firstToAct 변경)
      post(bb_seat, ante_amount * active_count, as_dead_money=true)
    case 4 (Dead Ante):
      // Ante를 currentBet에 포함하지 않음
      for each active seat: post(seat, ante_amount, as_dead_money=true)
    case 5 (Straddle):
      // 별도 StradlePost 이벤트로 처리
      post(straddle_seat, straddle_amount, as_live_bet=true)
    case 6 (Kill):
      post(kill_seat, kill_amount, as_live_bet=true)

  // Step 2: Blind 포스팅
  post(sb_seat, sb_amount, as_live_bet=true)
  post(bb_seat, bb_amount, as_live_bet=true)
  
  // Step 3: Short Contribution 처리
  // stack < required_amount → 전액 투입, allIn 전환
  // 미달 금액은 Dead Money로 Main Pot에 합산
  
  // Step 4: 상태 초기화
  acted_this_round = {}  // 블라인드/ante 포스터 미포함
  street = preflop
  firstToAct = nextActiveAfter(bb_seat)  // Straddle 시 nextActiveAfter(straddle_seat)
```

---

## 비활성 조건

1. **hand_in_progress == true** — 이미 핸드 진행 중
2. **num_seats < 2** — 플레이어 부족
3. **pl_dealer == -1** — 딜러 위치 미정
4. **num_blinds 미정** — Blind 구조 설정 안 됨
5. **게임 상태 ∉ {IDLE, HAND_COMPLETE}** — 핸드 진행 중 상태

---

## 영향 받는 요소

### 직접 영향

| 요소 | 변경 |
|------|------|
| **pot** | 강제 베팅 합계만큼 증가 |
| **player[i].stack** | 강제 베팅 금액만큼 감소 |
| **player[i].current_bet** | Blind 납부분 설정 |
| **biggest_bet_amt** | BB 또는 Straddle 기준 |
| **action_on** | first_to_act 또는 특수 규칙 |
| **hand_in_progress** | false → **true** 전환 |
| **state** | IDLE → **SETUP_HAND** |

### 간접 영향

| 요소 | 영향 |
|------|------|
| **CC UI 버튼** | 강제 베팅 완료 후 액션 버튼 활성화 |
| **overlay.pot_display** | 팟 값 갱신 및 오버레이 업데이트 |
| **session_statistics** | ante_collected, blind_collected 누적 |
| **Undo 버튼** | 최대 5단계 UNDO 시 강제 베팅 상태도 복구 가능 |

---

## 오류 처리 및 Edge Cases

### Case 1: 칩 부족

```
상황: SB=500 필요, player.stack=300

처리:
1. 가능한 만큼 납부: 300
2. player.status = "allin"
3. Side Pot 발생
4. 다음 핸드부터는 플레이어 제외 또는 Re-buy
```

### Case 2: Sitout 플레이어

```
상황: 8인 테이블, 1명이 sitout 중

처리:
1. Sitout 플레이어는 강제 베팅 제외
2. 나머지 7명만 Ante 수거 (if std_ante)
3. Blind는 위치 기반이므로 Sitout도 위치 도달 시 지급 필요
```

### Case 3: Blind Posting 실패

```
상황: 네트워크 지연으로 SB 납부 기록 누락

처리:
1. 게임 엔진이 "Blind Incomplete" 감지
2. 운영자에게 경고 ("Blind posting failed")
3. UNDO 버튼으로 복귀
4. 재시도
```

### Case 4: Multiple All-ins with Different Stacks

```
상황: SB=500, BB=1000, 4인 플레이어 칩: 300, 700, 900, 5000

처리:
1. 플레이어 1: 300 All-in (SB 500 필요 but 부족)
2. 플레이어 2: 700 All-in (BB 1000 필요 but 부족)
3. 플레이어 3: 900 All-in
4. 플레이어 4: 정상 post

→ Main Pot: 300×4 = 1200
→ Side Pot 1: (700-300)×3 = 1200
→ Side Pot 2: (900-700)×2 = 400
```

---

## 통계 및 로깅

### 기록되는 항목

| 필드명 | 타입 | 설명 |
|-------|------|------|
| `session_ante_paid` | dict | {player_id: 누적 ante} |
| `session_blind_paid` | dict | {player_id: 누적 blind} |
| `hand_ante_collected` | int | 현재 핸드 Ante 수거액 |
| `hand_blind_collected` | int | 현재 핸드 Blind 수거액 |
| `pot_initial_value` | int | 강제 베팅 완료 후 팟 초기값 |
| `forced_bet_timestamp` | timestamp | 강제 베팅 수거 시각 |

---

## 개발자 참고

### 상태 머신 전이

```
[IDLE]
  ↓ NEW HAND 버튼 또는 NextHand()
[강제 베팅 수거 시작]
  ├─ Blind 포스팅 (SB → BB → 3rd)
  ├─ Ante 수거 (ante_type별)
  ├─ Straddle 옵션 (활성화 시)
  ↓ 모두 완료
[SETUP_HAND]
  ↓ 카드 딜 시작
[PRE_FLOP]
```

### 금액 계산 우선순위

1. Blind (위치 기반, 고정)
2. Ante (Type별 계산)
3. Straddle (자발적 추가)
4. All-in / Short stack 조정

### 테스트 케이스

- [ ] Type 0 (std_ante) × 4개 blind 조합
- [ ] Type 1 (button_ante) × 3개 blind 조합
- [ ] Type 2 (bb_ante) × 2개 blind 조합
- [ ] Type 3 (bb_1st) × 2개 blind 조합
- [ ] Type 4 (live_ante) × 3개 조합
- [ ] Type 5 (tb_ante) × 2개 조합
- [ ] Type 6 (tb_1st) × 2개 조합
- [ ] Heads-up 2인 특수 규칙
- [ ] Dead Button + Sitout
- [ ] Bomb Pot 모드
- [ ] Straddle (UTG + Button + Re-Straddle)
- [ ] Multiple All-ins + Side Pots
- [ ] UNDO 후 강제 베팅 복구
