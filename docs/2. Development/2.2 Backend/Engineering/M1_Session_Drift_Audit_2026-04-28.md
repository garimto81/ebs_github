---
title: M1 Session Drift Audit (2026-04-28)
owner: team2
tier: internal
last-updated: 2026-04-28
related-plan: ~/.claude/plans/role-and-objective-reactive-canyon.md
---

# M1 — Backend Multi-session Audit Kickoff (D+0)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-28 | M1+M9 D+0 kickoff | Drift Gate (M9) 조기 적용 + lockout 정책 1건 (M1 Item 1) 정렬. 후속 D+1 항목 명시 |

## 개요

본 문서는 **Backend Multi-session 분산 IA 신설 plan** (audit 경로:
`~/.claude/plans/role-and-objective-reactive-canyon.md`) 의 **M1 (Drift 정량 해소)
+ M9 (CI Drift Gate)** 마일스톤 진행 추적이다.

D+0 목표는 사용자 요청대로 **"M1 브랜치 + Drift Gate CI 파이프라인 초안 PR 링크"**
공유. 본 PR (`work/team2/m1-session-drift`) 이 그 산출물이며, 후속 D+1~D+9 작업은
별 PR 들로 분리 진행한다.

## D+0 산출물 (본 PR 에 포함)

| Item | 파일 | 동작 검증 |
|------|------|-----------|
| Drift detector (auth) | `tools/spec_drift_check.py` `detect_auth()` (~95줄 추가) | `python tools/spec_drift_check.py --auth` 실행 시 0 violation (fix 적용 후) |
| Drift Gate workflow | `.github/workflows/spec-drift-gate.yml` (신규) | PR 트리거 + path filter + comment + fail-on-violation |
| Lockout 정책 fix (M1 Item 1) | `team2-backend/src/services/auth_service.py` `_MAX_FAILED_ATTEMPTS = 10` (was 5) | BS-01 §자동 잠금 정책 SSOT (CCR-048) 정렬 |
| 회귀 테스트 (lockout) | `team2-backend/tests/test_auth_lockout.py` (신규) | pytest 1 case: 9회 실패 unlocked / 10회 실패 locked |
| IMPL 추적 문서 | 본 문서 | D+1+ 후속 항목 표 |

## D+0 미달성 (D+1 이후 별 PR)

| M1 Item | 산출물 (예정) | 추가 detect_auth 룰 |
|---------|--------------|---------------------|
| Item 1b — Lock mode | `auth_service.py` `_LOCK_DURATION_MIN` 폐기 + `is_locked` boolean 도입 + Admin unlock 경로 | Rule 2: spec='permanent' vs code 의 timed lock 잔존 |
| Item 2 — Blacklist 모듈 | `team2-backend/src/security/blacklist.py` 신설 (Redis SETEX with jti TTL) + `middleware/rbac.py` 통합 | Rule 3: spec 의 `blacklist:jti:{jti}` 언급 vs `src/security/blacklist.py` 파일 존재 |
| Item 3 — Composite PK | `team2-backend/migrations/0007_session_multi_device.sql` + `init.sql` `user_sessions` PK `(user_id, device_id)` | Rule 4: spec 의 "최대 동시 세션 2" vs DDL `UNIQUE(user_id)` |
| Item 4 — Refresh delivery matrix | `auth_router.py` 환경별 분기 검증 강화 + 테스트 | Rule 5: spec 의 `refresh_token_delivery` 표 vs 코드 분기 |
| Item 5 — 회귀 테스트 풀세트 | `test_blacklist_propagation.py`, `test_concurrent_sessions.py`, `test_refresh_race.py` (3건) | — (Item 별 PR 에 부속) |

## Drift Gate 운영 정책

### 현재 (D+0 ~ D+1 중)
- **Mode**: Fail-on-violation (`exit 1` if total > 0)
- **Scope**: `--auth` (1 rule)
- **Trigger**: PR 시 paths-filter 매칭 변경 발생 시만

### D+1 이후 확장 시 절차
1. detect_auth() 에 새 rule 추가
2. **동시에** 해당 fix 코드를 같은 PR 에 포함
3. 로컬에서 `python tools/spec_drift_check.py --auth` 0 확인
4. PR open → Drift Gate 자동 실행
5. PASS 시 squash merge

> ⚠️ 새 rule 추가 시 fix 코드 동봉을 잊으면 본인 PR 이 즉시 fail. 이는 의도된 동작 (TDD 와 같은 정렬 강제).

### 다른 contract 추가 (--api/--schema 확장)
M1 외 다른 도메인 (api, schema 등) 의 drift gate 강제는 본 plan 범위 밖. 별 plan
필요 (각 detector 의 false positive 비율 사전 측정 후 결정).

## 검증 명령

```bash
# 로컬 (worktree 안에서)
cd C:/claude/ebs-team2-m1-drift
python tools/spec_drift_check.py --auth
# expected: total=0

# 회귀 테스트
cd team2-backend
python -m pytest tests/test_auth_lockout.py -v
# expected: 1 PASS

# 전체 회귀 baseline
python -m pytest tests/ -v
# expected: ≥247 PASS (M1 변경이 기존 테스트 깨지 않음 검증)
```

## 후속 PR 일정 (plan 마일스톤 매핑)

| PR # | 마일스톤 | 산출물 |
|:----:|---------|--------|
| **1 (본 PR)** | **M1 Item 1 + M9** | lockout 정렬 + Drift Gate kickoff |
| 2 | M1 Item 2 | blacklist 모듈 + middleware 통합 + Rule 3 추가 |
| 3 | M1 Item 3 | composite PK migration + DDL + Rule 4 추가 |
| 4 | M1 Item 4+5 | refresh delivery 정합 + 회귀 테스트 풀세트 + Rule 5 |
| 5 | M2 | `Distributed_Architecture.md` 신설 |
| 6 | M3 | `Token_Lifecycle_Sequences.md` (Mermaid 7개) |
| 7 | M4 | `Concurrency_and_Race_Conditions.md` |
| 8 | M5 | `Quickstart_Local_Cluster.md` + `docker-compose.cluster.yml` |
| 9 | M6 | `Troubleshooting_Runbook.md` |
| 10 | M7 | BS-01 754→500 + API-06 461→350 슬림화 |
| 11 | M8 | `Production_Deployment.md` |
| 12 | M10 | 3팀 리뷰 + main merge gate 통과 + plan close |

## 참조

- Plan: `~/.claude/plans/role-and-objective-reactive-canyon.md`
- BS-01 SSOT: `docs/2. Development/2.5 Shared/Authentication.md` §자동 잠금 정책 (line 644)
- API-06 계약: `docs/2. Development/2.2 Backend/APIs/Auth_and_Session.md`
- CCR-048 근거: WSOP LIVE Confluence Page 1972863063 (10회 자동 잠금)
- Drift detector: `tools/spec_drift_check.py::detect_auth()`
- CI gate: `.github/workflows/spec-drift-gate.yml`
