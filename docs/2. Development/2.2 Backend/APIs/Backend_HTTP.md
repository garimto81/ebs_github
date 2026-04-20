---
title: Backend HTTP
owner: team2
tier: internal
legacy-id: API-01
last-updated: 2026-04-15
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "API-01 REST 카탈로그 + WSOP LIVE 연동 (53KB). TBD 3건은 프로덕션 호스트/WSOP API 인증 등 외부 계약"
---
# API-01 Backend API — BO REST API + WSOP LIVE Integration

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | FastAPI 백엔드 REST API 전체 엔드포인트 카탈로그 |
| 2026-04-08 | 신규 작성 | WSOP LIVE Staff Page API 연동 방식, 데이터 매핑, 충돌 해결, Mock 모드 |
| 2026-04-09 | Skin API 추가 | skin CRUD + upload/download/activate/duplicate 9개 엔드포인트 |
| 2026-04-10 | CCR-003 | 모든 mutation API에 `Idempotency-Key` 헤더 표준 도입 + 멱등성 응답 계약 |
| 2026-04-10 | CCR-010 | `POST /tables/rebalance` 응답에 saga 구조(`saga_id`, `steps`, 207/500) 추가 |
| 2026-04-10 | CCR-015 | `GET /tables/{table_id}/events` replay 엔드포인트 신설 (WebSocket seq gap 복구) |
| 2026-04-13 | can_undo 필드 | 이벤트 replay 응답에 `can_undo: bool` 추가 (WSOP EventFlightHistoryInfo.canUndo 대응) |
| 2026-04-13 | PlayerWaitingStatus | Waiting List enum 7값 추가 (WSOP PlayerWaitingStatus 준거) |
| 2026-04-13 | WSOP LIVE 정합성 수정 | isRegisterable 플래그 도입, 표시 상태 매핑 (Restricted/Late Reg) 추가, Announce→Announced |
| 2026-04-14 | WSOP 대조 | 8건 WSOP LIVE Confluence 원본 대조 — enum int값, divergence 근거, 필드 매핑표 추가 |
| 2026-04-14 | CCR-043 | §8.1 PayoutStructure/Staff 동기화 대상 추가, §9.7 wsop_id 매핑 전략(신규 엔티티), §13.1 GGPass S2S 인증, §14 Phase별 통합 전략, §15 sync_conflicts 감사 테이블 |
| 2026-04-14 | 문서 통합 | API-02 WSOP LIVE Integration을 Part II로 흡수. §5.16 sync 엔드포인트 중복 해소 |
| 2026-04-20 | SG-008 a분류 편입 | §5.17 CRUD 완결성 편입 신설 — D3(code-only) 77건 리소스별 테이블로 일괄 편입 (Users/Competitions/Series/Events/Flights/Tables/Players/Hands/BlindStructures/PayoutStructures/Skins/Decks/Configs/Reports/Settings) |

---

## 개요

이 문서는 EBS Back Office(BO) FastAPI 서버의 **REST API 전체 엔드포인트 카탈로그**(Part I)와 **WSOP LIVE Staff Page API와의 연동 계약**(Part II)을 통합 정의한다. Lobby(웹)와 CC(Flutter)는 Part I의 REST API를 통해 BO DB와 데이터를 주고받으며, WSOP LIVE는 대회 계층(Series/Event/Flight)과 플레이어/블라인드 데이터의 원천으로서 Part II의 폴링 프로토콜에 따라 BO DB에 캐싱된다.

> **참조**: 인증 API 상세는 `API-06-auth-session.md`, WebSocket 이벤트는 `API-05-websocket-events.md`, 엔티티 필드 정의는 `DATA-04-db-schema.md`

### 설계 원칙 (Part I — REST API)

| 원칙 | 설명 |
|------|------|
| **RESTful** | 리소스 중심 URL, HTTP 메서드로 CRUD 매핑 |
| **JSON** | Request/Response 모두 `application/json` |
| **JWT 인증** | 모든 요청에 `Authorization: Bearer {token}` 헤더 필수 (인증 API 제외) |
| **RBAC** | 역할(Admin/Operator/Viewer)에 따라 접근 제한 |
| **일관된 응답** | 모든 응답은 공통 포맷 준수 |

### 설계 원칙 (Part II — WSOP LIVE Integration)

| 원칙 | 설명 |
|------|------|
| **폴링 기반** | WSOP LIVE가 Push(Webhook)를 지원하지 않는다고 가정. BO가 주기적으로 Pull |
| **캐싱 우선** | WSOP LIVE 데이터를 BO DB에 캐싱. 클라이언트는 항상 BO DB를 읽음 |
| **source 필드** | 모든 엔티티에 `source` 필드로 데이터 출처 구분 (`api` / `manual`) |
| **독립 운영** | API 연동 실패 시에도 수동 입력으로 EBS 단독 운영 가능 |

> **참조**: Lobby CRUD 요구사항은 `BS-02-lobby.md`, BO 전체 범위는 `BO-01-overview.md`

---

## Part I — REST API Catalog

## 1. Base URL

```
http://{bo_host}:{bo_port}/api/v1
```

| 환경 | Host | Port |
|------|------|:----:|
| 개발 | `localhost` | 8000 |
| 테스트 | `192.168.x.x` | 8000 |
| 프로덕션 | TBD | 443 (HTTPS) |

### 1.1 경로 표기 규약 (2026-04-20 SG-008 정렬)

본 문서의 엔드포인트 예시(`POST /users`, `GET /tables/{id}` 등)는 모두 **Base URL 기준 상대 경로**이다. 실제 요청 시에는 `/api/v1` prefix 를 붙여야 한다:

| 예시 표기 | 실제 요청 |
|-----------|-----------|
| `POST /users` | `POST /api/v1/users` |
| `GET /flights/{id}/clock` | `GET /api/v1/flights/{id}/clock` |
| `POST /tables/rebalance` | `POST /api/v1/tables/rebalance` |

**예외**: `/auth/*` 엔드포인트는 Base URL `/api/v1` 과 **무관**하게 루트 경로에서 제공된다 (`POST /auth/login` = `POST /auth/login`). 상세: `Auth_and_Session.md`.

> 이 규약을 따르지 않는 endpoint 발견 시 `tools/spec_drift_check.py --api` 에서 D1 으로 감지된다.

---

## 2. 공통 요청 헤더

| 헤더 | 값 | 필수 | 비고 |
|------|------|:----:|------|
| `Content-Type` | `application/json` | O | POST/PUT 요청 |
| `Authorization` | `Bearer {access_token}` | O | 인증 API 제외 |
| `Accept` | `application/json` | — | 기본값 |
| `Idempotency-Key` | UUIDv4 또는 ULID | 조건부 | mutation(POST/PUT/PATCH/DELETE) 권장. 클라이언트 생성, 24h 유지. (CCR-003) |
| `X-Request-ID` | UUIDv4 | 선택 | 분산 추적용 correlation ID. 서버 로그·응답 헤더에 echo. (CCR-003) |

---

## 3. 공통 응답 포맷

### 성공 응답

```json
{
  "data": { ... },
  "error": null,
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 150
  }
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `data` | object / array | 응답 데이터. 단건: object, 목록: array |
| `error` | null | 성공 시 항상 null |
| `meta` | object | 목록 조회 시 페이지네이션 정보. 단건 조회 시 생략 |

### 에러 응답

```json
{
  "data": null,
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Table with id 99 not found"
  }
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `error.code` | string | 머신 판독용 에러 코드 (UPPER_SNAKE_CASE) |
| `error.message` | string | 사람 판독용 에러 메시지 |

### 공통 에러 코드

| 코드 | HTTP | 설명 |
|------|:----:|------|
| `VALIDATION_ERROR` | 422 | 요청 데이터 유효성 실패 |
| `RESOURCE_NOT_FOUND` | 404 | 리소스 없음 |
| `RESOURCE_CONFLICT` | 409 | 중복 또는 상태 충돌 |
| `AUTH_UNAUTHORIZED` | 401 | 인증 실패 |
| `AUTH_FORBIDDEN` | 403 | 권한 부족 |
| `IDEMPOTENCY_KEY_REUSED` | 409 | 동일 `Idempotency-Key`로 상이한 바디 재요청 (CCR-003) |
| `INTERNAL_ERROR` | 500 | 서버 내부 오류 |

### 멱등성 동작 (CCR-003)

`Idempotency-Key` 헤더가 동반된 mutation 요청은 다음 규칙을 따른다.

| 상황 | 동작 |
|------|------|
| **최초 요청** | 정상 처리 + 응답 캐싱 (키당 24h TTL, `idempotency_keys` 테이블에 저장) |
| **동일 키 + 동일 바디 재요청** | 캐시된 응답 재생 (status/body 동일), 응답 헤더에 `Idempotent-Replayed: true` 추가 |
| **동일 키 + 상이한 바디 재요청** | `409 Conflict` + `IDEMPOTENCY_KEY_REUSED` 에러 |
| **키 누락 (mutation)** | 정상 처리되지만 재시도 안전성 보장 없음. 4xx 아님. |

**409 Conflict (Idempotency) 응답 예시:**

```json
{
  "data": null,
  "error": {
    "code": "IDEMPOTENCY_KEY_REUSED",
    "message": "Key 'abc-123' already used with different payload",
    "original_hash": "sha256:...",
    "original_created_at": "2026-04-10T12:34:56Z"
  }
}
```

**저장소**: `idempotency_keys` 테이블 (DATA-04 §4 / CCR-001). Phase 3+는 Redis 캐시 추가.
**범위**: `(user_id, key)` 단위로 격리 — 사용자당 키 공간 독립.
**대상 엔드포인트**: 모든 POST/PUT/PATCH/DELETE 엔드포인트 (5.x 카탈로그 전체).

---

## 4. 페이지네이션

목록 조회 API는 쿼리 파라미터로 페이지네이션을 지원한다.

| 파라미터 | 타입 | 기본값 | 설명 |
|---------|:----:|:-----:|------|
| `page` | int | 1 | 페이지 번호 (1-based) |
| `limit` | int | 20 | 페이지당 항목 수 (최대 100) |

---

## 5. 엔드포인트 카탈로그

### 5.1 Auth — 인증

> Auth API 전체 카탈로그(login, refresh, session, 2FA, password reset 등)·요청/응답 스키마·정책: `API-06-auth-session.md`. WSOP LIVE 비교(Google OAuth + 3-role RBAC + 2FA 독자 설계 등)도 API-06 §WSOP 비교 섹션 참조.

### 5.2 Users — 사용자 관리

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| GET | `/users` | 사용자 목록 | Admin |
| GET | `/users/:id` | 사용자 상세 | Admin |
| POST | `/users` | 사용자 생성 | Admin |
| PUT | `/users/:id` | 사용자 수정 | Admin |
| DELETE | `/users/:id` | 사용자 삭제 | Admin |

**POST /users — Request:**

```json
{
  "email": "operator@ebs.local",
  "password": "********",
  "display_name": "Operator 1",
  "role": "operator"
}
```

**Response (201 Created):**

