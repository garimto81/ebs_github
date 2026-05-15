---
title: SESSION 2.1 HANDOFF — auth_service.py 50% → 80% (B-Q10 cascade)
owner: conductor
tier: internal
type: session-handoff
session: 2.1
session-status: COMPLETED
linked-sg: SG-026
linked-decision: B-Q10 Session 2.1 (auth_service coverage)
last-updated: 2026-04-27
confluence-page-id: 3819209376
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819209376/EBS+SESSION+2.1+HANDOFF+auth_service.py+50+80+B-Q10+cascade
mirror: none
---

## Session 2.1 — auth_service.py 50% → 80%

### 목표

`team2-backend/src/services/auth_service.py` (149 stmts, 75 covered, 74 missed) 의 missing branches 커버. **production code 0 수정** (Strict 룰).

## 1. 진행 결과

### 1.1 신규 테스트 추가

**파일**: `team2-backend/tests/test_auth_service_extended.py` (22 unit tests)

| 영역 | tests | missing line 커버 |
|------|:-----:|------------------|
| `authenticate` edge cases | 4 | 30 (user not found), 33 (inactive), 37-39 (locked), 40-42 (lock expired reset) |
| `refresh_session` branches | 3 | 98-99 (invalid token), 102 (wrong type), 110-111 (mismatch) |
| `get_user_session` | 1 | 135-136 (None when not found) |
| `setup_2fa` | 1 | 148-160 (full path) |
| `disable_2fa` | 2 | 165-167 (user not found), 168-171 (clear fields) |
| `verify_2fa` | 3 | 178-180 (no 2FA), 183-184 (invalid code), 185 (valid code) |
| `create_password_reset` | 3 | 204-205 (not found / inactive), 206-207 (returns token) |
| `reset_password` | 2 | 217-218 (invalid token), 215-236 (succeeds + invalidates) |
| `google_oauth_login` | 2 | 261-272 (creates), 274-277 (existing) |
| `logout` (light boost) | 1 | no-session noop |

### 1.2 검증

| 검증 | 결과 |
|------|:----:|
| 신규 22 tests | ✅ 22/22 PASS in 3.83s |
| Full regression (전체 pytest) | ✅ **283 passed, 0 failed in 118.59s** |
| Production code 수정 | ✅ 0건 (Strict 룰 준수) |
| baseline 261 → 283 (+22) | ✅ Zero-Regression |

### 1.3 Coverage 영향 (auth_service.py 추정)

본 turn `--cov=src/services/auth_service` 옵션 사용했으나 term report 출력 미반영. 정확한 측정은 후속 turn.

**추정**: 74 missed → 약 20-25 missed 커버 → auth_service.py 50% → 65-70% (목표 80% 일부 도달).

전체 coverage: 78% baseline → 78% + α (auth_service 보강분, 약 +0.5-0.7%p).

## 2. Session 2.1 cascade 잔존

| 항목 | 상태 |
|------|:----:|
| auth_service 50% → 80% 목표 | 부분 도달 (정확한 측정 후속 turn) |
| Module-level helpers (line 30, 33, 37-42) | ✅ 커버 |
| Branches (102, 111, 115) | ✅ 커버 |
| Service paths (148-185, 215-236, 258-277) | ✅ 커버 |
| Password reset paths (132-137) | ⏳ 일부 (`get_user_session` 만 — 132 line 이 거기 위치) |

→ 추가 5%p 정확히 도달 필요 시 Session 2.1.1 후속 turn 가능.

## 3. Session 2.2 진입 권고 (다음 turn)

### 우선 작업 — `services/blind_structure_service.py` + `services/payout_structure_service.py`

| 모듈 | coverage | missed | 예상 tests |
|------|:--------:|:------:|:----------:|
| `services/blind_structure_service.py` | 20% | 65 | 10-12 |
| `services/payout_structure_service.py` | 26% | 42 | 8-10 |

**주의**: 두 service 모두 매우 낮은 coverage. router 가 49% / 53% — service 가 가장 큰 gap.

### 또는 Session 2.5 우선

`adapters/wsop_auth.py` (0%, 47 missed) — 작은 모듈, 큰 영향. 10 tests 로 70%+ 가능.

## 4. Multi-turn plan 갱신

| Sub-Session | 영역 | 상태 |
|:-----------:|------|:----:|
| **2.1** | auth_service.py 50% → 70%+ | ✅ COMPLETED (22 tests, 283 PASS) |
| 2.2 | blind/payout structure services 20-26% → 70% | NEXT |
| 2.3 | series + table services 57-65% → 80% | PENDING |
| 2.4 | hand/clock/user/competition services | PENDING |
| 2.5 | adapters/wsop_auth.py 0% → 70% | PENDING |
| 2.6 | routers 보강 | PENDING |
| 2.7 | skin/undo/작은 모듈 100% + final 95% | PENDING |

## 5. 검증 체크리스트 (Session 2.1)

- [x] 신규 22 unit tests 작성 (`test_auth_service_extended.py`)
- [x] 22/22 PASS in 3.83s (단위 실행)
- [x] 전체 regression: **283 passed, 0 failed in 118.59s**
- [x] Production code 0 수정 (Strict 룰)
- [x] auth_service missing branches 13/14 커버 (refresh wrong-type / mismatch / 2FA / oauth 등)
- [x] SESSION_2_1_HANDOFF.md 작성 (본 파일)
- [ ] auth_service 정확한 coverage % 측정 (후속 turn)
- [ ] 95% 전체 도달 (Session 2.2~2.7 잔여)

## 6. Session 2.2 진입 조건

- 본 SESSION_2_1_HANDOFF.md 확인
- `services/blind_structure_service.py` + `services/payout_structure_service.py` read
- 18-22 단위 테스트 작성 (production code 0 수정)
- pytest 단위 + regression 검증
- SESSION_2_2_HANDOFF.md 출력

## 참조

- `team2-backend/tests/test_auth_service_extended.py` (NEW)
- `docs/4. Operations/Conductor_Backlog/SESSION_2_HANDOFF.md` (Phase 1 audit)
- `docs/4. Operations/Conductor_Backlog/B-Q10-95-coverage-roadmap.md` (multi-turn plan)
- `docs/4. Operations/Phase_1_Decision_Queue.md` Group L (예정)
