# API-01 Backend Endpoints — BO REST API 전체 카탈로그

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | FastAPI 백엔드 REST API 전체 엔드포인트 카탈로그 |
| 2026-04-09 | Skin API 추가 | skin CRUD + upload/download/activate/duplicate 9개 엔드포인트 |
| 2026-04-10 | CCR-003 | 모든 mutation API에 `Idempotency-Key` 헤더 표준 도입 + 멱등성 응답 계약 |
| 2026-04-10 | CCR-010 | `POST /tables/rebalance` 응답에 saga 구조(`saga_id`, `steps`, 207/500) 추가 |
| 2026-04-10 | CCR-015 | `GET /tables/{table_id}/events` replay 엔드포인트 신설 (WebSocket seq gap 복구) |

---

## 개요

이 문서는 EBS Back Office(BO) FastAPI 서버의 **REST API 전체 엔드포인트 카탈로그**를 정의한다. Lobby(웹)와 CC(Flutter)는 이 API를 통해 BO DB와 데이터를 주고받는다.

> **참조**: 인증 API 상세는 `API-06-auth-session.md`, WebSocket 이벤트는 `API-05-websocket-events.md`, 엔티티 필드 정의는 `DATA-02-entities.md`

### 설계 원칙

| 원칙 | 설명 |
|------|------|
| **RESTful** | 리소스 중심 URL, HTTP 메서드로 CRUD 매핑 |
| **JSON** | Request/Response 모두 `application/json` |
| **JWT 인증** | 모든 요청에 `Authorization: Bearer {token}` 헤더 필수 (인증 API 제외) |
| **RBAC** | 역할(Admin/Operator/Viewer)에 따라 접근 제한 |
| **일관된 응답** | 모든 응답은 공통 포맷 준수 |

---

## 1. Base URL

```
http://{bo_host}:{bo_port}/api/v1
```

| 환경 | Host | Port |
|------|------|:----:|
| 개발 | `localhost` | 8000 |
| 테스트 | `192.168.x.x` | 8000 |
| 프로덕션 | TBD | 443 (HTTPS) |

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

> 상세: `API-06-auth-session.md`

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| POST | `/auth/login` | 로그인 (토큰 발급) | 없음 |
| POST | `/auth/refresh` | Access Token 갱신 | 없음 |
| GET | `/auth/session` | 현재 세션 정보 | 인증 사용자 |
| DELETE | `/auth/session` | 로그아웃 | 인증 사용자 |
| POST | `/auth/verify-2fa` | 2FA TOTP 검증 | 없음 |
| POST | `/auth/2fa/setup` | 2FA 초기 설정 | 인증 사용자 |
| POST | `/auth/2fa/disable` | 2FA 비활성화 | Admin |

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

### 5.6 Flights — Flight

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| GET | `/flights` | Flight 목록 (이벤트 필터: `?event_id=`) | 인증 사용자 |
| GET | `/flights/:id` | Flight 상세 | 인증 사용자 |
| POST | `/flights` | Flight 생성 | Admin |
| PUT | `/flights/:id` | Flight 수정 | Admin |
| DELETE | `/flights/:id` | Flight 삭제 | Admin |

### 5.7 Tables — 테이블

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| GET | `/tables` | 테이블 목록 (Flight 필터: `?flight_id=`) | 인증 사용자 |
| GET | `/tables/:id` | 테이블 상세 | 인증 사용자 (Operator: 할당만) |
| POST | `/tables` | 테이블 생성 | Admin |
| PUT | `/tables/:id` | 테이블 수정 | Admin |
| DELETE | `/tables/:id` | 테이블 삭제 | Admin |
| POST | `/tables/:id/launch-cc` | CC 인스턴스 Launch | Admin |
| GET | `/tables/:id/status` | 테이블 실시간 상태 | 인증 사용자 |
| POST | `/tables/rebalance` | 다중 테이블 플레이어 재배치 (saga) | Admin |
| GET | `/tables/:id/events` | WebSocket 재연결 후 누락 이벤트 replay | Admin, Operator(할당), Viewer |

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

