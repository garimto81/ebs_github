---
title: Task Dispatch Board (V9.3 — Intent/Execution Separation + AI Autonomous Merge)
owner: conductor
tier: contract
last-updated: 2026-04-29
governance: V9.3 intent_execution_separation_with_ai_autonomous_merge
---

# Task Dispatch Board

> **V9.2 Hub-and-Spoke 워크플로우 SSOT.** Conductor 가 백로그를 분해하여 각 팀 세션에 작업을 할당하고, 진행 상태를 단일 보드로 통합 관리한다. 팀 세션은 자기 ROW 만 읽고 결과 PR 을 보고한다.
>
> **V9.2 핵심**: (1) Conductor 사전 scope 분리로 충돌 최소화, (2) 충돌 없는 PR 은 worker 자체 머지 허용 (3-gate 검증 후), (3) 충돌 PR 만 Conductor 처리.

## 🟢 Day 0 Migration Complete (2026-04-29)

| Phase | 결과 |
|-------|------|
| **main 동기화** | local main rebased onto `origin/main` (`05b27cfb`) + V9.0 governance 2 commits ahead |
| **Worktree analyzed** | 23 total (1 main + 22 sibling) |
| **Absorbed (cleanup)** | 14 worktree removed (이미 main 에 흡수, branch ref 보존) |
| **Real-work rebased** | 2 worktree (`conductor-lint`, `conductor-p3`) 깔끔히 origin/main 위로 재배치 |
| **Real-work preserved** | 6 worktree rebase conflict → abort (작업 보존, V9.2 path 처리 대상) |
| **D1 정책 반영** | `team-policy.json` `main_push_allowed_for: ["conductor"]` 유지 + V9.2 note 갱신 |

**보존된 6 real-work worktree** (Day 1 V9.2 cold start 시 PR 화 대상):
- `ebs-conductor-curate` (work/conductor/v6-3-journal-log) — 52 commits, journal log
- `ebs-team1-flutter` (work/team1/n4-cc-url-scheme) — 23 commits, URL scheme
- `ebs-team1-harness` (work/team1/harness-e2e-validation) — unstaged changes 보유
- `ebs-team1-spec-gaps` (work/team1/spec-gaps-20260415) — 10 commits, Settings 탭 PASS
- `ebs-team2-work` (work/team2/work) — 3 commits, Auth prefix + B-088 PR-4
- `ebs-team3-work` (work/team3/b-342-foundation-ref-precision) — 23 commits

**깔끔히 재배치된 2 worktree** (즉시 PR 가능):
- `ebs-conductor-lint` (work/conductor/dockerfile-lint)
- `ebs-conductor-p3` (work/conductor/p3-docs-automation)

## 📋 운영 규칙

| 항목 | 규칙 |
|------|------|
| **할당 권한** | Conductor 만 작업 등록 / 우선순위 조정 / 재할당 가능 |
| **상태 갱신** | `ASSIGNED → IN_PROGRESS` 는 팀 세션이 기록. `REVIEW_READY → MERGED` 는 Conductor 만 기록 |
| **머지 권한** | **Conductor 독점** — 팀 세션은 PR 생성 + `REVIEW_READY` 상태 변경까지만 |
| **충돌 해결** | Conductor 가 SSOT (`docs/1. Product/`, `docs/2. Development/2.5 Shared/`) 기준으로 직접 해결 |
| **세션 종료** | 팀 세션은 `REVIEW_READY` 표시 후 Idle 대기. 다음 task 는 Conductor 가 새로 할당 |

## 🔄 상태 전이 다이어그램

```
  +---------+   Conductor    +----------+   Worker      +-------------+
  | PENDING |---할당-------->| ASSIGNED |---착수------->| IN_PROGRESS |
  +---------+                +----------+               +------+------+
                                                                |
                                                          PR 생성
                                                                |
  +--------+   Conductor   +-------+   Conductor      +--------v-----+
  | MERGED |<---병합-------| REVIEW |<---보고---------| REVIEW_READY |
  +--------+               +-------+                   +--------------+
                              |
                         (충돌 시 Conductor 해소 후 머지)
```

## 📊 활성 작업 큐

> 현재 in-flight 만 표기. MERGED 항목은 24h 후 `## 📜 완료 이력` 으로 이동.

### Team 1 — Frontend (lobby-web)

| ID | 상태 | 작업 | Scope | PR | 비고 |
|----|------|------|-------|----|------|
| TDB-002 | REASSIGNED | (구 V9.0 drain 4건) → V9.2 path 로 3 real worktree 만 처리 | `ebs-team1-{flutter,harness,spec-gaps}` | — | Day 0 결과: phase5 absorbed (cleanup 완료). 3 real-work 보존. Day 1 cold start 시 V9.2 PR 경로로 처리 |
| TDB-003 | ASSIGNED | B-088 docs rest-path PascalCase → kebab-case | `docs/2. Development/2.1 Frontend/**` `*.md` 6개 | — | 단일 PR. drift_gate CI green 확인 후 보고 |

