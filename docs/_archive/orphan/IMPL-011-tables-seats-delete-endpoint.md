---
id: IMPL-011
title: "구현: DELETE /tables/{id}/seats/{seat_no} (좌석 비우기) — SUPERSEDED + 의미 정정"
type: implementation
status: DONE
superseded-by: V9.5 P7 (Backend_HTTP.md §5.7 line 628 이미 spec'd, frontend removePlayer)
owner: team2
created: 2026-05-03
created-by: conductor (Wave 1 A3 자율 cascade)
resolved: 2026-05-03
resolved-by: conductor (post-merge SSOT 재확인 — V9.5 P7 already spec, draft 의미 오인 발견)
spec_ready: true
spec_ready_reason: "Backend_HTTP.md §5.7 line 628 V9.5 P7 already spec — frontend removePlayer (좌석 vacant 전환)"
blocking_spec_gaps: []
implements_chapters:
  - "docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md §5.7 line 628 + line 642-644 (V9.5 P7 already spec)"
  - "docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md §13.5 (table.seat.removed event 추가, 본 PR cascade)"
related_code:
  - team2-backend/src/api/routers/tables.py (V9.5 P7 구현)
  - team1-frontend/lib/features/table_management/* (frontend removePlayer consumer)
linked-audit: A3 frontend-impl-but-no-backend-spec (V9.5 cycle, audit pre-V9.5 P7)
draft-correction: "초기 draft 는 'seat 자체 삭제' 의미로 작성됐으나 실제 V9.5 P7 spec 은 'removePlayer' (vacant 전환). 의미 오인 — 본 정정으로 V9.5 P7 정합."
last-updated: 2026-05-03
reimplementability: PASS
reimplementability_checked: 2026-05-03
reimplementability_notes: "V9.5 P7 spec 확인 후 PASS 전환. Backend_HTTP.md §5.7 + WebSocket_Events.md §13 cascade 완비"
---

# IMPL-011 — DELETE /tables/{id}/seats/{seat_no} ✅ SUPERSEDED + 의미 정정

> ✅ **DONE (SUPERSEDED 2026-05-03)** — V9.5 P7 (`Backend_HTTP.md` §5.7 line 628) 이 본 endpoint 를 이미 spec'd. **의미 정정**: Conductor 초기 draft 는 "seat 자체 삭제 (10-max 축소)" 가정이었으나, 실제 V9.5 P7 spec 은 **frontend `removePlayer` (좌석을 vacant 상태로 전환, status=`empty`, player_id=null)**. 본 PR cascade 에서 `WebSocket_Events.md` §13.5 broadcast event 명세 추가로 SSOT 완비.

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
