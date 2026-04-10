# BS-06-21: Draw Games — 라이프사이클 및 카드 교환

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-06 | 신규 작성 | Draw 7종 FSM 정의, DRAW_ROUND 상세 메카닉, RFID 교환 순서 강제, 유저 스토리 8개 |
| 2026-04-09 | Phase 표시 | **Phase 3 범위** — Hold'em Core 구현 완료 후 착수 |

---

> **이 문서에서 사용하는 용어**
>
> | 용어 | 설명 |
> |------|------|
> | FSM | 게임 진행 단계를 정의한 상태 흐름도 (Finite State Machine) |
> | RFID | 무선 주파수로 카드를 자동 인식하는 기술 |
> | CC | Command Center, 운영자가 게임을 제어하는 화면 |
> | evaluator | 카드 조합을 분석하여 승자를 결정하는 함수 |
> | coalescence | 여러 센서 신호가 동시에 들어올 때 하나로 합치는 처리 규칙 |
> | antenna | RFID 카드를 감지하는 센서 |
> | 비트마스크 | 각 플레이어 완료 여부를 0/1로 추적하는 방식 |
> | 홀카드(hole card) | 각 플레이어에게 비공개로 나눠주는 카드 |
> | draw | 카드를 교환하는 행위 |
> | stand pat | 카드를 하나도 교환하지 않는 것 |
> | reshuffling | 덱 카드가 부족할 때 버린 카드를 다시 섞어 사용하는 것 |
> | burn | 카드 1장을 사용하지 않고 버리는 것 (부정 방지) |
> | All-in | 보유 금액 전부를 건 상태 |
> | SB/BB | Small Blind / Big Blind |
> | UTG | Under The Gun, 블라인드 바로 다음 좌석의 플레이어 |

## 개요

Draw 게임은 보드 카드 없이, 플레이어가 홀카드를 교환하는 라운드를 가진다. Hold'em의 베팅/팟/쇼다운 규칙은 공유하지만, FSM과 카드 처리가 근본적으로 다르다.

**Hold'em과의 핵심 차이**:
- 보드 카드가 없음 — 플레이어 홀카드만으로 핸드 구성
- FLOP/TURN/RIVER 상태가 없고, 대신 DRAW_ROUND(교환) + POST_DRAW_BET(교환 후 베팅) 반복
- RFID 추적 대상이 홀카드만 (보드 안테나 미사용)
- 카드 교환 시 discard/new dealt 순서가 강제됨

---

## 대상 게임

| `game_id` | 이름 | `draw_count` | `hole_cards` | 베팅 라운드 |
|:--:|------|:--:|:--:|:--:|
| 12 | draw5 | 1 | 5 | 2 |
| 13 | deuce7_draw | 1 | 5 | 2 |
| 14 | deuce7_triple | 3 | 5 | 4 |
| 15 | a5_triple | 3 | 5 | 4 |
| 16 | badugi | 3 | 4 | 4 |
| 17 | badeucy | 3 | 5 | 4 |
| 18 | badacey | 3 | 5 | 4 |

> 참고: `draw_count` = 1인 게임(12, 13)은 베팅 2회(PRE_DRAW + POST_DRAW), `draw_count` = 3인 게임(14~18)은 베팅 4회(PRE_DRAW + POST_DRAW x 3).

---

## FSM 정의

### 상태 다이어그램

```
IDLE
  │
  ▼  SendStartHand()
SETUP_HAND
  │
  ▼  홀카드 딜 완료 (RFID 감지)
PRE_DRAW_BET
  │
  ▼  베팅 완료
DRAW_ROUND[1]
  │
  ▼  모든 active 플레이어 교환 완료
POST_DRAW_BET[1]
  │
  ├─ draw_count == 1 ──────────────────┐
  │                                     │
  ▼  draw_count > 1                     │
DRAW_ROUND[2]                           │
  │                                     │
  ▼  교환 완료                          │
POST_DRAW_BET[2]                        │
  │                                     │
  ▼  draw_count == 3                    │
DRAW_ROUND[3]                           │
  │                                     │
  ▼  교환 완료                          │
POST_DRAW_BET[3]                        │
  │                                     │
  ▼ ◄──────────────────────────────────┘
SHOWDOWN
  │
  ▼  우승자 결정
HAND_COMPLETE
  │
  ▼  초기화
IDLE
```

### 상태별 정의

#### IDLE

