# QA-GE-06 — 22종 게임별 매트릭스

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Master Plan §8.7 + §8.7.1 확장 — 22종 게임 매트릭스 TC 상세화 v1.0.0 |
| 2026-04-09 | TC 추가 | 코드 리뷰 발견: TC-G1-012-12a (Courchevel preflop 카드 강제 사용) |

---

## §1 개요

22종 게임의 정상/예외 시나리오 조합을 매트릭스로 관리한다. 각 게임은 고유한 홀카드 수, evaluator, 특수 규칙을 가지며, 공통 예외 시나리오(All-In, Miss Deal, Run It Twice, Bomb Pot, Hi/Lo Split)와 교차 검증한다.

### 22종 게임 요약

| # | 계열 | 게임 | 홀카드 | Hi/Lo | evaluator | 특수 규칙 |
|:-:|:----:|------|:------:|:-----:|-----------|----------|
| 1 | Flop | Texas Hold'em | 2 | Hi | standard_high | 표준 |
| 2 | Flop | 6+ Hold'em (S>T) | 2 | Hi | short_deck_st | 36장 덱, Straight > Trips |
| 3 | Flop | 6+ Hold'em (T>S) | 2 | Hi | short_deck_ts | 36장 덱, Trips > Straight |
| 4 | Flop | Pineapple | 3→2 | Hi | standard_high | 1장 discard after FLOP |
| 5 | Flop | Omaha | 4 | Hi | omaha_high | 반드시 2장 사용 |
| 6 | Flop | Omaha Hi-Lo | 4 | Hi/Lo | omaha_hilo | 8-or-better |
| 7 | Flop | 5Card Omaha | 5 | Hi | omaha_high | 반드시 2장 사용 |
| 8 | Flop | 5Card Omaha Hi-Lo | 5 | Hi/Lo | omaha_hilo | 8-or-better |
| 9 | Flop | 6Card Omaha | 6 | Hi | omaha_high | 반드시 2장 사용 |
| 10 | Flop | 6Card Omaha Hi-Lo | 6 | Hi/Lo | omaha_hilo | 8-or-better |
| 11 | Flop | Courchevel | 5 | Hi | omaha_high | 1st board card PRE_FLOP 공개 |
| 12 | Flop | Courchevel Hi-Lo | 5 | Hi/Lo | omaha_hilo | 8-or-better + 1st card 공개 |
| 13 | Draw | Five Card Draw | 5 | Hi | standard_high | 교환 1회, 0~3장 |
| 14 | Draw | 2-7 Single Draw | 5 | Lo | deuce_to_seven | Lowball, 교환 1회 |
| 15 | Draw | 2-7 Triple Draw | 5 | Lo | deuce_to_seven | Lowball, 교환 3회 |
| 16 | Draw | A-5 Triple Draw | 5 | Lo | ace_to_five | Lowball (Ace low), 교환 3회 |
| 17 | Draw | Badugi | 4 | Lo | badugi | 4장 게임, 교환 3회 |
| 18 | Draw | Badeucy | 5 | Hi/Lo | badeucy | Badugi + 2-7, 교환 3회 |
| 19 | Draw | Badacey | 5 | Hi/Lo | badacey | Badugi + A-5, 교환 3회 |
| 20 | Stud | 7-Card Stud | 7 | Hi | standard_high | Up/Down 카드 순서 |
| 21 | Stud | 7-Card Stud Hi-Lo | 7 | Hi/Lo | stud_hilo | 8-or-better |
| 22 | Stud | Razz | 7 | Lo | ace_to_five | Lowball only |

---

## §2 Flop 계열 매트릭스 (12종)

### Flop 시나리오 교차 매트릭스

