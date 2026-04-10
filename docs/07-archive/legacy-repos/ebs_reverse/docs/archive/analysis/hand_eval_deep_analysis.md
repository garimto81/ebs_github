# PokerGFX hand_eval.dll -- Complete Reverse Engineering Analysis

## 1. Hand Evaluation Algorithm

### 1.1 Core Entry Points

평가 시스템은 두 가지 주요 진입 레이어를 가짐:

**Public dispatch** (`hand_eval\hand_eval\core.cs`):
- `evaluate_hand(string cards, string board, string _game)` -- 게임 타입 문자열에 따라 게임별 evaluator로 라우팅하는 마스터 디스패처

**Core evaluator** (`hand_eval\hand_eval\Hand.cs`, line 3915-4622):
- `Evaluate(ulong cards, bool ignore_wheel)` -- BitCount 계산 후 전체 버전에 위임
- `Evaluate(ulong cards, int numberOfCards, bool ignore_wheel)` -- 실제 평가 알고리즘

### 1.2 Evaluate() 알고리즘 (Hand.cs lines 4027-4622)

라이브러리 전체의 핵심. C# pseudocode로 복원:

```csharp
static uint Evaluate(ulong cards, int numberOfCards, bool ignore_wheel)
{
    // Step 1: suit mask 추출 (각 13비트)
    int clubs    = (int)((cards >> CLUB_OFFSET) & 0x1FFF);
    int diamonds = (int)((cards >> DIAMOND_OFFSET) & 0x1FFF);
    int hearts   = (int)((cards >> HEART_OFFSET) & 0x1FFF);
    int spades   = (int)((cards >> SPADE_OFFSET) & 0x1FFF);

    // Step 2: 결합 랭크 정보 계산
    int ranks = clubs | diamonds | hearts | spades;  // 존재하는 모든 랭크
    int uniqueRanks = nBitsTable[ranks];             // 고유 랭크 수
    int duplicates = numberOfCards - uniqueRanks;     // 중복 랭크 수

    uint retval = 0;

    // Step 3: Flush 감지 (5개 이상 고유 랭크 존재 시)
    if (uniqueRanks >= 5)
    {
        foreach (int suitMask in {clubs, diamonds, hearts, spades})
        {
            if (nBitsTable[suitMask] >= 5)
            {
                // Straight Flush 체크
                if (straightTable[suitMask] != 0)
                {
                    if (!ignore_wheel || straightTable[ranks] != 5)
                        return HANDTYPE_VALUE_STRAIGHTFLUSH
                             + (straightTable[suitMask] << TOP_CARD_SHIFT);
                }
                // Plain Flush
                retval = HANDTYPE_VALUE_FLUSH + TopFive(suitMask);
                break;
            }
        }
    }

    // Step 4: Straight 체크 (Flush 없을 때)
    if (retval == 0)
    {
        int straightTop = straightTable[ranks];
        if (straightTop != 0)
        {
            if (!ignore_wheel || straightTable[hearts] != 5)
                retval = HANDTYPE_VALUE_STRAIGHT
                       + (straightTop << TOP_CARD_SHIFT);
        }
    }

    // Step 5: Flush/Straight 발견 + 중복 < 3이면 조기 반환
    if (retval != 0 && duplicates < 3)
        return retval;

    // Step 6: 중복 수에 따른 처리
    switch (duplicates)
    {
        case 0: // HIGH CARD
            return HANDTYPE_VALUE_HIGHCARD + TopFive(ranks);

        case 1: // ONE PAIR
            int pairBits = ranks ^ (clubs ^ diamonds ^ hearts ^ spades);
            uint result = HANDTYPE_VALUE_PAIR
                        + (topCardTable[pairBits] << TOP_CARD_SHIFT);
            int kickers = ranks ^ pairBits;
            result += TopFive(kickers) >> CARD_WIDTH & ~FIFTH_CARD_MASK;
            return result;

        case 2: // TWO PAIR or TRIPS
            int singles = ranks ^ (clubs ^ diamonds ^ hearts ^ spades);
            if (singles != 0)  // Two Pair
            {
                int pairs = ranks ^ singles;
                return HANDTYPE_VALUE_TWOPAIR
                     + (TopFive(singles) & (TOP_CARD_MASK | SECOND_CARD_MASK))
                     + (topCardTable[pairs] << THIRD_CARD_SHIFT);
            }
            else  // Trips
            {
                int trips = (clubs & diamonds) | (hearts & spades)
                          | (clubs & hearts) | (diamonds & spades);
                return HANDTYPE_VALUE_TRIPS
                     + (topCardTable[trips] << TOP_CARD_SHIFT)
                     + kicker1 + kicker2;
            }

        default: // 3+ 중복: FOUR_OF_A_KIND, FULL_HOUSE, 복합 핸드
            // Four of a Kind: 4개 suit mask를 AND
            int quads = clubs & diamonds & hearts & spades;
            if (quads != 0)
            {
                int quadRank = topCardTable[quads];
                return HANDTYPE_VALUE_FOUR_OF_A_KIND
                     + (quadRank << TOP_CARD_SHIFT)
                     + (topCardTable[ranks ^ (1 << quadRank)] << SECOND_CARD_SHIFT);
            }

            // Full House 체크
            int xorResult = ranks ^ (clubs ^ diamonds ^ hearts ^ spades);
            if (nBitsTable[xorResult] != duplicates)
            {
                int tripsRank = (clubs&diamonds | hearts&spades)
                              & (clubs&hearts | diamonds&spades);
                uint fh = HANDTYPE_VALUE_FULLHOUSE;
                int trTop = topCardTable[tripsRank];
                fh += trTop << TOP_CARD_SHIFT;
                int remaining = (xorResult | tripsRank) ^ (1 << trTop);
                fh += topCardTable[remaining] << SECOND_CARD_SHIFT;
                return fh;
            }
    }
}
```

