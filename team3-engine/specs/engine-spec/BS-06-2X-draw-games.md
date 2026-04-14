# BS-06-2X: Draw Games — 라이프사이클 + 카드 교환 + 핸드 평가

> **존재 이유**: Draw 7종(game 12–18) 통합 사양. `coalescence.dart:CoalescenceWindow.draw()`가 §1 라이프사이클을 인용. §2 평가기 라우팅이 Phase 3 구현 타겟.
>
> **Status**: Phase 3 (deferred) — Hold'em Core 구현 완료 후 착수.
>
> **통합 이력**: 2026-04-14 — BS-06-21(라이프사이클) + BS-06-22(평가) 통합. 같은 게임군의 두 측면이므로 단일 문서가 자연스러움.

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-06 | 신규 작성 | Draw 7종 FSM, DRAW_ROUND 메카닉, 평가기 라우팅 (BS-06-21, 22 분리) |
| 2026-04-09 | Phase 표시 | **Phase 3** 명시 |
| 2026-04-14 | **통합** | BS-06-21 + BS-06-22 → BS-06-2X 단일 문서 |

---

## 공통 용어

| 용어 | 설명 |
|------|------|
| FSM | 게임 진행 단계를 정의한 상태 흐름도 |
| RFID | 무선 주파수로 카드를 자동 인식하는 기술 |
| CC | Command Center, 운영자가 게임을 제어하는 화면 |
| evaluator | 카드 조합을 분석하여 승자를 결정하는 함수 |
| coalescence | 여러 센서 신호가 동시에 들어올 때 하나로 합치는 처리 규칙 |
| antenna | RFID 카드를 감지하는 센서 |
| 비트마스크 | 각 플레이어 완료 여부를 0/1로 추적 |
| 홀카드(hole card) | 각 플레이어에게 비공개로 나눠주는 카드 |
| draw | 카드를 교환하는 행위 |
| stand pat | 카드를 하나도 교환하지 않는 것 |
| reshuffling | 덱 카드가 부족할 때 버린 카드를 다시 섞어 사용하는 것 |
| All-in | 보유 금액 전부를 건 상태 |
| SB/BB | Small Blind / Big Blind |
| UTG | Under The Gun, 블라인드 다음 좌석 |
| scoop | 한 사람이 팟 전체를 가져가는 것 |
| odd chip | 팟을 나눌 때 딱 떨어지지 않는 1개 베팅 토큰 |
| C(n,k) | n장에서 k장을 고르는 조합의 수 |

## Hold'em과의 핵심 차이

- 보드 카드 없음 — 플레이어 홀카드만으로 핸드 구성
- FLOP/TURN/RIVER 없음 — DRAW_ROUND + POST_DRAW_BET 반복
- RFID 추적 대상이 홀카드만 (보드 안테나 미사용)
- 카드 교환 시 discard/new dealt 순서 강제

## 대상 게임

| `game_id` | 이름 | `draw_count` | `hole_cards` | 베팅 라운드 | `evaluator` |
|:--:|------|:--:|:--:|:--:|------|
| 12 | draw5 | 1 | 5 | 2 | standard_high |
| 13 | deuce7_draw | 1 | 5 | 2 | lowball_27 |
| 14 | deuce7_triple | 3 | 5 | 4 | lowball_27 |
| 15 | a5_triple | 3 | 5 | 4 | lowball_a5 |
| 16 | badugi | 3 | **4** | 4 | badugi |
| 17 | badeucy | 3 | 5 | 4 | hilo_badugi_27 |
| 18 | badacey | 3 | 5 | 4 | hilo_badugi_a5 |

---

# §1. 라이프사이클 (구 BS-06-21)

## FSM 상태 다이어그램

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

## 상태별 정의

### SETUP_HAND

| 항목 | 값 |
|------|-----|
| Entry | SendStartHand() 성공 |
| Exit | 모든 active 플레이어 홀카드 RFID 감지 완료 |
| 딜 카드 수 | game 12,13,14,15,17,18 = 5장 / game 16 = 4장 |
| 트리거 | 게임 엔진 자동 (블라인드 → 딜) |

### PRE_DRAW_BET