| 게임 | 정상 | All-In | Miss Deal | Run It Twice | Bomb Pot | Hi/Lo Split |
|------|:----:|:------:|:---------:|:------------:|:--------:|:-----------:|
| Texas Hold'em | TC-G1-010-01 | TC-G1-010-02 | TC-G1-010-03 | TC-G1-010-04 | TC-G1-010-05 | N/A |
| 6+ Hold'em (S>T) | TC-G1-010-06 | TC-G1-010-07 | TC-G1-010-08 | TC-G1-010-09 | TC-G1-010-10 | N/A |
| 6+ Hold'em (T>S) | TC-G1-010-11 | TC-G1-010-12 | TC-G1-010-13 | TC-G1-010-14 | TC-G1-010-15 | N/A |
| Pineapple | TC-G1-010-16 | TC-G1-010-17 | TC-G1-010-18 | TC-G1-010-19 | TC-G1-010-20 | N/A |
| Omaha | TC-G1-011-01 | TC-G1-011-02 | TC-G1-011-03 | TC-G1-011-04 | TC-G1-011-05 | N/A |
| Omaha Hi-Lo | TC-G1-011-06 | TC-G1-011-07 | TC-G1-011-08 | TC-G1-011-09 | TC-G1-011-10 | TC-G1-011-11 |
| 5Card Omaha | TC-G1-011-12 | TC-G1-011-13 | TC-G1-011-14 | TC-G1-011-15 | TC-G1-011-16 | N/A |
| 5Card Omaha Hi-Lo | TC-G1-011-17 | TC-G1-011-18 | TC-G1-011-19 | TC-G1-011-20 | TC-G1-011-21 | TC-G1-011-22 |
| 6Card Omaha | TC-G1-012-01 | TC-G1-012-02 | TC-G1-012-03 | TC-G1-012-04 | TC-G1-012-05 | N/A |
| 6Card Omaha Hi-Lo | TC-G1-012-06 | TC-G1-012-07 | TC-G1-012-08 | TC-G1-012-09 | TC-G1-012-10 | TC-G1-012-11 |
| Courchevel | TC-G1-012-12 | TC-G1-012-13 | TC-G1-012-14 | TC-G1-012-15 | TC-G1-012-16 | N/A |
| Courchevel Hi-Lo | TC-G1-012-17 | TC-G1-012-18 | TC-G1-012-19 | TC-G1-012-20 | TC-G1-012-21 | TC-G1-012-22 |

> **Run It Twice**: Flop 계열만 적용. Draw/Stud는 N/A.
> **Hi/Lo Split**: Omaha Hi-Lo, 5Card Omaha Hi-Lo, 6Card Omaha Hi-Lo, Courchevel Hi-Lo만 해당.

### 변형 파라미터 요약

