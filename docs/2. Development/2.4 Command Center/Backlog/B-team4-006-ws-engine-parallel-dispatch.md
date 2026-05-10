---
id: B-team4-006
title: WS + Engine HTTP 병행 dispatch 통합 구현 (Overview §1.1.1 준수)
status: PENDING
source: docs/2. Development/2.4 Command Center/Backlog.md
mirror: none
---

# [B-team4-006] WS + Engine HTTP 병행 dispatch 구현

- **등록일**: 2026-04-21
- **기획 SSOT**: `docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md §1.1.1` (2026-04-21 신설)
- **관련 기획**: `docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md §10.1 (정정)`
- **관련**: `docs/2. Development/2.3 Game Engine/APIs/Harness_REST_API.md`
- **Type 분류**: Type D (기획 있음 + 구현 체인 단절) — Type B/C 아님 (이번 기획 보강으로 해소)

## 배경

2026-04-21 사용자 `flutter run -d windows` 로그:
```
[NEW_HAND] WS offline — local handFsm.startHand() only
[ACTION] deal 요청됨  (이후 아무 이벤트 없음)
[ACTION] fold x3  (반응 없음)
```

Root cause: `_dispatchAction` 에서 `engineClient` 전혀 호출 안 함. `ws != null` 분기만 있어 WS offline 시 FSM 전이만 실행.

**기획 모순 해소** (2026-04-21): Overview §1.1 "BO→Engine 없음" vs WebSocket_Events §10.1 "BO→Engine 전달" 의 Type C 모순 해결 — **§1.1.1 신설로 CC=Orchestrator 확정** (Engine primary + BO secondary 병행).

## 구현 요구사항 (§1.1.1 체크리스트)

### P1 — Engine 세션 초기화

- [ ] NEW HAND 시 `engineClient.createSession(variant, seatCount, stacks, blinds, dealerSeat)` 호출
- [ ] 응답 `sessionId` 를 `engineSessionProvider.notifier.state` 에 저장
- [ ] 실패 시 debug log ERROR + StubEngine fallback (Engine_Dependency §4)

### P1 — Action 병행 dispatch

- [ ] 모든 action (FOLD/CHECK/CALL/BET/RAISE/ALL-IN) 에서 **병렬로 2 호출**:
  - `engineClient.sendFold/sendCheck/sendCall/sendBet/sendRaise/sendAllIn(sessionId, seatIndex, amount?)`
  - `ws.sendAction(handId, seat, actionType, amount?)` (기존)
- [ ] CC 는 `Future.wait` 로 두 응답 대기 — Engine 응답 필수, BO 응답 optional
- [ ] Engine 응답이 `ActionRejected` 이면 UI 롤백 + SnackBar 경고
- [ ] BO 응답 실패/timeout 은 debug log WARN (블로킹 안 함)

### P1 — Engine outputEvents 소비

- [ ] Engine 응답의 `outputEvents[]` 파싱하여 각 이벤트 dispatch:
  - `ActionPerformed` → seat.activity 갱신, pot 계산
  - `StreetAdvanced` → handFsm 전이
  - `CardDealt` (hole/community) → seats.holeCards 설정
  - `HandCompleted` → seats/pot/handFsm 초기화
- [ ] dispatcher 를 별도 provider 로 분리 (`lib/features/command_center/services/engine_output_dispatcher.dart` 신규)

### P2 — DEAL → holecards 공개 타이밍 + Manual Card fallback

> **2026-04-22 정정**: `Harness_REST_API.md §2.1 POST /api/session` 이 **auto HandStart + 홀카드 배분** 수행 (§1.1.1 Action-to-Transport Matrix). DEAL 은 Engine 호출 **skip** — 이미 createSession 시점에 PRE_FLOP + holecards 완료.

- [ ] DEAL action 에서 **Engine 호출 안 함** (createSession 응답에서 이미 holecards 수신)
- [ ] DEAL 버튼 클릭 → CC UI 가 seats.holeCards 를 시각 공개 (타이밍 마킹)
- [ ] BO 에만 `WriteDeal` audit 이벤트 전송 (§11)
- [ ] RFID Real 모드: 5초 미감지 시 `cardInputProvider.requestManualForSlot(seatIndex, slot)` 호출 (Mock 모드는 createSession 응답의 holecards 그대로 표시)
- [ ] FALLBACK 전이 시 `_maybeOpenFallbackModal` 기존 listener 작동

### P2 — correlation_id

- [ ] CC 에서 `Uuid().v4()` 생성 (action 당 1 UUID)
- [ ] Engine 요청: `X-Request-Id` header
- [ ] BO 요청: `message_id` field
- [ ] debug log 에 `correlation_id` 포함

### P3 — 실패 처리 매트릭스 (§1.1.1 표)

| 상황 | 기대 |
|------|------|
| Engine 200 + BO 200 | 정상 진행 |
| Engine 200 + BO 실패 | UI 진행, debug WARN |
| Engine 4xx | UI 롤백 + SnackBar |
| Engine 5xx/timeout | StubEngine fallback |
| 둘 다 실패 | Demo mode + offline indicator |

### P4 — debug log 확장

- [ ] 각 dispatch 지점에 `DebugLog.d('ENGINE_DISPATCH', ...)` + `DebugLog.d('BO_DISPATCH', ...)`
- [ ] 응답 수신 시 `DebugLog.i('ENGINE_RESPONSE', ...)` + `DebugLog.i('BO_ACK', ...)`
- [ ] 실패 시 `DebugLog.w/e` + correlation_id

## 완료 기준

- [ ] `flutter run -d windows` 로 Engine harness (`localhost:8080`) 기동 상태에서 NEW HAND → DEAL → FOLD 전체 시나리오 성공
- [ ] Engine 응답의 `outputEvents` 로 seat/pot/handFsm 상태 변화 UI 반영
- [ ] BO offline 상태에서도 Engine 응답만으로 게임 진행 (§1.1 "BO 장애 시 게임 진행" 준수)
- [ ] Engine offline (harness 미기동) 상태에서 StubEngine fallback + offline indicator
- [ ] dart analyze 0 errors
- [ ] 기존 테스트 영향 없음

## 참조

- 기획 SSOT: `Overview.md §1.1.1` (CC=Orchestrator 아키텍처)
- Engine HTTP: `Harness_REST_API.md §2.1-§2.3` (POST /api/session, /event)
- BO WS: `WebSocket_Events.md §10 (정정), §11 WriteDeal, §9 WriteGameInfo`
- StubEngine fallback: `Overlay/Engine_Dependency_Contract.md §4`
- Manual Card Input: `Command_Center_UI/Manual_Card_Input.md §6.4.1`
- 코드 진입점: `src/lib/features/command_center/screens/at_01_main_screen.dart :194 _dispatchAction`

## MEMORY 원칙

- `project_intent_spec_validation`: 기획이 진실 default — 이번 §1.1.1 확정 후 구현
- `feedback_prototype_failure_as_spec_signal`: 사용자 debug log 를 Type 분류 증거로 활용 (Type D 확정)
- `feedback_critic_discipline`: 구현 전 critic 6 반박 통과 (3 반영, 3 기각)
