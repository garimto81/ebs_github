# BS-06-1X: Flop Variants — Hold'em 대비 차이점 통합

> **존재 이유**: Short Deck/Pineapple/Omaha/Courchevel 4종 variant 차이점을 단일 비교 문서로 제공. 각 variant 구현 사양 (`lib/core/variants/short_deck.dart`, `pineapple.dart`, `omaha.dart`, `courchevel.dart`)이 참조.
>
> **통합 이력**: 2026-04-14 — BS-06-11/12/13/14 4개 파일을 통합. 동일한 "Hold'em 대비 차이점" 패턴으로 비교가 자연스러운 그룹.

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-06 | 신규 작성 | 4개 variant 개별 작성 (BS-06-11~14) |
| 2026-04-09 | Phase 표시 | Pineapple/Courchevel은 Phase 3, Short Deck/Omaha는 Phase 2 |
| 2026-04-14 | **통합** | 4개 파일 → 단일 문서. 중복 용어 해설/구조 제거 |

---

## 공통 용어

| 용어 | 설명 |
|------|------|
| FSM | 게임 진행 단계를 정의한 상태 흐름도 (Finite State Machine) |
| RFID | 무선 주파수로 카드를 자동 인식하는 기술. 카드에 내장된 IC를 테이블 센서가 읽는다 |
| evaluator | 카드 조합을 분석하여 승자를 결정하는 함수 |
| coalescence | 여러 센서 신호가 동시에 들어올 때 하나로 합치는 처리 규칙 |
| CC | Command Center, 운영자가 게임을 제어하는 화면 |
| antenna | RFID 카드를 감지하는 센서 (seat / board / burn zone) |
| must-use 2+3 | 홀카드 정확히 2장 + 보드 정확히 3장 사용 (Omaha/Courchevel 규칙) |
| Hi-Lo | 팟을 가장 높은 패와 가장 낮은 패로 나누어 분배 |
| 8-or-better | 5장 모두 rank ≤ 8, 서로 다른 rank → Low 자격 |
| scoop | 한 사람이 양쪽 팟 모두 가져가는 것 |
| odd chip | 팟을 나눌 때 딱 떨어지지 않는 1개 베팅 토큰 |

---

## Variant Quick Comparison

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

---

## §1. Short Deck Hold'em (game 1, 2)

> **Status**: Phase 2 — Hold'em Core 직후 착수.

### 개요

Hold'em과 동일 프로세스를 따르되, **36장 덱**과 **수정된 핸드 랭킹**을 적용한다. `game_id=1`은 Straight > Trips, `game_id=2`는 Trips > Straight (Triton Poker 룰).

### 덱 구성

랭크 2~5를 제거하고 6~A만 사용. 9 ranks × 4 suits = 36장.

### 확률 변화

| 핸드 | 52장 기준 | 36장 기준 |
|------|---------|---------|
| Flush | 일반적 | 난이도 증가 (수트당 13→9장) |
| Straight | 일반적 | 빈도 변화 (범위 6~A로 축소) |
| Full House | 일반적 | 빈도 증가 (페어/트립스 확률 상승) |

### 핸드 랭킹

#### game_id = 1: Straight > Trips (`holdem_sixplus_straight`)

| 순위 | 핸드 |
|:----:|------|
| 1 | Royal Flush |
| 2 | Straight Flush |
| 3 | Four of a Kind |
| 4 | **Flush** |
| 5 | **Full House** |
| 6 | **Straight** |
| 7 | **Three of a Kind** |
| 8 | Two Pair |
| 9 | One Pair |
| 10 | High Card |

#### game_id = 2: Trips > Straight (`holdem_sixplus_trips`)

| 순위 | 핸드 |
|:----:|------|
| 1 | Royal Flush |
| 2 | Straight Flush |
| 3 | Four of a Kind |
| 4 | **Flush** |
| 5 | **Full House** |
| 6 | **Three of a Kind** |
| 7 | **Straight** |
| 8 | Two Pair |
| 9 | One Pair |
| 10 | High Card |

### RFID 검증

| 트리거 | 감지 조건 | 처리 |
|--------|---------|------|
| RFID 자동 | 랭크 2~5 카드 UID 감지 | **WRONG_CARD** 에러 |
| 게임 엔진 | `deck_size`=36인데 36장 외 입력 | **WRONG_CARD** 에러 |

### 매트릭스: 덱 초기화

