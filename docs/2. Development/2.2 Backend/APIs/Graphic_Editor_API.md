---
title: Graphic Editor API
owner: team2
tier: internal
legacy-id: API-07
last-updated: 2026-04-15
---

# API-07 Graphic Editor Endpoints

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-11 | 신규 작성 | 8 엔드포인트 + Idempotency-Key + If-Match ETag + X-Game-State (CCR-013) |

---

## 개요

Team 1 Lobby의 Graphic Editor 탭이 사용하는 BO REST API. Team 2 FastAPI 서비스가 구현한다. `.gfskin` 스킨 업로드·조회·메타데이터 편집·Activate·삭제를 커버한다.

**연관 문서**:
- `contracts/data/DATA-07-gfskin-schema.md` — 요청/응답 body 스키마
- `contracts/api/API-06-auth-session.md` — JWT + RBAC
- `team1-frontend/specs/BS-08-graphic-editor/` — 클라이언트 FSM + 요구사항 (CCR-056: team-policy v4 이관)
- `CCR-003` — Idempotency 헤더 정책
- `CCR-015` — WebSocket seq 단조증가

**공통 헤더**:
- `Authorization: Bearer {jwt}` (모든 요청)
- `Idempotency-Key: {uuid4}` (mutation 요청 필수, CCR-003)
- `If-Match: W/"{etag}"` (PATCH/PUT/DELETE 필수)
- `X-Game-State: IDLE | RUNNING` (Activate 전용)

---

## 1. POST /api/v1/skins — Upload `.gfskin`

### 요청

- **Method**: `POST`
- **Content-Type**: `multipart/form-data`
- **Headers**:
  - `Authorization: Bearer {admin_jwt}`
  - `Idempotency-Key: {uuid4}` (필수)
- **Body**:
  - `file`: `.gfskin` ZIP (필수)
  - `name`: 선택 override (form field, `skin.json` 내 이름 덮어쓰기)

### 응답

**201 Created**
```json
{
  "id": "sk_01HVQK...",
  "version": 1,
  "etag": "W/\"1-abc...\"",
  "url": "/api/v1/skins/sk_01HVQK..."
}
```

**409 Conflict** — 동일 `Idempotency-Key` 재사용 (CCR-003)
```json
{ "error": "IDEMPOTENCY_KEY_REUSED", "original_request_id": "..." }
```

**422 Unprocessable Entity** — JSON Schema 검증 실패
```json
{
  "error": "SCHEMA_VIOLATION",
  "path": "colors.badge_check",
  "message": "Pattern mismatch: expected ^#[0-9A-Fa-f]{6}$"
}
```

**403 Forbidden** — Admin 권한 부족 (GER-04)

**413 Payload Too Large** — 파일 크기 초과 (50MB 기준)

### 부수 효과

- 서버는 `skin.json` + `skin.riv` 검증 후 DB에 스킨 row 생성
- 원본 `.gfskin` 바이트를 object storage 또는 filesystem에 저장
- `audit_events` 테이블에 `skin_uploaded` 기록

---

## 2. GET /api/v1/skins — List

### 요청

- **Query**: `?limit=20&offset=0&sort=-modified_at`
- **Headers**: `Authorization: Bearer {jwt}` (Admin 또는 Operator)

### 응답

**200 OK**
```json
{
  "items": [
    {
      "id": "sk_01HVQK...",
      "skin_name": "wsop-2026-default",
      "version": "1.0.0",
      "author": "EBS Design Team",
      "modified_at": "2026-04-10T12:00:00Z",
      "is_active": true
    }
  ],
  "total": 42,
  "limit": 20,
  "offset": 0
}
```

---

## 3. GET /api/v1/skins/{id} — Download `.gfskin` bytes

### 요청

- **Path**: `{id}` = skin id
- **Headers**: `Authorization: Bearer {jwt}` (Admin, Operator, CC service account)

### 응답

**200 OK**
- `Content-Type: application/octet-stream`
- `Content-Disposition: attachment; filename="my-skin.gfskin"`
- Body: `.gfskin` 원본 ZIP 바이너리

**404 Not Found** — skin id 없음

---

## 4. GET /api/v1/skins/{id}/metadata — Read `skin.json`

### 요청

- **Headers**: `Authorization: Bearer {jwt}`

### 응답

**200 OK**
- `Content-Type: application/json`
- `ETag: W/"3-xyz..."` (현재 버전 ETag)
- Body: `skin.json` 전체 (파싱 편의 — 클라이언트가 ZIP 해제 불필요)

```json
{
  "skin_name": "wsop-2026-default",
  "version": "1.0.0",
  "resolution": { "width": 1920, "height": 1080 },
  "colors": { "badge_check": "#00FF00", "..." },
  "fonts": { "pot": { "family": "Inter", "size": 48 } },
  "animations": { "card_fade_duration_ms": 300, "..." }
}
```

---

## 5. PATCH /api/v1/skins/{id}/metadata — Update metadata

### 요청

- **Content-Type**: `application/merge-patch+json` (RFC 7396)
- **Headers**:
  - `Authorization: Bearer {admin_jwt}`
  - `If-Match: W/"{etag}"` (필수)
