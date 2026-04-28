---
title: Variants & Evaluation — Domain Master
owner: team3
tier: contract
legacy-ids:
  - BS-06-05    # Holdem/Evaluation.md (standard_high evaluator + 7-2 Side Bet)
  - BS-06-08    # Holdem/Exceptions.md (7 예외 + Boxed Card + Four-Card Flop + Deck Change)
  - BS-06-1X    # Flop_Variants.md (Short Deck/Pineapple/Omaha/Courchevel 통합)
  - BS-06-2X    # Draw_Games.md (Draw 7종 — draw5/27_*/A5/Badugi/Badeucy/Badacey)
  - BS-06-3X    # Stud_Games.md (Stud 3종 — stud7/Hi-Lo/Razz)
  - "Hand Evaluation Reference v1.1"   # Evaluation_Reference.md (25 게임 × 9 조합 × 7 룰)
last-updated: 2026-04-28
related:
  - "Behavioral_Specs/Lifecycle_and_State_Machine.md"      # Phase 1 (HandFSM)
  - "Behavioral_Specs/Triggers_and_Event_Pipeline.md"      # Phase 2 (IE/IT/OE)
  - "Behavioral_Specs/Betting_and_Pots.md"                 # Phase 3 (Side Pot/Showdown)
---

# Variants & Evaluation — Domain Master

> **존재 이유**: Hold'em 외 Variants (Short Deck / Pineapple / Omaha / Courchevel / Draw 7종 / Stud 3종) 의 게임별 차이점 + 통합 Hand Evaluation 체계 (25 게임 × 9 조합 × 7 룰) + 예외 처리 (Miss Deal / Boxed Card / Four-Card Flop / Deck Change / RFID Failure 등) 를 단일 SSOT 로 통합. 6 입력 문서를 zero information loss 로 병합. 상태 전이 / 트리거 / 베팅 / 팟 분배는 다른 도메인 마스터가 권위.

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-06 | BS-06-05 신규 | standard_high evaluator + 7-2 Side Bet |
| 2026-04-06 | BS-06-08 신규 | 7 예외 (All Fold / All-in Runout / Bomb Pot / RIT / Miss Deal / RFID Failure / Card Mismatch) |
| 2026-04-09 | BS-06-08 GAP-GE-002 | Miss Deal ante 반환 ante_type 별 분기 |
| 2026-04-10 | BS-06-08 WSOP P1/P2 | Four-Card Flop 복구 (Rule 89), Deck Change (Rule 78), Boxed Card (Rule 88) |
| 2026-04-13 | BS-06-05 GAP-D | 입/출 예시 5건 (Short Deck Wheel 주의) |
| 2026-04-14 | BS-06-1X 통합 | BS-06-11/12/13/14 → 단일 Flop_Variants.md (Short Deck/Pineapple/Omaha/Courchevel) |
| 2026-04-14 | BS-06-2X 통합 | BS-06-21 + 22 → Draw_Games.md (라이프사이클 + 평가) |
| 2026-04-14 | BS-06-3X 통합 | BS-06-31 + 32 → Stud_Games.md (라이프사이클 + 평가) |
| 2026-04-17 | Evaluation_Reference v1.1 | 25 게임 × 9 조합 × 7 룰 통합 레퍼런스 |
| 2026-04-28 | 도메인 통합 (본 문서) | 6 입력 lossless 병합. legacy-ids 보존. Lifecycle/Triggers/Betting 권위 위임. Chunk-by-chunk commit (sibling worktree). |

---

## 1. Overview & Definitions

### 1.1 도메인 정의

본 도메인은 **게임 종류별 차이점 + 핸드 평가 알고리즘 + Hold'em 일반 흐름을 벗어나는 예외 처리** 를 통합한다:

1. **Hand Evaluation 통합 레퍼런스** (Evaluation_Reference): 25 게임 → 7 룰 (R1~R7) → 9 조합 (C1~C9) 체계
2. **Hold'em 평가** (BS-06-05): standard_high evaluator + 7-2 Side Bet
3. **Flop Variants** (BS-06-1X): Short Deck / Pineapple / Omaha / Courchevel — Hold'em 대비 차이
4. **Draw Games** (BS-06-2X): 7종 (draw5 / 2-7 SD/TD / A-5 TD / Badugi / Badeucy / Badacey)
5. **Stud Games** (BS-06-3X): 3종 (stud7 / stud7_hilo8 / Razz)
6. **Exceptions** (BS-06-08): All Fold / All-in Runout / Bomb Pot / Run It Twice / Miss Deal / RFID Failure / Card Mismatch + Boxed Card / Four-Card Flop / Deck Change

