# BS-06-22: Draw Games — 핸드 평가

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-06 | 신규 작성 | Draw 7종 평가기 라우팅, Lowball 2-7/A-5 랭킹, Badugi 평가, Badeucy/Badacey 팟 분배, 유저 스토리 6개 |
| 2026-04-09 | Phase 표시 | **Phase 3 범위** — Hold'em Core 구현 완료 후 착수 |

---

> **이 문서에서 사용하는 용어**
>
> | 용어 | 설명 |
> |------|------|
> | evaluator | 카드 조합을 분석하여 승자를 결정하는 함수 |
> | 홀카드(hole card) | 각 플레이어에게 비공개로 나눠주는 카드 |
> | scoop | 한 사람이 팟 전체를 가져가는 것 |
> | odd chip | 팟을 나눌 때 딱 떨어지지 않는 나머지 1개 베팅 토큰 |
> | suit | 카드의 무늬 (스페이드/하트/다이아몬드/클럽의 4종류) |
> | Trips | Three of a Kind, 같은 숫자 카드 3장 |
> | C(n,k) | n장에서 k장을 고르는 조합의 수 (수학 조합 표기) |

## 개요

Draw 게임 중 5-Card Draw (game 12)는 Hold'em과 동일한 standard_high 평가를 사용한다. 나머지 6종은 고유한 평가 시스템이 필요하다. 이 문서는 각 평가기의 규칙, 랭킹, 동점 처리, 팟 분배 로직을 정의한다.

**Hold'em 평가와의 핵심 차이**:
- **Lowball**: 높은 핸드가 아닌 **낮은 핸드**가 승리
- **Badugi**: 5장이 아닌 **4장**, 수트/랭크 유니크 기준 평가
- **Split Pot**: 하나의 핸드를 **두 가지 평가기**로 분할 판정

---

## 평가기 라우팅

| `game_id` | 이름 | `evaluator` | 핵심 차이 |
|:--:|------|------|------|
| 12 | draw5 | standard_high | Hold'em과 동일 |
| 13 | deuce7_draw | lowball_27 | A=high, Straight/Flush 불리 |
| 14 | deuce7_triple | lowball_27 | 위와 동일, 3회 교환 |
| 15 | a5_triple | lowball_a5 | A=low, Straight/Flush 무시 |
| 16 | badugi | badugi | 4장, 수트x랭크 유니크 |
| 17 | badeucy | hilo_badugi_27 | Badugi + 2-7 Low split |
| 18 | badacey | hilo_badugi_a5 | Badugi + A-5 Low split |

---

## draw5 (game 12) — standard_high

5-Card Draw는 Hold'em과 동일한 standard_high 평가를 사용한다. 홀카드 5장이 곧 최종 핸드다 (best 5 of 5 = 5장 전부).

랭킹: High Card(0) ~ Straight Flush(8). BS-06-05 참조.

---

## Lowball 2-7 (game 13, 14)

### 규칙

| 항목 | 값 |
|------|-----|
| **목표** | 가장 낮은 핸드가 승리 |
| **A** | High (가장 높은 카드, 로우로 사용 불가) |
| **Straight** | 핸드에 불리하게 작용 (Straight가 있으면 랭킹 상승 = 패배 방향) |
| **Flush** | 핸드에 불리하게 작용 (Flush가 있으면 랭킹 상승 = 패배 방향) |
| **최고 핸드** | 2-3-4-5-7 (연속되지 않고, 같은 수트 아닌 5장) |

> 참고: A-2-3-4-5는 Straight이므로 불리. 7-5-4-3-2가 최고인 이유는 연속되지 않는 가장 낮은 5개 랭크 조합이기 때문이다.

### 랭킹

Lowball 2-7은 standard_high 랭킹을 **역순**으로 적용한다. 단, Straight와 Flush가 "불리하게 작용"하므로 단순 역순이 아님.

