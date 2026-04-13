# BS-06-06: Hold'em 사이드 팟

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-06 | 신규 작성 | N-player all-in 사이드팟 분리, 계산, 판정 순서 정의 |
| 2026-04-07 | 구조 → 번호 변경 | BS-06-07 → BS-06-08로 재배치 |
| 2026-04-06 | 구조 → 제목 변경 | Hold'em 전용으로 변환, BS-06-06으로 재배치 |

---

> **이 문서에서 사용하는 용어**
>
> | 용어 | 설명 |
> |------|------|
> | odd chip | 팟을 나눌 때 딱 떨어지지 않는 나머지 1개 베팅 토큰 |
> | scoop | 한 사람이 팟 전체를 가져가는 것 |
> | cascade | 하나의 이벤트가 연쇄적으로 다른 이벤트를 발생시키는 것 |
> | Pseudocode | 실제 프로그래밍 언어가 아닌 참고용 가상 코드 |

## 개요

**사이드팟**은 플레이어들이 서로 다른 금액으로 올인할 때 발생하는 팟 분리 메커니즘이다. 예를 들어, Player A가 $100 올인, Player B가 $200 올인, Player C가 $500 올인하면, 3개의 팟(메인팟 $300, 사이드팟1 $300, 사이드팟2 $600)이 생기고, 각 팟의 **eligible set(해당 팟에서 이길 자격이 있는 플레이어 목록)**이 다르다. 이 문서는 사이드팟 생성, eligible set 결정, 역순 판정 순서를 정의하여, 개발팀이 **복잡한 올인 상황을 정확히 처리**할 수 있도록 한다.

---

## 정의

**사이드팟**은 플레이어의 투입액 차이로 인해 자동으로 생성되는 **팟 분리 구조**이다.

- **메인팟**: 모든 플레이어가 참여 가능한 최소 투입액 기반 팟
- **사이드팟**: 추가 투입액 기반의 팟 (메인팟 이후)
- **eligible set**: 해당 팟에 우승할 자격이 있는 플레이어 목록

**핵심 원칙**:
- 모든 플레이어가 기여한 금액만큼만 팟에 참여 가능
- 팟 분배 순서는 **역순** (가장 작은 eligible set의 팟부터)
- Fold 플레이어의 데드 머니(이미 폴드한 플레이어가 넣어둔, 돌려받을 수 없는 금액)는 각 팟에 비례 분배

---

## 트리거

### 트리거 소스

| 소스 | 발동 주체 | 처리 시간 | 신뢰도 | 예시 |
|------|---------|---------|--------|------|
| **ALL_IN 액션** | 운영자 또는 게임 엔진 (자동) | <50ms | 높음 | 플레이어A $100 all-in, 플레이어B $250 all-in |
| **베팅 완료 후 보드 전개** | 게임 엔진 (자동) | 결정론적 | 최고 | 모든 액티브 all-in → 사이드팟 final, 역순 판정 시작 |
| **Fold 플레이어** | 운영자 (수동) | <50ms | 높음 | 플레이어C FOLD → 데드 머니 각 팟에 포함 |

---

## 전제조건

### 사이드팟 생성 전제조건

| 필드 | 조건 | 설명 |
|------|------|------|
| **game_state** | ANY (PRE_FLOP부터 RIVER까지) | 어떤 라운드에서든 all-in 발생 가능 |
| **num_remaining_players** | 2+ | 최소 2명 이상 |
| **all_in_amounts[seat]** | > 0 | 해당 플레이어가 all-in (스택 = 0) |
| **differs from others** | 서로 다름 | 최소 2명의 all-in 금액이 다름 |

### 역순 판정 전제조건

| 필드 | 조건 | 설명 |
|------|------|------|
| **board_cards.length** | game_class별 최대 | 보드 카드 완성됨 (Flop: 5장) |
| **showdown** | 진행 중 | 모든 팟 eligible set의 플레이어가 남음 |

---

## 유저 스토리

