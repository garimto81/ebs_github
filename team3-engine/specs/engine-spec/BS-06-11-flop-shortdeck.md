# BS-06-11: Short Deck Hold'em — Flop Extension

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-06 | 신규 작성 | Short Deck Hold'em 차이점 정의 (덱 구성, 핸드 랭킹 변형, RFID 검증) |
| 2026-04-09 | Phase 표시 | **Phase 3 범위** — Hold'em Core 구현 완료 후 착수 |

---

> **이 문서에서 사용하는 용어**
>
> | 용어 | 설명 |
> |------|------|
> | FSM | 게임 진행 단계를 정의한 상태 흐름도 (Finite State Machine) |
> | RFID | 무선 주파수로 카드를 자동 인식하는 기술. 카드에 내장된 IC를 테이블 센서가 읽는다 |
> | evaluator | 카드 조합을 분석하여 승자를 결정하는 함수 |
> | coalescence | 여러 센서 신호가 동시에 들어올 때 하나로 합치는 처리 규칙 |
> | CC | Command Center, 운영자가 게임을 제어하는 화면 |
> | NL/PL/FL | No Limit(무제한) / Pot Limit(팟 크기까지) / Fixed Limit(고정 금액) 베팅 구조 |
> | UID | 각 카드에 부여된 고유 식별 번호 |
> | antenna | RFID 카드를 감지하는 센서 (seat antenna = 좌석 센서, board antenna = 공용 카드 센서, burn zone antenna = 버린 카드 감지 센서) |
> | Bomb Pot | 모든 플레이어가 동일 금액을 미리 내고 Flop부터 시작하는 특수 모드 |

## 개요

Hold'em과 동일한 프로세스를 따르되, 36장 덱과 수정된 핸드 랭킹을 적용한다. `game_id` = 1은 Straight > Trips 규칙, `game_id` = 2는 Trips > Straight 규칙을 사용한다. FSM, 베팅, coalescence는 Hold'em과 완전히 동일하다.

---

## Hold'em과의 차이점 요약

| 항목 | Hold'em | Short Deck |
|------|---------|------------|
| `deck_size` | 52 | 36 (2, 3, 4, 5 제거) |
| `evaluator` | **standard_high** | **standard_high_modified** |
| 핸드 랭킹 | 표준 (Trips > Straight) | `game_id`별 변형 (아래 참조) |
| RFID 덱 등록 | 52장 전체 | 36장만 등록 |

---

## 덱 구성

52장 → 36장으로 축소한다. 랭크 2, 3, 4, 5를 제거하고 6~A만 사용한다.

| 속성 | 값 |
|------|-----|
| **남은 랭크** | 6, 7, 8, 9, 10, J, Q, K, A |
| **수트** | 4 (Spade, Heart, Diamond, Club) |
| **총 카드 수** | 9 ranks x 4 suits = 36장 |
| **제거 카드** | 2, 3, 4, 5 (4 suits x 4 ranks = 16장) |

### 확률 변화

| 핸드 | 52장 기준 | 36장 기준 | 변화 |
|------|---------|---------|------|
| **Flush** | 일반적 | 난이도 증가 | 수트당 카드 13→9장, 5장 동일 수트 확보 어려움 |
| **Straight** | 일반적 | 빈도 변화 | 연속 카드 범위 축소 (6~A), 조합 수 감소 |
| **Full House** | 일반적 | 빈도 증가 | 카드 풀 축소로 페어/트립스 확률 상대 증가 |

> 참고: 이 확률 변화가 핸드 랭킹 수정의 근거다. Flush가 더 희귀하므로 Full House보다 상위로 재배치된다.

---

## 핸드 랭킹 변형

### game_id = 1: Straight > Trips

`holdem_sixplus_straight` — Straight가 Trips보다 높은 핸드로 평가된다.

