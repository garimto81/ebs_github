# BS-05-05 Command Center — Undo 및 에러 복구

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | Undo 5단계, Event Sourcing 기반, 에러 복구 시나리오, 유저 스토리 10개 |
| 2026-04-13 | UI-02 redesign | Undo 5단계 제한 제거 → 무제한 (현재 핸드 내), 10개/페이지 페이지네이션 |

---

## 개요

CC는 Event Sourcing 아키텍처를 사용하여 모든 게임 이벤트를 순서대로 기록한다. Undo는 이 이벤트 로그에서 마지막 이벤트를 되돌려 이전 상태를 복원하는 기능이다. 현재 핸드 내에서 무제한 Undo가 가능하다.

> 참조: BS-00 §6 이벤트 명명 규약, BS-06-00-triggers.md §2.1 Undo 이벤트

---

## 정의

| 용어 | 정의 |
|------|------|
| **Event Sourcing** | 상태를 직접 저장하지 않고, 이벤트의 순서 목록으로 상태를 재구성하는 패턴 |
| **Undo Stack** | 현재 핸드에서 발생한 이벤트의 스택. 무제한 (현재 핸드 내) |
| **Redo** | Undo를 되돌리는 기능. EBS v1.0에서는 미지원 (추후 검토) |

---

## 트리거

| 트리거 | 발동 주체 | 단축키 | 설명 |
|--------|----------|:------:|------|
| `Undo` | 운영자 (CC) | Ctrl+Z | 마지막 이벤트 1개 되돌리기 |
| UNDO 버튼 클릭 | 운영자 (CC) | — | UI 버튼 |

---

## 전제조건

| 조건 | 설명 |
|------|------|
| hand_in_progress == true | 핸드 진행 중이어야 Undo 가능 |
| undo_stack.length > 0 | 되돌릴 이벤트가 있어야 함 |
| 핸드 진행 중 | HandCompleted 이후 undo 불가 |

---

## 1. Undo 범위 및 동작

### 1.1 Undo 가능 이벤트

| 이벤트 유형 | Undo 가능 | 복원 내용 |
|-----------|:--------:|----------|
| **Fold** | ✅ | player.status → active 복원, num_active_players +1 |
| **Check** | ✅ | action_on → 이전 플레이어 복원 |
| **Bet** | ✅ | biggest_bet_amt 복원, 플레이어 스택 + amount, 팟 - amount |
| **Call** | ✅ | 플레이어 스택 + call_amount, 팟 - call_amount |
| **Raise** | ✅ | biggest_bet_amt 복원, 스택/팟/min_raise 복원 |
| **AllIn** | ✅ | player.status → active, 스택 복원, 팟 - allin_amount |
| **ManualCardInput** | ✅ | 카드 슬롯 비우기, 그리드에서 카드 다시 사용 가능 |
| **Deal** | ✅ | 홀카드 전부 제거, SETUP_HAND 복귀 |

### 1.2 Undo 불가 이벤트

| 이벤트 유형 | 이유 |
|-----------|------|
| **StartHand** | 핸드 시작은 되돌릴 수 없음 (Miss Deal 사용) |
| **BlindsPosted** | Engine 자동 이벤트, 운영자 Undo 대상 아님 |
| **WinnerDetermined** | SHOWDOWN 결과 확정 후 불가 |
| **HandCompleted** | 핸드 종료 후 불가 (이전 핸드 접근 금지) |

### 1.3 Undo 동작 흐름

| 단계 | 시스템 동작 |
|:----:|------------|
| 1 | undo_stack에서 마지막 이벤트 pop |
| 2 | 이벤트의 역연산 실행 (상태 변수 복원) |
| 3 | action_on을 이전 값으로 복원 |
| 4 | CC UI 갱신 (좌석 상태, 팟, 스택, 보드) |
| 5 | Overlay에 복원된 상태 전송 |
| 6 | undo_depth += 1 |

### Undo 범위

