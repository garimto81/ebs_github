---
title: CR-conductor-20260411-ge-api-spec
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-conductor-20260411-ge-api-spec
confluence-page-id: 3818587284
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818587284/EBS+CR-conductor-20260411-ge-api-spec
---

# CCR-DRAFT: API-07 Graphic Editor 엔드포인트 신설

- **제안팀**: conductor
- **제안일**: 2026-04-11
- **영향팀**: [team1, team2]
- **변경 대상 파일**: contracts/api/`Graphic_Editor_API.md` (legacy-id: API-07) (add)
- **변경 유형**: add
- **변경 근거**: `contracts/api/`에 GE 관련 Backend 엔드포인트 스펙이 **존재하지 않는다**. Team 1 Lobby가 Backend를 호출해야 하는데 호출할 API가 계약에 없어 Team 2가 무엇을 구현해야 하는지 불명확. CCR `ge-ownership-move` 승격 후 즉시 필요. Idempotency-Key (CCR-003 준수), `If-Match` ETag 낙관적 동시성, `X-Game-State` 헤더 검증 (방송 중 activate 경고)을 공식화.

## 변경 요약

`Graphic_Editor_API.md` (legacy-id: API-07) 신설, 8개 엔드포인트 정의:

| # | Method | Path | 역할 | RBAC | Header |
|---|--------|------|------|------|--------|
| 1 | POST | /api/v1/skins | `.gfskin` multipart upload | Admin | Idempotency-Key |
| 2 | GET | /api/v1/skins | 목록 (pagination) | Admin, Operator | - |
| 3 | GET | /api/v1/skins/{id} | `.gfskin` bytes 다운로드 | Admin, Operator | - |
| 4 | GET | /api/v1/skins/{id}/metadata | skin.json JSON 반환 | Admin, Operator | - |
| 5 | PATCH | /api/v1/skins/{id}/metadata | 메타데이터 부분 편집 | Admin | If-Match |
| 6 | PUT | /api/v1/skins/{id}/activate | active_skin_id 설정 + WS broadcast | Admin | If-Match, X-Game-State |
| 7 | GET | /api/v1/skins/active | 현재 active skin_id 조회 | Admin, Operator, (CC) | - |
| 8 | DELETE | /api/v1/skins/{id} | 스킨 삭제 | Admin | If-Match |

## Diff 초안

`Graphic_Editor_API.md` (legacy-id: API-07) 신설 (핵심 골격):

````markdown
# API-07 Graphic Editor Endpoints

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-11 | 신규 작성 | 8 엔드포인트 + Idempotency + If-Match ETag + X-Game-State |

## 개요

Team 1 Lobby의 Graphic Editor 탭이 사용하는 BO REST API. Team 2 FastAPI 서비스가 구현.

참조:
- DATA-07-gfskin-schema.md — 요청/응답 body 스키마
- `Auth_and_Session.md` (legacy-id: API-06) — JWT + RBAC
- CCR-003 — Idempotency 정책
- CCR-015 — WS seq 단조증가

## 1. POST /api/v1/skins — Upload

### 요청
- Method: POST
- Content-Type: multipart/form-data
- Headers:
  - Authorization: Bearer {admin_jwt}
  - Idempotency-Key: {uuid4} (필수)
- Body:
  - file: `.gfskin` ZIP
  - name (form): "my-skin" (선택, skin.json 내 이름 override)

### 응답
- 201 Created
  ```json
  {
    "id": "sk_01HVQK...",
    "version": 1,
    "etag": "W/\"1-...\"",
    "url": "/api/v1/skins/sk_01HVQK..."
  }
  ```
- 409 Conflict — 동일 Idempotency-Key 재사용 (CCR-003)
- 422 Unprocessable Entity — JSON Schema 검증 실패
  ```json
  {
    "error": "schema_violation",
    "path": "colors.badge_check",
    "message": "Pattern mismatch"
  }
  ```
- 403 Forbidden — Admin 아님

## 2. GET /api/v1/skins — List

### 요청
- Query: `?limit=20&offset=0&sort=-modified_at`

### 응답
- 200 OK
  ```json
  {
    "items": [
      { "id": "sk_...", "skin_name": "...", "version": "1.0.0", "modified_at": "...", "is_active": true }
    ],
    "total": 42,
    "limit": 20,
    "offset": 0
  }
  ```

## 3. GET /api/v1/skins/{id} — Download bytes

### 응답
- 200 OK
- Content-Type: application/octet-stream
- Body: `.gfskin` 바이너리