| 순위 | 핸드 이름 | 설명 | 예시 |
|:--:|------|------|------|
| 1 | **Number One** | 최고 로우: 7-high, 다른 수트 | 7♠5♥4♦3♣2♠ |
| 2 | **7-6 Low** | 7-6-x-x-x | 7♠6♥4♦3♣2♠ |
| 3 | **8 Low** | 8-x-x-x-x (No pair, no straight, no flush) | 8♠5♥4♦3♣2♠ |
| 4 | **9 Low** | 9-x-x-x-x | 9♠7♥5♦3♣2♠ |
| ... | ... | 높아질수록 불리 | ... |
| 하위 | **Pair** | 원페어 | K♠K♥7♦3♣2♠ |
| 하위 | **Two Pair** | 투페어 | K♠K♥7♦7♣2♠ |
| 하위 | **Trips**(같은 숫자 카드 3장) | 쓰리오브어카인드 | K♠K♥K♦3♣2♠ |
| 하위 | **Straight** | 스트레이트 (불리) | 7♠6♥5♦4♣3♠ |
| 하위 | **Flush** | 플러시 (불리) | 7♠5♠4♠3♠2♠ |
| 최하 | **Full House~Quads** | 풀하우스 이상 | 최악 |

### 동점 규칙

1. 핸드 타입 비교 (No Pair > Pair > Two Pair > ... , 낮을수록 유리)
2. 같은 타입이면 **가장 높은 카드부터 비교** (낮을수록 유리)
3. 모든 카드가 동일하면 팟 분할

**예시**:
- 7♠5♥4♦3♣2♠ vs 7♠6♥4♦3♣2♠ → 첫 번째 승 (5 < 6, 두 번째 높은 카드 비교)
- 8♠5♥4♦3♣2♠ vs 7♠6♥5♦4♣3♠ → 두 번째 승 (7-high < 8-high)

---

## Lowball A-5 (game 15)

### 규칙

| 항목 | 값 |
|------|-----|
| **목표** | 가장 낮은 핸드가 승리 |
| **A** | Low (가장 낮은 카드 = 1) |
| **Straight** | 무시 (핸드 평가에 영향 없음) |
| **Flush** | 무시 (핸드 평가에 영향 없음) |
| **최고 핸드** | A-2-3-4-5 (wheel) |

> 참고: Lowball 2-7과의 결정적 차이 — A가 Low이고, Straight/Flush를 무시하므로 A-2-3-4-5가 최고 핸드가 된다.

### 랭킹

| 순위 | 핸드 이름 | 설명 | 예시 |
|:--:|------|------|------|
| 1 | **Wheel** | A-2-3-4-5 (최고) | A♠2♥3♦4♣5♠ |
| 2 | **6 Low** | A-2-3-4-6 또는 6-x-x-x-x | A♠2♥3♦4♣6♠ |
| 3 | **7 Low** | 7-x-x-x-x | A♠2♥3♦4♣7♠ |
| 4 | **8 Low** | 8-x-x-x-x | A♠2♥3♦5♣8♠ |
| ... | ... | 높아질수록 불리 | ... |
| 하위 | **Pair** | 원페어 | A♠A♥3♦4♣5♠ |
| 하위 | **Two Pair** | 투페어 | A♠A♥3♦3♣5♠ |
| 최하 | **Trips~Quads** | 쓰리오브어카인드 이상 | 최악 |

> 참고: Straight와 Flush는 **무시**되므로 랭킹 테이블에 등장하지 않는다. A♠2♠3♠4♠5♠는 Flush이지만 여전히 Wheel(최고 핸드)이다.

### 동점 규칙

Lowball 2-7과 동일: 가장 높은 카드부터 비교 (낮을수록 유리).

---

## Badugi (game 16)

### 규칙

| 항목 | 값 |
|------|-----|
| **목표** | 4장으로 최고의 Badugi 구성 |
| **카드 수** | 4장 (Draw 게임 중 유일한 4장 게임) |
| **Badugi 조건** | 4 different suits(카드의 무늬 -- 스페이드/하트/다이아몬드/클럽) + 4 different ranks |
| **A** | Low (가장 낮은 카드 = 1) |
| **평가 우선순위** | 4-card Badugi > 3-card > 2-card > 1-card |
| **같은 card count 내** | 낮은 rank가 유리 |

