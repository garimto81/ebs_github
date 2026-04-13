# BS-06-12: Pineapple — Flop Extension

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-06 | 신규 작성 | Pineapple 차이점 정의 (DISCARD_PHASE FSM 추가, 3장 딜, RFID discard 감지) |
| 2026-04-09 | Phase 표시 | **Phase 3 범위** — Hold'em Core 구현 완료 후 착수 |

---

> **이 문서에서 사용하는 용어**
>
> | 용어 | 설명 |
> |------|------|
> | FSM | 게임 진행 단계를 정의한 상태 흐름도 (Finite State Machine) |
> | RFID | 무선 주파수로 카드를 자동 인식하는 기술. 카드에 내장된 IC를 테이블 센서가 읽는다 |
> | coalescence | 여러 센서 신호가 동시에 들어올 때 하나로 합치는 처리 규칙 |
> | CC | Command Center, 운영자가 게임을 제어하는 화면 |
> | NL/PL/FL | No Limit(무제한) / Pot Limit(팟 크기까지) / Fixed Limit(고정 금액) 베팅 구조 |
> | antenna | RFID 카드를 감지하는 센서 (seat antenna = 좌석 센서, board antenna = 공용 카드 센서, burn zone antenna = 버린 카드 감지 센서) |
> | Bomb Pot | 모든 플레이어가 동일 금액을 미리 내고 Flop부터 시작하는 특수 모드 |

## 개요

Hold'em과 동일한 프로세스를 따르되, 3장 딜 후 1장 버리는 **DISCARD_PHASE**(카드 버리기 단계)가 추가된다. `game_id` = 3. 핸드 평가, 베팅 구조, 덱 크기는 Hold'em과 동일하며, FSM에 1개 상태가 추가되고 RFID가 3장 감지 + 1장 discard를 추적하는 것이 핵심 차이다.

---

## Hold'em과의 차이점 요약

| 항목 | Hold'em | Pineapple |
|------|---------|-----------|
| `hole_cards` | 2 | 3→2 (3장 배분, 1장 버림) |
| FSM 상태 | 9개 | 10개 (**DISCARD_PHASE** 추가) |
| RFID 홀카드 감지 | 2장/인 | 3장/인 (SETUP) + 1장/인 discard |
| RFID 안테나 | 0-9 (홀 2장) | 0-9 (홀 3장) + #11 (burn zone) |
| Miss Deal 기준 | 홀카드 != 2 | 홀카드 != 3 |

---

## FSM 변경 사항 (핵심 차이)

Hold'em FSM에 **DISCARD_PHASE** 상태를 추가한다. PRE_FLOP 베팅 완료 후, FLOP 진입 전에 삽입된다.

```
IDLE → SETUP_HAND → PRE_FLOP (3장 보유)
  → DISCARD_PHASE (1장 버림)
  → FLOP → TURN → RIVER → SHOWDOWN → HAND_COMPLETE
```

### DISCARD_PHASE 상태 정의

| 속성 | 값 |
|------|-----|
| **Entry 조건** | PRE_FLOP 베팅 완료 (모든 active 플레이어 액션 종료) |
| **hand_in_progress** | true |
| **action_on** | -1 (개별 플레이어 액션 아님, 전체 대기) |
| **board_cards** | 0 (아직 보드 미공개) |
| **처리** | 각 active 플레이어가 3장 중 1장을 선택하여 폐기 |
| **Exit 조건** | 모든 active 플레이어 discard 완료 → **FLOP** 전이 대기 |
| **타임아웃** | 30초 후 CC 수동 입력 모드 전환 |

### DISCARD_PHASE Entry/Exit 매트릭스

| Entry 조건 | Exit 조건 | 다음 상태 |
|-----------|-----------|----------|
| PRE_FLOP 베팅 완료 | 모든 active 플레이어 discard 완료 | **FLOP** |
| PRE_FLOP 베팅 완료 | 타임아웃 30초 + CC 수동 입력 | **FLOP** |
| PRE_FLOP에서 all fold (1명 남음) | — | **HAND_COMPLETE** (DISCARD_PHASE 스킵) |

### RFID Discard 감지

| 속성 | 값 |
|------|-----|
| **감지 위치** | burn zone antenna #11 |
| **감지 순서** | 좌석별 비동기 (순서 강제 없음) |
| **대기 규칙** | 모든 active 플레이어 discard 완료까지 FLOP 전이 대기 |
| **폴드 플레이어** | discard 불필요, 자동 스킵 |
| **기록** | `Player {seat} discarded {card}` 파일 기록 (통계/감시용) |