| TC ID | 요약 |
|-------|------|
| TC-G1-010-01 | 2장 홀카드, 표준 5보드, standard_high evaluator |
| TC-G1-010-02 | Hold'em All-In — side pot 생성, 남은 보드 전개 |
| TC-G1-010-03 | Hold'em Miss Deal — 핸드 무효, pot 반환 |
| TC-G1-010-04 | Hold'em Run It Twice — 2개 보드 독립 평가, pot 50/50 분할 |
| TC-G1-010-05 | Hold'em Bomb Pot — PRE_FLOP 전원 강제 베팅, FLOP부터 액션 |
| TC-G1-010-06 | 6+ (S>T) — 36장 덱, Flush > Full House, Straight > Trips |
| TC-G1-010-07~10 | 6+ (S>T) 예외 시나리오 — 36장 덱 유지 검증 |
| TC-G1-010-11 | 6+ (T>S) — 36장 덱, Trips > Straight |
| TC-G1-010-12~15 | 6+ (T>S) 예외 시나리오 — ranking 역전 검증 |
| TC-G1-010-16 | Pineapple — 3장 딜, FLOP 후 1장 discard, 2장으로 평가 |
| TC-G1-010-17~20 | Pineapple 예외 — discard 전/후 All-In 타이밍 검증 |
| TC-G1-011-01 | Omaha — 4장 홀카드, 반드시 2장 사용 규칙 |
| TC-G1-011-02~05 | Omaha 예외 — 2장 사용 규칙 유지 검증 |
| TC-G1-011-06 | Omaha Hi-Lo — 4장 홀카드, Hi/Lo 8-or-better 분할 |
| TC-G1-011-07~11 | Omaha Hi-Lo 예외 + Hi/Lo Split — Lo 미달 시 Hi 독식 검증 |
| TC-G1-011-12 | 5Card Omaha — 5장 홀카드, 반드시 2장 사용 |
| TC-G1-011-13~16 | 5Card Omaha 예외 — 5장 중 2장 선택 조합 검증 |
| TC-G1-011-17 | 5Card Omaha Hi-Lo — 5장 홀카드, Hi/Lo 8-or-better |
| TC-G1-011-18~22 | 5Card Omaha Hi-Lo 예외 + Hi/Lo Split |
| TC-G1-012-01 | 6Card Omaha — 6장 홀카드, 반드시 2장 사용 |
| TC-G1-012-02~05 | 6Card Omaha 예외 — 6장 중 2장 선택 조합 검증 |
| TC-G1-012-06 | 6Card Omaha Hi-Lo — 6장 홀카드, Hi/Lo 8-or-better |
| TC-G1-012-07~11 | 6Card Omaha Hi-Lo 예외 + Hi/Lo Split |
| TC-G1-012-12 | Courchevel — 5장 홀카드, PRE_FLOP에 1st board card 공개 |
| TC-G1-012-13~16 | Courchevel 예외 — 1st board card 공개 타이밍 검증 |
| TC-G1-012-17 | Courchevel Hi-Lo — 5장 홀카드, Hi/Lo + 1st card 공개 |
| TC-G1-012-18~22 | Courchevel Hi-Lo 예외 + Hi/Lo Split |

---

### 대표 TC 상세 (Flop 계열)

### TC-G1-010-01: Texas Hold'em 정상 핸드

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 3 |
| **우선순위** | P2 |
| **Players** | 6인 (P0~P5), stack=10000, BB=100, SB=50, Dealer=P0 |
| **Hole Cards** | P0: As Kd, P1: Qh Jh, P2: 9c 8c, P3: 7s 6s, P4: Td Tc, P5: 2h 3d |
| **Board** | Ks 9h 4d 7c 2s |
| **Actions** | PRE_FLOP: P3 Call(100) → P4 Raise(300) → P5 Fold → P0 Call(300) → P1 Fold → P2 Call(300) → P3 Call(300). FLOP: P2 Check → P3 Check → P4 Bet(400) → P0 Call(400) → P2 Fold → P3 Fold. TURN: P4 Check → P0 Bet(800) → P4 Call(800). RIVER: P4 Check → P0 Bet(1500) → P4 Fold |
| **기대 결과** | P0 승리 (pair of Kings, Ace kicker). pot=4200 (PRE_FLOP 1350 + FLOP 1050 + TURN 1600 + RIVER 200 미수금=P4 Fold). game_phase=HAND_COMPLETE. evaluator_type=standard_high |
| **판정 기준** | `winner == P0`, `pot_awarded == pot_total`, `evaluator_type == standard_high`, `hole_cards_count == 2`, `board_count == 5` |
| **참조** | PRD-GAME-01 Texas Hold'em, TEST-03 TC-01 |

### TC-G1-011-01: Omaha 정상 핸드

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 3 |
| **우선순위** | P2 |
| **Players** | 6인 (P0~P5), stack=10000, BB=100, SB=50, Dealer=P0 |
| **Hole Cards** | P0: As Kd Qh Jc, P1: 9h 8h 7h 6h, P2: Td Tc 5s 4s, P3: Ac Kc 3d 2d, P4: Js Jd 8c 7c, P5: Qs Qd 9s 9d |
| **Board** | Ks 9c 4d Th 2s |
| **Actions** | PRE_FLOP: P3 Raise(300) → P4 Fold → P5 Call(300) → P0 Call(300) → P1 Fold → P2 Call(300) → P3=done. FLOP: P2 Check → P3 Bet(500) → P5 Fold → P0 Call(500) → P2 Fold. TURN: P3 Bet(1000) → P0 Call(1000). RIVER: P3 Check → P0 Bet(2000) → P3 Fold |
| **기대 결과** | P0 승리. Omaha 규칙: **반드시 홀카드 2장 + 보드 3장** 사용. P0 best hand = Kd Qh (홀카드 2장) + Ks Th 9c (보드 3장) = Two Pair (K, T). evaluator_type=omaha_high. hole_cards_count=4 |
| **판정 기준** | `winner == P0`, `evaluator_type == omaha_high`, `hole_cards_used == 2`, `board_cards_used == 3`, `hole_cards_count == 4` |
| **참조** | PRD-GAME-01 Omaha |

