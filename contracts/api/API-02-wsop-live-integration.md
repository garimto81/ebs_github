# API-02 WSOP LIVE Integration — 외부 API 연동 계약

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | WSOP LIVE Staff Page API 연동 방식, 데이터 매핑, 충돌 해결, Mock 모드 |
| 2026-04-13 | WSOP LIVE 정합성 수정 | isRegisterable 플래그 도입, 표시 상태 매핑 (Restricted/Late Reg) 추가, Announce→Announced |

---

## 개요

이 문서는 **WSOP LIVE Staff Page API와 EBS Back Office(BO) 간의 연동 계약**을 정의한다. WSOP LIVE는 대회 계층(Series/Event/Flight)과 플레이어/블라인드 데이터의 원천이며, EBS BO는 이를 폴링하여 로컬 DB에 캐싱한다.

> **참조**: 엔티티 필드 정의는 `DATA-02-entities.md`, Lobby CRUD 요구사항은 `BS-02-lobby.md`, BO 전체 범위는 `BO-01-overview.md`

### 설계 원칙

| 원칙 | 설명 |
|------|------|
| **폴링 기반** | WSOP LIVE가 Push(Webhook)를 지원하지 않는다고 가정. BO가 주기적으로 Pull |
| **캐싱 우선** | WSOP LIVE 데이터를 BO DB에 캐싱. 클라이언트는 항상 BO DB를 읽음 |
| **source 필드** | 모든 엔티티에 `source` 필드로 데이터 출처 구분 (`api` / `manual`) |
| **독립 운영** | API 연동 실패 시에도 수동 입력으로 EBS 단독 운영 가능 |

---

## 1. 연동 아키텍처

### 1.1 데이터 흐름

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

### 1.2 Sync Worker 위치

Sync Worker는 BO FastAPI 서버 내 **백그라운드 태스크**로 실행된다. 별도 프로세스가 아님.

| 항목 | 값 |
|------|------|
| 실행 방식 | FastAPI `BackgroundTasks` 또는 APScheduler |
| 시작 조건 | BO 서버 시작 시 자동 시작 |
| 중지 조건 | BO 서버 종료 시 자동 종료 |
| 수동 트리거 | `POST /api/v1/sync/wsop-live` |

---

## 2. 동기화 대상 엔티티

### 2.1 엔티티별 폴링 설정

| 엔티티 | WSOP LIVE 엔드포인트 | 폴링 주기 | EBS 테이블 | 비고 |
|--------|---------------------|:---------:|-----------|------|
| **Competition** | `GET /competitions` | 24시간 | `competitions` | 변경 빈도 매우 낮음 |
| **Series** | `GET /series` | 1시간 | `series` | 시즌 초 1회 생성, 이후 변경 드뭄 |
| **Event** | `GET /series/:id/events` | 5분 | `events` | 상태 변경(created→running→completed) 추적 |
| **Flight** | `GET /events/:id/flights` | 5분 | `event_flights` | Event와 동일 주기 |
| **Player** | `GET /events/:id/players` | 10분 | `players` | 좌석 변경, 탈락 반영 |
| **BlindStructure** | `GET /events/:id/blind-structure` | 30분 | `blind_structures` + `blind_structure_levels` | 대회 중 변경 거의 없음 |

### 2.2 폴링 주기 조정 규칙

| 조건 | 조정 |
|------|------|
| Flight 상태가 `running` | Event, Player 폴링 주기 → 2분 (가속) |
| Flight 상태가 `completed` | 해당 Flight 폴링 중지 |
| WSOP LIVE 응답 지연 > 5초 | 폴링 주기 2배 증가 (백오프) |
| 연속 3회 실패 | 폴링 일시 중지 (5분 후 재시도) |

---

## 3. 데이터 매핑

### 3.1 Series 매핑

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

### 3.2 Event 매핑

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

### 3.3 Flight 매핑

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

### 3.4 Player 매핑

| WSOP LIVE 필드 | EBS 필드 | 변환 규칙 |
|---------------|----------|----------|
| `id` | `wsop_id` | 문자열 변환 |
| `first_name` | `first_name` | 그대로 |
| `last_name` | `last_name` | 그대로 |
| `nationality` | `nationality` | 그대로 |
| `country_code` | `country_code` | ISO 3166 |
| `photo_url` | `profile_image` | 그대로 |
| — | `source` | `'api'` 고정 |

### 3.5 BlindStructure 매핑

| WSOP LIVE 필드 | EBS 필드 | 변환 규칙 |
|---------------|----------|----------|
| `structure_name` | `name` | 그대로 |
| `levels[].level` | `level_no` | 그대로 |
| `levels[].small_blind` | `small_blind` | 그대로 |
| `levels[].big_blind` | `big_blind` | 그대로 |
| `levels[].ante` | `ante` | 그대로 |
| `levels[].duration` | `duration_minutes` | 분 단위 |

### 3.6 대회 표시 상태 매핑 (WSOP LIVE 정합)

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

---

## 4. 충돌 해결

### 4.1 source 필드 기반 판단

모든 동기화 대상 엔티티는 `source` 필드를 가진다.

| source 값 | 의미 | 동기화 시 동작 |
|-----------|------|-------------|
| `api` | WSOP LIVE에서 자동 생성 | **덮어쓰기** — 최신 API 데이터로 갱신 |
| `manual` | Lobby에서 수동 생성 | **보존** — WSOP LIVE 동기화가 덮어쓰지 않음 |

