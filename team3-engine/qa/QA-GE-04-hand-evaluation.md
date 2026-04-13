# QA-GE-04 — 핸드 평가 검증

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Master Plan §8.5 + §8.5.1 확장 — 핸드 평가 + Hi/Lo Split TC 상세화 |
| 2026-04-09 | TC 추가 | 코드 리뷰 발견: TC-G1-005-13~15 (Short Deck Wheel, Hi/Lo Odd Chip) |

---

## 개요

Game Engine의 핸드 평가 알고리즘을 검증한다. standard_high evaluator 기반 승자 결정, Split Pot, Kicker 비교, Hi/Lo Split 게임 7종의 Lo 판정 규칙을 포함한다.

---

## HandRank 표준 (standard_high)

| Rank | 이름 | 예시 |
|:--:|------|------|
| 0 | HighCard | A♠K♥Q♦J♣9♠ |
| 1 | Pair | K♠K♥Q♦J♣9♠ |
| 2 | TwoPair | K♠K♥Q♦Q♣9♠ |
| 3 | Trips | K♠K♥K♦Q♣J♠ |
| 4 | Straight | K♠Q♥J♦T♣9♠ |
| 5 | Flush | K♠Q♠J♠9♠7♠ |
| 6 | FullHouse | K♠K♥K♦Q♣Q♠ |
| 7 | Quads | K♠K♥K♦K♣J♠ |
| 8 | StraightFlush | T♠9♠8♠7♠6♠ |
| 9 | RoyalFlush | A♠K♠Q♠J♠T♠ |

---

## TC 목록

### TC-G1-005-01: 일반 승자 결정

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 1 |
| **우선순위** | P0 |
| **Players** | 3인, P0(5000), P1(5000), P2(5000), BB=100, SB=50, Dealer=P0 |
| **Hole Cards** | P0: `As Ks` (HighCard Ace), P1: `Qd Qh` (Pair Queens), P2: `7c 2d` (HighCard 7) |
| **Board** | `Jh Td 5c 3s 2h` |
| **Actions** | PRE_FLOP: P1 Call → P2 Call → P0 Check. FLOP~RIVER: 전원 Check |
| **기대 결과** | 승자 = P1 (Pair of Queens). HandRank: P0=HighCard(0), P1=Pair(1), P2=Pair(1, 2s+2h). P1 Pair Q > P2 Pair 2. P1 전체 팟 획득 |
| **판정 기준** | `winner == [P1]`, `P1.handRank == 1`, `P0.handRank == 0`, `P2.handRank == 1`, `P1.bestFive[0].rank > P2.bestFive[0].rank` |
| **참조** | BS-06-05 §HandRank |

### TC-G1-005-02: Split Pot — 동점 균등 분배

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 1 |
| **우선순위** | P0 |
| **Players** | 2인, P0(5000), P1(5000), BB=100, SB=50, Dealer=P0(=SB) |
| **Hole Cards** | P0: `As Kd`, P1: `Ah Kc` |
| **Board** | `Qs Jd Td 8c 3h` |
| **Actions** | PRE_FLOP: P0 Raise(200) → P1 Call. FLOP~RIVER: 전원 Check |
| **기대 결과** | 양측 동일 핸드 (A-K-Q-J-T Straight). Pot=400, Split Pot 균등 분배: P0 200, P1 200. Odd chip 없음 |
| **판정 기준** | `winners == [P0, P1]`, `pots[0].splitCount == 2`, `P0.awarded == P1.awarded == 200` |
| **참조** | BS-06-05 §Tiebreaker |

### TC-G1-005-02a: 3인 Split Pot + Odd Chip

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 3인, P0(5000), P1(5000), P2(5000), BB=100, SB=50, Dealer=P0 |
| **Hole Cards** | P0: `As 4d`, P1: `Ah 4c`, P2: `Ad 4s` |
| **Board** | `Ks Qs Js Ts 3h` |
| **Actions** | PRE_FLOP: P1 Call → P2 Call → P0 Check. FLOP: P0 Bet(100) → P1 Call → P2 Call. TURN~RIVER: 전원 Check |
| **기대 결과** | 전원 동일 Straight (A-K-Q-J-T). Pot=600. 600 / 3 = 200 균등. Odd chip 없음 |
| **판정 기준** | `winners == [P0, P1, P2]`, 3등분. Odd chip 발생 시 Dealer 좌측 첫 eligible 플레이어에게 배정 |
| **참조** | BS-06-05 §OddChip |