- **제한 없음**: 현재 핸드 내 모든 액션 undo 가능 (기존 5단계 제한 제거, UI-02 2026-04-13)
- **경계**: HandCompleted 이후에는 undo 불가 (핸드 결과 확정)
- **페이지네이션**: 10개/페이지로 표시 ([Prev] / [Next])

### 1.4 연속 Undo (예시)

| 연속 Undo | 예시 |
|----------|------|
| 1회 | Player A의 Raise 되돌리기 → action_on = A, biggest_bet_amt 복원 |
| 2회 | Player B의 Call 되돌리기 → action_on = B |
| 3회 | Player C의 Fold 되돌리기 → C 다시 active |
| N회 | 현재 핸드 내 모든 이벤트까지 가능 |

---

## 2. Undo 가능 범위

### 2.1 현재 핸드 내만

| 범위 | Undo 가능 | 이유 |
|------|:--------:|------|
| 현재 핸드 이벤트 | ✅ | Event Sourcing 스택에 보존 |
| 이전 핸드 이벤트 | ❌ | HAND_COMPLETE 시 스택 클리어 |
| 다른 테이블 이벤트 | ❌ | CC 인스턴스 독립 |

### 2.2 스트리트 경계 Undo

베팅 라운드가 완료되어 다음 스트리트로 전이된 후에도 Undo 가능:

| 시나리오 | Undo 결과 |
|---------|----------|
| FLOP 진입 직후, 마지막 PRE_FLOP 액션 Undo | → PRE_FLOP 복귀, 보드 카드 제거 |
| TURN 진입 직후, FLOP 마지막 액션 Undo | → FLOP 복귀, Turn 카드 제거 |

> 보드 카드가 이미 RFID로 감지된 경우에도 Undo 시 소프트웨어 상에서 제거된다 (물리 카드는 테이블 위에 그대로).

---

## 3. Undo UI 표시

| 요소 | 표시 |
|------|------|
| **UNDO 버튼** | 항상 표시 (액션 패널 보조 영역) |
| **Undo 스택 크기** | 버튼에 숫자 뱃지 (예: "UNDO (3)") |
| **Undo 불가 시** | 버튼 비활성 (회색) + "0" 표시 |
| **Undo 실행 시** | 되돌린 이벤트 텍스트 일시 표시 (예: "Undo: Fold by Seat 3") |

---

## 4. 에러 복구 시나리오

### 4.1 미스딜 (Miss Deal)

| 항목 | 내용 |
|------|------|
| **감지** | SETUP_HAND 중 홀카드 수 불일치, 또는 운영자가 MISS DEAL 버튼 클릭 |
| **확인** | "미스딜을 선언하시겠습니까?" 확인 다이얼로그 |
| **복구 동작** | HandFSM → IDLE, 팟 전액 원래 스택 복원, board_cards 클리어 |
| **Undo 스택** | 전체 클리어 (새 핸드로 리셋) |

### 4.2 잘못된 카드 입력

| 시나리오 | 복구 방법 |
|---------|----------|
| 홀카드 잘못 입력 (아직 베팅 전) | 카드 슬롯 클릭 → 제거 → 재입력 |
| 홀카드 잘못 입력 (베팅 진행 후) | Undo로 액션 되돌리기 → 카드 재입력 |
| 보드 카드 잘못 입력 (베팅 전) | 보드 슬롯 클릭 → 제거 → 재입력 |
| 보드 카드 잘못 입력 (베팅 후) | Undo로 해당 스트리트 베팅 전체 되돌리기 |

### 4.3 운영자 실수 — 잘못된 액션

| 시나리오 | 복구 방법 |
|---------|----------|
| 잘못된 플레이어에 Fold 입력 | Undo (Ctrl+Z) → 올바른 플레이어 선택 → 재입력 |
| BET 대신 ALL-IN 입력 | Undo → BET으로 재입력 |
| 금액 오입력 (BET 500 대신 5000) | Undo → 올바른 금액으로 재입력 |
| 여러 액션 연속 오류 | 연속 Undo (무제한, 현재 핸드 내) → 정상 지점에서 재입력 |

