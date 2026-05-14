---
title: Worktree Cleanup Report (v8.0 Phase 9 — Decision 3A)
owner: conductor
tier: internal
status: cleanup-candidates-identified
last-updated: 2026-04-28
related:
  - docs/4. Operations/Conductor_Backlog/v8-phase9-governance-decisions.md (결정 3A)
confluence-page-id: 3819766444
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819766444/EBS+Worktree+Cleanup+Report+v8.0+Phase+9+Decision+3A
---

# Worktree Cleanup Report

## 결정 3A 의 의미

사용자 결정: **3A — merged 작업의 worktree 만 cleanup 후보 list 제출** (실 cleanup 은 사용자 명시 필요).

이유: worktree 는 사용자 작업 환경. 자율 cleanup = 작업 손실 risk. Conductor 자율 = "merged" 만 식별 + report.

## 17 Active Worktrees (2026-04-28)

| # | Worktree 경로 | 브랜치 | merged PR | cleanup 후보 |
|:-:|--------------|-------|:---------:|:---:|
| 1 | `C:/claude/ebs` | `main` | — | ❌ (메인) |
| 2 | `ebs-conductor-ci` | `work/conductor/ci-docker-build-gate` | **#20** | ✅ |
| 3 | `ebs-conductor-curate` | `work/conductor/v6-3-journal-log` | — | ⚠️ 사용자 확인 |
| 4 | `ebs-conductor-infra` | `work/conductor/infra-alignment-cleanup` | **#11** | ✅ |
| 5 | `ebs-conductor-lint` | `work/conductor/dockerfile-lint` | — | ⚠️ 사용자 확인 |
| 6 | `ebs-conductor-p0` | `work/conductor/fix-p0-context-and-port` | **#17** | ✅ |
| 7 | `ebs-conductor-p1` | `work/conductor/p1-sentry-flutter-pin` | **#18** | ✅ |
| 8 | `ebs-team1-flutter` | `work/team1/n4-cc-url-scheme` | — | ⚠️ 사용자 확인 |
| 9 | `ebs-team1-harness` | `work/team1/harness-e2e-validation` | **#10** | ✅ |
| 10 | `ebs-team1-phase5` | `work/team1/phase5-e2e-final` | **#16** | ✅ |
| 11 | `ebs-team1-spec-gaps` | `work/team1/spec-gaps-20260415` | — | ⚠️ 사용자 확인 |
| 12 | `ebs-team2-work` | `work/team2/work` | — | ⚠️ 지속 work branch |
| 13 | `ebs-team3-betting` | `work/team3/20260428-betting-domain` | **#12** | ✅ |
| 14 | `ebs-team3-shim` | `work/team3/20260428-deprecation-shim` | — | ⚠️ 사용자 확인 |
| 15 | `ebs-team3-triggers` | `work/team3/20260427-triggers-domain-v2` | **#9** | ✅ |
| 16 | `ebs-team3-variants` | `work/team3/20260428-variants-domain` | — | ⚠️ 사용자 확인 |
| 17 | `ebs-team3-work` | `work/team3/b-342-foundation-ref-precision` | — | ⚠️ 지속 work branch |

## Cleanup 후보 (8개, merged)

```
+-------------------------------------------------------+
|                                                       |
|   merged worktree 8개 cleanup 가능:                   |
|                                                       |
|   1. ebs-conductor-ci          (PR #20)               |
|   2. ebs-conductor-infra       (PR #11)               |
|   3. ebs-conductor-p0          (PR #17)               |
|   4. ebs-conductor-p1          (PR #18)               |
|   5. ebs-team1-harness         (PR #10)               |
|   6. ebs-team1-phase5          (PR #16)               |
|   7. ebs-team3-betting         (PR #12)               |
|   8. ebs-team3-triggers        (PR #9)                |
|                                                       |
|   상태: PR merged → 작업 완료 → 안전 cleanup          |
|                                                       |
+-------------------------------------------------------+
```

## 사용자 확인 필요 (8개, PR 없음)

각 worktree 가 active work 인지 확인 후 결정:

| Worktree | 상태 추정 | 권장 action |
|----------|-----------|-----------|
| `ebs-conductor-curate` (v6-3-journal-log) | 진행 중? | 사용자 확인 |
| `ebs-conductor-lint` (dockerfile-lint) | 진행 중? | 사용자 확인 |
| `ebs-team1-flutter` (n4-cc-url-scheme) | 진행 중? | 사용자 확인 |
| `ebs-team1-spec-gaps` (spec-gaps-20260415) | 오래됨 (4-15) | 진행 여부 확인 |
| `ebs-team2-work` (team2/work) | 지속 work branch | 유지 권장 |
| `ebs-team3-shim` (deprecation-shim) | 진행 중? | 사용자 확인 |
| `ebs-team3-variants` (variants-domain) | 진행 중? | 사용자 확인 |
| `ebs-team3-work` (b-342) | 지속 work branch | 유지 권장 |

## Cleanup 명령 (사용자 명시 후 실행)

merged worktree 8개 cleanup 시:

```bash
# 사용자 검토 후 실행. 예시 (모두 cleanup 시):
cd C:/claude/ebs

# 1. worktree 제거 (sibling-dir 도 함께 삭제)
git worktree remove ../ebs-conductor-ci
git worktree remove ../ebs-conductor-infra
git worktree remove ../ebs-conductor-p0
git worktree remove ../ebs-conductor-p1
git worktree remove ../ebs-team1-harness
git worktree remove ../ebs-team1-phase5
git worktree remove ../ebs-team3-betting
git worktree remove ../ebs-team3-triggers

# 2. (선택) merged 브랜치 삭제 (origin 에서 이미 squash-merge 후 삭제됨)
git branch -D work/conductor/ci-docker-build-gate
git branch -D work/conductor/infra-alignment-cleanup
git branch -D work/conductor/fix-p0-context-and-port
git branch -D work/conductor/p1-sentry-flutter-pin
git branch -D work/team1/harness-e2e-validation
git branch -D work/team1/phase5-e2e-final
git branch -D work/team3/20260428-betting-domain
git branch -D work/team3/20260427-triggers-domain-v2

# 3. 검증
git worktree list   # 9개 잔존 (main + 8 active)
```

**예상 결과**: 17 → 9개 worktree (47% 감소).

## 디스크 공간 (추정)

각 worktree = 200MB ~ 1GB (의존성 + node_modules + venv 등). 8개 cleanup 시 **~3-5GB 회수**.

## 자율 안전 영역 (이번 turn 가능)

| 항목 | 자율 | 비고 |
|------|:---:|------|
| **본 report 작성** | ✅ done | 결정/cleanup 자체 X |
| `git worktree list` 조회 | ✅ done | read-only |
| `gh pr list --state merged` 조회 | ✅ done | read-only |
| `git worktree remove` 실행 | ❌ | **사용자 환경 변경 = Mode A 한계** |
| `git branch -D` 실행 | ❌ | local branch 삭제, 사용자 명시 필요 |

## 결정 후 다음 단계

사용자가 위 8개 cleanup 명시 (또는 일부) 시:
- `git worktree remove` 명령 실행 → 다음 turn 진행 가능
- 단, 각 worktree 의 uncommitted change 확인 필수 (실수 방지)
- 안전: `git worktree remove --force` 금지, 일반 `remove` 만 (uncommitted 시 실패 = 안전 신호)

## Changelog

| 날짜 | 변경 |
|------|------|
| 2026-04-28 | 최초 작성 (사용자 결정 3A) |
