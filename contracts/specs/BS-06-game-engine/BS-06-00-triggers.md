# BS-06-00 Triggers — CC/RFID/Engine 트리거 경계 정의

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 4소스 이벤트 분류, Mock 합성 규칙, 충돌 해결, 순서 보장 |

---

## 개요

이 문서는 **어떤 이벤트가 누구에 의해 발동되는가**를 모든 경우의 수에 대해 정의한다. EBS의 4가지 이벤트 소스(CC, RFID, Engine, BO) 사이의 경계가 모호한 상황을 명시적으로 해결하며, Mock 모드에서 RFID 이벤트를 어떻게 합성하는지 규칙을 제공한다.

> **참조**: 용어·상태·FSM 정의는 `BS-00-definitions.md`, Enum 값 상세는 `BS-06-00-REF-game-engine-spec.md`, 핸드 라이프사이클 FSM은 `BS-06-01-holdem-lifecycle.md`

---

## 정의

**트리거**는 시스템 상태를 변경하는 입력 이벤트다. 모든 트리거는 반드시 하나의 발동 소스에 귀속된다.

---

## 1. 4소스 정의

> 참조: BS-00 §4 트리거 3소스 + BO 소스

| 소스 | 주체 | 처리 시간 | 신뢰도 | 채널 |
|------|------|---------|--------|------|
| **CC** | 운영자 (수동) | 즉시 (<50ms) | 낮음 (인간 오류 가능) | CC Flutter → Game Engine |
| **RFID** | 시스템 (자동) | 변동 (50~150ms) | 높음 (하드웨어) | RFID HAL → CC → Game Engine |
| **Engine** | 시스템 (자동) | 결정론적 (<10ms) | 최고 (규칙 기반) | Game Engine 내부 |
| **BO** | 시스템 (자동) | 변동 (100~500ms) | 높음 | BO WebSocket → CC/Lobby |

---

## 2. 이벤트 분류표 — 전체 카탈로그

### 2.1 CC 소스 이벤트 (운영자 수동)

운영자가 CC에서 버튼/키보드/터치로 발동하는 이벤트.

| 이벤트 | 트리거 조건 | 대상 FSM | 설명 |
|--------|-----------|---------|------|
| `StartHand` | IDLE 상태 + precondition 충족 | HandFSM | NEW HAND 버튼 |
| `Deal` | SETUP_HAND 상태 | HandFSM | 홀카드 딜 시작 |
| `Fold` | action_on == 해당 플레이어 | HandFSM | 카드 포기 |
| `Check` | biggest_bet_amt == 해당 플레이어 베팅액 | HandFSM | 패스 |
| `Bet` | biggest_bet_amt == 0 (첫 베팅) | HandFSM | 금액 입력 후 확인 |
| `Call` | biggest_bet_amt > 해당 플레이어 베팅액 | HandFSM | 콜 (동일 금액 맞추기) |
| `Raise` | biggest_bet_amt > 0 (기존 베팅 존재) | HandFSM | 추가 베팅 |
| `AllIn` | 스택 전부 베팅 | HandFSM | 올인 |
| `Undo` | hand_in_progress == true | HandFSM | 이전 이벤트 되돌리기 (최대 5단계) |
| `ManualNextHand` | HAND_COMPLETE 상태 | HandFSM | 다음 핸드로 이동 |
| `ManualCardInput` | 카드 입력 모드 활성 | — | 수동으로 카드 지정 (suit+rank) |
| `SeatAssign` | Table SETUP/LIVE | SeatFSM | 플레이어 좌석 배치 |
| `SeatVacate` | Seat OCCUPIED | SeatFSM | 플레이어 좌석 해제 |
| `SeatMove` | 두 Seat 간 이동 | SeatFSM | 플레이어 좌석 이동 |
| `PauseTable` | Table LIVE | TableFSM | 테이블 일시 중단 |
| `ResumeTable` | Table PAUSED | TableFSM | 테이블 재개 |
| `CloseTable` | Table LIVE/PAUSED | TableFSM | 테이블 종료 |
| `SetBombPot` | IDLE 상태 | HandFSM | Bomb Pot 모드 설정 (PRE_FLOP 스킵) |
| `SetRunItTimes` | SHOWDOWN 진입 전 올인 시 | HandFSM | Run It Multiple 횟수 설정 |
| `ConfirmChop` | HAND_COMPLETE 진입 전 | HandFSM | 칩 합의 분배 확인 |
| `RegisterDeck` | Deck UNREGISTERED | DeckFSM | 덱 등록 시작 (RFID 스캔 또는 Mock 자동) |

