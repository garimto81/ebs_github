---
title: OWASP Top-10 Audit Kickoff Report — team2-backend
owner: conductor
tier: internal
created: 2026-05-03
created-by: conductor (Mode A 자율, R2 critic resolution)
linked-decisions:
  - B-Q11 OWASP audit (PENDING)
  - B-Q7 ㉠ Production-strict (security gate)
audit-tools:
  - bandit 1.9.2 (SAST)
  - pip-audit 2.10.0 (SCA — dependency CVE)
last-updated: 2026-05-03
reimplementability: PASS
---

# OWASP Top-10 Audit Kickoff — team2-backend

## TL;DR

| 영역 | 결과 |
|------|:----:|
| SAST (bandit) — High severity | **0** ✓ |
| SAST (bandit) — Medium severity | 2 (false positive 의심) |
| SCA (pip-audit) — Critical CVEs in EBS deps | **3** (transitive, fix straightforward) |
| Manual threat-model | 본 문서 §3 |
| Pen-test | **NOT YET** (별도 cascade) |

production-launch (2027-01) 9개월 전 baseline. **HIGH severity 0** 은 긍정 신호이나 CVE 3건 + manual threat-model 갭 = **Phase 1 launch 전 R2 후속 cascade 필수**.

## 1. SAST (Static Application Security Testing) — bandit

### 실행

```bash
cd team2-backend && python -m bandit -r src/
```

- Code scanned: 7980 LoC
- Run timestamp: 2026-05-03 04:30 UTC

### 결과 분포

| Severity | 개수 | Confidence 분포 |
|:--------:|:----:|----------------|
| **High** | **0** | — |
| Medium | 2 | Low confidence (false positive likely) |
| Low | 4 | Mixed |
| Total | 6 | — |

### Medium severity 상세 (B608 — SQL injection)

| File | Line | Pattern | 평가 |
|------|:----:|---------|------|
| `src/services/wsop_sync_service.py` | 641 | `text(f"DELETE FROM {tbl}")` (hardcoded list iteration) | **False positive** — `tbl` 은 함수 내 hardcoded list `["deck_cards", "decks", ...]` 의 iteration. 사용자 입력 무관 |
| `src/services/wsop_sync_service.py` | 646 | `text(f"DELETE FROM {tbl} WHERE source='api'")` | **False positive** — 동일 (table name list 는 literal) |

**처리**: `# nosec B608` 주석 추가 권고 (audit 통과 + 의도 명시). 실 보안 위험 없음.

## 2. SCA (Software Composition Analysis) — pip-audit

### 실행

```bash
cd team2-backend && pip-audit
```

### EBS 직접 의존 CVE (filtered from global env)

| Package | Current | Fix Version | CVE | Severity (EBS context) |
|---------|:-------:|:-----------:|-----|:---------------------:|
| python-multipart | 0.0.19 | 0.0.22+ | CVE-2026-24486, CVE-2026-40347 | **HIGH** (multipart parse — file upload endpoints affected) |
| python-dotenv | 1.0.1 | 1.2.2 | CVE-2026-28684 | LOW (parsing, not exploited at runtime) |
| werkzeug | 3.1.5 | 3.1.6 | CVE-2026-27199 | MEDIUM (transitive, depends on usage path) |
| pytest | 8.3.4 | 9.0.3 | CVE-2025-71176 | LOW (dev-only, not in prod image) |

### Production-build CVE 처리

```bash
pip install --upgrade python-multipart==0.0.22 werkzeug==3.1.6 python-dotenv==1.2.2
```

또는 `pyproject.toml` 에 명시 pin:

```toml
dependencies = [
    "python-multipart>=0.0.22",
    "werkzeug>=3.1.6",
    "python-dotenv>=1.2.2",
    ...
]
```

## 3. OWASP Top-10 Manual Coverage Matrix

| OWASP 항목 | EBS 현 상태 | 검증 도구 | Phase 1 게이트 |
|-----------|:----------:|----------|:--------------:|
| **A01:2021 Broken Access Control** | RBAC 3-role (Admin/Operator/Viewer) 구현 | pytest test_auth.py + test_security_middleware.py | ✓ baseline |
| **A02:2021 Cryptographic Failures** | bcrypt password hash + JWT HS256 + cryptography 패키지 | manual review | ✓ baseline |
| **A03:2021 Injection** | SQLModel + parametrized queries + bandit B608 0 true-positive | bandit | ✓ |
| **A04:2021 Insecure Design** | threat-model **PENDING** (별도 cascade) | manual | ⚠ |
| **A05:2021 Security Misconfiguration** | CORS_ORIGINS env + JWT_SECRET prod override 명시 | docker-compose.yml + env audit | ⚠ JWT_SECRET 기본값 위험 |
| **A06:2021 Vulnerable Components** | pip-audit 3 CVE (위 §2) | pip-audit | ⚠ 위 fix 반영 후 ✓ |
| **A07:2021 Auth Failures** | JWT access/refresh + bcrypt + 2FA scaffold (B14) | pytest + test_auth_security.py | ⚠ 2FA 미구현 |
| **A08:2021 SW & Data Integrity** | seq 단조증가 (WS) + Idempotency-Key + audit_events | test_idempotency.py + test_publishers.py | ✓ baseline |
| **A09:2021 Logging Failures** | audit_events + audit_logs DB + observability/ | manual review | ✓ baseline |
| **A10:2021 SSRF** | wsop_sync 외부 호출 — URL whitelist 검증 필요 | manual review | ⚠ |

### 우선순위 (Phase 1 launch 전 처리)

1. **P0 — A06 dependency upgrade** (3 CVE fix) — surgical 1 turn
2. **P0 — A05 JWT_SECRET prod override 강제** — production env validation
3. **P1 — A04 threat-model** — DFD + STRIDE workshop (별도 cascade)
4. **P1 — A07 2FA enable** — SG-008-b14 scaffold 활성화
5. **P1 — A10 SSRF whitelist** — wsop_sync URL 검증
6. **P2 — Pen-test** — 외부 vendor 또는 Phase 1 직전 in-house

## 4. 후속 cascade (B-Q11 변경)

본 audit kickoff 으로 B-Q11 status 변경 권고: **PENDING → IN_PROGRESS** (baseline 확립).

| 후속 작업 | 권장 시점 | 담당 |
|----------|:---------:|------|
| python-multipart / werkzeug / python-dotenv upgrade | 즉시 (1 turn) | conductor Mode A |
| JWT_SECRET prod override 강제 (`config.py` validator) | Phase 0 freeze 전 | team2 |
| 2FA enable (SG-008-b14 활성화) | Phase 0 freeze 전 | team2 |
| Threat-model DFD + STRIDE | Phase 0.5 시점 | conductor + team2 |
| Pen-test (3rd-party) | Phase 1 직전 (2026-12) | external vendor |

## 5. 검증 evidence

```bash
# bandit baseline
$ python -m bandit -r src/ -ll
Total issues (by severity):
    Undefined: 0
    Low: 4
    Medium: 2
    High: 0

# pip-audit (EBS deps only — filtered)
python-multipart 0.0.19 → 0.0.22  CVE-2026-24486
werkzeug         3.1.5  → 3.1.6   CVE-2026-27199
python-dotenv    1.0.1  → 1.2.2   CVE-2026-28684
```

## Changelog

| 날짜 | 버전 | 변경 |
|------|------|------|
| 2026-05-03 | v1.0 | 최초 작성 (B-Q11 baseline) |