### 상태별 상태변수 (Hold'em 대비 추가분)

| 상태 | hand_in_progress | action_on | board_cards | discard_pending |
|------|:--------:|:-----:|:--------:|:--------:|
| **DISCARD_PHASE** | true | -1 | 0 | active 플레이어 수 |

> 참고: `discard_pending`은 Pineapple 전용 상태변수다. 초기값 = active 플레이어 수, 각 discard마다 -1, 0이 되면 FLOP 전이.

---

## 카드 배분

| 속성 | Hold'em | Pineapple |
|------|---------|-----------|
| 배분 카드 수 | 2장/인 | **3장/인** |
| 플레이 카드 수 | 2장 | 2장 (discard 후) |
| RFID 이벤트 (6인) | 12 | **18** (3장 x 6인) |
| 덱 소모 (6인, SETUP) | 12장 | 18장 |

### SETUP_HAND에서의 RFID 감지

| 좌석 | 안테나 | 감지 카드 수 |
|:----:|:------:|:----------:|
| 0 | 0, 1, 2 | 3장 |
| 1 | 3, 4, 5 | 3장 |
| 2~5 | 6~9 (순환) | 3장 |

> 참고: 안테나 할당은 테이블 설정에 따라 다를 수 있다. 위는 6인 기준 예시.

---

## 핸드 평가

**변경 없음** — `evaluator` = **standard_high**, best 5 of 7 (홀 2장 + 보드 5장). Discard 후 플레이어는 2장을 보유하므로 Hold'em과 동일한 평가를 적용한다.

---

## 베팅 변경 사항

**없음** — NL, PL, FL 모든 `bet_structure` 동일. `forced_bet` = blind, `betting_rounds` = 4. PRE_FLOP 베팅은 3장 보유 상태에서 진행하지만, 베팅 로직 자체는 Hold'em과 동일하다.

---

## Coalescence 변경 사항

DISCARD_PHASE 상태에 대한 coalescence 규칙을 추가 정의한다.

### DISCARD_PHASE coalescence 규칙