### 1.3 핵심 알고리즘 기법

**XOR 기반 중복 감지** (Hand.cs lines 4304-4312, 4345-4354, 4489-4498):

`clubs XOR diamonds XOR hearts XOR spades`는 홀수 번 등장하는 랭크만 비트가 SET되는 마스크를 생성. 정확히 2개 suit에 있는 랭크는 XOR로 상쇄되어 0.

- `singles = ranks XOR (c XOR d XOR h XOR s)` -- 페어 랭크 추출
- `(c AND d) OR (h AND s) OR (c AND h) OR (d AND s)` -- 3+ suit 등장 랭크 (trips/quads)
- `c AND d AND h AND s` -- 4개 suit 모두 등장 (quads)

**Lookup table 접근** (Hand.cs lines 7852-7887):
모든 핵심 lookup table은 8192 엔트리 배열 (2^13, 13비트 랭크 패턴 전체 커버):

| 테이블 | 타입 | 크기 | 설명 |
|--------|------|------|------|
| `nBitsTable[8192]` | ushort[] | 8192 | 13비트 값의 popcount |
| `straightTable[8192]` | ushort[] | 8192 | Straight 포함 시 최고 카드 랭크, 없으면 0 |
| `topFiveCardsTable[8192]` | uint[] | 8192 | 상위 5개 비트 packed 표현 |
| `topCardTable[8192]` | ushort[] | 8192 | 최상위 비트 랭크 |
| `nBitsAndStrTable[8192]` | ushort[] | 8192 | bitcount + straight 결합 정보 |

### 1.4 Hand Value 인코딩

핸드 값은 빠른 비교를 위해 단일 `uint`에 packed (Hand.cs lines 7768-7829):