### TC-G1-005-03: Hi/Lo Split — Omaha Hi-Lo

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 2인, P0(5000), P1(5000), BB=100, SB=50, Dealer=P0(=SB). game_type=OmahaHiLo |
| **Hole Cards** | P0: `As 2d 3c Kh` (4장), P1: `Ks Kd Qh Jc` (4장) |
| **Board** | `5h 7d 9s Tc 4c` |
| **Actions** | PRE_FLOP: P0 Call → P1 Check. FLOP~RIVER: 전원 Check |
| **기대 결과** | Hi: P1 (K-K pair, 정확히 2장 사용). Lo: P0 (A-2-3-4-5, 8-or-better 충족). Pot=200, Hi 50% → P1(100), Lo 50% → P0(100) |
| **판정 기준** | `hiWinner == [P1]`, `loWinner == [P0]`, `P0.awarded == 100`, `P1.awarded == 100`, `loHand == [5,4,3,2,1]` (A=1) |
| **참조** | BS-06-05 §Hi/Lo |

### TC-G1-005-04: Lo 조건 미충족

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 2인, P0(5000), P1(5000), BB=100, SB=50, Dealer=P0(=SB). game_type=OmahaHiLo |
| **Hole Cards** | P0: `Ks Kd 9h 8c` (4장), P1: `Qs Qd Jh Tc` (4장) |
| **Board** | `Kh Qc Js 9d 9c` |
| **Actions** | PRE_FLOP: P0 Raise(200) → P1 Call. FLOP~RIVER: 전원 Check |
| **기대 결과** | Hi: P0 (Full House K-K-K-9-9). Lo: 없음 (전원 8-or-better 미충족). P0이 전체 팟 획득 |
| **판정 기준** | `hiWinner == [P0]`, `loWinner == null`, `loQualified == false`, P0 전액 수령 |
| **참조** | BS-06-05 §Hi/Lo |

### TC-G1-005-05: Kicker 비교

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 1 |
| **우선순위** | P0 |
| **Players** | 2인, P0(5000), P1(5000), BB=100, SB=50, Dealer=P0(=SB) |
| **Hole Cards** | P0: `As 9d`, P1: `Ah 8c` |
| **Board** | `Ac 7h 5d 3s 2c` |
| **Actions** | PRE_FLOP: P0 Raise(200) → P1 Call. FLOP~RIVER: 전원 Check |
| **기대 결과** | 양측 Pair of Aces. P0 kicker 9 > P1 kicker 8. P0 승 |
| **판정 기준** | `winner == [P0]`, `P0.handRank == P1.handRank == 1`, `P0.kickers[0] == 9`, `P1.kickers[0] == 8` |
| **참조** | BS-06-05 §Tiebreaker |

### TC-G1-005-05a: 동일 Kicker — 두번째 Kicker 결정

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 2인, P0(5000), P1(5000), BB=100, SB=50, Dealer=P0(=SB) |
| **Hole Cards** | P0: `As 9d`, P1: `Ah 9c` |
| **Board** | `Ac Kh 7d 4s 2c` |
| **Actions** | PRE_FLOP: P0 Raise(200) → P1 Call. FLOP~RIVER: 전원 Check |
| **기대 결과** | 양측 Pair of Aces, 1st kicker K (공유), 2nd kicker 9 (동일), 3rd kicker 7 (공유), 4th kicker 4 (공유). 완전 동점 → Split Pot |
| **판정 기준** | `winners == [P0, P1]`, 5장 best hand 완전 동일 시 Split |
| **참조** | BS-06-05 §Tiebreaker |

---

