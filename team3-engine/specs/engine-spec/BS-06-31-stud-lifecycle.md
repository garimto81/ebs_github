# BS-06-31: Seven Card Stud — 라이프사이클 및 Street 시스템

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-06 | 신규 작성 | Stud 3종 FSM, Street 시스템, bring-in, RFID 카드 감지 정의 |
| 2026-04-09 | Phase 표시 | **Phase 3 범위** — Hold'em Core 구현 완료 후 착수 |

---

> **이 문서에서 사용하는 용어**
>
> | 용어 | 설명 |
> |------|------|
> | FSM | 게임 진행 단계를 정의한 상태 흐름도 (Finite State Machine) |
> | RFID | 무선 주파수로 카드를 자동 인식하는 기술 |
> | CC | Command Center, 운영자가 게임을 제어하는 화면 |
> | coalescence | 여러 센서 신호가 동시에 들어올 때 하나로 합치는 처리 규칙 |
> | NL/PL/FL | No Limit / Pot Limit / Fixed Limit 베팅 구조 |
> | Street | 각 베팅 라운드 (카드가 추가로 나눠지는 각 단계) |
> | down card | 뒤집어 놓은 비공개 카드 |
> | up card | 앞면이 보이는 공개 카드 |
> | door card | 처음 받는 공개 카드 1장 |
> | bring-in | 약한 패를 가진 사람이 의무적으로 내는 최소 베팅 |
> | ante | 모든 참가자가 게임 시작 전에 내는 참가비 |
> | visible hand | 공개된 카드만으로 보이는 패 |
> | 커뮤니티 카드 | 모든 플레이어가 공유하는 테이블 중앙의 공용 카드 |

## 개요

Seven Card Stud 게임은 보드 카드 없이, 각 플레이어에게 공개/비공개 카드를 7장까지 배분한다. Hold'em의 팟/쇼다운 규칙은 공유하지만, FSM, 강제 베팅, 카드 배분이 근본적으로 다르다.

**Hold'em과의 핵심 차이**:
- **보드 카드 없음** — 모든 카드가 플레이어 개인 소유
- **5 베팅 라운드** — Hold'em 4회 대비 1회 추가 (3RD~7TH Street)
- **Blind 없음** — ante + bring-in 시스템으로 대체
- **공개/비공개 혼합** — 2장 down + 5장 up (7TH만 down)
- **액팅 순서 변동** — 매 Street마다 visible hand 기준으로 재결정

---

## 대상 게임

| `game_id` | 이름 | `evaluator` | 핵심 |
|:--:|------|------|------|
| 19 | stud7 | standard_high | 표준 하이 평가 |
| 20 | stud7_hilo8 | hilo_8or_better | Hi/Lo split pot |
| 21 | razz | lowball_a5 | 로우볼 전용 |

> 참고: game 19의 평가는 Hold'em과 동일한 standard_high를 사용한다. game 20, 21의 고유 평가 규칙은 BS-06-32 문서에서 다룬다.

---

## FSM 정의

### 상태 다이어그램

```
IDLE
  │
  ▼
SETUP_HAND ─── ante 수집 + 3장 딜 (2 down + 1 up)
  │
  ▼
3RD_STREET ─── bring-in 결정 + 1st 베팅 라운드
  │
  ▼
4TH_STREET ─── +1 up 카드, 2nd 베팅 라운드
  │
  ▼
5TH_STREET ─── +1 up 카드, 3rd 베팅 (big bet 시작)
  │
  ▼
6TH_STREET ─── +1 up 카드, 4th 베팅
  │
  ▼
7TH_STREET ─── +1 down 카드, final 베팅
  │
  ▼
SHOWDOWN ───── 핸드 평가 + 팟 분배
  │
  ▼
HAND_COMPLETE
```

### 상태별 정의

#### IDLE

| 속성 | 값 |
|------|-----|
| **Entry 조건** | 앱 시작 OR 이전 핸드 HAND_COMPLETE |
| **Exit 조건** | SendStartHand() 호출 |
| **`hand_in_progress`** | false |
| **`action_on`** | -1 |
| **트리거** | CC 버튼 "NEW HAND" (운영자 수동) |
| **UI 상태** | 대기 화면, "NEW HAND" 버튼 활성 |

> 참고: Hold'em IDLE과 동일하다.

#### SETUP_HAND