### 4.2 충돌 시나리오

| 시나리오 | 처리 |
|---------|------|
| API 엔티티가 없는데 WSOP LIVE에 존재 | INSERT (source='api') |
| API 엔티티가 있고 WSOP LIVE에 변경 | UPDATE (source='api' 유지) |
| 수동 엔티티가 있고 WSOP LIVE에 동일 이름 | **수동 데이터 보존**. 중복 감지 시 감사 로그 기록 |
| WSOP LIVE에서 엔티티 삭제 | EBS에서 삭제하지 않음. `synced_at`이 갱신되지 않음으로 감지 |
| 수동 생성 후 나중에 API 연동 | `source='manual'` 유지. Admin이 명시적으로 API 소스로 전환 가능 |

### 4.3 필드별 병합 규칙

| 필드 유형 | source=api | source=manual |
|----------|-----------|-------------|
| 이름/날짜/상태 (WSOP LIVE 원천) | API 데이터 덮어쓰기 | 수동 데이터 보존 |
| EBS 전용 필드 (game_mode, rfid 등) | 보존 (API에 없으므로) | 보존 |
| 통계 필드 (total_entries, players_left) | API 데이터 덮어쓰기 | 수동 데이터 보존 |

---

## 5. 동기화 API

### 5.1 수동 동기화 트리거

**POST /api/v1/sync/wsop-live**

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

### 5.2 동기화 상태 확인

**GET /api/v1/sync/wsop-live/status**

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

---

## 6. Mock WSOP LIVE

개발/테스트 시 실제 WSOP LIVE API 없이 EBS를 운영하기 위한 Mock 모드.

### 6.1 Mock 모드 활성화

| 설정 | 값 | 위치 |
|------|------|------|
| `WSOP_LIVE_MOCK` | `true` / `false` | 환경 변수 또는 Config |
| `WSOP_LIVE_MOCK_DATA_DIR` | 디렉토리 경로 | Mock JSON 파일 위치 |

### 6.2 Mock 데이터 파일 구조

```
mock-data/wsop-live/
  ├── competitions.json
  ├── series.json
  ├── events.json
  ├── flights.json
  ├── players.json
  └── blind-structures.json
```

### 6.3 Mock 데이터 형식 (예: events.json)

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

### 6.4 Mock vs Real 차이

| 항목 | Real 모드 | Mock 모드 |
|------|----------|----------|
| 데이터 소스 | WSOP LIVE HTTP API | 로컬 JSON 파일 |
| 네트워크 | 필요 | 불필요 |
| 폴링 | 주기적 HTTP 요청 | 파일 읽기 (변경 감지 없음) |
| 수동 동기화 | API 호출 | JSON 파일 재로드 |
| 에러 시뮬레이션 | — | JSON에 `_error` 필드 주입 가능 |

---

## 7. 장애 대응

### 7.1 연결 실패 시 동작

| 단계 | 조건 | BO 동작 | Lobby 영향 |
|:----:|------|--------|-----------|
| 1 | 단일 요청 타임아웃 (10초) | 재시도 (최대 3회, 지수 백오프) | 영향 없음 |
| 2 | 연속 3회 실패 | 해당 엔티티 폴링 일시 중지 (5분) | 감사 로그 + 알림 |
| 3 | 5분 후 재시도 실패 | 폴링 주기 30분으로 확대 | Lobby에 동기화 중단 배너 |
| 4 | 30분 이상 연결 불가 | 폴링 완전 중지, 수동 트리거만 허용 | 수동 운영 모드 전환 |

### 7.2 캐시 데이터 유지

API 연결 실패 시에도 **마지막 성공 동기화 데이터를 BO DB에 유지**한다. Lobby와 CC는 캐시된 데이터로 정상 운영한다.

| 항목 | 동작 |
|------|------|
| 읽기 | BO DB의 캐시 데이터 반환 (정상) |
| 쓰기 (수동) | 수동 생성/수정 가능 (source='manual') |
| 상태 표시 | Lobby에 마지막 동기화 시각 + 경고 배너 표시 |
| 복구 후 | 수동 동기화 트리거 권장. 자동 폴링 재개 |

### 7.3 데이터 정합성 검증

동기화 완료 시 다음 항목을 검증한다.

| 검증 | 설명 | 실패 시 |
|------|------|--------|
| 엔티티 수 비교 | API 응답 수 vs DB 수 | 차이 > 10% 시 감사 로그 |
| 필수 필드 | NOT NULL 필드에 null 값 | 해당 레코드 건너뜀 + 에러 로그 |
| FK 참조 | series_id, event_id 존재 여부 | 부모 없으면 해당 레코드 건너뜀 |
| 중복 검사 | wsop_id 기준 중복 Player | 기존 레코드 UPDATE |

---

## 8. WSOP LIVE API 인증 (TBD)

WSOP LIVE API 인증 방식은 계약에 따라 결정된다. 현재 가정:

| 항목 | 가정 |
|------|------|
| 인증 방식 | API Key (HTTP Header) |
| 헤더 | `X-API-Key: {wsop_live_api_key}` |
| Rate Limit | 분당 60회 (가정) |
| 키 저장 | 환경 변수 (`WSOP_LIVE_API_KEY`) |

> WSOP LIVE API 공식 문서가 확보되면 이 섹션을 업데이트한다.