## §8.5.1 Hi/Lo Split 게임 Lo 판정 매트릭스

| 게임 | Lo 규칙 | Lo 미충족 시 | 홀카드 장수 | TC ID | Phase |
|------|---------|------------|:----------:|-------|-------|
| Omaha Hi-Lo | 8-or-better | Hi만 수상 | 4 | TC-G1-005-06 | P2 |
| 5Card Omaha Hi-Lo | 8-or-better | Hi만 수상 | 5 | TC-G1-005-07 | P2 |
| 6Card Omaha Hi-Lo | 8-or-better | Hi만 수상 | 6 | TC-G1-005-08 | P2 |
| Courchevel Hi-Lo | 8-or-better | Hi만 수상 | 5 | TC-G1-005-09 | P2 |
| 7-Card Stud Hi-Lo | 8-or-better | Hi만 수상 | 7 | TC-G1-005-10 | P2 |
| Badeucy | Badugi + 2-7 | 항상 분할 | 5 | TC-G1-005-11 | P2 |
| Badacey | Badugi + A-5 | 항상 분할 | 5 | TC-G1-005-12 | P2 |

### TC-G1-005-06: Omaha Hi-Lo — Lo 충족 + Lo 미충족

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P2 |
| **Players** | 2인, P0(5000), P1(5000), BB=100, SB=50, Dealer=P0(=SB). game_type=OmahaHiLo |
| **Hole Cards** | P0: `As 2d 3c Kh` (4장), P1: `Qs Qd Jh Tc` (4장) |
| **Board** | `5h 7d 4c Ks 9s` |
| **Actions** | PRE_FLOP~RIVER: 전원 Check |
| **기대 결과** | **Lo 충족**: P0 Lo hand = A-2-3-4-5 (8-or-better). Hi: P1 (Q-Q pair) vs P0 (K-K pair) → P0 Hi 승. Lo: P0 수상. P0이 Hi+Lo 양쪽 수상(scoop) |
| **판정 기준** | `loQualified == true`, `loWinner == [P0]`, `hiWinner == [P0]` |
| **참조** | BS-06-05 §Hi/Lo |

**TC-G1-005-06 Lo 미충족 서브케이스**: Board `Kh Qs Jd 9c Ts`, 전원 Lo 불가 → Hi 승자만 전액 수령

### TC-G1-005-07: 5Card Omaha Hi-Lo — Lo 충족 + Lo 미충족

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P2 |
| **Players** | 2인, P0(5000), P1(5000), BB=100, SB=50, Dealer=P0(=SB). game_type=5CardOmahaHiLo |
| **Hole Cards** | P0: `As 2d 3c 6h 8d` (5장), P1: `Ks Kd Qh Jc Tc` (5장) |
| **Board** | `4h 7d 9s Ts 2c` |
| **Actions** | PRE_FLOP~RIVER: 전원 Check |
| **기대 결과** | **Lo 충족**: P0 Lo hand = A-2-3-4-7 (정확히 2장 사용). Hi: P1 승. Pot 50/50 분할 |
| **판정 기준** | `loQualified == true`, 홀카드 5장 중 정확히 2장만 사용 검증 |
| **참조** | BS-06-05 §Hi/Lo |

**TC-G1-005-07 Lo 미충족 서브케이스**: Board `Kh Qs Jd 9c Ts` → Hi만 수상

### TC-G1-005-08: 6Card Omaha Hi-Lo — Lo 충족 + Lo 미충족

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P2 |
| **Players** | 2인, P0(5000), P1(5000), BB=100, SB=50, Dealer=P0(=SB). game_type=6CardOmahaHiLo |
| **Hole Cards** | P0: `As 2d 3c 6h 8d 9h` (6장), P1: `Ks Kd Qh Jc Tc 4d` (6장) |
| **Board** | `4h 7d 5s Ts 2c` |
| **Actions** | PRE_FLOP~RIVER: 전원 Check |
| **기대 결과** | **Lo 충족**: P0 Lo hand = A-2-3-4-5 (정확히 2장 사용). Hi: 판정 후 승자 결정. Pot Hi/Lo 50/50 |
| **판정 기준** | `loQualified == true`, 홀카드 6장 중 정확히 2장만 사용 검증 |
| **참조** | BS-06-05 §Hi/Lo |

