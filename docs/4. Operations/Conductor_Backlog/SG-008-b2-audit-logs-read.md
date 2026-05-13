---
id: SG-008-b2
title: "GET /api/v1/audit-logs RBAC 스코프 판정"
type: spec_gap
sub_type: spec_drift_b_escalated
parent_sg: SG-008
status: RESOLVED
owner: conductor
decision_owners_notified: [team2]
created: 2026-04-20
affects_chapter:
  - docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md
  - docs/2. Development/2.5 Shared/Authentication.md
protocol: Spec_Gap_Triage §7.2
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "2026-04-20 RESOLVED — 옵션 1 채택 (team2 세션 구현 완료)"
tier: internal
backlog-status: open
---

# SG-008-b2 — `GET /api/v1/audit-logs` RBAC 스코프

## 배경

SG-008 §"b분류" 에서 승격. `audit-logs` 는 `audit-events` 와 별개 리소스인지, alias 인지부터 불명확. 현재 코드는 두 endpoint 가 공존.

## 대상 endpoint (code-only)

- `GET /api/v1/audit-logs` — 조회

## 논점

1. `audit-events` 와 `audit-logs` 는 **다른 리소스**인가, alias 인가?
   - `audit-events`: WebSocket/API 이벤트 append-only (audit_events 테이블, seq 기반)
   - `audit-logs`: login/permission 변경/설정 변경 등 user action log (별개 테이블?)
2. RBAC — Admin only? Operator 가 자기 테이블 관련 로그 조회 가능해야 하는가?
3. retention — 얼마나 보관? (GDPR/compliance 고려)

## 결정 옵션

| 옵션 | 장점 | 단점 |
|------|------|------|
| 1. 별도 리소스 (user action log), Admin only | 책임 분리 명확. audit_events 와 query 패턴 다름 | DB 스키마 추가 필요 (`audit_logs` 테이블 신설) |
| 2. `audit-events` alias 로 통합, 코드 삭제 | Drift 최단 해소. DB 단일 소스 | 의미 혼란 ("log" vs "event" 용어 차이) |
| 3. Internal-only (미문서화 유지) | 판정 deferred | 장기 방치 위험 |

## Default 제안

**옵션 1 (별도 리소스, Admin only)**. 이유:
- WSOP LIVE Confluence `Staff App §AuditLog` 는 `events` 와 별개 리소스
- `audit_events` 는 게임 이벤트 stream (high-volume, seq 기반 replay), `audit_logs` 는 user action audit (low-volume, time-range query) — 용도/인덱스/retention 이 다름
- 개발팀 인계 시 두 개념을 분리해야 운영 혼란 없음

**스펙 제안 초안**:
- `GET /api/v1/audit-logs?actor_user_id={id}&action={t}&from_ts={iso}&to_ts={iso}&limit={1..500}`
- RBAC: Admin only
- Response: `{ items: AuditLog[], next_cursor, has_more }`
- 신규 테이블 `audit_logs` (user_id, action, target, payload_json, ip, ts) — Schema.md 보강

## 수락 기준

- [ ] 옵션 선택
- [ ] 옵션 1: Backend_HTTP.md + Schema.md 보강, Authentication.md RBAC 표
- [ ] 옵션 2: team2 코드 삭제 PR + `audit-events` 로 리디렉트 (deprecated)
- [ ] 옵션 3: internal 마킹 + scanner skip-list 등록


## Resolution

**2026-04-20: 옵션 1 채택** — 별도 리소스 유지, Admin-only filter API

team2 세션에서 코드·스펙 반영 완료:
- Backend_HTTP.md §16 "SG-008 b-분류 결정 스펙" 에 최종 스펙 기록
- 코드 변경: `C:/claude/ebs/team2-backend/src/routers/`
- 상세: Backend_HTTP.md §16 참조

## Changelog

| 날짜 | 버전 | 변경 | 비고 |
|------|------|------|------|
| 2026-04-20 | v1.0 | SG-008 (b) 승격 신규 작성 | Conductor |
| 2026-04-20 | v1.1 | RESOLVED — 옵션 1 채택: 별도 리소스 유지, Admin-only filter API | team2 session |
