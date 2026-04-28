---
title: Betting & Pots — Domain Master
owner: team3
tier: contract
legacy-ids:
  - BS-06-02   # Holdem/Betting.md (베팅 액션 6종 + NL/PL/FL × 특수 상황)
  - BS-06-03   # Holdem/Blinds_and_Ante.md (Ante 7종 + Blind 4종 + Straddle + Heads-up + Missed Blind)
  - BS-06-06   # Holdem/Side_Pot.md (사이드팟 생성 + 역순 판정)
  - BS-06-07   # Holdem/Showdown.md (카드 공개 + Muck + Hand 보호 + Run It Twice)
last-updated: 2026-04-28
related:
  - "Behavioral_Specs/Lifecycle_and_State_Machine.md"      # Phase 1 도메인 (HandFSM 전이)
  - "Behavioral_Specs/Triggers_and_Event_Pipeline.md"      # Phase 2 도메인 (IE/IT/OE 카탈로그)
  - "../2.5 Shared/BS_Overview.md"                           # GameState 권위
---

# Betting & Pots — Domain Master

> **존재 이유**: Hold'em 의 베팅 라운드 전체 사이클 (강제 베팅 → 액션 → 팟 분리 → 쇼다운 카드 공개 → 핸드 보호) 을 단일 SSOT 로 통합한다. BS-06-02 + BS-06-03 + BS-06-06 + BS-06-07 4개 문서를 zero information loss 로 병합. 상태 전이는 Lifecycle 도메인, 이벤트 파이프라인은 Triggers 도메인 권위.

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-06 | BS-06-02 신규 | 6 액션 × 3 bet_structure × 특수 케이스 |
| 2026-04-06 | BS-06-03 신규 | Ante 7종 + Blind 4종 + Straddle + Heads-up + Bomb Pot |
| 2026-04-06 | BS-06-06 신규 | N-player all-in 사이드팟 생성/계산/판정 |
| 2026-04-06 | BS-06-07 신규 | 카드 공개 48 조합 + Muck + Venue/Broadcast Canvas |
| 2026-04-09 | BS-06-02 GAP-GE-006 | CALL/BET/RAISE/ALL-IN → is_betting_round_complete 분기 + 스트리트 전환 초기화 |
| 2026-04-09 | BS-06-02 CALL 보강 | enforcement pseudocode, 외부 amount 무시 강제 |
| 2026-04-10 | WSOP P0 (BS-06-02) | §5.1 Under-raise (Rule 95) + §5.2 Raise Cap (Rule 100.b) + §6.1 Incomplete All-in (Rule 96) |
| 2026-04-10 | WSOP (BS-06-02) | Rule 56 verbal/chip + Rule 80-83 Time bank/At-seat 참조 |
| 2026-04-10 | WSOP (BS-06-03) | Heads-up Button Adjust (Rule 87), Missed Blind 복귀 (Rule 86) |
| 2026-04-10 | WSOP P1/P2 (BS-06-07) | Tabled Hand 보호 (Rule 71), Folded Hand 복구 (Rule 110), Muck 재판정 (Rule 109) |
| 2026-04-13 | GAP-C (BS-06-03) | 통합 포스팅 순서 Pseudocode + ManagerRuling 패널티 |
| 2026-04-28 | 도메인 통합 (본 문서) | BS-06-02 + 03 + 06 + 07 lossless 병합. legacy-ids 보존. Lifecycle/Triggers 도메인 권위 위임. Chunk-by-chunk commit (sibling worktree). |

---

## 1. Overview & Definitions

### 1.1 도메인 정의

본 도메인은 핸드 진행 중 **칩이 움직이는 모든 메커니즘** 을 통합한다:

1. **강제 베팅 (BS-06-03)**: SETUP_HAND 진입 시 Ante 7종 + Blind 4종 + Straddle 자동 수거 → `pot_initial` + `biggest_bet_amt` 확정
2. **베팅 액션 (BS-06-02)**: PRE_FLOP ~ RIVER 동안 Fold/Check/Bet/Call/Raise/All-in 6 액션 × NL/PL/FL 3 bet_structure 처리
3. **사이드팟 (BS-06-06)**: 서로 다른 all-in 금액으로 인한 자동 팟 분리 + eligible set 계산 + 역순 판정
4. **쇼다운 (BS-06-07)**: 카드 공개 순서 (Last Aggressor first) + Muck 권리 + Venue/Broadcast Canvas 차이 + Run It Twice + Hand 보호/복구

상태 전이 자체는 Lifecycle 도메인 마스터 권위. 본 도메인은 그 결과 **칩 흐름 + 팟 형성 + 승자 결정** 만 담는다.

### 1.2 핵심 개념 정의

#### 1.2.1 베팅 액션 (BS-06-02 §정의)

**베팅 액션**: 현재 액션 턴 (`action_on`) 을 가진 플레이어가 자신의 의도를 선언하는 행동. 6가지 유형:

1. **Fold** — 현재 핸드를 포기하고 팟에서 탈락
2. **Check** — 베팅 없이 액션을 다음 플레이어에게 넘김
3. **Bet** — 현재 스트리트에서 처음으로 금액을 베팅
4. **Call** — 현재까지 가장 높은 베팅액과 같은 금액을 납부
5. **Raise** — 현재까지 가장 높은 베팅액을 초과하는 금액을 베팅
6. **All-in** — 자신의 모든 칩을 팟에 넣음 (금액과 무관하게 상태 전환)

#### 1.2.2 베팅 구조 (bet_structure, BS-06-02 §정의)

- **NL (No Limit)** — 최소 big_blind 이상이면 스택 전액까지 베팅 가능
- **PL (Pot Limit)** — 베팅 금액의 상한 = 팟 + 2×콜액 계산식 적용
- **FL (Fixed Limit)** — 각 스트리트별 고정 금액 (low_limit / high_limit) 및 레이즈 상한 제한

#### 1.2.3 강제 베팅 (BS-06-03 §정의)

운영자가 CC 버튼을 누르지 않아도 게임 규칙에 의해 **자동으로 수거** 되는 의무 납부금:

- **Ante**: 핸드 시작 전 전원 (또는 특정 플레이어) 이 납부하는 추가 의무금
- **Blind**: 딜러 위치 기준 2~3명이 **순차적으로** 납부하는 강제 베팅
- **Straddle**: UTG 또는 Button 위치 플레이어가 자발적으로 납부하는 **추가 블라인드** (2× BB)

**속성**:
- **Dead Money vs Live Money**: Ante/Blind 는 일반적으로 Dead 이지만, Live Ante 는 예외
- **자동 처리**: 운영자 입력 불필요, 게임 엔진이 자동 처리
- **팟 초기값**: 모든 강제 베팅 합계 = `pot_initial`

#### 1.2.4 사이드팟 (BS-06-06 §정의)

**사이드팟**은 플레이어의 투입액 차이로 인해 자동으로 생성되는 **팟 분리 구조**:

- **메인팟**: 모든 플레이어가 참여 가능한 최소 투입액 기반 팟
- **사이드팟**: 추가 투입액 기반의 팟 (메인팟 이후)
- **eligible set**: 해당 팟에 우승할 자격이 있는 플레이어 목록

**핵심 원칙**:
- 모든 플레이어가 기여한 금액만큼만 팟에 참여 가능
- 팟 분배 순서는 **역순** (가장 작은 eligible set 의 팟부터)
- Fold 플레이어의 데드 머니 (이미 폴드한 플레이어가 넣어둔, 돌려받을 수 없는 금액) 는 각 팟에 비례 분배

#### 1.2.5 쇼다운 카드 공개 (BS-06-07 §정의)

**카드 공개**는 SHOWDOWN 또는 ALL_IN_RUNOUT 단계에서 플레이어의 홀카드를 가시화하는 프로세스:

- **Last Aggressor**: 마지막 베팅/레이즈를 한 플레이어 (공개 우선권)
- **Muck**: 패배자가 카드를 비공개 상태로 유지할 권리
- **Venue Canvas**: 신뢰성 중심 (홀카드 절대 미공개) — 현장 관중용 화면, 공정성 유지
- **Broadcast Canvas**: 시각화 중심 (항상 홀카드 표시, 이전 상태 유지) — 방송 시청자용 화면, 흥미 유발

**핵심 원칙**:
- 공개 순서: last aggressor first, then clockwise
- Muck 권리는 showdown 에서만 적용 (all-in 경우 강제 공개)
- Venue 와 Broadcast 는 홀카드 가시성이 반대

### 1.3 베팅 입력 방식 (BS-06-02 WSOP Rule 56)

EBS 는 CC (Command Center) 의 전자식 입력을 유일한 공식 소스로 간주한다. WSOP Official Live Action Rules Rule 56 은 구두/칩 동시 발생 시의 우선순위 (구두 우선, 또는 먼저 발생한 쪽 우선) 를 규정하지만, EBS 운영 환경에서는 다음과 같이 해석한다:

1. **라이브 테이블 (physical)**: 딜러 또는 CC 운영자가 Rule 56 을 적용하여 verbal/chip 의도를 판단한 후, 결과를 CC 에 **단일 이벤트** 로 입력한다.
2. **EBS Engine**: CC 가 전송한 이벤트를 재해석 없이 그대로 수락한다. Rule 56 재해석은 수행하지 않는다.
3. **CC UI 구현 권고** (Team 4 참조):
   - 구두 먼저 → 칩 금액 불일치 시 구두 우선 (Rule 56 전단)
   - Amount-only 선언은 동일 금액 call/raise 로 자동 판정 (Rule 56.c "declaring 200 = silently pushing 200 chips")
   - 불분명한 상황은 Floor 판정 버튼으로 전환

이 레이어는 Rule 95 (under-raise) 와 Rule 96 (incomplete all-in) 과 **독립적** 으로 동작한다.

### 1.4 용어 사전 (4 문서 통합)

| 용어 | 출처 | 설명 |
|------|------|------|
| **CC** | BS-06-02/07 | Command Center, 운영자가 게임을 제어하는 화면 |
| **NL/PL/FL** | BS-06-02 | No Limit / Pot Limit / Fixed Limit 베팅 구조 |
| **Pseudocode** | All | 실제 프로그래밍 언어가 아닌 가상 코드 (참고용) |
| **scoop** | BS-06-02/06 | 한 사람이 팟 전체를 가져가는 것 |
| **odd chip** | BS-06-02/06 | 팟을 나눌 때 딱 떨어지지 않는 나머지 1개 베팅 토큰 |
| **FSM** | BS-06-03 | Finite State Machine — 게임 진행 단계 흐름도 |
| **Dead Money** | BS-06-03/06 | 폴드한 플레이어가 팟에 남긴 돌려받을 수 없는 금액 |
| **Live Money** | BS-06-03 | 첫 라운드 베팅에 포함되는 ante 금액 (Live Ante 예외) |
| **Straddle** | BS-06-02/03 | UTG 또는 Button 의 자발적 추가 블라인드 (2× BB) |
| **TB Ante** | BS-06-03 | Two Blinds Ante — SB+BB 가 합산하여 전원분 ante 부담 |
| **Bomb Pot** | BS-06-02/03 | 전원 고정액 자동 납부 + PRE_FLOP 스킵 → FLOP 직행 |
| **Dead Button** | BS-06-03 | 이전 딜러 좌석이 빈 경우 button 위치 유지 |
| **Last Aggressor** | BS-06-07 | 마지막 베팅/레이즈 플레이어 (공개 우선권) |
| **Muck** | BS-06-07 | 패를 공개하지 않고 버리는 것 |
| **eligible set** | BS-06-06 | 해당 팟에 우승할 자격이 있는 플레이어 목록 |
| **cascade** | BS-06-06 | 하나의 이벤트가 연쇄적으로 다른 이벤트 발생 |
| **홀카드 (hole card)** | BS-06-07 | 각 플레이어에게 비공개로 나눠주는 카드 |

### 1.5 핵심 원칙 (4 문서 종합)

- 강제 베팅 (Ante/Blind/Straddle) 은 모두 결정론적 자동 처리 — 운영자 개입 없음
- 베팅 액션은 CC 의 단일 이벤트로 처리되며, 엔진이 amount 검증 (REJECTED 시 재입력)
- Call/AllIn 의 amount 는 엔진 내부 재계산 (외부 전달값 무시) — BS-06-02 의 핵심 invariant
- 사이드팟 분리는 자동 — 운영자 수동 입력 불필요
- 쇼다운 카드 공개 순서는 Last Aggressor first, 그 다음 시계방향
- Muck 권리는 SHOWDOWN 에서만 (ALL_IN_RUNOUT 은 강제 공개)

---

## 2. State Machine / Data Flow

### 2.1 Betting Round 전체 흐름

```
[SETUP_HAND]
  ├─ Step 1: Ante 포스팅 (ante_type 0~6 별 분기)
  ├─ Step 2: Blind 포스팅 (SB → BB → Third)
  ├─ Step 3: Straddle 옵션 (활성화 시)
  ├─ Step 4: Short Contribution 처리 (자동 all-in)
  ├─ Step 5: 상태 초기화 (acted_this_round = {})
  ↓
[PRE_FLOP] (Bomb Pot 시 SKIP → FLOP 직행)
  ├─ first_to_act = UTG (또는 SB heads-up / Straddle 다음)
  ├─ Loop: PlayerAction (Fold/Check/Bet/Call/Raise/AllIn)
  │       └─ is_betting_round_complete? (BS-06-10 권위 / Lifecycle 도메인 §5.7)
  ├─ Side Pot 분리 (all-in 발생 시 자동)
  ↓ (betting_round_complete == true)
[FLOP]
  ├─ 스트리트 전환 초기화 (biggest_bet_amt=0, current_bet=0, num_raises=0, acted_this_round={})
  ├─ first_to_act = SB (또는 BB heads-up)
  ├─ Loop: PlayerAction
  ↓
[TURN] (동일)
  ↓
[RIVER] (동일, final_betting_round=true)
  ↓
[SHOWDOWN]
  ├─ 카드 공개 순서: Last Aggressor first → clockwise
  ├─ Run It Twice 옵션 (조건 충족 시)
  ├─ 사이드팟 역순 판정: 가장 작은 eligible set 팟부터
  ├─ 데드 머니 분배 (각 팟 비례)
  ├─ Muck 권리 (Venue/Broadcast 별)
  ↓
[HAND_COMPLETE]
  ├─ Hand 보호 & 복구 (Rule 71/109/110)
  ├─ Statistics 업데이트
  ├─ Missed Blind 마크 (Rule 86)
  ├─ Heads-up Button Adjust (Rule 87)
```