### 2.2 RFID 소스 이벤트 (시스템 자동)

RFID 리더가 안테나를 통해 카드를 감지/제거할 때 자동 발동하는 이벤트.

| 이벤트 | 트리거 조건 | payload | 설명 |
|--------|-----------|---------|------|
| `CardDetected` | 안테나 위에 카드 배치 | antennaId, cardUid, suit, rank, timestamp | 카드 인식됨 |
| `CardRemoved` | 안테나에서 카드 제거 | antennaId, cardUid, timestamp | 카드 제거됨 |
| `DeckRegistered` | 52장 전수 스캔 완료 | deckId, cardMap[52], timestamp | 덱 등록 완료 |
| `DeckRegistrationProgress` | 스캔 진행 중 | scannedCount, totalCount | 등록 진행률 |
| `AntennaStatusChanged` | 안테나 연결/해제 | antennaId, status, timestamp | 안테나 상태 변경 |
| `ReaderError` | 하드웨어 오류 | errorCode, message, antennaId | RFID 오류 |

> **RFID 이벤트는 `IRfidReader.events` 스트림을 통해 전달된다.** 상세: `API-03-rfid-hal-interface.md`

### 2.3 Engine 소스 이벤트 (시스템 자동)

Game Engine이 규칙에 따라 자동 발생시키는 이벤트. 외부 입력 없이 내부 상태 전이.

| 이벤트 | 트리거 조건 | 설명 |
|--------|-----------|------|
| `BlindsPosted` | SETUP_HAND 진입 + 블라인드 대상 확정 | SB/BB/Ante 자동 수집 |
| `HoleCardsDealt` | 모든 플레이어 홀카드 배분 완료 | → PRE_FLOP 전이 |
| `BettingRoundComplete` | 현재 라운드 모든 액션 완료 (동일 베팅액) | → 다음 Street 전이 |
| `AllFolded` | 1명 제외 전원 폴드 | → HAND_COMPLETE 직행 |
| `AllInRunout` | 올인 + 남은 베팅 불가 | 남은 보드 자동 공개 |
| `ShowdownStarted` | 최종 라운드 완료 + 2+ 플레이어 | 핸드 평가 시작 |
| `WinnerDetermined` | 핸드 평가 완료 | 우승자 + 팟 분배 계산 |
| `HandCompleted` | 팟 분배 + 통계 업데이트 완료 | → HAND_COMPLETE 전이 |
| `EquityUpdated` | 카드 상태 변경 (홀카드/보드 변경) | Monte Carlo/LUT 승률 재계산 |
| `SidePotCreated` | 올인 발생 시 초과분 분리 | 사이드 팟 생성 |
| `StatisticsUpdated` | 핸드 종료 시 | VPIP/PfR/WTSD/Agr 등 업데이트 |
| `MisdealDetected` | 카드 불일치 감지 | → IDLE 복귀, 스택 복원 |

### 2.4 BO 소스 이벤트 (시스템 자동)

Back Office에서 데이터 변경 시 WebSocket을 통해 Lobby/CC에 통지하는 이벤트.