| 조건 | 결과 |
|------|------|
| 36장 정확히 감지 | 정상 — 핸드 시작 |
| 36장 미만 / 초과 | **Miss Deal** — IDLE 복귀 |

### 구현 체크리스트

- [ ] 36장 덱 필터링 (2~5 제거)
- [ ] `game_id`=1: Straight > Trips
- [ ] `game_id`=2: Trips > Straight
- [ ] RFID 덱 스캔 36장 검증
- [ ] 유효하지 않은 카드 → WRONG_CARD
- [ ] `evaluator` = `standard_high_modified` 라우팅

---

## §2. Pineapple (game 3)

> **Status**: Phase 3 — Hold'em Core 완료 후 착수.

### 개요

Hold'em과 동일하되, 3장 딜 후 1장 버리는 **DISCARD_PHASE**가 추가된다.

### FSM 변경 — DISCARD_PHASE 추가

```
IDLE → SETUP_HAND → PRE_FLOP (3장 보유)
  → DISCARD_PHASE (1장 버림)
  → FLOP → TURN → RIVER → SHOWDOWN → HAND_COMPLETE
```

### DISCARD_PHASE 정의

| 속성 | 값 |
|------|-----|
| **Entry** | PRE_FLOP 베팅 완료 |
| **hand_in_progress** | true |
| **action_on** | -1 (전체 대기) |
| **board_cards** | 0 |
| **처리** | 각 active 플레이어가 3장 중 1장 폐기 |
| **Exit** | 모든 active 플레이어 discard 완료 → **FLOP** |
| **타임아웃** | 30초 후 CC 수동 입력 모드 |

### Entry/Exit 매트릭스

| Entry | Exit | 다음 상태 |
|-------|------|----------|
| PRE_FLOP 베팅 완료 | 모든 active discard 완료 | FLOP |
| PRE_FLOP 베팅 완료 | 30초 + CC 수동 | FLOP |
| PRE_FLOP all fold (1명) | — | HAND_COMPLETE (DISCARD_PHASE 스킵) |

### RFID Discard 감지

| 속성 | 값 |
|------|-----|
| 감지 위치 | burn zone antenna #11 |
| 감지 순서 | 좌석별 비동기 (순서 강제 없음) |
| 폴드 플레이어 | discard 불필요, 자동 스킵 |
| 기록 | `Player {seat} discarded {card}` |

### 추가 상태변수

| 변수 | 초기값 | 동작 |
|------|--------|------|
| `discard_pending` | active 플레이어 수 | 각 discard마다 -1, 0이면 FLOP 전이 |

### Coalescence