### Badugi 카드 수 판정

중복 suit 또는 중복 rank가 있으면 카드를 제거하여 유효 카드 수를 결정한다.

**제거 규칙**:
1. 같은 suit 2장 이상 → 그 중 가장 **높은** 랭크 카드를 제거
2. 같은 rank 2장 이상 → 그 중 하나를 제거
3. 반복하여 남은 카드가 Badugi 카드 수

**예시**:

| 핸드 | 중복 | 제거 | 유효 카드 | Badugi 수 |
|------|------|------|---------|:--:|
| A♠2♥3♦4♣ | 없음 | 없음 | A♠2♥3♦4♣ | **4** |
| A♠2♥3♦4♦ | 3♦, 4♦ 같은 suit | 4♦ 제거 (높은 쪽) | A♠2♥3♦ | **3** |
| A♠2♥3♥4♦ | 2♥, 3♥ 같은 suit | 3♥ 제거 (높은 쪽) | A♠2♥4♦ | **3** |
| A♠A♥3♦4♣ | A♠, A♥ 같은 rank | A♥ 제거 | A♠3♦4♣ | **3** |
| A♠2♠3♠4♣ | A♠, 2♠, 3♠ 같은 suit | 3♠, 2♠ 순서 제거 | A♠4♣ | **2** |
| A♠A♠3♦3♦ | suit + rank 중복 | 최대 제거 | A♠3♦ | **2** |

### 랭킹

| 등급 | 조건 | 최고 예시 | 최악 예시 |
|:--:|------|------|------|
| **4-card** | 4 suits, 4 ranks | A♠2♥3♦4♣ (최고) | J♠Q♥K♦A♣ 아님 — K♠Q♥J♦T♣ |
| **3-card** | 유효 3장 | A♠2♥3♦ | Q♠K♥A♦ |
| **2-card** | 유효 2장 | A♠2♥ | K♠A♥ |
| **1-card** | 유효 1장 | A♠ | K♠ |

### Badugi 동점 규칙

1. **카드 수 비교**: 4-card > 3-card > 2-card > 1-card
2. **같은 카드 수 내**: 가장 높은 유효 카드부터 비교 (낮을수록 유리)

**예시**:
- A♠2♥3♦4♣ (4-card) vs A♠2♥3♦K♦ (3-card) → 첫 번째 승 (4-card > 3-card)
- A♠2♥3♦4♣ vs A♠2♥3♦5♣ → 첫 번째 승 (4 < 5, 최고 카드 비교)
- A♠2♥4♦ (3-card) vs A♠3♥4♦ (3-card) → 첫 번째 승 (2 < 3, 두 번째 카드 비교)

---

## Badeucy (game 17) — 2-7 Low + Badugi Split

### 규칙

| 항목 | 값 |
|------|-----|
| **홀카드** | 5장 |
| **`draw_count`** | 3 |
| **팟 분할** | Badugi half + 2-7 Low half |
| **Badugi half** | 홀카드 5장 중 4장으로 Badugi 평가 (최저 Badugi 승리) |
| **2-7 Low half** | 홀카드 5장 전체로 Lowball 2-7 평가 (최저 5-card 승리) |
| **scoop** | 동일 플레이어가 양쪽 모두 승리 → 팟 100% 수령 |

### Badugi half 평가 방법

5장 중 최고의 4-card Badugi를 자동 선택한다:
1. 5장에서 가능한 4장 조합 = C(5,4)(5장에서 4장을 고르는 조합의 수 = 5가지)
2. 각 조합에 대해 Badugi 평가 (유효 카드 수 + 낮은 rank 우선)
3. 최고 Badugi를 선택

### 2-7 Low half 평가 방법

5장 전체로 Lowball 2-7 규칙 적용 (A=high, Straight/Flush 불리).

