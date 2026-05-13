---
title: CR-team4-20260410-bs05-protocol-gaps
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team4-20260410-bs05-protocol-gaps
confluence-page-id: 3819209842
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819209842/EBS+CR-team4-20260410-bs05-protocol-gaps
---

# CCR-DRAFT: BS-05 서버 프로토콜 매핑 및 내부 모호성 해소

- **제안팀**: team4
- **제안일**: 2026-04-10
- **영향팀**: [team2]
- **변경 대상 파일**: contracts/specs/BS-05-command-center/BS-05-00-overview.md, contracts/specs/BS-05-command-center/BS-05-01-hand-lifecycle.md, contracts/specs/BS-05-command-center/BS-05-02-action-buttons.md, contracts/specs/BS-05-command-center/BS-05-03-seat-management.md, contracts/specs/BS-05-command-center/BS-05-04-manual-card-input.md, contracts/api/`WebSocket_Events.md` (legacy-id: API-05)
- **변경 유형**: modify
- **변경 근거**: WSOP 원본(`EBS UI Design Action Tracker.md` §6)에 명시된 서버 프로토콜 이름(SendPlayerFold, SendPlayerBet, SendPlayerAllIn, UndoLastAction, WriteGameInfo, ActionOnResponse)이 BS-05에 누락되어 있고, 이전 critic 분석에서 식별된 내부 모호성 6건(W2, W6, W8, W9, W10, W12)이 구현 리스크로 남아 있음. 특히 BO 연결 상실 시 복구 규칙 부재는 라이브 방송 사고의 직접 원인이 될 수 있음.

## 변경 요약

### A. 서버 프로토콜 이름 매핑 (G14, G15, G16)

BS-05-02와 API-05 사이에 Cross-reference를 강화하여 WSOP 조직 내 공유 용어(PokerGFX 역설계 자산)를 계약에 반영.

### B. 내부 모호성 해소 (6건)

