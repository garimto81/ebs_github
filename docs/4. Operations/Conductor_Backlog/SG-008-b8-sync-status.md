---
id: SG-008-b8
title: "GET /api/v1/sync/status 공개 범위 판정"
type: spec_gap
sub_type: spec_drift_b_escalated
parent_sg: SG-008
status: RESOLVED
owner: conductor
decision_owners_notified: [team2]
created: 2026-04-20
affects_chapter:
  - docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md
  - docs/2. Development/2.5 Shared/EBS_Core.md
protocol: Spec_Gap_Triage §7.2
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "2026-04-20 RESOLVED — 옵션 1 채택 (team2 세션 구현 완료)"
tier: internal
backlog-status: open
---

# SG-008-b8 — `GET /api/v1/sync/status` 공개 범위

## 배경

SG-008 §"b분류" 에서 승격. WSOP LIVE ↔ EBS 동기화 상태 관측 endpoint. 기획 EBS_Core.md 에 sync worker 는 정의되어 있으나 observability API 는 누락.

## 대상 endpoint (code-only)

- `GET /api/v1/sync/status` — sync worker 상태 조회

## 논점

1. RBAC — Admin only? Lobby UI 에서 sync 지연 경고 표시에 필요하면 Operator/Viewer 에게도 필요
2. 반환 필드 — `{ last_sync_ts, lag_seconds, status, error_count }` 수준?
3. 공개 범위 — 외부 모니터링(Prometheus) 연계? `/metrics` 로 통합?
4. Phase 별 정책 — Phase 1(단일 source) vs Phase 2+(multi-source WSOP LIVE/internal)

## 결정 옵션

| 옵션 | 장점 | 단점 |
|------|------|------|
| 1. Public (all authenticated), 읽기 전용 `{ last_sync_ts, lag_seconds, status }` | Lobby UI 실시간 상태 배너 가능. 운영 투명성 | 권한 세분화 없음 |
| 2. Admin only + 확장 필드 (error_count, stacktrace) | 운영자 관점 유리 | Lobby UI 에서 별도 경로로 동일 정보 재조회 필요 |
| 3. `/metrics` prometheus 통합, 본 endpoint 삭제 | 표준 관측성 | 비-Prometheus 환경에서는 접근 어려움 |

## Default 제안

**옵션 1 (Public authenticated, 최소 필드)** + Admin 전용 확장 필드는 별도 `/api/v1/sync/status/detail` 로 분리. 이유:
- Lobby 실시간 sync 상태 배너는 UX 필수 (delay 시 사용자에게 알림)
- WSOP LIVE Confluence `SignalR Service §SyncStatus` 도 동일 Public 패턴
- Admin 전용 상세(`/detail`)는 error stacktrace 등 민감 정보 격리

**스펙 제안 초안**:
- `GET /api/v1/sync/status` — 모든 authenticated user
  - Response: `{ last_sync_ts, lag_seconds, status: "healthy"|"degraded"|"down", source: "wsop-live" }`
- `GET /api/v1/sync/status/detail` — Admin only
  - Response: `{ ...basic, error_count_24h, last_error, worker_pid, uptime_seconds }`
- `/metrics` 로도 동시 export (Prometheus counter/gauge)

## 수락 기준

- [ ] 옵션 선택
- [ ] 옵션 1: Backend_HTTP.md 섹션 + Lobby UI 와 계약 (Frontend Engineering.md §sync-status-banner)
- [ ] 옵션 2: Admin only 명시, Lobby UI 별도 경로 설계 필요 시 SG 승격
- [ ] 옵션 3: /metrics 스펙 확장 + team2 코드 삭제


## Resolution

**2026-04-20: 옵션 1 채택** — Admin-only aggregate status (last_sync + conflicts_pending + CB)

team2 세션에서 코드·스펙 반영 완료:
- Backend_HTTP.md §16 "SG-008 b-분류 결정 스펙" 에 최종 스펙 기록
- 코드 변경: `C:/claude/ebs/team2-backend/src/routers/`
- 상세: Backend_HTTP.md §16 참조

## Changelog

| 날짜 | 버전 | 변경 | 비고 |
|------|------|------|------|
| 2026-04-20 | v1.0 | SG-008 (b) 승격 신규 작성 | Conductor |
| 2026-04-20 | v1.1 | RESOLVED — 옵션 1 채택: Admin-only aggregate status (last_sync + conflicts_pending + CB) | team2 session |