> **핵심 검증**: P0가 As Kd Qh Jc 중 3장 이상을 사용하면 규칙 위반. evaluator는 반드시 홀카드 2장만 선택해야 한다.

### TC-G1-012-12: Courchevel 정상 핸드

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 3 |
| **우선순위** | P2 |
| **Players** | 6인 (P0~P5), stack=10000, BB=200, SB=100, Dealer=P0 |
| **Hole Cards** | P0: As Kd Qh Jc 9s, P1: Td Tc 8h 7h 6d, P2: Ac Ad 5s 4s 3c, P3: Ks Kc 8c 7c 2d, P4: Qs Qd Jd Ts 5c, P5: 9h 9d 8s 6s 4d |
| **Board** | **PRE_FLOP 공개: Ah** → FLOP: Ah Kh 3d → TURN: Ah Kh 3d 7s → RIVER: Ah Kh 3d 7s 2h |
| **Actions** | PRE_FLOP (1st board card Ah 공개 상태): P3 Raise(600) → P4 Fold → P5 Fold → P0 Call(600) → P1 Fold → P2 Call(600) → P3=done. FLOP: P2 Bet(800) → P3 Call(800) → P0 Call(800). TURN: P2 Check → P3 Bet(1500) → P0 Fold → P2 Call(1500). RIVER: P2 Bet(3000) → P3 Fold |
| **기대 결과** | P2 승리. Courchevel 규칙: 5장 홀카드, PRE_FLOP에 보드 1st card 공개. evaluator_type=omaha_high (홀카드 2장 + 보드 3장). P2 best hand = Ac Ad (홀카드) + Ah Kh 3d (보드) = Three of a Kind (Aces). game_phase=HAND_COMPLETE |
| **판정 기준** | `winner == P2`, `evaluator_type == omaha_high`, `hole_cards_count == 5`, `hole_cards_used == 2`, `board_cards_used == 3`, `board[0] == Ah` (PRE_FLOP 공개 카드), `board_visible_at_preflop == 1` |
| **참조** | PRD-GAME-01 Courchevel |

> **핵심 검증**: PRE_FLOP 시점에 board[0]이 공개 상태여야 한다. 나머지 보드 카드는 FLOP/TURN/RIVER에서 순차 공개.

---

## §3 Draw 계열 매트릭스 (7종)

### Draw 시나리오 교차 매트릭스

| 게임 | 정상 | All-In | Miss Deal | Bomb Pot | Hi/Lo Split |
|------|:----:|:------:|:---------:|:--------:|:-----------:|
| Five Card Draw | TC-G1-013-01 | TC-G1-013-02 | TC-G1-013-03 | TC-G1-013-04 | N/A |
| 2-7 Single Draw | TC-G1-013-05 | TC-G1-013-06 | TC-G1-013-07 | TC-G1-013-08 | N/A |
| 2-7 Triple Draw | TC-G1-013-09 | TC-G1-013-10 | TC-G1-013-11 | TC-G1-013-12 | N/A |
| A-5 Triple Draw | TC-G1-013-13 | TC-G1-013-14 | TC-G1-013-15 | TC-G1-013-16 | N/A |
| Badugi | TC-G1-013-17 | TC-G1-013-18 | TC-G1-013-19 | TC-G1-013-20 | N/A |
| Badeucy | TC-G1-013-21 | TC-G1-013-22 | TC-G1-013-23 | TC-G1-013-24 | TC-G1-013-25 |
| Badacey | TC-G1-013-26 | TC-G1-013-27 | TC-G1-013-28 | TC-G1-013-29 | TC-G1-013-30 |