| 이벤트 | 트리거 조건 | 수신 대상 | 설명 |
|--------|-----------|----------|------|
| `ConfigChanged` | Admin이 Settings 변경 | CC | 출력/오버레이/게임 설정 변경 |
| `PlayerUpdated` | Lobby에서 플레이어 정보 수정 | CC | 이름/프로필 변경 |
| `TableAssigned` | Lobby에서 테이블 설정 변경 | CC | RFID 할당, 덱 상태, 출력 설정 |
| `BlindStructureChanged` | Lobby에서 블라인드 레벨 변경 | CC | 새 레벨 적용 |
| `OperatorConnected` | CC가 BO에 WebSocket 연결 | Lobby | Lobby 모니터링 업데이트 |
| `OperatorDisconnected` | CC WebSocket 끊김 | Lobby | 연결 해제 알림 |
| `HandStarted` | CC에서 핸드 시작 → BO 기록 | Lobby | 모니터링 핸드 번호 갱신 |
| `HandEnded` | CC에서 핸드 종료 → BO 기록 | Lobby | 모니터링 결과 반영 |
| `GameChanged` | CC에서 Mix 게임 종목 변경 → BO 기록 | Lobby | 모니터링 종목 표시 |
| `RfidStatusChanged` | CC에서 RFID 상태 변경 → BO 기록 | Lobby | 테이블 카드 RFID 상태 |
| `OutputStatusChanged` | CC에서 출력 상태 변경 → BO 기록 | Lobby | 테이블 카드 출력 상태 |
| `ActionPerformed` | CC에서 액션 수행 → BO 기록 | Lobby (Admin) | 실시간 액션 모니터링 |

---

## 3. 경계 케이스 — CC vs RFID 동시 발생

### 3.1 카드 인식: RFID 자동 vs CC 수동

| 시나리오 | RFID 감지 | CC 수동 입력 | 우선순위 | 시스템 반응 |
|---------|:--------:|:-----------:|---------|-----------|
| Feature Table, Real 모드 | `CardDetected` | — | **RFID 우선** | 자동 인식된 카드 사용 |
| Feature Table, Real 모드, RFID 실패 | 실패/무응답 | `ManualCardInput` | **CC 폴백** | 수동 입력으로 전환 |
| Feature Table, Mock 모드 | — | `ManualCardInput` | **CC 유일** | 수동 입력 → `CardDetected` 합성 |
| General Table (RFID 없음) | — | `ManualCardInput` | **CC 유일** | 수동 입력만 가능 |
| Real 모드 + 수동 입력 동시 | `CardDetected` | `ManualCardInput` | **RFID 우선** | RFID 결과 사용, 수동 입력 무시 + 경고 로그 |

### 3.2 폴드 인식: CC 버튼 vs RFID 카드 제거

| 시나리오 | 시스템 반응 |
|---------|-----------|
| 운영자가 FOLD 버튼 클릭 | `Fold` 이벤트 즉시 처리. RFID 카드 제거는 무시 |
| RFID가 카드 제거 감지 (폴드 의도?) | **자동 폴드 안 함.** `CardRemoved` 경고 로그만. 운영자 FOLD 버튼 필수 |
| 운영자 FOLD + 동시에 RFID 카드 제거 | `Fold` 이벤트 1회만 처리 (중복 방지) |

> **핵심 원칙**: 카드 제거는 "정보"이지 "액션"이 아니다. 폴드는 반드시 운영자 의도(CC 버튼)로만 실행된다.

### 3.3 보드 카드 공개: RFID vs CC

| 시나리오 | 시스템 반응 |
|---------|-----------|
| RFID가 보드 카드 3장 감지 (Flop) | `CardDetected` × 3 → Engine이 FLOP 전이 허용 |
| 운영자가 수동으로 보드 카드 입력 | `ManualCardInput` × 3 → `CardDetected` 합성 → Engine 동일 처리 |
| RFID가 2장만 감지 (1장 미인식) | 경고 표시 → 운영자가 나머지 1장 수동 입력 → 혼합 가능 |

---

## 4. Mock 모드 이벤트 합성 규칙

### 4.1 기본 원칙

Mock HAL(`MockRfidReader`)은 CC UI의 수동 입력을 받아 **Real HAL과 동일한 이벤트 스트림**을 생성한다.

