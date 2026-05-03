---
id: IMPL-010
title: "구현: POST /tables/{id}/seats (테이블 seat 추가)"
type: implementation
status: PENDING
owner: team2
created: 2026-05-03
created-by: conductor (Wave 1 A3 자율 cascade)
spec_ready: false
spec_ready_reason: "Conductor draft 완료. team2 publisher 검증 + Backend_HTTP.md 보강 후 true 전환"
blocking_spec_gaps: []
implements_chapters:
  - "docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md (tables/seats section, 보강 필요)"
  - "docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md (table.seat.added event 추가)"
related_code:
  - team2-backend/src/api/routers/tables.py (예상 위치, 기존 router 확장)
  - team1-frontend/lib/features/table_management/* (consumer)
linked-audit: A3 frontend-impl-but-no-backend-spec (V9.5 reimplementability cycle)
last-updated: 2026-05-03
reimplementability: UNKNOWN
reimplementability_checked: 2026-05-03
reimplementability_notes: "PENDING — Conductor draft 단계. team2 publisher 검증 후 PASS 전환"
---

# IMPL-010 — POST /tables/{id}/seats

> 🟡 **PENDING** — Conductor 자율 draft 완료. team2 publisher Fast-Track 검증 대기.

## 배경

V9.5 reimplementability audit A3 — team1-frontend table 관리 화면에서 `POST /tables/{id}/seats` 호출 발견, `Backend_HTTP.md` 에 GET /tables/{id}/seats 만 존재 (POST 미정의).

운영자가 진행 중 테이블에 seat 동적 추가 (기존 9-max 테이블에서 8-max 로 시작 후 9번째 seat 활성화 시나리오).

## Conductor 자율 spec draft (V9.4 AI-Centric)

### HTTP

```
POST /tables/{id}/seats
Authorization: Bearer <operator token>
Content-Type: application/json

{
  "seat_no": 1-10,
  "active": true
}
```

### Response

| Status | Meaning |
|:---:|---------|
| 201 Created | `{ "table_id": ..., "seat_no": ..., "active": true, "player_id": null, "created_at": "..." }` |
| 400 Bad Request | seat_no 범위 외 또는 누락 |
| 404 Not Found | table id 미존재 |
| 409 Conflict | seat_no 이미 존재 (table 내 unique 제약) |
| 401/403 | 권한 부재 |

### Business rules (자율 판정)

1. **Player 비포함**: seat 생성 시 player_id 항상 null. player 배정은 별도 endpoint (`PUT /tables/{id}/seats/{seat_no}` — 기존).
2. **Seat number 제약**: 1-10 정수. table 의 max_seats config (table.config) 초과 시 400.
3. **Idempotency**: 동일 seat_no 재생성 시 409 (PUT 으로 업데이트 유도).
4. **WebSocket broadcast**: `table.seat.added` event (`/ws/lobby/{table_id}`) 송출. payload `{ seat_no, active, created_at }`.
5. **활성 hand 영향**: 진행 중 hand 에서 새 seat 추가 시 다음 hand 부터 적용 (현재 hand 영향 0). team3-engine 의 `tournament-status` 확인.
6. **DB schema**: `table_seats` 테이블 `(table_id, seat_no)` PK + `active` flag (Soft-state). 신규 컬럼 불필요 if 기존 schema 가 row 단위 관리.

## 검증 plan

```
1. Backend_HTTP.md tables section 에 endpoint 추가 (team2 publisher)
2. WebSocket_Events.md 에 `table.seat.added` event 추가
3. team2-backend/src/api/routers/tables.py POST /seats 구현
4. tests/api/test_tables_seats_create.py:
   - 201 정상
   - 400 seat_no 범위 외
   - 409 중복
   - 404 table 미존재
   - 동시성: 같은 seat_no 동시 POST 2개 → 1개만 201, 다른 1개 409
5. team3-engine 활성 hand 영향 0 검증 (다음 hand 적용)
6. team1-frontend 호출 코드 mocking + WS event 수신 검증
```

## Spec ready 전환 조건

```
[ ] team2 publisher Backend_HTTP.md 보강 commit
[ ] WebSocket_Events.md `table.seat.added` 추가
[ ] DB schema 검증 (`table_seats` 기존 / 신규 컬럼 결정)
[ ] team3-engine TableFSM 영향 분석 (SG-009 case-serialization 정합)
[ ] 위 4건 완료 시 spec_ready=true + reimplementability=PASS
```

## V9.4 자율성 명시

본 draft 는 다음 SSOT 기반 자율 판정:

- 기존 `GET /tables/{id}/seats`, `PUT /tables/{id}/seats/{seat_no}` 패턴 일관성
- WebSocket events 표준 (SG-020 ack/reject 분리)
- WSOP LIVE Confluence table 관리 패턴 (원칙 1)

사용자 개입 0 (V9.4 정합).