| # | 모호 영역 | 해소 방향 |
|:-:|---------|---------|
| W2 | BO 연결 상실 시 동기화 규칙 | 핸드 진행 중 로컬 Event Sourcing + ReplayEvents 정책 |
| W6 | Table FSM vs HandFSM 경계 (PAUSED 소속) | PAUSED는 Table FSM 상태로 확정 |
| W8 | Sitting Out 즉시/지연 적용 | 핸드 진행 중 토글 = 다음 핸드, IDLE 토글 = 즉시 |
| W9 | Straddle + BB Check Option 충돌 | Straddle 있을 때 BB Check Option 비활성, Straddle 플레이어가 마지막 옵션 |
| W10 | RFID 5초 대기 의미 | (CCR-DRAFT #2에서 해소됨, 본 CCR에서는 참조) |
| W12 | RFID 완료 시 자동 스트리트 전이 | RFID 완료 시 Engine 자동 전이, Run It Multiple은 예외 |

## 변경 내용

### 1. BS-05-02-action-buttons.md §서버 프로토콜 매핑 (신규 섹션)

> **참조**: `WebSocket_Events.md` (legacy-id: API-05) §이벤트 카탈로그의 Cross-reference로 연결. BS-05는 운영자 관점(버튼 → 프로토콜), API-05는 전송 관점(프로토콜 스키마)으로 역할 분리.

#### 버튼 → 서버 프로토콜 매핑

| 버튼 | CC → Server 프로토콜 | 필드 | Server → CC 선행 조건 |
|------|-------------------|------|---------------------|
| NEW HAND | `WriteGameInfo` | `{ hand_id, dealer_seat, sb_seat, bb_seat, ante, straddles[], allowed_games, rotation_order, blind_structure_id, ... }` (22+ 필드) | — |
| DEAL | (Engine 자동, 프로토콜 없음) | — | `WriteGameInfo` 완료 |
| FOLD | `SendPlayerFold` | `{ hand_id, seat_no }` | `ActionOnResponse { seat_no, allowed_actions }` |
| CHECK | `SendPlayerBet` | `{ hand_id, seat_no, amount: 0 }` | `ActionOnResponse` |
| CALL | `SendPlayerBet` | `{ hand_id, seat_no, amount: biggest_bet - current_bet }` | `ActionOnResponse` |
| BET | `SendPlayerBet` | `{ hand_id, seat_no, amount }` | `ActionOnResponse` |
| RAISE-TO | `SendPlayerBet` | `{ hand_id, seat_no, amount: raise_to_value }` | `ActionOnResponse` |
| ALL-IN | `SendPlayerAllIn` | `{ hand_id, seat_no }` | `ActionOnResponse` |
| UNDO | `UndoLastAction` | `{ hand_id }` | `GameStateSync { full_state }` |
| MISS DEAL | `AbortHand` | `{ hand_id, reason: "miss_deal" }` | — |
| CHOP | `ChopPot` | `{ hand_id, share_mode: "equal" }` | — |
| RUN IT (X2/X3) | `SetRunItMultiple` | `{ hand_id, run_count }` | ALL-IN 상황에서만 |

#### 버튼 활성 전제 (G15 해소)

> **규칙**: "서버에서 `ActionOnResponse`를 수신하기 전까지는 모든 액션 버튼(FOLD/CHECK/CALL/BET/RAISE/ALL-IN)이 **비활성(회색)** 상태로 표시된다."
>
> 이는 기존의 HandFSM × biggest_bet × current_bet × stack 매트릭스와 **추가 AND 조건**으로 적용된다. 즉 HandFSM이 PRE_FLOP이고 stack > 0이어도 `ActionOnResponse` 미수신이면 비활성.

#### 참조 보강

API-05-websocket-events.md의 Cross-reference CCR을 Team 2가 별도로 제출해야 하는 항목:

- `ActionPerformed` → `SendPlayerFold`/`SendPlayerBet`/`SendPlayerAllIn` 세분화
- `HandStarted` → `WriteGameInfo` 매핑 명시
- `UndoRequested` → `UndoLastAction` 매핑 명시
- `ActionRequested` → `ActionOnResponse` (서버→CC) 방향 명시

### 2. BS-05-00-overview.md §BO 연결 상실 복구 (신규 섹션, W2 해소)

#### 감지

- WebSocket `Ping` 30초 간격 / `Pong` 10초 타임아웃 (API-05 §하트비트 참조)
- 3회 연속 Pong 타임아웃 시 연결 상실로 판단

#### 복구 흐름

```
BO WebSocket 연결 상실 감지
  │
  ├─ 핸드 미진행 (HandFSM == IDLE)
  │   ├─ AT-01 우상단 연결 상태 아이콘 → 적색
  │   ├─ M-01 Toolbar에 "재연결 중..." 토스트
  │   ├─ 재연결 시도: 0ms → 5s → 10s × 최대 100회 → 중단
  │   └─ 재연결 성공:
  │        ├─ BO에 GET /tables/{id}/state 호출
  │        ├─ 서버 상태 수신 → IDLE 복귀
  │        └─ 연결 상태 아이콘 → 녹색
  │
  └─ 핸드 진행 중 (HandFSM ∈ { PRE_FLOP, FLOP, TURN, RIVER, SHOWDOWN })
      ├─ AT-01 최상단에 경고 배너 "BO 연결 끊김 — 로컬 모드 (액션 X/20)"
      ├─ 로컬 Event Sourcing 스택에 모든 액션 기록 (최대 20 이벤트)
      ├─ 액션 버튼은 정상 활성 (로컬 검증만, 서버 ActionOnResponse 무시)
      ├─ RFID 감지는 계속 동작 (로컬 스택에 기록)
      │
      └─ 재연결 성공 시:
         ├─ 로컬 이벤트 스택을 `ReplayEvents` 프로토콜로 BO에 일괄 전송
         │   payload: { hand_id, events: [{ type, payload, local_timestamp }, ...] }
         │
         ├─ BO 응답 처리
         │   ├─ Accept: 모든 이벤트 수용 → 현재 상태 동기화 → 배너 해제
         │   ├─ PartialAccept: N개까지만 수용 → "일부 이벤트 거부. N번째부터 재입력 필요" 다이얼로그
         │   └─ Reject: "동기화 실패 — 핸드 Reset 필요" 다이얼로그 → 운영자 확인 후 `AbortHand` 호출
         │
         └─ 20 이벤트 초과 시:
             ├─ 로컬 스택 가득 참 → "이벤트 버퍼 초과" 경고 배너
             ├─ 새 액션 입력 차단
             └─ 운영자가 핸드 Reset 선택 가능
```

#### 구현 요구사항

| 요구사항 | 값 |
|---------|---|
| 하트비트 간격 | 30초 |
| Pong 타임아웃 | 10초 |
| 재연결 백오프 | 0ms → 5s → 10s × 100 → 중단 |
| 로컬 이벤트 버퍼 크기 | 20 |
| ReplayEvents 최대 payload | 20 × 2KB = 40KB |

### 3. BS-05-00-overview.md §Table FSM vs HandFSM 경계 (W6 해소)

```
Table FSM (BS-00 §3.X에 정의, CC가 소비)
  ├─ EMPTY: 테이블 없음. CC 시작 불가.
  ├─ CLOSED: 운영 종료. CC 읽기 전용.
  ├─ SETUP: 테이블 생성 중. CC가 좌석 배치/Player 편집 가능, NEW HAND 불가.
  ├─ LIVE: 핸드 진행 가능. HandFSM 활성.
  └─ PAUSED: 운영 일시 중지. HandFSM은 현재 상태 동결. 모든 액션 버튼 비활성.

HandFSM (BS-06-01에 정의, Table == LIVE일 때만 활성)
  └─ IDLE → SETUP_HAND → PRE_FLOP → FLOP → TURN → RIVER → SHOWDOWN → COMPLETE → IDLE
```

**결정**:
- `PAUSED`는 **Table FSM** 상태로 확정
- BS-00 §3.X에 Table FSM 정의 명시 예정 (본 CCR의 후속으로 Team 4가 BS-00 CCR 제출 또는 Conductor가 직접 보강)
- BS-05-02의 "Table 상태가 PAUSED일 때 모든 액션 버튼 비활성" 규칙은 Table FSM PAUSED를 참조하도록 업데이트

**CC UI 동작 (Table FSM별)**:

| Table FSM | M-01 Toolbar | M-07 액션 패널 | M-05 좌석 편집 |
|-----------|:-----------:|:------------:|:-----------:|
| EMPTY | 비활성 | 비활성 | 불가 |
| SETUP | 제한적 | 비활성 (NEW HAND 불가) | 가능 |
| LIVE | 전체 활성 | HandFSM 따름 | IDLE 상태만 가능 |
| PAUSED | 제한적 (Resume만) | 전부 비활성 | 불가 |
| CLOSED | 읽기 전용 | 비활성 | 불가 |

### 4. BS-05-04-manual-card-input.md §RFID 자동 전이 트리거 (W12 해소)

> **규칙**: "RFID로 보드 카드가 올바른 수만큼 감지(모두 DEALT 상태 진입)되면, Engine이 자동으로 다음 스트리트로 전이한다. 운영자 확인 불필요."
>
> **카드 수 기준**:
> - Flop: 보드 3장 모두 DEALT → Engine 자동 전이 (PRE_FLOP → FLOP)
> - Turn: 보드 4장째 DEALT → Engine 자동 전이 (FLOP → TURN)
> - River: 보드 5장째 DEALT → Engine 자동 전이 (TURN → RIVER)
>
> **예외 (Run It Multiple)**: Run It 2/3이 활성된 상황에서는 자동 전이하지 않고, CC가 "Which board?" 선택 UI를 표시한다. 운영자가 보드 선택 후 해당 보드만 전이된다.
>
> **수동 입력 경로**: AT-03 Card Selector로 카드를 선택한 경우도 동일하게 자동 전이된다 (RFID와 수동 입력의 결과는 동등).

### 5. BS-05-03-seat-management.md §Sitting Out 적용 시점 (W8 해소)

> **규칙**:
> - **현재 핸드 진행 중** Sitting Out 토글: **다음 핸드부터** 적용. 현재 핸드는 플레이어가 계속 참여하며, 이미 들어간 베팅은 유지.
> - **IDLE 상태에서** Sitting Out 토글: **즉시** 적용. 다음 NEW HAND 시점에 이 플레이어는 제외된다.
>
> **자동 폴드 규칙**: `player.status == sitting_out`이고 해당 플레이어의 액션 차례가 오면, CC는 자동으로 `SendPlayerFold`를 호출한다. 운영자 확인 불필요.
>
> **Sit Back In 규칙**: Sitting Out 상태에서 IDLE 동안 운영자가 토글을 해제하면, 다음 NEW HAND부터 참여한다.

### 6. BS-05-02-action-buttons.md §Straddle × BB Check Option 충돌 (W9 해소)

> **규칙**:
> - **Straddle 없음 + PRE_FLOP + biggest_bet == BB + action_on == BB_seat**:
>   BB는 `CHECK` 가능 (BB Check Option). CHECK 하면 FLOP으로 전이.
>
> - **Straddle 있음 + PRE_FLOP + action_on == BB_seat**:
>   BB Check Option **비활성**. BB는 Straddle 금액만큼 `CALL`하거나 `RAISE`해야 한다.
>   
>   근거: Straddle 플레이어가 `biggest_bet` 보유자가 되므로, BB는 `biggest_bet == current_bet` 조건을 만족하지 못한다.
>
> - **Straddle 있음 + PRE_FLOP + action_on == Straddle_seat + 모든 플레이어가 Straddle CALL 완료**:
>   Straddle 플레이어가 "마지막 Check Option 보유자"가 된다. 
>   이 상태에서 Straddle 플레이어는 `CHECK` 가능. CHECK 하면 FLOP으로 전이.
>
> **상태 판단**: 
> `BB Check Option Available = (biggest_bet == BB_amount) && (action_on == BB_seat) && (no_raise_this_round)`
> `Straddle Check Option Available = (biggest_bet == Straddle_amount) && (action_on == Straddle_seat) && (all_others_called_or_folded)`

## Diff 초안

```diff
 # BS-05-02-action-buttons.md

+## 6. 서버 프로토콜 매핑
+
+> 참조: `WebSocket_Events.md` (legacy-id: API-05) §이벤트 카탈로그
+
+| 버튼 | CC → Server | 필드 |
+|------|-----------|------|
+| NEW HAND | WriteGameInfo | hand_id, dealer_seat, sb/bb/ante, ... (22+) |
+| FOLD | SendPlayerFold | hand_id, seat_no |
+| CHECK/CALL | SendPlayerBet | hand_id, seat_no, amount |
+| BET/RAISE-TO | SendPlayerBet | hand_id, seat_no, amount |
+| ALL-IN | SendPlayerAllIn | hand_id, seat_no |
+| UNDO | UndoLastAction | hand_id |
+| MISS DEAL | AbortHand | hand_id, reason |
+| CHOP | ChopPot | hand_id, share_mode |
+| RUN IT (X2/X3) | SetRunItMultiple | hand_id, run_count |
+
+### 6.x 버튼 활성 전제
+
+서버 ActionOnResponse 수신 전 모든 액션 버튼 비활성 (회색).
+기존 HandFSM × biggest_bet × current_bet × stack 매트릭스에 AND 조건으로 추가.

+## 7. Straddle × BB Check Option 충돌 (W9 해소)
+
+- Straddle 없음: 기존 BB Check Option 규칙 유지
+- Straddle 있음: BB Check Option 비활성. Straddle 플레이어가 마지막 옵션 보유.
```

```diff
 # BS-05-00-overview.md

+## 7. BO 연결 상실 복구
+
+### 7.1 감지
+- 하트비트 30s / Pong timeout 10s / 3회 실패 시 상실
+
+### 7.2 핸드 미진행 (IDLE) 복구
+- 재연결 백오프 0ms → 5s → 10s × 100 → 중단
+- 재연결 성공: GET /tables/{id}/state → IDLE 복귀
+
+### 7.3 핸드 진행 중 복구
+- 경고 배너 "BO 연결 끊김 — 로컬 모드 (액션 X/20)"
+- 로컬 Event Sourcing 스택 (최대 20 이벤트)
+- 재연결 시: ReplayEvents { hand_id, events[] } → BO 응답에 따라 Accept/Partial/Reject
+- 20 이벤트 초과: 핸드 Reset 권고

+## 8. Table FSM vs HandFSM 경계
+
+Table FSM: EMPTY / CLOSED / SETUP / LIVE / PAUSED (BS-00 정의)
+HandFSM: IDLE → SETUP_HAND → PRE_FLOP → ... → COMPLETE (BS-06-01 정의)
+
+- PAUSED는 Table FSM. HandFSM 동결. 모든 버튼 비활성.
+- LIVE일 때만 HandFSM 활성.
```

## 영향 분석

### Team 2 (Backend)
- **영향**:
  - **프로토콜 이름 통일**: API-05에 `WriteGameInfo`, `SendPlayerFold`, `SendPlayerBet`, `SendPlayerAllIn`, `UndoLastAction`, `ActionOnResponse`, `ReplayEvents`, `AbortHand`, `ChopPot`, `SetRunItMultiple` 이벤트 스키마 추가 또는 기존 이벤트에 별칭 추가. Team 2가 별도 Cross-reference CCR 제출 필요.
  - **ReplayEvents 핸들러 구현**: BO에 `POST /ws/cc` 또는 WebSocket 메시지 `ReplayEvents` 핸들러 신설. 이벤트 순서 검증 + hand_id 일치 확인 + Accept/PartialAccept/Reject 응답 구현. 약 8시간.
  - **20 이벤트 버퍼 크기 적절성**: 실제 핸드당 평균 액션 수 측정 후 조정 권장 (10명 핸드에서 평균 30~60 액션). 본 CCR의 20 초기값은 **핸드 내 부분 복구** 관점 (최근 20개 액션만 복구, 그 이전은 Reset).
- **구현 영향**:
  - API-05 Cross-reference CCR 제출 및 승인 후 이벤트 스키마 수정: 3시간
  - ReplayEvents 핸들러: 8시간
  - 통합 테스트: 4시간
- **예상 총 시간**: 15시간

### Team 4 (self)
- **영향**:
  - BS-05-00 복구 섹션 구현: 로컬 Event Sourcing 스택 (`lib/features/command_center/services/local_event_store.dart`)
  - WebSocket 재연결 정책 구현 (`lib/features/command_center/services/bo_connector.dart`)
  - Sitting Out 적용 시점 로직 구현 (`lib/features/command_center/providers/seat_provider.dart`)
  - Straddle + BB Check Option 판단 로직 구현 (`lib/features/command_center/providers/action_button_provider.dart`)
  - RFID 자동 스트리트 전이 구현 (Engine 연동)
- **예상 작업 시간**: 
  - 로컬 Event Sourcing: 10시간
  - WebSocket 재연결: 4시간
  - Sitting Out/Straddle 로직: 5시간
  - RFID 자동 전이: 3시간
  - 총 약 22시간

### 마이그레이션
- 없음 (계약 명세 보강)

## 대안 검토

### 대안 A: 프로토콜 이름 미명시 (현행 유지)
- **장점**: API-05의 추상 이벤트만 유지, 계약 단순
- **단점**: 
  - WSOP 원본 코드 참조(`EBS UI Design Action Tracker.md`, PokerGFX 역설계)와 연결 끊김
  - 구현자가 WSOP 복사본의 프로토콜 이름을 BS-05에 없다는 이유로 무시하거나 자의적 이름 사용
- **채택**: ❌

### 대안 B: 프로토콜 이름 명시 + Cross-reference (본 제안)
- **내용**: BS-05-02에 프로토콜 이름 표 + 필드 요약 + API-05 참조
- **장점**:
  - BS-05는 운영자 관점, API-05는 전송 관점으로 역할 분리
  - WSOP 조직 용어 재사용
  - API-05는 단일 SSOT 유지
- **단점**: Team 2가 API-05 Cross-reference CCR 추가 제출 필요
- **채택**: ✅

### 대안 C: BS-05에 프로토콜 전문 정의
- **장점**: BS-05 자체 완결
- **단점**: 
  - API-05와 중복 → SSOT 위반
  - 프로토콜 변경 시 양쪽 동기화 비용
- **채택**: ❌

### 대안 D: BO 연결 상실 시 모든 액션 차단 (단순화)
- **장점**: 구현 단순 (로컬 Event Sourcing 불필요)
- **단점**: 
  - 방송 중 잠깐의 네트워크 끊김에도 운영자가 "카드를 받았는데 버튼이 눌리지 않는" 경험
  - 라이브 방송 지연 → 시청자 체감 사고
- **채택**: ❌ (본 CCR의 B 방향이 방송 안정성 우선)

## 검증 방법

### 1. 프로토콜 이름 일관성
- [ ] BS-05-02의 프로토콜 표가 API-05의 이벤트 카탈로그와 1:1 매핑되는지 확인
- [ ] Team 2가 제출한 API-05 Cross-reference CCR이 본 CCR의 표와 일치하는지 대조
- [ ] grep으로 `SendPlayerFold` 등의 이름이 코드베이스 어디에도 중복 정의되지 않는지 확인

### 2. BO 연결 상실 복구 시나리오
- **통합 테스트 시나리오**:
  1. CC → BO 연결 → HandFSM PRE_FLOP 진입
  2. BO 프로세스 강제 종료
  3. CC가 10초 이내 "BO 연결 끊김" 배너 표시 확인
  4. 운영자가 FOLD/CALL/BET 버튼 클릭 (로컬 스택에 기록됨)
  5. BO 프로세스 재시작
  6. CC가 자동 재연결 + ReplayEvents 전송
  7. BO가 모든 이벤트 Accept → 정상 동기화 확인
- **Edge case**:
  - 21번째 액션 시도 → "이벤트 버퍼 초과" 경고 확인
  - BO Reject 응답 → "핸드 Reset 필요" 다이얼로그 확인
  - 재연결 도중 또 다른 연결 끊김 → 백오프 초기화 확인

### 3. Table FSM PAUSED 동작
- Table FSM을 PAUSED로 전이 → 모든 액션 버튼 비활성 + "Table Paused" 배너 확인
- PAUSED → LIVE 복귀 → HandFSM 이전 상태 유지 확인

### 4. Sitting Out 적용 시점
- [ ] IDLE 상태에서 Sit Out 토글 → 다음 NEW HAND에서 즉시 제외 확인
- [ ] PRE_FLOP 진행 중 Sit Out 토글 → 현재 핸드는 참여 계속, 다음 핸드부터 제외 확인
- [ ] `player.status == sitting_out`이고 action_on이 해당 좌석이면 자동 `SendPlayerFold` 확인

### 5. Straddle + BB Check Option
- **시나리오 A (Straddle 없음)**: PRE_FLOP, biggest_bet == BB, action_on == BB_seat → CHECK 버튼 활성 확인
- **시나리오 B (Straddle 있음, 모두 Straddle CALL)**: action_on == Straddle_seat → CHECK 버튼 활성 확인
- **시나리오 C (Straddle 있음, BB 차례)**: BB Check Option 비활성 확인

### 6. RFID 자동 스트리트 전이
- Mock RFID로 보드 3장 감지 → Engine이 PRE_FLOP → FLOP 자동 전이 확인
- Run It 2 활성 상태에서 보드 3장 감지 → 자동 전이 차단, "Which board?" UI 표시 확인

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 2 기술 검토 (프로토콜 이름, ReplayEvents 핸들러, API-05 Cross-reference CCR 준비)
- [ ] Team 4 기술 검토 (로컬 Event Sourcing, 재연결 정책, Sitting Out/Straddle 로직)