| 항목 | 값 |
|------|-----|
| **Entry 조건** | 앱 시작 OR 이전 핸드 HAND_COMPLETE |
| **Exit 조건** | SendStartHand() 호출 |
| **`hand_in_progress`** | false |
| **`action_on`** | -1 (없음) |
| **트리거** | CC "NEW HAND" 버튼 (운영자 수동) |
| **UI 상태** | 테이블 대기 화면, "NEW HAND" 버튼 활성 |

> 참고: Hold'em IDLE과 동일.

---

#### SETUP_HAND

| 항목 | 값 |
|------|-----|
| **Entry 조건** | SendStartHand() 성공 |
| **Exit 조건** | 모든 active 플레이어 홀카드 RFID 감지 완료 |
| **`hand_in_progress`** | true |
| **`hand_number`** | 이전 + 1 |
| **딜 카드 수** | `hole_cards` (게임별: 4 또는 5장) |
| **트리거** | 게임 엔진 자동 (블라인드 수납 → 딜 시작) |
| **UI 상태** | 블라인드/앤티 수납 표시, 홀카드 배분 애니메이션 |

**게임별 딜 카드 수**:

| `game_id` | 딜 카드 수 |
|:--:|:--:|
| 12, 13, 14, 15, 17, 18 | 5장 |
| 16 | 4장 |

**RFID 감지**: 각 플레이어의 seat antenna에서 `hole_cards`장 감지 완료 시 다음 상태로 전이.

---

#### PRE_DRAW_BET

| 항목 | 값 |
|------|-----|
| **Entry 조건** | 홀카드 딜 완료 |
| **Exit 조건** | 모든 active 플레이어 액션 완료, 베팅액 균등 |
| **`action_on`** | UTG (BB 다음 플레이어) |
| **베팅 규칙** | Hold'em PRE_FLOP과 동일 (fold/call/raise/all-in) |
| **트리거** | CC 버튼 (운영자) — CHECK, BET, FOLD, CALL, RAISE, ALL-IN |
| **UI 상태** | 액션 버튼 활성, 현재 `action_on` 플레이어 강조 |

> 참고: 블라인드 기반 강제 베팅. bring-in 없음.

---

#### DRAW_ROUND[N]

| 항목 | 값 |
|------|-----|
| **Entry 조건** | PRE_DRAW_BET 완료 (N=1) 또는 POST_DRAW_BET[N-1] 완료 (N>1) |
| **Exit 조건** | 모든 active 플레이어 교환 완료 (`draw_completed` 비트마스크 전체 set) |
| **N 범위** | 1 ~ `draw_count` (게임별 1 또는 3) |
| **`action_on`** | SB 또는 첫 active 플레이어 (딜러 좌측부터) |
| **트리거** | CC "DRAW N" 버튼 또는 "STAND PAT" 버튼 (운영자 수동) |
| **UI 상태** | 교환 장수 선택 UI, STAND PAT 버튼, 교환 진행 상태 표시 |

**핵심 — Hold'em에 없는 상태**:
- 플레이어가 교환할 카드를 선택 (0 ~ `hole_cards`장)
- **STAND PAT** = 교환 없음 선언 (0장 교환)
- 교환 순서: SB부터 시계 방향, 각 플레이어 순차 처리

**교환 수량 제한**:

| `game_id` | `hole_cards` | 최대 교환 수 |
|:--:|:--:|:--:|
| 12, 13, 14, 15, 17, 18 | 5 | 5장 (전부 교환 가능) |
| 16 | 4 | 4장 (전부 교환 가능) |

---

#### POST_DRAW_BET[N]

| 항목 | 값 |
|------|-----|
| **Entry 조건** | DRAW_ROUND[N] 완료 |
| **Exit 조건** | 모든 active 플레이어 액션 완료, 베팅액 균등 |
| **`action_on`** | SB 또는 첫 active 플레이어 (딜러 좌측부터) |
| **베팅 규칙** | Hold'em과 동일 (fold/check/bet/call/raise/all-in) |
| **다음 상태 판단** | N < `draw_count` → DRAW_ROUND[N+1], N == `draw_count` → SHOWDOWN |
| **트리거** | CC 버튼 (운영자) |
| **UI 상태** | 액션 버튼 활성, 베팅 라운드 번호 표시 |

---

#### SHOWDOWN

| 항목 | 값 |
|------|-----|
| **Entry 조건** | POST_DRAW_BET[final] 완료 AND active 플레이어 >= 2 |
| **Exit 조건** | 우승자 결정 |
| **`evaluator`** | 게임별 평가 함수 (BS-06-22 참조) |
| **트리거** | 게임 엔진 자동 |
| **UI 상태** | 핸드 공개, 승자 강조 |