> 상태 전이 권위: Lifecycle 도메인 §3.3 매트릭스 1 (Hold'em 상태 상세) + §3.6 매트릭스 4 (특수 오버라이드).

### 2.2 GameState 핵심 필드 (베팅/팟 측 view)

> Data Model 권위: Lifecycle 도메인 §5.1 GameState. 본 도메인은 베팅/팟 관련 필드의 의미만 명시.

| 필드 | 타입 | 의미 |
|------|------|------|
| `pot` | Pot | 메인 팟 (amount + eligible_seats) |
| `side_pots` | Pot[] | 사이드 팟 배열 |
| `biggest_bet_amt` | int | 현재 스트리트 최고 베팅액 (Bet/Raise/All-in 갱신) |
| `last_raise_increment` | int | 직전 raise 의 증가분 (next min raise 계산 기반) |
| `min_raise_amt` | int | 다음 레이즈 최소액 |
| `num_raises_this_street` | int | 현재 스트리트 raise 횟수 (FL cap 카운터) |
| `acted_this_round` | Set\<int\> | 현재 라운드 액션한 좌석 (BB check option 보호) |
| `last_aggressor` | int | 마지막 베팅/레이즈 좌석 (Showdown 공개 우선권) |
| `bomb_pot_enabled` | bool | Bomb Pot 모드 활성화 |
| `bomb_pot_amount` | int | Bomb Pot 전원 납부 금액 |
| `bomb_pot_opted_out` | Set\<int\> | Bomb Pot opt-out 좌석 (Rule 28.3.2) |
| `tournament_heads_up` | bool | 토너먼트 2명 남음 (FL raise cap 무시 판정) |
| `straddle_enabled` | bool | Straddle 활성화 |
| `straddle_seat` | int | Straddle 좌석 (UTG 또는 Button) |
| `bb_ante` | bool | BB Ante 활성 |
| `ante_type` | int | 0~6 (std/button/bb/bb_1st/live/tb/tb_1st) |
| `prev_hand_bb_seat` | int? | 직전 핸드 BB 좌석 (Rule 87 Heads-up Button Adjust) |
| `boxed_card_count` | int | 현재 핸드 boxed card 누적 수 (Rule 88, 2+ 시 misdeal) |

### 2.3 Player 베팅 관련 필드

| 필드 | 타입 | 의미 |
|------|------|------|
| `current_bet` | int | 현재 스트리트 기여액 (스트리트 전환 시 0 리셋) |
| `total_invested` | int | 핸드 전체 누적 기여액 (사이드팟 계산 기준) |
| `stack` | int | 남은 칩 |
| `status` | enum | active / folded / allin / sitting_out / busted |
| `missed_sb` | bool | SB 포지션 놓침 (Rule 86) |
| `missed_bb` | bool | BB 포지션 놓침 (Rule 86) |
| `cards_tabled` | bool | 명시적 카드 공개 (Rule 71 보호 활성) |

### 2.4 Pot 구조 (BS-06-06 §데이터 모델)

```python
class SidePot:
    pot_id: int                # 0=메인팟, 1=사이드팟1, 2=사이드팟2, ...
    amount: float              # 팟 금액
    eligible_seats: set[int]   # 이 팟에 우승할 자격 있는 플레이어 좌석
    winner_seat: int = -1      # 우승자 좌석 (-1=미결정)
    winning_hand: HandRank     # 우승자의 핸드 평가

class PotStructure:
    main_pot: SidePot
    side_pots: list[SidePot]   # [사이드팟1, 사이드팟2, ...]
    total_pot: float           # 전체 팟 합계

    def get_all_pots() -> list[SidePot]:
        return [self.main_pot] + self.side_pots

class HandState:  # 확장
    all_in_amounts: dict[int, float]      # {seat: amount}
    pot_structure: PotStructure
    side_pot_verdicts: list[dict]         # [{pot_id, winner_seat, amount, hand_rank}]
```

### 2.5 ShowdownSettings 구조 (BS-06-07 §데이터 모델)

```python
class ShowdownSettings:
    # Visibility
    card_reveal_type: int      # 0~5 (immediate/after_action/end_of_hand/never/showdown_cash/showdown_tourney)
    show_type: int             # 0~3 (immediate/action_on/after_bet/action_on_next)
    fold_hide_type: int        # 0~1 (immediate/delayed)

    # Muck
    allow_muck: bool           # showdown_tourney=True, broadcast=False
    muck_default: bool         # True=기본 Muck, False=기본 Show

    # Canvas
    canvas_type: str           # "venue" or "broadcast"

class CardRevealState:
    revealed_seats: set[int]
    last_aggressor_seat: int
    reveal_order: list[int]                   # [last_agg, next_clockwise, ...]
    mocked_seats: dict[int, bool]
    revealed_cards: dict[int, list[Card]]     # {seat: [card1, card2]}

class HandState:  # 확장
    showdown_settings: ShowdownSettings
    card_reveal_state: CardRevealState
    last_aggressor_seat: int
    all_in_runout: bool        # True = 강제 공개
```

### 2.6 RunItTwiceState 구조 (BS-06-07 §Run It Twice)

```python
class RunItTwiceState:
    can_select_run_it_twice: bool = False
    run_it_times: int = 0                       # 0=미사용, 2=2회, 3=3회
    run_it_times_remaining: int = 0             # 남은 횟수
    run_it_times_board_cards: list[list[int]] = []  # 각 런별 보드 카드 저장
```

### 2.7 스트리트 전환 시 초기화 (BS-06-02 §스트리트 전환)

다음 스트리트로 전환될 때마다 아래 값을 반드시 초기화한다. **이 초기화 없이는 BET 조건 (`biggest_bet_amt == 0`) 이 절대 충족되지 않는다.**

| 필드 | 초기화 값 | 이유 |
|------|:---------:|------|
| `biggest_bet_amt` | 0 | BET 가능 조건 충족, 스트리트 독립 |
| `num_raises_this_street` | 0 | FL cap 카운터 리셋 |
| `player[*].current_bet` | 0 | 각 플레이어의 스트리트 기여도 리셋 |
| `acted_this_round` | `{}` | BS-06-10 위임, 블라인드 포스터 포함 금지 |

> `player[*].current_bet = 0` 초기화는 side pot 계산 기준이기도 하다. 스트리트 간 누적 기여액은 별도 `total_invested` 필드로 추적.

### 2.8 베팅 라운드 종료 확인 — 공통 프로토콜 (BS-06-02 §베팅 라운드 종료)

모든 베팅 액션 (FOLD, CHECK, BET, CALL, RAISE, ALL-IN) 처리 후, **반드시** `is_betting_round_complete(state)` (Lifecycle 도메인 §5.7) 를 호출해야 한다.

| 반환값 | 처리 |
|:------:|------|
| **true** | 다음 스트리트 이벤트 발행 (StreetAdvance) 또는 HAND_COMPLETE |
| **false** | `action_on = next_active_player(action_on)` 으로 이동, 다음 액션 대기 |

> 이 체크는 CHECK 액션에만 적용하는 것이 아니다. CALL 이 마지막 필요 액션인 경우 (레이즈 후 전원 콜 완료 등) CALL 직후 라운드가 종료된다.

---

## 3. Trigger & Action Matrix

### 3.1 베팅 액션 트리거 (BS-06-02 §트리거)

| 트리거 유형 | 조건 | 발동 주체 | 정확도 |
|-----------|------|---------|--------|
| **CC 액션 버튼** | 운영자가 FOLD, CHECK, BET, CALL, RAISE, ALL-IN 버튼 클릭 | 운영자 (수동) | ≤100ms |
| **금액 입력 후 CONFIRM** | 운영자가 금액을 직접 입력하고 확인 버튼 클릭 (BET/RAISE 만) | 운영자 (수동) | ≤150ms |
| **키보드 단축키** | 할당된 단축키 (예: F=Fold, C=Call, R=Raise) | 운영자 (수동) | ≤50ms |

**전제조건** (모두 참):
1. `hand_in_progress == true`
2. `GamePhase ∈ {PRE_FLOP, FLOP, TURN, RIVER}`
3. `action_on == player_index`
4. `player.status == active` (folded ❌, allin ❌, busted ❌)
5. `num_active_players ≥ 2`
6. `betting_round_complete == false`

### 3.2 강제 베팅 트리거 (BS-06-03 §트리거)

| 트리거 유형 | 조건 | 발동 주체 | 처리 시간 |
|-----------|------|---------|---------|
| **NEW HAND 버튼** | 운영자가 CC "NEW HAND" 클릭 + precondition 충족 | 운영자 (수동) | 즉시 (<50ms) |
| **게임 엔진 자동** | SendStartHand() 응답 수신 후 SETUP_HAND 진입 | 게임 엔진 (자동) | 계산 기반 |
| **상태 추적** | `hand_in_progress = true`, 강제 베팅 수거 완료 시점 | 게임 엔진 (자동) | 상태 전이와 동시 |

**전제조건**:
1. `hand_in_progress == false` — 이전 핸드 완료 또는 초기 상태
2. `pl_dealer != -1` — 딜러 위치 할당됨 (0~num_seats-1)
3. `num_blinds ∈ {0, 1, 2, 3}`
4. `ante_type ∈ {0~6}`
5. `num_seats ≥ 2`
6. 게임 상태 ∈ {IDLE, HAND_COMPLETE}

### 3.3 매트릭스 1: 액션별 유효성 검증 (BS-06-02 Matrix 1, 6 actions × 3 bet_structures)

| 액션 | NL 유효조건 | NL 금액 범위 | PL 유효조건 | PL 금액 범위 | FL 유효조건 | FL 금액 |
|:----:|-----------|-----------|-----------|-----------|-----------|---------|
| **Fold** | 항상 가능 (active 상태만) | N/A | 항상 가능 | N/A | 항상 가능 | N/A |
| **Check** | biggest_bet_amt == player.current_bet | N/A | biggest_bet_amt == player.current_bet | N/A | biggest_bet_amt == player.current_bet | N/A |
| **Bet** | biggest_bet_amt == 0 | [big_blind, stack] | biggest_bet_amt == 0 | [big_blind, pot + 2×big_blind] | biggest_bet_amt == 0 | limit 값 고정 |
| **Call** | biggest_bet_amt > player.current_bet | [call_amount, min(call_amount, stack)] | biggest_bet_amt > player.current_bet | [call_amount, min(call_amount, stack)] | biggest_bet_amt > player.current_bet | call_amount (고정) |
| **Raise** | biggest_bet_amt > 0 && last_raise_increment > 0 | [min_raise, stack] | biggest_bet_amt > 0 | [min_raise, pot + call_amt + biggest_bet_amt + call_amt] | biggest_bet_amt > 0 && raise_count < cap | limit 고정 |
| **All-in** | player.stack > 0 | player.stack (자동) | player.stack > 0 | player.stack (자동) | player.stack > 0 | player.stack (자동) |

### 3.4 매트릭스 2: 액션 유효성 (GamePhase × biggest_bet_amt × player.status, BS-06-02 Matrix 2)

| GamePhase | biggest_bet_amt == 0 | biggest_bet_amt > 0 | player.stack == 0 | player.status == folded |
|:--------:|:---:|:---:|:---:|:---:|
| **PRE_FLOP** | CHECK/BET/RAISE 가능 | CHECK ❌ / CALL/RAISE 가능 | ALL-IN 만 가능 | 모든 액션 ❌ |
| **FLOP** | CHECK/BET/RAISE 가능 | CHECK ❌ / CALL/RAISE 가능 | ALL-IN 만 가능 | 모든 액션 ❌ |
| **TURN** | CHECK/BET/RAISE 가능 | CHECK ❌ / CALL/RAISE 가능 | ALL-IN 만 가능 | 모든 액션 ❌ |
| **RIVER** | CHECK/BET/RAISE 가능 | CHECK ❌ / CALL/RAISE 가능 | ALL-IN 만 가능 | 모든 액션 ❌ |
| **SHOWDOWN** | 모든 액션 ❌ | 모든 액션 ❌ | 모든 액션 ❌ | 모든 액션 ❌ |

### 3.5 매트릭스 3: 베팅 특수 상황 (BS-06-02 Matrix 3)

| 상황 | 조건 | 처리 |
|:---:|------|------|
| **Short all-in** | call_amount > player.stack | 모두 올인 상태로 처리, side pot 분리 |
| **BB check option** | PRE_FLOP && biggest_bet_amt == BB && action_on == BB_index | CHECK 허용 (이후 레이즈 들어오면 다시 액션 턴) |
| **Cap reached** | num_raises >= 4 && num_active_players > 2 && street ≠ heads-up | 추가 레이즈 거부 |
| **Heads-up cap override** | num_active_players == 2 | cap 미적용, 무제한 레이즈 |
| **Live ante included** | ante > 0 && biggest_bet_amt == 0 | 첫 베팅 금액 ≥ BB + ante (선택 옵션) |
| **Bomb Pot** | bomb_pot_active == true && street == PRE_FLOP | PRE_FLOP 베팅 스킵, DEAL 직행 |
| **Straddle** | straddle_index >= 0 && action_on < straddle_index | 스트래들이 마지막 액션 (BB 다음) |
| **Dead button** | button_dead == true | 액션 순서: SB → UTG → (button 스킵) |
| **Multiple all-ins** | 3+ players all-in with stack[i] ≠ stack[j] | side pot 다중 생성 (예: 3개 pot) |
| **0원 베팅 시도** | amount == 0 | REJECTED, 재입력 요청 |

### 3.6 매트릭스 4: Ante 7종 × Blind 4종 (BS-06-03 Matrix 1)

#### Ante 7 Type 정의

| Ante Type | 납부자 | 금액 | Dead/Live | 액션 순서 변경 |
|:---------:|-------|------|:---------:|--------------|
| **0** (std_ante) | 모든 활성 플레이어 | `ante_amount` (동일) | Dead | 일반 (UTG first) |
| **1** (button_ante) | 딜러 1명 | `ante_amount × num_seats` | Dead | 일반 |
| **2** (bb_ante) | BB 1명 (전원분 대납) | `ante_amount × num_seats` | Dead | 일반 (UTG first) |
| **3** (bb_ante_bb1st) | BB 1명 (전원분 대납) | `ante_amount × num_seats` | Dead | **BB 먼저 행동 (Option)** |
| **4** (live_ante) | 모든 활성 플레이어 | `ante_amount` (동일) | **Live** | 일반 (콜 시 ante 차감) |
| **5** (tb_ante) | SB+BB 2명이 나눔 | `ante_amount × num_seats` | Dead | 일반 |
| **6** (tb_ante_tb1st) | SB+BB 2명이 나눔 | `ante_amount × num_seats` | Dead | **SB/BB 먼저 행동** |

> Type 0~6 × Blind 0~3 = **28 조합**. 핵심 분기는 (a) 납부자, (b) Live/Dead, (c) 액션 순서 3 차원.

#### Blind 구조 4 종

| num_blinds | 형태 | 포스팅 | first_to_act |
|:----------:|------|--------|--------------|
| **0** | No Blind (Ante Only) | Ante 만 | 딜러 좌측 첫 활성 |
| **1** | BB only | BB 납부 | UTG (BB 다음) |
| **2** | SB + BB (표준) | SB → BB | UTG (3+) / SB(Dealer) heads-up PRE_FLOP / BB heads-up POST_FLOP |
| **3** | SB + BB + Third Blind | SB → BB → Third (보통 UTG+1, 2×BB) | first_to_act 결정 (biggest_bet = max(BB, Third)) |

### 3.7 매트릭스 5: 팟 초기값 계산 공식 (BS-06-03 Matrix 2)

| 요소 | 계산식 |
|------|-------|
| **SB 기여** | small_blind (if num_blinds ≥ 2) |
| **BB 기여** | big_blind (if num_blinds ≥ 1) |
| **Third 기여** | third_blind (if num_blinds == 3) |
| **Ante 기여** | ante_amount × count (ante_type 별) |
| **Straddle 기여** | straddle_amount (if straddle active) |
| **총 팟** | SB + BB + Third + Ante + Straddle |

**예시 1** (6인 NL Hold'em, BB Ante):
```
SB = 500, BB = 1000, ante_type = 2 (BB Ante), ante_amount = 1000, num_seats = 6
pot_initial = 500 + 1000 + (1000 × 6) = 8500
```

**예시 2** (6인 NL Hold'em, Straddle):
```
SB = 500, BB = 1000, Straddle = 2000 (UTG)
pot_initial = 500 + 1000 + 2000 = 3500
biggest_bet_amt = 2000 (Straddle 기준)
```

### 3.8 Straddle 경우의 수 (BS-06-03 §Straddle)

| straddle_enabled | Position | Stack | 결과 |
|:--------:|:--------:|:--------:|----------|
| ❌ | UTG | ≥ 2BB | Straddle 옵션 없음, 표준 PRE_FLOP |
| ✅ | UTG | ≥ 2BB | Straddle 선택 가능 |
| ✅ | UTG | < 2BB | 스택 부족, 옵션 회색 처리 |
| ✅ | Button | ≥ 2BB | Button Straddle 선택 가능 |
| ✅ | (Middle) | ≥ 2BB | 중간 위치는 Straddle 불가 |

**Re-Straddle**: `re_straddle_enabled = true` 시 다음 플레이어가 추가 Straddle (4× BB) 선택 가능. 마지막 Straddle 플레이어가 최종 Option 취득.

> Straddle 과 Bomb Pot 은 동시 활성화 불가 (PRE_FLOP 진행 방식 충돌).

### 3.9 Heads-up 특수 규칙 (BS-06-03 §Heads-up)

| 구분 | 일반 테이블 (3명+) | Heads-up (2인) |
|------|:----:|:----:|
| **Dealer 위치** | BTN | SB (Dealer = SB) |
| **SB 납부자** | Dealer 왼쪽 | Dealer 자신 |
| **BB 납부자** | SB 왼쪽 | 상대방 |
| **PRE_FLOP first to act** | UTG | **SB(Dealer)** |
| **POST_FLOP first to act** | SB | **BB(상대)** |

**딜링 순서 (Rule 87 보충)**: WSOP Rule 87 "마지막 카드는 버튼으로 처리됩니다":
1. 첫 hole card: BB(상대방) 에게 먼저
2. 두 번째 hole card: BB → SB(Dealer)
3. 결과적으로 마지막 카드가 Dealer 에게 도달

> Engine 구현: 논리적 딜링 순서는 `DealHoleCards` 이벤트의 `cards` 맵 순서로 표현. 물리적 RFID 스캔 순서는 Team 4 CC hardware layer 담당.

### 3.10 사이드팟 매트릭스 (BS-06-06)

#### 3.10.1 Matrix 1: 2인 올인 (Simple)

| 플레이어 | 투입액 | 메인팟 | 사이드팟1 | Eligible Set |
|:--------:|:-----:|:-----:|:--------:|:----------:|
| A | $100 | $100 | — | {A, B} |
| B | $200 | $100 | $100 | {B} |
| **합계** | $300 | $200 | $100 | — |

**판정 순서**: 사이드팟1 ({B}) → 메인팟 ({A,B})

#### 3.10.2 Matrix 2: 3인 올인 (Cascade)

| 플레이어 | 투입액 | 메인팟 | 사이드팟1 | 사이드팟2 | Eligible Set |
|:--------:|:-----:|:-----:|:--------:|:--------:|:----------:|
| A | $50 | $50 | — | — | {A,B,C} |
| B | $150 | $100 | $100 | — | {A,B,C} {B,C} |
| C | $300 | $150 | $200 | $150 | {A,B,C} {B,C} {C} |
| **합계** | $500 | $300 | $300 | $150 | — |

**판정 순서**: 사이드팟2 ({C}) → 사이드팟1 ({B,C}) → 메인팟 ({A,B,C})

#### 3.10.3 Matrix 3: 4인 (2 all-in, 2 계속 베팅)

| 플레이어 | 투입액 | 메인팟 | 사이드팟1 | 사이드팟2 | Eligible Set |
|:--------:|:-----:|:-----:|:--------:|:--------:|:----------:|
| A | $100 | $100 | — | — | {A,B,C,D} |
| B | $100 | $100 | — | — | {A,B,C,D} |
| C | $200 | $100 | $100 | — | {A,B,C,D} {C,D} |
| D | $350 | $100 | $100 | $150 | {A,B,C,D} {C,D} {D} |
| **합계** | $750 | $400 | $200 | $150 | — |

**판정 순서**: 사이드팟2 ({D}) → 사이드팟1 ({C,D}) → 메인팟 ({A,B,C,D})

#### 3.10.4 Matrix 4: Fold 플레이어 데드 머니

| 플레이어 | 상태 | 투입액 | 메인팟 배분 | 사이드팟1 배분 | 비고 |
|:--------:|:-----:|:-----:|:--------:|:--------:|------|
| A | Fold | $100 | $100 (데드) | — | 팟 반환 불가, 메인팟에 포함 |
| B | All-in | $200 | $100 | $100 | 메인팟과 사이드팟 eligible |
| C | 계속 | $300 | $100 | $200 | 사이드팟1 eligible |
| **합계** | — | $600 | $300 | $300 | A 데드 머니는 메인팟 우승자가 취함 |

### 3.11 Showdown 카드 공개 매트릭스 (BS-06-07)

#### 3.11.1 Matrix 1: 카드 공개 조합 (card_reveal × show × fold_hide = 48 조합)

| card_reveal_type | show_type | fold_hide_type | 설명 | Canvas | 유효성 |
|:--------:|:--------:|:--------:|------|--------|:------:|
| 0 (immediate) | 0 (immediate) | 0 (immediate) | 모든 카드 즉시 공개, 폴드 카드 즉시 숨김 | Broadcast | ✅ |
| 0 (immediate) | 0 (immediate) | 1 (delayed) | 모든 카드 즉시, 폴드 카드 액션 완료 후 숨김 | Broadcast | ✅ |
| 0 (immediate) | 1 (action_on) | 0 | action_on 카드 강조, 다른 카드 보조, 폴드 즉시 숨김 | Broadcast | ✅ |
| 0 (immediate) | 1 (action_on) | 1 | action_on 카드 강조, 폴드 지연 숨김 | Broadcast | ✅ |
| 0 (immediate) | 2 (after_bet) | 0 | 베팅 후 카드 공개, 폴드 즉시 숨김 | Broadcast | ✅ |
| 0 (immediate) | 2 (after_bet) | 1 | 베팅 후 카드 공개, 폴드 지연 숨김 | Broadcast | ✅ |
| 0 (immediate) | 3 (action_on_next) | 0 | 부드러운 전환, 폴드 즉시 숨김 | Broadcast | ✅ |
| 0 (immediate) | 3 (action_on_next) | 1 | 부드러운 전환, 폴드 지연 숨김 | Broadcast | ✅ |
| 1 (after_action) | 0~3 | 0~1 | (PRE_FLOP 용, SHOWDOWN 미사용) | — | ❌ |
| 2 (end_of_hand) | 0~3 | 0~1 | 핸드 완료 후 카드 공개 (가장 보수적) | Venue | ✅ |
| 3 (never) | 0~3 | 0~1 | 절대 공개 안 함 (히든 게임) | Venue | ✅ |
| 4 (showdown_cash) | 0~3 | 0~1 | SHOWDOWN 시만 공개 (캐시 게임) | Broadcast | ✅ |
| 5 (showdown_tourney) | 0~3 | 0~1 | SHOWDOWN 시만 공개 (토너먼트, Muck 적용) | Venue | ✅ |
| **48 조합** | — | — | 전체 | — | **~32 유효** |

#### 3.11.2 Matrix 2: Canvas 별 홀카드 가시성

| Canvas | card_reveal_type | 시청자 관점 | 신뢰성 | 시각성 |
|--------|:--------:|---------|:-----:|:-----:|
| **Broadcast** | 0~4 (except 2, 3) | 홀카드 **표시됨** | 낮음 (카드 노출, 스포일) | 높음 (흥미로움) |
| **Venue** | 2, 3, 5 (또는 0 ALL_IN_RUNOUT) | 홀카드 **미표시** (showdown_tourney 는 Muck 적용) | 높음 (공정성) | 낮음 (실시간 판정만) |

#### 3.11.3 Matrix 3: Muck 규칙 적용

| 상황 | Canvas | Muck 권리 | 카드 공개 | 설명 |
|------|--------|:------:|---------|------|
| **SHOWDOWN (자발 폴드 없음)** | Broadcast | ✅ YES | Optional (플레이어 선택) | 패배자 카드 비공개 가능 |
| **SHOWDOWN (자발 폴드 없음)** | Venue | ✅ YES | Optional (Muck 기본) | 모든 패배자는 default Muck |
| **ALL_IN_RUNOUT** | Broadcast | ❌ NO | Forced | 모든 액티브 강제 공개 |
| **ALL_IN_RUNOUT** | Venue | ❌ NO | Forced | 투명성 위해 강제 공개 |
| **강제 공개 요청** | Both | ❌ NO | Forced | 운영자가 "Show" 지시 |

#### 3.11.4 Matrix 4: WRONG_CARD 처리

| Canvas | RFID 감지 카드 | 예상 카드 | 시스템 반응 | Broadcast | Venue |
|--------|:--------:|:-------:|---------|---------|------|
| **Broadcast** | 7♠ | A♠ | Mismatch 경고 | 경고 표시, 이전 상태 유지 | — |
| **Venue** | 7♠ | A♠ | Mismatch 경고 | — | 에러 표시, 이전 상태 유지 |
| **Both** | 7♠ | A♠ | 사용자 확인 필요 | 수동 입력 또는 UNDO | UNDO 권장 |

### 3.12 Run It Twice 매트릭스 (BS-06-07 §Run It Twice)

| can_run_it_twice | game_state | num_allin | board_cards | run_it_times | 결과 |
|:--------:|:--------:|:--------:|:--------:|:--------:|----------|
| ❌ | SHOWDOWN | 2+ | < 5 | — | Run It Twice 옵션 없음 |
| ✅ | SHOWDOWN | 2+ | 0~4 | 2 | 2회 전개 |
| ✅ | SHOWDOWN | 2+ | 3 | 2 | TURN+RIVER 2회 |
| ✅ | SHOWDOWN | 2+ | 4 | 2 | RIVER 2회 |
| ✅ | SHOWDOWN | 2 | 5 | — | 보드 완성, Run It Twice 불가 |
| ✅ | SHOWDOWN | 1 | < 5 | — | 1인만 남음, Run It Twice 불필요 |

### 3.13 Missed Blind 복귀 옵션 (BS-06-03 Rule 86)

| missed_sb | missed_bb | 복귀 옵션 | 설명 |
|:---------:|:---------:|----------|------|
| false | false | 즉시 복귀 | 포스팅 의무 없음 |
| true  | false | 다음 SB 포지션까지 대기 또는 즉시 SB+BB 포스트 | SB 는 dead, BB 는 live bet |
| false | true  | 다음 BB 포지션까지 대기 또는 즉시 BB 포스트 | BB 는 live bet |
| true  | true  | SB+BB 동시 포스트 (SB dead, BB live) 또는 다음 BB 까지 대기 | 양쪽 포스팅 의무 |

### 3.14 Raise Cap 판정 표 (BS-06-02 §5.2 Rule 100.b)

| 게임 형식 | 핸드 내 2명 | 핸드 내 3명+ | 전체 토너먼트 2명 |
|-----------|:----------:|:-----------:|:---------------:|
| NL (No-Limit) | 무제한 | 무제한 | 무제한 |
| PL (Pot-Limit) | 무제한 | 무제한 | 무제한 |
| FL (Fixed-Limit) | **cap 적용** (1 bet + 4 raises) | cap 적용 | **cap 무제한** |
| Spread Limit | cap 적용 | cap 적용 | cap 무제한 |

> 엔진은 `state.tournament_heads_up: bool` 필드 참조. 캐시 heads-up 은 `tournament_heads_up = false` 고정 (Rule 100.b 불적용). House 옵션 `cash_heads_up_uncapped: bool` 검토.

### 3.15 검증 규칙 — REJECT 시 이유 메시지 (BS-06-02 §검증 규칙)

| 검증 항목 | 조건 | 에러 메시지 |
|:-------:|------|----------|
| **활성 상태** | player.status ≠ active | "이미 폴드한 플레이어입니다" |
| **액션 턴** | action_on ≠ player_index | "해당 플레이어의 차례가 아닙니다" |
| **CHECK 유효** | biggest_bet_amt ≠ player.current_bet | "베팅이 있으므로 체크할 수 없습니다" |
| **BET 유효** | biggest_bet_amt > 0 | "이미 베팅이 있습니다. CALL 또는 RAISE 선택" |
| **금액 범위 (NL)** | amount < big_blind | "최소 베팅액은 {big_blind} 칩입니다" |
| **금액 범위 (NL)** | amount > stack | "최대 베팅액은 {stack} 칩입니다" |
| **금액 범위 (PL)** | amount > max_amount | "최대 베팅액은 {max_amount} 칩입니다" |
| **최소 레이즈** | amount < min_raise | "최소 레이즈액은 {min_raise} 칩입니다" |
| **FL cap** | num_raises >= 4 && players > 2 | "이 스트리트 레이즈 상한 (4회) 도달" |
| **0원 베팅** | amount == 0 | "0칩은 베팅할 수 없습니다" |
| **게임 상태** | hand_in_progress == false | "게임이 진행 중이 아닙니다" |
| **모든 올인** | allin_count == active_count | "모두 올인 상태. 보드 자동 딜 진행 중..." |

### 3.16 비활성 조건 — 베팅 액션 불가 (BS-06-02 §비활성)

| 조건 | 이유 | 처리 |
|:---:|------|------|
| `hand_in_progress == false` | 핸드 종료 | REJECTED |
| GamePhase ∈ {IDLE, HAND_COMPLETE, SHOWDOWN} | 베팅 시간 아님 | REJECTED |
| `action_on == -1` 또는 `>= num_players` | 유효 액션 턴 없음 | REJECTED |
| `player.status == folded` | 이미 포기 | REJECTED |
| `player.status == allin` | 이미 올인 | REJECTED |
| `player.status == busted` | 게임 탈락 | REJECTED |
| `num_active_players < 2` | 1명 이하면 게임 종료 | REJECTED |
| `betting_round_complete == true` | 라운드 종료 | REJECTED |
| CC 모달 활성 (금액 입력 중) | UI 잠금 | 새 입력 대기 |

### 3.17 유저 스토리 — Betting (BS-06-02 §유저 스토리, 20건)

| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| 1 | 운영자 | SB 베팅 상황에서 CHECK 클릭 | 거부, "베팅이 있습니다" 경고 | CHECK 비활성 유지 |
| 2 | 운영자 | NL UTG 가 2× BB 레이즈 | 유효, min_raise_amt 갱신 | 다음은 최소 1×(레이즈 차액) 추가 |
| 3 | 운영자 | PL Omaha pot=100, bet=50, raise 300 | 유효 (300 = 100+50+100) | 301 입력 시 거부 |
| 4 | 운영자 | FL Hold'em PRE_FLOP, bet=2, raise=2 | 유효, 1라운드 레이즈 | 4번째 시도 시 "Cap reached" |
| 5 | 운영자 | FL heads-up (2인) cap 조건 | cap 미적용, 무제한 | 3명+ 일 때 cap 적용 |
| 6 | 운영자 | BB 가 PRE_FLOP raise 없이 체크 | BB check option, 체크 허용 | 누군가 레이즈 시 다시 액션 턴 |
| 7 | 운영자 | 스택 150, raise 200 시도 | 모두 올인 150 칩만 납부 | side pot 분리 |
| 8 | 운영자 | 모든 플레이어 all-in 상태 | 보드 자동 딜, showdown 직행 | 수동 입력 불가 |
| 9 | 운영자 | 전원 (3명) all-in: 100/300/500 | 3개 side pot (100/100/300) | pot 별 승률/수익률 계산 |
| 10 | 운영자 | Bomb Pot 시작, 전원 고정액 | PRE_FLOP 베팅 스킵, DEAL 직행 | 후속 BET 정상 처리 |
| 11 | 운영자 | Live ante 5칩, BB+5 옵션 | "With ante" 시 first_bet = BB+ante | 옵션 선택 |
| 12 | 운영자 | Straddle UTG+1=2× BB | 액션 순서 변경, Straddle 마지막 | check option 활성 |
| 13 | 운영자 | 첫 bet 후 두 번째 액션 | "Raise 최소액 계산" 전환 | Call 옵션 유지 |
| 14 | 운영자 | 3인 다양한 스택, P1 call/P2 all-in 150/P3 raise 300 | pot 재계산: main=450, side=300 | pot 별 분배 |
| 15 | 운영자 | 0원 베팅 시도 | REJECTED, "최소 베팅액 X 칩" | 재입력 |
| 16 | 운영자 | 스택 100, 베팅 150 입력 | 자동 all-in 100 납부 | short call 기록 |
| 17 | 운영자 | NL 최소 레이즈: bet=50, BB=10 | min raise = 50 + max(10, 이전 raise) | 다음 min=100 |
| 18 | 운영자 | 4번째 raise (FL cap=4, 3명+) | REJECTED, "Raise cap reached" | 2인 시 cap 무시 |
| 19 | 운영자 | All-in 후 side pot 영향 액션 | side pot 분리 후 다음 액션 | main → side A → side B |
| 20 | 운영자 | River 전원 all-in 후 showdown | 보드 공개, 패 평가 자동 | 승자 결정 후 분배 |

### 3.18 유저 스토리 — Blinds & Ante (BS-06-03 §유저 스토리, 16건)

| # | As a | When | Then |
|:-:|------|------|------|
| 1 | 운영자 | 10인 NL, NEW HAND, BB=1000, BB Ante=1000 | SB=500, BB=1000, Ante 10×1000=10000 → action_on=UTG |
| 2 | 운영자 | 6인 Button Ante, BB=100 | BTN 만 6×100=600 납부, 다른 변화 없음 |
| 3 | 운영자 | Live Ante=100, BB=1000, 누군가 500 Bet | UTG 콜 = 500-100(Ante 포함)=400 추가 |
| 4 | 운영자 | Heads-up 2인 NEW HAND | Dealer(SB)=500, Opponent(BB)=1000 → SB PRE_FLOP 먼저 |
| 5 | 운영자 | 3명 num_blinds=3 (Third Blind) | SB=50, BB=100, UTG+1=200 → biggest_bet=200 |
| 6 | 운영자 | Dead Button BTN=빈 좌석 | SB 포스팅 스킵 또는 다음 활성으로 이동 |
| 7 | 운영자 | Bomb Pot 새 핸드 | 모든 플레이어 bomb_pot_amount 자동 → PRE_FLOP 스킵 |
| 8 | 운영자 | TB Ante 6인 | SB+BB 가 Ante 6×100=600 합산, 팟+=600 |
| 9 | 운영자 | std Ante 8인, ante=50 | 모든 플레이어 50×8=400 (동일) |
| 10 | 운영자 | 블라인드 변경 (레벨 상승) | 이전 핸드 완료 후 새 SB/BB |
| 11 | 운영자 | 칩 부족 SB 500 필요, 350 보유 | 350 자동 납부 (All-in), Side Pot |
| 12 | 운영자 | Straddle UTG 200(2×BB) 자발 | BB Ante 후 Straddle → action_on=UTG (마지막) |
| 13 | 운영자 | 3인 BB Ante, 1명 Sitout | Sitout 제외, 2명만 Ante |
| 14 | 운영자 | 토너먼트 "Blinds Up" | 현 핸드 완료 후 다음부터 새 BB/SB |
| 15 | 운영자 | Blind Posting 실패 (네트워크) | UNDO 로 복귀, 재시도 |
| 16 | 시스템 | 강제 베팅 수거 완료 | 팟 확정, hand_in_progress=true, 베팅 라운드 시작 |

### 3.19 유저 스토리 — Side Pot (BS-06-06 §유저 스토리, 12건)

| # | As a | When | Then | Scenario |
|:-:|------|------|------|----------|
| 1 | 운영자 | 2인 올인 (A: $100, B: $200) | 메인팟 $200 (A×2), 사이드팟1 $100 (B×1) | 2인 simple |
| 2 | 운영자 | 3인 올인 (A: $50, B: $150, C: $300) | 메인팟 $150, 사이드팟1 $200 (B,C), 사이드팟2 $150 (C) | 3인 cascade |
| 3 | 운영자 | 2인 올인 (A: $100, B: $100) + C 계속 | 메인팟 $300 + 사이드팟1 (B,C 만) | 메인팟 + 사이드팟 |
| 4 | 운영자 | A FOLD ($50), B all-in $100 | 메인팟 $150 (A 데드, B), 사이드팟 $100 (B only) | Fold 데드 머니 |
| 5 | 운영자 | A=$100, B=$200, C=$300, D=$500 | 메인팟 $400, 사이드팟1 $300, 사이드팟2 $200, 사이드팟3 $200 | 4인 cascade |
| 6 | 게임 엔진 | 사이드팟 판정 (역순) | 가장 작은 eligible set 부터 | 역순 처리 |
| 7 | 게임 엔진 | 사이드팟3 = D (D only) | D 가 사이드팟3 전체 수령 | 역순 판정 이점 |
| 8 | 게임 엔진 | 메인팟 (4인 모두 eligible) | 최고 HandRank, Tie 시 split | 메인팟 최종 |
| 9 | 운영자 | 3인 올인, 일부 Fold (PRE_FLOP) | Fold 데드 머니 각 팟 계산 | Fold 후 올인 |
| 10 | 게임 엔진 | Run It Twice (2회차) | 각 런별 팟 동일, 2회차 재판정 | RIT 팟 반복 |
| 11 | 운영자 | Bomb Pot + 일부 short contribution | 전원 시도, 부족자 short | Bomb Pot 사이드팟 |
| 12 | 게임 엔진 | Odd chip 분배 | dealer-left 가까운 eligible 에게 | Split pot odd chip |

### 3.20 유저 스토리 — Showdown (BS-06-07 §유저 스토리, 12건)

| # | As a | When | Then | Canvas | Reveal Type |
|:-:|------|------|------|--------|-----------|
| 1 | Broadcast 시청자 | SHOWDOWN 진입 | 모든 활동 플레이어 홀카드 즉시 표시 (Last aggressor first) | Broadcast | immediate (0) |
| 2 | Venue 관중 | SHOWDOWN 진입 | 홀카드 미표시, 보드/평가 결과만 | Venue | immediate (0) |
| 3 | Broadcast 시청자 | 패배자 Muck 권리 | 패배자 카드 그레이아웃 또는 뒷면 | Broadcast | showdown_cash (4) |
| 4 | Venue 관중 | ALL_IN_RUNOUT (강제) | 패배자도 카드 공개 (Muck 없음) | Venue | immediate (0) |
| 5 | Broadcast 시청자 | 액션 플레이어 변경 | action_on 강조, 다른 카드 흐릿 | Broadcast | action_on (1) |
| 6 | Broadcast 시청자 | 베팅 후 카드 공개 | 베팅 직후 공개 (액션 강조) | Broadcast | after_bet (2) |
| 7 | Broadcast 시청자 | 첫 카드 후 다음 액션 | 부드러운 전환 | Broadcast | action_on_next (3) |
| 8 | Venue 관중 | SHOWDOWN 카드 게시 | 우승자만 공개, 패배자 비공개 | Venue | showdown_tourney (5) |
| 9 | Broadcast 시청자 | 패배자 카드 숨김 | 액션 완료 후 일괄 숨김 | Broadcast | delayed (1, fold_hide) |
| 10 | Broadcast 시청자 | Odd chip 분배 | 홀카드 공개 후 odd chip 수령자 강조 | Broadcast | showdown_cash (4) |
| 11 | Broadcast 시청자 | Run It Twice 1회차 | 1회차 결과 후 카드 유지, 2회차 전개 | Broadcast | immediate (0) |
| 12 | Venue 관중 | 카드 불일치 (WRONG_CARD) | 오류 표시, 이전 상태 유지 | Venue | immediate (0) |

---

<!-- CHUNK-3: §4 Exceptions + §5 Data Models + Appendix A/B -->