| 항목 | 값 |
|------|-----|
| Entry | 홀카드 딜 완료 |
| Exit | 모든 active 액션 완료, 베팅액 균등 |
| `action_on` | UTG (BB 다음) |
| 베팅 규칙 | Hold'em PRE_FLOP과 동일 |

### DRAW_ROUND[N] — 핵심 상태

| 항목 | 값 |
|------|-----|
| Entry | PRE_DRAW_BET 완료 (N=1) 또는 POST_DRAW_BET[N-1] 완료 |
| Exit | 모든 active `draw_completed` 비트 set |
| N 범위 | 1 ~ `draw_count` (1 또는 3) |
| `action_on` | SB부터 시계 방향 |
| 트리거 | CC "DRAW N" 또는 "STAND PAT" 버튼 |

### POST_DRAW_BET[N]

| 항목 | 값 |
|------|-----|
| Entry | DRAW_ROUND[N] 완료 |
| Exit | 베팅 완료 |
| 다음 상태 | N < `draw_count` → DRAW_ROUND[N+1], 아니면 SHOWDOWN |

### SHOWDOWN, HAND_COMPLETE

Hold'em과 동일. SHOWDOWN의 `evaluator`는 §2 라우팅 참조.

## 상태 전이 매트릭스

| 현재 | 트리거 | 다음 |
|------|--------|------|
| IDLE | CC "NEW HAND" | SETUP_HAND |
| SETUP_HAND | RFID 홀카드 완전 감지 | PRE_DRAW_BET |
| PRE_DRAW_BET | 베팅 완료 | DRAW_ROUND[1] |
| PRE_DRAW_BET | All Fold | HAND_COMPLETE |
| DRAW_ROUND[N] | 모든 교환 완료 | POST_DRAW_BET[N] |
| POST_DRAW_BET[N] | 베팅 완료, N < draw_count | DRAW_ROUND[N+1] |
| POST_DRAW_BET[N] | 베팅 완료, N == draw_count | SHOWDOWN |
| POST_DRAW_BET[N] | All Fold | HAND_COMPLETE |
| SHOWDOWN | 우승자 결정 | HAND_COMPLETE |
| HAND_COMPLETE | 초기화 | IDLE |

---

## DRAW_ROUND 상세 메카닉

### 카드 교환 절차

| 단계 | 행위 | 발동 주체 | RFID |
|:--:|------|---------|------|
| 1 | CC "DRAW N" 또는 "STAND PAT" 버튼 | 운영자 수동 | 없음 |
| 2 | 플레이어가 discard 카드를 테이블에 놓음 | 플레이어 | 없음 |
| 3 | burn zone antenna에서 discard RFID 감지 | RFID 자동 | discard |
| 4 | 딜러가 새 카드 배분 | 딜러 | 없음 |
| 5 | seat antenna에서 new dealt RFID 감지 | RFID 자동 | new_dealt |
| 6 | discard 수 == new dealt 수 검증 | 게임 엔진 | 검증 |
| 7 | `draw_completed[P]` 비트 set | 게임 엔진 | 없음 |

**STAND PAT 처리**: CC 버튼 클릭 → 즉시 `draw_completed` set, RFID 이벤트 없음.

### RFID 순서 강제

| 규칙 | 설명 |
|------|------|
| discard 우선 | discard 처리 후에만 new dealt 처리 |
| 리오더링 | new dealt가 먼저 도착 → 버퍼 보관, discard 처리 후 순차 처리 |
| WRONG_SEQUENCE | discard 없이 new dealt만 감지 → 에러 |
| 타임아웃 | discard 30초 미감지 → 수동 입력 모드 |

### Coalescence 확장 윈도우

| 상태 | 윈도우 | 근거 |
|------|:--:|------|
| Hold'em (모든 상태) | 100ms | 단일 카드 감지 기준 |
| **DRAW_ROUND** | **200ms** | 물리적 카드 교환에 100ms 이상 소요 |

### Triple Draw 라운드 흐름 (`draw_count`=3)