| # | As a | When | Then | Scenario |
|:-:|------|------|------|----------|
| 1 | 운영자 | 2인 올인 (A: $100, B: $200) | 메인팟 $200 (A×2), 사이드팟1 $100 (B×1) | 2인 simple |
| 2 | 운영자 | 3인 올인 (A: $50, B: $150, C: $300) | 메인팟 $150 (A,B,C×50), 사이드팟1 $200 (B,C×100), 사이드팟2 $150 (C×150) | 3인 cascade |
| 3 | 운영자 | 2인 올인 (A: $100, B: $100) + C: 계속 베팅 | 메인팟 $300 (A,B,C×100), 사이드팟1 $300+ (B,C만, C 베팅액) | 메인팟만 + 사이드팟 |
| 4 | 운영자 | A FOLD (이미 $50 기여), B: $100 all-in | 메인팟 $150 (A 데드 $50, B $100), 사이드팟 $100 (B only) | Fold 플레이어 데드 머니 |
| 5 | 운영자 | A all-in $100, B all-in $200, C all-in $300, D: $500 베팅 | 메인팟 $400 (A,B,C,D×100), 사이드팟1 $300 (B,C,D×100), 사이드팟2 $200 (C,D×100), 사이드팟3 $200 (D only) | 4인 cascade |
| 6 | 게임 엔진 | 사이드팟 판정 (역순) | 가장 작은 eligible set(D) 팟부터 승자 판정, 다음 팟(C,D) 판정, 다음(B,C,D) 판정, 메인팟(A,B,C,D) | 역순 처리 |
| 7 | 게임 엔진 | 사이드팟1 승자 = D (D only) | D가 사이드팟3 전체 수령, 나머지 팟은 여전히 경쟁 중 | 역순 판정의 이점 |
| 8 | 게임 엔진 | 메인팟 (4인 모두 eligible) | 최고 HandRank 결정, Tie 시 split | 메인팟 최종 판정 |
| 9 | 운영자 | 3인 올인, 일부 Fold (PRE_FLOP) | Fold 플레이어 데드 머니 각 팟에 계산 | Fold 후 올인 처리 |
| 10 | 게임 엔진 | Run It Twice (2회차) | 각 런별로 팟 구성 동일, 2회차 승자 재판정 | Run It Twice 팟 반복 |
| 11 | 운영자 | Bomb Pot + 일부 short contribution | 전원 bomb_pot_amount 수납 시도, 부족자 short contribution | Bomb Pot 사이드팟 |
| 12 | 게임 엔진 | 팟 분배 (Odd chip) | 각 팟별 odd chip를 dealer-left 가장 가까운 eligible 플레이어에게 할당 | Split pot odd chip |

---

## 경우의 수 매트릭스

### 매트릭스 1: 2인 올인 (Simple)

| 플레이어 | 투입액 | 메인팟 | 사이드팟1 | Eligible Set |
|:--------:|:-----:|:-----:|:--------:|:----------:|
| A | $100 | $100 | — | {A, B} |
| B | $200 | $100 | $100 | {B} |
| **합계** | $300 | $200 | $100 | — |

**판정 순서**: 사이드팟1({B}) → 메인팟({A,B})

### 매트릭스 2: 3인 올인 (Cascade)

| 플레이어 | 투입액 | 메인팟 | 사이드팟1 | 사이드팟2 | Eligible Set |
|:--------:|:-----:|:-----:|:--------:|:--------:|:----------:|
| A | $50 | $50 | — | — | {A, B, C} |
| B | $150 | $100 | $100 | — | {A, B, C} {B, C} |
| C | $300 | $150 | $200 | $150 | {A, B, C} {B, C} {C} |
| **합계** | $500 | $300 | $300 | $150 | — |

**판정 순서**: 사이드팟2({C}) → 사이드팟1({B,C}) → 메인팟({A,B,C})

### 매트릭스 3: 4인 (2 all-in, 2 계속 베팅)

| 플레이어 | 투입액 | 메인팟 | 사이드팟1 | 사이드팟2 | Eligible Set |
|:--------:|:-----:|:-----:|:--------:|:--------:|:----------:|
| A | $100 | $100 | — | — | {A,B,C,D} |
| B | $100 | $100 | — | — | {A,B,C,D} |
| C | $200 | $100 | $100 | — | {A,B,C,D} {C,D} |
| D | $350 | $100 | $100 | $150 | {A,B,C,D} {C,D} {D} |
| **합계** | $750 | $400 | $200 | $150 | — |

