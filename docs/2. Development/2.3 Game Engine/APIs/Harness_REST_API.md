---
title: Harness REST API
owner: team3
tier: contract
legacy-id: API-04.2
last-updated: 2026-04-22
reimplementability: PASS
reimplementability_checked: 2026-04-22
reimplementability_notes: "§2.1 response schema 실측 정렬 (notify: team3). 이전 {id, events, currentState, outputEvents} 4필드 분리 기술 → 실제 flat state snapshot (sessionId + 모든 state 필드 최상위)."
---
# Harness REST API 명세 (API-04.2)

## Edit History

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-16 | 초기 작성 | 12 endpoint 카탈로그 + 이벤트 타입 catalog |
| 2026-04-22 | §2.1 response schema 실측 정정 (notify: team3) | 이전 `{id, events, currentState, outputEvents}` 4 필드 → 실제 `{sessionId, variant, street, seats[], community[], pot, actionOn, dealerSeat, legalActions[], handNumber, ...flat state fields, eventCount, cursor, log[]}`. `outputEvents` 필드는 존재하지 않음 — CC 는 state-snapshot 을 받아 `dispatchState()` 로 provider 업데이트. team4 B-team4-006 E2E 검증 (2026-04-22 `curl` 실측) 후 정렬. |
| 2026-04-22 | §2.13 `/engine/health` endpoint 신설 (B-331, notify: team4) | Foundation §6.3 Demo Mode fallback 지원. team4 `engine_connection_provider` 3-stage probe 용. §1 목록 13번째 endpoint 추가. |
| 2026-04-22 | §개요 SSOT 선언 블록 신설 (B-332, notify: team4) | Foundation §6.3 §1.1.1 / §6.4 "Engine 응답이 게임 상태 SSOT. BO WS = audit 참고값" 을 API-04.2 계약 레벨에 명시. |

## 개요

Team 3 Game Engine 의 HTTP Harness 서비스(`bin/harness.dart`) 가 노출하는 REST API. 개발·테스트·통합 시나리오 재생·team4 CC 개발 보조 용도.

> **정본 구현**: `team3-engine/ebs_game_engine/lib/harness/server.dart` (`HarnessServer` 클래스)
>
> **기본 host/port**: `http://0.0.0.0:8080` (설정 가능)
>
> **CORS**: `Access-Control-Allow-Origin: *`, Methods `GET,POST,OPTIONS`, Headers `Content-Type` — 브라우저 기반 디버그 UI 허용.
>
> **용도**: 개발·통합 테스트 전용. 프로덕션 배포 시 인증/인가 레이어 래핑 필요 (현재 **미구현**, API-06 Auth_and_Session 과 별개).

### SSOT 선언 (B-332, Foundation §6.3 §1.1.1 / §6.4)

**Engine 응답은 게임 상태(hands / cards / pots / actionOn / legalActions) 의 최종 SSOT 이다.**

- CC 가 `POST /api/session/:id/event` (또는 GET) 으로 받은 응답 본문을 **즉시 자체 provider 에 반영**해야 한다 (`dispatchState()`).
- CC 는 Orchestrator 로서 BO / Engine 을 **병렬** 호출 (동일 `correlation_id`). BO 가 WS 로 재발행한 `ActionAck` 등은 **audit/모니터 참고값**이며 게임 상태 판정 근거가 아니다.
- BO WS 실패 시 **warn-only** — 게임 진행은 Engine 응답만으로 계속된다 (Foundation §6.3 시나리오 A/B 실패 매트릭스).
- 정본 근거: Foundation.md §6.3 §1.1.1 (병행 dispatch) · §6.4 (실시간 상태 동기화 §"Engine SSOT").

---

## 1. Endpoint 목록

