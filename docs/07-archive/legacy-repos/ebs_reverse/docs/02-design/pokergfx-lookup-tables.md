# PokerGFX Lookup Tables 데이터베이스 명세

> **Summary**: PokerGFX 핸드 평가 엔진의 Lookup Table 아키텍처 및 메모리 맵 구조
> **Version**: 1.0.0
> **Date**: 2026-02-17
> **Source**: hand_eval.dll, TopTables.cs
> **Total Memory**: ~2.1MB (538개 정적 배열 + Memory-Mapped 파일)

---

## 목차

1. [개요](#1-개요)
2. [핵심 8개 Lookup Table](#2-핵심-8개-lookup-table)
3. [Memory-Mapped 파일 구조](#3-memory-mapped-파일-구조)
4. [538개 정적 배열 초기화](#4-538개-정적-배열-초기화)
5. [메모리 사용량 분석](#5-메모리-사용량-분석)
6. [Thread-Safe 초기화](#6-thread-safe-초기화)
7. [CardMask 비트 표현](#7-cardmask-비트-표현)
8. [게임별 Evaluator와 Lookup Table 사용](#8-게임별-evaluator와-lookup-table-사용)
9. [Short Deck 변형 상수](#9-short-deck-변형-상수)
10. [Omaha6 Memory-Mapped 파일](#10-omaha6-memory-mapped-파일)
11. [암호화 및 보안](#11-암호화-및-보안)

---

## 1. 개요

PokerGFX 핸드 평가 엔진은 **Lookup Table 기반 O(1) 평가**를 핵심으로 한다. 모든 주요 테이블은 **8192 엔트리 배열**(2^13, 13비트 랭크 패턴 전체 커버)로 구성되며, 64비트 bitmask 카드 표현과 결합하여 즉각적인 핸드 평가를 수행한다.

### 주요 특징

- **사전 계산**: 모든 가능한 13비트 랭크 조합에 대한 결과를 미리 계산
- **Bitmask 기반**: ulong(64비트) 단일 비트로 카드 표현, bitwise 연산으로 평가
- **Memory-Mapped 옵션**: topFiveCards.bin, topCard.bin 파일 로드로 메모리 절약 가능
- **Thread-Safe Lazy 초기화**: Double-checked locking으로 멀티스레드 안전성 보장
- **게임별 최적화**: Hold'em, Omaha, Short Deck, Stud, Draw 등 17개 게임에 특화된 evaluator

---

## 2. 핵심 8개 Lookup Table

모든 핵심 lookup table은 **8192 엔트리 배열**(2^13, 13비트 랭크 패턴 전체 커버)이다.

| 테이블 | 타입 | 크기 | 엔트리 수 | 메모리 | 설명 |
|--------|------|:----:|:--------:|:------:|------|
| **nBitsTable** | ushort[] | 16KB | 8192 | 2 bytes × 8192 | 13비트 값의 popcount (1의 개수) |
| **straightTable** | ushort[] | 16KB | 8192 | 2 bytes × 8192 | Straight 포함 시 최고 카드 랭크, 없으면 0 |
| **topFiveCardsTable** | uint[] | 32KB | 8192 | 4 bytes × 8192 | 상위 5개 비트 packed 표현 |
| **topCardTable** | ushort[] | 16KB | 8192 | 2 bytes × 8192 | 최상위 비트 랭크 |
| **nBitsAndStrTable** | ushort[] | 16KB | 8192 | 2 bytes × 8192 | bitcount + straight 결합 정보 |
| **bits** | byte[] | 256B | 256 | 1 byte × 256 | 바이트 popcount (0-255) |
| **CardMasksTable** | ulong[] | 416B | 52 | 8 bytes × 52 | 단일 카드 bitmask |
| **CardTable** | string[] | ~1KB | 52 | ~20 bytes × 52 | 카드 이름 문자열 ("2c", "Ah" 등) |

**총 메모리**: ~97KB (8개 핵심 테이블만)

### 2.1 nBitsTable (Popcount)

```csharp
// 13비트 값 중 1인 비트의 개수 (popcount)
ushort[] nBitsTable = new ushort[8192];

// 예시:
// nBitsTable[0b1010100001001] = 5  (5개의 1 비트)
// nBitsTable[0b1111100000000] = 5  (AKQJT)
```

**용도**: 고유 랭크 개수 계산 → 중복 감지 (페어, 트립스, 쿼드 판별)

### 2.2 straightTable (Straight 감지)

```csharp
// 13비트 값에 Straight가 포함된 경우 최고 카드 랭크 반환
ushort[] straightTable = new ushort[8192];

// 예시:
// straightTable[0b0000000011111] = 3  (A2345 Wheel, top 5)
// straightTable[0b1111100000000] = 12 (TJQKA, top Ace)
// straightTable[0b0000001011110] = 0  (Straight 아님)
```

**용도**: O(1) Straight 체크, Straight/StraightFlush 판정

### 2.3 topFiveCardsTable (Top 5 Cards Packed)

```csharp
// 13비트 값에서 상위 5개 비트를 packed 표현으로 인코딩
uint[] topFiveCardsTable = new uint[8192];

// 예시:
// topFiveCardsTable[0b1111111111111] = (12 << 16) | (11 << 12) | (10 << 8) | (9 << 4) | 8
// → AKQJT (상위 5장)
```

**용도**: HighCard, Flush의 kicker 계산 (5장 중 최고 조합)

### 2.4 topCardTable (Top Card)

```csharp
// 13비트 값에서 최상위 비트(1) 랭크 반환
ushort[] topCardTable = new ushort[8192];

// 예시:
// topCardTable[0b1000000000001] = 12  (Ace, bit 12)
// topCardTable[0b0000010000000] = 7   (9, bit 7)
```

**용도**: 최고 카드 빠른 조회 (Pair, TwoPair의 kicker)

### 2.5 nBitsAndStrTable (Combined Info)

```csharp
// bitcount + straight 결합 정보
ushort[] nBitsAndStrTable = new ushort[8192];

// 인코딩: (nBits << 4) | (straightTop & 0xF)
// 예시:
// nBitsAndStrTable[0b1111100000000] = (5 << 4) | 12 = 92  (5장 TJQKA, straight top Ace)
```

**용도**: 중복 수 + Straight 정보 단일 조회 (평가 최적화)

### 2.6 bits (Byte Popcount)

```csharp
// 0-255 바이트 값의 popcount
byte[] bits = new byte[256];

// 예시:
// bits[0b11010010] = 4  (4개의 1 비트)
```

**용도**: 8비트 단위 popcount 빠른 조회 (큰 bitmask 처리)

### 2.7 CardMasksTable (Single Card Bitmask)

```csharp
// 52장 카드 각각의 단일 비트 마스크
ulong[] CardMasksTable = new ulong[52];

// 예시:
// CardMasksTable[0]  = 1UL << 0   (2♣, bit 0)
// CardMasksTable[12] = 1UL << 12  (A♣, bit 12)
// CardMasksTable[13] = 1UL << 13  (2♦, bit 13)
// CardMasksTable[51] = 1UL << 51  (A♠, bit 51)
```

**배치 순서**: `["2c","3c",...,"Ac","2d",...,"Kd","Ad","2h",...,"Ah","2s",...,"As"]`

**용도**: 카드 문자열 → bitmask 변환 (파서에서 사용)

### 2.8 CardTable (Card Name Strings)

```csharp
// 52장 카드 이름 문자열
string[] CardTable = new string[52];

// 예시:
// CardTable[0]  = "2c"  (2♣)
// CardTable[12] = "Ac"  (A♣)
// CardTable[51] = "As"  (A♠)
```

**용도**: bitmask → 카드 문자열 역변환 (디버그, 출력)

---

## 3. Memory-Mapped 파일 구조

`TopTables.cs`는 성능 최적화를 위해 **memory-mapped 파일**에서 lookup table을 로드하는 옵션을 제공한다. 파일이 없거나 인덱스 범위 초과 시 인메모리 배열로 fallback한다.

### 3.1 topFiveCards.bin

```
파일 크기: 32KB (8192 × 4 bytes)
타입: uint[]
인덱스 범위: 0-8191 (13비트 랭크 조합)
용도: topFiveCardsTable[] 대체
```

**레이아웃**:
```
[offset 0]  → topFiveCards[0]  (4 bytes, little-endian uint)
[offset 4]  → topFiveCards[1]
...
[offset 32764] → topFiveCards[8191]
```

**로드 코드** (TopTables.cs):
```csharp
private static uint[] topFiveCardsTable;
private static MemoryMappedFile mmf_topFive;

static TopTables() {
    if (File.Exists("topFiveCards.bin")) {
        mmf_topFive = MemoryMappedFile.CreateFromFile("topFiveCards.bin", FileMode.Open);
        using (var accessor = mmf_topFive.CreateViewAccessor(0, 8192 * 4)) {
            topFiveCardsTable = new uint[8192];
            for (int i = 0; i < 8192; i++) {
                topFiveCardsTable[i] = accessor.ReadUInt32(i * 4);
            }
        }
    } else {
        // Fallback to in-memory generation
        topFiveCardsTable = GenerateTopFiveCards();
    }
}
```

### 3.2 topCard.bin

```
파일 크기: 16KB (8192 × 2 bytes)
타입: ushort[]
인덱스 범위: 0-8191 (13비트 랭크 조합)
용도: topCardTable[] 대체
```

**레이아웃**:
```
[offset 0]  → topCard[0]  (2 bytes, little-endian ushort)
[offset 2]  → topCard[1]
...
[offset 16382] → topCard[8191]
```

**로드 방식**: topFiveCards.bin과 동일, 2바이트 단위 `ReadUInt16()` 사용

---

## 4. 538개 정적 배열 초기화

`Hand.cs`의 `.cctor` (static constructor)에서 **538개 정적 배열**을 초기화한다. 모든 lookup table은 애플리케이션 시작 시 한 번만 계산되며, 이후 전역 상수처럼 사용된다.

### 초기화 과정

```csharp
static Hand() {
    // 1. CardMasksTable 초기화 (52장 카드 bitmask)
    for (int i = 0; i < 52; i++) {
        int rank = i % 13;
        int suit = i / 13;
        CardMasksTable[i] = 1UL << (rank + suit * 13);
    }

    // 2. CardTable 초기화 (52장 카드 문자열)
    string[] ranks = {"2","3","4","5","6","7","8","9","T","J","Q","K","A"};
    string[] suits = {"c","d","h","s"};
    for (int i = 0; i < 52; i++) {
        CardTable[i] = ranks[i % 13] + suits[i / 13];
    }

    // 3. nBitsTable 초기화 (0-8191 popcount)
    for (int i = 0; i < 8192; i++) {
        nBitsTable[i] = (ushort)CountBits(i);
    }

    // 4. straightTable 초기화 (Straight 감지)
    for (int i = 0; i < 8192; i++) {
        straightTable[i] = CheckStraight(i);
    }

    // 5. topFiveCardsTable 초기화 (상위 5장)
    for (int i = 0; i < 8192; i++) {
        topFiveCardsTable[i] = TopFive(i);
    }

    // 6. topCardTable 초기화 (최상위 카드)
    for (int i = 0; i < 8192; i++) {
        topCardTable[i] = TopCard(i);
    }

    // 7. nBitsAndStrTable 초기화 (결합 정보)
    for (int i = 0; i < 8192; i++) {
        nBitsAndStrTable[i] = (ushort)((nBitsTable[i] << 4) | (straightTable[i] & 0xF));
    }

    // 8. bits 초기화 (0-255 바이트 popcount)
    for (int i = 0; i < 256; i++) {
        bits[i] = (byte)CountBits(i);
    }

    // ... 나머지 530개 배열 (게임별 사전 계산 테이블)
}
```

**총 초기화 시간**: ~50ms (첫 Hand 클래스 접근 시)

---

## 5. 메모리 사용량 분석

### 5.1 핵심 8개 테이블

| 테이블 | 타입 | 크기 | 메모리 |
|--------|------|:----:|:------:|
| nBitsTable | ushort[8192] | 16KB | 16,384 bytes |
| straightTable | ushort[8192] | 16KB | 16,384 bytes |
| topFiveCardsTable | uint[8192] | 32KB | 32,768 bytes |
| topCardTable | ushort[8192] | 16KB | 16,384 bytes |
| nBitsAndStrTable | ushort[8192] | 16KB | 16,384 bytes |
| bits | byte[256] | 256B | 256 bytes |
| CardMasksTable | ulong[52] | 416B | 416 bytes |
| CardTable | string[52] | ~1KB | ~1,040 bytes |

**소계**: ~97KB

### 5.2 게임별 사전 계산 테이블 (530개)

- **Hold'em PreCalc**: `PreCalcPlayerOdds[169][9]`, `PreCalcOppOdds[169][9]` → ~50KB
- **Omaha 조합**: `OmahaEvaluator` C(52,4) = 270,725개 → ~1.0MB
- **Omaha5 조합**: `Omaha5Evaluator` C(52,5) = 2,598,960개 → ~10MB (메모리 아님, 계산 캐시)
- **Short Deck 상수**: `holdem_sixplus` dead cards, wheel 패턴 → ~1KB
- **Stud/Draw 테이블**: 각종 조합 캐시 → ~100KB

**총 메모리**: ~**2.1MB** (정적 배열 + 게임별 캐시)

### 5.3 Memory-Mapped 파일 사용 시

- **topFiveCards.bin** 로드: 32KB → 메모리 절약 (lazy load)
- **topCard.bin** 로드: 16KB → 메모리 절약 (lazy load)
- **omaha6.vpt** 로드: C(52,6) × 128 bytes ≈ **2.6GB** (디스크, 필요 시 페이징)

**절약 효과**: 메모리 상주 테이블 48KB 감소, Omaha6은 디스크 I/O로 대체

---

## 6. Thread-Safe 초기화

`TopTables.cs`는 **Double-checked locking**으로 thread-safe lazy 초기화를 수행한다.

```csharp
private static uint[] topFiveCardsTable;
private static volatile bool initialized = false;
private static object lockObj = new object();

public static uint GetTopFive(int index) {
    if (!initialized) {
        lock (lockObj) {
            if (!initialized) {
                LoadTopFiveTables();
                initialized = true;
            }
        }
    }
    return topFiveCardsTable[index];
}

private static void LoadTopFiveTables() {
    if (File.Exists("topFiveCards.bin")) {
        // Memory-mapped 로드
    } else {
        // In-memory 생성
    }
}
```

**보장 사항**:
1. 여러 스레드가 동시 접근해도 초기화는 단 1회만 실행
2. `volatile` 키워드로 CPU 캐시 무효화 (visibility 보장)
3. 초기화 완료 전까지 다른 스레드는 lock 대기

---

## 7. CardMask 비트 표현

모든 카드는 64비트 `ulong`의 단일 비트로 표현된다. 52장이 4개 suit 영역에 각 13비트씩 배치된다.

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

### Suit Offset 상수

```csharp
CLUB_OFFSET    = 13 * 0 = 0
DIAMOND_OFFSET = 13 * 1 = 13
HEART_OFFSET   = 13 * 2 = 26
SPADE_OFFSET   = 13 * 3 = 39
```

### 카드 마스크 공식

```csharp
// 단일 카드 bitmask 생성
ulong mask = 1UL << (rank + suit * 13);

// 예시:
// Ace of Spades (rank=12, suit=3): 1UL << (12 + 39) = 1UL << 51
// Two of Clubs (rank=0, suit=0):   1UL << 0
```

### Suit Mask 추출

```csharp
ulong cards = 0x123456789ABCDEF0;  // 임의의 핸드

int clubs    = (int)((cards >> 0)  & 0x1FFF);  // bits 0-12
int diamonds = (int)((cards >> 13) & 0x1FFF);  // bits 13-25
int hearts   = (int)((cards >> 26) & 0x1FFF);  // bits 26-38
int spades   = (int)((cards >> 39) & 0x1FFF);  // bits 39-51

int ranks = clubs | diamonds | hearts | spades;  // 결합 랭크
```

---

## 8. 게임별 Evaluator와 Lookup Table 사용

`core.evaluate_hand()`와 `core.calc_odds()`가 게임 문자열에 따라 라우팅한다.

| 게임 문자열 | Evaluator | Lookup 사용 | 비고 |
|------------|-----------|------------|------|
| **HOLDEM** | `Hand.Evaluate` | nBits, straight, topFive, topCard | Texas Hold'em, 7장 중 최고 5장 |
| **PINEAPPL** | `Hand.Evaluate` | 동일 | Pineapple (Hold'em과 동일 평가) |
| **6THOLDEM** | `holdem_sixplus.eval` | nBits, straight (수정), topFive | Short Deck, trips > straight |
| **6PHOLDEM** | `holdem_sixplus.eval` | nBits, straight (수정), topFive | Short Deck, 표준 랭킹 |
| **OMAHA** | `OmahaEvaluator.EvaluateHigh` | PreCalc 270,725개 조합 | 4카드 Omaha, 정확히 2장 사용 |
| **OMAHAHL** | `OmahaEvaluator` + EvaluateLow | PreCalc + A-5 Low | Omaha Hi-Lo, 8-or-better |
| **OMAHA5** | `Omaha5Evaluator.EvaluateHigh` | PreCalc 2,598,960개 조합 | 5카드 Omaha |
| **COUR** | `Omaha5Evaluator` | 동일 | Courchevel |
| **OMAHA6** | `Omaha6Evaluator.EvaluateHigh` | omaha6.vpt (memory-mapped) | 6카드 Omaha, C(52,6) 20M+ |
| **5DRAW** | `draw.HandOdds` | Hand.Evaluate (5장 고정) | Five-card Draw |
| **27DRAW** | `draw.HandOdds(seven_deuce_lowball=true)` | A-5 Low 반전 | 2-7 Single Draw |
| **27TRIPLE** | `draw.HandOdds(seven_deuce_lowball=true)` | A-5 Low 반전 | 2-7 Triple Draw |
| **A5TRIPLE** | `draw.a5_HandOdds` | A-5 Low | A-5 Triple Draw |
| **BADUGI** | `draw.badugi` | 커스텀 Low (4-suit) | Badugi |
| **BADEUCY** | `draw.badugi` | Badugi + 2-7 Low | Badeucy |
| **BADACEY** | `draw.badugi` | Badugi + A-5 Low | Badacey |
| **7STUD** | `stud.odds` | Hand.Evaluate (7장) | 7-Card Stud |
| **7STUDHL** | `stud.odds` + EvaluateLow | Hand.Evaluate + A-5 Low | 7-Card Stud Hi-Lo |
| **RAZZ** | `Razz.Evaluate` | A-5 Low 전용 | Razz (Stud Low) |

**공통 패턴**:
- Hold'em 계열: `Hand.Evaluate` + 8개 핵심 lookup table 직접 사용
- Omaha 계열: 사전 계산 조합 테이블 + `Hand.Evaluate` 간접 사용
- Draw 계열: `Hand.Evaluate` + Low 변형 로직
- Stud 계열: `Hand.Evaluate` + Low 평가 추가

---

## 9. Short Deck 변형 상수

Short Deck (6+ Hold'em, holdem_sixplus.cs, 783줄)은 **2, 3, 4, 5를 제거한 36장 덱**이다.

### Dead Cards 상수

```csharp
// 제거된 16장 카드의 bitmask (2, 3, 4, 5 × 4 suits)
public const ulong DEAD_CARDS = 8247343964175;

// 비트 분해:
// 0x780F780F780F (hex)
// = 0b0111_1000_0000_1111_0111_1000_0000_1111_0111_1000_0000_1111 (binary)
//     ^^^^ ^^^^ ^^^^ ^^^^  (각 suit의 bit 0-3이 SET)
```

**계산 방식**:
```csharp
ulong deadCards = 0;
for (int suit = 0; suit < 4; suit++) {
    for (int rank = 0; rank < 4; rank++) {  // 2, 3, 4, 5 (rank 0-3)
        deadCards |= (1UL << (rank + suit * 13));
    }
}
// deadCards = 8247343964175
```

### Wheel 패턴 (A-6-7-8-9)

```csharp
// 표준 Hold'em Wheel: A-2-3-4-5 (bitmask 0x100F)
// Short Deck Wheel:  A-6-7-8-9 (bitmask 4336)

public const int WHEEL_PATTERN = 4336;

// 비트 분해:
// 4336 = 0b0001_0001_0000_0000
//          ^    ^     ^^^^
//         Ace   9   8 7 6
```

**6THOLDEM 변형 랭킹 교환**:
```csharp
if (handType == HandType.Trips) {
    handType = HandType.Straight;  // Trips가 Straight를 이긴다
} else if (handType == HandType.Straight) {
    handType = HandType.Trips;
}

if (handType == HandType.Flush) {
    handType = HandType.FullHouse;  // Flush가 FullHouse를 이긴다
} else if (handType == HandType.FullHouse) {
    handType = HandType.Flush;
}
```

---

## 10. Omaha6 Memory-Mapped 파일

Omaha6 (6카드 Omaha)는 **C(52,6) = 20,358,520개** 조합을 처리한다. 모든 조합을 메모리에 올리면 수 GB가 필요하므로, **memory-mapped 파일** `omaha6.vpt`를 사용한다.

### 파일 구조

```
파일 크기: 20,358,520 × 128 bytes ≈ 2.6GB
레코드 크기: 128 bytes
총 레코드 수: 20,358,520개 (C(52,6))
```

### 레코드 레이아웃 (128 bytes)

```
[offset 0-7]   ulong hand        (6장 카드 bitmask)
[offset 8-11]  uint  hiValue     (High 핸드 평가값)
[offset 12-15] short lowValue    (Low 핸드 평가값, -1이면 없음)
[offset 16-127] byte[112] reserved (미사용, 패딩)
```

### 인덱싱

```csharp
// 6장 조합 → 인덱스 매핑 (lexicographic order)
int index = CombinationIndex(c1, c2, c3, c4, c5, c6);  // 0 ~ 20,358,519

// Memory-mapped 파일 접근
using (var accessor = mmf.CreateViewAccessor(index * 128, 128)) {
    ulong hand = accessor.ReadUInt64(0);
    uint hiValue = accessor.ReadUInt32(8);
    short lowValue = accessor.ReadInt16(12);
}
```

### 성능 최적화

- **페이징**: OS가 자동으로 필요한 영역만 메모리에 로드 (demand paging)
- **캐싱**: 자주 접근하는 조합은 OS 페이지 캐시에 상주
- **순차 접근**: lexicographic 순서로 배치하여 캐시 친화성 증가

**초기 로드 시간**: ~100ms (파일 핸들만 열기, 데이터는 lazy load)

---

## 11. 암호화 및 보안

### 11.1 암호화 여부

Lookup table 파일은 **암호화되지 않은 plain binary 포맷**이다.

- `topFiveCards.bin`: Little-endian uint[] (4 bytes/entry)
- `topCard.bin`: Little-endian ushort[] (2 bytes/entry)
- `omaha6.vpt`: 고정 128 bytes/record, little-endian

**검증 방법**: 파일을 HEX 에디터로 열면 직접 값 확인 가능

### 11.2 무결성 검증

**없음**. 파일 손상 시 평가 결과 오류가 발생하지만, CRC/checksum 검증 로직은 존재하지 않음.

**Fallback 메커니즘**:
- 파일 없음/손상 → 인메모리 배열 생성 (`GenerateTopFiveCards()`)
- 인덱스 범위 초과 → ArrayIndexOutOfBounds 예외 (catch 후 fallback)

### 11.3 파일 경로

```csharp
// 실행 파일과 동일 디렉토리에서 검색
string basePath = AppDomain.CurrentDomain.BaseDirectory;
string topFivePath = Path.Combine(basePath, "topFiveCards.bin");
string topCardPath = Path.Combine(basePath, "topCard.bin");
string omaha6Path = Path.Combine(basePath, "omaha6.vpt");
```

**배포 시 주의**: 3개 파일을 실행 파일과 동일 디렉토리에 배치 필수

---

## 마무리

PokerGFX Lookup Tables는 **사전 계산 + Bitmask 기반 O(1) 평가**의 정교한 구현체이다. 538개 정적 배열과 memory-mapped 파일을 결합하여 17개 포커 게임 변형을 단일 엔진에서 지원하며, thread-safe lazy 초기화로 멀티스레드 환경에서도 안전하게 동작한다.

**핵심 장점**:
- **속도**: O(1) 평가, 1초에 수백만 핸드 처리 가능
- **메모리 효율**: Memory-mapped 파일로 2.6GB Omaha6 데이터를 디스크 I/O로 처리
- **확장성**: 새 게임 추가 시 lookup table 확장으로 대응 가능
- **안정성**: Double-checked locking으로 race condition 방지

**한계**:
- 암호화/무결성 검증 부재 → 파일 변조 가능
- Omaha6 파일 크기 (2.6GB) → 디스크 용량 소모
- 초기화 시간 (~50ms) → 첫 평가 시 레이턴시

---

**문서 이력**:
- 2026-02-17: v1.0.0 초안 작성 (역공학 문서 Section 6 기반)