| 항목 | 규칙 |
|------|------|
| CC 허용 | 없음 (자동 대기) |
| 예상 RFID | discard 1장/인 (#11) |
| Engine Auto | 모든 discard 완료 시 자동 FLOP 전이 |

### Bomb Pot 상호작용

| 모드 | DISCARD_PHASE | 이유 |
|:----:|:------------:|------|
| OFF | 정상 진입 | 표준 흐름 |
| ON | **스킵** | PRE_FLOP 스킵 → DISCARD_PHASE도 스킵 |

### 구현 체크리스트

- [ ] DISCARD_PHASE 상태 추가 (FSM enum)
- [ ] `discard_pending` 카운터
- [ ] 3장 딜 RFID (SETUP_HAND, 3장/인)
- [ ] burn zone #11 discard 감지
- [ ] 비동기 완료 추적
- [ ] DISCARD_TIMEOUT 30초 → 수동 모드
- [ ] 폴드 좌석 자동 스킵
- [ ] Bomb Pot에서 DISCARD_PHASE 스킵
- [ ] Miss Deal 기준: 홀카드 != 3
- [ ] CC 버튼 비활성 (UNDO 제외)

---

## §3. Omaha (game 4–9)

> **Status**: Phase 2 — Hold'em Core 직후 착수.

### 대상 게임

| `game_id` | 이름 | `hole_cards` | Hi-Lo |
|:--:|------|:--:|:--:|
| 4 | omaha | 4 | N |
| 5 | omaha_hilo | 4 | Y |
| 6 | omaha5 | 5 | N |
| 7 | omaha5_hilo | 5 | Y |
| 8 | omaha6 | 6 | N |
| 9 | omaha6_hilo | 6 | Y |

### 핵심 규칙: Must-Use 2+3

홀카드 **정확히 2장** + 보드 **정확히 3장** = 5장 핸드. Hold'em "best 5 of 7"과 다름.

### 조합 수

| `hole_cards` | C(n,2) | C(5,3) | 총 평가 조합 |
|:--:|:--:|:--:|:--:|
| 4 | 6 | 10 | 60 |
| 5 | 10 | 10 | 100 |
| 6 | 15 | 10 | 150 |

> Hold'em은 C(7,5)=21. Omaha 6은 7배 이상 연산량 증가.

### Hi-Lo (game 5, 7, 9)

**High pot**: `standard_high` + must-use 2+3
**Low pot**: 5장 모두 rank ≤ 8, 서로 다른 rank, A=Low, must-use 2+3

8-or-better 미충족 시 High가 전체 팟 수령(scoop). Odd chip은 High에 배분.

### Hi-Lo 분배 매트릭스

| High 승자 | Low 자격 | Low 승자 | 분배 |
|:--:|:--:|:--:|------|
| A | 충족 | B | A 50%, B 50% |
| A | 충족 | A | A 100% (scoop) |
| A | 미충족 | — | A 100% (scoop) |
| A 타이 | 충족 | B | High 타이 분할 + Low 50% |
| A | 충족 | B,C 타이 | A 50%, B 25%, C 25% |

### Coalescence — Omaha 6 큐 오버플로우

| 조건 | 처리 |
|------|------|
| `len(Event_Q)` ≥ 32 | 최저 우선순위 이벤트 폐기 |
| 폐기 이벤트 | `QUEUE_OVERFLOW` 로그, 운영자 재스캔 안내 |
| 홀카드 vs 보드 | 홀카드가 보드보다 높은 서브 우선순위 |

> Omaha 6은 유일하게 `MAX_QUEUE_SIZE=32` 초과 가능. 큐 확장 또는 배치 처리 검토.

### 구현 체크리스트

- [ ] `hole_cards` 4/5/6장 배분 + RFID
- [ ] Must-Use 2+3 조합 (C(n,2) × C(5,3))
- [ ] Hi-Lo split (`hilo_8or_better`)
- [ ] Low 미자격 시 High scoop
- [ ] Odd chip → High
- [ ] Omaha 6 큐 오버플로우 처리

---

## §4. Courchevel (game 10, 11)

> **Status**: Phase 3 — Hold'em Core 완료 후 착수.

### 개요

Omaha 5장 방식이지만 SETUP에서 **`board_1`**(첫 보드 카드)이 미리 공개. FLOP에서 추가 2장만 공개. 평가는 Omaha와 동일 (must-use 2+3).

### 대상 게임

| `game_id` | 이름 | `evaluator` | Hi-Lo |
|:--:|------|------|:--:|
| 10 | courchevel | `standard_high` | N |
| 11 | courchevel_hilo | `hilo_8or_better` | Y |

### SETUP_HAND 확장

| 항목 | Hold'em | Courchevel |
|------|---------|------------|
| 홀카드 | 2장 | 5장 |
| 보드 | 0장 | **1장** (`board_1`) |
| RFID | seat | seat + board **동시** |
| Exit | 홀카드 완전 감지 | 홀카드 + `board_1` 감지 |

- `board_1`은 즉시 오버레이 표시
- PRE_FLOP 베팅은 `board_1` 공개 상태에서 진행

### RFID 시퀀스

```
SETUP:  [홀카드] 5장 + [보드] 1장 → board_cards = [board_1]
FLOP:   board_cards += [card2, card3] → 길이 3
TURN:   board_cards += [card4] → 길이 4
RIVER:  board_cards += [card5] → 길이 5
```

### FLOP 카드 검증

| 조건 | 처리 |
|------|------|
| board 2장 감지 | 정상 진행 |
| board 3장 감지 | **WRONG_CARD** 에러 (`board_1` 중복) |
| board 1장만 | 타임아웃 → 수동 입력 |

### 핸드 평가

§3 Omaha와 동일 (must-use 2+3, C(5,2)×C(5,3) = 100 조합). game 11의 Hi-Lo도 §3과 동일.

### 구현 체크리스트

- [ ] SETUP에서 `board_1` 동시 RFID 감지
- [ ] `board_1` 오버레이 즉시 표시
- [ ] FLOP 추가 2장만 (3장 시 WRONG_CARD)
- [ ] Hole/`board_1` 동일 우선순위 병렬
- [ ] `board_1` 미감지 타임아웃
- [ ] Hi-Lo split (game 11)
- [ ] Low 미자격 시 High scoop
- [ ] Odd chip → High
