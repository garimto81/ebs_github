---
title: B-Q11 — OWASP Top 10 audit (B-Q7 ㉠ Production-strict cascade)
owner: conductor
tier: internal
status: PENDING
type: backlog
linked-sg: SG-026
linked-decision: B-Q7 ㉠ (Production-strict)
last-updated: 2026-04-27
---

## 개요

B-Q7 ㉠ (Production-strict) 채택으로 OWASP Top 10 준수가 production 게이트. **EBS 시스템 종합 보안 audit 수행 plan 필요**.

## OWASP Top 10 (2021) 영역별 EBS 점검

| ID | 영역 | EBS 점검 대상 |
|----|------|--------------|
| A01 | Broken Access Control | API-06 RBAC, JWT 토큰, 5-level Settings scope |
| A02 | Cryptographic Failures | password hash, JWT secret, refresh cookie HttpOnly+Secure+SameSite (이미 적용 — auth.py) |
| A03 | Injection | SQLModel ORM (이미 적용), input validation (Pydantic) |
| A04 | Insecure Design | API-06 2FA, audit log 영구 보존 |
| A05 | Security Misconfiguration | env guard (sync/mock dev-only — SG-008-b6/b7), Docker 이미지 hardening |
| A06 | Vulnerable Components | dependency 자동 audit (pip-audit, npm-audit) |
| A07 | Identification and Authentication Failures | session timeout, 2FA, password policy |
| A08 | Software and Data Integrity Failures | git commit 추적성 (이미 강함), CI/CD 무결성 |
| A09 | Security Logging and Monitoring Failures | audit_logs (이미 구현), audit_events |
| A10 | Server-Side Request Forgery (SSRF) | 외부 API 호출 (WSOP LIVE 폴링) URL whitelist |

## 처리 작업

1. **자동 audit 도구 통합** — pip-audit, bandit (Python), npm audit, ESLint security plugin
2. **수동 audit checklist** — OWASP ASVS Level 2 기준
3. **Penetration test** (선택, Phase 1 런칭 전 외부 audit 권장)
4. **Audit log 정책** — 보존 기간 / 접근 권한 / 삭제 금지

## 우선순위

P1 — B-Q7 ㉠ 직접 cascade. Phase 1 (2027-01 런칭) 직전 외부 audit 권장.

## 참조

- Spec_Gap_Registry SG-026 (B-Q7 quality gates)
- memory `project_intent_production_2026_04_27`
- 현재 보안 자산: src/security/jwt.py, src/middleware/rbac.py (auth.py), audit_log/audit_event 모델