**POST /tables/:id/launch-cc — Response (200 OK):**

```json
{
  "data": {
    "table_id": 1,
    "status": "live",
    "cc_instance_id": "cc-uuid-abcd",
    "launch_token": "eyJhbGc...",
    "ws_url": "ws://host/ws/cc?table_id=1",
    "launched_at": "2026-04-08T12:00:00Z"
  },
  "error": null
}
```

> **CCR-029**: Launch 응답에는 `cc_instance_id` + `launch_token` (JWT 5분 수명) + `ws_url`이 반드시 포함된다. Lobby는 이 정보를 shell command/deep link 인자로 전달해 Flutter CC 앱을 실행하고, CC는 `ws_url?token={launch_token}&cc_instance_id={uuid}`로 WebSocket 연결한다. Launch 시퀀스 상세는 `BS-05-00 §7` 참조.

**Launch 검증 절차 (서버)**:
1. JWT 인증 (role = Admin 또는 Operator)
2. RBAC — Operator면 `assigned_tables`에 `table_id` 포함
3. TableFSM 확인 — SETUP 이상
4. `cc_session` record 생성 + `cc_instance_id` 할당
5. `launch_token` 발급 (sub = `cc_instance_id`, exp = 현재 + 5분)
6. WebSocket 연결 시 token 검증 + `cc_instance_id` 매칭

---

#### POST /tables/rebalance (CCR-010 — Saga)

**용도**: 여러 테이블 간 플레이어 재배치. WSOP `Tables API.md`의 다단계 연산(seat release → seat assign → chip move → WSOP LIVE notify)을 saga 패턴으로 가시화하고, 부분 실패 시 compensating action으로 일관성을 복원한다.

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
        "payload": { "seat": 3, "player_id": "p-123" }
      }
    ],
    "last_seq": 12500,
    "has_more": false
  },
  "error": null
}
```

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

### 5.13 BlindStructures — 블라인드 구조

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| GET | `/blind-structures` | 블라인드 구조 목록 | 인증 사용자 |
| GET | `/blind-structures/:id` | 블라인드 구조 상세 (레벨 포함) | 인증 사용자 |
| POST | `/blind-structures` | 블라인드 구조 생성 | Admin |
| PUT | `/blind-structures/:id` | 블라인드 구조 수정 | Admin |
| DELETE | `/blind-structures/:id` | 블라인드 구조 삭제 | Admin |

**POST /blind-structures — Request:**

```json
{
  "name": "Standard NLH Structure",
  "levels": [
    { "level_no": 1, "small_blind": 100, "big_blind": 200, "ante": 0, "duration_minutes": 60 },
    { "level_no": 2, "small_blind": 200, "big_blind": 400, "ante": 50, "duration_minutes": 60 },
    { "level_no": 3, "small_blind": 300, "big_blind": 600, "ante": 100, "duration_minutes": 60 }
  ]
}
```

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

### 5.15 Reports — 리포트

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| GET | `/reports/:type` | 리포트 조회 | Admin |

**type 값:**

| type | 설명 | 필터 파라미터 |
|------|------|-------------|
| `hands-summary` | 핸드 통계 요약 | `?table_id=`, `?event_id=` |
| `player-stats` | 플레이어 통계 (VPIP, PFR, AGR) | `?player_id=`, `?event_id=` |
| `table-activity` | 테이블 활동 이력 | `?flight_id=`, `?from=`, `?to=` |
| `session-log` | 사용자 세션 이력 | `?user_id=`, `?from=`, `?to=` |

### 5.16 WSOP LIVE Sync — 외부 동기화

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| POST | `/sync/wsop-live` | WSOP LIVE 수동 동기화 트리거 | Admin |
| GET | `/sync/wsop-live/status` | 동기화 상태 확인 | Admin |

> 상세: `API-02-wsop-live-integration.md`

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
| Sync | 1 | 1 | — | — | 2 |
| **합계** | **33** | **19** | **10** | **9** | **71** |