> 참고: Hold'em SHOWDOWN과 동일한 쇼다운 로직 적용 (BS-06-07).

---

#### HAND_COMPLETE

| 항목 | 값 |
|------|-----|
| **Entry 조건** | SHOWDOWN 완료 OR All Fold (active 플레이어 == 1) |
| **Exit 조건** | 팟 분배 + 통계 기록 완료 |
| **`hand_in_progress`** | false로 리셋 |
| **트리거** | 게임 엔진 자동 |
| **UI 상태** | 우승자 표시, 팟 금액 표시, 통계 업데이트 |

> 참고: Hold'em HAND_COMPLETE와 동일 (BS-06-01).

---

### 상태 전이 매트릭스

| 현재 상태 | 트리거 | 다음 상태 |
|----------|--------|----------|
| **IDLE** | CC "NEW HAND" | SETUP_HAND |
| **SETUP_HAND** | RFID 홀카드 완전 감지 | PRE_DRAW_BET |
| **PRE_DRAW_BET** | 베팅 완료 | DRAW_ROUND[1] |
| **PRE_DRAW_BET** | All Fold (1명 생존) | HAND_COMPLETE |
| **DRAW_ROUND[N]** | 모든 플레이어 교환 완료 | POST_DRAW_BET[N] |
| **POST_DRAW_BET[N]** | 베팅 완료, N < `draw_count` | DRAW_ROUND[N+1] |
| **POST_DRAW_BET[N]** | 베팅 완료, N == `draw_count` | SHOWDOWN |
| **POST_DRAW_BET[N]** | All Fold (1명 생존) | HAND_COMPLETE |
| **SHOWDOWN** | 우승자 결정 | HAND_COMPLETE |
| **HAND_COMPLETE** | 초기화 완료 | IDLE |

---

## DRAW_ROUND 상세 메카닉

### 카드 교환 절차

단계별 흐름 (각 플레이어에 대해 순차 처리):

| 단계 | 행위 | 발동 주체 | RFID |
|:--:|------|---------|------|
| 1 | CC "DRAW N" 버튼 (교환 장수 선언) 또는 "STAND PAT" 버튼 | 운영자 수동 | 없음 |
| 2 | 플레이어가 discard할 카드를 테이블에 놓음 | 플레이어 물리 액션 | 없음 |
| 3 | burn zone antenna(버린 카드를 감지하는 안테나 영역)에서 discard RFID 감지 | RFID 자동 | discard 이벤트 |
| 4 | 딜러가 새 카드를 플레이어에게 배분 | 딜러 물리 액션 | 없음 |
| 5 | seat antenna에서 new dealt RFID 감지 | RFID 자동 | new_dealt 이벤트 |
| 6 | discard 수 == new dealt 수 검증 | 게임 엔진 자동 | 검증 |
| 7 | 해당 플레이어 `draw_completed` 비트 set | 게임 엔진 자동 | 없음 |

**STAND PAT 처리**:
- CC "STAND PAT" 버튼 클릭 → 교환 장수 = 0
- RFID 이벤트 없음 (discard/new dealt 모두 발생하지 않음)
- 즉시 해당 플레이어 `draw_completed` 비트 set
- 다음 플레이어로 이동

### RFID 순서 강제

| 규칙 | 설명 |
|------|------|
| **discard 우선** | discard RFID 이벤트가 먼저 처리된 후에만 new dealt 처리 |
| **리오더링** | new dealt가 discard보다 먼저 도착 → 버퍼에 보관, discard 처리 후 순차 처리 |
| **WRONG_SEQUENCE** | discard 없이 new dealt만 감지 (STAND PAT 선언 없는 상태) → 에러 |
| **타임아웃** | discard RFID 30초 미감지 → 수동 입력 모드 전환 |

**시퀀스 다이어그램**:

```
CC ────── "DRAW 2" ──────────────────►
                                      │
Player ── [discard 2장] ──►           │
                                      │
RFID ──── burn zone: card_A ──────►   │
RFID ──── burn zone: card_B ──────►   │
                                      │
Dealer ── [new 2장 배분] ──►          │
                                      │
RFID ──── seat: card_C ──────────►    │
RFID ──── seat: card_D ──────────►    │
                                      │
Engine ── discard 2 == new 2 OK ──►   │
Engine ── draw_completed[P] = true    │
```

### Coalescence 확장 윈도우