| 라운드 | 상태 흐름 |
|:--:|------|
| 1 | PRE_DRAW_BET → DRAW_ROUND[1] → POST_DRAW_BET[1] |
| 2 | POST_DRAW_BET[1] → DRAW_ROUND[2] → POST_DRAW_BET[2] |
| 3 | POST_DRAW_BET[2] → DRAW_ROUND[3] → POST_DRAW_BET[3] |

총 베팅: PRE_DRAW_BET + POST_DRAW_BET × 3 = **4회**.

### 블라인드/앤티

- 강제 베팅: blind (SB + BB)
- bring-in 없음 (Draw 게임 전체)
- 앤티: 게임 설정에 따라

### 사이드 팟

Hold'em과 동일. All-in 플레이어:
- DRAW_ROUND: 교환 불가 (현재 홀카드 유지)
- POST_DRAW_BET: 액션 스킵
- SHOWDOWN: 평가 포함

### 예외 처리

| 예외 | 감지 | 처리 |
|------|------|------|
| RFID 감지 실패 | 30초 타임아웃 | 수동 입력 모드 |
| WRONG_SEQUENCE | 이벤트 순서 검증 | new dealt 버퍼 보관, discard 대기 |
| 수량 불일치 | 엔진 검증 | 운영자 수동 보정 |
| 덱 소진 | 카드 수 추적 | discard reshuffle 재사용 |
| All-in 중 DRAW | 플레이어 상태 | 교환 스킵 |
| 연결 끊김 | 네트워크 모니터링 | 상태 보존, 재개 |

---

# §2. 핸드 평가 (구 BS-06-22)

## 평가기 라우팅

| `game_id` | `evaluator` | 핵심 차이 |
|:--:|------|------|
| 12 | standard_high | Hold'em과 동일 (BS-06-05) |
| 13, 14 | lowball_27 | A=high, Straight/Flush 불리 |
| 15 | lowball_a5 | A=low, Straight/Flush 무시 |
| 16 | badugi | 4장, 수트×랭크 유니크 |
| 17 | hilo_badugi_27 | Badugi + 2-7 Low split |
| 18 | hilo_badugi_a5 | Badugi + A-5 Low split |

## §2.1 draw5 (game 12) — standard_high

5장이 곧 최종 핸드. BS-06-05 참조.

## §2.2 Lowball 2-7 (game 13, 14)

| 항목 | 값 |
|------|-----|
| 목표 | 가장 낮은 핸드 승리 |
| A | High (Low 사용 불가) |
| Straight | 불리 (랭킹 상승) |
| Flush | 불리 (랭킹 상승) |
| 최고 핸드 | 7-5-4-3-2 |

### 랭킹

| 순위 | 핸드 | 예시 |
|:--:|------|------|
| 1 | Number One | 7♠5♥4♦3♣2♠ |
| 2 | 7-6 Low | 7♠6♥4♦3♣2♠ |
| 3 | 8 Low | 8♠5♥4♦3♣2♠ |
| 4 | 9 Low | 9♠7♥5♦3♣2♠ |
| ... | ... | ... |
| 하위 | Pair / Two Pair / Trips | |
| 하위 | Straight (불리) | 7♠6♥5♦4♣3♠ |
| 하위 | Flush (불리) | 7♠5♠4♠3♠2♠ |
| 최하 | Full House+ | |

### 동점 규칙

1. 핸드 타입 비교 (낮을수록 유리)
2. 같은 타입이면 가장 높은 카드부터 비교 (낮을수록 유리)
3. 모든 카드 동일 → 팟 분할

## §2.3 Lowball A-5 (game 15)

| 항목 | 값 |
|------|-----|
| A | Low (1) |
| Straight | 무시 |
| Flush | 무시 |
| 최고 핸드 | A-2-3-4-5 (wheel) |

### 랭킹

| 순위 | 핸드 | 예시 |
|:--:|------|------|
| 1 | Wheel | A♠2♥3♦4♣5♠ |
| 2 | 6 Low | A♠2♥3♦4♣6♠ |
| 3 | 7 Low | A♠2♥3♦4♣7♠ |
| 4 | 8 Low | A♠2♥3♦5♣8♠ |
| ... | ... | ... |
| 하위 | Pair, Two Pair | |
| 최하 | Trips+ | |

