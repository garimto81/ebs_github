# TEST-03: Game Engine 테스트 Fixtures

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | Hold'em 대표 테스트 케이스 32개 (10개 카테고리) |

---

## 개요

Game Engine(순수 Dart 패키지)의 Hold'em 테스트 케이스를 정의한다. 각 케이스는 **입력(players, cards, actions)**과 **기대 출력(game_phase, pots, winners)**을 명시하며, 결정론적 재현이 가능하다.

> 참조: HandFSM — BS-06-01, 베팅 액션 — BS-06-02, Mock 합성 — BS-06-00 §4

### 표기법

| 표기 | 의미 |
|------|------|
| `As` | Ace of Spades |
| `Kh` | King of Hearts |
| `Td` | Ten of Diamonds |
| `9c` | Nine of Clubs |
| suit: 0=Spade, 1=Heart, 2=Diamond, 3=Club | rank: 0=Two ~ 12=Ace |

---

## 카테고리 1: 기본 흐름 (Pre-Flop → Showdown)

### TC-01: 6인 정상 핸드 — Showdown 도달

| 항목 | 값 |
|------|:--|
| **Players** | P0~P5, stack=10000 각각, BB=100, SB=50, Dealer=P0 |
| **Hole Cards** | P0: `As Ks`, P1: `Qh Jh`, P2: `Td 9d`, P3: `8c 7c`, P4: `6s 5s`, P5: `4h 3h` |
| **Board** | `Ah 7d 2c Ts 3s` |
| **Actions** | PRE_FLOP: P3 Call, P4 Fold, P5 Fold, P0 Raise(300), P1 Call, P2 Fold, P3 Call → FLOP: P1 Check, P3 Check, P0 Bet(500), P1 Call, P3 Fold → TURN: P1 Check, P0 Bet(1000), P1 Call → RIVER: P1 Check, P0 Check |
| **기대 결과** | game_phase = SHOWDOWN → HAND_COMPLETE, winner = P0 (Pair of Aces, K kicker), pot = 4550 |

### TC-02: 2인 Heads-Up 정상 핸드

| 항목 | 값 |
|------|:--|
| **Players** | P0, P1, stack=5000, BB=100, SB=50, Dealer=P0 (Heads-up: Dealer=SB) |
| **Hole Cards** | P0: `Kd Qd`, P1: `Jc Tc` |
| **Board** | `9h 8s 2d Kc 4h` |
| **Actions** | PRE_FLOP: P0 Call, P1 Check → FLOP: P1 Bet(200), P0 Call → TURN: P1 Check, P0 Bet(500), P1 Call → RIVER: P1 Check, P0 Check |
| **기대 결과** | winner = P0 (Pair of Kings), pot = 1550 |

### TC-03: 3인 핸드 — River에서 최종 결정

| 항목 | 값 |
|------|:--|
| **Players** | P0~P2, stack=8000, BB=200, SB=100 |
| **Hole Cards** | P0: `Ah Kh`, P1: `Qs Qd`, P2: `Jd Td` |
| **Board** | `Qh Th 5c 3s 2h` |
| **Actions** | PRE_FLOP: 전원 Call → FLOP~RIVER: 전원 Check |
| **기대 결과** | winner = P0 (Flush, Ace-high Hearts), pot = 600 |

### TC-04: 4인 핸드 — Flop에서 3명 폴드

| 항목 | 값 |
|------|:--|
| **Players** | P0~P3, stack=10000, BB=100, SB=50 |
| **Hole Cards** | P0: `7s 2d`, P1: `As Kd`, P2: `9c 8c`, P3: `Jh Th` |
| **Board** | `Ac 5d 3h` (Flop만) |
| **Actions** | PRE_FLOP: 전원 Call → FLOP: P1 Bet(300), P2 Fold, P3 Fold, P0 Fold |
| **기대 결과** | winner = P1 (All Fold at FLOP), game_phase = HAND_COMPLETE, pot = 700 |

### TC-05: 최대 10인 핸드 — PRE_FLOP 다수 폴드 후 2인 진행

| 항목 | 값 |
|------|:--|
| **Players** | P0~P9, stack=10000, BB=100, SB=50 |
| **Hole Cards** | P0: `As Ad`, P9: `Ks Kd`, 나머지 임의 |
| **Board** | `7c 4d 2s Jh 8c` |
| **Actions** | PRE_FLOP: P2~P8 Fold, P9 Raise(300), P0 Call, P1 Fold → FLOP~RIVER: P0 Check, P9 Check (전 라운드) |
| **기대 결과** | winner = P0 (Pair of Aces), pot = 750 |