| 순위 | 핸드 | 설명 |
|:----:|------|------|
| 1 | **Royal Flush** | A-K-Q-J-10 동일 수트 |
| 2 | **Straight Flush** | 연속 5장 동일 수트 |
| 3 | **Four of a Kind** | 동일 랭크 4장 |
| 4 | **Flush** | 동일 수트 5장 (비연속) |
| 5 | **Full House** | 트립스 + 페어 |
| 6 | **Straight** | 연속 5장 (다른 수트) |
| 7 | **Three of a Kind** | 동일 랭크 3장 |
| 8 | **Two Pair** | 페어 2조 |
| 9 | **One Pair** | 페어 1조 |
| 10 | **High Card** | 위 해당 없음 |

**확률 근거**: 36장 덱에서 Straight 조합 수가 Trips보다 적다. 더 희귀한 핸드가 더 높은 순위를 받는다.

> 참고: 표준 Hold'em과 비교하면 Flush가 Full House 위로 이동하고, Straight가 Trips 위로 이동한다.

### game_id = 2: Trips > Straight

`holdem_sixplus_trips` — Trips가 Straight보다 높은 핸드로 평가된다. Triton Poker(Short Deck 변형 룰을 사용하는 하이스테이크 포커 대회) 룰.

| 순위 | 핸드 | 설명 |
|:----:|------|------|
| 1 | **Royal Flush** | A-K-Q-J-10 동일 수트 |
| 2 | **Straight Flush** | 연속 5장 동일 수트 |
| 3 | **Four of a Kind** | 동일 랭크 4장 |
| 4 | **Flush** | 동일 수트 5장 (비연속) |
| 5 | **Full House** | 트립스 + 페어 |
| 6 | **Three of a Kind** | 동일 랭크 3장 |
| 7 | **Straight** | 연속 5장 (다른 수트) |
| 8 | **Two Pair** | 페어 2조 |
| 9 | **One Pair** | 페어 1조 |
| 10 | **High Card** | 위 해당 없음 |

**확률 근거**: 이 변형은 36장 덱에서도 표준 순위에 더 가까운 배치를 유지한다. Flush만 Full House 위로 이동하고, Trips/Straight 순서는 표준과 동일하다.

---

## FSM 변경 사항

**없음** — Hold'em FSM 그대로 적용한다.

```
IDLE → SETUP_HAND → PRE_FLOP → FLOP → TURN → RIVER → SHOWDOWN → HAND_COMPLETE
```

모든 상태 전이 조건, Entry/Exit 규칙, 특수 상황 오버라이드(All Fold, All-in, Bomb Pot, Run It Multiple, Miss Deal, UNDO)가 Hold'em과 동일하다.

---

## 베팅 변경 사항

**없음** — NL, PL, FL 모든 `bet_structure` 동일하게 적용한다. `forced_bet` = blind, `betting_rounds` = 4.

---

## RFID 변경 사항

덱 크기가 36장으로 축소되므로 RFID 시스템의 카드 등록 및 검증 로직이 변경된다.

### 덱 스캔

| 항목 | Hold'em | Short Deck |
|------|---------|------------|
| 등록 카드 수 | 52장 | 36장 |
| 예상 미감지 | 0장 | 16장 (2~5 x 4 suits) |
| 미감지 카드 처리 | 에러 | 정상 (제거된 카드) |

### 유효하지 않은 카드 감지

| 트리거 | 감지 조건 | 처리 |
|--------|---------|------|
| **RFID 자동** | 랭크 2, 3, 4, 5 카드 UID 감지 | **WRONG_CARD** 에러 발생 |
| **게임 엔진** | `deck_size` = 36인데 36장 외 카드 입력 | **WRONG_CARD** 에러 발생 |

**WRONG_CARD 에러 처리**:
1. 오버레이에 경고 표시 (운영자 알림)
2. 해당 카드 무효 처리 (핸드 상태 유지)
3. 운영자가 물리적 카드 제거 후 정상 카드로 교체

---

## Coalescence 변경 사항

**없음** — Hold'em coalescence 규칙 그대로 적용한다. 트리거 우선순위(RFID > CC > Engine), ±100ms 병합 윈도우, 중복 폐기 규칙 모두 동일.

---

## 핸드 평가 변경 사항