```json
{
  "data": {
    "user_id": 2,
    "email": "operator@ebs.local",
    "display_name": "Operator 1",
    "role": "operator",
    "is_active": true,
    "created_at": "2026-04-08T10:00:00Z"
  },
  "error": null
}
```

### 5.3 Competitions — 대회 브랜드

> **WSOP 원본과 다름**: WSOP LIVE에는 `Competition`이 독립 CRUD 엔티티가 아닌 `CompetitionType` enum(WSOP=0, WSOPC=1, APL=2, APT=3, WSOPP=4)과 `CompetitionTag` enum으로만 존재. EBS는 이를 독립 엔티티로 확장.

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| GET | `/competitions` | 대회 목록 | 인증 사용자 |
| GET | `/competitions/:id` | 대회 상세 | 인증 사용자 |
| POST | `/competitions` | 대회 생성 | Admin |
| PUT | `/competitions/:id` | 대회 수정 | Admin |
| DELETE | `/competitions/:id` | 대회 삭제 | Admin |

### 5.4 Series — 시리즈

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| GET | `/series` | 시리즈 목록 | 인증 사용자 |
| GET | `/series/:id` | 시리즈 상세 | 인증 사용자 |
| POST | `/series` | 시리즈 생성 | Admin |
| PUT | `/series/:id` | 시리즈 수정 | Admin |
| DELETE | `/series/:id` | 시리즈 삭제 | Admin |

**POST /series — Request:**

```json
{
  "competition_id": 1,
  "series_name": "2026 WSOP",
  "year": 2026,
  "begin_at": "2026-05-27",
  "end_at": "2026-07-17",
  "time_zone": "America/Los_Angeles",
  "currency": "USD"
}
```

### 5.5 Events — 이벤트

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| GET | `/events` | 이벤트 목록 (시리즈 필터: `?series_id=`) | 인증 사용자 |
| GET | `/events/:id` | 이벤트 상세 | 인증 사용자 |
| POST | `/events` | 이벤트 생성 | Admin |
| PUT | `/events/:id` | 이벤트 수정 | Admin |
| DELETE | `/events/:id` | 이벤트 삭제 | Admin |
| GET | `/events/:id/flights` | 이벤트의 Flight 목록 | 인증 사용자 |

**POST /events — Request:**

```json
{
  "series_id": 1,
  "event_no": 1,
  "event_name": "$10,000 NL Hold'em Championship",
  "buy_in": 10000,
  "game_type": 0,
  "bet_structure": 0,
  "game_mode": "single",
  "table_size": 9,
  "start_time": "2026-05-28T12:00:00Z"
}
```

**game_type — WSOP `EventGameType` 준거** (Confluence page 1960411325):

| int | 이름 | 설명 |
|:---:|------|------|
| 0 | Holdem | No Limit / Limit Hold'em |
| 1 | Omaha | Pot Limit / Limit Omaha |
| 2 | Stud | Seven Card Stud |
| 3 | Razz | Razz |
| 4 | Lowball | 2-7 Lowball |
| 5 | HORSE | HORSE |
| 6 | DealerChoice | Dealer's Choice |
| 7 | Mixed | Mixed Game |
| 8 | Badugi | Badugi |

### 5.6 Flights — Flight

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| GET | `/flights` | Flight 목록 (이벤트 필터: `?event_id=`) | 인증 사용자 |
| GET | `/flights/:id` | Flight 상세 | 인증 사용자 |
| POST | `/flights` | Flight 생성 | Admin |
| PUT | `/flights/:id` | Flight 수정 | Admin |
| PUT | `/flights/:id/complete` | EventFlight 완료 (Running → Completed) (CCR-050) | Admin |
| PUT | `/flights/:id/cancel` | EventFlight 취소 ({Created,Announce,Registering,Running} → Canceled) (CCR-050) | Admin |
| DELETE | `/flights/:id` | Flight 영구 제거 | Admin |

**PUT /flights/:id/complete — Request:**

```json
{ "final_results": { "total_entries": 342, "prize_pool": 171000, "winner_player_id": 55 } }
```

> 전이 외 상태 호출 시 `409`. `tournament_status_changed` WebSocket 이벤트 발행 (API-05 §4.2.6).

**PUT /flights/:id/cancel — Request:**

```json
{ "reason": "venue closure", "refund_policy": "full" }
```

> Completed 상태 호출 시 `409`. 활성 CC 세션 종료 브로드캐스트 동반.

**Flight status**: `EventFlightStatus` enum (BS-00-definitions §3.6, WSOP LIVE Confluence Page 1960411325 준거).

#### 5.6.1 Clock — Tournament Timer

> **WSOP LIVE 대응**: `PUT/POST /Series/{seriesId}/EventFlights/{eventFlightId}/Clock/*` (SSOT Page 1651343762, 3728441546).
> **ClockFSM**: BS-00-definitions §3.7. **BlindDetailType**: BS-00-definitions §3.8.
> **WebSocket 이벤트**: clock_tick / clock_level_changed / clock_detail_changed / clock_reload_requested / stack_adjusted (API-05 §4.2).

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| GET | `/flights/:id/clock` | Clock 현재 상태 (ClockFSM + 잔여 시간 + 현재 레벨) | 인증 사용자 |
| POST | `/flights/:id/clock/start` | Clock 시작 (STOPPED → RUNNING) | Admin, Operator |
| POST | `/flights/:id/clock/restart` | Clock 재시작 (현재 레벨 duration 처음부터) (CCR-050) | Admin, Operator |
| POST | `/flights/:id/clock/pause` | Clock 일시정지 (RUNNING → PAUSED). 옵셔널 `duration_sec` 자동 재개 | Admin, Operator |
| POST | `/flights/:id/clock/resume` | Clock 재개 (PAUSED → RUNNING) | Admin, Operator |
| PUT | `/flights/:id/clock` | 시간/레벨 수동 조정 (`duration_diff_sec`, `level_diff`) | Admin |
| PUT | `/flights/:id/clock/detail` | 테마/공지/이벤트명/그룹명 변경 (CCR-050) | Admin, Operator |
| PUT | `/flights/:id/clock/reload-page` | 대시보드(전광판) 리로드 신호 (CCR-050) | Admin, Operator |
| PUT | `/flights/:id/clock/adjust-stack` | 평균 칩 스택 강제 조정 (CCR-050) | Admin |

**GET /flights/:id/clock — Response:**

```json
{
  "status": "running",
  "level": 8,
  "level_index": 9,
  "blind_detail_type": 0,
  "duration_sec": 1200,
  "time_remaining_sec": 719,
  "blind_info": { "sb": 400, "bb": 800, "ante": 100 },
  "is_paused": false,
  "auto_advance": true
}
```

**PUT /flights/:id/clock — Request:**

```json
{ "duration_diff_sec": 60, "level_diff": 0 }
```

> WSOP LIVE `durationDiff`/`levelDiff` 대응.

**POST /flights/:id/clock/pause — Request (optional):**

```json
{ "duration_sec": 600 }
```

> `duration_sec` 제공 시 자동 Resume. 미제공 시 수동.

**PUT /flights/:id/clock/detail — Request:**

```json
{
  "theme": "final_table",
  "announcement": "Dinner break at Level 15",
  "group_name": "Day 1B"
}
```

> 모든 필드 optional. `clock_detail_changed` 이벤트 발행 (API-05 §4.2.4).

**PUT /flights/:id/clock/adjust-stack — Request:**

```json
{ "average_stack": 45000, "reason": "re-entry window closed" }
```

> `stack_adjusted` 이벤트 발행 (API-05 §4.2.9).

### 5.7 Tables — 테이블

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| GET | `/tables` | 테이블 목록 (Flight 필터: `?flight_id=`) | 인증 사용자 |
| GET | `/tables/:id` | 테이블 상세 | 인증 사용자 (Operator: 할당만) |
| POST | `/tables` | 테이블 생성 | Admin |
| PUT | `/tables/:id` | 테이블 수정 | Admin |
| DELETE | `/tables/:id` | 테이블 삭제 | Admin |
| GET | `/tables/:id/status` | 테이블 실시간 상태 | 인증 사용자 |
| POST | `/tables/rebalance` | 다중 테이블 플레이어 재배치 (saga) | Admin |
| GET | `/tables/:id/events` | WebSocket 재연결 후 누락 이벤트 replay | Admin, Operator(할당), Viewer |

> **WSOP 원본과 다름**: WSOP Table API는 nested path `GET /Series/{seriesId}/EventFlights/{eventFlightId}/TotalTableList` 구조. EBS는 flat REST `/tables?flight_id=` 구조. WSOP `SeatInfo`에 `PlayerMoveStatus { None=0, New=1, Move=2 }`, `WsopId`, `Nickname`, `reEntryCount` 등 추가 필드 존재.

**POST /tables — Request:**

```json
{
  "event_flight_id": 3,
  "table_no": 1,
  "name": "Feature Table 1",
  "type": "feature",
  "max_players": 9,
  "game_type": 0,
  "delay_seconds": 30
}
```

> **SG-008-b11 결정 (2026-04-20, 옵션 1 채택)**: `POST /tables/:id/launch-cc` 엔드포인트는 제거되었다. CC launch 는 OS deep-link (`ebs-cc://table/{id}?token={short_lived_token}`) 방식으로 전환되었다. Lobby 가 short-lived launch token 을 `/api/v1/auth/launch-token` (별도 issuance) 로 받아 deep-link 인자로 전달하고, CC 앱은 Flutter `app_links` 패키지로 OS protocol handler 를 등록한다. 원격 launch 요구는 Phase 1 범위 밖 (필요 시 WebSocket push 패턴으로 재설계). 근거: WSOP LIVE `Staff App §Launch` = deep-link 패턴.

---

#### POST /tables/rebalance (CCR-010 — Saga)

**용도**: 여러 테이블 간 플레이어 재배치. **WSOP 원본에는 saga 없음** — WSOP Table API는 `ConfirmMoveTable`(테이블 간 이동), `TableRandomSeatPlayer`(랜덤 배치) 등 개별 move API만 제공. EBS는 이를 saga 패턴으로 묶어 atomicity + compensating action을 보장.

**멱등성**: `Idempotency-Key` 헤더 **필수**. saga 전체에 1개 키 부여 (CCR-003 §3.1).

**Request:**

```json
{
  "event_flight_id": "ef-001",
  "strategy": "balanced",
  "target_players_per_table": 9,
  "dry_run": false
}
```

**단계 정의** (실패 시 역순 compensation 실행, 각 step 별 idempotent 보장):

| step | 이름 | 설명 | 보상 동작 |
|:----:|------|------|----------|
| 1 | `acquire_locks` | 영향 테이블 전체에 distributed lock (`lock:table:{id}` Redis `SET NX EX 30s`) + fencing token | lock release |
| 2 | `compute_plan` | 대상 플레이어/좌석 배치 계산 | (무상태) |
| 3 | `release_seats` | 원 좌석 비움 + `audit_events` 기록 | `revert_releases` (원 좌석 복구) |
| 4 | `assign_seats` | 신규 좌석 배정 + `audit_events` 기록 | `revert_assigns` (신규 좌석 해제) |
| 5 | `notify_wsop_live` | WSOP LIVE 동기화 (실패 시 fallback queue로 보내고 단계 성공 처리) | fallback queue retry |
| 6 | `broadcast_ws` | WebSocket `rebalance_*` 이벤트 발행 | (무상태) |

