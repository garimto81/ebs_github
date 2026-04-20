---
id: SG-008-b9
title: "POST /api/v1/sync/trigger/{source} RBAC + 환경 제약 판정"
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
---

# SG-008-b9 — `POST /api/v1/sync/trigger/{source}` 수동 트리거 RBAC

## 배경

SG-008 §"b분류" 에서 승격. Sync worker 를 수동으로 강제 실행하는 관리 endpoint. 기획 EBS_Core.md 의 sync 워커는 자동(polling) 가정만 기술.

## 대상 endpoint (code-only)

- `POST /api/v1/sync/trigger/{source}` — sync 강제 실행. `{source}` = `wsop-live` | `mock` | `internal`

## 논점

1. RBAC — Admin only 확실. Operator/Viewer 허용 불가
2. `{source}` enum 범위 — Phase 별로 허용 source 가 확장 (wsop-live Phase 1, internal Phase 2+)
3. sync job 충돌 — 이미 실행 중인 sync 가 있으면 queue? reject?
4. rate limit — 과도 호출 방지

## 결정 옵션

| 옵션 | 장점 | 단점 |
|------|------|------|
| 1. Admin only, rate limit 1/min, concurrent=1 (실행 중이면 409) | 단순/안전 | 장기 실행 sync 중 차단 |
| 2. Admin only, queued (실행 중이면 대기) | 재시도 불필요 | 큐 구현 필요 |
| 3. 코드 삭제 — sync worker 자동 실행만 허용 | Drift 해소 최단 | 장애 시 수동 복구 불가 |

## Default 제안

**옵션 1 (Admin only, rate limit 1/min, concurrent reject)**. 이유:
- 수동 sync trigger 는 sync worker 장애·지연 복구용 escape hatch — 장기 큐잉은 불필요
- 409 Conflict 반환은 운영자가 상황 파악 후 재시도 결정하는 게 투명
- WSOP LIVE `SignalR Service §SyncTrigger` 도 동일 reject 패턴
- rate limit 1/min 은 충분 (보통 1회 실행이면 해소)

**스펙 제안 초안**:
- `POST /api/v1/sync/trigger/{source}` — Admin only, rate limit 1/min per user
- path param: `{source}` = `wsop-live` (Phase 1) / `mock` (dev/staging only, SG-008-b6 env 가드와 동일) / `internal` (Phase 2+)
- Body: `{ force: bool }` (force=true 면 마지막 성공 이후 delta 만 이 아닌 full resync)
- Response: `202 Accepted { job_id, started_at }` — 비동기 실행. 상태는 `/sync/status` 로 조회
- 409 Conflict — 이미 sync 실행 중
- 404 Not Found — `{source}` enum 에 없거나 env 제약 위반

## 수락 기준

- [ ] 옵션 선택
- [ ] 옵션 1: Backend_HTTP.md + EBS_Core.md §sync 섹션 보강 + rate limit 정책
- [ ] 옵션 2: queue 인프라 별도 SG 승격
- [ ] 옵션 3: team2 코드 삭제


## Resolution

**2026-04-20: 옵션 1 채택** — Admin-only, scope 파라미터 기반. sync/wsop-live alias — Phase 2+에서 단일화

team2 세션에서 코드·스펙 반영 완료:
- Backend_HTTP.md §16 "SG-008 b-분류 결정 스펙" 에 최종 스펙 기록
- 코드 변경: `C:/claude/ebs/team2-backend/src/routers/`
- 상세: Backend_HTTP.md §16 참조

## Changelog

| 날짜 | 버전 | 변경 | 비고 |
|------|------|------|------|
| 2026-04-20 | v1.0 | SG-008 (b) 승격 신규 작성 | Conductor |
| 2026-04-20 | v1.1 | RESOLVED — 옵션 1 채택: Admin-only, scope 파라미터 기반. sync/wsop-live alias — Phase 2+에서 단일화 | team2 session |