> **Run It Twice**: Draw 계열 비적용 (N/A).
> **Hi/Lo Split**: Badeucy, Badacey만 해당.

### 변형 파라미터 요약

| TC ID | 요약 |
|-------|------|
| TC-G1-013-01 | Five Card Draw — 5장 딜, 1회 교환 (0~3장), standard_high evaluator |
| TC-G1-013-02~04 | Five Card Draw 예외 — 교환 전 All-In 시 교환 생략 검증 |
| TC-G1-013-05 | 2-7 Single — 5장 딜, 1회 교환 (0~5장), deuce_to_seven lowball |
| TC-G1-013-06~08 | 2-7 Single 예외 |
| TC-G1-013-09 | 2-7 Triple — 5장 딜, 3회 교환 (0~5장), deuce_to_seven lowball |
| TC-G1-013-10~12 | 2-7 Triple 예외 — 3회 교환 + 4회 베팅 라운드 정합성 |
| TC-G1-013-13 | A-5 Triple — 5장 딜, 3회 교환 (0~5장), ace_to_five lowball |
| TC-G1-013-14~16 | A-5 Triple 예외 — Ace 최저 ranking 검증 |
| TC-G1-013-17 | Badugi — **4장** 딜, 3회 교환 (0~4장), badugi evaluator |
| TC-G1-013-18~20 | Badugi 예외 — 4장 게임 특수 교환 제한 |
| TC-G1-013-21 | Badeucy — 5장 딜, 3회 교환 (0~5장), Badugi + 2-7 복합 평가 |
| TC-G1-013-22~25 | Badeucy 예외 + Hi/Lo Split — Badugi hand vs 2-7 hand 분리 평가 |
| TC-G1-013-26 | Badacey — 5장 딜, 3회 교환 (0~5장), Badugi + A-5 복합 평가 |
| TC-G1-013-27~30 | Badacey 예외 + Hi/Lo Split — Badugi hand vs A-5 hand 분리 평가 |

### 대표 TC 상세 (Draw 계열)

### TC-G1-013-01: Five Card Draw 정상 핸드

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 3 |
| **우선순위** | P2 |
| **Players** | 6인 (P0~P5), stack=5000, BB=50, SB=25, Dealer=P0 |
| **Hole Cards** | P0: As Kd Qh 7c 3s, P1: Td Tc 8h 5s 2d, P2: Jh Jd 9c 6s 4d, P3: Ac Kc 8c 7h 2h, P4: Qs 9s 8s 5h 3c, P5: 6h 6d 6c Ks 4h |
| **Board** | N/A (Draw 게임 — 커뮤니티 카드 없음) |
| **Actions** | PRE_DRAW 베팅: P3(UTG) Call(50) → P4 Fold → P5 Raise(100) → P0 Call(100) → P1 Fold → P2 Call(100) → P3 Call(100). DRAW: P2 교환 2장 (9c, 4d → Ah, Ts) → P3 교환 3장 (8c, 7h, 2h → Jc, 5c, 4c) → P5 교환 0장 (Stand Pat) → P0 교환 3장 (7c, 3s → 결과 N/A — P0 max 3장 교환). POST_DRAW 베팅: P2 Check → P3 Check → P5 Bet(200) → P0 Fold → P2 Fold → P3 Fold |
| **기대 결과** | P5 승리 (Three of a Kind, 6s). pot=800. game_phase=HAND_COMPLETE. evaluator_type=standard_high. draw_rounds=1 |
| **판정 기준** | `winner == P5`, `evaluator_type == standard_high`, `draw_round_count == 1`, `max_discard == 3`, `board == null` |
| **참조** | PRD-GAME-02 Five Card Draw |

---

## §4 Stud 계열 매트릭스 (3종)

### Stud 시나리오 교차 매트릭스