**Response 200 (전체 성공 — `status: "completed"`):**

```json
{
  "data": {
    "saga_id": "sg-20260410-001",
    "status": "completed",
    "moved": [
      { "player_id": "p-123", "from_table": "tbl-01", "to_table": "tbl-05", "to_seat": 3 }
    ],
    "tables_closed": ["tbl-07"],
    "steps": [
      { "step_no": 1, "name": "acquire_locks", "status": "ok", "duration_ms": 42 },
      { "step_no": 2, "name": "compute_plan", "status": "ok", "duration_ms": 18 },
      { "step_no": 3, "name": "release_seats", "status": "ok", "duration_ms": 120 },
      { "step_no": 4, "name": "assign_seats", "status": "ok", "duration_ms": 180 },
      { "step_no": 5, "name": "notify_wsop_live", "status": "ok", "duration_ms": 310 },
      { "step_no": 6, "name": "broadcast_ws", "status": "ok", "duration_ms": 25 }
    ],
    "completed_at": "2026-04-10T12:34:57.234Z"
  },
  "error": null
}
```

**Response 207 Multi-Status (부분 성공 후 보상 완료 — `status: "compensated"`):**

saga 중간 실패 후 compensating action이 실행되어 **일관된 상태로 복원**됐을 때. 재시도 안전.

```json
{
  "data": {
    "saga_id": "sg-20260410-002",
    "status": "compensated",
    "steps": [
      { "step_no": 1, "name": "acquire_locks", "status": "ok" },
      { "step_no": 2, "name": "compute_plan", "status": "ok" },
      { "step_no": 3, "name": "release_seats", "status": "ok" },
      {
        "step_no": 4, "name": "assign_seats", "status": "failed",
        "error": "seat_conflict",
        "message": "Seat tbl-05/3 already taken by concurrent operation"
      },
      {
        "step_no": 3, "name": "release_seats", "status": "compensated",
        "compensation": "reverted_releases",
        "affected_players": ["p-123", "p-456"]
      }
    ],
    "moved": [],
    "tables_closed": []
  },
  "error": {
    "code": "partial_failure_compensated",
    "message": "Rebalancing rolled back to original state. Retry safe."
  }
}
```

**Response 500 (보상 실패 — `status: "compensation_failed"`, 수동 개입 필요):**

```json
{
  "data": {
    "saga_id": "sg-20260410-003",
    "status": "compensation_failed",
    "steps": [ "..." ]
  },
  "error": {
    "code": "manual_intervention_required",
    "message": "Partial state detected. See audit_events for recovery.",
    "audit_cursor": { "from_seq": 15001, "to_seq": 15024 }
  }
}
```

Operator 경고 모달 + `BO-03 §4 Scenario D` 복구 절차를 트리거한다. `audit_cursor` 범위로 `audit_events`를 조회하여 수동 복구.

---

#### GET /tables/:id/events (CCR-015 — WebSocket Replay)

**용도**: WebSocket 재연결 후 누락 이벤트 재생. 클라이언트가 gap 감지 시 호출하여 `seq` 연속성 복구.

**근거**: WSOP+ Architecture `SignalR Real-Time Stream Server + MSK Event Stream` 이중 구조 — 네트워크 순간 단절·백그라운드 복귀·WebSocket 재연결 후 놓친 이벤트를 안전하게 재생하기 위한 REST fallback 경로.

**Path params**: `table_id` — 대상 테이블 ID

**Query parameters:**

| 파라미터 | 타입 | 필수 | 기본 | 설명 |
|---------|:----:|:----:|:----:|------|
| `since` | int | O | — | 마지막으로 수신한 `seq`. 응답은 `seq > since` 만 포함 |
| `limit` | int | — | 500 | 페이지 크기. 최대 2000 |

**Response 200:**

```json
{
  "data": {
    "table_id": "tbl-001",
    "events": [
      {
        "type": "seat_assigned",
        "seq": 12346,
        "table_id": "tbl-001",
        "ts": "2026-04-10T12:34:57.000Z",
        "server_time": "2026-04-10T12:34:57.000Z",
        "payload": { "seat": 3, "player_id": "p-123" },
        "can_undo": true
      }
    ],
    "last_seq": 12500,
    "has_more": false
  },
  "error": null
}
```

**`can_undo` 계산 규칙** (WSOP `EventFlightHistoryInfo.canUndo` 대응):
- `true`: 해당 이벤트의 `inverse_payload`가 존재(NULL 아님) + 현재 핸드 진행 중 아님(`hand_in_progress == false`) + undo 스택 깊이 < 5
- `false`: 위 조건 중 하나라도 미충족, 또는 Bounty/Payout 관련 이벤트(Phase 3+)
- 이 필드는 **서버가 사전 계산**하여 응답에 포함. 클라이언트는 이 값으로 Undo 버튼 활성/비활성을 결정.

**권한**: Admin / Operator(해당 테이블 할당) / Viewer (읽기 전용).
**Rate Limit**: 10 req/sec per table per client.
**데이터 소스**: DATA-04 `audit_events` 테이블 (CCR-001, CCR-015). `(table_id, seq DESC)` 인덱스 사용.
**관련**: API-05 §2.1 envelope `seq` 필드와 1:1 매핑.

---

### 5.8 Seats — 좌석

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| GET | `/tables/:id/seats` | 테이블 좌석 목록 (10석) | 인증 사용자 |
| PUT | `/tables/:id/seats/:seat_no` | 좌석 정보 수정 (플레이어 배치/제거) | Admin, Operator (할당 테이블) |

**PUT /tables/:id/seats/:seat_no — Request (플레이어 배치):**

```json
{
  "player_id": 42,
  "chip_count": 50000,
  "status": "occupied"
}
```

**PUT /tables/:id/seats/:seat_no — Request (좌석 비우기):**

```json
{
  "player_id": null,
  "chip_count": 0,
  "status": "vacant"
}
```

**WSOP SeatInfo 응답 필드** (Table API, Confluence page 1653833763) — EBS Phase 1 에서 포함 여부:

| WSOP 필드 | 타입 | EBS 포함 | 비고 |
|-----------|------|:--------:|------|
| SeatId | int | 미포함 | EBS는 `seat_no`로 식별 |
| SeatNo | int | O | |
| PlayerId | int | O | |
| PlayerName | string | 미포함 | join 필요 |
| WsopId | string | 미포함 | WSOP 연동 시 필요 |
| Nickname | string | 미포함 | |
| Nationality | string | 미포함 | |
| ChipCount | int | O | |
| Status (PlayerPlayingStatus) | enum | O | EBS: `vacant/occupied` 문자열, WSOP: `0(정상)/1(waiting eliminate)` |
| PlayerMoveStatus | enum | 미포함 | `None=0, New=1, Move=2` |
| PlayerRegisteredAt | string | 미포함 | |
| PlayerSeatBeginAt | string | 미포함 | |
| ProfileImageUrl | string | 미포함 | |
| reEntryCount | int | 미포함 | |

### 5.9 Players — 플레이어

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| GET | `/players` | 플레이어 목록 | 인증 사용자 |
| GET | `/players/:id` | 플레이어 상세 | 인증 사용자 |
| POST | `/players` | 플레이어 수동 등록 | Admin |
| PUT | `/players/:id` | 플레이어 수정 | Admin, Operator (할당 테이블) |
| DELETE | `/players/:id` | 플레이어 삭제 | Admin |
| GET | `/players/search` | 플레이어 검색 (`?q=name`) | 인증 사용자 |

**GET /players/search?q=john — Response:**

```json
{
  "data": [
    {
      "player_id": 42,
      "wsop_id": "WSOP-12345",
      "first_name": "John",
      "last_name": "Doe",
      "nationality": "USA",
      "source": "api"
    }
  ],
  "error": null,
  "meta": { "page": 1, "limit": 20, "total": 1 }
}
```

### 5.10 Hands — 핸드

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| GET | `/hands` | 핸드 목록 (테이블 필터: `?table_id=`) | 인증 사용자 |
| GET | `/hands/:id` | 핸드 상세 | 인증 사용자 |
| GET | `/hands/:id/actions` | 핸드 액션 목록 | 인증 사용자 |
| GET | `/hands/:id/players` | 핸드 참여 플레이어 | 인증 사용자 |

> 핸드 생성(POST)은 CC에서 WebSocket을 통해 수행한다. REST API는 조회 전용.

### 5.11 Configs — 시스템 설정

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| GET | `/configs/:section` | 섹션별 설정 조회 | Admin |
| PUT | `/configs/:section` | 섹션별 설정 수정 | Admin |

**section 값:**

| section | 설명 | 예시 키 |
|---------|------|--------|
| `output` | 출력 설정 | `default_output_type`, `default_resolution` |
| `overlay` | 오버레이 설정 | `default_skin_id`, `animation_speed` |
| `game` | 게임 기본 설정 | `default_game_type`, `default_table_size` |
| `statistics` | 통계 설정 | `vpip_enabled`, `equity_display` |
| `rfid` | RFID 설정 | `rfid_mode`, `mock_enabled` |
| `system` | 시스템 설정 | `log_level`, `backup_interval` |

**GET /configs/output — Response:**

```json
{
  "data": {
    "section": "output",
    "values": {
      "default_output_type": "ndi",
      "default_resolution": "1920x1080",
      "default_framerate": 60,
      "security_delay_sec": 0,
      "chroma_key": false
    }
  },
  "error": null
}
```

### 5.12 Skins — 오버레이 스킨

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| GET | `/skins` | 스킨 목록 조회 | Viewer+ |
| GET | `/skins/:id` | 스킨 상세 조회 (skin.json) | Viewer+ |
| POST | `/skins` | 새 스킨 생성 | Admin |
| PUT | `/skins/:id` | 스킨 수정 (skin.json 업데이트) | Admin |
| DELETE | `/skins/:id` | 스킨 삭제 | Admin |
| POST | `/skins/:id/upload` | .gfskin 파일 업로드 | Admin |
| GET | `/skins/:id/download` | .gfskin 파일 다운로드 | Viewer+ |
| POST | `/skins/:id/activate` | 스킨 활성화 (Overlay 적용) | Admin, Operator |
| POST | `/skins/:id/duplicate` | 스킨 복제 | Admin |

### 5.13 BlindStructures — 블라인드 구조 (CCR-049)

