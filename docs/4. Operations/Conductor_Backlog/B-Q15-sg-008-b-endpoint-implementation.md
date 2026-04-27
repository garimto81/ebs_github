---
title: B-Q15 — SG-008-b 11건 endpoint 실구현 (team2 우선 작업 7번 cascade)
owner: team2 (or conductor Mode A)
tier: internal
status: IN_PROGRESS (구조 일부 존재, 실구현 필요)
type: backlog
linked-sg: SG-008-b1~b9, b14, b15
linked-decision: B (일괄 채택) + B-Q5 ㉠ (Mode A) + B-Q7 ㉠ (Production-strict)
last-updated: 2026-04-27
---

## 개요

Phase 1 Decision Group B (SG-008-b 11건 일괄 채택) cascade. **team2-backend/CLAUDE.md "우선 작업 7번"** 에 이미 등재된 작업. team2 baseline = 247 tests / 90% coverage.

## 11건 endpoint 현황 (2026-04-27 점검 결과)

| ID | endpoint | 결정 | 구현 현황 (Conductor 점검) |
|----|----------|------|--------------------------|
| SG-008-b1 | `GET /api/v1/audit-events` | RBAC: Admin only | audit.py 에 `list_audit_logs` 존재. audit-events 별도 endpoint 추가 또는 통합 검토 필요 |
| SG-008-b2 | `GET /api/v1/audit-logs` | 별도 리소스 | ✅ audit.py `list_audit_logs` 존재 (admin only RBAC 적용) |
| SG-008-b3 | `GET /api/v1/audit-logs/download` | NDJSON + 100req/min | audit.py 의 csv import 보임 — download endpoint 추가 + NDJSON 형식 확정 + rate limit middleware |
| SG-008-b4 | `GET /api/v1/auth/me` | 확장 필드 | auth.py 에 광범위한 endpoint — auth.me 명시 필요 |
| SG-008-b5 | `POST /api/v1/auth/logout` | current + ?all=true | auth.py 에 svc_logout import 보임 — logout endpoint + ?all 옵션 |
| SG-008-b6 | `POST /api/v1/sync/mock/seed` | env guard dev/staging | sync 라우터 미확인 (별도 sync.py 또는 통합?) |
| SG-008-b7 | `DELETE /api/v1/sync/mock/reset` | env guard dev/staging | 동일 |
| SG-008-b8 | `GET /api/v1/sync/status` | Public + Admin | 동일 |
| SG-008-b9 | `POST /api/v1/sync/trigger/{source}` | Admin + reject | 동일 |
| SG-008-b14 | Settings.`twoFactorEnabled` | User scope | 2FA migration 0006 필요 (team2 우선 작업 8번 등재) |
| SG-008-b15 | Settings.`fillKeyRouting` | NDI fill/key (Hardware Out Phase 2) | Phase 2 기능, 우선순위 낮음 |

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