| 상태 | coalescence 윈도우 | 근거 |
|------|:--:|------|
| Hold'em (모든 상태) | 100ms | 단일 카드 감지 기준 |
| **DRAW_ROUND** | **200ms** | 물리적 카드 교환에 100ms 이상 소요 |

DRAW_ROUND에서는 다수의 discard + new dealt RFID 이벤트가 짧은 시간에 연속 발생한다. coalescence 윈도우를 200ms로 확장하여 이벤트 분리를 보장한다.

### Triple Draw 특수 규칙

`draw_count` = 3인 게임: 14, 15, 16, 17, 18

| 라운드 | 상태 흐름 |
|:--:|------|
| 1 | PRE_DRAW_BET → DRAW_ROUND[1] → POST_DRAW_BET[1] |
| 2 | POST_DRAW_BET[1] → DRAW_ROUND[2] → POST_DRAW_BET[2] |
| 3 | POST_DRAW_BET[2] → DRAW_ROUND[3] → POST_DRAW_BET[3] |

총 베팅 라운드: PRE_DRAW_BET + POST_DRAW_BET x 3 = **4회**.

---

## 블라인드/앤티

| 항목 | 값 |
|------|-----|
| **강제 베팅** | blind (SB + BB) |
| **bring-in** | 없음 (Draw 게임 전체) |
| **앤티** | 게임 설정에 따라 존재 여부 결정 |

> 참고: Hold'em 블라인드와 동일 규칙 적용 (BS-06-03).

---

## 사이드 팟

Hold'em과 동일 규칙 공유 (BS-06-06).

All-in 플레이어 발생 시:
- DRAW_ROUND: all-in 플레이어는 교환 불가 (현재 홀카드 유지)
- POST_DRAW_BET: all-in 플레이어 액션 스킵
- SHOWDOWN: all-in 플레이어 포함하여 평가

---

## 유저 스토리

### US-D01: Single Draw 2장 교환

**게임**: draw5 (game 12), deuce7_draw (game 13)

1. PRE_DRAW_BET 완료 → DRAW_ROUND[1] 진입
2. CC "DRAW 2" 버튼 → 플레이어 A가 2장 교환 선언
3. 플레이어 A가 카드 2장을 테이블에 놓음
4. burn zone antenna: discard 2장 RFID 감지 (card_7S, card_QH)
5. 딜러가 새 카드 2장 배분
6. seat antenna: new dealt 2장 RFID 감지 (card_3D, card_9C)
7. 엔진 검증: discard 2 == new dealt 2 → OK
8. `draw_completed[A]` = true → 다음 플레이어로 이동
9. 모든 플레이어 교환 완료 → POST_DRAW_BET[1]

---

### US-D02: Triple Draw 3라운드 진행

**게임**: deuce7_triple (game 14)

1. PRE_DRAW_BET 완료 → DRAW_ROUND[1]
2. 모든 플레이어 1차 교환 완료 → POST_DRAW_BET[1]
3. 베팅 완료 → DRAW_ROUND[2]
4. 모든 플레이어 2차 교환 완료 → POST_DRAW_BET[2]
5. 베팅 완료 → DRAW_ROUND[3]
6. 모든 플레이어 3차 교환 완료 → POST_DRAW_BET[3]
7. 베팅 완료, active 플레이어 >= 2 → SHOWDOWN
8. `evaluator` = lowball_27 → 가장 낮은 핸드 승리

---

### US-D03: Stand Pat 선언

**게임**: 모든 Draw 게임

1. DRAW_ROUND[N] 진입, `action_on` = 플레이어 B
2. CC "STAND PAT" 버튼 → 교환 장수 = 0
3. RFID 이벤트 없음 (discard/new dealt 모두 발생하지 않음)
4. 즉시 `draw_completed[B]` = true
5. 다음 플레이어로 이동

---

### US-D04: Badugi 4장 중 3장 교환

**게임**: badugi (game 16)

1. SETUP_HAND: 각 플레이어 4장 딜 (RFID 4장 감지)
2. PRE_DRAW_BET 완료 → DRAW_ROUND[1]
3. CC "DRAW 3" 버튼 → 플레이어 C가 3장 교환 선언
4. burn zone: discard 3장 감지
5. seat: new dealt 3장 감지
6. 엔진 검증: 3 == 3 → OK
7. 플레이어 C 홀카드: 기존 1장 + 새 3장 = 4장 유지
8. `draw_completed[C]` = true

---

### US-D05: 6인 x 2장 교환 = 12 RFID 이벤트 burst(여러 카드가 동시에 감지되는 현상)