| 게임 | 정상 | All-In | Miss Deal | Bomb Pot | Hi/Lo Split |
|------|:----:|:------:|:---------:|:--------:|:-----------:|
| 7-Card Stud | TC-G1-014-01 | TC-G1-014-02 | TC-G1-014-03 | TC-G1-014-04 | N/A |
| 7-Card Stud Hi-Lo | TC-G1-014-05 | TC-G1-014-06 | TC-G1-014-07 | TC-G1-014-08 | TC-G1-014-09 |
| Razz | TC-G1-014-10 | TC-G1-014-11 | TC-G1-014-12 | TC-G1-014-13 | N/A |

> **Run It Twice**: Stud 계열 비적용 (N/A).
> **Hi/Lo Split**: 7-Card Stud Hi-Lo만 해당.

### 변형 파라미터 요약

| TC ID | 요약 |
|-------|------|
| TC-G1-014-01 | 7-Card Stud — 7장 (2 down + 4 up + 1 down), standard_high evaluator, bring-in |
| TC-G1-014-02~04 | 7-Card Stud 예외 — bring-in + All-In 상호작용 검증 |
| TC-G1-014-05 | 7-Card Stud Hi-Lo — 7장, stud_hilo evaluator, 8-or-better |
| TC-G1-014-06~09 | 7-Card Stud Hi-Lo 예외 + Hi/Lo Split — Lo 미달 시 Hi 독식 |
| TC-G1-014-10 | Razz — 7장, ace_to_five lowball only, 최저 hand 승리 |
| TC-G1-014-11~13 | Razz 예외 — Ace 최저 ranking, pair 불리 검증 |

### 대표 TC 상세 (Stud 계열)

### TC-G1-014-01: 7-Card Stud 정상 핸드

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 3 |
| **우선순위** | P2 |
| **Players** | 4인 (P0~P3), stack=5000, ante=25, bring-in=50, small bet=100, big bet=200 (Fixed Limit) |
| **Hole Cards** | P0: [2d 5h] Ks 9c 7h Td [Kd] — (down/up/down 표기). P1: [Ah Ac] 3s 4d Jh 8c [As] — Three Aces. P2: [Qd 9d] Qs 8s 6d 2s [Qh] — Three Queens. P3: [Jc Js] 7s Tc 5c 3d [4h] — Pair of Jacks |
| **Board** | N/A (Stud 게임 — 커뮤니티 카드 없음, 개인별 7장) |
| **Actions** | 3rd Street: ante 전원 (25x4=100). P0 bring-in(50, 가장 낮은 up card). P1 Complete(100) → P2 Call(100) → P3 Call(100) → P0 Fold. 4th Street: P2 (Qs high) Check → P1 Bet(100) → P2 Call(100) → P3 Fold. 5th Street: P1 (pair 미공개) Bet(200) → P2 Call(200). 6th Street: P1 Bet(200) → P2 Call(200). 7th Street (down): P1 Bet(200) → P2 Call(200) |
| **기대 결과** | P1 승리 (Three of a Kind, Aces). evaluator_type=standard_high. game_type=Fixed Limit Stud. bring_in_player=P0 (lowest up card=5h at 3rd street) |
| **판정 기준** | `winner == P1`, `evaluator_type == standard_high`, `cards_per_player == 7`, `up_cards == [3,4,5,6]` (3rd~6th street), `down_cards == [0,1,6]` (dealt face-down), `bring_in_player == lowest_up_card_player`, `bet_structure == fixed_limit` |
| **참조** | PRD-GAME-03 7-Card Stud |

> **핵심 검증**: Up/Down 카드 순서 — 3rd street: 2 down + 1 up. 4th~6th street: up. 7th street: down. bring-in은 가장 낮은 up card 보유자가 강제.

---

## §5 Draw 카드 교환 매트릭스 (TC-G1-015)

### 교환 규칙 매트릭스

