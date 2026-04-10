# BS-06-05: Hold'em 핸드 평가

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-06 | 신규 작성 | 5가지 evaluator type 핸드 평가 로직, 랭킹 비교, tiebreaker 규칙 |
| 2026-04-07 | 구조 → 번호 변경 | BS-06-06 → BS-06-07로 재배치 |
| 2026-04-06 | 구조 → Hold'em 전용 | Hold'em 전용으로 변환, standard_high만 유지, 7-2 Side Bet 흡수, BS-06-05로 재배치 |

---

> **이 문서에서 사용하는 용어**
>
> | 용어 | 설명 |
> |------|------|
> | 홀카드(hole card) | 각 플레이어에게 비공개로 나눠주는 카드 |
> | 커뮤니티 카드 | 테이블 중앙에 공개하는 공용 카드 |
> | kicker | 같은 족보일 때 승부를 가르는 나머지 카드 |
> | Muck | 패를 공개하지 않고 버리는 것 |
> | odd chip | 팟을 나눌 때 딱 떨어지지 않는 나머지 1개 베팅 토큰 |
> | offsuit | 두 카드의 무늬가 서로 다른 경우 |
> | suited | 두 카드의 무늬가 같은 경우 |
> | evaluator | 카드 조합을 분석하여 승자를 결정하는 함수 |
> | Pseudocode | 실제 프로그래밍 언어가 아닌 참고용 가상 코드 |

## 개요

Hold'em 게임 엔진은 **standard_high evaluator**를 사용하여 플레이어의 핸드를 평가한다. 2장의 홀카드(각 플레이어에게 비공개로 나눠주는 카드)와 5장의 커뮤니티 카드(테이블 중앙에 공개하는 공용 카드, 총 7장)에서 최고의 5장 조합을 찾아 승자를 결정한다. 이 문서는 standard_high evaluator의 핸드 랭킹, tiebreaker 규칙, 7-2 Side Bet 사이드 판정을 정의하여, 개발팀이 **정확한 핸드 평가 규칙을 구현**할 수 있도록 한다.

---

## 정의

**핸드 평가**는 플레이어의 홀카드 2장과 커뮤니티 카드 5장에서 최고의 5장 조합을 찾아, 다른 플레이어와 비교하여 **우승자를 결정하는 프로세스**이다.