---

## 카테고리 2: 베팅 — NL Bet/Raise/All-In 금액 계산

### TC-06: NL 최소 레이즈 계산

| 항목 | 값 |
|------|:--|
| **Setup** | 3인, BB=100, P1 Bet(200) |
| **테스트** | P2 Raise 시 최소 금액 |
| **기대 결과** | min_raise = 200 + (200 - 0) = 400. P2 Raise(300) → REJECTED, P2 Raise(400) → ACCEPTED |

### TC-07: NL 연속 레이즈 — min_raise 추적

| 항목 | 값 |
|------|:--|
| **Setup** | 4인, BB=100. P1 Bet(200), P2 Raise(500) |
| **테스트** | P3 Raise 시 최소 금액 |
| **기대 결과** | last_raise_increment = 500 - 200 = 300, min_raise = 500 + 300 = 800 |

### TC-08: Short All-In Call 처리

| 항목 | 값 |
|------|:--|
| **Setup** | 3인. P1(stack=500) Bet(500) All-In, P2(stack=300) Call |
| **테스트** | P2 Call 금액 |
| **기대 결과** | P2 Call = 300 (short call), P2.status = allin, side pot 분리 |

### TC-09: PL 최대 베팅 계산

| 항목 | 값 |
|------|:--|
| **Setup** | 3인, PL, pot=600, biggest_bet=200, P1.current_bet=0 |
| **테스트** | P1 Raise 최대 금액 |
| **기대 결과** | max_raise = pot(600) + call(200) + call(200) = 1000. P1 Raise(1001) → REJECTED |

### TC-10: FL 레이즈 Cap 도달

| 항목 | 값 |
|------|:--|
| **Setup** | 3인, FL, low_limit=100, raise_cap=4 |
| **Actions** | P0 Bet(100), P1 Raise(200), P2 Raise(300), P0 Raise(400) — 4번째 레이즈 |
| **기대 결과** | P1 Raise 시도 → REJECTED ("Cap reached"), P1은 Call/Fold만 가능 |

---

## 카테고리 3: 블라인드 — 7종 Ante 유형별 수집

### TC-11: 기본 SB/BB (Ante 없음)

| 항목 | 값 |
|------|:--|
| **Setup** | 6인, SB=50, BB=100, Ante=0 |
| **기대 결과** | SETUP_HAND 진입 시: P1(SB) 스택 -50, P2(BB) 스택 -100, pot=150 |

### TC-12: SB/BB + Big Blind Ante (BBA)

| 항목 | 값 |
|------|:--|
| **Setup** | 6인, SB=50, BB=100, BBA=100 (BB가 Ante도 납부) |
| **기대 결과** | P1(SB) -50, P2(BB) -200, pot=250. BB check option: biggest_bet = 100 (BBA는 Dead money) |

### TC-13: Straddle 포함 블라인드

| 항목 | 값 |
|------|:--|
| **Setup** | 6인, SB=50, BB=100, Straddle=200 (UTG) |
| **기대 결과** | P1(SB) -50, P2(BB) -100, P3(UTG/Straddle) -200, pot=350. 액션 순서: P4 → P5 → P0 → P1 → P2 → P3 (Straddle가 마지막) |

---

## 카테고리 4: 사이드 팟 분배

### TC-14: 2개 사이드 팟 — 3인 All-In

| 항목 | 값 |
|------|:--|
| **Players** | P0(stack=1000), P1(stack=3000), P2(stack=5000) |
| **Actions** | P0 All-In(1000), P1 All-In(3000), P2 Call(3000) |
| **Board** | `As Kd Qc Jh Ts` |
| **Hole Cards** | P0: `Ah Ad` (Pair of Aces), P1: `Ks Kh` (Pair of Kings), P2: `7c 2d` (High card) |
| **기대 결과** | Main Pot=3000 → P0 승. Side Pot 1=4000 → P1 승. P2 나머지 2000 반환 |

### TC-15: 동일 핸드 — 팟 균등 분할 (Chop)