| 값 | HandType | 계산식 |
|----|----------|--------|
| 0 | HighCard | `0 << HANDTYPE_SHIFT` |
| 1 | Pair | `1 << HANDTYPE_SHIFT` |
| 2 | TwoPair | `2 << HANDTYPE_SHIFT` |
| 3 | Trips | `3 << HANDTYPE_SHIFT` |
| 4 | Straight | `4 << HANDTYPE_SHIFT` |
| 5 | Flush | `5 << HANDTYPE_SHIFT` |
| 6 | FullHouse | `6 << HANDTYPE_SHIFT` |
| 7 | FourOfAKind | `7 << HANDTYPE_SHIFT` |
| 8 | StraightFlush | `8 << HANDTYPE_SHIFT` |

Kicker 정보는 `TOP_CARD_SHIFT`, `SECOND_CARD_SHIFT`, `THIRD_CARD_SHIFT`, `CARD_WIDTH` 상수를 사용하여 하위 비트에 packed. 직접 uint 비교 가능: 상위 핸드 타입이 항상 우선, 동일 타입 내에서 kicker로 타이 해결.

---

## 2. 카드 표현 시스템

### 2.1 Bitmask 인코딩 (64비트 ulong)

각 카드는 64비트 `ulong`의 단일 비트. 52장이 4개 연속 13비트 영역에 배치:

```
비트 레이아웃 (64비트 중 52비트 사용):
[--- Spades ---][--- Hearts ---][--- Diamonds ---][--- Clubs ---]
 bits 39-51       bits 26-38       bits 13-25        bits 0-12

각 suit 내 (13비트):
bit 0  = 2 (최저)
bit 1  = 3
...
bit 8  = 10
bit 9  = Jack
bit 10 = Queen
bit 11 = King
bit 12 = Ace (최고)
```

**Suit offset** (Hand.cs lines 7831-7845):
```
CLUB_OFFSET    = 13 * 0 = 0
DIAMOND_OFFSET = 13 * 1 = 13
HEART_OFFSET   = 13 * 2 = 26
SPADE_OFFSET   = 13 * 3 = 39
```

### 2.2 카드 문자열 파싱

`NextCard()` (Hand.cs lines 2716-2958) - 2글자 카드 문자열 파싱:

**랭크 문자** (대소문자 무관):

| 문자 | 비트 위치 |
|------|----------|
| 2-9 | 0-7 |
| T/t | 8 |
| J/j | 9 |
| Q/q | 10 |
| K/k | 11 |
| A/a | 12 |

**Suit 문자** (대소문자 무관):

| 문자 | Suit | 인덱스 |
|------|------|--------|
| C/c | Clubs | 0 |
| D/d | Diamonds | 1 |
| H/h | Hearts | 2 |
| S/s | Spades | 3 |

**카드 마스크 공식**: `mask |= (1UL << (rank + suit * 13))`

### 2.3 CardMasksTable & CardTable

- `CardMasksTable[52]`: ulong[] - 각 카드의 단일 비트 마스크
- `CardTable[52]`: string[] - `["2c","3c",...,"Ac","2d",...,"Ad","2h",...,"Ah","2s",...,"As"]`

### 2.4 TopTables (Memory-Mapped File 최적화)

`hand_eval\_global\TopTables.cs`:

`topFiveCardsTable`과 `topCardTable`은 성능을 위해 memory-mapped 바이너리 파일에서 로드 가능:

- **topFiveCards.bin**: 각 엔트리 `uint` (4바이트), `ReadUInt32`로 `index * 4` 오프셋에서 읽기
- **topCard.bin**: 각 엔트리 `ushort` (2바이트), `ReadUInt16`로 `index * 2` 오프셋에서 읽기

파일 없거나 인덱스 범위 초과 시 인메모리 배열로 fallback. Double-checked locking으로 thread-safe lazy 초기화.

---

## 3. 게임 타입별 평가

### 3.1 게임 라우팅

`core.evaluate_hand()`과 `core.calc_odds()`가 게임 문자열에 따라 라우팅:

| 게임 문자열 | Evaluator | 비고 |
|------------|-----------|------|
| HOLDEM | `Hand.Evaluate` | Texas Hold'em |
| PINEAPPL | `Hand.Evaluate` | Pineapple (Hold'em과 동일 평가) |
| 6THOLDEM | `holdem_sixplus.eval` | Short Deck, trips > straight |
| 6PHOLDEM | `holdem_sixplus.eval` | Short Deck, 표준 랭킹 |
| OMAHA | `OmahaEvaluator.EvaluateHigh` | 4카드 Omaha |
| OMAHAHL | `OmahaEvaluator` + EvaluateLow | Omaha Hi-Lo |
| OMAHA5 | `Omaha5Evaluator.EvaluateHigh` | 5카드 Omaha |
| COUR | `Omaha5Evaluator` | Courchevel |
| OMAHA6 | `Omaha6Evaluator.EvaluateHigh` | 6카드 Omaha |
| 5DRAW | `draw.HandOdds` | Five-card Draw |
| 27DRAW | `draw.HandOdds(seven_deuce_lowball=true)` | 2-7 Single Draw |
| 27TRIPLE | `draw.HandOdds(seven_deuce_lowball=true)` | 2-7 Triple Draw |
| A5TRIPLE | `draw.a5_HandOdds` | A-5 Triple Draw |
| BADUGI | `draw.badugi` | Badugi |
| BADEUCY | `draw.badugi` | Badeucy |
| BADACEY | `draw.badugi` | Badacey |
| 7STUD | `stud.odds` | Seven Card Stud |
| 7STUDHL | `stud.odds(lo=true)` | Stud Hi-Lo |
| RAZZ | `stud.odds(lo=true)` | Razz |

### 3.2 Short Deck Hold'em (holdem_sixplus.cs, 783줄)

Short Deck는 2, 3, 4, 5를 제거 (36장). 두 가지 규칙 변형:

**6THOLDEM** (trips_beats_straight = true):
1. `Hand.Evaluate`로 정상 평가
2. 결과가 Straight이면: 최고 straight 카드를 Rank2 동치로 교체 후 재평가. Trips 결과 시 유지 (trips가 straight를 이김)
3. 사후 교환: Trips 값 <-> Straight 값, Flush 값 <-> FullHouse 값

**Dead cards 상수**: `8247343964175` -- 4개 suit의 모든 2, 3, 4, 5 bitmask (16장 제거)

**Wheel 처리**: A-6-7-8-9 패턴 (bitmask 4336)이 표준 A-2-3-4-5 wheel을 대체

### 3.3 Omaha 변형

**OmahaEvaluator** (485줄):

생성자에서 C(52,4) = 270,725개 4카드 조합을 사전 계산, 정렬 후 binary search용 리스트에 저장.

`EvaluateHigh(ulong hand, ulong table)`:
1. Binary search로 pocket 카드에 매칭되는 `OmahaHand` 찾기
2. C(4,2) = 6개 2카드 조합 반복 (`OmahaHand.hands[]`에 저장)
3. 각 조합: board와 OR → `Hand.Evaluate` → 최대값 추적
4. 최고 핸드 값 반환

**Omaha5Evaluator** (504줄):
- C(52,5) = 2,598,960개 5카드 조합 사전 계산 (인메모리)
- C(5,2) = 10개 2카드 조합/핸드

**Omaha6Evaluator** (625줄):
- **Memory-mapped file** (`omaha6.vpt`) 사용 - C(52,6) = 20,358,520개 조합 (인메모리 불가)
- 각 레코드 = 128바이트 (1 ulong cards + 15 ulong combinations)
- `HandRecordSize = 128` 바이트
- Memory-mapped file에서 직접 binary search

### 3.4 Stud 변형 (stud.cs, 713줄)

**SevenCards Evaluator** (636줄):
- 생성자에서 `m_evaluatedresults[8192]`와 `m_topthree[8192]` 테이블 사전 계산
- 각 13비트 랭크 패턴(5+ 비트)에 평가 결과 저장
- Magic constant `1161928703861587968` 사용

**Razz** (573줄):
- Low-hand evaluator
- King (bit 12)을 high로 처리: `shl 1` + `shr 12`로 리맵
- Ace를 low로 처리 (원래 위치 유지)

### 3.5 Badugi (419줄)

4카드 lowball 게임, 고유 suit + 고유 rank 필요:

핸드 강도 인코딩 (높은 base = 나쁜 핸드):

| 카드 수 | Base 값 |
|---------|---------|
| 4-card Badugi | 9,007,199,254,740,992 |
| 3-card | 18,014,398,509,481,984 |
| 2-card | 36,028,797,018,963,968 |
| 1-card | 72,057,594,037,927,936 |

### 3.6 Draw 게임 (draw.cs, 689줄)

- `HandOdds(bool seven_deuce_lowball, ...)`: 5카드 Draw 평가
- `a5_HandOdds()`: Ace-to-Five lowball (Razz evaluator 사용)
- `badugi_eval()`: C(48,4) 조합 평가

---

## 4. 확률 계산

### 4.1 Hold'em Odds (Hand.HandOdds, lines 1272-1546)

1. 모든 pocket 카드와 dead 카드를 ulong bitmask로 파싱
2. 각 플레이어 정확히 2장 pocket 카드 검증
3. 남은 board 카드 생성: `Hands(board, allUsedCards, 5)` (전수 조사)
4. **Monte Carlo 임계값**: 열거 수 > `MC_NUM` (기본 100,000)이면 `RandomHands()`로 전환
5. 각 board 가능성에 대해: 모든 플레이어 평가 → 최고 핸드 값 찾기 → 승/무/패 할당

### 4.2 Omaha Odds

- Omaha 4/5: MC_NUM 임계값 `10,000`
- Omaha 6: MC_NUM 임계값 `1,000`
- Hi-Lo: scoop 추적 (hi와 lo 모두 승리)

### 4.3 Preflop Lookup (HandPlayerOpponentOdds)

**사전 계산 fast path** (board 0장, preflop):
- `PreCalcPlayerOdds[169][9]`: 핸드 타입별 확률 (플레이어)
- `PreCalcOppOdds[169][9]`: 핸드 타입별 확률 (상대)
- `PocketHand169Type(ourcards)`로 인덱싱 -- 169개 canonical pocket 타입

### 4.4 Outs 계산 (Hand.OutsMask, lines 1560-1691)

1. 모든 단일 카드 추가 열거: `Hands(0, dead | board | player, 1)`
2. 각 카드: 플레이어+board+카드 평가, 모든 상대+board+카드 평가
3. 플레이어가 모든 상대를 이기면 (또는 `include_splits` 시 타이) "out" 카드
4. 모든 out 카드의 bitmask 반환

---

## 5. 핵심 상수 및 데이터 구조

### 5.1 HandTypes Enum

| 값 | 이름 |
|----|------|
| 0 | HighCard |
| 1 | Pair |
| 2 | TwoPair |
| 3 | Trips |
| 4 | Straight |
| 5 | Flush |
| 6 | FullHouse |
| 7 | FourOfAKind |
| 8 | StraightFlush |

### 5.2 PocketHand169Enum (174줄)

Texas Hold'em의 전략적으로 구분되는 169개 pocket hand 타입:
- 13개 pocket pair: AA, KK, ..., 22
- 78개 suited: AKs, AQs, ..., 32s
- 78개 offsuit: AKo, AQo, ..., 32o
- `None` (값 0)

### 5.3 Static Lookup Tables (Hand.cs .cctor)

| 테이블 | 타입 | 크기 | 설명 |
|--------|------|------|------|
| `bits[256]` | byte[] | 256 | 바이트 popcount |
| `nBitsAndStrTable[8192]` | ushort[] | 8192 | bitcount + straight 결합 |
| `nBitsTable[8192]` | ushort[] | 8192 | 13비트 popcount |
| `straightTable[8192]` | ushort[] | 8192 | Straight 최고 카드 |
| `topFiveCardsTable[8192]` | uint[] | 8192 | 상위 5비트 packed |
| `topCardTable[8192]` | ushort[] | 8192 | 최상위 비트 랭크 |
| `CardMasksTable[52]` | ulong[] | 52 | 단일 카드 bitmask |
| `CardTable[52]` | string[] | 52 | 카드 이름 문자열 |

### 5.4 IPokerEvaluator 인터페이스

```csharp
interface IPokerEvaluator
{
    void Evaluate(ref ulong HiResult, ref short LowResult, ulong Hand, ulong OpenCards);
    bool IsHighLow { get; }
}
```

구현체: SevenCards, Razz, Badugi

---

## 6. 아키텍처 요약

```
                    core.evaluate_hand() / core.calc_odds()
                              |
              +---------------+----------------+
              |               |                |
    Hand.Evaluate()   OmahaEvaluator    IPokerEvaluator
    (Hold'em core)    Omaha5Evaluator   (SevenCards, Razz, Badugi)
                      Omaha6Evaluator
              |
    holdem_sixplus.eval()
    (Short Deck variant)
              |
         draw.HandOdds()
         (Draw poker variants)

Supporting infrastructure:
    EvaluationHelper (bitcount, LSB, MSB tables)
    APokerEvaluationBaseClass (low hand evaluation)
    TopTables (memory-mapped file optimization)
    PermutationsAndCombinations (combinatorics)
    PocketHand169Enum (strategic hand classification)
```

**핵심 설계 패턴**:
1. **Bitmask 중심**: 모든 연산이 64비트 마스크 기반. 평가 중 객체 생성 없음
2. **Lookup table 기반**: 8192 엔트리 사전 계산 테이블로 O(n) → O(1) 변환
3. **조합 사전 계산**: Omaha 변형은 초기화 시 모든 pocket 조합 사전 계산
4. **적응형 열거**: MC_NUM 임계값에 따라 전수 조사 ↔ Monte Carlo 자동 전환
5. **Memory-mapped file**: Omaha6는 C(52,6) 조합 테이블에 memory-mapped .vpt 파일 사용; TopTables는 hot-path lookup에 .bin 파일 선택적 사용

---

## 7. 디컴파일 파일 목록 (52개)

```
hand_eval/
├── hand_eval/
│   ├── core.cs                    # 마스터 디스패처
│   ├── Hand.cs                    # 핵심 평가 알고리즘 (8098줄)
│   ├── OmahaEvaluator.cs          # 4카드 Omaha (485줄)
│   ├── OmahaHand.cs               # Omaha 4 핸드 (109줄)
│   ├── Omaha5Evaluator.cs         # 5카드 Omaha (504줄)
│   ├── Omaha5Hand.cs              # Omaha 5 핸드 (139줄)
│   ├── Omaha6Evaluator.cs         # 6카드 Omaha (625줄)
│   ├── Omaha6Hand.cs              # Omaha 6 핸드 (278줄)
│   ├── holdem_sixplus.cs          # Short Deck (783줄)
│   ├── stud.cs                    # Stud/Razz (713줄)
│   └── draw.cs                    # Draw 게임 (689줄)
├── PokerEvaluators/
│   ├── IPokerEvaluator.cs         # 인터페이스
│   ├── SevenCards.cs              # 7카드 Stud evaluator (636줄)
│   ├── Razz.cs                    # Razz evaluator (573줄)
│   ├── Badugi.cs                  # Badugi evaluator (419줄)
│   ├── APokerEvaluationBaseClass.cs # 추상 base (125줄)
│   └── EvaluationHelper.cs        # 유틸리티 (363줄)
├── _global/
│   ├── HandTypes.cs               # 핸드 타입 enum
│   ├── PocketHand169Enum.cs       # 169 pocket 타입
│   ├── GroupTypeEnum.cs           # 그룹 분류
│   ├── TopTables.cs               # Memory-mapped 최적화
│   └── PermutationsAndCombinations.cs # 조합론
└── Properties/
    └── AssemblyInfo.cs
```
