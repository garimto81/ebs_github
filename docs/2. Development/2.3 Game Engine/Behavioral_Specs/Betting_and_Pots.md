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

<!-- CHUNK-2: §3 Trigger & Action Matrix (Ante/Blind 28 조합 + 6 액션 NL/PL/FL × 특수 + Side Pot 매트릭스 + Showdown 48 조합) -->

<!-- CHUNK-3: §4 Exceptions + §5 Data Models + Appendix A/B -->