- **Body**: JSON Merge Patch — 변경된 필드만
```json
{
  "colors": { "badge_check": "#00FF00" },
  "fonts": { "pot": { "size": 48 } }
}
```

### 응답

**200 OK**
- `ETag: W/"{new_etag}"`
- Body: 갱신된 `skin.json` 전체

**412 Precondition Failed** — ETag 충돌
```json
{
  "error": "ETAG_MISMATCH",
  "current_etag": "W/\"5-...\"",
  "message": "다른 세션이 먼저 수정했습니다. refetch 후 재시도하세요."
}
```

**422 Unprocessable Entity** — 서버 JSON Schema 재검증 실패

**403 Forbidden** — Admin 아님

---

## 6. PUT /api/v1/skins/{id}/activate — Activate + Broadcast

### 요청

- **Headers**:
  - `Authorization: Bearer {admin_jwt}`
  - `If-Match: W/"{etag}"` (필수)
  - `X-Game-State: IDLE | RUNNING` (필수, 클라이언트 자체 보고)
  - `Idempotency-Key: {uuid4}` (필수)

### 응답

**201 Created**
```json
{
  "active_skin_id": "sk_01HVQK...",
  "seq": 42,
  "broadcasted_at": "2026-04-11T10:30:00Z"
}
```

- `seq`: 단조증가 (CCR-015). Overlay replay 기준.
- `broadcasted_at`: 서버 시각.

**409 Conflict + Warning 헤더** — 서버 판단 GameState==RUNNING + 클라 선언 IDLE 불일치
```
HTTP/1.1 409 Conflict
Warning: 199 - "GameState mismatch: server=RUNNING, client=IDLE"

{
  "error": "GAME_STATE_MISMATCH",
  "server_state": "RUNNING",
  "client_state": "IDLE"
}
```

**412 Precondition Failed** — ETag 충돌

**403 Forbidden** — Admin 아님

### 부수 효과

- DB: `active_skin_id = {id}` 갱신
- WebSocket broadcast: `{type: "skin_updated", seq, payload: {skin_id, version, transition_type}}` (API-05 상세)
- `audit_events`: `skin_activated` 기록

---

## 7. GET /api/v1/skins/active — Current active skin

### 요청

- **Headers**: `Authorization: Bearer {jwt}` (Admin, Operator, CC service account)

### 응답

**200 OK**
```json
{
  "active_skin_id": "sk_01HVQK...",
  "seq": 42
}
```

**204 No Content** — active 스킨 미설정 (초기 상태)

---

## 8. DELETE /api/v1/skins/{id} — Remove

### 요청

- **Headers**:
  - `Authorization: Bearer {admin_jwt}`
  - `If-Match: W/"{etag}"` (필수)

### 응답

**204 No Content**

**409 Conflict** — active 스킨은 삭제 불가
```json
{
  "error": "ACTIVE_SKIN_CANNOT_DELETE",
  "message": "현재 활성 스킨입니다. 먼저 다른 스킨을 Activate하세요."
}
```

**412 Precondition Failed** — ETag 충돌

**403 Forbidden** — Admin 아님

---

## RBAC 매트릭스

| Role | POST | GET list | GET bytes | GET metadata | PATCH | PUT activate | GET active | DELETE |
|------|:----:|:--------:|:---------:|:------------:|:-----:|:------------:|:----------:|:------:|
| Admin | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Operator | ✗ | ✓ | ✓ | ✓ | ✗ | ✗ | ✓ | ✗ |
| CC service account | ✗ | ✗ | ✓ | ✗ | ✗ | ✗ | ✓ | ✗ |
| Viewer | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |

상세는 `BS-08-04-rbac-guards.md` 참조.

---

## X-Game-State 헤더 규칙

Activate 엔드포인트만 해당. 클라이언트(Lobby)가 `GameState == RUNNING` 감지 시 Admin 경고 다이얼로그를 거친 후 `X-Game-State: IDLE` 을 강제 선언하여 진행한다. 서버는 DB의 실제 GameState와 대조하여 불일치 시 409 + Warning 헤더로 거부.

---

## Idempotency-Key 처리 (CCR-003)

모든 mutation 엔드포인트(POST/PATCH/PUT/DELETE)는 `Idempotency-Key` 헤더를 요구한다. 서버는 `idempotency_keys` 테이블(DATA-04 §4.5)에 키·요청 해시·응답을 저장하여 동일 키 재수신 시 원본 응답을 그대로 반환한다.

---

## 에러 응답 표준

기존 `API-00` 또는 공통 에러 포맷 재사용. 모든 4xx/5xx 응답은 다음 구조:

```json
{
  "error": "ERROR_CODE",
  "message": "사용자 표시 메시지",
  "details": { ... }
}
```

---

## 검증 시나리오

- **Integration test `01-upload-download.http`**: POST 201 → GET 200 → 바이트 동일성 확인
- **Integration test `03-patch-metadata-etag.http`**: PATCH + stale ETag → 412
- **Integration test `05-rbac-denied.http`**: Operator POST → 403
- **Integration test `06-activate-game-state-warning.http`**: X-Game-State=IDLE + 서버 RUNNING → 409 + Warning
- **Integration test `07-multi-cc-sync.http`**: Activate → 2+ WS 클라이언트 동시 skin_updated 수신, 시간차 < 500ms
