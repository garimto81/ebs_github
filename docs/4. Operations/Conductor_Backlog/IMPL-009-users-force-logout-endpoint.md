---
id: IMPL-009
title: "구현: POST /users/{id}/force-logout (admin 강제 로그아웃)"
type: implementation
status: PENDING
owner: team2
created: 2026-05-03
created-by: conductor (Wave 1 A3 자율 cascade)
spec_ready: false
spec_ready_reason: "Conductor draft 완료. team2 publisher 검증 + Auth_and_Session.md 보강 후 true 전환"
blocking_spec_gaps: []
implements_chapters:
  - "docs/2. Development/2.2 Backend/APIs/Auth_and_Session.md (admin section, 보강 필요)"
  - "docs/2. Development/2.5 Shared/Authentication/Token_Lifecycle_Sequences.md (revoke flow 보강)"
related_code:
  - team2-backend/src/api/routers/auth.py (예상 위치, 신규 admin endpoint)
  - team1-frontend/lib/features/admin/user_management/* (consumer)
linked-audit: A3 frontend-impl-but-no-backend-spec (V9.5 reimplementability cycle)
last-updated: 2026-05-03
reimplementability: UNKNOWN
reimplementability_checked: 2026-05-03
reimplementability_notes: "PENDING — Conductor draft 단계. team2 publisher 검증 후 PASS 전환"
---

# IMPL-009 — POST /users/{id}/force-logout

> 🟡 **PENDING** — Conductor 자율 draft 완료. team2 publisher Fast-Track 검증 대기.

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