| # | Method | Path | 설명 |
|---|--------|------|------|
| 1 | POST | `/api/session` | 신규 세션 생성 (auto HandStart + 홀카드 배분) |
| 2 | GET | `/api/session/:id` | 세션 상태 조회 (cursor 지원) |
| 3 | POST | `/api/session/:id/event` | 이벤트 추가 (모든 플레이어 액션·씬 전환) |
| 4 | POST | `/api/session/:id/undo` | 직전 이벤트 Undo |
| 5 | POST | `/api/session/:id/save` | 세션 → YAML 시나리오 저장 |
| 6 | GET | `/api/scenarios` | 저장된 시나리오 목록 |
| 7 | POST | `/api/scenarios/:name/load` | YAML 시나리오 → 새 세션 로드 |
| 8 | GET | `/api/session/:id/equity` | 몬테카를로 Equity (5000 iter) |
| 9 | GET | `/api/session/:id/validate` | RFID 카드 무결성 검증 |
| 10 | GET | `/api/session/:id/showdown-order` | Showdown 공개 순서 |
| 11 | GET | `/api/session/:id/runout-check` | 올인 runout 상태 |
| 12 | GET | `/api/variants` | 지원 variant 목록 |
| 13 | GET | `/engine/health` | Engine 헬스 프로브 (Demo Mode fallback, B-331) |

---

## 2. Endpoint 상세

### 2.1 POST /api/session — 세션 생성

**Request**
```json
{
  "variant": "nlh",
  "seatCount": 6,
  "stacks": [1000, 1000, 1000, 1500, 1000, 800],
  "blinds": { "sb": 5, "bb": 10 },
  "dealerSeat": 0,
  "seed": 42,
  "config": {
    "anteType": 0,
    "anteAmount": 0,
    "straddleEnabled": false,
    "bombPotEnabled": false,
    "canvasType": "broadcast",
    "sevenDeuceEnabled": false,
    "actionTimeoutMs": null
  }
}
```

| 필드 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `variant` | string | `nlh` | 게임 variant (`/api/variants` 참조) |
| `seatCount` | int | 6 | 좌석 수 |
| `stacks` | int[] or int | 1000 | 좌석별 칩 (단일 정수면 동일 스택) |
| `blinds` | object | `{sb:5, bb:10}` | `{sb,bb}` 또는 `{"1":5,"2":10}` (seat index 지정) |
| `dealerSeat` | int | 0 | 딜러 좌석 인덱스 |
| `seed` | int? | | 덱 셔플 시드 (결정론 테스트용) |
| `config` | object | `{}` | 옵션: straddle, bomb pot, 7-2, ante 등 |

**Response 201** (2026-04-22 실측 정정 — notify: team3, team4)

> **이전 기술(outdated)**: 응답이 `{id, events, currentState, outputEvents}` 4 필드로 분리되어 있다고 기술됐으나, 실제 Harness 구현 (`server.dart`) 은 **full state snapshot 을 flat** 하게 반환한다. 실측 확인 (`curl -s -X POST http://localhost:8080/api/session -d ...`) 후 본 스키마로 수정.

```json
{
  "sessionId": "mo9mksrrpj",
  "variant": "NL Hold'em",
  "street": "preflop",
  "seats": [
    {
      "index": 0,
      "label": "Seat 1",
      "stack": 1000,
      "currentBet": 0,
      "status": "active",
      "holeCards": ["3d", "2c"],
      "isDealer": true
    }
  ],
  "community": [],
  "pot": { "main": 15, "total": 15, "sides": [] },
  "actionOn": 0,
  "dealerSeat": 0,
  "legalActions": [
    {"type": "fold"},
    {"type": "call", "callAmount": 10},
    {"type": "raise", "minAmount": 20, "maxAmount": 1000}
  ],
  "handNumber": 0,
  "anteType": null,
  "anteAmount": null,
  "straddleEnabled": false,
  "straddleSeat": null,
  "bombPotEnabled": false,
  "bombPotAmount": null,
  "canvasType": "broadcast",
  "sevenDeuceEnabled": false,
  "sevenDeuceAmount": null,
  "runItTimes": null,
  "actionTimeoutMs": null,
  "isAllInRunout": false,
  "eventCount": 2,
  "cursor": 2,
  "log": [
    {"type": "HandStart", "description": "#0 HandStart dealer=0 blinds={1: 5, 2: 10}"},
    {"type": "DealHole", "description": "#1 DealHoleCards seats=[0, 1, 2]"}
  ]
}
```