| 게임 | 교환 라운드 | 교환 장수 | Stand Pat | TC ID |
|------|:---------:|:--------:|:---------:|-------|
| Five Card Draw | 1 | 0~3 | 허용 | TC-G1-015-01 |
| 2-7 Single Draw | 1 | 0~5 | 허용 | TC-G1-015-02 |
| 2-7 Triple Draw | 3 | 0~5 | 허용 | TC-G1-015-03 |
| A-5 Triple Draw | 3 | 0~5 | 허용 | TC-G1-015-04 |
| Badugi | 3 | 0~4 | 허용 | TC-G1-015-05 |
| Badeucy | 3 | 0~5 | 허용 | TC-G1-015-06 |
| Badacey | 3 | 0~5 | 허용 | TC-G1-015-07 |

> **Five Card Draw**: PRD-GAME-02 기준 교환 장수 **0~3장** 제한.
> **Badugi**: 4장 게임이므로 교환 장수 **0~4장** 제한.

### 교환 검증 포인트

| 검증 항목 | 설명 | 적용 TC |
|----------|------|--------|
| 교환 장수 제한 초과 거부 | Five Card Draw에서 4장 교환 시도 → 거부 | TC-G1-015-01 |
| Stand Pat 허용 | 0장 교환 요청 → 수락, 핸드 변경 없음 | 전체 |
| 교환 라운드 수 정확성 | 1회 교환 게임에서 2회 교환 시도 → 거부 | TC-G1-015-01, 02 |
| 교환 후 핸드 카드 수 유지 | 교환 전후 hand_size 동일 | 전체 |
| 덱 소진 시 discard pile reshuffle | 교환 카드가 덱 잔여보다 많을 때 | TC-G1-015-03, 06, 07 |

### 대표 TC 상세 (Draw 교환)

### TC-G1-015-01: Five Card Draw 교환 (1라운드, 3장)

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 3 |
| **우선순위** | P2 |
| **Players** | 4인 (P0~P3), stack=3000, BB=50, SB=25, Dealer=P0 |
| **Hole Cards** | P0: As Kd Qh 7c 3s, P1: Td Tc 8h 5s 2d, P2: Jh Jd 9c 6s 4d, P3: Ac 8c 7h 5h 2h |
| **Board** | N/A |
| **Actions** | PRE_DRAW 베팅: P1(SB) Call(50) → P2 Call(50) → P3 Fold → P0 Check. DRAW Round 1: P1 교환 3장 (8h, 5s, 2d → Kc, 9s, 4c) → P2 교환 2장 (6s, 4d → Ah, Ts) → P0 교환 3장 (7c, 3s → 결과에 따라). POST_DRAW 베팅: P1 Bet(100) → P2 Raise(200) → P0 Fold → P1 Call(200) |
| **기대 결과** | P2 승리 (Two Pair, J-T). draw_rounds=1. max_discard=3 검증: P1이 3장 교환 성공, P0이 3장 교환 성공 (최대 허용). evaluator_type=standard_high |
| **판정 기준** | `draw_round_count == 1`, `P1.discarded_count == 3`, `P2.discarded_count == 2`, `P0.discarded_count == 3`, `hand_size_after_draw == 5` (전원), `max_discard_limit == 3` |
| **참조** | PRD-GAME-02 Five Card Draw |

### TC-G1-015-01a: Five Card Draw 교환 제한 초과 거부

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 3 |
| **우선순위** | P2 |
| **Players** | 4인, stack=3000, BB=50, SB=25, Dealer=P0 |
| **Hole Cards** | P0: As Kd Qh 7c 3s (임의) |
| **Board** | N/A |
| **Actions** | DRAW Round 1: P0 교환 시도 4장 (Qh, 7c, 3s, Kd) |
| **기대 결과** | 거부. Five Card Draw 교환 제한 = 0~3장. 4장 이상 교환 요청은 `InvalidDrawError` 발생 |
| **판정 기준** | `error_type == InvalidDrawError`, `draw_executed == false`, `hand_unchanged == true` |
| **참조** | PRD-GAME-02 Five Card Draw |

