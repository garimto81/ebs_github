---
title: B-Q15 — SG-008-b 11건 endpoint 실구현 (team2 우선 작업 7번 cascade)
owner: team2 (or conductor Mode A)
tier: internal
status: DONE-PARTIAL (b4/b5/b6/b7/b8 Conductor Mode A 보강 완료 2026-04-27, b1/b3/b14/b15 잔여)
resolved_partial: 2026-04-27
resolved_by: conductor (Mode A)
type: backlog
linked-sg: SG-008-b1~b9, b14, b15
linked-decision: B (일괄 채택) + B-Q5 ㉠ (Mode A) + B-Q7 ㉠ (Production-strict)
last-updated: 2026-04-27
confluence-page-id: 3819274985
confluence-parent-id: 3811573898
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819274985/EBS+B-Q15+SG-008-b+11+endpoint+team2+7+cascade
---

## 개요

Phase 1 Decision Group B (SG-008-b 11건 일괄 채택) cascade. **team2-backend/CLAUDE.md "우선 작업 7번"** 에 이미 등재된 작업. team2 baseline = 247 tests / 90% coverage.

## 11건 endpoint 현황 (2026-04-27 Conductor Mode A 진행 후)

| ID | endpoint | 결정 | 진행 결과 (Conductor Mode A 2026-04-27) |
|----|----------|------|----------------------------------------|
| SG-008-b1 | `GET /api/v1/audit-events` | RBAC: Admin only | ⏳ **보류** — 현재 `get_current_user` (모든 인증). RBAC 변경 시 기존 테스트 영향 우려. 별도 turn 신중 처리 |
| SG-008-b2 | `GET /api/v1/audit-logs` | 별도 리소스 | ✅ **DONE** (사전 구현됨, admin only RBAC) |
| SG-008-b3 | `GET /api/v1/audit-logs/download` | NDJSON + 100req/min | ⏳ **보류** — 현재 CSV. NDJSON 추가 + rate limit middleware 별도 turn |
| SG-008-b4 | `GET /api/v1/auth/me` | 확장 필드 | ✅ **DONE** Mode A — MeResponse 에 `permissions` (role 기반 derive) + `settingsScope` (user-level identifier) 추가. `_ROLE_PERMISSIONS` 매핑 (admin/operator/viewer) |
| SG-008-b5 | `POST /api/v1/auth/logout` | current + ?all=true | ✅ **DONE** Mode A — `?all: bool = False` query param + response `scope` marker. 현재 single-session 모델, future-proof api |
| SG-008-b6 | `POST /api/v1/sync/mock/seed` | env guard dev/staging | ✅ **DONE** Mode A — `_require_dev_or_staging` dependency. `auth_profile in ("dev", "staging")` 가드. prod/live 시 403 ENV_GUARD_PROD_FORBIDDEN |
| SG-008-b7 | `DELETE /api/v1/sync/mock/reset` | env guard dev/staging | ✅ **DONE** Mode A — 동일 (b6 와 페어) |
| SG-008-b8 | `GET /api/v1/sync/status` | Public + Admin | ✅ **DONE** Mode A — response 에 `scope` marker (`admin` or `public`). 향후 admin sanitize 가능 |
| SG-008-b9 | `POST /api/v1/sync/trigger/{source}` | Admin + reject | ✅ **DONE** (사전 구현됨, admin only + 알 수 없는 source 400) |
| SG-008-b14 | Settings.`twoFactorEnabled` | User scope | ⏳ **보류** — 2FA migration 0006 필요 (DB schema 변경). team2 우선 작업 8번. 별도 turn |
| SG-008-b15 | Settings.`fillKeyRouting` | NDI fill/key (Hardware Out Phase 2) | ⏳ **보류** — Phase 2 기능, 우선순위 낮음 |

**진행 요약**: 7/11 = DONE (b2/b4/b5/b6/b7/b8/b9), 4/11 = 보류 (b1/b3/b14/b15).

## Mode A 진행 결과 (2026-04-27)

| 영역 | 결과 |
|------|:----:|
| 코드 보강 | auth.py + sync.py surgical edit. 5 endpoint 보강 (b4/b5/b6/b7/b8) |
| 테스트 추가 | tests/test_sg008b_extensions.py NEW — 13 cases |
| pytest regression | **261 passed, 0 failed in 114.79s** (baseline 247 → +14) |
| Coverage 측정 | 미수행 (B-Q10 cascade 후속) |
| OWASP audit | 미수행 (B-Q11 cascade 후속) |
| 100ms SLA 측정 | 미수행 (B-Q12 cascade 후속) |

## team2-backend/CLAUDE.md 우선 작업 7번 인용

> 7. **SG-008 (b1~b9) 9 endpoint 실구현** — audit-events/logs-read/download, auth-me/logout, sync-status/trigger, sync-mock-seed/reset
> 8. **SG-008-b14 2FA migration 0006** — users 테이블 twofa_enabled/secret/backup_codes 컬럼 + 6 endpoint 구현

## 처리 옵션

| 옵션 | 의미 |
|:----:|------|
| ㉠ | team2 세션 자체 처리 (우선 작업 7/8번 진행) — 표준 Mode B |
| ㉡ | Conductor Mode A — Conductor 가 직접 endpoint 보강 |
| ㉢ | 단계 분할 — sync_router.py 신규 (b6/b7/b8/b9) → 후속 audit-events 별도 endpoint → 2FA migration |

## 우선순위

P1 — B-Q7 ㉠ Production-strict 의 endpoint 완결 + Phase 0 (~ 2026-12) 의 backend 인프라.

## 참조

- Spec_Gap_Registry SG-008-b1~b9, b14, b15
- team2-backend/CLAUDE.md "우선 작업 7/8번"
- team2-backend/src/routers/audit.py (b1/b2/b3 부분 구현)
- team2-backend/src/routers/auth.py (b4/b5 부분 구현)
- team2-backend baseline: 247 tests / 90% coverage
