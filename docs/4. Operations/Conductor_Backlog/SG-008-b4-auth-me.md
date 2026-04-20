---
id: SG-008-b4
title: "GET /auth/me 반환 필드 + 캐싱 정책 판정"
type: spec_gap
sub_type: spec_drift_b_escalated
parent_sg: SG-008
status: PENDING
owner: conductor
decision_owners_notified: [team2]
created: 2026-04-20
affects_chapter:
  - docs/2. Development/2.2 Backend/APIs/Auth_and_Session.md
  - docs/2. Development/2.5 Shared/Authentication.md
protocol: Spec_Gap_Triage §7.2
reimplementability: UNKNOWN
reimplementability_checked: 2026-04-20
reimplementability_notes: "SG-008-b PENDING. decision_owner 판정 대기"
---

# SG-008-b4 — `GET /auth/me` 반환 필드 + 캐싱

## 배경

SG-008 §"b분류" 에서 승격. self-info endpoint — 로그인 사용자 정보 조회. 반환 필드 구성이 frontend 의 RBAC/display 로직에 직결.

## 대상 endpoint (code-only)

- `GET /auth/me` — 현재 세션 사용자 정보

## 논점

1. 반환 필드 — 어디까지 포함?
   - 최소: `{ user_id, email, role }`
   - 확장: `{ ..., display_name, avatar_url, assigned_tables[], last_login_ts }`
2. 캐싱 — client-side 에서 TTL 캐시 허용? 권한 변경 반영 지연 문제
3. role 값 — `admin | operator | viewer` enum 직렬화 형식
4. `assigned_tables` 포함 여부 — Operator 의 할당 테이블 목록 (RBAC 검증용)

## 결정 옵션

| 옵션 | 장점 | 단점 |
|------|------|------|
| 1. 확장 필드 (user_id, email, role, display_name, assigned_tables[], last_login_ts), no-cache | Frontend 가 1회 호출로 세션 초기화 완료. WSOP LIVE `Staff App §/me` 패턴 | 권한 변경 즉시 반영 필요 (WS event 로 보완) |
| 2. 최소 필드 (user_id, email, role), client TTL 5분 | 캐시 가능, 부하 낮음 | Frontend 가 assigned_tables 를 별도 API 로 호출 |
| 3. Internal-only (미문서화 유지) | 판정 deferred | Frontend 구현 블로커 |

## Default 제안

**옵션 1 (확장 필드, no-cache)**. 이유:
- EBS Frontend 초기화 흐름에서 user info + assigned tables 가 동시 필요 — 왕복 최소화
- WSOP LIVE Confluence `Auth §/me` 가 동일 패턴 (user + permissions + last_login)
- `no-cache` 는 권한 변경 (Admin 이 Operator 의 assigned_tables 수정) 이 즉시 반영되어야 하므로 필요. 부하는 낮음 (lightweight endpoint)

**스펙 제안 초안**:
```json
{
  "user_id": 3,
  "email": "op1@example.com",
  "display_name": "Operator 1",
  "role": "operator",
  "assigned_tables": [5, 12],
  "last_login_ts": "2026-04-20T10:30:00Z",
  "created_at": "2026-01-10T00:00:00Z"
}
```
- RBAC: authenticated user only (any role)
- Cache-Control: `no-cache, no-store`
- role enum: `admin | operator | viewer`

## 수락 기준

- [ ] 옵션 선택
- [ ] 옵션 1: `Auth_and_Session.md §/me` 섹션 + Authentication.md RBAC 표 갱신
- [ ] 옵션 2: `Auth_and_Session.md` 최소 필드 정의 + 별도 `/api/v1/users/{id}/assigned-tables` 스펙 추가
- [ ] 옵션 3: internal 마킹

## Changelog

| 날짜 | 버전 | 변경 | 비고 |
|------|------|------|------|
| 2026-04-20 | v1.0 | SG-008 (b) 승격 신규 작성 | Conductor |