상태 전이 (Lifecycle), 이벤트 파이프라인 (Triggers), 칩 흐름 (Betting & Pots) 는 별도 도메인 권위.

### 1.2 핵심 개념 정의

#### 1.2.1 Hand Evaluation (Evaluation_Reference)

**핸드 평가** = 25 게임에서 승자를 결정하는 알고리즘. 3 차원 직교:

1. **승리 룰** (R1~R7): "누가 이기나" — Standard Hi / Short Deck 6+ / Triton / 8-or-Better Lo / 2-7 Lowball / A-5 Lowball / Badugi
2. **조합** (C1~C9): 9 게임 그룹 — 각 조합은 1~2 룰을 사용하여 팟 분배 (Hi 전액 / Hi-Lo 50:50 등)
3. **카드 선택**: Free (N장 중 최고 5장) / Omaha (홀 2 + 보드 3 must-use) / Badugi (4장 부분집합)

#### 1.2.2 Variant 차이

**Hold'em 표준** 대비 차이:
- **Deck size**: 52장 (default) vs 36장 (Short Deck)
- **Hole cards**: 2 / 3→2 (Pineapple) / 4 / 5 / 6
- **Board cards**: 5 (default) / 0 (Stud, Draw) / 1+4 (Courchevel SETUP+FLOP)
- **카드 조합**: Free best-5 / must-use 2+3 (Omaha/Courchevel) / 4-card Badugi
- **베팅 라운드 수**: 4 (Hold'em) / 2 (draw5) / 4 (Triple Draw / Stud) / 5 (Stud +1)
- **DRAW_PHASE**: 카드 교환 (Draw / Pineapple)
- **Bring-in**: ante + bring-in (Stud 전용) vs SB+BB (Hold'em)

#### 1.2.3 예외 (BS-06-08)

**예외 상황** = 정상 핸드 진행의 제어 흐름을 벗어나는 모든 경우. 7 + 3 유형:

- 핸드 진행 중: All Fold / All-in Runout / Bomb Pot / Run It Twice / Miss Deal / RFID Failure / Card Mismatch
- 카드 무결성: Boxed Card (Rule 88) / Four-Card Flop (Rule 89) / Deck Change (Rule 78)

### 1.3 용어 사전 (6 문서 통합)

| 용어 | 출처 | 설명 |
|------|------|------|
| **홀카드 (hole card)** | All | 각 플레이어에게 비공개로 나눠주는 카드 |
| **커뮤니티 카드** | BS-06-05 | 테이블 중앙 공개 공용 카드 |
| **kicker** | BS-06-05 | 같은 족보일 때 승부를 가르는 나머지 카드 |
| **odd chip** | BS-06-05/Evaluation_Ref | 팟을 나눌 때 딱 떨어지지 않는 1개 베팅 토큰 |
| **offsuit / suited** | BS-06-05 | 두 카드 무늬 다름 / 같음 |
| **evaluator** | All | 카드 조합 분석하여 승자 결정하는 함수 |
| **must-use 2+3** | BS-06-1X | 홀카드 정확히 2 + 보드 정확히 3 (Omaha/Courchevel) |
| **8-or-better** | BS-06-1X / BS-06-3X | Low 자격: 5장 모두 rank ≤ 8, 서로 다른 rank → Low 자격 |
| **scoop** | BS-06-05/Eval_Ref | 한 사람이 양쪽 팟 (Hi+Lo) 모두 가져가는 것 |
| **wheel** | BS-06-05 | A-2-3-4-5 (standard) 또는 A-6-7-8-9 (Short Deck) |
| **Boxed card** | BS-06-08 | 의도와 다르게 face-up 으로 딜링된 카드 |
| **bring-in** | BS-06-3X | Stud 게임의 약한 패 보유자가 의무로 내는 최소 베팅 |
| **down card / up card** | BS-06-3X | 비공개 (down) / 공개 (up) 카드 |
| **door card** | BS-06-3X | Stud 처음 받는 공개 카드 1장 |
| **draw / stand pat** | BS-06-2X | 카드 교환 / 한장도 교환하지 않는 것 |
| **DISCARD_PHASE** | BS-06-1X (Pineapple) | Pineapple 의 3장→2장 1장 폐기 단계 |
| **DRAW_ROUND** | BS-06-2X | Draw 게임 카드 교환 라운드 |
| **bitmask** | BS-06-2X | 각 플레이어 완료 여부 0/1 추적 |
| **reshuffling** | BS-06-2X | 덱 카드 부족 시 버린 카드 다시 섞어 사용 |
| **C(n,k)** | All | n 장에서 k 장 선택 조합 수 |
| **qualifier** | Evaluation_Ref | Lo 자격 조건 (예: 8-or-better) |
| **Royal Flush (RF)** | All | A-K-Q-J-10 같은 수트 |

### 1.4 핵심 원칙 (6 문서 종합)

- 25 게임은 7 룰 × 9 조합으로 환원 — 코드 정본 `hand_evaluator.dart` / `badugi_evaluator.dart` / `showdown.dart`
- Hi-Lo split 게임: Lo qualifier 미충족 시 Hi 가 전액 수령 (scoop)
- Odd chip: Hi 우선 / 딜러 왼쪽 가까운 승자 (WSOP Rule 73)
- Variant 별 evaluator 라우팅은 `game_id` (0-21+) 로 결정
- Coalescence 윈도우: Hold'em 100ms / DRAW_ROUND 200ms / Stud 3RD burst 확장
- Hand 보호 (Rule 71/89/109/110) 는 모든 variant 에 동일 적용
- Boxed Card 2+ → Misdeal (Rule 88)
- Four-Card Flop → 4장 shuffle, 1장 burn 보존, 3장 정식 flop (Rule 89)
- Deck Change → 핸드 종료 후에만 (Rule 78)

---

## 2. State Machine / Data Flow

### 2.1 25 게임 마스터 테이블 (Evaluation_Reference §5)

| # | 게임 | 홀 | 보드 | 카드선택 | 순서 | Hi | Lo | Split | Bring-in | 최강 Hi | 최강 Lo |
|:-:|------|:--:|:----:|:-------:|:----:|:--:|:--:|:-----:|:--------:|--------|--------|
| 1 | NL Hold'em | 2 | 5 | Free | std | bestHand | — | — | — | RF | — |
| 2 | FL Hold'em | 2 | 5 | Free | std | bestHand | — | — | — | RF | — |
| 3 | PL Hold'em | 2 | 5 | Free | std | bestHand | — | — | — | RF | — |
| 4 | Pineapple | 3→2 | 5 | Free | std | bestHand | — | — | — | RF | — |
| 5 | Short Deck 6+ | 2 | 5 | Free | **6+** | bestHand | — | — | — | RF | — |
| 6 | Short Deck Triton | 2 | 5 | Free | **Tri** | bestHand | — | — | — | RF | — |
| 7 | Omaha | 4 | 5 | **Omaha** | std | bestOmaha | — | — | — | RF | — |
| 8 | Omaha Hi-Lo | 4 | 5 | **Omaha** | std | bestOmaha | bestOmahaLo | **50/50** | — | RF | A2345 |
| 9 | 5-Card Omaha | 5 | 5 | **Omaha** | std | bestOmaha | — | — | — | RF | — |
| 10 | 5-Card Omaha HL | 5 | 5 | **Omaha** | std | bestOmaha | bestOmahaLo | **50/50** | — | RF | A2345 |
| 11 | 6-Card Omaha | 6 | 5 | **Omaha** | std | bestOmaha | — | — | — | RF | — |
| 12 | 6-Card Omaha HL | 6 | 5 | **Omaha** | std | bestOmaha | bestOmahaLo | **50/50** | — | RF | A2345 |
| 13 | Courchevel | 5 | 1+4 | **Omaha** | std | bestOmaha | — | — | — | RF | — |
| 14 | Courchevel HL | 5 | 1+4 | **Omaha** | std | bestOmaha | bestOmahaLo | **50/50** | — | RF | A2345 |
| 15 | 7-Card Stud | 7 | 0 | Free | std | bestHand | — | — | **Low** | RF | — |
| 16 | 7-Card Stud HL | 7 | 0 | Free | std | bestHand | bestLow8 | **50/50** | **Low** | RF | A2345 |
| 17 | Razz | 7 | 0 | Free | — | **lbA5** | — | — | **High** | A2345 | — |
| 18 | 5-Card Draw | 5 | 0 | Free | std | bestHand | — | — | — | RF | — |
| 19 | 2-7 Single Draw | 5 | 0 | Free | — | **lb27** | — | — | — | 75432o | — |
| 20 | 2-7 Triple Draw | 5 | 0 | Free | — | **lb27** | — | — | — | 75432o | — |
| 21 | A-5 Triple Draw | 5 | 0 | Free | — | **lbA5** | — | — | — | A2345 | — |
| 22 | Badugi | 4 | 0 | — | — | **badugi** | — | — | — | A234(4suit) | — |
| 23 | Badeucy | 5 | 0 | — | — | **badugi** | **lb27** | **50/50** | — | A234(4suit) | 75432o |
| 24 | Badacey | 5 | 0 | — | — | **badugi** | **lbA5** | **50/50** | — | A234(4suit) | A2345 |

> 약어: std=standard, 6+=shortDeck6Plus, Tri=shortDeckTriton, RF=Royal Flush, lb27=bestLowball27, lbA5=bestLowballA5, HL=Hi-Lo, o=offsuit. 25번째는 표준 Hold'em 변형 (NL/FL/PL 분리 카운트). game_id 매핑: 0~21+.

### 2.2 9 조합 → 25 게임 배치 (Evaluation_Reference §Executive Summary)

| 조합 | 사용 룰 | 팟 분배 | 포함 게임 | 게임 수 |
|:----:|--------|:------:|----------|:------:|
| **C1** | R1 | Hi 전액 | NLH, FLH, PLH, Pineapple, Omaha, 5CO, 6CO, Courchevel, 7-Card Stud, 5-Card Draw | **10종** |
| **C2** | R2 | Hi 전액 | Short Deck 6+ | 1종 |
| **C3** | R3 | Hi 전액 | Short Deck Triton | 1종 |
| **C4** | R1 + R4 | Hi/Lo 50:50 | Omaha HL, 5CO HL, 6CO HL, Courchevel HL, 7CS HL | **5종** |
| **C5** | R5 | Lo 전액 | 2-7 Single Draw, 2-7 Triple Draw | 2종 |
| **C6** | R6 | Lo 전액 | A-5 Triple Draw, Razz | 2종 |
| **C7** | R7 | Hi 전액 | Badugi | 1종 |
| **C8** | R7 + R5 | Hi/Lo 50:50 | Badeucy | 1종 |
| **C9** | R7 + R6 | Hi/Lo 50:50 | Badacey | 1종 |

> C4 의 Lo 에서 qualifier 실패 (8 이하 핸드 없음) → Hi 가 전액 수령 (scoop).

### 2.3 7 승리 룰 (Evaluation_Reference §Executive Summary)

| 룰 | 이름 | "누가 이기나" | 최강 핸드 |
|:--:|-----|-------------|----------|
| **R1** | Standard Hi | 표준 10 카테고리 최강 | Royal Flush |
| **R2** | Short Deck 6+ | Flush > Full House 로 순서 변경 | Royal Flush |
| **R3** | Short Deck Triton | + Trips > Straight 추가 변경 | Royal Flush |
| **R4** | 8-or-Better Lo | A=1, 페어 실격, 8 이하만 | A-2-3-4-5 |
| **R5** | 2-7 Lowball | A=high, S/F 불리, 최약 핸드 승리 | 7-5-4-3-2 offsuit |
| **R6** | A-5 Lowball | A=1, S/F 무시, 최저 핸드 승리 | A-2-3-4-5 |
| **R7** | Badugi | 4장 고유 수트+랭크, 장 수 우선 | A♣2♦3♥4♠ |

### 2.4 R1~R3 카테고리 순서 비교

| 등급 | R1 standard | R2 6+ | R3 Triton |
|:----:|:-----------:|:-----:|:---------:|
| 1 | Royal Flush | Royal Flush | Royal Flush |
| 2 | Straight Flush | Straight Flush | Straight Flush |
| 3 | Four of a Kind | Four of a Kind | Four of a Kind |
| 4 | Full House | **Flush** | **Flush** |
| 5 | Flush | **Full House** | **Full House** |
| 6 | Straight | Straight | **Three of a Kind** |
| 7 | Three of a Kind | Three of a Kind | **Straight** |
| 8 | Two Pair | Two Pair | Two Pair |
| 9 | One Pair | One Pair | One Pair |
| 10 | High Card | High Card | High Card |

> R2/R3 에서 추가로 `shortDeck=true` → A-6-7-8-9 wheel 활성화 (36장 덱).

### 2.5 카드 선택 (Evaluation_Reference §1.6)

| 선택 | 규칙 | 적용 |
|------|------|------|
| **Free** | N장 중 아무 5장 (C(N,5) 전체 조합 중 최강) | Hold'em (7→21조합), Stud (7→21조합), Draw (5→1조합) |
| **Omaha** | C(H, 2) × C(C, 3) — 홀카드 2장 + 보드 3장 고정 | Omaha 4/5/6, Courchevel 4/5 |
| **Badugi** | 4장 중 유효 부분집합 (수트+랭크 unique) | Badugi 계열 (3종, R7 전용) |

#### Omaha 조합 수

| 게임 | 홀 | C(H,2) × C(5,3) | 총 조합 |
|------|:--:|:---------------:|:-------:|
| Omaha 4 | 4 | 6 × 10 | 60 |
| Omaha 5 / Courchevel | 5 | 10 × 10 | 100 |
| Omaha 6 | 6 | 15 × 10 | 150 |

> 홀카드 전부 같은 수트여도 커뮤니티에 같은 수트 3장 없으면 Flush 불가.

### 2.6 Hold'em HandRank 분포 (BS-06-05 매트릭스 1)

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

### 2.7 Variant Quick Comparison (BS-06-1X)

| 항목 | Hold'em | Short Deck | Pineapple | Omaha 4/5/6 | Courchevel |
|------|---------|------------|-----------|-------------|------------|
| `game_id` | 0 | 1, 2 | 3 | 4–9 | 10, 11 |
| `deck_size` | 52 | **36** | 52 | 52 | 52 |
| `hole_cards` | 2 | 2 | **3→2** | **4/5/6** | **5** |
| 조합 규칙 | best 5 of 7 | best 5 of 7 | best 5 of 7 | **must-use 2+3** | **must-use 2+3** |
| FSM | 9 상태 | 9 (동일) | **10** (DISCARD_PHASE 추가) | 9 (동일) | 9 (SETUP 확장) |
| SETUP 보드 | 0장 | 0장 | 0장 | 0장 | **1장** (`board_1`) |
| FLOP 보드 | 3장 | 3장 | 3장 | 3장 | **2장** (추가분만) |
| `evaluator` | standard_high | **standard_high_modified** | standard_high | standard_high / hilo_8or_better | standard_high / hilo_8or_better |
| Hi-Lo 변형 | 없음 | 없음 | 없음 | game 5/7/9 | game 11 |
| RFID burst (6인) | 12 | 12 | **18** (3장/인) | 24/30/**36** | 30 + board 1 |

### 2.8 Draw Games 라이프사이클 FSM (BS-06-2X §1)

```
IDLE
  │ SendStartHand()
  ▼
SETUP_HAND
  │ 홀카드 딜 완료 (RFID)
  ▼
PRE_DRAW_BET
  │ 베팅 완료
  ▼
DRAW_ROUND[1]  ──► POST_DRAW_BET[1]
  │                       │
  │ draw_count > 1        │ draw_count == 1
  ▼                       │
DRAW_ROUND[2] → POST_DRAW_BET[2]
  │
  │ draw_count == 3
  ▼
DRAW_ROUND[3] → POST_DRAW_BET[3]
  │
  ▼
SHOWDOWN → HAND_COMPLETE → IDLE
```

#### Draw 7 게임 (game 12-18)

| `game_id` | 이름 | `draw_count` | `hole_cards` | 베팅 라운드 | `evaluator` |
|:--:|------|:--:|:--:|:--:|------|
| 12 | draw5 | 1 | 5 | 2 | standard_high |
| 13 | deuce7_draw | 1 | 5 | 2 | lowball_27 |
| 14 | deuce7_triple | 3 | 5 | 4 | lowball_27 |
| 15 | a5_triple | 3 | 5 | 4 | lowball_a5 |
| 16 | badugi | 3 | **4** | 4 | badugi |
| 17 | badeucy | 3 | 5 | 4 | hilo_badugi_27 |
| 18 | badacey | 3 | 5 | 4 | hilo_badugi_a5 |

### 2.9 Stud Games 라이프사이클 FSM (BS-06-3X §1)

```
IDLE
  ▼
SETUP_HAND ─── ante 수집 + 3장 딜 (2 down + 1 up)
  ▼
3RD_STREET ─── bring-in 결정 + 1st 베팅
  ▼
4TH_STREET ─── +1 up, 2nd 베팅
  ▼
5TH_STREET ─── +1 up, 3rd 베팅 (big bet 시작)
  ▼
6TH_STREET ─── +1 up, 4th 베팅
  ▼
7TH_STREET ─── +1 down, final 베팅
  ▼
SHOWDOWN ───── 핸드 평가 + 팟 분배
  ▼
HAND_COMPLETE
```

#### Stud 3 게임 (game 19-21)

| `game_id` | 이름 | `evaluator` | 핵심 |
|:--:|------|------|------|
| 19 | stud7 | standard_high | 표준 하이 (BS-06-05 참조) |
| 20 | stud7_hilo8 | hilo_8or_better | Hi/Lo split + 8-or-better |
| 21 | razz | lowball_a5 | 로우볼 전용 |

#### Stud 베팅 구조 (FL 기준)

| Street | 베팅 크기 | 예외 |
|--------|---------|------|
| 3RD | `low_limit` | bring-in 별도 |
| 4TH | `low_limit` | pair visible 시 big bet 선택 |
| 5TH–7TH | `high_limit` | 없음 |

### 2.10 Pineapple DISCARD_PHASE (BS-06-1X §2)

```
IDLE → SETUP_HAND → PRE_FLOP (3장 보유)
  → DISCARD_PHASE (1장 버림)
  → FLOP → TURN → RIVER → SHOWDOWN → HAND_COMPLETE
```

| 속성 | 값 |
|------|-----|
| **Entry** | PRE_FLOP 베팅 완료 |
| **hand_in_progress** | true |
| **action_on** | -1 (전체 대기) |
| **board_cards** | 0 |
| **처리** | 각 active 플레이어가 3장 중 1장 폐기 |
| **Exit** | 모든 active 플레이어 discard 완료 → **FLOP** |
| **타임아웃** | 30초 후 CC 수동 입력 모드 |
| **RFID 감지 위치** | burn zone antenna #11 |
| **추가 상태변수** | `discard_pending` (active 수, 0 시 FLOP 전이) |

### 2.11 ExceptionState 데이터 모델 (BS-06-08 §데이터 모델)

```python
class ExceptionState:
    exception_type: str  # "all_fold", "all_in_runout", "bomb_pot", "run_it_twice",
                         # "miss_deal", "rfid_failure", "card_mismatch", "network_disconnect"
    triggered_at_state: str  # 예외 발생 당시 game_state
    triggered_at_time: float  # 타임스탬프
    recovery_actions: list[str]  # 복구 액션 히스토리
    is_resolved: bool = False

class HandState:  # 확장
    exception_state: ExceptionState = None
    saved_state_for_undo: HandState = None  # UNDO 용 이전 상태 백업

class RFIDFailureRetry:
    attempt_count: int = 0  # 1-5
    max_attempts: int = 5
    retry_interval: float = 2.0  # 초
    last_retry_time: float = None

    def should_retry(self) -> bool:
        return self.attempt_count < self.max_attempts

    def should_fallback_to_manual(self) -> bool:
        return self.attempt_count >= self.max_attempts
```

---

<!-- CHUNK-2: §3 Trigger & Action Matrix (Hi-Lo 분배 + Variant 트리거 + 7 예외 매트릭스) -->

<!-- CHUNK-3: §4 Exceptions + §5 Data Models + Appendix A/B -->