> A♠2♠3♠4♠5♠는 Flush이지만 Wheel(최고)이다 — Flush 무시.

## §2.4 Badugi (game 16)

| 항목 | 값 |
|------|-----|
| 카드 수 | 4장 (Draw 중 유일) |
| Badugi 조건 | 4 different suits + 4 different ranks |
| A | Low |
| 우선순위 | 4-card > 3-card > 2-card > 1-card |
| 같은 카드 수 내 | 낮은 rank 유리 |

### 유효 카드 수 판정

중복 suit/rank 제거:
1. 같은 suit 2장+ → 가장 **높은** 랭크 제거
2. 같은 rank 2장+ → 하나 제거
3. 반복

**예시**:

| 핸드 | 제거 | 유효 | Badugi 수 |
|------|------|------|:--:|
| A♠2♥3♦4♣ | — | A♠2♥3♦4♣ | **4** |
| A♠2♥3♦4♦ | 4♦ | A♠2♥3♦ | **3** |
| A♠A♥3♦4♣ | A♥ | A♠3♦4♣ | **3** |
| A♠2♠3♠4♣ | 3♠, 2♠ | A♠4♣ | **2** |

### 동점 규칙

1. 카드 수 비교 (4 > 3 > 2 > 1)
2. 같은 카드 수 내 가장 높은 카드부터 비교 (낮을수록 유리)

## §2.5 Badeucy (game 17) — Badugi + 2-7 Low Split

| 항목 | 값 |
|------|-----|
| 홀카드 | 5장 |
| `draw_count` | 3 |
| Badugi half | 5장 중 4장으로 평가 (C(5,4)=5 조합 중 최고) |
| 2-7 Low half | 5장 전체로 Lowball 2-7 |
| Odd chip | Badugi half 귀속 |

### 분배 매트릭스

| Badugi 승자 | 2-7 Low 승자 | 분배 |
|:--:|:--:|------|
| A | B | A 50%, B 50% |
| A | A | A 100% (scoop) |
| 동점 (2명) | B | 동점자 각 25%, B 50% |
| A | 동점 (2명) | A 50%, 동점자 각 25% |

## §2.6 Badacey (game 18) — Badugi + A-5 Low Split

Badeucy와 동일하되 Low half가 **A-5 Lowball**:

| 항목 | Badeucy | Badacey |
|------|:--:|:--:|
| Badugi half | Badugi | Badugi |
| Low half | Lowball 2-7 | **Lowball A-5** |
| A (Low) | High | **Low** |
| Straight (Low) | 불리 | **무시** |
| Flush (Low) | 불리 | **무시** |
| 최고 Low | 7-5-4-3-2 | **A-2-3-4-5** |

분배 매트릭스는 Badeucy와 동일.

---

## 통합 구현 체크리스트

### 라이프사이클 (§1)

- [ ] DRAW_ROUND 진입/퇴출 (`draw_count` 1 또는 3)
- [ ] STAND PAT 즉시 `draw_completed` set
- [ ] RFID 순서 강제 (discard → new dealt 리오더링)
- [ ] WRONG_SEQUENCE 에러
- [ ] coalescence 200ms (DRAW_ROUND 전용)
- [ ] 덱 소진 reshuffle
- [ ] All-in 플레이어 교환 스킵
- [ ] UNDO 롤백 (discard + new dealt 쌍)
- [ ] RFID 타임아웃 → 수동 입력
- [ ] All Fold → SHOWDOWN 스킵

### 평가 (§2)

- [ ] `evaluator` 라우팅 (`game_id` 기반)
- [ ] Lowball 2-7: A=high, Straight/Flush 불리
- [ ] Lowball A-5: A=low, Straight/Flush 무시
- [ ] Badugi: 유효 카드 수 판정 (suit/rank 중복 제거)
- [ ] Badugi: 4장 > 3장 > 2장 > 1장
- [ ] Badeucy: Badugi(C(5,4)) + 2-7 split
- [ ] Badacey: Badugi(C(5,4)) + A-5 split
- [ ] Split pot 50/50, odd chip → Badugi half
- [ ] Scoop 판정 (동일인 양쪽 승리)
- [ ] 동점 시 팟 분할