**응답 필드 정의**:

| 필드 | 타입 | 설명 |
|------|------|------|
| `sessionId` | string | 세션 고유 ID |
| `variant` | string | 게임 variant display name (예: "NL Hold'em") |
| `street` | string | `preflop`/`flop`/`turn`/`river`/`showdown`/`complete` |
| `seats[]` | Seat[] | 좌석 배열 (seatCount 개). `holeCards` 는 실제 배분된 2장 카드. 각 seat 는 `index` 0-based |
| `community[]` | string[] | 커뮤니티 카드 (flop 후 3, turn 4, river 5) |
| `pot.total` | int | 총 pot. `main`+`sides` 합산 |
| `pot.sides[]` | SidePot[] | 올인 발생 시 side pot 배열 |
| `actionOn` | int | 현재 액션할 좌석 index (0-based). null 가능 (hand 종료) |
| `dealerSeat` | int | 딜러 좌석 index (0-based) |
| `legalActions[]` | LegalAction[] | 현재 actionOn 좌석의 허용 액션. 각 요소 `{type, callAmount?, minAmount?, maxAmount?}` |
| `handNumber` | int | 현재 핸드 번호 (0-based, 핸드 완료마다 증가) |
| `ante*`, `straddle*`, `bombPot*`, `sevenDeuce*`, `runItTimes`, `actionTimeoutMs` | 혼합 | config 옵션 반영 (request `config` field 참조) |
| `canvasType` | string | `broadcast`/`cash`/... — variant 별 canvas |
| `isAllInRunout` | bool | 올인 runout 진행 중 여부 |
| `eventCount` | int | 총 발생 이벤트 수 |
| `cursor` | int | replay cursor 현재 위치 |
| `log[]` | LogEntry[] | 이벤트 로그 (`{type, description}`). `type` 은 `HandStart`/`DealHole`/`Fold`/`Call`/`Raise` 등 내부 event type |

**참고 — 삭제된 필드** (이전 기술에 있었으나 실제 응답에는 **없음**):
- `id` → `sessionId` 로 변경됨
- `events` → `log` 로 변경됨 (형식도 다름)
- `currentState` → **중첩 object 아님**. 모든 state 필드가 최상위로 flat
- `outputEvents` → **Harness REST 에는 없음**. OutputEvent 는 CC 내부에서 `log`/state-diff 를 기반으로 합성 (`OutputEvent_Serialization.md §1` 참조)

> CC consumer 구현 (`team4-cc/src/lib/features/command_center/services/engine_output_dispatcher.dart`) 은 본 응답을 `dispatchState(state)` 로 받아 seats/pot/street/actionOn/dealerSeat 를 CC provider 에 반영한다. Overview.md §1.1.1 "Engine 응답이 gameState + outputEvents" 도 실제 구현이 state-snapshot 이라 본 문서 schema 에 정렬.

**Response 400** — 알 수 없는 variant
```json
{ "error": "Unknown variant: xxx" }
```

---

### 2.2 GET /api/session/:id — 상태 조회

**Query**: `?cursor=<int>` — 해당 이벤트 인덱스로 시점 되돌림 (replay).

**Response 200** — 동일 스키마 (§2.1 응답).
**Response 404** — `{ "error": "Session not found: :id" }`

---

### 2.3 POST /api/session/:id/event — 이벤트 추가

모든 플레이어 액션 + 씬 전환 + 특수 이벤트를 이 단일 endpoint 로 전달한다. `type` 필드로 분기.

**공통 Request**
```json
{ "type": "<event_type>", ...추가 필드 }
```

**지원 `type` 값과 페이로드**