| 속성 | 값 |
|------|-----|
| **Entry 조건** | SendStartHand() 성공 |
| **Exit 조건** | 모든 플레이어 3장 RFID 감지 완료 |
| **`hand_in_progress`** | true |
| **`action_on`** | -1 (아직 베팅 시작 전) |
| **트리거** | 게임 엔진 자동 |

**동작 순서**:
1. 전원 ante 수집 — 모든 활성 플레이어에서 `ante` 금액 차감
2. 카드 배분 — 플레이어당 3장: **2장 down** (비공개) + **1장 up** (공개, "door card")
3. RFID burst 감지 — 6인 기준 18장 (3장 x 6인)

**상태 변수**:

| 변수 | 값 |
|------|-----|
| **`ante_type`** | std_ante (0) — 전원 균등 수집 |
| **`bring_in`** | 설정값 (ante보다 크고 small bet보다 작음) |
| **카드 배분** | down 2장 + up 1장 per player |

#### 3RD_STREET

| 속성 | 값 |
|------|-----|
| **Entry 조건** | SETUP_HAND 카드 배분 완료 |
| **Exit 조건** | 베팅 라운드 완료 OR 1인 제외 전원 폴드 |
| **`hand_in_progress`** | true |
| **`action_on`** | bring-in 플레이어 좌석 번호 |
| **트리거** | 게임 엔진 자동 (RFID 감지 완료) |
| **UI 상태** | bring-in 플레이어 강조, 베팅 버튼 활성 |

**bring-in 결정**:
- game 19, 20: 가장 **낮은** up card 보유자
- game 21 (Razz): 가장 **높은** up card 보유자 (역순)
- 동점 시: suit 순서로 결정 — clubs < diamonds < hearts < spades

**베팅 구조**:
- bring-in 플레이어: bring-in 금액 포스팅 또는 "complete"(bring-in 대신 정규 베팅 금액을 내는 행위, full small bet) 선택
- 이후 나머지 플레이어 시계 방향 순차 액션
- 베팅 크기: `low_limit` (small bet)

#### 4TH_STREET

| 속성 | 값 |
|------|-----|
| **Entry 조건** | 3RD_STREET 베팅 완료 |
| **Exit 조건** | 베팅 라운드 완료 OR 1인 제외 전원 폴드 |
| **`hand_in_progress`** | true |
| **`action_on`** | 최고 visible hand 보유자 |
| **트리거** | 게임 엔진 자동 |

**동작**:
1. 각 활성 플레이어에게 +1 up card 배분
2. first to act = 공개 카드 기준 **최고 visible hand** 보유자
3. 베팅 크기: `low_limit` (small bet)

**pair visible 예외 (FL 전용)**:
- 4TH_STREET에서 어떤 플레이어의 공개 카드에 **pair가 보이면**, 해당 라운드에서 big bet (`high_limit`) 선택 가능
- pair visible이 없으면 small bet만 허용

#### 5TH_STREET

| 속성 | 값 |
|------|-----|
| **Entry 조건** | 4TH_STREET 베팅 완료 |
| **Exit 조건** | 베팅 라운드 완료 OR 1인 제외 전원 폴드 |
| **`hand_in_progress`** | true |
| **`action_on`** | 최고 visible hand 보유자 |
| **트리거** | 게임 엔진 자동 |

**동작**:
1. 각 활성 플레이어에게 +1 up card 배분
2. first to act = 최고 visible hand
3. **big bet 시작** — `high_limit` 적용 (FL 기준)

#### 6TH_STREET

| 속성 | 값 |
|------|-----|
| **Entry 조건** | 5TH_STREET 베팅 완료 |
| **Exit 조건** | 베팅 라운드 완료 OR 1인 제외 전원 폴드 |
| **`hand_in_progress`** | true |
| **`action_on`** | 최고 visible hand 보유자 |
| **트리거** | 게임 엔진 자동 |

**동작**: 5TH_STREET와 동일 — +1 up card, big bet, 최고 visible hand부터 액션

#### 7TH_STREET

| 속성 | 값 |
|------|-----|
| **Entry 조건** | 6TH_STREET 베팅 완료 |
| **Exit 조건** | 베팅 라운드 완료 OR 1인 제외 전원 폴드 |
| **`hand_in_progress`** | true |
| **`action_on`** | 최고 visible hand 보유자 |
| **트리거** | 게임 엔진 자동 |