> **WSOP LIVE 대응**: `/Series/{sId}/BlindStructures/*` + `/EventFlights/{efId}/BlindStructure` (SSOT Page 1603666061). Series 레벨 템플릿 관리 + EventFlight 레벨 적용/수정.

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| GET | `/series/:id/blind-structures` | 템플릿 목록 | 인증 사용자 |
| GET | `/series/:id/blind-structures/templates/:blind_type` | 타입별 샘플 템플릿 | 인증 사용자 |
| GET | `/series/:id/blind-structures/:bs_id` | 템플릿 상세 (레벨 배열) | 인증 사용자 |
| POST | `/series/:id/blind-structures` | 템플릿 생성 | Admin |
| PUT | `/series/:id/blind-structures/:bs_id` | 템플릿 수정 (전체 PUT, creator 만) | Admin |
| DELETE | `/series/:id/blind-structures/:bs_id` | 템플릿 영구 제거 | Admin |
| GET | `/flights/:id/blind-structure` | Flight 적용 구조 조회 | 인증 사용자 |
| PUT | `/flights/:id/blind-structure` | Flight 적용 구조 수정 (`blind_structure_changed` 이벤트) | Admin |

**POST /series/:id/blind-structures — Request:**

```json
{
  "name": "Standard NL Holdem 60min",
  "blind_type": "no_limit_holdem",
  "is_auto_renaming": true,
  "details": [
    { "level": 1, "type": 0, "sb": 100, "bb": 200, "ante": 0, "duration_sec": 3600 },
    { "level": 2, "type": 0, "sb": 200, "bb": 400, "ante": 50, "duration_sec": 3600 },
    { "level": 3, "type": 1, "sb": null, "bb": null, "ante": null, "duration_sec": 900 }
  ]
}
```

> `type`: BlindDetailType (BS-00 §3.8).

**PUT /flights/:id/blind-structure — Request:**

```json
{ "template_id": 42, "overrides": { "3": { "duration_sec": 1200 } } }
```

> `blind_structure_changed` WebSocket 이벤트 발행 (API-05 §4.2.7).

> **레거시 호환**: 기존 `/blind-structures` flat 엔드포인트 5종은 Phase 1 호환. 신규 구현은 Series-scoped 경로.

**WSOP BlindType enum 매핑** (EBS `game_type` + `bet_structure` 2필드 매핑):

| int | BlindType | EBS game_type | EBS bet_structure |
|:---:|-----------|:------------:|:-----------------:|
| 0 | NoLimitHoldem | 0 (Holdem) | 0 (No Limit) |
| 1 | HORSE | 5 (HORSE) | — (mixed) |
| 2 | Limits | — | 1 (Limit) |
| 3 | DealerChoice | 6 (DealerChoice) | — |
| 5 | PotLimitOmaha | 1 (Omaha) | 2 (Pot Limit) |
| 6 | Stud | 2 (Stud) | — |
| 7 | MixedGame | 7 (Mixed) | — |
| 8 | MixedOmaha | 1 (Omaha) | — (mixed) |
| 9 | PLONLH | — | — (PLO+NLH) |
| 10 | OFC | — | — (Open Face Chinese) |

### 5.13.1 PayoutStructures — 상금 구조 (CCR-051)

> **WSOP LIVE 대응**: `/Series/{sId}/PayoutStructures/*` + `/EventFlights/{efId}/PayoutStructure` (SSOT Page 1603600679). 용어: WSOP "PayoutStructure" = 사용자 용어 "PrizePool".

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| GET | `/series/:id/payout-structures` | 템플릿 목록 | 인증 사용자 |
| POST | `/series/:id/payout-structures` | 템플릿 생성 | Admin |
| GET | `/series/:id/payout-structures/:ps_id` | 템플릿 상세 | 인증 사용자 |
| PUT | `/series/:id/payout-structures/:ps_id` | 템플릿 수정 (creator 만) | Admin |
| DELETE | `/series/:id/payout-structures/:ps_id` | 템플릿 제거 | Admin |
| GET | `/flights/:id/payout-structure` | Flight 적용 Payout 조회 | 인증 사용자 |
| PUT | `/flights/:id/payout-structure` | Flight 적용 Payout 수정 (`prize_pool_changed` 이벤트) | Admin |

**POST /series/:id/payout-structures — Request:**

```json
{
  "name": "Standard Tournament Payout",
  "is_template": true,
  "entries": [
    {
      "entry_from": 10, "entry_to": 50,
      "ranks": [
        { "rank_from": 1, "rank_to": 1, "award_percent": 50.0 },
        { "rank_from": 2, "rank_to": 2, "award_percent": 30.0 },
        { "rank_from": 3, "rank_to": 3, "award_percent": 20.0 }
      ]
    }
  ]
}
```

> `ranks[].award_percent` 합 `= 100.0` 검증 (400 `PAYOUT_PERCENT_INVALID`).

**PUT /flights/:id/payout-structure — Request:**

```json
{ "template_id": 7, "overrides": null }
```

> `prize_pool_changed` WebSocket 이벤트 발행 (API-05 §4.2.8).

### 5.14 AuditLogs — 감사 로그

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| GET | `/audit-logs` | 감사 로그 목록 | Admin |

**쿼리 파라미터:**

| 파라미터 | 타입 | 설명 |
|---------|------|------|
| `entity_type` | string | 필터: 엔티티 종류 (table, player, event 등) |
| `action` | string | 필터: 작업 유형 (create, update, delete, login, logout) |
| `user_id` | int | 필터: 수행자 ID |
| `from` | datetime | 시작 일시 |
| `to` | datetime | 종료 일시 |

### 5.15 Reports — 리포트 (SG-007)

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| GET | `/reports/dashboard` | 전체 운영 현황 개요 (B-037) | Admin, Viewer |
| GET | `/reports/table-activity` | 테이블별 활동 시계열 (B-038) | Admin, Operator |
| GET | `/reports/player-stats` | VPIP/PFR/AF/3bet% (B-039) | Admin, Viewer |
| GET | `/reports/hand-distribution` | 169 홀덤 시작패 매트릭스 (B-048) | Admin |
| GET | `/reports/rfid-health` | RFID 리더/카드 상태 (B-049) | Admin, Operator |
| GET | `/reports/operator-activity` | 운영자 작업 이력 (B-050) | Admin, Operator(self-only) |

**공통 쿼리 파라미터 (SG-007 §공통)**:

| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|:----:|------|
| `scope` | `global \| series \| event \| table` | O | 집계 범위 |
| `scope_id` | string | △ | `scope != global` 시 필수 |
| `from` | ISO 8601 datetime | O | 시작 시각 |
| `to` | ISO 8601 datetime | O | 종료 시각 |
| `granularity` | `minute \| hour \| day \| hand` | O | 시계열 해상도 |
| `format` | `json \| csv` | △ | 기본 json |
| `timezone` | IANA TZ | △ | 기본 `Asia/Seoul` |

> **SG-008-b12 결정 (2026-04-20, 옵션 1 채택)**: legacy `GET /reports/{report_type}` (type=hands-summary/player-stats/table-activity/session-log) 엔드포인트는 제거되었다. Frontend/CC 에서 호출 0 확인 후 삭제. 본 6-endpoint 로 완전 대체. 재도입 요청 시 SG-008-b12 재오픈.

### 5.16 WSOP LIVE Sync — 외부 동기화

#### POST /api/v1/sync/wsop-live

Admin이 수동으로 전체 동기화를 실행한다.

**Request:**

```json
{
  "scope": "all"
}
```

| scope 값 | 동작 |
|----------|------|
| `all` | 전체 엔티티 동기화 |
| `series` | Series만 동기화 |
| `events` | Events + Flights 동기화 |
| `players` | Players 동기화 |
| `blinds` | BlindStructure 동기화 |

**Response (202 Accepted):**

```json
{
  "data": {
    "sync_id": "sync-uuid-1234",
    "scope": "all",
    "status": "started",
    "started_at": "2026-04-08T12:00:00Z"
  },
  "error": null
}
```

#### GET /api/v1/sync/wsop-live/status

**Response:**

```json
{
  "data": {
    "last_sync": {
      "sync_id": "sync-uuid-1234",
      "scope": "all",
      "status": "completed",
      "started_at": "2026-04-08T12:00:00Z",
      "completed_at": "2026-04-08T12:00:03Z",
      "stats": {
        "series": { "created": 0, "updated": 1, "skipped": 0 },
        "events": { "created": 5, "updated": 12, "skipped": 0 },
        "flights": { "created": 8, "updated": 3, "skipped": 0 },
        "players": { "created": 50, "updated": 120, "skipped": 5 },
        "blinds": { "created": 0, "updated": 0, "skipped": 3 }
      }
    },
    "scheduler": {
      "is_running": true,
      "next_event_sync": "2026-04-08T12:05:00Z",
      "next_player_sync": "2026-04-08T12:10:00Z"
    }
  },
  "error": null
}
```

#### GET /api/v1/sync/conflicts

충돌 감사 로그를 조회한다. 상세 스키마는 §15 참조.

**쿼리 파라미터:**

| 파라미터 | 타입 | 설명 |
|---------|------|------|
| `entity_table` | string | 필터: 엔티티 테이블명 |
| `resolution` | string | 필터: `wsop_wins` / `ebs_wins` / `pending` |

**역할 제한**: Admin

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| POST | `/sync/wsop-live` | WSOP LIVE 수동 동기화 트리거 | Admin |
| GET | `/sync/wsop-live/status` | 동기화 상태 확인 | Admin |
| GET | `/sync/conflicts` | 동기화 충돌 감사 로그 조회 | Admin |

---

### PlayerWaitingStatus

Waiting List에서 플레이어의 현재 상태를 나타내는 enum. WSOP LIVE `PlayerWaitingStatus` 준거.

| 값 | int | 설명 | 전이 조건 |
|------|:---:|------|----------|
| `WAITING` | 0 | 대기열 등록 | Sit-In 요청 시 |
| `FRONT` | 1 | 대기열 선두 (배치 임박) | 자동 (대기 순서) |
| `CALLING` | 2 | 호출 중 (이름 호출됨, 응답 대기) | Auto-seating 또는 수동 호출 시 |
| `READY` | 3 | 응답 완료, 좌석 배정 대기 | 플레이어 응답 확인 |
| `SEATED` | 10 | 좌석 배정 완료 | `seat_assigned` 이벤트 후 |
| `CANCELED` | 20 | 대기 취소 | 플레이어 요청 또는 Admin 취소 |
| `EXPIRED` | 30 | 호출 응답 없음 (Call Limit 타임아웃) | `CALL_LIMIT_MS` (IMPL-10 §6, 기본 120s) 초과. **WSOP 원본에 없는 EBS 확장값** |

> WSOP 원본: `WaitingStatus { Waiting=0, Front=1, Calling=2, Ready=3, Seated=10, Canceled=20 }` (Confluence page 1960411325). EBS는 UPPER_SNAKE_CASE, WSOP는 PascalCase.

**사용처**: `GET /tables/:event_flight_id/waiting` 응답의 각 항목에 `status` 필드로 포함.

---

## 5.17 CRUD 완결성 편입 (2026-04-20 SG-008 a분류)

**배경**: `tools/spec_drift_check.py --api` 결과 D3(code-only) 96건 중 (a) 기획 추가 77건을 본 섹션에서 일괄 편입한다. (b) 판정 필요 12건은 `SG-008-b1 ~ b12` 로 개별 승격됨(마스터: `Conductor_Backlog/SG-008-api-d3-bulk-documentation.md`).

**편입 원칙**:

1. **기획이 진실** — 본 섹션의 모든 endpoint 는 §5.2~5.16 에 이미 정의된 리소스의 CRUD 완결성 보강. 새 리소스나 새 동작을 추가하지 않는다.
2. **공통 규약 준용** — RBAC/auth/Idempotency/응답 포맷은 §1~§4 규약을 그대로 따른다. 본 섹션은 중복 기술하지 않는다.
3. **Request/Response 스키마 참조** — 각 endpoint 의 body/response 는 `team2-backend/src/routers/<resource>.py` 의 Pydantic/SQLModel 모델에 정의. FastAPI OpenAPI 자동 생성 (`/docs`, `/openapi.json`) 시 노출. 본 문서는 **endpoint 목록 + 용도 + RBAC** 만 명세.
4. **멱등성** — POST/PATCH/DELETE 는 `Idempotency-Key` 헤더 사용 권장 (§3.1 참조).

### 5.17.1 Users — CRUD 완결

§5.2 기 정의. 본 표는 D3 편입분 명시.

| Method | Path | 용도 | RBAC | Status |
|:------:|------|------|:----:|:------:|
| GET | `/api/v1/users` | 목록 | Admin | 200 |
| GET | `/api/v1/users/{user_id}` | 단건 | Admin | 200 / 404 |
| PUT | `/api/v1/users/{user_id}` | 수정 | Admin | 200 / 404 |
| DELETE | `/api/v1/users/{user_id}` | 삭제 | Admin | 204 / 404 |

### 5.17.2 Competitions — CRUD 완결

§5.3 기 정의. Phase 2 deprecated 예정이나 Phase 1 유지.

| Method | Path | 용도 | RBAC | Status |
|:------:|------|------|:----:|:------:|
| GET | `/api/v1/competitions/{competition_id}` | 단건 | 인증 | 200 / 404 |
| POST | `/api/v1/competitions` | 생성 | Admin | 201 |
| PUT | `/api/v1/competitions/{competition_id}` | 수정 | Admin | 200 / 404 |
| DELETE | `/api/v1/competitions/{competition_id}` | 삭제 | Admin | 204 / 404 |

### 5.17.3 Series — CRUD 완결

§5.4 기 정의. sub-route 추가.

| Method | Path | 용도 | RBAC | Status |
|:------:|------|------|:----:|:------:|
| GET | `/api/v1/series/{series_id}` | 단건 | 인증 | 200 / 404 |
| PUT | `/api/v1/series/{series_id}` | 수정 | Admin | 200 / 404 |
| DELETE | `/api/v1/series/{series_id}` | 삭제 | Admin | 204 / 404 |
| GET | `/api/v1/series/{series_id}/events` | Series의 Event 목록 | 인증 | 200 |
| POST | `/api/v1/series/{series_id}/events` | Series 하위 Event 생성 | Admin | 201 |

### 5.17.4 Events — CRUD 완결

§5.5 기 정의. flights sub-route 추가.

| Method | Path | 용도 | RBAC | Status |
|:------:|------|------|:----:|:------:|
| GET | `/api/v1/events/{event_id}` | 단건 | 인증 | 200 / 404 |
| PUT | `/api/v1/events/{event_id}` | 수정 | Admin | 200 / 404 |
| DELETE | `/api/v1/events/{event_id}` | 삭제 | Admin | 204 / 404 |
| GET | `/api/v1/events/{event_id}/flights` | Event의 Flight 목록 | 인증 | 200 |
| POST | `/api/v1/events/{event_id}/flights` | Event 하위 Flight 생성 | Admin | 201 |

### 5.17.5 Flights — CRUD 완결 + Clock 제어 + 하위 리소스

§5.6 기 정의. Clock 제어 9종 전체 (§5.6.1 이미 명세), blind-structure/tables sub-route 추가.

| Method | Path | 용도 | RBAC | Status |
|:------:|------|------|:----:|:------:|
| GET | `/api/v1/flights` | 목록 (`?event_id=`) | 인증 | 200 |
| GET | `/api/v1/flights/{flight_id}` | 단건 | 인증 | 200 / 404 |
| POST | `/api/v1/flights` | 생성 | Admin | 201 |
| PUT | `/api/v1/flights/{flight_id}` | 수정 | Admin | 200 / 404 |
| DELETE | `/api/v1/flights/{flight_id}` | 삭제 | Admin | 204 / 404 |
| PUT | `/api/v1/flights/{flight_id}/complete` | Running → Completed | Admin | 200 / 409 |
| PUT | `/api/v1/flights/{flight_id}/cancel` | Canceled 전이 | Admin | 200 / 409 |
| GET | `/api/v1/flights/{flight_id}/clock` | Clock 상태 | 인증 | 200 |
| POST | `/api/v1/flights/{flight_id}/clock/start` | Clock 시작 | Admin/Op | 200 / 409 |
| POST | `/api/v1/flights/{flight_id}/clock/pause` | Clock 일시정지 | Admin/Op | 200 / 409 |
| POST | `/api/v1/flights/{flight_id}/clock/resume` | Clock 재개 | Admin/Op | 200 / 409 |
| POST | `/api/v1/flights/{flight_id}/clock/restart` | 현 레벨 재시작 (CCR-050) | Admin/Op | 200 / 409 |
| PUT | `/api/v1/flights/{flight_id}/clock` | 수동 조정 | Admin | 200 |
| PUT | `/api/v1/flights/{flight_id}/clock/detail` | 테마/공지 변경 (CCR-050) | Admin/Op | 200 |
| PUT | `/api/v1/flights/{flight_id}/clock/reload-page` | 대시보드 리로드 (CCR-050) | Admin/Op | 200 |
| PUT | `/api/v1/flights/{flight_id}/clock/adjust-stack` | 평균 스택 강제 조정 (CCR-050) | Admin | 200 |
| GET | `/api/v1/flights/{flight_id}/blind-structure` | Flight 적용 구조 | 인증 | 200 / 404 |
| PUT | `/api/v1/flights/{flight_id}/blind-structure` | 구조 수정 | Admin | 200 |
| GET | `/api/v1/flights/{flight_id}/tables` | Flight의 Table 목록 | 인증 | 200 |
| POST | `/api/v1/flights/{flight_id}/tables` | Flight 하위 Table 생성 | Admin | 201 |

> Clock 제어 의미·request body 상세는 §5.6.1 참조. blind-structure 의미는 §5.13 참조.

### 5.17.6 Tables — CRUD 완결 + 하위 리소스

§5.7 기 정의. seats sub-route 추가.

| Method | Path | 용도 | RBAC | Status |
|:------:|------|------|:----:|:------:|
| GET | `/api/v1/tables` | 목록 (`?flight_id=`) | 인증 | 200 |
| GET | `/api/v1/tables/{table_id}` | 단건 | 인증 (Op: 할당만) | 200 / 404 |
| PUT | `/api/v1/tables/{table_id}` | 수정 | Admin | 200 / 404 |
| DELETE | `/api/v1/tables/{table_id}` | 삭제 | Admin | 204 / 404 |
| GET | `/api/v1/tables/{table_id}/status` | 실시간 상태 | 인증 | 200 |
| GET | `/api/v1/tables/{table_id}/seats` | 좌석 목록 (10석) | 인증 | 200 |
| PUT | `/api/v1/tables/{table_id}/seats/{seat_no}` | 좌석 수정 (배치/제거) | Admin/Op(할당) | 200 / 404 |

### 5.17.7 Players — CRUD 완결

§5.9 기 정의.

| Method | Path | 용도 | RBAC | Status |
|:------:|------|------|:----:|:------:|
| GET | `/api/v1/players` | 목록 | 인증 | 200 |
| GET | `/api/v1/players/{player_id}` | 단건 | 인증 | 200 / 404 |
| POST | `/api/v1/players` | 수동 등록 | Admin | 201 |
| PUT | `/api/v1/players/{player_id}` | 수정 | Admin/Op(할당) | 200 / 404 |
| DELETE | `/api/v1/players/{player_id}` | 삭제 | Admin | 204 / 404 |

### 5.17.8 Hands — 조회 전용

§5.10 기 정의. 생성은 WebSocket (CC) 경로.

| Method | Path | 용도 | RBAC | Status |
|:------:|------|------|:----:|:------:|
| GET | `/api/v1/hands` | 목록 (`?table_id=`) | 인증 | 200 |
| GET | `/api/v1/hands/{hand_id}` | 단건 | 인증 | 200 / 404 |
| GET | `/api/v1/hands/{hand_id}/actions` | 액션 목록 | 인증 | 200 |
| GET | `/api/v1/hands/{hand_id}/players` | 참여 플레이어 | 인증 | 200 |

### 5.17.9 BlindStructures — CRUD 완결 (legacy flat)

§5.13 에 Series-scoped 경로가 정의되어 있다. 본 표는 **Phase 1 legacy flat** 호환 경로.

| Method | Path | 용도 | RBAC | Status | 비고 |
|:------:|------|------|:----:|:------:|------|
| GET | `/api/v1/blind-structures` | 템플릿 목록 (flat) | 인증 | 200 | Phase 1 호환 |
| GET | `/api/v1/blind-structures/{bs_id}` | 단건 (flat) | 인증 | 200 / 404 | Phase 1 호환 |
| POST | `/api/v1/blind-structures` | 생성 (flat) | Admin | 201 | Phase 1 호환 |
| PUT | `/api/v1/blind-structures/{bs_id}` | 수정 (flat) | Admin | 200 / 404 | Phase 1 호환 |
| DELETE | `/api/v1/blind-structures/{bs_id}` | 삭제 (flat) | Admin | 204 / 404 | Phase 1 호환 |

> 신규 구현은 Series-scoped 경로 (§5.13) 권장. flat 경로는 Phase 2 deprecate 예정.

### 5.17.10 PayoutStructures — CRUD 완결 (legacy flat)

§5.13.1 에 Series-scoped 경로 정의. 본 표는 Phase 1 legacy flat 호환.

| Method | Path | 용도 | RBAC | Status |
|:------:|------|------|:----:|:------:|
| GET | `/api/v1/payout-structures` | 템플릿 목록 (flat) | 인증 | 200 |
| GET | `/api/v1/payout-structures/{ps_id}` | 단건 (flat) | 인증 | 200 / 404 |
| POST | `/api/v1/payout-structures` | 생성 (flat) | Admin | 201 |
| PUT | `/api/v1/payout-structures/{ps_id}` | 수정 (flat) | Admin | 200 / 404 |
| DELETE | `/api/v1/payout-structures/{ps_id}` | 삭제 (flat) | Admin | 204 / 404 |

### 5.17.11 Skins — 확장

§5.12 기 정의. metadata PATCH + activate 별칭 추가.

| Method | Path | 용도 | RBAC | Status |
|:------:|------|------|:----:|:------:|
| PUT | `/api/v1/skins/{skin_id}` | 수정 (skin.json 갱신) | Admin | 200 / 404 |
| DELETE | `/api/v1/skins/{skin_id}` | 삭제 | Admin | 204 / 404 |
| PATCH | `/api/v1/skins/{skin_id}/metadata` | 메타데이터만 부분 수정 | Admin | 200 |
| POST | `/api/v1/skins/{skin_id}/activate` | 활성화 (표준 — POST) | Admin/Op | 200 |
| PUT | `/api/v1/skins/{skin_id}/activate` | 활성화 (idempotent 별칭 — PUT) | Admin/Op | 200 |