| type | 추가 필드 | 설명 |
|------|-----------|------|
| `fold` | `seatIndex` | 폴드 |
| `check` | `seatIndex` | 체크 |
| `call` | `seatIndex`, `amount` | 콜 |
| `bet` | `seatIndex`, `amount` | 베팅 |
| `raise` | `seatIndex`, `amount` | 레이즈 |
| `allin` | `seatIndex`, `amount` | 올인 |
| `street_advance` | `next`: `flop`\|`turn`\|`river`\|`showdown`\|`runItMultiple` | 다음 스트리트 |
| `deal_community` | `cards`: `string[]` (예: `["As","Kh","7c"]`) | 커뮤니티 카드 딜 |
| `deal_hole` | `cards`: `{ "0": ["As","Kh"], "3": [...] }` | 홀카드 딜 (Map seat→cards) |
| `pot_awarded` | `awards`: `{ "0": 500, "5": 120 }` | 팟 수여 (Map seat→amount) |
| `hand_end` | — | 핸드 종료 |
| `misdeal` | — | 미스딜 선언 |
| `bomb_pot_config` | `amount` | Bomb Pot 세팅 |
| `run_it_choice` | `times`: int | Run It Twice/Thrice 선택 |
| `manual_next_hand` | — | 수동 다음 핸드 |
| `timeout_fold` | `seatIndex` | 타임아웃으로 강제 폴드 |
| `muck` | `seatIndex`, `showCards`: bool | 머크 결정 |
| `pineapple_discard` | `seatIndex`, `card`: string | Pineapple 변형 카드 버림 |

**Response 200** — 갱신된 세션 상태 (§2.1 응답).
**Response 400** — `{ "error": "Unknown event type: <type>" }` 또는 입력 오류.

---

### 2.4 POST /api/session/:id/undo — Undo

Body 없음. 직전 이벤트 1건 되돌림.

**Response 200** — 갱신된 세션 상태.

---

### 2.5 POST /api/session/:id/save — 시나리오 저장

Body 없음. `scenarios/<session_id>.yaml` 에 저장.

**Response 200**
```json
{ "saved": "scenarios/k9f2a....yaml" }
```

---

### 2.6 GET /api/scenarios — 시나리오 목록

**Response 200**
```json
{ "scenarios": ["hand-01", "hand-02", ...] }
```

---

### 2.7 POST /api/scenarios/:name/load — 시나리오 로드

Body 없음. `scenarios/<name>.yaml` 파일에서 새 세션 생성 후 시나리오 이벤트 전부 replay.

**Response 201** — 세션 상태 (§2.1).
**Response 404** — 시나리오 파일 없음.
**Response 400** — 알 수 없는 variant (YAML 파싱 후 판단).

---

### 2.8 GET /api/session/:id/equity — 승률 계산

몬테카를로 시뮬레이션 (5000 iterations).

**Response 200**
```json
{ "equity": { "0": 0.68, "3": 0.21, "5": 0.11 } }
```

2명 미만이면 `{ "equity": {} }`.

---

### 2.9 GET /api/session/:id/validate — 카드 무결성

RFID 덱 중복·누락 검증 (`Engine.validateCards()`).

**Response 200**
```json
{ "valid": true, "issues": [] }
```

또는
```json
{
  "valid": false,
  "issues": ["Duplicate card: As (seat 0 and community)", ...]
}
```

---

### 2.10 GET /api/session/:id/showdown-order — Showdown 순서

**Response 200**
```json
{ "revealOrder": [3, 5, 0] }
```

0-based seat index 순서 (WSOP Rule 71 last-aggressor 우선).

---

### 2.11 GET /api/session/:id/runout-check — All-in Runout

**Response 200**
```json
{ "isAllInRunout": true }
```

---

### 2.12 GET /api/variants — Variant 목록

**Response 200**
```json
{ "variants": ["nlh", "plh", "flh", "plo", "plo5", "short_deck", ...] }
```

---

### 2.13 GET /engine/health — Engine 헬스 프로브 (B-331)

Foundation §6.3 Demo Mode fallback 을 지원하는 헬스 체크. team4 CC `engine_connection_provider` 가 3-stage 상태 머신 (확인 → 재시도 → fallback) 에서 호출.

**Query / Body**: 없음.