- **evaluator_type**: **standard_high** (Hold'em 전용)
- **HandRank**: 핸드 순위 (0~8, HighCard~StraightFlush)
- **Tiebreaker**: 동일 순위 시 kicker 비교 규칙

---

## 트리거

### 트리거 소스

| 소스 | 발동 주체 | 처리 시간 | 신뢰도 | 예시 |
|------|---------|---------|--------|------|
| **SHOWDOWN 진입** | 게임 엔진 (자동) | 결정론적 | 최고 | 최종 베팅 완료 → 2+ 플레이어 → 핸드 평가 |
| **Run It Twice 각 런** | 게임 엔진 (자동) | 결정론적 | 최고 | 각 런별 보드 완성 → 승자 재판정 |
| **All-in Runout** | 게임 엔진 (자동) | 결정론적 | 최고 | 모든 액티브 올인 → 보드 자동 완성 → 핸드 평가 |

---

## 전제조건

### 핸드 평가 실행 전제조건

| 필드 | 조건 | 설명 |
|------|------|------|
| **game_state** | SHOWDOWN 또는 ALL_IN_RUNOUT | 최종 베팅 완료 또는 올인 상황 |
| **num_remaining_players** | 2+ | 최소 2명 이상 플레이어 남음 |
| **board_cards** | 5장 | 커뮤니티 카드 5장 완성됨 |
| **hole_cards[seat]** | 모든 액티브 플레이어 | 모든 활동 중인 플레이어가 홀카드 2장 보유 |
| **evaluator_type** | standard_high | Hold'em 표준 평가 방식 |

---

## 유저 스토리

| # | As a | When | Then |
|:-:|------|------|------|
| 1 | 게임 엔진 | RIVER 베팅 완료, 2+ 플레이어 남음 | standard_high evaluator로 각 플레이어 핸드 평가, 최고 HandRank 승자 결정 |
| 2 | 게임 엔진 | 동일 HandRank 발생 (둘 다 Pair) | Pair 등급 비교 → kicker 순차 비교 → 동일 시 팟 split |
| 3 | 게임 엔진 | Odd chip 발생 (팟 split) | Odd chip를 dealer-left 가장 가까운 플레이어에게 할당 |
| 4 | 게임 엔진 | Run It Twice 1회차 완료, 2회차 진행 | 각 런별 보드 다름, 독립적으로 핸드 평가 후 합산 |
| 5 | 게임 엔진 | SHOWDOWN에서 3명 이상, 일부 올인 미발생 | 모든 액티브 플레이어 동시에 핸드 평가 후 팟 분배 |
| 6 | 게임 엔진 | 패배자 카드 Muck (공개 거부) | 승자 카드만 기반 팟 분배 (패배자 카드 평가 불필요) |
| 7 | 게임 엔진 | 7-2 Side Bet 활성, 승자가 7-2 offsuit 보유 | 메인팟 외 사이드벳 추가 수령 (상대 수 x side_bet_amount) |
| 8 | 게임 엔진 | 7-2 Side Bet 활성, 승자가 7-2 suited 보유 | 사이드벳 미수령 (offsuit만 해당) |

---

## 경우의 수 매트릭스

### 매트릭스 1: HandRank 표준 (standard_high)

| Rank | 이름 | 조건 | 예시 | 확률 |
|:--:|------|------|------|:----:|
| 0 | HighCard | 쌍 없음, 플러시 없음, 스트레이트 없음 | A♠K♥Q♦J♣9♠ | ~50% |
| 1 | Pair | 같은 랭크 2장 | K♠K♥Q♦J♣9♠ | ~42% |
| 2 | TwoPair | 서로 다른 쌍 2개 | K♠K♥Q♦Q♣9♠ | ~5% |
| 3 | Trips | 같은 랭크 3장 | K♠K♥K♦Q♣J♠ | ~2% |
| 4 | Straight | 연속 랭크 5장 | K♠Q♥J♦10♣9♠ | ~0.4% |
| 5 | Flush | 같은 수트 5장 | K♠Q♠J♠9♠7♠ | ~0.2% |
| 6 | FullHouse | Trips + Pair | K♠K♥K♦Q♣Q♠ | ~0.14% |
| 7 | FourOfAKind | 같은 랭크 4장 | K♠K♥K♦K♣Q♠ | ~0.024% |
| 8 | StraightFlush | Straight + Flush | K♠Q♠J♠10♠9♠ | ~0.0015% |

### 매트릭스 2: Tiebreaker (동일 HandRank)

| HandRank | Tiebreaker 순서 | 예시 | 결과 |
|:--------:|-----------|------|------|
| **Pair** | Pair rank > Kicker 1 > 2 > 3 | K♠K♥A♦Q♣J♠ vs K♥K♦A♠K♣10♠ | 두 번째가 승리 (K♣ kicker 추가) |
| **TwoPair** | High Pair > Low Pair > Kicker | A♠A♥K♦K♣Q♠ vs A♦A♣K♠K♥J♠ | 첫 번째 승리 (Q kicker) |
| **Trips** | Trips rank > Kicker 1 > 2 | K♠K♥K♦A♣Q♠ vs K♣K♦K♠K♥J♠ | 두 번째 불가능 (4 cards 이상) |
| **Straight** | Highest card in straight | K♠Q♥J♦10♣9♠ vs Q♦J♣10♠9♥8♠ | 첫 번째 승리 (K high) |
| **Flush** | Highest card > 2nd > 3rd > 4th > 5th | A♠K♠Q♠J♠9♠ vs A♥K♥Q♥10♥8♥ | 첫 번째 승리 (Q > 10 비교) |
| **FullHouse** | Trips rank > Pair rank | K♠K♥K♦Q♣Q♠ vs K♣K♦K♠J♥J♠ | 첫 번째 승리 (Q > J pair) |
| **FourOfAKind** | Quads rank > Kicker | A♠A♥A♦A♣K♠ vs A♠A♥A♦A♣Q♠ | 첫 번째 승리 (K kicker) |
| **StraightFlush** | Highest card in straight | K♠Q♠J♠10♠9♠ vs Q♦J♦10♦9♦8♦ | 첫 번째 승리 (K high) |

### 매트릭스 3: Odd Chip 분배

| 팟 금액 | Num Players (Split) | Odd Chip | Recipient | 최종 분배 |
|:--------:|:-------:|:--------:|----------|---------|
| $101 | 2 (50/50 split) | $1 | Player next to dealer-left | $50 + $51 |
| $103 | 3 (33/33 split) | $1 | Player 1 seat to left of dealer | $34 + $34 + $35 |
| $100 | 2 (50/50 split) | $0 | — | $50 + $50 |

---

## 비활성 조건

### 핸드 평가 비활성 조건

- **SHOWDOWN 도달 미달**: 모든 플레이어 폴드 → 1인 남음 → 핸드 평가 불필요
- **All players all-in 미발생**: 베팅 계속 진행 중 → 핸드 평가 시점 아님
- **board_cards 미완성 (올인 미발생)**: 커뮤니티 카드 5장 미완성 → 평가 시점 아님

---

## 영향 받는 요소

### 1. Hand Evaluation 영향

1. **showdown_reveal.md**: 카드 공개 순서 (evaluator 결과 기반 승자 강조)
2. **side_pot_algebra.md**: 각 사이드팟별 핸드 평가 (eligible set별 재평가)
3. **Overlay**: 승자 강조(winning hand highlight), Equity 업데이트
4. **Statistics**: player_stats.hand_types_won, evaluator별 통계

### 2. Tiebreaker 영향

1. **side_pot_algebra.md**: 동일 HandRank 팟 split
2. **chip_collection**: Odd chip 분배 (dealer-left 지정)
3. **Overlay**: "POT SPLIT" 표시, Odd chip 수령자 강조

### 3. 7-2 Side Bet 영향

1. **hand_evaluation.md**: 승자 핸드 분석 (홀카드 7-2 offsuit 감지)
2. **chip_collection**: side_bet 자동 수납 및 분배
3. **Overlay**: "7-2 BONUS!" 표시 (7-2 offsuit 승리 시)
4. **Statistics**: `player_stats.seven_deuce_wins`, `total_seven_deuce_bonuses`

---

## 데이터 모델 (Pseudo-code)

> 아래는 개발자 참고용 코드입니다.

### HandEvaluator 인터페이스

```python
class HandEvaluator:
    evaluator_type: str = "standard_high"
    
    def evaluate(hole_cards: list[Card], community_cards: list[Card]) -> HandRank:
        """홀카드 2장 + 커뮤니티 5장에서 최고 5장 조합의 HandRank 계산"""
        pass
    
    def compare(hand1: HandRank, hand2: HandRank) -> int:
        """hand1 > hand2: 1, hand1 == hand2: 0, hand1 < hand2: -1"""
        pass
    
    def tiebreak(hand1: HandDetail, hand2: HandDetail) -> int:
        """동일 rank 시 kicker 기반 비교"""
        pass

class StandardHighEvaluator(HandEvaluator):
    evaluator_type = "standard_high"
    rankings = [0, 1, 2, 3, 4, 5, 6, 7, 8]  # HighCard ~ StraightFlush
```

### HandRank 구조

```python
class HandRank:
    evaluator_type: str = "standard_high"
    rank: int  # 0-8 (HighCard ~ StraightFlush)
    primary: int  # Pair rank, Trips rank, Straight high, etc
    kicker: list[int]  # [kicker1, kicker2, kicker3, ...]
    cards: list[Card]  # 핸드를 구성하는 5장
    
class HandDetail:
    hand_rank: HandRank
    best: HandRank  # 7장 중 최고 5장 조합
```

---

## 알고리즘: 핸드 평가 순서

```
1. SHOWDOWN 또는 ALL_IN 진입
   └─ standard_high evaluator 적용
   
2. 각 플레이어 핸드 평가
   ├─ 홀카드 2장 + 커뮤니티 5장 (총 7장 중 최고 5장 선택)
   └─ HandRank 계산 (0~8)
   
3. 핸드 비교
   ├─ 모든 플레이어 HandRank 정렬
   ├─ HandRank 동일 → tiebreaker (kicker 순차 비교)
   └─ 최고 HandRank 플레이어 = 우승자
   
4. 팟 분배
   ├─ single winner: 전체 팟 수령
   ├─ split (tie): 팟 분할, odd chip → dealer-left
   └─ multiple rounds (Run It Twice): 각 런별 반복
   
5. 7-2 Side Bet 판정 (활성화 시)
   ├─ 승자 홀카드가 7-2 offsuit인지 확인
   ├─ 해당 시: 각 상대에게서 side_bet_amount 수취
   └─ 미해당 시: 사이드벳 미수령
```

---

## 특수 케이스

### 케이스 1: Multi-way Tie (보드 결정적)

```
4명 모두 동일 핸드 (예: 보드가 결정적인 경우)
→ Pot split: 4 ways (odd chip → dealer-left)
```

### 케이스 2: Kicker 비교

```
Player A: K♠K♥A♦Q♣J♠ (Pair of Kings, A-Q-J kicker)
Player B: K♦K♣A♠10♥9♠ (Pair of Kings, A-10-9 kicker)
→ Player A 승리 (Q kicker > 10 kicker)
```

---

## 7-2 Side Bet — 사이드 판정

Hold'em에서 최약 핸드인 **7-2 offsuit**로 팟을 이기면, 각 상대에게서 사이드벳 금액을 추가로 수취하는 옵션 규칙이다.

### 활성화 전제조건

| 필드 | 조건 | 설명 |
|------|------|------|
| **special_rules.seven_deuce_side_bet_enabled** | true | 7-2 Side Bet 활성화됨 |
| **side_bet_amount** | > 0 | 각 플레이어별 사이드벳 금액 |

### 판정 규칙

1. **offsuit만 해당**: 7♠2♥, 7♥2♦ 등 수트가 다른 경우만 인정. 7♠2♠ 같은 suited는 미해당
2. **승리 필수**: SHOWDOWN에서 7-2 offsuit으로 팟을 이겨야 함. Fold한 7-2는 무효
3. **수취 금액**: `side_bet_amount` x 상대 수 (폴드 플레이어 제외)
4. **복수 보유**: 여러 플레이어가 7-2를 가져도 승리한 플레이어만 사이드벳 수취

### 경우의 수 매트릭스

| 7-2 SideBet Enabled | Winner Hand | Suit | Opponent Count | Side Bet Amt | 결과 |
|:--------:|:--------:|:--------:|:--------:|:--------:|----------|
| ❌ | 7-2o | — | 3 | — | Side Bet 미활성화 |
| ✅ | 7-2o (offsuit) | ✅ | 3 | $10 | $30 (3x10) 수령 |
| ✅ | 7-2s (suited) | ❌ | 3 | $10 | Side Bet 미수령 |
| ✅ | 7-3o | ❌ | 3 | $10 | Side Bet 미수령 (7-2 아님) |
| ✅ | 7-2o | ✅ | 2 (1인 폴드) | $10 | $10 (남은 플레이어만) |
| ✅ | 7-2o | ✅ | 3 (패자도 7-2o) | $10 | $30 (패자의 7-2는 무시) |

### 비활성 조건

- `special_rules.seven_deuce_side_bet_enabled == false` → 사이드벳 미활성화
- 승자 핸드가 7-2 offsuit이 아님 → 사이드팟 미수령
- 핸드가 끝나기 전 → 사이드벳 계산 미실행
