---
id: IMPL-008
title: "구현: POST /skins/{id}/deactivate (gfskin 비활성화) — SUPERSEDED"
type: implementation
status: DONE
superseded-by: V9.5 P7 (Backend_HTTP.md §5.12 line 811 이미 spec'd)
owner: team2
created: 2026-05-03
created-by: conductor (Wave 1 A3 자율 cascade)
resolved: 2026-05-03
resolved-by: conductor (post-merge SSOT 재확인 — V9.5 P7 already spec)
spec_ready: true
spec_ready_reason: "Backend_HTTP.md §5.12 line 811 V9.5 P7 already spec — POST /skins/:id/deactivate (Admin)"
blocking_spec_gaps: []
implements_chapters:
  - "docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md §5.12 line 811 (V9.5 P7 already spec)"
  - "docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md §13.2 (gfskin.deactivated event 추가, 본 PR cascade)"
related_code:
  - team2-backend/src/api/routers/skins.py (V9.5 P7 구현)
  - team1-frontend/lib/features/lobby/skin_management/* (consumer)
linked-audit: A3 frontend-impl-but-no-backend-spec (V9.5 cycle, audit pre-V9.5 P7)
last-updated: 2026-05-03
reimplementability: PASS
reimplementability_checked: 2026-05-03
reimplementability_notes: "V9.5 P7 spec 확인 후 PASS 전환. Backend_HTTP.md §5.12 + WebSocket_Events.md §13 cascade 완비"
---

# IMPL-008 — POST /skins/{id}/deactivate ✅ SUPERSEDED

> ✅ **DONE (SUPERSEDED 2026-05-03)** — V9.5 P7 (`Backend_HTTP.md` §5.12 line 811) 이 본 endpoint 를 이미 spec'd. Conductor draft 시점에 SSOT lookup 부족으로 redundant 작성. 본 PR cascade 에서 `WebSocket_Events.md` §13.2 broadcast event 명세 추가로 SSOT 완비.

## 배경

V9.5 reimplementability audit 결과 A3 분류 (frontend 호출 코드 존재 + backend spec 부재). team1-frontend 의 Lobby 스킨 관리 화면에서 `POST /skins/{id}/deactivate` 호출 코드가 발견되었으나, `Backend_HTTP.md` 에 endpoint 미정의.

기존 endpoint 패턴 (`POST /skins/{id}/activate`) 의 inverse — 활성 스킨을 비활성으로 전환.

## Conductor 자율 spec draft (V9.4 AI-Centric)

### HTTP

```
POST /skins/{id}/deactivate
Authorization: Bearer <admin token>
Content-Type: application/json

(no body)
```

### Response

| Status | Meaning |
|:---:|---------|
| 200 OK | `{ "id": "<skin_id>", "active": false, "deactivated_at": "<iso8601>" }` |
| 404 Not Found | skin id 미존재 |
| 409 Conflict | 이미 비활성 (idempotent 거부) 또는 활성 게임에서 사용 중 |
| 401/403 | admin 권한 부재 |

### Business rules (자율 판정)

1. **Idempotency**: 이미 `active=false` 시 409 (활성/비활성 명확 구분). PUT 이 아닌 POST 사용 — `activate` 와 대칭.
2. **활성 게임 보호**: 현재 진행 중 hand 에서 사용 중인 skin 비활성 차단 (409 + `reason: "in_use_in_active_hand"`). 게임 종료 후 재시도.
3. **Soft delete**: 데이터 삭제 X. `active=false` flag 만 변경 + `deactivated_at` timestamp 기록.
4. **WebSocket broadcast**: `gfskin.deactivated` event 를 운영자 채널 (`/ws/cc`) 에 송출. team4 CC 가 UI 갱신.
5. **Permission**: admin only. 일반 운영자 불가.

## 검증 plan

```
1. Backend_HTTP.md gfskin section 에 endpoint 추가 (team2 publisher)
2. team2-backend/src/api/routers/skins.py 에 route 구현
3. tests/api/test_skins_deactivate.py:
   - 200 정상 케이스
   - 404 미존재
   - 409 중복 비활성
   - 409 활성 hand 사용 중
   - 401/403 권한 부재
4. team1-frontend 의 호출 코드 mocking 검증
5. WebSocket event team4-cc 수신 검증
```

## Spec ready 전환 조건

```
[ ] team2 publisher Backend_HTTP.md 보강 commit
[ ] DB schema 영향 분석 완료 (skins 테이블 deactivated_at 컬럼 추가)
[ ] WebSocket events SSOT (`docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md`) 에 `gfskin.deactivated` 추가
[ ] 위 3건 완료 시 spec_ready=true 전환 + reimplementability=PASS 재분류
```

## V9.4 자율성 명시

본 draft 는 사용자에게 도메인 결정을 떠넘기지 않는다. Conductor 가 다음 SSOT 기반으로 자율 판정:

- 기존 `POST /skins/{id}/activate` inverse 패턴
- `Backend_HTTP.md` REST convention
- WSOP LIVE Confluence skin management 패턴 (원칙 1)

team2 publisher 가 이 draft 를 검증하면서 SSOT 부족 영역만 보강. 사용자 개입 0 (V9.4 정합).
