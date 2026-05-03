---
id: IMPL-009
title: "구현: POST /users/{id}/force-logout (admin 강제 로그아웃) — SUPERSEDED"
type: implementation
status: DONE
superseded-by: V9.5 P7 (Backend_HTTP.md §5.2 line 213 이미 spec'd)
owner: team2
created: 2026-05-03
created-by: conductor (Wave 1 A3 자율 cascade)
resolved: 2026-05-03
resolved-by: conductor (post-merge SSOT 재확인 — V9.5 P7 already spec)
spec_ready: true
spec_ready_reason: "Backend_HTTP.md §5.2 line 213 V9.5 P7 already spec — POST /users/:id/force-logout (Admin)"
blocking_spec_gaps: []
implements_chapters:
  - "docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md §5.2 line 213-215 (V9.5 P7 already spec)"
  - "docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md §13.3 (force_logout event + close code 4003 추가, 본 PR cascade)"
related_code:
  - team2-backend/src/api/routers/auth.py (V9.5 P7 구현)
  - team1-frontend/lib/features/admin/user_management/* (consumer)
linked-audit: A3 frontend-impl-but-no-backend-spec (V9.5 cycle, audit pre-V9.5 P7)
last-updated: 2026-05-03
reimplementability: PASS
reimplementability_checked: 2026-05-03
reimplementability_notes: "V9.5 P7 spec 확인 후 PASS 전환. Backend_HTTP.md §5.2 + WebSocket_Events.md §13 cascade 완비"
---

# IMPL-009 — POST /users/{id}/force-logout ✅ SUPERSEDED

> ✅ **DONE (SUPERSEDED 2026-05-03)** — V9.5 P7 (`Backend_HTTP.md` §5.2 line 213) 이 본 endpoint 를 이미 spec'd. Conductor draft 시점에 SSOT lookup 부족으로 redundant 작성. 본 PR cascade 에서 `WebSocket_Events.md` §13.3 broadcast event + close code 4003 명세 추가로 SSOT 완비.

## 배경

V9.5 reimplementability audit A3 — team1-frontend admin 화면에서 `POST /users/{id}/force-logout` 호출 발견, `Auth_and_Session.md` admin section 미정의.

운영자 보안 사건 대응 (계정 탈취 의심, 부정행위 적발) 시 admin 이 즉시 사용자 세션 종료.

## Conductor 자율 spec draft (V9.4 AI-Centric)

### HTTP

```
POST /users/{id}/force-logout
Authorization: Bearer <admin token>
Content-Type: application/json

{
  "reason": "string (audit log 용, optional)"
}
```

### Response

| Status | Meaning |
|:---:|---------|
| 204 No Content | 성공 (revoke + WebSocket close 완료) |
| 404 Not Found | user id 미존재 |
| 409 Conflict | 이미 로그아웃 상태 (no active session) |
| 401/403 | admin 권한 부재 |

### Business rules (자율 판정)

1. **Token revoke**: 대상 user 의 모든 active refresh token 즉시 invalidate. access token blacklist 추가 (TTL = access token 만료까지).
2. **WebSocket close**: 대상 user 의 active WebSocket 연결 (lobby/cc 모두) 강제 종료. close code `4003 force_logout`.
3. **Audit log**: `audit_logs` 테이블에 `event=force_logout`, `target_user_id`, `actor_user_id`, `reason`, `at` 기록 (SG-008-b1 의 audit-events 통합).
4. **Idempotency**: 이미 active session 0 시 409. 재시도 시 동일 응답.
5. **Permission**: admin only. self force-logout 차단 (`actor_id != target_id`).
6. **WSOP LIVE 정렬**: 동일 패턴 `POST /admin/users/{id}/sign_out` (WSOP LIVE Confluence) 참조 — naming 일치 검토 필요 (team2 publisher 결정).

## 검증 plan

```
1. Auth_and_Session.md admin section 에 endpoint 추가 (team2 publisher)
2. Token_Lifecycle_Sequences.md 에 force_logout flow sequence diagram 추가
3. team2-backend/src/api/routers/auth.py force_logout 구현
4. tests/api/test_force_logout.py:
   - 204 정상 (token revoke + ws close)
   - 404 user 미존재
   - 409 이미 logout
   - 403 self target
   - 403 non-admin actor
5. WebSocket close code 4003 frontend 수신 검증 (auto-redirect to login)
```

## Spec ready 전환 조건

```
[ ] team2 publisher Auth_and_Session.md 보강 commit
[ ] Token_Lifecycle_Sequences.md sequence 추가
[ ] audit_logs schema 확인 (force_logout event_type 등록)
[ ] WebSocket close code 정책 (`Backend_HTTP_Status.md` 또는 신규 WS_Close_Codes.md) 정합
[ ] 위 4건 완료 시 spec_ready=true + reimplementability=PASS
```

## V9.4 자율성 명시

본 draft 는 다음 SSOT 기반 자율 판정:

- 기존 `POST /auth/logout` (self) 의 admin 변형
- WSOP LIVE Confluence admin user management 패턴 (원칙 1)
- SG-008-b1 audit-events 통합 패턴

사용자 개입 0 (V9.4 정합).