**TC-G1-005-08 Lo 미충족 서브케이스**: Board `Kh Qs Jd 9c Ts` → Hi만 수상

### TC-G1-005-09: Courchevel Hi-Lo — Lo 충족 + Lo 미충족

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P2 |
| **Players** | 2인, P0(5000), P1(5000), BB=100, SB=50, Dealer=P0(=SB). game_type=CourchevelHiLo |
| **Hole Cards** | P0: `As 2d 3c 7h 8d` (5장), P1: `Ks Kd Qh Jc Tc` (5장) |
| **Board** | `4h 5d 9s Ts 2c` (첫 FLOP 카드 1장 PRE_FLOP 공개) |
| **Actions** | PRE_FLOP(1장 공개): 전원 Check. FLOP~RIVER: 전원 Check |
| **기대 결과** | **Lo 충족**: P0 Lo hand = A-2-3-4-5 (정확히 2장 사용). Pot Hi/Lo 50/50 |
| **판정 기준** | `loQualified == true`, Courchevel 1장 공개 메커니즘 정상 동작 |
| **참조** | BS-06-05 §Hi/Lo |

**TC-G1-005-09 Lo 미충족 서브케이스**: Board `Kh Qs Jd 9c Ts` → Hi만 수상

### TC-G1-005-10: 7-Card Stud Hi-Lo — Lo 충족 + Lo 미충족

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P2 |
| **Players** | 2인, P0(5000), P1(5000), ante=25, bring-in=50 |
| **Hole Cards** | P0: `As 2d / 3c 4h 7d / 5s 8h` (3 down + 4 up), P1: `Ks Kd / Qh Jc Tc / 9s 8c` (3 down + 4 up) |
| **Board** | 없음 (Stud — 커뮤니티 카드 없음) |
| **Actions** | 3rd Street ~ 7th Street: 전원 Check/Call |
| **기대 결과** | **Lo 충족**: P0 best Lo = A-2-3-4-5 (8-or-better). Hi: P1 (K-K pair). Pot Hi/Lo 50/50 |
| **판정 기준** | `loQualified == true`, 7장 중 best 5장 Lo 판정, Stud 고유 betting round 정상 동작 |
| **참조** | BS-06-05 §Hi/Lo |

**TC-G1-005-10 Lo 미충족 서브케이스**: P0 `Ks Qd / Js Tc 9h / 8s 7c` — 전원 Lo 불가 → Hi만 수상

### TC-G1-005-11: Badeucy — 항상 분할 (Badugi + 2-7 Lowball)

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P2 |
| **Players** | 2인, P0(5000), P1(5000), BB=100, SB=50, Dealer=P0(=SB). game_type=Badeucy |
| **Hole Cards** | P0: `As 2d 3c 7h 6s` (5장), P1: `4s 5d 8c Kh Qs` (5장) |
| **Board** | 없음 (Draw 게임) |
| **Actions** | Draw round 1~3: P0 Stand Pat, P1 Draw 2 |
| **기대 결과** | Badugi 판정: P0 (A-2-3-7, 4장 Badugi) > P1. 2-7 Lowball 판정: P0 (7-6-3-2-A → A high = 불리) vs P1 (K-Q-8-5-4 → K high). P1 2-7 승. **항상 분할**: Badugi→P0, 2-7→P1. Pot 50/50 |
| **판정 기준** | `badugiWinner == [P0]`, `lowballWinner == [P1]`, 항상 양쪽 판정 수행, Lo 미충족 개념 없음 |
| **참조** | BS-06-05 §Badeucy |