### Team 2 — Backend (BO / API / DB)

| ID | 상태 | 작업 | Scope | PR | 비고 |
|----|------|------|-------|----|------|
| TDB-004 | REASSIGNED | (구 V9.0 drain 2건) → V9.2 path 로 1 real worktree 만 처리 | `ebs-team2-work` | — | Day 0 결과: m1-drift absorbed (cleanup 완료). team2-work 보존 (Auth prefix + B-088 PR-4). Day 1 V9.2 PR 경로 |
| TDB-005 | ASSIGNED | SG-008-b4 GET /api/v1/auth/me 구현 | `team2-backend/src/routers/auth.py`, `tests/test_auth_me.py`, `docs/2. Development/2.2 Backend/APIs/Auth_and_Session.md §me` | — | 단일 endpoint + pytest. b5 (logout) 는 차후 dispatch |

### Team 3 — Game Engine

| ID | 상태 | 작업 | Scope | PR | 비고 |
|----|------|------|-------|----|------|
| TDB-006 | REASSIGNED | (구 V9.0 drain 4건) → V9.2 path 로 1 real worktree 만 처리 | `ebs-team3-work` | — | Day 0 결과: b349/b351/betting/shim/triggers/variants 모두 absorbed (6 cleanup 완료). team3-work 보존. Day 1 V9.2 PR 경로 |
| TDB-007 | ASSIGNED | B-330 (P0) Engine 별도 프로세스 원칙 API-04 전반 전파 | `docs/2. Development/2.3 Game Engine/APIs/{Overlay_Output_Events,OutputEventBuffer_Boundary,OutputEvent_Serialization}.md` | — | doc-only. Foundation §6.3/§6.4 정렬. notify:team4 commit tag |

### Team 4 — Command Center (cc-web)

| ID | 상태 | 작업 | Scope | PR | 비고 |
|----|------|------|-------|----|------|
| TDB-008 | ASSIGNED | B-team4-007 (P0 CRITICAL) Foundation §8.5/§5.0/§6.3 정합 | `docs/2. Development/2.4 Command Center/Command_Center_UI/Multi_Table_Operations.md`, `Overlay/Sequences.md` | — | doc-only. Type C 모순 해소. team4 worktree 신규 생성 필요 (`ebs-team4-foundation-007`). flutter 코드 영향 없음. team4 **idle** 상태 → 즉시 착수 가능 |

### Conductor — Cross-team / Infra

| ID | 상태 | 작업 | Scope | PR | 비고 |
|----|------|------|-------|----|------|
| TDB-001 | MERGED | V9.0 Hub-and-Spoke 인프라 개편 | `team-policy.json`, `Multi_Session_Workflow.md`, `pr-auto-merge.yml`, `Task_Dispatch_Board.md`, `SKILL.md` | 직접 commit (74e3a106 → rebased) | 본 보드 신설 |
| TDB-009 | REASSIGNED | (구 9 conductor drain) → V9.2 path 로 3 real worktree 만 처리 | `ebs-conductor-{curate,lint,p3}` | — | Day 0 결과: bcrypt/contract/deps-gov/engine/lan/p5p6 absorbed (6 cleanup). lint/p3 깔끔히 rebased → 즉시 PR 가능. curate 는 52 commits 충돌 → 별도 검토 |
| TDB-010 | MERGED | V9.0 push 권한 정합 검토 → V9.2 D1 결정 적용 | `team-policy.json` `branch_strategy.main_push_allowed_for: ["conductor"]` | 본 commit | V9.2 D1 (㉡): Conductor governance/board 직접 push 허용. 충돌 없는 worker PR 은 self-merge 허용 (V9.2 핵심) |
| TDB-011 | PENDING | V9.2 인프라 구축 (Day 1 cold start) — 3-gate auto-merge workflow + scope_overlap_check + dispatch_scope hook + governance_self_modification 절 | `tools/{team_v92_safe_merge,dispatch_scope_check,scope_overlap_check}.py`, `.github/workflows/pr-v92-merge-gate.yml`, `.claude/hooks/v92_*.py`, `team-policy.json` (v9.2 governance), `Multi_Session_Workflow.md` (v9.2 SOP) | — | Day 0 완료 후 Day 1 작업. 사용자 추가 mandate 대기 |
| TDB-012 | PENDING | 6 real-work conflict worktree 처리 plan 수립 | `ebs-conductor-curate`, `ebs-team1-{flutter,harness,spec-gaps}`, `ebs-team2-work`, `ebs-team3-work` | — | rebase conflict 발생. 옵션: (a) cherry-pick 추출 (b) 새 브랜치로 squash 후 재PR (c) 폐기. 사용자 결정 필요 |