```
[운영자] → CC 수동 카드 입력 (suit, rank)
    → MockRfidReader.injectCard(suit, rank)
    → Stream<RfidEvent> emit: CardDetected(
        antennaId: 0,           // Mock 고정값
        cardUid: generated,      // "MOCK-{suit}{rank}" 형식
        suit: suit,
        rank: rank,
        timestamp: DateTime.now(),
        confidence: 1.0          // Mock은 항상 100%
      )
    → Game Engine 수신 (Real과 동일 처리)
```

### 4.2 이벤트별 합성 규칙

| Real 이벤트 | Mock 합성 방법 | 차이점 |
|------------|--------------|--------|
| `CardDetected` | CC 수동 카드 선택 → `injectCard()` | antennaId=0, uid="MOCK-XX", confidence=1.0 |
| `CardRemoved` | Mock에서 미지원 | 테스트 필요 시 `injectRemoval()` API 사용 |
| `DeckRegistered` | "자동 등록" 버튼 → 52장 가상 매핑 즉시 생성 | 스캔 시간 0ms, 진행률 100% 즉시 |
| `DeckRegistrationProgress` | "자동 등록" 시 1회 100% 이벤트 | Real은 1장씩 52회 이벤트 |
| `AntennaStatusChanged` | Mock 초기화 시 1회 `CONNECTED` | antenna 1개만 가상 존재 |
| `ReaderError` | `injectError(errorCode)` API | 테스트/데모용 에러 주입 |

### 4.3 시나리오 스크립트 재생 (E2E 테스트용)

Mock HAL은 **YAML 시나리오 파일**을 로드하여 사전 정의된 이벤트 시퀀스를 재생할 수 있다.

```yaml
# scenarios/holdem-basic.yaml
scenario: "Basic Hold'em Hand"
events:
  - type: DeckRegistered
    delay_ms: 0
  - type: CardDetected
    delay_ms: 100
    payload: { seat: 0, suit: 3, rank: 12 }  # As (플레이어 1 홀카드 1)
  - type: CardDetected
    delay_ms: 100
    payload: { seat: 0, suit: 2, rank: 11 }  # Kh (플레이어 1 홀카드 2)
  # ... 계속
```

> **시나리오 파일 상세**: `docs/testing/TEST-04-mock-data.md`

---

## 5. 충돌 해결 규칙

### 5.1 동일 이벤트 중복 수신

| 상황 | 해결 |
|------|------|
| 같은 카드 `CardDetected` 2회 수신 | 두 번째 이벤트 무시 + `DUPLICATE_CARD` 경고 로그 |
| `Fold` + `CardRemoved` 동시 | `Fold`만 처리 (§3.2) |
| `Bet(100)` + `Bet(200)` 빠른 연속 | 첫 `Bet` 처리 후 두 번째는 `Raise`로 재해석 또는 거부 |

### 5.2 소스 간 충돌

| 상황 | 우선순위 | 해결 |
|------|---------|------|
| CC + RFID 동시 카드 입력 (같은 카드) | RFID | 수동 입력 무시, RFID 결과 사용 |
| CC + RFID 동시 카드 입력 (다른 카드) | RFID | RFID 카드 사용 + `CARD_CONFLICT` 경고 + 운영자 확인 요청 |
| CC 액션 + BO ConfigChanged 동시 | CC | 게임 진행 액션 우선, Config는 핸드 종료 후 적용 (핸드 중간 설정 변경은 지연) |
| Engine 자동 전이 + CC Undo 동시 | CC | Undo가 Engine 자동 전이를 되돌림 |

---

## 6. 이벤트 순서 보장

### 6.1 선후관계 필수 케이스 (위반 시 에러)