### TC-G1-005-12: Badacey — 항상 분할 (Badugi + A-5 Lowball)

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P2 |
| **Players** | 2인, P0(5000), P1(5000), BB=100, SB=50, Dealer=P0(=SB). game_type=Badacey |
| **Hole Cards** | P0: `As 2d 3c 5h 7s` (5장), P1: `4s 6d 8c Kh Qs` (5장) |
| **Board** | 없음 (Draw 게임) |
| **Actions** | Draw round 1~3: P0 Stand Pat, P1 Draw 2 |
| **기대 결과** | Badugi 판정: P0 (A-2-3-5, 4장 Badugi) > P1. A-5 Lowball 판정: P0 (A-2-3-5-7 = 7 low) vs P1 (4-6-8-K-Q = K high). P0 A-5 승. **항상 분할**: Badugi→P0, A-5→P0. P0 scoop |
| **판정 기준** | `badugiWinner == [P0]`, `lowballWinner == [P0]`, 양쪽 동일 승자 시 전액 수령(scoop) |
| **참조** | BS-06-05 §Badacey |

---

## 코드 리뷰 발견 TC (2026-04-09)

### TC-G1-005-13: Short Deck Wheel (A-6-7-8-9) 스트레이트 검증

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 1 |
| **우선순위** | P0 |
| **Known Issue** | KI-01 — `hand_evaluator.dart` L284 `_checkStraight` wheel 분기가 Short Deck 최소 랭크(6)를 미인식 |
| **Players** | 2인, P0(5000), P1(5000), BB=100, game=6+ Hold'em |
| **Hole Cards** | P0: `As 6h`, P1: `Kd Qc` |
| **Board** | `7d 8c 9s 2c 3h` (Short Deck이므로 2,3 제외 — 실제 테스트 시 `Jh Tc`로 대체 필요) |
| **기대 결과** | P0: Straight (A-6-7-8-9, 9-high). 현재 구현: HighCard로 오판 |
| **판정 기준** | `handRank == HandCategory.straight`, `highCard == 9` |
| **참조** | BS-06-11 §Short Deck Straight, `hand_evaluator.dart` L284-292 |

> **버그 원인**: `lowValues = [1, 6, 7, 8, 9]` → `_isConsecutiveAsc` 실패 (`6-1=5≠1`). Ace를 1로 치환하는 wheel 로직이 Short Deck의 최소 랭크(6)를 고려하지 않음.

### TC-G1-005-14: Short Deck Steel Wheel (A-6-7-8-9 동일 수트) StraightFlush 검증

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 1 |
| **우선순위** | P0 |
| **Known Issue** | KI-01 연장 |
| **Players** | 2인, P0(5000), P1(5000), BB=100, game=6+ Hold'em |
| **Hole Cards** | P0: `As 6s`, P1: `Kd Qd` |
| **Board** | `7s 8s 9s Jh Tc` |
| **기대 결과** | P0: StraightFlush (A♠-6♠-7♠-8♠-9♠). 현재 구현: Flush(Ace-high)로 오판 |
| **판정 기준** | `handRank == HandCategory.straightFlush` |
| **참조** | BS-06-11 §Short Deck Straight |

### TC-G1-005-15: Hi/Lo Odd Pot — Hi에게 Odd Chip 할당

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 1 |
| **우선순위** | P0 |
| **Known Issue** | KI-02 — `showdown.dart` L77 `hiHalf = potAmount ~/ 2` (floor) → Hi가 작은 쪽 수령 |
| **Players** | 2인, P0(5000), P1(5000), BB=100, game=Omaha Hi-Lo |
| **Hole Cards** | P0: `As 2d 7c Kh` (Lo 자격), P1: `Ks Kd Qh Jc` (Hi only) |
| **Board** | `5h 8d 9s Tc 4c` |
| **Actions** | P0 Bet(100), P1 Call → Showdown |
| **기대 결과** | pot=301 (odd). Hi=P1 → **151칩**, Lo=P0 → **150칩**. 현재 구현: Hi=150, Lo=151 (반대) |
| **판정 기준** | `awards[P1] == 151`, `awards[P0] == 150` (TDA/WSOP odd chip → Hi 규칙) |
| **참조** | BS-06-05 §Hi/Lo Split, TDA Rule 15 |