**동작**:
1. 각 활성 플레이어에게 +1 **down** card (비공개) 배분
2. first to act = 최고 visible hand (6TH까지의 공개 카드 기준)
3. 베팅 크기: `high_limit` (big bet)
4. 마지막 베팅 라운드

**덱 부족 예외**: 남은 카드가 활성 플레이어 수보다 적으면, 남은 카드 1장을 **커뮤니티 카드**로 테이블 중앙에 공개한다. 이 카드는 모든 활성 플레이어가 공유한다.

#### SHOWDOWN

| 속성 | 값 |
|------|-----|
| **Entry 조건** | 7TH_STREET 베팅 완료 + 2인 이상 |
| **Exit 조건** | 우승자 결정 |
| **`hand_in_progress`** | true |
| **트리거** | 게임 엔진 자동 |

**동작**:
- 각 플레이어의 7장 (3 down + 4 up) 중 best 5-card hand 자동 평가
- C(7,5) = 21 조합 중 최고 선택
- game 19: standard_high
- game 20: hilo_8or_better (Hi/Lo split)
- game 21: lowball_a5 (최저 핸드 승리)

> 참고: Hold'em SHOWDOWN과 동일한 팟 분배 로직 적용.

#### HAND_COMPLETE

| 속성 | 값 |
|------|-----|
| **Entry 조건** | SHOWDOWN 완료 OR 1인 제외 전원 폴드 |
| **Exit 조건** | IDLE로 복귀 |
| **`hand_in_progress`** | false |
| **트리거** | 게임 엔진 자동 |

**동작**: 팟 분배, 통계 기록, UI 결과 표시. Hold'em과 동일.

### 상태 전이 매트릭스

| 현재 상태 | 트리거 | 다음 상태 |
|---------|--------|---------|
| **IDLE** | SendStartHand() | SETUP_HAND |
| **SETUP_HAND** | 3장 RFID 완료 | 3RD_STREET |
| **3RD_STREET** | 베팅 완료 | 4TH_STREET |
| **3RD_STREET** | 전원 폴드 (1인 잔류) | HAND_COMPLETE |
| **4TH_STREET** | 베팅 완료 | 5TH_STREET |
| **4TH_STREET** | 전원 폴드 | HAND_COMPLETE |
| **5TH_STREET** | 베팅 완료 | 6TH_STREET |
| **5TH_STREET** | 전원 폴드 | HAND_COMPLETE |
| **6TH_STREET** | 베팅 완료 | 7TH_STREET |
| **6TH_STREET** | 전원 폴드 | HAND_COMPLETE |
| **7TH_STREET** | 베팅 완료 + 2인+ | SHOWDOWN |
| **7TH_STREET** | 전원 폴드 | HAND_COMPLETE |
| **SHOWDOWN** | 우승자 결정 | HAND_COMPLETE |
| **HAND_COMPLETE** | cycle 완료 | IDLE |

---

## Bring-in 상세

### Bring-in 결정 규칙

| `game_id` | 기준 | 결정 방식 |
|:--:|------|------|
| 19 | 최저 up card | 가장 낮은 door card 보유자 |
| 20 | 최저 up card | 가장 낮은 door card 보유자 |
| 21 | 최고 up card | 가장 높은 door card 보유자 (역순) |

**Razz 역순 이유**: Razz는 로우볼 게임이므로 높은 카드 = 불리한 손. 약한 손이 먼저 강제 베팅하는 원칙에 따라 최고 door card가 bring-in을 담당한다.

### Bring-in 경우의 수 매트릭스

| 상황 | 동작 |
|------|------|
| **단독 최저/최고 door** | 해당 플레이어가 bring-in |
| **동점 door card (2인+)** | suit 순서로 결정: clubs(최저) < diamonds < hearts < spades(최고) |
| **game 19, 20 동점** | 가장 낮은 suit 보유자가 bring-in |
| **game 21 동점** | 가장 높은 suit 보유자가 bring-in |
| **bring-in 포스팅** | bring-in 금액만 포스팅 |
| **bring-in complete** | bring-in 대신 full small bet (`low_limit`) 포스팅 선택 |
| **bring-in 후 raise** | 다른 플레이어가 small bet 또는 그 이상으로 raise 가능 |
| **bring-in 미포스팅** | 타임아웃 → 자동 bring-in 또는 fold 처리 |
| **모든 플레이어 콜/체크** | 베팅 라운드 완료 → 4TH_STREET |

