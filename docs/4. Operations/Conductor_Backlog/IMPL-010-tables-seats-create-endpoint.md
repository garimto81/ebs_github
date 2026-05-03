---
id: IMPL-010
title: "구현: POST /tables/{id}/seats (좌석 플레이어 배치) — SUPERSEDED + 의미 정정"
type: implementation
status: DONE
superseded-by: V9.5 P7 (Backend_HTTP.md §5.7 line 626 이미 spec'd, frontend addPlayer)
owner: team2
created: 2026-05-03
created-by: conductor (Wave 1 A3 자율 cascade)
resolved: 2026-05-03
resolved-by: conductor (post-merge SSOT 재확인 — V9.5 P7 already spec, draft 의미 오인 발견)
spec_ready: true
spec_ready_reason: "Backend_HTTP.md §5.7 line 626 V9.5 P7 already spec — frontend addPlayer (좌석에 플레이어 배치)"
blocking_spec_gaps: []
implements_chapters:
  - "docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md §5.7 line 626 + line 630-640 (V9.5 P7 already spec)"
  - "docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md §13.4 (table.seat.added event 추가, 본 PR cascade)"
related_code:
  - team2-backend/src/api/routers/tables.py (V9.5 P7 구현)
  - team1-frontend/lib/features/table_management/* (frontend addPlayer consumer)
linked-audit: A3 frontend-impl-but-no-backend-spec (V9.5 cycle, audit pre-V9.5 P7)
draft-correction: "초기 draft 는 'seat 자체 추가 (max_seats 변경)' 의미로 작성됐으나 실제 V9.5 P7 spec 은 'addPlayer' 의미. 의미 오인 — 본 정정으로 V9.5 P7 정합."
last-updated: 2026-05-03
reimplementability: PASS
reimplementability_checked: 2026-05-03
reimplementability_notes: "V9.5 P7 spec 확인 후 PASS 전환. Backend_HTTP.md §5.7 + WebSocket_Events.md §13 cascade 완비"
---

# IMPL-010 — POST /tables/{id}/seats ✅ SUPERSEDED + 의미 정정

> ✅ **DONE (SUPERSEDED 2026-05-03)** — V9.5 P7 (`Backend_HTTP.md` §5.7 line 626) 이 본 endpoint 를 이미 spec'd. **의미 정정**: Conductor 초기 draft 는 "seat 자체 추가 (10-max 동적 확장)" 가정이었으나, 실제 V9.5 P7 spec 은 **frontend `addPlayer` (좌석에 플레이어 배치)** — payload `{ seat_no, player_id, chip_count }`. 본 PR cascade 에서 `WebSocket_Events.md` §13.4 broadcast event 명세 추가로 SSOT 완비.

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