## 🧾 Task 등록 템플릿

```markdown
| TDB-NNN | ASSIGNED | <task title> | <files/globs> | <PR URL or "—"> | <constraint or dependency> |
```

**필수 필드**:
- **ID** — `TDB-{3자리 시퀀스}` (Conductor 가 발급)
- **상태** — `ASSIGNED` 시작 / `IN_PROGRESS` (worker) / `REVIEW_READY` (worker) / `MERGED` (Conductor)
- **작업** — 단일 PR 로 마무리 가능한 최소 단위. 너무 크면 분할
- **Scope** — 편집 대상 파일/glob. 다른 팀 영역 침범 시 Conductor 명시 사전 승인 필요
- **PR** — Phase 2 완료 후 `https://github.com/garimto81/ebs_github/pull/NN` 기재
- **비고** — 의존성 / 차단 / 공동 검증 필요 사항

## 🔁 일일 운영 루틴

### Conductor 일과
1. `git fetch && gh pr list --state open` 로 보고된 PR 확인
2. `REVIEW_READY` 상태 PR 을 순차 리뷰 (단일 스레드)
3. 충돌 / 의미 모순 시 SSOT 확인 → 직접 rebase + 해결
4. `gh pr merge --squash --delete-branch` 로 머지
5. 보드에서 해당 row → `MERGED` 갱신 + 다음 task 등록
6. 팀 세션에 다음 작업 dispatch

### Worker (Team 1~4) 일과
1. 본 보드에서 자기 팀 row 의 `ASSIGNED` 항목만 확인
2. 상태 → `IN_PROGRESS` 갱신, sibling worktree 에서 작업
3. 자체 테스트 (pytest / dart analyze / flutter test) 통과 확인
4. `git push` + `gh pr create --draft` (또는 ready PR) — **`auto-merge` 라벨 부여 금지**
5. 보드 row → `REVIEW_READY` + PR URL 기재
6. **Idle 상태 대기**. 다음 작업은 Conductor 가 등록할 때까지 시작 금지

## ⚠️ 절대 규칙

1. **팀 세션은 main 머지 시도 절대 금지**. `gh pr merge`, `git push origin main`, auto-merge 라벨 부여 모두 차단.
2. **Conductor 가 등록하지 않은 작업 자율 착수 금지**. 발견한 추가 작업은 PR comment / Backlog 추가 후 Conductor 결정 대기.
3. **충돌 해결 임의 시도 금지**. Rebase 충돌 발생 시 PR 에 `conflict` 라벨 + Conductor 알림.
4. **보드 = 단일 SSOT**. PR 본문 / Backlog 와 상이 시 본 보드 우선.

## 📜 완료 이력

> 24h 이상 경과한 MERGED 항목 누적. 분기별 `Reports/` 로 archive.

| 일시 | ID | 팀 | 작업 | 머지 PR |
|------|----|----|------|---------|
| 2026-04-29 | TDB-001 | conductor | V9.0 Hub-and-Spoke 인프라 개편 | 직접 commit (Mode A) |
| 2026-04-29 | TDB-010 | conductor | V9.2 D1 결정 적용 — main_push_allowed_for 정합 | 본 commit |

## 🗂 Day 0 Cleanup Audit Trail

> Day 0 마이그레이션 결과 데이터: `.scratch/v92-day0-{analysis,finalize,classification,cleanup,rebase}.json`. 보존된 worktree branch ref 는 git reflog 30일 보호.

### 14 Absorbed Worktrees (cleanup 완료)
- **conductor (6)**: bcrypt, contract, deps-gov, engine, lan, p5p6
- **team1 (1)**: phase5
- **team2 (1)**: m1-drift
- **team3 (6)**: variants, b349, b351, betting, shim, triggers

각 worktree 의 작업은 origin/main 에 이미 흡수됨 (PR 머지 후 worktree 가 stale 상태로 남아있던 것). branch ref 는 보존 (git reflog 30일).

### 8 Real-Work Worktrees (보존)
- **rebased (즉시 PR 가능, 2)**: conductor-lint, conductor-p3
- **conflict aborted (V9.2 path 처리, 6)**: conductor-curate (52 commits), team1-flutter (23), team1-harness (unstaged), team1-spec-gaps (10), team2-work (3), team3-work (23)

## 관련 문서

- `docs/4. Operations/Multi_Session_Workflow.md` — V9.0 표준 운영 절차 (정책 본문)
- `docs/2. Development/2.5 Shared/team-policy.json` — `governance_model: conductor_centralized_review`
- `.github/workflows/pr-auto-merge.yml` — V9.0 에서 비활성화됨 (history 보존)
- `.claude/skills/team/SKILL.md` — 팀 세션 worker 워크플로우 (PR 보고까지)