**판정 순서**: 사이드팟2({D}) → 사이드팟1({C,D}) → 메인팟({A,B,C,D})

### 매트릭스 4: Fold 플레이어 데드 머니

| 플레이어 | 상태 | 투입액 | 메인팟 배분 | 사이드팟1 배분 | 비고 |
|:--------:|:-----:|:-----:|:--------:|:--------:|------|
| A | Fold | $100 | $100 (데드) | — | 팟 반환 불가, 메인팟에 포함 |
| B | All-in | $200 | $100 | $100 | 메인팟과 사이드팟 eligible |
| C | 계속 | $300 | $100 | $200 | 사이드팟1 eligible |
| **합계** | — | $600 | $300 | $300 | A 데드 머니는 메인팟 우승자가 취함 |

---

## 비활성 조건

### 사이드팟 생성 미필요

- `num_allin < 2` → 1인만 올인 (나머지는 계속 베팅)
- 모든 올인 플레이어 금액이 동일 → 메인팟만 생성, 사이드팟 미필요
- `num_remaining_players < 2` → 모두 폴드 (1인만 남음)

### 역순 판정 미실행

- `num_allin == 0` → 모두 계속 베팅, 정상 SHOWDOWN
- `board_cards.length < game_class 최대` → 보드 미완성, 아직 판정 시점 아님

---

## 영향 받는 요소

### 1. Side Pot 생성 영향

1. **hand_evaluation.md**: 각 팟의 eligible set만 해당 팟 판정에 참여
2. **showdown_reveal.md**: 팟별로 다른 eligible set 카드 공개
3. **Overlay**: 팟 분리 시각화 (메인팟 vs 사이드팟 표시)
4. **Statistics**: pot_structure 저장 (메인팟 크기, 사이드팟 수)

### 2. Fold 플레이어 데드 머니 영향

1. **chip_collection**: Fold 후 투입액 데드 머니로 처리
2. **hand_evaluation.md**: Fold 플레이어는 평가 대상 제외, 하지만 데드 머니는 팟에 남음
3. **Statistics**: player_stats.money_dead (dead money 누적)

### 3. 역순 판정 영향

1. **hand_evaluation.md**: 가장 작은 eligible set부터 순차 평가
2. **chip_distribution.md**: 각 팟별 우승자 결정 후 분배
3. **Overlay**: 팟별 승자 표시 (역순 진행 표시)

### 4. Run It Twice 영향

1. **hand_evaluation.md**: 각 런별로 동일 팟 구조 유지, 2회 판정 실행
2. **chip_distribution.md**: 각 런 결과 누적 후 최종 분배
3. **Overlay**: "RUN 1", "RUN 2" 표시, 각 런별 팟 결과

---

## 데이터 모델 (Pseudo-code)

> 아래는 개발자 참고용 코드입니다.

### SidePot 구조

```python
class SidePot:
    pot_id: int  # 0=메인팟, 1=사이드팟1, 2=사이드팟2, ...
    amount: float  # 팟 금액
    eligible_seats: set[int]  # 이 팟에 우승할 자격 있는 플레이어 좌석
    winner_seat: int = -1  # 우승자 좌석 (-1=미결정)
    winning_hand: HandRank  # 우승자의 핸드 평가
    
class PotStructure:
    main_pot: SidePot
    side_pots: list[SidePot]  # [사이드팟1, 사이드팟2, ...]
    total_pot: float  # 전체 팟 합계
    
    def get_all_pots() -> list[SidePot]:
        return [self.main_pot] + self.side_pots
```

### HandState 확장

```python
class HandState:
    # ... 기존 필드 ...
    
    # All-in / Side Pot 관련
    all_in_amounts: dict[int, float]  # {seat: amount}
    pot_structure: PotStructure
    side_pot_verdicts: list[dict]  # [{pot_id, winner_seat, amount, hand_rank}]
```

---

## 알고리즘: 사이드팟 생성 (Pseudocode)

