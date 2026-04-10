# API-01 Backend Endpoints — BO REST API 전체 카탈로그

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | FastAPI 백엔드 REST API 전체 엔드포인트 카탈로그 |
| 2026-04-09 | Skin API 추가 | skin CRUD + upload/download/activate/duplicate 9개 엔드포인트 |

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
| `INTERNAL_ERROR` | 500 | 서버 내부 오류 |

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
    "launched_at": "2026-04-08T12:00:00Z"
  },
  "error": null
}
```

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
| Tables | 3 | 2 | 1 | 1 | 7 |
| Seats | 1 | — | 1 | — | 2 |
| Players | 3 | 1 | 1 | 1 | 6 |
| Hands | 4 | — | — | — | 4 |
| Configs | 1 | — | 1 | — | 2 |
| Skins | 3 | 4 | 1 | 1 | 9 |
| BlindStructures | 2 | 1 | 1 | 1 | 5 |
| AuditLogs | 1 | — | — | — | 1 |
| Reports | 1 | — | — | — | 1 |
| Sync | 1 | 1 | — | — | 2 |
| **합계** | **32** | **18** | **10** | **9** | **69** |