### 4.4 RFID 오류 복구

| 시나리오 | 복구 방법 |
|---------|----------|
| RFID가 잘못된 카드 감지 | Undo로 카드 제거 → 수동 입력으로 올바른 카드 지정 |
| RFID 중간 연결 해제 | 수동 입력 폴백 모드 자동 전환 |
| RFID 재연결 | 자동 Real 모드 복귀, 이후 카드 RFID 감지 |

---

## 유저 스토리

| # | As a | When | Then |
|:-:|------|------|------|
| 1 | 운영자 | Player A를 잘못 Fold 처리 | Ctrl+Z → Fold 되돌림, Player A 다시 active |
| 2 | 운영자 | BET 금액 오입력 (500 대신 5000) | Undo → BET 되돌림 → 올바른 금액 500으로 재입력 |
| 3 | 운영자 | 3번 연속 잘못된 액션 입력 | Ctrl+Z × 3 → 3개 액션 순서대로 되돌림 |
| 4 | 운영자 | 현재 핸드 모든 액션 Undo | StartHand까지 도달 시 추가 Undo 불가 (Miss Deal 사용) |
| 5 | 운영자 | 미스딜 발생 | MISS DEAL 클릭 → 확인 → 스택 복원, IDLE |
| 6 | 운영자 | FLOP 진입 직후 PRE_FLOP 마지막 액션 Undo | PRE_FLOP 복귀, 보드 카드 제거 |
| 7 | 운영자 | RFID가 잘못된 카드 감지 | Undo → 카드 제거 → 수동으로 올바른 카드 입력 |
| 8 | 운영자 | HAND_COMPLETE 후 이전 핸드 Undo 시도 | Undo 불가, 버튼 비활성 |
| 9 | 운영자 | Undo 후 올바른 액션 재입력 | 정상 진행, undo_depth 리셋되지 않음 (추가 Undo 가능) |
| 10 | 운영자 | ALL-IN 잘못 입력 후 Undo | 스택 복원, player.status → active, 사이드 팟 제거 |

---

## 경우의 수 매트릭스

### Matrix: 이벤트 유형 × Undo 복원 내용

| 이벤트 | action_on 복원 | 스택 복원 | 팟 복원 | player.status 복원 | 보드 복원 |
|--------|:----------:|:-------:|:-----:|:--------------:|:-------:|
| **Fold** | ✅ | — | — | folded → active | — |
| **Check** | ✅ | — | — | — | — |
| **Bet** | ✅ | + amount | - amount | — | — |
| **Call** | ✅ | + call_amt | - call_amt | allin → active (short call 시) | — |
| **Raise** | ✅ | + raise_diff | - raise_diff | — | — |
| **AllIn** | ✅ | + allin_amt | - allin_amt | allin → active | — |
| **ManualCardInput** | — | — | — | — | 카드 제거 |
| **Deal** | — | — | — | — | 홀카드 전체 제거 |

---

## 비활성 조건

- hand_in_progress == false일 때 Undo 불가
- undo_stack.length == 0일 때 Undo 버튼 비활성
- undo_stack이 StartHand까지 도달 시 추가 Undo 불가 (Miss Deal 사용)
- HAND_COMPLETE 상태에서 Undo 불가

---

## 영향 받는 요소

| 영향 대상 | 이 문서와의 관계 |
|----------|----------------|
| BS-05-01 핸드 라이프사이클 | Undo 시 HandFSM 상태 복원 |
| BS-05-02 액션 버튼 | Undo 후 버튼 활성 상태 재계산 |
| BS-05-04 수동 카드 입력 | 카드 입력 Undo 시 그리드 복원 |
| BS-06-01-holdem-lifecycle | Engine 상태 복원 규칙 |
| BS-07-overlay | Undo 시 Overlay 화면 동기 복원 |
