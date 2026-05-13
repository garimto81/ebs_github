---
id: SG-008-b5
title: "POST /auth/logout 세션 무효화 범위 판정"
type: spec_gap
sub_type: spec_drift_b_escalated
parent_sg: SG-008
status: RESOLVED
owner: conductor
decision_owners_notified: [team2]
created: 2026-04-20
affects_chapter:
  - docs/2. Development/2.2 Backend/APIs/Auth_and_Session.md
  - docs/2. Development/2.5 Shared/Authentication.md
protocol: Spec_Gap_Triage §7.2
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "2026-04-20 RESOLVED — 옵션 1 채택 (team2 세션 구현 완료)"
tier: internal
backlog-status: open
---

# SG-008-b5 — `POST /auth/logout` 세션 무효화 범위

## 배경

SG-008 §"b분류" 에서 승격. 로그아웃 시 현재 세션만 무효화할지, 모든 device 세션을 무효화할지 결정 필요.

## 대상 endpoint (code-only)

- `POST /auth/logout` — 로그아웃

## 논점

1. 무효화 범위 — current session only vs all sessions (all devices)
2. JWT 무효화 전략 — refresh token revocation list? access token 은 짧은 TTL 로 자연 만료 대기?
3. logout 요청 시 body 필수 필드? (현재 body=null 허용?)
4. Response — 204 No Content vs 200 + message

## 결정 옵션

| 옵션 | 장점 | 단점 |
|------|------|------|
| 1. Current session only (default) + `POST /auth/logout?all=true` 로 전체 무효화 | 일반 로그아웃 빠름. 전체 무효화는 opt-in | refresh token revocation list DB 필요 |
| 2. 항상 모든 세션 무효화 (all devices) | 구현 단순. 보안 강화 | 사용자 UX 나쁨 (다른 device 강제 로그아웃) |
| 3. Client-side token 폐기만 (server no-op) | 구현 zero. stateless JWT 철학 | logout 이 실효 없음. stolen token 차단 불가 |

## Default 제안

**옵션 1 (current session default + `?all=true` opt-in)**. 이유:
- WSOP LIVE `Auth §Logout` 과 동일 패턴
- Operator 가 여러 테이블 device 운용 시 single logout 이 UX 상 기본
- `?all=true` 는 보안 사고 시 사용자가 직접 호출 가능한 escape hatch
- refresh token revocation list 는 소규모 (`revoked_refresh_tokens` 테이블 + cleanup job)

**스펙 제안 초안**:
- `POST /auth/logout` → current session (refresh token revocation)
- `POST /auth/logout?all=true` → 해당 user_id 의 모든 refresh token 일괄 revocation
- Body: none
- Response: `204 No Content`
- RBAC: authenticated user only
- 신규 테이블: `revoked_refresh_tokens (jti, user_id, revoked_at, expires_at)` — Schema.md 보강
- access token 은 TTL 만료(15분) 대기

## 수락 기준

- [ ] 옵션 선택
- [ ] 옵션 1: Auth_and_Session.md + Schema.md 보강
- [ ] 옵션 2: Auth_and_Session.md 에 all-device 명시, team2 구현 조정
- [ ] 옵션 3: 코드에 no-op 주석 명시 + Auth_and_Session.md 에 "client-side only" 기록


## Resolution

**2026-04-20: 옵션 1 채택** — JWT jti 블랙리스트 (Redis TTL)

team2 세션에서 코드·스펙 반영 완료:
- Backend_HTTP.md §16 "SG-008 b-분류 결정 스펙" 에 최종 스펙 기록
- 코드 변경: `C:/claude/ebs/team2-backend/src/routers/`
- 상세: Backend_HTTP.md §16 참조

## Changelog

| 날짜 | 버전 | 변경 | 비고 |
|------|------|------|------|
| 2026-04-20 | v1.0 | SG-008 (b) 승격 신규 작성 | Conductor |
| 2026-04-20 | v1.1 | RESOLVED — 옵션 1 채택: JWT jti 블랙리스트 (Redis TTL) | team2 session |