> `POST`/`PUT` 두 동사 모두 구현 — PUT 은 idempotent 재요청에 안전.

### 5.17.12 Decks — RFID 카드 덱 관리 (SG-006)

§5.7~5.8 관련 RFID 카드 매핑을 위한 독립 리소스 (SG-006 deck 라우터).

| Method | Path | 용도 | RBAC | Status |
|:------:|------|------|:----:|:------:|
| GET | `/api/v1/decks/{deck_id}` | 덱 상세 (52장 매핑) | 인증 | 200 / 404 |
| PATCH | `/api/v1/decks/{deck_id}` | 덱 메타 수정 (이름 등) | Admin | 200 / 404 |
| DELETE | `/api/v1/decks/{deck_id}` | 덱 삭제 | Admin | 204 / 404 |
| POST | `/api/v1/decks/{deck_id}/cards` | 카드 일괄 등록 | Admin | 201 |
| PATCH | `/api/v1/decks/{deck_id}/cards/{card_code}` | 단일 카드 매핑 변경 | Admin | 200 / 404 |
| POST | `/api/v1/decks/import` | .deck 파일 import | Admin | 201 |

> 의미·request body 상세는 `SG-006-rfid-52-card-codemap.md` 및 `src/routers/decks.py` Pydantic 모델 참조.

### 5.17.13 Configs — 섹션별 설정

§5.11 기 정의. SG-003 legacy wrapper — Phase 2 `settings_kv` 로 이관 예정.

| Method | Path | 용도 | RBAC | Status |
|:------:|------|------|:----:|:------:|
| GET | `/api/v1/configs/{section}` | 섹션별 조회 | Admin | 200 / 404 |
| PUT | `/api/v1/configs/{section}` | 섹션별 수정 | Admin | 200 |

### 5.17.14 Reports — 리포트 확장

§5.15 에 `{type}` path 로 조회 명세. team2 SG-007 구현은 **개별 report type 별 endpoint** 로 분기.

| Method | Path | 용도 | RBAC | Status |
|:------:|------|------|:----:|:------:|
| GET | `/api/v1/reports/dashboard` | 운영 대시보드 집계 | Admin | 200 |
| GET | `/api/v1/reports/hand-distribution` | 핸드 분포 통계 | Admin | 200 |
| GET | `/api/v1/reports/operator-activity` | Operator 활동 이력 | Admin | 200 |
| GET | `/api/v1/reports/player-stats` | 플레이어 통계 (VPIP/PFR/AGR) | Admin | 200 |
| GET | `/api/v1/reports/rfid-health` | RFID 리더 헬스 체크 | Admin | 200 |
| GET | `/api/v1/reports/table-activity` | 테이블 활동 이력 | Admin | 200 |

> §5.15 `GET /reports/{type}` 의 실제 구현은 위 6개 type-specific endpoint 로 분기된다. `{type}` path 변수 형태는 SG-008-b12 에서 Phase 2 deprecate 판정 대기.

### 5.17.15 Settings — resolved 조회

§5.11 Configs 와 별개로 team1 Settings UI 가 소비하는 resolved view.

| Method | Path | 용도 | RBAC | Status |
|:------:|------|------|:----:|:------:|
| GET | `/api/v1/settings/resolved` | 스코프별 merge 결과 (Series→Event→Table 우선순위) | 인증 | 200 |

> resolved 규칙: Table override → Event override → Series default 순서 적용. 상세는 `Settings/Overview.md §Settings Scope`.

### 5.17.16 편입 총괄

| 카테고리 | 편입 개수 | 참조 섹션 |
|----------|:---------:|----------|
| Users | 4 | §5.2, §5.17.1 |
| Competitions | 4 | §5.3, §5.17.2 |
| Series | 5 | §5.4, §5.17.3 |
| Events | 5 | §5.5, §5.17.4 |
| Flights (clock 포함) | 20 | §5.6, §5.17.5 |
| Tables (seats 포함) | 7 | §5.7, §5.17.6 |
| Players | 5 | §5.9, §5.17.7 |
| Hands | 4 | §5.10, §5.17.8 |
| BlindStructures (flat) | 5 | §5.13, §5.17.9 |
| PayoutStructures (flat) | 5 | §5.13.1, §5.17.10 |
| Skins | 5 | §5.12, §5.17.11 |
| Decks | 6 | §5.17.12 |
| Configs | 2 | §5.11, §5.17.13 |
| Reports | 6 | §5.15, §5.17.14 |
| Settings | 1 | §5.17.15 |
| **합계** | **84** | — |

> 총 84건 — SG-008 마스터 (a) 분류 77건 + 이미 §5.6.1 Clock 등에 부분 명세되어 있던 7건 (명시 재확인). §6 총괄표는 리소스 대분류 단위로 유지되며 본 편입은 상세 보강.

---

## 6. 엔드포인트 총괄표

| 분류 | GET | POST | PUT | DELETE | 합계 |
|------|:---:|:----:|:---:|:------:|:----:|
| Auth | 1 | 4 | — | 1 | 6 |
| Users | 2 | 1 | 1 | 1 | 5 |
| Competitions | 2 | 1 | 1 | 1 | 5 |
| Series | 2 | 1 | 1 | 1 | 5 |
| Events | 3 | 1 | 1 | 1 | 6 |
| Flights | 2 | 1 | 1 | 1 | 5 |
| Tables | 4 | 3 | 1 | 1 | 9 |
| Seats | 1 | — | 1 | — | 2 |
| Players | 3 | 1 | 1 | 1 | 6 |
| Hands | 4 | — | — | — | 4 |
| Configs | 1 | — | 1 | — | 2 |
| Skins | 3 | 4 | 1 | 1 | 9 |
| BlindStructures | 2 | 1 | 1 | 1 | 5 |
| AuditLogs | 1 | — | — | — | 1 |
| Reports | 1 | — | — | — | 1 |
| Sync | 2 | 1 | — | — | 3 |
| **합계** | **34** | **19** | **10** | **9** | **72** |

---

## Part II — WSOP LIVE Integration Protocol

## 7. 연동 아키텍처

### 7.1 데이터 흐름

```
WSOP LIVE API
     │
     │ (HTTP GET, 주기적 폴링)
     ▼
BO Sync Worker ──── 변환/검증 ──── BO DB
     │                                │
     │ (에러 시)                      │ (성공 시)
     ▼                                ▼
에러 로그 + 재시도              WebSocket 알림 → Lobby
```

### 7.2 Sync Worker 위치

Sync Worker는 BO FastAPI 서버 내 **백그라운드 태스크**로 실행된다. 별도 프로세스가 아님.

| 항목 | 값 |
|------|------|
| 실행 방식 | FastAPI `BackgroundTasks` 또는 APScheduler |
| 시작 조건 | BO 서버 시작 시 자동 시작 |
| 중지 조건 | BO 서버 종료 시 자동 종료 |
| 수동 트리거 | `POST /api/v1/sync/wsop-live` |

---

## 8. 동기화 대상 엔티티

### 8.1 엔티티별 폴링 설정

| 엔티티 | WSOP LIVE 엔드포인트 | 폴링 주기 | EBS 테이블 | 비고 |
|--------|---------------------|:---------:|-----------|------|
| **Competition** | `GET /competitions` | 24시간 | `competitions` | 변경 빈도 매우 낮음 |
| **Series** | `GET /series` | 1시간 | `series` | 시즌 초 1회 생성, 이후 변경 드뭄 |
| **Event** | `GET /series/:id/events` | 5분 | `events` | 상태 변경(created→running→completed) 추적 |
| **Flight** | `GET /events/:id/flights` | 5분 | `event_flights` | Event와 동일 주기 |
| **Player** | `GET /events/:id/players` | 10분 | `players` | 좌석 변경, 탈락 반영 |
| **BlindStructure** | `GET /events/:id/blind-structure` | 30분 | `blind_structures` + `blind_structure_levels` | 대회 중 변경 거의 없음 |
| **PayoutStructure** | `GET /series/:sid/PayoutStructures` | 1시간 | `payout_structures` | Series 레벨 템플릿. Staff App API 대응 (Page 1603600679) |
| **Staff** | `GET /series/:sid/Staffs` | 24시간 (낮 우선) | `users` (Suspend/Lock 필드) | Staff App API 대응 (Page 1597768061). Phase 2+ only. |

> **신규 엔티티 Phase 정책**: PayoutStructure는 Phase 1에서 읽기 전용 동기화, Staff는 Phase 2 GGPass 통합 이후 활성화. 상세: §14.

### 8.2 폴링 주기 조정 규칙

| 조건 | 조정 |
|------|------|
| Flight 상태가 `running` | Event, Player 폴링 주기 → 2분 (가속) |
| Flight 상태가 `completed` | 해당 Flight 폴링 중지 |
| WSOP LIVE 응답 지연 > 5초 | 폴링 주기 2배 증가 (백오프) |
| 연속 3회 실패 | 폴링 일시 중지 (5분 후 재시도) |

---

## 9. 데이터 매핑

### 9.1 Series 매핑

| WSOP LIVE 필드 | EBS 필드 | 변환 규칙 |
|---------------|----------|----------|
| `id` | — | EBS 내부 `series_id` 자동 생성 (WSOP ID는 별도 저장 안 함) |
| `name` | `series_name` | 그대로 |
| `year` | `year` | 그대로 |
| `begin_date` | `begin_at` | ISO 8601 → DATE 변환 |
| `end_date` | `end_at` | ISO 8601 → DATE 변환 |
| `image_url` | `image_url` | 그대로 |
| `timezone` | `time_zone` | IANA 시간대 문자열 |
| `currency` | `currency` | 기본 `USD` |
| `country` | `country_code` | ISO 3166 코드 변환 |
| — | `source` | `'api'` 고정 |
| — | `synced_at` | 동기화 시각 기록 |
| — | `competition_id` | WSOP LIVE 시리즈 → Competition 자동 매핑 |

### 9.2 Event 매핑

| WSOP LIVE 필드 | EBS 필드 | 변환 규칙 |
|---------------|----------|----------|
| `event_number` | `event_no` | 그대로 |
| `name` | `event_name` | 그대로 |
| `buy_in` | `buy_in` | 센트 → 정수 변환 (필요 시) |
| `display_buy_in` | `display_buy_in` | 그대로 (`"$10,000"`) |
| `game_type` | `game_type` | WSOP LIVE 게임 종류 → EBS enum 매핑 |
| `limit_type` | `bet_structure` | `NL`→0, `PL`→1, `FL`→2 |
| `table_size` | `table_size` | 그대로 (6/8/9/10) |
| `total_entries` | `total_entries` | 그대로 |
| `players_remaining` | `players_left` | 그대로 |
| `start_time` | `start_time` | ISO 8601 → DATETIME |
| `status` | `status` | WSOP LIVE 상태 → EBS 상태 매핑 (아래 참조) |
| — | `game_mode` | `'single'` 기본. Mix 이벤트는 수동 설정 |
| — | `source` | `'api'` 고정 |