**Response 200**
```json
{
  "status": "ok",
  "version": "0.1.0",
  "uptime_seconds": 1234,
  "sessions_active": 3,
  "timestamp": "2026-04-22T18:45:23.123Z"
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `status` | string | `ok` (정상). 향후 `degraded` 값 확장 여지 (scenario load 실패 등) |
| `version` | string | Engine harness 버전. 정본: `lib/harness/server.dart` 의 `engineHarnessVersion` 상수 (pubspec.yaml 과 sync) |
| `uptime_seconds` | int | 프로세스 기동 후 경과 초. `start()` 호출 시점 기준 |
| `sessions_active` | int | 현재 in-memory session 개수 (`_sessions.length`) |
| `timestamp` | ISO-8601 string | 서버 현재 시각 (UTC) |

**CORS**: `/api/*` 와 동일 (`Access-Control-Allow-Origin: *`). 브라우저 기반 디버그 UI 접근 가능.

**Idempotent**: GET 이며 side-effect 없음. 반복 호출 안전.

**사용 예시 (team4)**:
```dart
// team4-cc/lib/features/command_center/providers/engine_connection_provider.dart
final response = await http.get(Uri.parse('$engineUrl/engine/health'));
if (response.statusCode == 200) {
  final body = jsonDecode(response.body) as Map<String, dynamic>;
  return EngineState.healthy(version: body['version'] as String);
}
```

---

## 3. 공통 응답 규칙

| 상태 | 의미 |
|------|------|
| 200 | OK |
| 201 | Created (세션·시나리오 로드) |
| 204 | No Content (CORS preflight) |
| 400 | Bad Request (입력 오류, 알 수 없는 variant/event type) |
| 404 | Not Found (세션·시나리오) |
| 500 | Internal Server Error (예외) |

모든 에러는 `{ "error": "<message>" }` 형식.

---

## 4. Session JSON 구조 (참조용)

`Session.toJson()` 는 다음을 포함:

```json
{
  "id": "k9f2a...",
  "variant": "nlh",
  "events": [ { "type": "HandStart", ... }, ... ],
  "currentState": {
    "seats": [ ... ],
    "community": [ "As", "Kh", "7c" ],
    "pots": [ 450, 120 ],
    "dealerSeat": 0,
    ...
  },
  "outputEvents": [
    { "type": "StateChanged", "oeCode": "OE-01", ... },
    ...
  ]
}
```

`outputEvents` 스키마는 `OutputEvent_Serialization.md §1` 참조.

---

## 5. 사용 흐름 예시 (team4 연동)

```
POST /api/session                       → 세션 생성
POST /api/session/:id/event (bet 20)    → 베팅
POST /api/session/:id/event (call 20)   → 콜
POST /api/session/:id/event (street_advance flop)
POST /api/session/:id/event (deal_community ["As","Kh","7c"])
GET  /api/session/:id/equity            → 승률
GET  /api/session/:id                   → 최종 상태 + outputEvents[]
```

각 응답의 `outputEvents` 배열을 team4 OutputEventBuffer 에 enqueue → Security Delay 적용 → Overlay 렌더.

---

## 6. 미구현·제약

- **인증/인가**: 없음. 프로덕션 사용 전 reverse proxy + token 추가 필수.
- **WebSocket 푸시**: 현재 REST pull 기반. OutputEvent 스트리밍은 향후 `API-05 WebSocket_Events` 와 정렬 필요.
- **Rate limiting**: 없음.
- **Multi-tenant**: 세션은 프로세스 메모리 내 Map. 재시작 시 손실 (save/load 로 우회). → B-338 에서 persistence 구현 예정.
- **Health degraded 상태**: 현재 `status` 는 `ok` 고정. scenario load 실패·LRU eviction 등 degraded 조건은 후속 작업.

---

## 7. 연관 문서

- `Overlay_Output_Events.md` (API-04) — Overlay 계약 상위
- `OutputEvent_Serialization.md` (API-04.1) — outputEvents 스키마
- `OutputEventBuffer_Boundary.md` (API-04.3) — team4 소비 경계
- 정본 구현: `team3-engine/ebs_game_engine/lib/harness/server.dart`