### 팟 분배 매트릭스

| Badugi 승자 | 2-7 Low 승자 | 분배 |
|:--:|:--:|------|
| 플레이어 A | 플레이어 B | A = 50%, B = 50% |
| 플레이어 A | 플레이어 A | A = 100% (scoop) |
| 동점 (2명) | 플레이어 B | 동점자 각 25%, B = 50% |
| 플레이어 A | 동점 (2명) | A = 50%, 동점자 각 25% |

> 참고: 홀수 베팅 토큰은 Badugi half 승자에게 귀속.

---

## Badacey (game 18) — A-5 Low + Badugi Split

### 규칙

Badeucy(game 17)와 동일한 구조이지만, Low half가 **A-5 Lowball** 규칙을 사용한다.

| 항목 | Badeucy (game 17) | Badacey (game 18) |
|------|:--:|:--:|
| **Badugi half** | Badugi | Badugi (동일) |
| **Low half** | Lowball 2-7 | **Lowball A-5** |
| **A 용도 (Low)** | High (최악) | **Low (최고)** |
| **Straight (Low)** | 불리 | **무시** |
| **Flush (Low)** | 불리 | **무시** |
| **최고 Low** | 7-5-4-3-2 | **A-2-3-4-5** |

### Badugi half 평가 방법

Badeucy와 동일 (5장 중 최고 4-card Badugi 자동 선택).

### A-5 Low half 평가 방법

5장 전체로 Lowball A-5 규칙 적용 (A=low, Straight/Flush 무시).

### 팟 분배 매트릭스

Badeucy와 동일한 분배 규칙 적용.

| Badugi 승자 | A-5 Low 승자 | 분배 |
|:--:|:--:|------|
| 플레이어 A | 플레이어 B | A = 50%, B = 50% |
| 플레이어 A | 플레이어 A | A = 100% (scoop) |
| 동점 (2명) | 플레이어 B | 동점자 각 25%, B = 50% |
| 플레이어 A | 동점 (2명) | A = 50%, 동점자 각 25% |

> 참고: 홀수 베팅 토큰은 Badugi half 승자에게 귀속 (Badeucy와 동일).

---

## 유저 스토리

### US-E01: Lowball 2-7 Single Draw 승자 판정

**게임**: deuce7_draw (game 13)

1. SHOWDOWN 진입, 2명 active
2. 플레이어 A 핸드: 7♠5♥4♦3♣2♠ → **Number One** (최고 로우)
3. 플레이어 B 핸드: 8♠5♥4♦3♣2♠ → 8 Low
4. `evaluator` = lowball_27 → 가장 높은 카드 비교: 7 < 8
5. 플레이어 A 승리, 팟 전체 수령

---

### US-E02: Lowball A-5에서 Wheel 승리

**게임**: a5_triple (game 15)

1. SHOWDOWN 진입, 3명 active
2. 플레이어 A: A♠2♥3♦4♣5♠ → **Wheel** (A-2-3-4-5, 최고)
3. 플레이어 B: 2♠3♥4♦5♣6♠ → 6 Low
4. 플레이어 C: A♠2♥3♦4♣7♠ → 7 Low
5. `evaluator` = lowball_a5 → Wheel이 최고 로우
6. 플레이어 A 승리

---

### US-E03: Badugi 4-card vs 3-card

**게임**: badugi (game 16)

1. SHOWDOWN 진입, 2명 active
2. 플레이어 A: A♠2♥3♦4♣ → 4-card Badugi (4 suits, 4 ranks)
3. 플레이어 B: A♠2♥3♦K♦ → 3-card Badugi (3♦, K♦ 중복 suit → K♦ 제거)
4. `evaluator` = badugi → 4-card > 3-card
5. 플레이어 A 승리

---

### US-E04: Badugi 동점 — 같은 카드 수 내 비교

**게임**: badugi (game 16)