**Event 상태 매핑:**

| WSOP LIVE 상태 | EBS 상태 | 설명 |
|---------------|---------|------|
| `scheduled` | `created` | 예정 |
| `registration_open` | `created` | EBS는 등록 미지원 → created 유지 |
| `in_progress` | `running` | 진행 중 |
| `completed` | `completed` | 완료 |
| `cancelled` | `cancelled` | 취소 |

### 9.3 Flight 매핑

| WSOP LIVE 필드 | EBS 필드 | 변환 규칙 |
|---------------|----------|----------|
| `name` | `display_name` | 그대로 (`"Day 1A"`) |
| `start_time` | `start_time` | ISO 8601 → DATETIME |
| `is_tbd` | `is_tbd` | 그대로 |
| `entries` | `entries` | 그대로 |
| `players_remaining` | `players_left` | 그대로 |
| `table_count` | `table_count` | 그대로 |
| `current_level` | `play_level` | 그대로 |
| `level_time_remaining` | `remain_time` | 초 단위 |
| — | `source` | `'api'` 고정 |

### 9.4 Player 매핑

| WSOP LIVE 필드 | EBS 필드 | 변환 규칙 |
|---------------|----------|----------|
| `id` | `wsop_id` | 문자열 변환 |
| `first_name` | `first_name` | 그대로 |
| `last_name` | `last_name` | 그대로 |
| `nationality` | `nationality` | 그대로 |
| `country_code` | `country_code` | ISO 3166 |
| `photo_url` | `profile_image` | 그대로 |
| — | `source` | `'api'` 고정 |

### 9.5 BlindStructure 매핑

| WSOP LIVE 필드 | EBS 필드 | 변환 규칙 |
|---------------|----------|----------|
| `structure_name` | `name` | 그대로 |
| `levels[].level` | `level_no` | 그대로 |
| `levels[].small_blind` | `small_blind` | 그대로 |
| `levels[].big_blind` | `big_blind` | 그대로 |
| `levels[].ante` | `ante` | 그대로 |
| `levels[].duration` | `duration_minutes` | 분 단위 |

### 9.6 대회 표시 상태 매핑 (WSOP LIVE 정합)

WSOP LIVE에서 동기화된 Flight 상태는 Backend 상태(6개)로 저장되며, UI 표시 상태는 `isRegisterable` 플래그와 Day 번호의 조합으로 결정된다.

**Backend 상태** (WSOP LIVE 동일): `Created`, `Announced`, `Registering`, `Running`, `Completed`, `Canceled`

**isRegisterable 플래그**: WSOP LIVE API에서 동기화. Flight 등록 가능 여부를 나타낸다.

| Backend 상태 | isRegisterable | Day | UI 표시 상태 | 설명 |
|-------------|:-:|:-:|---------|------|
| Created | F | * | Created | App에서 미노출 |
| Announced | F | 1 | Announced | 등록 전 공지 |
| Announced | F | 2+ | **Restricted** | Day2+ 등록 불가 |
| Registering | T | 1 | Registering | Day1 등록 가능 |
| Registering | T | 2+ | **Late Reg.** | Day2+ 등록 가능 |
| Registering | F | * | Registering | Staff만 등록 가능 |
| Running | T | * | **Late Reg.** | 시작 후 등록 가능 |
| Running | F | * | Running | 등록 마감 |
| Completed | * | * | Completed | Flight 종료 |
| Canceled | * | * | Canceled | Flight 취소 |

> **참조**: WSOP LIVE Tournament Status (Confluence page 1904542277)

### 9.7 wsop_id 매핑 전략 (신규 엔티티)

> **범위**: CCR-043 으로 추가된 PayoutStructure, Staff 엔티티에 한정. 기존 엔티티(Series/Event/Flight/BlindStructure)의 wsop_id 정책은 §9.1 "WSOP ID 별도 저장 안 함" 을 유지하며, Phase 2 시점에 전체 재정렬 검토.

| 엔티티 | 컬럼 | 근거 |
|--------|------|------|
| payout_structures | `wsop_id VARCHAR(64) UNIQUE NULL` | WSOP LIVE `PayoutStructure.id` 보존. 중복 동기화 차단. |
| users | `wsop_id VARCHAR(64) UNIQUE NULL` | WSOP LIVE `Staff.staffId` 보존. Phase 2 GGPass 연동 키. |
| players | `wsop_id VARCHAR(64)` | 기존 정의 유지 (DATA-04 §Player) |

**Phase별 값 정책**:
- Phase 1: NULL (EBS 로컬 생성)
- Phase 2+: WSOP 원본 ID 저장. UNIQUE 제약으로 중복 upsert 차단.

---

## 10. 충돌 해결

### 10.1 source 필드 기반 판단

모든 동기화 대상 엔티티는 `source` 필드를 가진다.

| source 값 | 의미 | 동기화 시 동작 |
|-----------|------|-------------|
| `api` | WSOP LIVE에서 자동 생성 | **덮어쓰기** — 최신 API 데이터로 갱신 |
| `manual` | Lobby에서 수동 생성 | **보존** — WSOP LIVE 동기화가 덮어쓰지 않음 |

### 10.2 충돌 시나리오

| 시나리오 | 처리 |
|---------|------|
| API 엔티티가 없는데 WSOP LIVE에 존재 | INSERT (source='api') |
| API 엔티티가 있고 WSOP LIVE에 변경 | UPDATE (source='api' 유지) |
| 수동 엔티티가 있고 WSOP LIVE에 동일 이름 | **수동 데이터 보존**. 중복 감지 시 감사 로그 기록 |
| WSOP LIVE에서 엔티티 삭제 | EBS에서 삭제하지 않음. `synced_at`이 갱신되지 않음으로 감지 |
| 수동 생성 후 나중에 API 연동 | `source='manual'` 유지. Admin이 명시적으로 API 소스로 전환 가능 |

### 10.3 필드별 병합 규칙

| 필드 유형 | source=api | source=manual |
|----------|-----------|-------------|
| 이름/날짜/상태 (WSOP LIVE 원천) | API 데이터 덮어쓰기 | 수동 데이터 보존 |
| EBS 전용 필드 (game_mode, rfid 등) | 보존 (API에 없으므로) | 보존 |
| 통계 필드 (total_entries, players_left) | API 데이터 덮어쓰기 | 수동 데이터 보존 |

---

## 11. Mock WSOP LIVE

개발/테스트 시 실제 WSOP LIVE API 없이 EBS를 운영하기 위한 Mock 모드.

### 11.1 Mock 모드 활성화

| 설정 | 값 | 위치 |
|------|------|------|
| `WSOP_LIVE_MOCK` | `true` / `false` | 환경 변수 또는 Config |
| `WSOP_LIVE_MOCK_DATA_DIR` | 디렉토리 경로 | Mock JSON 파일 위치 |

### 11.2 Mock 데이터 파일 구조

```
mock-data/wsop-live/
  ├── competitions.json
  ├── series.json
  ├── events.json
  ├── flights.json
  ├── players.json
  └── blind-structures.json
```

### 11.3 Mock 데이터 형식 (예: events.json)

```json
[
  {
    "event_number": 1,
    "name": "$10,000 NL Hold'em Championship",
    "buy_in": 1000000,
    "game_type": "NLH",
    "table_size": 9,
    "total_entries": 1000,
    "status": "in_progress"
  }
]
```

### 11.4 Mock vs Real 차이

| 항목 | Real 모드 | Mock 모드 |
|------|----------|----------|
| 데이터 소스 | WSOP LIVE HTTP API | 로컬 JSON 파일 |
| 네트워크 | 필요 | 불필요 |
| 폴링 | 주기적 HTTP 요청 | 파일 읽기 (변경 감지 없음) |
| 수동 동기화 | API 호출 | JSON 파일 재로드 |
| 에러 시뮬레이션 | — | JSON에 `_error` 필드 주입 가능 |

---

## 12. 장애 대응

### 12.1 연결 실패 시 동작

| 단계 | 조건 | BO 동작 | Lobby 영향 |
|:----:|------|--------|-----------|
| 1 | 단일 요청 타임아웃 (10초) | 재시도 (최대 3회, 지수 백오프) | 영향 없음 |
| 2 | 연속 3회 실패 | 해당 엔티티 폴링 일시 중지 (5분) | 감사 로그 + 알림 |
| 3 | 5분 후 재시도 실패 | 폴링 주기 30분으로 확대 | Lobby에 동기화 중단 배너 |
| 4 | 30분 이상 연결 불가 | 폴링 완전 중지, 수동 트리거만 허용 | 수동 운영 모드 전환 |

### 12.2 캐시 데이터 유지

API 연결 실패 시에도 **마지막 성공 동기화 데이터를 BO DB에 유지**한다. Lobby와 CC는 캐시된 데이터로 정상 운영한다.

| 항목 | 동작 |
|------|------|
| 읽기 | BO DB의 캐시 데이터 반환 (정상) |
| 쓰기 (수동) | 수동 생성/수정 가능 (source='manual') |
| 상태 표시 | Lobby에 마지막 동기화 시각 + 경고 배너 표시 |
| 복구 후 | 수동 동기화 트리거 권장. 자동 폴링 재개 |

### 12.3 데이터 정합성 검증

동기화 완료 시 다음 항목을 검증한다.

| 검증 | 설명 | 실패 시 |
|------|------|--------|
| 엔티티 수 비교 | API 응답 수 vs DB 수 | 차이 > 10% 시 감사 로그 |
| 필수 필드 | NOT NULL 필드에 null 값 | 해당 레코드 건너뜀 + 에러 로그 |
| FK 참조 | series_id, event_id 존재 여부 | 부모 없으면 해당 레코드 건너뜀 |
| 중복 검사 | wsop_id 기준 중복 Player | 기존 레코드 UPDATE |

---

## 13. WSOP LIVE API 인증 (TBD)

WSOP LIVE API 인증 방식은 계약에 따라 결정된다. 현재 가정:

| 항목 | 가정 |
|------|------|
| 인증 방식 | API Key (HTTP Header) |
| 헤더 | `X-API-Key: {wsop_live_api_key}` |
| Rate Limit | 분당 60회 (가정) |
| 키 저장 | 환경 변수 (`WSOP_LIVE_API_KEY`) |

> WSOP LIVE API 공식 문서가 확보되면 이 섹션을 업데이트한다.

### 13.1 GGPass External API S2S 인증 (Phase 2+)

> **근거**: WSOP LIVE GGPass External API (Confluence page 1975582764), API Headers 가이드 (Confluence page 1970962433). Phase 2 도입 시 §13 TBD 가정을 대체한다.

| 헤더 | 값 | 용도 |
|------|----|------|
| `X-API-KEY` | `{WSOP_API_KEY}` 환경변수 | 시스템(EBS) 인증 |
| `Z-Authorization` | `Bearer {JWT}` | 최종 사용자 컨텍스트 전달 |