| 선행 이벤트 | 후행 이벤트 | 이유 |
|-----------|-----------|------|
| `StartHand` | `BlindsPosted` | 핸드 시작 전 블라인드 수집 불가 |
| `BlindsPosted` | `HoleCardsDealt` | 블라인드 없이 딜 불가 |
| `HoleCardsDealt` | 첫 `Bet`/`Fold`/`Check` | 카드 없이 액션 불가 |
| `BettingRoundComplete` | 다음 Street 보드 카드 | 베팅 미완료 시 보드 공개 금지 |
| `CardDetected` (홀카드) | `EquityUpdated` | 카드 없이 승률 계산 불가 |
| `DeckRegistered` | 첫 `CardDetected` (게임 중) | 미등록 덱으로 게임 불가 |

### 6.2 순서 무관 케이스 (병렬 처리 가능)

| 이벤트 A | 이벤트 B | 이유 |
|---------|---------|------|
| `EquityUpdated` | `StatisticsUpdated` | 독립 계산 |
| `OperatorConnected` | `ConfigChanged` | 서로 다른 채널 |
| `PlayerUpdated` (Lobby) | `ActionPerformed` (CC) | 서로 다른 앱 |
| `CardDetected` (Seat 1) | `CardDetected` (Seat 2) | 서로 다른 안테나 |

---

## 7. 트리거와 HandFSM 상태 매핑 요약

| HandFSM 상태 | 허용 CC 트리거 | 허용 RFID 트리거 | 허용 Engine 트리거 |
|-------------|--------------|----------------|-------------------|
| **IDLE** | `StartHand`, `RegisterDeck` | `DeckRegistered`, `AntennaStatusChanged` | — |
| **SETUP_HAND** | `Deal` | `CardDetected` (홀카드) | `BlindsPosted` |
| **PRE_FLOP** | `Fold`, `Check`, `Bet`, `Call`, `Raise`, `AllIn`, `Undo` | — | `BettingRoundComplete`, `AllFolded`, `AllInRunout` |
| **FLOP** | `Fold`, `Check`, `Bet`, `Call`, `Raise`, `AllIn`, `Undo` | `CardDetected` (보드) | `BettingRoundComplete`, `AllFolded`, `AllInRunout` |
| **TURN** | `Fold`, `Check`, `Bet`, `Call`, `Raise`, `AllIn`, `Undo` | `CardDetected` (보드) | `BettingRoundComplete`, `AllFolded`, `AllInRunout` |
| **RIVER** | `Fold`, `Check`, `Bet`, `Call`, `Raise`, `AllIn`, `Undo` | `CardDetected` (보드) | `BettingRoundComplete`, `AllFolded`, `ShowdownStarted` |
| **SHOWDOWN** | `SetRunItTimes`, `ConfirmChop` | — | `WinnerDetermined`, `HandCompleted` |
| **RUN_IT_MULTIPLE** | — | `CardDetected` (추가 보드) | `HandCompleted` |
| **HAND_COMPLETE** | `ManualNextHand` | — | (overrideButton 시 자동 IDLE) |

---

## 비활성 조건

- Table 상태가 EMPTY 또는 CLOSED일 때 모든 게임 트리거 비활성
- RFID 모드가 Mock이고 `MockRfidReader`가 초기화되지 않은 경우 RFID 이벤트 미발생
- BO WebSocket 연결이 끊긴 경우 BO 소스 이벤트 미수신 (CC는 로컬 캐시로 계속 동작)

---

## 영향 받는 요소

| 영향 대상 | 이 문서와의 관계 |
|----------|----------------|
| `BS-04-rfid/` | RFID 이벤트 정의의 행동 명세 버전 |
| `BS-05-command-center/` | CC 이벤트의 UI 트리거 조건 |
| `BS-06-01-holdem-lifecycle.md` | HandFSM 상태 전이의 트리거 소스 |
| `API-03-rfid-hal-interface.md` | RFID HAL 인터페이스의 이벤트 타입 정의 |
| `API-05-websocket-events.md` | BO/CC 간 WebSocket 이벤트 프로토콜 |
| `BO-09-data-sync.md` | BO 소스 이벤트의 동기화 프로토콜 |
