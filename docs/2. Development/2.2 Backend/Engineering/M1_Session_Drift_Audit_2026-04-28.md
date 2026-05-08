---
title: M1 Session Drift Audit (2026-04-28)
owner: team2
tier: internal
last-updated: 2026-04-28
related-plan: ~/.claude/plans/role-and-objective-reactive-canyon.md
confluence-page-id: 3819209316
confluence-parent-id: 3811770578
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819209316/EBS+M1+Session+Drift+Audit+2026-04-28
---

# M1 — Backend Multi-session Audit Kickoff (D+0)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-28 | M1+M9 D+0 kickoff (PR #40) | Drift Gate (M9) 조기 적용 + lockout 정책 1건 (M1 Item 1) 정렬. 후속 D+1 항목 명시 |
| 2026-04-28 | M1 Item 2 (PR #42) | JWT blacklist 모듈 + middleware 통합 + Drift Rule 3 |
| 2026-04-28 | M1 Item 3 (PR #43) | user_sessions 복합 PK migration 0009 + Drift Rule 4 |
| 2026-04-28 | **M1 완결** Item 1b+4 (PR 4) | Lock mode permanent sentinel + refresh_delivery Rule + Drift Rule 1b/5. **5/5 SSOT drift 전부 해소** |

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

## M1 완결 매핑 (D+1 종료 시점, 2026-04-28)

| M1 Item | 산출 PR | Drift Rule | 상태 |
|---------|:------:|:---------:|:----:|
| Item 1 — Lockout MAX 5→10 | #40 | Rule 1 | ✅ |
| Item 1b — Lock mode permanent | PR 4 | Rule 1b | ✅ |
| Item 2 — Blacklist 모듈 + middleware | #42 | Rule 3 | ✅ |
| Item 3 — Composite PK migration | #43 | Rule 4 | ✅ |
| Item 4 — Refresh delivery matrix | PR 4 | Rule 5 | ✅ |
| Item 5 — 회귀 테스트 풀세트 | #40/#42/#43/PR 4 부속 | — | ✅ (test_auth + test_blacklist + test_concurrent + permanent_sentinel) |

**Drift Gate 운영**: 5 rules / 0 violations. 향후 동일 도메인의 정책 수치/구조 변경 시 코드 fix 동봉 강제.

**미해소 (별 plan 범위)**:
- `test_refresh_race.py` (concurrent rotation race) — 현 architecture 가 refresh token 을 rotate 안 하므로 race 자체 미발생. M8 Production_Deployment 시 PostgreSQL `SELECT FOR UPDATE` 도입 시 추가 검토.
- X-Device-Id 헤더 router-level 통합 — service layer 에서는 device_id 분리 동작. router 레벨은 후속 feature work (multi-device login UX 정의 시).

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

## 완료 PR 매핑 (M1~M10, 2026-04-28 single session)

| PR # | 마일스톤 | 상태 | 산출물 |
|:----:|---------|:----:|--------|
| #40 | M1 Item 1 + M9 | ✅ | lockout 5→10 + Drift Gate kickoff (1 rule) |
| #42 | M1 Item 2 | ✅ | blacklist 모듈 (`src/security/blacklist.py`) + middleware 통합 + Rule 3 |
| #43 | M1 Item 3 | ✅ | composite PK migration `0009_session_multi_device.py` + Rule 4 |
| #44 | M1 Items 1b + 4 | ✅ | permanent lock sentinel + refresh delivery + Rules 1b/5. **M1 5/5 완결** |
| #45 | M2 | ✅ | `Authentication/Distributed_Architecture.md` (338줄, 토폴로지 + Authority Map + 분산 락 + Failover + 4 ADR) |
| #46 | M3 | ✅ | `Authentication/Token_Lifecycle_Sequences.md` (298줄, Mermaid 7개 시퀀스) |
| #47 | M4 | ✅ | `Backend/Authentication/Concurrency_and_Race_Conditions.md` (285줄, R1~R6) |
| #48 | M6 | ✅ | `Authentication/Troubleshooting_Runbook.md` (344줄, T1~T6 + cheatsheet + Escalation) |
| #49 | M5 | ✅ | `Backend/Authentication/Quickstart_Local_Cluster.md` (220줄) + `docker-compose.cluster.yml` + `tools/seed_admin.py` |
| #50 | M8 | ✅ | `Backend/Authentication/Production_Deployment.md` (390줄, k8s + JWT 회전 + SLO + 롤백) |
| #51 | M7 (BS-01 부분) | ✅ | BS-01 위임 cross-reference 표 추가 (8개 매핑) |
| #52 | M7 (API-06 부분) | ✅ | API-06 위임 cross-reference 표 추가 (7개 매핑) |
| **본 PR** | **M10** | ✅ | 본 IMPL doc 최종 매핑 + Conductor confirm + plan close |

**총 13개 PR** (M1 = 4건 / M2~M8 = 7건 / M7 split = 2건 / M10 = 1건). 모두 squash merge.

## 미해소 / 후속 (별 plan 범위)

| 항목 | 이유 | 다음 단계 |
|------|------|----------|
| `test_refresh_race.py` | 현 architecture 가 refresh rotation 미구현 | M8 PG `SELECT FOR UPDATE` 도입 후 활성화 |
| X-Device-Id 헤더 router 통합 | service layer 분리 완료, router UX 정의 필요 | 별 feature PR (multi-device login UX) |
| Redis backend startup 활성화 (`configure_redis_backend`) | M5 production 시점 결정 | `src/main.py` startup event PR |
| Admin 강등 시 jti revoke + Pub/Sub | M2 §5.3 채널 설계 완료, trigger 구현 필요 | 별 feature PR |
| Rate limit Redis 통합 (per-worker → 분산) | M2 §3 Decision Matrix 정의, 코드 미구현 | M8 production 활성화와 함께 |
| BS-01 754→500 / API-06 461→350 슬림 다운 (content cut) | M7 cross-reference 만 추가, content cut 은 SSOT 정합 위험 | focused 세션에서 한 줄씩 mapping 검증 후 cut |
| 3팀 (team1/team4) 리뷰 라운드 | autonomous session 한계 | 사용자 또는 팀 세션에서 진행 |

## 참조

- Plan: `~/.claude/plans/role-and-objective-reactive-canyon.md`
- BS-01 SSOT: `docs/2. Development/2.5 Shared/Authentication.md` §자동 잠금 정책 (line 644)
- API-06 계약: `docs/2. Development/2.2 Backend/APIs/Auth_and_Session.md`
- CCR-048 근거: WSOP LIVE Confluence Page 1972863063 (10회 자동 잠금)
- Drift detector: `tools/spec_drift_check.py::detect_auth()`
- CI gate: `.github/workflows/spec-drift-gate.yml`