| 항목 | Hold'em | Short Deck |
|------|---------|------------|
| `evaluator` | **standard_high** | **standard_high_modified** |
| 랭킹 테이블 | 표준 10단계 | `game_id`별 수정 10단계 |
| 조합 규칙 | best 5 of 7 | best 5 of 7 (동일) |
| `hole_cards` | 2 | 2 (동일) |
| `board_cards` | 5 | 5 (동일) |

> 참고: 핸드 평가 함수만 다르고, 카드 조합 방식(홀 2 + 보드 5 = 7장 중 최고 5장)은 Hold'em과 동일하다.

---

## 예외 처리 변경 사항

### 덱 불일치

| 상황 | 조건 | 처리 |
|------|------|------|
| 덱 카드 수 부족 | SETUP_HAND 시 36장 미만 감지 | **Miss Deal** — IDLE 복귀 |
| 덱 카드 수 초과 | SETUP_HAND 시 36장 초과 감지 | **Miss Deal** — IDLE 복귀 |
| 유효하지 않은 카드 | 핸드 중 2~5 카드 감지 | **WRONG_CARD** 에러 (핸드 유지) |

### 유저 스토리

| # | As a | When | Then |
|:-:|------|------|------|
| 1 | 운영자 | `game_id` = 1 또는 2 선택 | `deck_size` 자동 36으로 설정, RFID 36장 등록 |
| 2 | 시스템 | SETUP_HAND에서 RFID가 36장이 아닌 카드 수 감지 | Miss Deal 처리, IDLE 복귀 |
| 3 | 시스템 | 핸드 중 랭크 2~5 카드 RFID 감지 | WRONG_CARD 에러, 운영자 알림 |
| 4 | 시스템 | SHOWDOWN에서 `game_id`=1 핸드 평가 | Straight > Trips 랭킹 적용 |
| 5 | 시스템 | SHOWDOWN에서 `game_id`=2 핸드 평가 | Trips > Straight 랭킹 적용 |

---

## 경우의 수 매트릭스

### 매트릭스 1: game_id별 핸드 랭킹 차이

| 순위 | Hold'em (game_id=0) | Short Deck (game_id=1) | Short Deck (game_id=2) |
|:----:|---------------------|----------------------|----------------------|
| 4 | **Flush** | **Flush** | **Flush** |
| 5 | **Straight** | **Full House** | **Full House** |
| 6 | **Three of a Kind** | **Straight** | **Three of a Kind** |
| 7 | **Two Pair** | **Three of a Kind** | **Straight** |

> 참고: 순위 1~3 (Royal Flush, Straight Flush, Four of a Kind)과 8~10 (Two Pair, One Pair, High Card)은 세 게임 모두 동일.

### 매트릭스 2: RFID 카드 검증 경우의 수

| 감지 카드 | `deck_size` | 처리 | 에러 |
|---------|:-----------:|------|------|
| 랭크 6~A | 36 | **정상** 처리 | 없음 |
| 랭크 2~5 | 36 | **무효** 처리 | WRONG_CARD |
| 랭크 6~A | 52 (Hold'em) | **정상** 처리 | 없음 |
| 랭크 2~5 | 52 (Hold'em) | **정상** 처리 | 없음 |

### 매트릭스 3: 덱 초기화 경우의 수

| 조건 | 감지 카드 수 | 결과 |
|------|:----------:|------|
| 36장 정확히 감지 | 36 | **정상** — 핸드 시작 가능 |
| 36장 미만 감지 | < 36 | **Miss Deal** — 카드 부족 |
| 36장 초과 감지 | > 36 | **Miss Deal** — 비정상 카드 혼입 |

---

## 구현 체크리스트

- [ ] 36장 덱 필터링 (2~5 제거)
- [ ] `game_id`=1: Straight > Trips 랭킹 적용
- [ ] `game_id`=2: Trips > Straight 랭킹 적용
- [ ] RFID 덱 스캔 36장 검증
- [ ] 유효하지 않은 카드 감지 시 WRONG_CARD 에러
- [ ] `deck_size` = 36 자동 설정 (`game_id` 1, 2 선택 시)
- [ ] `evaluator` = `standard_high_modified` 라우팅
