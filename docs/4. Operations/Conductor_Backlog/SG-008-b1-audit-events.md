---
id: SG-008-b1
title: "GET /api/v1/audit-events 공개 범위 + RBAC 판정"
type: spec_gap
sub_type: spec_drift_b_escalated
parent_sg: SG-008
status: PENDING
owner: conductor
decision_owners_notified: [team2]
created: 2026-04-20
affects_chapter:
  - docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md
  - docs/2. Development/2.5 Shared/Authentication.md
protocol: Spec_Gap_Triage §7.2
reimplementability: UNKNOWN
reimplementability_checked: 2026-04-20
reimplementability_notes: "SG-008-b PENDING. decision_owner 판정 대기"
---

# SG-008-b1 — `GET /api/v1/audit-events` 공개 범위 + RBAC

## 배경

SG-008 §"b분류" 에서 본 endpoint 가 설계 결정 필요로 분류됨. 코드에 존재하지만 기획 Backend_HTTP.md 에 미정의. WSOP LIVE 는 audit events 를 **internal-only** 로 운용하지만 EBS 는 개발팀 인계용이라 공개 API 여부부터 결정해야 함.

## 대상 endpoint (code-only)

- `GET /api/v1/audit-events` — 모든 audit event 조회 (`audit_events` 테이블)

## 논점

1. 공개 API 인가, internal-only 인가?
2. 공개 시 RBAC — Admin 전용인가, Operator/Viewer 에게도 제한적 조회 허용인가?
3. pagination 전략 (`?limit=100&offset=0` vs `?since_seq=N`)
4. filter 지원 범위 (`?table_id`, `?event_type`, `?from_ts`, `?to_ts`)

## 결정 옵션

| 옵션 | 장점 | 단점 |
|------|------|------|
| 1. Public API (Admin only, filter 지원) | 개발팀 인계 시 디버깅/감사 도구 제공. WSOP LIVE Staff App §AuditLog 패턴 | RBAC/pagination 설계 + 문서화 + 테스트 부담 |
| 2. Internal-only (API docs 에서 제외, 코드 유지) | 공개 범위 결정 deferred. 현재 코드 유지 | "internal" 마킹이 스캐너·외부 팀에게 모호 |
| 3. 코드 삭제 | Drift 해소 최단 경로 | 향후 감사 도구 재구현 비용 |

## Default 제안

**옵션 1 (Admin-only public API)**. 이유:
- EBS 는 개발팀 인계용 프로토타입 → 감사 도구는 **인계 대상 기능**
- WSOP LIVE Confluence page 1793328277 `SignalR Service` §AuditLog 가 동일 패턴 (Admin role required)
- SG-008 §3분류 기준 "감사 이벤트" = 판정 후 유지 방향이 자연스러움
- 코드 삭제(c) 시 team2 의 이미 구현된 `audit_repository` 활용도가 0 이 됨

**스펙 제안 초안**:
- `GET /api/v1/audit-events?table_id={id}&event_type={t}&since_seq={n}&limit={1..500}`
- RBAC: Admin only (`require_role("admin")`)
- Response: `{ items: AuditEvent[], next_cursor: int, has_more: bool }`

## 수락 기준

- [ ] 옵션 선택 (1/2/3)
- [ ] 옵션 1 선택 시: `Backend_HTTP.md §audit-events` 신규 섹션 + `Authentication.md` RBAC 표 갱신
- [ ] 옵션 2 선택 시: 코드에 `@router.get(..., include_in_schema=False)` 표시 + Backend_HTTP.md 에 internal 명시 주석
- [ ] 옵션 3 선택 시: 코드 삭제 PR (team2 세션) + spec_drift_check.py 재실행 확인

## Changelog

| 날짜 | 버전 | 변경 | 비고 |
|------|------|------|------|
| 2026-04-20 | v1.0 | SG-008 (b) 승격 신규 작성 | Conductor |