## 4. GET /api/v1/skins/{id}/metadata — Read skin.json

### 응답
- 200 OK
- Content-Type: application/json
- Body: skin.json 전체 (파싱 편의)
- Header: ETag: W/"..."

## 5. PATCH /api/v1/skins/{id}/metadata — Update metadata

### 요청
- Headers:
  - If-Match: W/"{etag}" (필수)
- Body: RFC 7396 JSON Merge Patch
  ```json
  { "colors": { "badge_check": "#00FF00" } }
  ```

### 응답
- 200 OK with new etag
- 412 Precondition Failed — ETag 충돌, 클라이언트는 최신 상태 refetch 후 재시도

## 6. PUT /api/v1/skins/{id}/activate — Activate + Broadcast

### 요청
- Headers:
  - If-Match: W/"{etag}"
  - X-Game-State: "IDLE" | "RUNNING" (클라이언트 자체 보고, 서버가 DB와 대조)

### 응답
- 201 Created
  ```json
  {
    "active_skin_id": "sk_01HVQK...",
    "seq": 42,
    "broadcasted_at": "2026-04-11T10:30:00Z"
  }
  ```
- 409 Conflict + Warning 헤더 — 서버 판단 GameState==RUNNING이고 X-Game-State 불일치
- 412 Precondition Failed — ETag 충돌

### 사이드 이펙트
- DB: `active_skin_id = {id}`
- WebSocket broadcast: `{type: "skin_updated", payload: {skin_id, version, seq, transition_type}}`
  - 상세는 API-05 `skin_updated` 이벤트 (CCR `skin-updated-ws` 참조)

## 7. GET /api/v1/skins/active — Current active

### 응답
- 200 OK
  ```json
  { "active_skin_id": "sk_01HVQK...", "seq": 42 }
  ```

## 8. DELETE /api/v1/skins/{id} — Remove

### 요청
- Headers: If-Match: W/"{etag}"

### 응답
- 204 No Content
- 409 Conflict — active 스킨은 삭제 불가

## 에러 응답 표준

(기존 API-00 형식 재사용)

## RBAC

| Role | POST | GET | PATCH | PUT activate | DELETE |
|------|:----:|:---:|:-----:|:------------:|:------:|
| Admin | ✓ | ✓ | ✓ | ✓ | ✓ |
| Operator | ✗ | ✓ | ✗ | ✗ | ✗ |
| Viewer | ✗ | ✗ | ✗ | ✗ | ✗ |

## X-Game-State 헤더 규칙

Activate 엔드포인트만 해당. 클라이언트(Lobby)가 사용자 경고 다이얼로그 후에도 진행하려면 요청에 `X-Game-State: IDLE` 강제 선언. 서버는 DB의 실제 GameState와 대조하여 불일치 시 409.

(기타 상세는 Team 2가 구현 중 보강)
````

## 영향 분석

| 팀 | 영향 | 공수 |
|----|------|------|
| Team 1 | 8 엔드포인트 호출 래퍼 (`src/services/skinsApi.ts`), ETag 추적, 재시도 로직 | 1주 |
| Team 2 | 8 엔드포인트 구현 (FastAPI router), pydantic + JSON Schema 검증, DB 모델(`Skin`, `SkinVersion`, `active_skin_id` 컬럼), Idempotency-Key store | 2주 |

## 대안 검토

1. **단일 PUT /skins/{id}로 모두 처리 (메타데이터 + ZIP 동시 업로드)**: 구현 단순. 단점: 부분 편집 시 매번 전체 ZIP 재업로드. ❌
2. **본 CCR (POST ZIP + PATCH metadata 분리)**: 부분 편집 최적화, 대역폭 절감. ✅

## 검증 방법

- Integration test `01-upload-download.http`: POST 201 → GET 200 → bytes 동일
- `03-patch-metadata-etag.http`: PATCH + stale ETag → 412
- `05-rbac-denied.http`: Operator POST → 403
- `06-broadcast-warning.http`: X-Game-State=RUNNING → 409 + warning

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 1 기술 검토 (ETag 상태 추적 구현 가능성)
- [ ] Team 2 기술 검토 (FastAPI + fastjsonschema 수용, Idempotency store 기술 선택)

## 참고 사항

- **선행 조건**: CCR `ge-ownership-move` (팀 경계 확정), CCR `gfskin-format-unify` (DATA-07 신설)
- **후속 CCR**: `skin-updated-ws` (API-05 WebSocket 이벤트)
- **Plan 파일**: `C:/Users/AidenKim/.claude/plans/floating-percolating-petal.md`
