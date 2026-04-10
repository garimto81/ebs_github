# BS-06-32: Seven Card Stud — 핸드 평가

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-06 | 신규 작성 | Stud Hi-Lo (game 20) + Razz (game 21) 핸드 평가 규칙 정의 |
| 2026-04-09 | Phase 표시 | **Phase 3 범위** — Hold'em Core 구현 완료 후 착수 |

---

> **이 문서에서 사용하는 용어**
>
> | 용어 | 설명 |
> |------|------|
> | evaluator | 카드 조합을 분석하여 승자를 결정하는 함수 |
> | 8-or-better | 8 이하 카드로만 구성된 패만 Low 자격이 있다는 조건 |
> | scoop | 한 사람이 팟 전체를 가져가는 것 |
> | odd chip | 팟을 나눌 때 딱 떨어지지 않는 나머지 1개 베팅 토큰 |
> | C(n,k) | n장에서 k장을 고르는 조합의 수 (수학 조합 표기) |
> | suit | 카드의 무늬 (스페이드/하트/다이아몬드/클럽의 4종류) |

## 개요

7-Card Stud (game 19)는 Hold'em과 동일한 standard_high 평가를 사용한다. 이 문서는 고유한 평가가 필요한 **Stud Hi-Lo** (game 20)와 **Razz** (game 21)를 다룬다.

**이 문서의 범위**:
- game 20: hilo_8or_better 평가 — Hi/Lo split pot + 8-or-better qualifier(자격 조건 -- 이 조건을 충족해야 Low 팟에 참여 가능)
- game 21: lowball_a5 평가 — 로우볼 전용, A = Low

**이 문서의 범위 밖**:
- game 19: standard_high — Hold'em 평가 문서 (BS-06-05) 참조

---

## 평가기 라우팅

| `game_id` | 이름 | `evaluator` | 이 문서 범위 |
|:--:|------|------|:--:|
| 19 | stud7 | standard_high | 범위 밖 |
| 20 | stud7_hilo8 | hilo_8or_better | 범위 내 |
| 21 | razz | lowball_a5 | 범위 내 |

---

## 7-Card Stud 공통: 7장 중 best 5

모든 Stud 게임은 플레이어 개인 7장 (3 down + 4 up) 중 best 5-card hand를 선택한다.

