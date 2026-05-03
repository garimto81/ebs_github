---
id: IMPL-011
title: "구현: DELETE /tables/{id}/seats/{seat_no} (테이블 seat 삭제)"
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
  - "docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md (table.seat.removed event 추가)"
related_code:
  - team2-backend/src/api/routers/tables.py (예상 위치, 기존 router 확장)
  - team1-frontend/lib/features/table_management/* (consumer)
linked-audit: A3 frontend-impl-but-no-backend-spec (V9.5 reimplementability cycle)
last-updated: 2026-05-03
reimplementability: UNKNOWN
reimplementability_checked: 2026-05-03
reimplementability_notes: "PENDING — Conductor draft 단계. team2 publisher 검증 후 PASS 전환"
---

# IMPL-011 — DELETE /tables/{id}/seats/{seat_no}

> 🟡 **PENDING** — Conductor 자율 draft 완료. team2 publisher Fast-Track 검증 대기.

## 배경

V9.5 reimplementability audit A3 — team1-frontend table 관리 화면에서 `DELETE /tables/{id}/seats/{seat_no}` 호출 발견, `Backend_HTTP.md` 에 PUT 만 존재 (DELETE 미정의).

10-max 테이블을 9-max 로 축소 또는 비활성 seat 정리.

## Conductor 자율 spec draft (V9.4 AI-Centric)

### HTTP

```
DELETE /tables/{id}/seats/{seat_no}
Authorization: Bearer <operator token>
```

### Response

| Status | Meaning |
|:---:|---------|
| 204 No Content | 성공 |
| 404 Not Found | table 또는 seat 미존재 |
| 409 Conflict | seat 에 active player 가 있어 삭제 불가 또는 진행 중 hand 에서 사용 중 |
| 401/403 | 권한 부재 |

### Business rules (자율 판정)

1. **Empty seat 만 삭제 허용**: `player_id != null` 시 409 + `reason: "seat_occupied"`. player 먼저 stand-up 후 재시도.
2. **활성 hand 보호**: 진행 중 hand 에서 사용 중인 seat (player_id null 이라도 dealer/SB/BB 위치 등) 409. team3-engine 의 hand status 확인.
3. **Cascade**: seat 삭제 시 `table_seats` row 제거. chip 데이터는 player stand-up 시 이미 처리됨. orphan chip 이력 0 보장.
4. **WebSocket broadcast**: `table.seat.removed` event (`/ws/lobby/{table_id}`) 송출. payload `{ seat_no, removed_at }`.
5. **Idempotency**: 이미 미존재 시 404 (DELETE convention). 일부 framework (RFC 7231) 는 200 + body 권장 — team2 publisher 결정.
6. **Audit log**: `seat_removed` event 기록 (SG-008-b1 audit-events 통합).

## 검증 plan

```
1. Backend_HTTP.md tables section 에 endpoint 추가 (team2 publisher)
2. WebSocket_Events.md `table.seat.removed` 추가
3. team2-backend/src/api/routers/tables.py DELETE /seats/{seat_no} 구현
4. tests/api/test_tables_seats_delete.py:
   - 204 정상 (empty seat)
   - 409 occupied
   - 409 active hand 사용 중
   - 404 미존재
   - 동시성: 같은 seat 동시 DELETE 2개 → 1개만 204, 다른 1개 404
5. team3-engine TableFSM 영향 검증 (다음 hand 부터 적용)
6. orphan chip 0 검증
```

## Spec ready 전환 조건

```
[ ] team2 publisher Backend_HTTP.md 보강 commit
[ ] WebSocket_Events.md `table.seat.removed` 추가
[ ] team3-engine TableFSM 영향 분석 (SG-009 정합)
[ ] audit_logs `seat_removed` event 등록
[ ] 위 4건 완료 시 spec_ready=true + reimplementability=PASS
```

## V9.4 자율성 명시

본 draft 는 다음 SSOT 기반 자율 판정:

- 기존 `PUT /tables/{id}/seats/{seat_no}`, `GET /tables/{id}/seats` inverse
- IMPL-010 (POST /seats) 와 대칭 패턴
- WebSocket events 표준 (SG-020)
- audit-events SG-008-b1 통합

사용자 개입 0 (V9.4 정합).