**게임**: draw5 (game 12), 6인 테이블

1. DRAW_ROUND[1] 진입, 6명 모두 active
2. 각 플레이어 평균 2장 교환 → discard 12장 + new dealt 12장 = **24 RFID 이벤트**
3. coalescence 윈도우 200ms 적용으로 이벤트 분리 보장
4. 순차 처리: 플레이어 0 완료 → 플레이어 1 → ... → 플레이어 5
5. 모든 `draw_completed` 비트 set → POST_DRAW_BET[1]

---

### US-D06: DRAW_ROUND 중 UNDO

**게임**: 모든 Draw 게임

1. DRAW_ROUND[N] 진행 중, 플레이어 D의 교환 처리 중
2. CC "UNDO" 버튼 → 직전 액션 롤백
3. discard + new dealt 쌍 롤백:
   - new dealt 카드 → 덱으로 복귀
   - discard 카드 → 플레이어에게 복원
4. `draw_completed[D]` = false로 리셋
5. 해당 플레이어 교환 재시작

---

### US-D07: discard RFID 미감지 타임아웃

**게임**: 모든 Draw 게임

1. CC "DRAW 2" 버튼 → 플레이어 E가 2장 교환 선언
2. 플레이어가 카드를 burn zone에 놓았으나 RFID 감지 실패
3. **30초 타임아웃** → 수동 입력 모드 전환
4. 운영자가 CC에서 discard 카드를 수동 입력
5. 수동 입력 완료 → new dealt 감지 대기
6. 이후 정상 흐름 재개

---

### US-D08: POST_DRAW_BET 후 All Fold

**게임**: 모든 Draw 게임

1. POST_DRAW_BET[N] 진행 중
2. 베팅 라운드에서 1명 제외 모두 FOLD
3. active 플레이어 == 1 → **SHOWDOWN 스킵**
4. 즉시 HAND_COMPLETE 전이
5. 남은 1명이 팟 전체 수령
6. 통계 기록: "won without showdown"

---

## 예외 처리

| 예외 상황 | 감지 방법 | 처리 |
|----------|---------|------|
| **RFID 감지 실패** (DRAW_ROUND) | 30초 타임아웃 | 수동 입력 모드 전환 |
| **WRONG_SEQUENCE** (discard 없이 new dealt 감지) | RFID 이벤트 순서 검증 | 에러 알림, new dealt 버퍼에 보관, discard 대기 |
| **discard/new 수량 불일치** | 엔진 검증 (단계 6) | 에러 알림, 운영자 수동 보정 |
| **덱 소진** | 카드 수 추적 (6인 x 5장 교환 = 30장, 52장 덱 부족 가능) | discard를 reshuffling하여 재사용 |
| **All-in 중 DRAW_ROUND** | 플레이어 상태 = allin | 해당 플레이어 교환 스킵, 현재 홀카드 유지 |
| **DRAW_ROUND 중 테이블 연결 끊김** | 네트워크 모니터링 | 현재 상태 보존, 재연결 시 중단 지점부터 재개 |

### 덱 소진 상세

Triple Draw 게임에서 6인 테이블의 경우:
- 초기 딜: 6 x 5 = 30장 사용
- 1회 교환: 최대 30장 추가 필요 → 52장 덱 초과
- **해결**: 이전 라운드에서 discard된 카드를 reshuffle하여 재사용
- reshuffle 시점: DRAW_ROUND[N] 시작 전, 남은 덱 카드 < active 플레이어 x `hole_cards`

---

## 구현 체크리스트

| 항목 | 검증 기준 |
|------|---------|
| DRAW_ROUND 상태 진입/퇴출 | `draw_count`에 따라 1회 또는 3회 반복 |
| STAND PAT 처리 | RFID 이벤트 없이 즉시 `draw_completed` set |
| RFID 순서 강제 | discard → new dealt 순서 보장, 리오더링 동작 |
| WRONG_SEQUENCE 에러 | discard 없이 new dealt 감지 시 에러 발생 |
| coalescence 윈도우 200ms | DRAW_ROUND에서만 확장 적용 |
| 덱 소진 reshuffle | discard 카드를 재사용하여 딜 |
| All-in 플레이어 교환 스킵 | allin 상태 플레이어는 DRAW_ROUND에서 패스 |
| UNDO 롤백 | discard + new dealt 쌍 단위 롤백 |
| 수동 입력 모드 | RFID 타임아웃 시 전환 |
| All Fold → SHOWDOWN 스킵 | active == 1이면 즉시 HAND_COMPLETE |