### Suit 순서

| 순위 | Suit | 기호 |
|:--:|------|:--:|
| 1 (최저) | Clubs | ♣ |
| 2 | Diamonds | ♦ |
| 3 | Hearts | ♥ |
| 4 (최고) | Spades | ♠ |

> 참고: suit 순서는 bring-in 결정에만 사용된다. 핸드 평가 (SHOWDOWN)에서는 suit 순서를 사용하지 않는다.

---

## RFID 카드 감지

### Street별 RFID

| Street | 카드 종류 | 안테나 | 이벤트 수 (6인) |
|--------|---------|--------|:--:|
| **SETUP (3RD)** | 2 down + 1 up | seat antenna | 18 |
| **4TH** | 1 up | 공개 영역 | 6 |
| **5TH** | 1 up | 공개 영역 | 6 |
| **6TH** | 1 up | 공개 영역 | 6 |
| **7TH** | 1 down | seat antenna | 6 |

**총 RFID 이벤트**: 6인 기준 42장 (18 + 6 + 6 + 6 + 6). 폴드 플레이어의 카드도 감지되지만 게임 로직에서 무시한다.

### Down/Up 카드 구분

| 카드 종류 | 안테나 위치 | 공개 여부 | RFID 필수 |
|---------|---------|:--:|:--:|
| **Down card** | seat antenna (좌석 개별) | 비공개 | 필수 |
| **Up card** | 공개 영역 antenna | 공개 | 선택 |

**처리 우선순위**: Down card > Up card. 비공개 카드는 반드시 RFID로 감지해야 한다. 공개 카드는 시각적으로 확인 가능하므로 RFID 감지는 보조 수단이다.

### Coalescence 변경

| 상황 | 처리 |
|------|------|
| **3RD_STREET burst** | 18장 RFID 동시 처리 — 표준 100ms 윈도우 확장 |
| **bring-in 판정 대기** | 모든 up card (6장) RFID 감지 완료까지 대기 후 bring-in 결정 |
| **4TH~6TH** | 1장/인, 표준 100ms 윈도우 |
| **7TH** | 1장/인, down card이므로 seat antenna로 감지 |

---

## 블라인드/앤티

| 항목 | Hold'em | Stud |
|------|---------|------|
| **강제 베팅** | SB + BB (blind) | ante + bring-in |
| **수집 대상** | SB, BB 좌석만 | 전원 ante |
| **수집 시점** | SETUP_HAND | SETUP_HAND (ante), 3RD_STREET (bring-in) |
| **`ante_type`** | 0-6 (다양) | std_ante (0)만 지원 |
| **`bring_in`** | 0 (사용 안 함) | 설정값 (ante < bring-in < small bet) |

**Stud ante 규칙**:
- 모든 활성 플레이어에게 동일한 `ante` 금액 수거
- SETUP_HAND 진입 즉시 자동 차감
- ante 수거 후 3장 배분 시작

---

## 베팅 구조

### Street별 베팅 크기 (FL 기준)

| Street | 베팅 크기 | 필드 | 예외 |
|--------|---------|------|------|
| **3RD** | small bet | `low_limit` | bring-in은 별도 금액 |
| **4TH** | small bet | `low_limit` | pair visible 시 big bet 선택 가능 |
| **5TH** | big bet | `high_limit` | 없음 |
| **6TH** | big bet | `high_limit` | 없음 |
| **7TH** | big bet | `high_limit` | 없음 |

### 베팅 구조별 지원

| `bet_structure` | 지원 | 비고 |
|:--:|:--:|------|
| 0 (NL) | 가능 | NL Stud — 드문 형태 |
| 1 (FL) | **기본** | 대부분의 Stud 게임 |
| 2 (PL) | 가능 | PL Stud — 드문 형태 |

### First to Act 규칙

| Street | First to Act | 기준 |
|--------|------------|------|
| **3RD** | bring-in 플레이어 | 최저/최고 door card |
| **4TH~7TH** | 최고 visible hand | 공개 카드 기준 best rank |

**visible hand 평가 기준**:
- 공개된 up card만으로 판단
- pair > 높은 카드 > 낮은 카드
- 동점 시 딜러 왼쪽(시계 방향) 가장 가까운 플레이어

---

## 유저 스토리