| 항목 | 규칙 |
|------|------|
| **CC 허용** | 없음 (자동 대기 상태, CC 버튼 비활성) |
| **예상 RFID** | Discard 1장/인 (burn zone #11) |
| **Engine Auto** | 모든 discard 완료 시 자동 FLOP 전이 |
| **버퍼 동작** | 표준 ±100ms, discard 완료까지 FLOP 전이 대기 |
| **RFID 중복** | 동일 UID 100ms 내 중복 → 폐기 |

### DISCARD_PHASE에서의 트리거 처리

| 트리거 | 처리 | 이유 |
|--------|------|------|
| RFID discard 감지 (burn zone) | **정상** — `discard_pending` -1 | 플레이어 discard 기록 |
| RFID 홀카드 재감지 | **무시** — 이미 등록된 카드 | 중복 감지 |
| CC 버튼 (액션) | **무효** — DISCARD_PHASE에서 CC 액션 불가 | 상태 불일치 |
| 타임아웃 30초 | **수동 모드** — 운영자 수동 입력 전환 | 자동 감지 실패 대비 |

---

## 예외 처리 변경 사항

### DISCARD_TIMEOUT

| 항목 | 값 |
|------|-----|
| **트리거** | DISCARD_PHASE 진입 후 30초 경과, 미완료 discard 존재 |
| **발동 주체** | 게임 엔진 자동 |
| **처리** | CC 수동 입력 모드로 전환 — 운영자가 미완료 플레이어의 discard 카드를 수동 지정 |
| **상태 유지** | **DISCARD_PHASE** 유지 (FLOP 전이 안 함) |

### 폴드 좌석 discard 처리

| 상황 | 처리 |
|------|------|
| PRE_FLOP에서 폴드한 플레이어 | `discard_pending`에서 제외 (자동 스킵) |
| 폴드 좌석에서 RFID discard 감지 | 감지 데이터 폐기 (기록만, 상태 변경 없음) |

### Miss Deal 기준 변경

| 항목 | Hold'em | Pineapple |
|------|---------|-----------|
| 감지 기준 | 홀카드 수 != 2 | 홀카드 수 != **3** |
| 처리 | IDLE 복귀 | IDLE 복귀 (동일) |

---

## 유저 스토리

| # | As a | When | Then |
|:-:|------|------|------|
| 1 | 시스템 | DISCARD_PHASE에서 플레이어 A가 카드 1장을 burn zone에 놓음 | RFID 감지 → discard 기록, `discard_pending` -1 |
| 2 | 시스템 | DISCARD_PHASE에서 1명 미완료, 30초 경과 | DISCARD_TIMEOUT → 운영자 수동 입력 모드 전환 |
| 3 | 시스템 | DISCARD_PHASE 중 RFID 에러 (burn zone 안테나 미감지) | 수동 입력 모드 전환, 운영자가 discard 카드 지정 |
| 4 | 시스템 | PRE_FLOP에서 폴드한 플레이어의 discard | 불필요, 자동 스킵 (`discard_pending`에서 제외) |
| 5 | 운영자 | NEW HAND 버튼 (game_id=3) | SETUP_HAND — 3장/인 배분, UI에 3장 표시 |
| 6 | 시스템 | 모든 active 플레이어 discard 완료 | `discard_pending` = 0 → 자동 FLOP 전이 |
| 7 | 시스템 | SETUP_HAND에서 RFID 홀카드 수 != 3 | Miss Deal — IDLE 복귀, 스택 복구 |

---

## 경우의 수 매트릭스

### 매트릭스 1: DISCARD_PHASE 진입 조건

| PRE_FLOP 결과 | active 플레이어 | DISCARD_PHASE 진입 | 다음 상태 |
|-------------|:-------------:|:-----------------:|----------|
| 베팅 완료, 2+ 남음 | 2+ | **예** | DISCARD_PHASE |
| 베팅 완료, all-in 발생 | 2+ (all-in 포함) | **예** | DISCARD_PHASE |
| 전원 폴드, 1명 남음 | 1 | **아니오** | HAND_COMPLETE |

### 매트릭스 2: DISCARD_PHASE 내 이벤트 처리

| 이벤트 | 조건 | 처리 | 상태 변화 |
|--------|------|------|----------|
| RFID discard 감지 | active 플레이어 | `discard_pending` -1 | 유지 또는 FLOP |
| RFID discard 감지 | 폴드 플레이어 | 폐기 (기록만) | 변화 없음 |
| 타임아웃 30초 | `discard_pending` > 0 | 수동 입력 모드 | DISCARD_PHASE 유지 |
| 수동 입력 완료 | 운영자 지정 | `discard_pending` -1 | 유지 또는 FLOP |
| 모든 discard 완료 | `discard_pending` = 0 | 자동 전이 | → FLOP |

### 매트릭스 3: Bomb Pot과 DISCARD_PHASE 상호작용

| Bomb Pot 모드 | DISCARD_PHASE | 이유 |
|:------------:|:------------:|------|
| **OFF** | 정상 진입 | 표준 흐름 |
| **ON** | **스킵** | Bomb Pot은 PRE_FLOP 스킵 → DISCARD_PHASE도 스킵, FLOP 직행 |

> 참고: Bomb Pot 모드에서는 PRE_FLOP 베팅이 없으므로 DISCARD_PHASE 진입 조건(PRE_FLOP 베팅 완료)이 충족되지 않는다. 3장 배분 후 discard 없이 3장 보유 상태로 FLOP에 진입한다.

---

## CC 버튼 활성 변경

DISCARD_PHASE에서의 CC 버튼 상태를 정의한다.

| 버튼 | DISCARD_PHASE | 이유 |
|------|:------------:|------|
| NEW HAND | 비활성 | 핸드 진행 중 |
| DEAL | 비활성 | 이미 딜 완료 |
| CHECK~FOLD | 비활성 | 베팅 라운드 아님 |
| ALL-IN | 비활성 | 베팅 라운드 아님 |
| UNDO | **활성** | 이전 상태(PRE_FLOP) 복원 가능 |

---

## 구현 체크리스트

- [ ] **DISCARD_PHASE** 상태 추가 (FSM state enum)
- [ ] `discard_pending` 상태변수 추가
- [ ] 3장 딜 RFID 감지 (SETUP_HAND, 3장/인)
- [ ] burn zone antenna #11 discard 감지
- [ ] 비동기 discard 완료 추적 (`discard_pending` 카운트다운)
- [ ] DISCARD_TIMEOUT 30초 → 수동 입력 모드
- [ ] 폴드 좌석 자동 스킵 (`discard_pending`에서 제외)
- [ ] Bomb Pot 모드에서 DISCARD_PHASE 스킵
- [ ] Miss Deal 기준: 홀카드 수 != 3
- [ ] DISCARD_PHASE에서 CC 버튼 비활성 (UNDO 제외)