**IP Whitelist**: WSOP LIVE 측은 환경별 IP whitelist 기반 접근 제어를 운영한다 (Test/Stage/Prod 분리). Phase 2 진입 전 EBS Prod IP를 WSOP 측에 사전 등록 필요.

**Rate Limit**: WSOP LIVE 공식 문서 미발견. Phase 2 계약 시 합의. 잠정값으로 §13 "분당 60회" 유지.

### 13.2 Phase 1 인증 (Mock 모드)

Phase 1은 Mock 모드(§11)로 운영하며 외부 호출 없음. `WSOP_LIVE_API_KEY` 환경변수는 Phase 2 진입 전까지 미설정 허용.

---

## 14. Phase별 통합 전략

| Phase | 기간 | 통합 방식 | 활성 엔티티 | 비고 |
|-------|------|----------|-------------|------|
| **Phase 1** | 2026 H2 | Mock seed (§11) | 전체 (mock 데이터) | 외부 API 접근 협상 전 |
| **Phase 2** | 2027 Q1 | GGPass S2S (§13.1) 계정/인증만 | Staff (users) | 조직 계정 sync, IP whitelist 확정 |
| **Phase 3** | 2027 Q2+ | Staff App API 읽기 전용 양방향 sync | 전체 | 토너먼트 데이터 통합 |

**Phase 전환 게이트**:
- Phase 1 → 2: WSOP 측 IP whitelist 등록 + `WSOP_API_KEY` 발급 + 계약 체결
- Phase 2 → 3: Staff App API 접근 승인 + Rate Limit 합의 + sync_conflicts 운영 경험 축적

---

## 15. sync_conflicts 감사 테이블

§10 충돌 해결의 감사 증적을 남기기 위한 전용 테이블.

**스키마** (상세 DDL은 DATA-04 CCR 후속):

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `conflict_id` | INTEGER PK | |
| `entity_table` | VARCHAR(64) | `series` / `events` / `event_flights` / `players` / `payout_structures` / `users` |
| `entity_id` | INTEGER | EBS 로컬 PK |
| `wsop_id` | VARCHAR(64) NULL | 원본 WSOP 식별자 (신규 엔티티에 한정) |
| `wsop_value` | JSON | 동기화 시점 WSOP 응답 스냅샷 |
| `ebs_value` | JSON | 덮어쓰기 전 EBS 값 스냅샷 |
| `resolution` | VARCHAR(16) | `wsop_wins` / `ebs_wins` / `pending` |
| `resolved_by` | INTEGER FK users | Admin 수동 해결 시 |
| `resolved_at` | TIMESTAMP NULL | |
| `created_at` | TIMESTAMP | |

**충돌 기록 조건** (§10.2 시나리오 중):
- 수동 엔티티가 있고 WSOP LIVE에 동일 이름 → 보존 + conflict 기록 (`resolution='ebs_wins'`)
- `source='manual'` + `manual_override=false` 인 엔티티에 WSOP 값이 덮어씀 → 덮어쓴 뒤 conflict 기록 (`resolution='wsop_wins'`)
- FK 부모 없음으로 건너뛴 레코드 → `resolution='pending'` 기록 후 Admin 수동 해결 대기

**조회 엔드포인트**: `GET /api/v1/sync/conflicts?entity_table=&resolution=` — §5.16 참조. Sprint 3 S3-03 에서 구현.

---

## 16. SG-008 b-분류 결정 스펙 (2026-04-20)

SG-008 Spec Drift Triage 에서 b-분류(설계 결정 필요)로 승격된 12개 항목의 결정 결과와 각 엔드포인트의 최종 스펙. `SG-008-bN-*.md` 파일과 1:1 매핑.

### 16.1 결정 요약

| SG | 엔드포인트 | 결정 | 반영 위치 |
|----|-----------|:----:|-----------|
| b1 | `GET /audit-events` | 옵션 1 (Admin-only public) | §16.2 |
| b2 | `GET /audit-logs` | 옵션 1 (Admin-only, filter) | §16.3 |
| b3 | `GET /audit-logs/download` | 옵션 1 (Admin-only CSV stream) | §16.4 |
| b4 | `GET /auth/me` | 옵션 1 (모든 인증 사용자) | §16.5 |
| b5 | `POST /auth/logout` | 옵션 1 (JWT 블랙리스트) | §16.6 |
| b6 | `POST /sync/mock-seed` | 옵션 1 (Admin, dev/test profile 한정) | §16.7 |
| b7 | `POST /sync/mock-reset` | 옵션 1 (Admin, dev/test profile 한정) | §16.8 |
| b8 | `GET /sync/status` | 옵션 1 (Admin, last-sync + conflicts_pending) | §16.9 |
| b9 | `POST /sync/trigger` | 옵션 1 (Admin, scope 파라미터) | §16.10 |
| b10 | `POST /events/{event_id}/undo` | 옵션 3 (삭제, Phase 1 미지원) | §16.11 |
| b11 | `POST /tables/{table_id}/launch-cc` | 옵션 1 (deep-link 전환, 삭제) | §5.4 |
| b12 | `GET /reports/{report_type}` (legacy) | 옵션 1 (삭제, SG-007 6-endpoint 대체) | §5.15 |

### 16.2 GET /audit-events (b1)

| 항목 | 값 |
|------|-----|
| Method / Path | `GET /api/v1/audit-events` |
| Auth | 필수 (JWT Bearer) |
| RBAC | Admin only |
| Query | `table_id` (optional), `correlation_id` (optional), `since` (seq, default 0), `limit` (1..2000, default 100) |
| Response | `{ data: AuditEvent[], meta: { since, limit, count } }` |

WSOP LIVE Confluence `SignalR Service §AuditLog` 패턴 정렬. 근거: SG-008-b1.

### 16.3 GET /audit-logs (b2)

| 항목 | 값 |
|------|-----|
| Method / Path | `GET /api/v1/audit-logs` |
| Auth | 필수 |
| RBAC | Admin only |
| Query | `user_id` (optional), `entity_type` (optional), `skip` (default 0), `limit` (1..100, default 20) |
| Response | `{ data: AuditLog[], meta: { skip, limit, total } }` |

관리자 작업 로그 (admin action 감사). 근거: SG-008-b2.

### 16.4 GET /audit-logs/download (b3)

| 항목 | 값 |
|------|-----|
| Method / Path | `GET /api/v1/audit-logs/download` |
| Auth | 필수 |
| RBAC | Admin only |
| Response | `text/csv` streaming (Content-Disposition: attachment; filename=audit_logs.csv) |

CSV 컬럼: `id, user_id, entity_type, entity_id, action, detail, ip_address, created_at`. 근거: SG-008-b3.

### 16.5 GET /auth/me (b4)

| 항목 | 값 |
|------|-----|
| Method / Path | `GET /api/v1/auth/me` |
| Auth | 필수 (JWT Bearer) |
| RBAC | 모든 인증 사용자 (Admin/Operator/Viewer) |
| Response | `{ user_id, email, role, display_name, is_active, assigned_tables? }` |

JWT decode → user 레코드 조회. 근거: SG-008-b4. WSOP LIVE `Staff App §Me` 동등.

### 16.6 POST /auth/logout (b5)

| 항목 | 값 |
|------|-----|
| Method / Path | `POST /api/v1/auth/logout` |
| Auth | 필수 |
| RBAC | 모든 인증 사용자 |
| Body | 없음 (Bearer token 에서 jti 추출) |
| Response | `204 No Content` |

서버 측: JWT `jti` 를 블랙리스트 (Redis TTL = 토큰 남은 수명) 등록. `get_current_user` 에서 매 요청 jti 체크. 근거: SG-008-b5.

### 16.7 POST /sync/mock-seed (b6)

| 항목 | 값 |
|------|-----|
| Method / Path | `POST /api/v1/sync/mock-seed` |
| Auth | 필수 |
| RBAC | Admin only |
| Profile gate | `settings.auth_profile in ('dev', 'test')` — prod 에서는 `405 METHOD_NOT_ALLOWED_IN_PROFILE` |
| Body | `{ "fixture": "wsop-basic" \| "wsop-mix-game" \| "empty" }` |
| Response | `202 Accepted` + `{ seeded: { series, events, players, ... } }` |

WSOP LIVE mock fixture 로 DB 시드. `test_wsop_sync_fixtures.py` 와 동일 fixture 재사용. 근거: SG-008-b6.

### 16.8 POST /sync/mock-reset (b7)

| 항목 | 값 |
|------|-----|
| Method / Path | `POST /api/v1/sync/mock-reset` |
| Auth | 필수 |
| RBAC | Admin only |
| Profile gate | `settings.auth_profile in ('dev', 'test')` |
| Body | 없음 |
| Response | `204 No Content` |

mock-seed 로 생성된 레코드를 모두 삭제 (truncate `series`, `events`, `event_flights`, `players` where `source='wsop_mock'`). 근거: SG-008-b7.

### 16.9 GET /sync/status (b8)

| 항목 | 값 |
|------|-----|
| Method / Path | `GET /api/v1/sync/status` |
| Auth | 필수 |
| RBAC | Admin only |
| Response | `{ last_sync: { sync_id, scope, status, completed_at }, conflicts_pending: int, circuit_breaker: { state, failure_count } }` |

`/api/v1/sync/wsop-live/status` 와 중복되지 않는 점: 본 엔드포인트는 **aggregate 현황** (마지막 성공 + 충돌 + CB 상태), 후자는 특정 sync_id 진행 상태. 근거: SG-008-b8.

### 16.10 POST /sync/trigger (b9)

| 항목 | 값 |
|------|-----|
| Method / Path | `POST /api/v1/sync/trigger` |
| Auth | 필수 |
| RBAC | Admin only |
| Body | `{ "scope": "all" \| "series" \| "events" \| "players" \| "blinds" }` |
| Response | `202 Accepted` + `{ sync_id, scope, status: "started", started_at }` |

`/api/v1/sync/wsop-live` (§5.16) 와 기능 동일. 본 엔드포인트는 flat alias — 기존 `sync/wsop-live` 가 vendor-specific (WSOP) 네이밍이라면 `sync/trigger` 는 일반 sync 추상화. 정렬 진행 중 (Phase 2+에서 단일화 예정). 근거: SG-008-b9.

### 16.11 POST /events/{event_id}/undo (b10) — 삭제됨

> **SG-008-b10 결정 (2026-04-20, 옵션 3 채택)**: Phase 1 미지원. 엔드포인트 + 테스트 (test_undo.py) 제거 완료.
>
> **이유**: Undo 는 단순 기능이 아닌 **설계 철학 결정** (append-only vs mutable state). Event Sourcing 기반 `audit_events` (DATA-04) 는 append-only 이므로 undo = compensating event 필요. 이 규약 설계는 Phase 2+ 재도입 시 SG-008-b10 재오픈 + 옵션 1 기반 설계. Operator 실수 복구는 Phase 1 에서는 "다음 이벤트로 보정" 로 대체 가능.
>
> 참조: WSOP LIVE `Staff App` 은 Undo 를 Operator UI-local 상태로만 구현, 서버 이벤트 무효화 없음.