**US-31-01: 3RD_STREET 카드 배분**
- 운영자가 "NEW HAND" 버튼 클릭 → 게임 엔진 자동: 전원 ante 수집 → 6인 x 3장 = 18장 RFID burst 시작 → 각 좌석에서 down 2장 + up 1장 감지 → bring-in 플레이어 자동 결정 → 3RD_STREET 베팅 시작

**US-31-02: Bring-in 포스팅**
- 게임 엔진이 최저 up card 보유자 결정 → 해당 플레이어에 bring-in 포스팅 → UI에서 bring-in 금액 자동 차감 표시 → bring-in 플레이어는 "complete" (full small bet) 선택 가능

**US-31-03: Bring-in 동점 처리**
- 2인 이상이 동일한 lowest door card 보유 → suit 순서 적용 (clubs 최저) → 해당 suit 보유자가 bring-in 담당

**US-31-04: Razz bring-in 역순**
- game 21 (Razz) 선택 → bring-in 결정이 **최고** up card 기준으로 전환 → 가장 높은 door card 보유자가 bring-in → UI에서 "Razz: High card brings in" 표시

**US-31-05: 4TH_STREET pair visible**
- 4TH_STREET 진입 → 각 플레이어에게 +1 up card → 어떤 플레이어의 2장 up card에 pair 발견 → 해당 라운드 big bet (`high_limit`) 선택 활성화 → pair 없으면 small bet만 허용

**US-31-06: 7TH_STREET 덱 부족**
- 7TH_STREET 진입 → 남은 덱 카드 < 활성 플레이어 수 → 게임 엔진 자동: 남은 카드 1장을 커뮤니티 카드로 테이블 중앙 공개 → 모든 활성 플레이어가 공유하여 7번째 카드로 사용 → `stud_community_card` = true

**US-31-07: 폴드 플레이어 카드 처리**
- 3RD~6TH 중 플레이어 폴드 → 해당 플레이어의 다음 Street 카드 RFID 감지 시 → 게임 로직에서 무시 (폐기 처리) → 통계에는 "folded at Nth Street" 기록

**US-31-08: All Fold on 3RD**
- 3RD_STREET에서 bring-in 포스팅 후 모든 다른 플레이어 폴드 → 1인 잔류 → 4TH~7TH 전체 스킵 → 즉시 HAND_COMPLETE → 잔류 플레이어가 팟 수령

---

## 예외 처리

| 예외 | 트리거 | 처리 |
|------|--------|------|
| **3RD RFID burst 실패** | 18장 중 일부 미감지 (timeout 5초) | CC에 수동 입력 모드 전환 알림 |
| **덱 부족 (7TH)** | 잔여 카드 < 활성 플레이어 수 | 커뮤니티 카드 1장 공개 |
| **bring-in 미포스팅** | 타임아웃 30초 | 자동 bring-in 강제 차감 |
| **bring-in 타임아웃 + 잔액 부족** | bring-in 금액 > 플레이어 스택 | all-in 처리 |
| **all-in 발생** | 베팅 라운드 중 스택 소진 | 이후 Street 자동 진행, 추가 베팅 불참 |
| **미스딜**(카드를 잘못 나눈 것으로, 핸드를 처음부터 다시 시작) | RFID down card != 2장 감지 | 게임 엔진 자동 경고 + CC에 재딜 옵션 표시 |
| **up card RFID 불일치** | 공개 카드 시각 확인과 RFID 불일치 | CC에 수동 보정 옵션 표시 |

---

## 구현 체크리스트

| 항목 | 설명 | 우선순위 |
|------|------|:--:|
| FSM 8상태 구현 | IDLE~HAND_COMPLETE | P0 |
| bring-in 결정 로직 | game별 최저/최고 door + suit 순서 | P0 |
| Street별 카드 배분 | 3RD(3장), 4TH~6TH(+1 up), 7TH(+1 down) | P0 |
| first to act 결정 | 3RD=bring-in, 4TH~7TH=visible hand | P0 |
| 4TH pair visible 예외 | FL에서 big bet 선택 활성화 | P1 |
| 덱 부족 커뮤니티 카드 | 7TH에서 잔여 카드 부족 시 | P1 |
| RFID burst 처리 | 3RD 18장 동시 감지 윈도우 | P1 |
| ante + bring-in 수집 | blind 비활성, ante/bring-in 활성 | P0 |
| Razz bring-in 역순 | game 21 전용 로직 분기 | P0 |