| 속성 | 값 |
|------|-----|
| **총 카드** | 7장 (개인 소유) |
| **평가 대상** | best 5-card hand |
| **조합 수** | C(7,5) = 21 조합 |
| **보드 카드** | 없음 (Hold'em과 다름) |

> 참고: Hold'em은 홀 2장 + 보드 5장 = 7장에서 best 5를 선택한다. Stud는 개인 7장에서 best 5를 선택한다. 조합 계산 로직은 동일하다.

---

## Stud Hi-Lo 8-or-better (game 20)

### High 평가

standard_high를 그대로 사용한다. 7장 중 best 5-card high hand를 선택한다.

| 랭킹 | 핸드 | 설명 |
|:--:|------|------|
| 0 | High Card | 쌍 없음 |
| 1 | Pair | 같은 랭크 2장 |
| 2 | Two Pair | 서로 다른 쌍 2개 |
| 3 | Trips | 같은 랭크 3장 |
| 4 | Straight | 연속 5장 |
| 5 | Flush | 같은 수트 5장 |
| 6 | Full House | Trips + Pair |
| 7 | Four of a Kind | 같은 랭크 4장 |
| 8 | Straight Flush | Straight + Flush |

### Low 자격 (8-or-better qualifier)

Low 자격을 얻으려면 **5장 모두** 아래 조건을 충족해야 한다:

| 조건 | 설명 |
|------|------|
| **rank <= 8** | 5장 모두 8 이하 (A, 2, 3, 4, 5, 6, 7, 8) |
| **서로 다른 rank** | 5장이 모두 다른 랭크 |
| **A = Low** | Ace는 1로 계산 (가장 낮은 카드) |
| **Straight 무시** | Low 평가에서 Straight는 핸드를 해치지 않음 |
| **Flush 무시** | Low 평가에서 Flush는 핸드를 해치지 않음 |

### Low 자격 경우의 수

| 예시 핸드 | Low 자격 | 이유 |
|---------|:--:|------|
| A-2-3-4-5 | 충족 | 모두 8 이하, 서로 다른 rank (최고 Low = "wheel") |
| A-2-3-4-8 | 충족 | 모두 8 이하, 서로 다른 rank |
| A-2-3-4-9 | **불충족** | 9가 8보다 큼 |
| A-2-3-3-5 | **불충족** | 3이 중복 |
| 2-3-4-5-6 | 충족 | Straight이지만 Low에서 무시 |

### Low 랭킹

Low 자격을 충족한 핸드들 사이에서는 **가장 높은 카드부터 비교**한다.

| 순위 | 예시 | Low 값 |
|:--:|------|------|
| 1 (최고) | A-2-3-4-5 | 5-4-3-2-A |
| 2 | A-2-3-4-6 | 6-4-3-2-A |
| 3 | A-2-3-5-6 | 6-5-3-2-A |
| ... | ... | ... |
| 최저 | 4-5-6-7-8 | 8-7-6-5-4 |

### 팟 분배

| High 승자 | Low 자격자 존재 | 분배 |
|---------|:--:|------|
| A 플레이어 | 없음 | A가 **전체 팟** 수령 (scoop) |
| A 플레이어 | B 플레이어 | A가 50%, B가 50% (split) |
| A 플레이어 | A 플레이어 (동일인) | A가 **전체 팟** 수령 (scoop) |
| A, B 동점 Hi | C 플레이어 Low | Hi 50% 균분 (A 25%, B 25%), Lo C 50% |
| A 플레이어 | B, C 동점 Lo | Hi A 50%, Lo 균분 (B 25%, C 25%) |

### Odd Chip 규칙

| 상황 | Odd Chip 수령자 |
|------|-------------|
| **Hi/Lo split** | Hi 승자에게 우선 |
| **Hi 동점** | 딜러 왼쪽 가장 가까운 플레이어 |
| **Lo 동점** | 딜러 왼쪽 가장 가까운 플레이어 |

---

## Razz (game 21)

### 규칙

| 속성 | 값 |
|------|-----|
| **평가** | Lowball A-5 |
| **A 역할** | Low (가장 낮은 카드, 1로 계산) |
| **Straight** | 무시 (Low에 영향 없음) |
| **Flush** | 무시 (Low에 영향 없음) |
| **최고 핸드** | A-2-3-4-5 (wheel) |
| **최악 핸드** | K-K-K-K-x (높은 pair 조합) |

### Razz 핸드 랭킹

7장 중 **가장 낮은 5장**을 선택한다. 가장 높은 카드부터 비교하여 낮을수록 승리한다.

| 순위 | 예시 | 설명 |
|:--:|------|------|
| 1 (최고) | A-2-3-4-5 | wheel — 가능한 최저 핸드 |
| 2 | A-2-3-4-6 | 6-low |
| 3 | A-2-3-5-6 | 6-low (5가 4보다 높음) |
| 4 | A-2-3-4-7 | 7-low |
| ... | ... | ... |
| 하위 | 2-3-4-5-K | K-low |
| 최악 | 높은 pair+ | pair가 있으면 pair 없는 핸드에 항상 짐 |

### Razz 평가 상세 규칙

| 규칙 | 설명 |
|------|------|
| **pair 없는 핸드 > pair 있는 핸드** | pair가 없는 핸드가 항상 우위 |
| **pair 동점** | 더 낮은 pair가 승리 |
| **최고 카드 비교** | 가장 높은 카드부터 내림차순 비교 |
| **모두 pair** | 가장 낮은 pair 보유자 승리, 동점 시 나머지 카드 비교 |
| **Straight 포함** | Low에 영향 없음 (A-2-3-4-5 = wheel, straight이지만 최고) |
| **Flush 포함** | Low에 영향 없음 |

### Razz vs Deuce-7 Lowball 차이

| 속성 | Razz (game 21) | Deuce-7 (game 13, 14) |
|------|------|------|
| **A 역할** | Low (1) | High (14) |
| **Straight** | 무시 | 불리 (핸드 올라감) |
| **Flush** | 무시 | 불리 (핸드 올라감) |
| **최고 Low** | A-2-3-4-5 | 7-5-4-3-2 |
| **game_class** | stud (2) | draw (1) |

### Bring-in과의 관계

| 항목 | game 19, 20 | game 21 (Razz) |
|------|------|------|
| **bring-in 기준** | 최저 up card | 최고 up card (역순) |
| **이유** | 약한 카드 = 불리 → 먼저 강제 베팅 | 높은 카드 = 불리 → 먼저 강제 베팅 |
| **first to act (4TH~7TH)** | 최고 visible hand | 최고 visible hand |

> 참고: 4TH~7TH Street의 first to act는 모든 Stud 게임에서 동일하게 **최고 visible hand** 기준이다. Razz에서도 "가장 강해 보이는 공개 카드"가 먼저 액션한다 — 이는 bring-in 역순 규칙과 별개다.

---

## 유저 스토리

**US-32-01: Hi-Lo Low 자격 없음 (scoop)**
- game 20 SHOWDOWN → 모든 활성 플레이어의 7장 중 Low qualifier 체크 → 어떤 플레이어도 5장 모두 8 이하 조합 불가 → "No Low" 판정 → Hi 승자가 **전체 팟** 수령 → UI에 "No Low Qualifier" 표시

**US-32-02: Hi-Lo 동일인 scoop**
- game 20 SHOWDOWN → 플레이어 A가 Hi 최고 + Low 최저 동시 보유 → 팟 100% A에게 분배 → UI에 "Scoops Hi & Lo" 표시

**US-32-03: Hi-Lo 다른 플레이어 split**
- game 20 SHOWDOWN → 플레이어 A가 Hi 승자, 플레이어 B가 Lo 승자 → 팟 50/50 분배 → Odd chip은 Hi 승자 A에게 → UI에 "Split Pot: Hi=A, Lo=B" 표시

**US-32-04: Razz wheel vs 6-low**
- game 21 SHOWDOWN → 플레이어 A의 best low = A-2-3-4-5, 플레이어 B의 best low = 2-3-4-5-6 → A의 wheel이 B의 6-low를 이김 → A가 팟 수령

**US-32-05: Razz pair 비교**
- game 21 SHOWDOWN → 플레이어 A의 best 5 = A-2-3-4-4 (pair of 4s), 플레이어 B의 best 5 = 2-3-4-5-K (K-low, no pair) → pair 없는 B가 pair 있는 A를 이김 → B가 팟 수령

---

## 구현 체크리스트

| 항목 | 설명 | 우선순위 |
|------|------|:--:|
| hilo_8or_better 평가기 | Hi(standard) + Lo(A-5, qualifier) 동시 평가 | P0 |
| 8-or-better qualifier | 5장 모두 rank <= 8, 서로 다른 rank | P0 |
| lowball_a5 평가기 | A=Low, Straight/Flush 무시, 7장 중 best low 5 | P0 |
| Hi/Lo split pot 분배 | 50/50 분배, No-Low 시 Hi scoop | P0 |
| Odd chip 처리 | Hi 우선, 동점 시 딜러 왼쪽 | P1 |
| C(7,5) 조합 평가 | 21 조합 중 best 선택 (Hi, Lo 각각) | P0 |
| Razz bring-in 역순 연동 | BS-06-31 bring-in 로직과 일관성 확인 | P1 |
| No-Low UI 표시 | "No Low Qualifier" 메시지 | P1 |