1. SHOWDOWN 진입, 2명 active
2. 플레이어 A: A♠2♥3♦5♣ → 4-card Badugi, 최고 카드 = 5
3. 플레이어 B: A♠2♥4♦5♣ → 4-card Badugi, 최고 카드 = 5
4. 최고 카드 동일 (5) → 다음 카드 비교: A의 3 vs B의 4
5. 3 < 4 → 플레이어 A 승리

---

### US-E05: Badeucy Split Pot

**게임**: badeucy (game 17)

1. SHOWDOWN 진입, 3명 active
2. 플레이어 A 핸드 (5장): A♠2♥3♦4♣7♠
   - Badugi half: A♠2♥3♦4♣ → **4-card Badugi** (A-2-3-4)
   - 2-7 Low half: 7♠4♦3♣2♥A♠ → A=high → A-7-4-3-2 (Pair 없지만 A가 highest)
3. 플레이어 B 핸드 (5장): 2♠3♥5♦7♣8♠
   - Badugi half: 2♠3♥5♦7♣ → **4-card Badugi** (2-3-5-7)
   - 2-7 Low half: 8♠7♣5♦3♥2♠ → **8 Low** (8-7-5-3-2)
4. 플레이어 C 핸드 (5장): 4♠5♥6♦8♣T♠
   - Badugi half: 4♠5♥6♦8♣ → **4-card Badugi** (4-5-6-8)
   - 2-7 Low half: T♠8♣6♦5♥4♠ → **T Low** (10-8-6-5-4)
5. Badugi 승자: 플레이어 A (A-2-3-4 < 2-3-5-7 < 4-5-6-8)
6. 2-7 Low 승자: 플레이어 B (8-7-5-3-2 < A-7-4-3-2 < T-8-6-5-4)
7. 팟 분배: A = 50%, B = 50%

---

### US-E06: Badacey Scoop (동일인 양쪽 승리)

**게임**: badacey (game 18)

1. SHOWDOWN 진입, 2명 active
2. 플레이어 A 핸드 (5장): A♠2♥3♦4♣5♠
   - Badugi half: A♠2♥3♦4♣ → **4-card Badugi** (A-2-3-4)
   - A-5 Low half: A♠2♥3♦4♣5♠ → **Wheel** (A-2-3-4-5, 최고)
3. 플레이어 B 핸드 (5장): 5♠6♥7♦8♣J♠
   - Badugi half: 5♠6♥7♦8♣ → **4-card Badugi** (5-6-7-8)
   - A-5 Low half: J♠8♣7♦6♥5♠ → **J Low** (11-8-7-6-5)
4. Badugi 승자: 플레이어 A (A-2-3-4 < 5-6-7-8)
5. A-5 Low 승자: 플레이어 A (Wheel < J Low)
6. **Scoop**: 플레이어 A = 100%

---

## 구현 체크리스트

| 항목 | 검증 기준 |
|------|---------|
| `evaluator` 라우팅 | `game_id`에 따라 올바른 평가 함수 호출 |
| Lowball 2-7: A=high | A를 14(highest)로 처리 |
| Lowball 2-7: Straight/Flush 불리 | Straight/Flush 보유 시 핸드 랭킹 상승 |
| Lowball A-5: A=low | A를 1(lowest)로 처리 |
| Lowball A-5: Straight/Flush 무시 | 평가에서 제외 |
| Badugi: 유효 카드 수 판정 | 중복 suit/rank 제거 로직 |
| Badugi: 4장 > 3장 > 2장 > 1장 | 카드 수 우선 비교 |
| Badugi: 같은 카드 수 내 비교 | 가장 높은 카드부터 비교 (낮을수록 유리) |
| Badeucy: Badugi + 2-7 split | 5장 중 4장 Badugi + 5장 전체 2-7 |
| Badacey: Badugi + A-5 split | 5장 중 4장 Badugi + 5장 전체 A-5 |
| Split pot: 50/50 분배 | 홀수 토큰은 Badugi half 귀속 |
| Scoop 판정 | 동일인 양쪽 승리 시 100% |
| 동점 처리 | 모든 평가기에서 동점 시 팟 분할 |