### TC-G1-015-03: 2-7 Triple Draw 교환 (3라운드, 각 라운드 다른 장수)

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 3 |
| **우선순위** | P2 |
| **Players** | 4인 (P0~P3), stack=3000, small bet=50, big bet=100 (Fixed Limit) |
| **Hole Cards** | P0: 2s 3d 5h 8c Ks, P1: 4d 6h 7s 9c Jd, P2: 2h 3c 4s 7d Qh, P3: 5c 6d 8s Td Kd |
| **Board** | N/A |
| **Actions** | Round 1 베팅 → DRAW 1: P0 교환 1장 (Ks → 4h) → P1 교환 2장 (9c, Jd → Tc, 2c) → P2 교환 1장 (Qh → 8d) → P3 교환 3장 (Td, Kd, 8s → As, 9h, 3h). Round 2 베팅 → DRAW 2: P0 Stand Pat (0장) → P1 교환 1장 (Tc → 5d) → P2 Stand Pat (0장) → P3 교환 2장 (As, 9h → 7c, Jc). Round 3 베팅 → DRAW 3: P0 Stand Pat → P1 Stand Pat → P2 Stand Pat → P3 교환 1장 (Jc → 9d). Final 베팅 → Showdown |
| **기대 결과** | 2-7 Lowball evaluator 적용. P0: 2-3-4-5-8 (best low). P2: 2-3-4-7-8. P0 승리. draw_rounds=3. 각 라운드별 교환 장수 독립 검증 |
| **판정 기준** | `draw_round_count == 3`, `evaluator_type == deuce_to_seven`, `betting_rounds == 4` (pre-draw + 3 post-draw), `max_discard_limit == 5`, 각 라운드 `hand_size == 5` 유지 |
| **참조** | PRD-GAME-02 2-7 Triple Draw |

> **핵심 검증**: 3회 교환 라운드마다 독립적으로 교환 장수를 결정할 수 있으며, Stand Pat과 혼합 가능. 베팅 라운드는 총 4회 (1 pre-draw + 3 post-draw).

---

## 전체 TC 통계

| 계열 | 매트릭스 TC 수 | 풀 fixture TC | Phase | 우선순위 |
|:----:|:----------:|:----------:|:-----:|:------:|
| Flop (12종) | 72 | 3 | Phase 3 | P2 |
| Draw (7종) | 30 | 1 | Phase 3 | P2 |
| Stud (3종) | 13 | 1 | Phase 3 | P2 |
| Draw 교환 (7종) | 7 + 서브케이스 | 2 | Phase 3 | P2 |
| **합계** | **122+** | **7** | | |

> 나머지 TC는 매트릭스 + 변형 파라미터 요약으로 Phase 3 확장 시 fixture 추가.

---

## 코드 리뷰 발견 TC (2026-04-09)

### TC-G1-012-12a: Courchevel — Preflop 공개 카드 강제 사용 검증

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 3 |
| **우선순위** | P2 |
| **Known Issue** | KI-07 — `courchevel.dart` L35 `bestOmaha`가 C(5,3) 자유 선택, preflop 카드 미강제 |
| **Players** | 2인, P0(5000), P1(5000), BB=100, game=Courchevel |
| **Hole Cards** | P0: `As Kd Qh Jc 9s` (5장) |
| **Board** | `2h 7d Tc 5s 8c` (2h = preflop 공개 카드) |
| **기대 결과** | P0의 best hand 평가 시 community 3장 선택에 `2h` (preflop card) 반드시 포함. `bestOmaha`가 `2h` 미포함 조합 (`7d Tc 5s` 등)을 허용하면 안 됨 |
| **판정 기준** | `selectedCommunity.contains(board[0])` == true (모든 평가 조합에서) |
| **참조** | BS-06-14 §Courchevel, PRD-GAME-01 §Courchevel |

> **버그 원인**: `bestOmaha`는 generic Omaha evaluator로, Courchevel 고유 규칙(preflop 카드 강제)을 모름. Courchevel 전용 evaluator 또는 community 필터 추가 필요.