```
Input: all_in_amounts {seat: amount}, initial_pot (전체 베팅액)

1. 정렬: all_in_amounts를 오름차순 정렬
   sorted_amounts = [50, 100, 150, 200, ...]
   
2. 팟 생성:
   previous_tier = 0
   all_pots = []
   
   for (amount, num_remaining_players) in sorted_amounts:
       tier_diff = amount - previous_tier
       pot_amount = tier_diff × num_remaining_players
       
       eligible_seats = {seat | seat의 all_in ≥ amount}
       pot = SidePot(pot_amount, eligible_seats)
       all_pots.append(pot)
       
       previous_tier = amount
   
3. Fold 플레이어 데드 머니 분배:
   for fold_seat in fold_seats:
       dead_money = fold_seat의 투입액
       # 각 팟에 비례 분배 (eligible set 기준)
       for pot in all_pots:
           pot.amount += (dead_money × pot.num_eligible / total_eligible)
   
4. 메인팟 / 사이드팟 분류:
   main_pot = all_pots[0]
   side_pots = all_pots[1:]
   
Output: PotStructure(main_pot, side_pots)
```

---

## 알고리즘: 역순 판정 (Pseudocode)

```
Input: PotStructure, hand_evaluations

1. 팟 역순 정렬:
   pots_in_reverse = reverse(main_pot + side_pots)
   
2. 각 팟 판정 (역순):
   for pot in pots_in_reverse:
       eligible_players = pot.eligible_seats
       
       # 해당 팟의 eligible 플레이어만 평가
       best_hand = evaluate_best_hand(eligible_players)
       
       pot.winner = best_hand.seat
       pot.winning_hand = best_hand.rank
       
       # 해당 팟의 칩은 이 우승자에게 할당 (최종 결과에 누적)
   
3. 최종 분배:
   for pot in main_pot + side_pots:
       add_to_winner_stack(pot.winner, pot.amount)

Output: hand_results [{pot_id, winner, amount, hand_rank}]
```

---

## 예시 시나리오

### 시나리오 1: 3인 올인 (Cascade)

```
Players: A, B, C, D
Stack: A=$100, B=$250, C=$400, D=$1000

1. Round 진행: A all-in $100 → B raise $250 → C raise $400 → D all-in $1000

2. All-in amounts: {A: $100, B: $250, C: $400, D: $1000}

3. Pot 구성:
   Tier 0→100: $100 × 4 = $400 (Eligible: A,B,C,D)
   Tier 100→250: $150 × 3 = $450 (Eligible: B,C,D)
   Tier 250→400: $150 × 2 = $300 (Eligible: C,D)
   Tier 400→1000: $600 × 1 = $600 (Eligible: D)
   
4. Pot Structure:
   Main Pot: $400 (Eligible: {A,B,C,D})
   Side Pot 1: $450 (Eligible: {B,C,D})
   Side Pot 2: $300 (Eligible: {C,D})
   Side Pot 3: $600 (Eligible: {D})
   Total: $1,750

5. 역순 판정:
   Pot 3 ({D}): D only → D wins $600
   Pot 2 ({C,D}): C vs D → Best hand wins
   Pot 1 ({B,C,D}): B vs C vs D → Best hand wins
   Main ({A,B,C,D}): A vs B vs C vs D → Best hand wins

6. 최종 결과:
   D: $600 (Pot 3) + Pot 2 share + Pot 1 share + Main share
   C: Pot 2 share + Pot 1 share + Main share
   (etc.)
```

### 시나리오 2: Fold + All-in

```
Players: A, B, C
Initial Pot: $300 (A=$100, B=$100, C=$100)

1. B raises $200 (total $300)
   C calls $200 (total $300)
   A folds (dead $100)

2. All-in amounts after: {B: $300, C: $300 + betting}
   A's dead money: $100

3. Pot 구성:
   Main Pot: $600 (B $300 + C $300) + A dead $100 = $700
   (No side pots, both invested same amount to this point)
   
4. 역순 판정:
   Main Pot ({B,C}): B vs C → Best hand wins
   A's dead $100 included in Main Pot winner's take

5. 최종:
   Winner (B or C): $700
```
