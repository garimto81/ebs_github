---
title: Multi-Hand State — Button rotate + handNumber 증가 (Cycle 5 v02)
owner: team3 (S8 Cycle 5)
tier: contract
legacy-id: API-04.5
last-updated: 2026-05-12
last-synced: 2026-05-12
reimplementability: PASS
reimplementability_checked: 2026-05-12
reimplementability_notes: "rotation 규칙 표 + heads-up 분기 + sitting-out skip + 코드 file:line + test 11 + harness test 4 모두 PASS"
related-issue: 287
related-cycle: 5
related-spec: ../Behavioral_Specs/Holdem/
---

# Multi-Hand State — Button rotate + handNumber 증가

## 개요

연속된 hand 간 dealer button + SB/BB 회전과 handNumber 누적을 Engine 이 자율 처리한다. Cycle 4 v01 의 1-hand 종료 후 hand 2 진입 (`POST /api/session/{id}/next-hand`) 으로 multi-hand 시나리오를 지원한다.

> **목적**: 1-hand harness 통과(`cascade:engine-hand-ready`, Cycle 2 seq 28) 의 multi-hand 확장. S9 #285 v02 e2e 시나리오 의존성 해소.
>
> **연관 Issue**: [#287](https://github.com/garimto81/ebs_github/issues/287) S8 Cycle 5 Path C 보조.

---

## 1. ManualNextHand 이벤트 동작 규칙

```
[hand_end 이후 state] --(ManualNextHand)--> [hand+1 idle state]
```

### 1.1 입력 / 출력 계약

| 항목 | 입력 (pre) | 출력 (post) |
|------|-----------|-------------|
| `handNumber` | n | n + 1 |
| `dealerSeat` | d | rotate to next non-sittingOut seat after d |
| `sbSeat` | (이전 hand SB) | rotate per 1.2 규칙 |
| `bbSeat` | (이전 hand BB) | rotate per 1.2 규칙 |
| `street` | any | `Street.idle` |
| `community` | any | `[]` |
| `pot.main` / `pot.sides` | any | 0 / `[]` |
| `handInProgress` | any | `false` |
| `bombPotEnabled` | any | `false` |
| `seat.holeCards` (all) | any | `[]` |
| `seat.currentBet` (all) | any | 0 |
| `seat.antePosted` (all) | any | 0 |
| `seat.isDealer` (per seat) | any | `seat.index == nextDealer` |
| `seat.status` (folded only) | `folded` | `active` |

### 1.2 SB/BB 산출 알고리즘

3+ active seats 와 heads-up(2 active seats) 을 분기:

| 활성 seat 수 | SB | BB | 비고 |
|:------------:|----|----|------|
| ≥ 3 | (new dealer + 1) 후 첫 non-sittingOut seat | (new dealer + 1) 후 두번째 non-sittingOut seat | 표준 hold'em |
| 2 (heads-up) | new dealer 본인 | dealer 이외 1명 active seat | dealer = SB 룰 |
| 1 | (변경 없음, 기존 SB/BB 유지) | (변경 없음) | hand 시작 불가 |

> **WHY heads-up dealer=SB**: 표준 hold'em 규칙. `lib/engine.dart::_startHandFull` line 159-167 의 hand 시작 분기와 일치. 본 문서가 SSOT — issue body 의 "button=BB" 문구는 dead-button 룰 ([Behavioral_Specs/Holdem/dead_button_test.dart] 참조) 과 혼동된 오기.

### 1.3 sitting-out skip 규칙

dealer rotation 은 sittingOut seat 을 건너뛴다 (`_endHandFull` 의 기존 패턴 재사용):

```
nextDealer = dealerSeat
for i in 1..n:
  idx = (dealerSeat + i) mod n
  if seats[idx].status != sittingOut:
    nextDealer = idx
    break
```

SB/BB 산출 시에도 sittingOut seat 은 active list 에서 제외된다.

### 1.4 OutputEvent

`ManualNextHand` 처리 후 emit:

| Event | Payload | 비고 |
|-------|---------|------|
| `StateChanged` | `fromState=<prev street>`, `toState=idle` | 기존 동작 보존 |

> **참조**: `lib/core/actions/output_event.dart`, `Overlay_Output_Events.md` §6.0

---

## 2. POST /api/session/:id/next-hand endpoint

### 2.1 계약

| 항목 | 값 |
|------|-----|
| Method | POST |
| Path | `/api/session/{sessionId}/next-hand` |
| Request body | (없음) |
| Response 200 | `Session.toJson()` (post-rotation 상태) |
| Response 404 | `{"error": "Session not found: {id}"}` |

### 2.2 사용 예시

```http
POST http://localhost:18080/api/session/mp21ivpi35/next-hand

→ 200 OK
{
  "sessionId": "mp21ivpi35",
  "handNumber": 2,
  "dealerSeat": 1,
  "street": "idle",
  "seats": [
    {"index":0,"isDealer":false,"status":"active",...},
    {"index":1,"isDealer":true,"status":"active",...},
    ...
  ],
  "pot": {"main":0,"total":0,"sides":[]}
}
```

### 2.3 POST /api/session/:id/event (type=manual_next_hand) 와의 관계

`POST /next-hand` 는 `POST /event {"type":"manual_next_hand"}` 의 편의 wrapper. 내부적으로 동일한 `ManualNextHand` event 를 dispatch 한다. v01 시나리오 호환성 보존.

| 경로 | 용도 |
|------|------|
| `POST /event {"type":"manual_next_hand"}` | scenario file (`.http`) 작성 시 일관성 유지용 |
| `POST /next-hand` | CC / Lobby / e2e 시나리오의 직관적 호출용 |

---

## 3. round-robin / heads-up 검증 시나리오

### 3.1 6-seat round-robin

```
hand 1: dealer=0  SB=1  BB=2
  ↓ POST /next-hand
hand 2: dealer=1  SB=2  BB=3
  ↓ POST /next-hand
hand 3: dealer=2  SB=3  BB=4
  ↓ POST /next-hand
hand 4: dealer=3  SB=4  BB=5
  ↓ POST /next-hand
hand 5: dealer=4  SB=5  BB=0
  ↓ POST /next-hand
hand 6: dealer=5  SB=0  BB=1
  ↓ POST /next-hand
hand 7: dealer=0  ← 원위치 복귀 ★
```

### 3.2 heads-up toggle

```
hand 1: dealer=0 (=SB)  BB=1
  ↓ POST /next-hand
hand 2: dealer=1 (=SB)  BB=0
```

### 3.3 sitting-out skip

```
seats: [0=active, 1=sittingOut, 2=active, 3=active]
hand 1: dealer=0  SB=2  BB=3
  ↓ POST /next-hand
hand 2: dealer=2  (seat 1 건너뛰기)  SB=3  BB=0
```

---

## 4. 검증 (Cycle 5)

| 항목 | 결과 | 위치 |
|------|:----:|------|
| `dart test test/multi_hand_state_test.dart` (11 cases) | ✅ ALL PASS | `team3-engine/ebs_game_engine/test/multi_hand_state_test.dart` |
| `dart test test/harness/next_hand_endpoint_test.dart` (4 cases) | ✅ ALL PASS | `team3-engine/ebs_game_engine/test/harness/next_hand_endpoint_test.dart` |
| Full regression (`dart test`) | ✅ 740 PASS / 1 skip / 0 fail | — |
| `dart analyze lib/engine.dart lib/harness/server.dart …` | ✅ No issues found | — |

> **재실행 명령**:
> ```bash
> cd team3-engine/ebs_game_engine
> dart test test/multi_hand_state_test.dart
> dart test test/harness/next_hand_endpoint_test.dart
> ```

---

## 5. 코드 위치 (file:line SSOT)

| 책임 | 코드 위치 |
|------|----------|
| `ManualNextHand` event class | `team3-engine/ebs_game_engine/lib/core/actions/event.dart:65-67` |
| `_handleManualNextHandFull` reducer (rotation 로직) | `team3-engine/ebs_game_engine/lib/engine.dart:751-849` |
| event 라우팅 (`case ManualNextHand`) | `team3-engine/ebs_game_engine/lib/engine.dart:86` |
| HTTP 라우트 (`POST /next-hand`) | `team3-engine/ebs_game_engine/lib/harness/server.dart:113-122` |
| HTTP 핸들러 (`_nextHand`) | `team3-engine/ebs_game_engine/lib/harness/server.dart` |
| `manual_next_hand` event 타입 라우팅 (기존) | `team3-engine/ebs_game_engine/lib/harness/server.dart:389-390` |

---

## 6. 미해결 (Cycle 5 이후 후속)

| 항목 | 우선순위 | 비고 |
|------|:--------:|------|
| `handHistory[]` 누적 (이전 hand 결과 보존) | MEDIUM | Session.events 가 이미 모든 event 보존. 별도 압축 history 필요 시 추가 설계 |
| Engine 자동 hand_end → next-hand 전환 (single-active-seat 감지) | LOW | 현재는 operator 수동 호출. auto-finish 룰은 별도 issue 필요 |
| Blind level 자동 증가 | LOW | 현재 `bbAmount` 는 hand 간 변경 없음. tournament 모드는 별도 spec 필요 |

---

## 7. Changelog

| 날짜 | 버전 | 변경 내용 | 변경 유형 | 결정 근거 |
|------|------|-----------|----------|----------|
| 2026-05-12 | v1.0 | 최초 작성 (issue #287 Path C) | - | Cycle 5 v02 multi-hand e2e 의존성 해소 |