| 항목 | 값 |
|------|:--|
| **Players** | P0(stack=2000), P1(stack=2000) |
| **Actions** | 전원 All-In |
| **Board** | `As Kd Qc Jh Ts` (Board Straight) |
| **Hole Cards** | P0: `2c 3c`, P1: `4d 5d` (둘 다 Board Straight) |
| **기대 결과** | Pot=4000 → 균등 분할 P0=2000, P1=2000 |

### TC-16: 3개 사이드 팟 — 4인 All-In

| 항목 | 값 |
|------|:--|
| **Players** | P0(500), P1(1500), P2(3000), P3(5000) |
| **Actions** | 전원 All-In |
| **Board** | `Td 9h 5c 2s Kd` |
| **Hole Cards** | P0: `Kh Ks`, P1: `Qd Qc`, P2: `Jd Js`, P3: `8c 7c` |
| **기대 결과** | Main(2000)→P0. Side1(3000)→P1. Side2(3000)→P2. P3 나머지 2000 반환 |

---

## 카테고리 5: 핸드 평가

### TC-17: Royal Flush 승리

| 항목 | 값 |
|------|:--|
| **Hole Cards** | P0: `As Ks`, P1: `Qd Qc` |
| **Board** | `Qs Js Ts 5h 2d` |
| **기대 결과** | P0 = Royal Flush (A-K-Q-J-T Spades), P1 = Three Queens. winner = P0 |

### TC-18: Full House vs Full House — Kicker 비교

| 항목 | 값 |
|------|:--|
| **Hole Cards** | P0: `Kh Kd`, P1: `Qh Qd` |
| **Board** | `Kc Qs 7c 7h 2d` |
| **기대 결과** | P0 = Full House (K-K-K-7-7), P1 = Full House (Q-Q-Q-7-7). winner = P0 |

### TC-19: Straight vs Flush — Flush 승리

| 항목 | 값 |
|------|:--|
| **Hole Cards** | P0: `9h 8h`, P1: `Jd Td` |
| **Board** | `7h 6h 5d Kh 2c` |
| **기대 결과** | P0 = Flush (K-9-8-7-6 Hearts), P1 = Straight (J-T-9-8-7, 아니요 — 8이 없음). 재확인: P1 = J-high. winner = P0 |

### TC-20: Two Pair vs Two Pair — 5번째 카드(Kicker) 결정

| 항목 | 값 |
|------|:--|
| **Hole Cards** | P0: `Ah 9c`, P1: `As 8d` |
| **Board** | `Kd 9h 8c 5s 2d` |
| **기대 결과** | P0 = Two Pair (A-A, 9-9, K kicker — 아니요: A-9-9-K), 재확인: P0 = A-9 pair with K kicker, P1 = A-8 pair with K kicker. P0 = (9s > 8s). winner = P0 |

### TC-21: Hi-Lo Split (Omaha Hi-Lo 시 참조용)

| 항목 | 값 |
|------|:--|
| **Hole Cards** | P0: `As 2d`, P1: `Kh Kd` |
| **Board** | `3c 4h 5s Jd 9c` |
| **기대 결과** | Hi: P1 (Pair of Kings). Lo: P0 (5-4-3-2-A wheel). Pot 50/50 분할 |

---

## 카테고리 6: All Fold — 전원 폴드 → 우승자

### TC-22: PRE_FLOP All Fold (BB 승리)

| 항목 | 값 |
|------|:--|
| **Setup** | 6인, BB=100. PRE_FLOP: UTG~BTN 전원 Fold, SB Fold |
| **기대 결과** | winner = BB (마지막 생존자), pot = 150 (SB+BB), game_phase → HAND_COMPLETE 직행. Showdown 없음, 카드 미공개 |

### TC-23: FLOP All Fold (Bet 후 전원 폴드)

| 항목 | 값 |
|------|:--|
| **Setup** | 3인, pot=300 (PRE_FLOP 후). FLOP: P0 Bet(500), P1 Fold, P2 Fold |
| **기대 결과** | winner = P0, pot = 800, game_phase → HAND_COMPLETE 직행 |

---

## 카테고리 7: Bomb Pot

### TC-24: Bomb Pot — PRE_FLOP 스킵

| 항목 | 값 |
|------|:--|
| **Setup** | 6인, bomb_pot_amount=500, stack=10000 각각 |
| **기대 결과** | SETUP_HAND: 전원 -500, pot=3000. PRE_FLOP 스킵. game_phase → FLOP 직행. 이후 정상 FLOP 베팅 |

### TC-25: Bomb Pot — Short Stack 처리

| 항목 | 값 |
|------|:--|
| **Setup** | 6인, bomb_pot_amount=500, P3(stack=200) |
| **기대 결과** | P3은 200만 납부 (short contribution), 나머지 5명 500 납부. pot=2700. P3 기여분으로 side pot 분리 가능 |

---

## 카테고리 8: Run It Twice

### TC-26: Run It Twice — 2회 보드 전개

| 항목 | 값 |
|------|:--|
| **Setup** | 2인 All-In at FLOP. Board = `Kd 7h 3c`. run_it_times=2 |
| **Hole Cards** | P0: `As Ad`, P1: `Ks Qs` |
| **Run 1 Board** | `Kd 7h 3c 2s 5d` → P0 승 (Pair of Aces) |
| **Run 2 Board** | `Kd 7h 3c Kh Qd` → P1 승 (Three Kings) |
| **기대 결과** | Pot 50/50 분할. game_phase: SHOWDOWN → RUN_IT_MULTIPLE → HAND_COMPLETE |

### TC-27: Run It Twice — 동일 승자

| 항목 | 값 |
|------|:--|
| **Setup** | 2인 All-In at FLOP. run_it_times=2 |
| **Hole Cards** | P0: `As Ah`, P1: `2d 3c` |
| **Run 1, 2 Board** | 둘 다 P0 승 |
| **기대 결과** | P0가 전체 Pot 수령 (50% + 50% = 100%) |

---

## 카테고리 9: Undo

### TC-28: Undo 1단계 — 마지막 액션 되돌리기

| 항목 | 값 |
|------|:--|
| **Setup** | PRE_FLOP, P1 Bet(200), P2 Call(200), P3 Raise(500) |
| **Action** | UNDO |
| **기대 결과** | P3 Raise 되돌림. P3 스택 +500 복원. action_on = P3. biggest_bet_amt = 200 |

### TC-29: Undo 5단계 최대 + 6번째 거부

| 항목 | 값 |
|------|:--|
| **Setup** | 5개 액션 진행 후 |
| **Action** | UNDO × 5 → 성공, UNDO × 6 → REJECTED |
| **기대 결과** | 5번째까지 정상 복원. 6번째 시도 시 "Undo limit reached" 에러 |

---

## 카테고리 10: Edge Cases

### TC-30: Heads-Up — 딜러/SB 동일

| 항목 | 값 |
|------|:--|
| **Setup** | 2인 (P0=Dealer/SB, P1=BB), BB=100, SB=50 |
| **기대 결과** | P0(SB) 먼저 액션 (PRE_FLOP). FLOP부터 P1(BB) 먼저 액션. Heads-up 레이즈 cap 미적용 |

### TC-31: Straddle — 액션 순서 변경

| 항목 | 값 |
|------|:--|
| **Setup** | 6인, SB=P1, BB=P2, Straddle=P3(200) |
| **기대 결과** | PRE_FLOP 액션 순서: P4 → P5 → P0 → P1 → P2 → P3. P3(Straddle)가 마지막 액션, Check option 활성 |

### TC-32: 칩 합의 (Chop Agreement) — ConfirmChop

| 항목 | 값 |
|------|:--|
| **Setup** | SHOWDOWN 직전, 2인 All-In, 운영자가 ConfirmChop 선택 |
| **Actions** | ConfirmChop(P0=6000, P1=4000) |
| **기대 결과** | Pot 분배: P0=6000, P1=4000 (합의 금액). 핸드 평가 미실행. game_phase → HAND_COMPLETE |

---

## 비활성 조건

- 물리 RFID 카드 감지: 테스트 범위 외 (Mock injectCard만)
- Omaha, Stud, Razz 전용 테스트: 이 문서 범위 외 (별도 문서 필요)

---

## 영향 받는 요소

| 요소 | 관계 |
|------|------|
| TEST-01 Test Plan | Unit 테스트 70% 계층의 구체적 케이스 |
| TEST-04 Mock Data | 테스트 입력값의 Mock 데이터 참조 |
| BS-06-01 Lifecycle | HandFSM 상태 전이 검증 기준 |
| BS-06-02 Betting | 베팅 유효성/금액 계산 검증 기준 |
