---
title: Multi-Session Workflow (V9.0 — Hub-and-Spoke Centralized Review)
owner: conductor
tier: contract
last-updated: 2026-04-29
governance: v9.0 conductor_centralized_review
reimplementability: PASS
reimplementability_checked: 2026-04-29
reimplementability_notes: "V9.0 — V8.0 자율 오케스트레이션 폐기. Hub-and-Spoke 중앙 통제형. 팀 세션 = Worker (PR 보고까지). Conductor = Hub (단일 스레드 리뷰 + 머지)."
---

# Multi-Session Workflow — V9.0 Hub-and-Spoke

> **🚨 V9.0 패러다임 전환** — 2026-04-29.
> V8.0 의 Reactive 자율 머지 (`concurrency: main-merge-queue` + `auto-merge` 라벨) 가 **PR 적체 + 교착** 을 유발 → 인간 개발팀 방식의 **Hub-and-Spoke 중앙 통제형 위임 모델** 로 전면 개편.
> 모든 main 머지 / 충돌 해결 권한은 **Conductor 독점**. 팀 세션은 할당된 작업의 **구현 + 보고** 까지만 수행.

## 🎯 V9.0 핵심 원칙

| 원칙 | 설명 |
|------|------|
| **Hub-and-Spoke** | Conductor (Hub) 가 N 개 팀 세션 (Spoke) 에 작업 dispatch, 결과 PR 통합 |
| **단일 머지 권한** | `main` 으로의 모든 머지는 Conductor 만 수행 |
| **단일 스레드 리뷰** | Conductor 가 보고된 PR 을 순차적으로 리뷰. 동시 처리 금지 |
| **SSOT 기반 충돌 해결** | 의미적 충돌 시 `docs/1. Product/`, `docs/2. Development/2.5 Shared/` 가 판정 기준 |
| **중앙 할당판** | `docs/4. Operations/Task_Dispatch_Board.md` 가 작업 + 상태 SSOT |

## 🔄 V9.0 표준 운영 절차 (Standard Operating Procedure)

### Step 1: Task Dispatch — Conductor 의 할당

Conductor 는 백로그 (`docs/2. Development/2.{1..4} {팀}/Backlog.md`, `docs/4. Operations/Conductor_Backlog.md`) 를 분석하여:

1. **최소 단위 분해** — 각 팀 세션이 독립적으로 단일 PR 로 마무리할 수 있는 크기로 작업 분할
2. **Task_Dispatch_Board.md 등록** — 팀별 row 에 `TDB-NNN` ID + 목표 + scope + 제약 명시 (`ASSIGNED` 상태)
3. **세션 통지** — 해당 팀 세션이 활성화되면 본 보드 self-discovery (별도 push 알림 없음)

**금지**: Conductor 가 보드에 등록하지 않은 작업을 팀 세션이 자율 착수하는 것.

### Step 2: Execute & Report — 팀 세션의 실행 및 보고

각 팀 세션 (Worker) 은:

1. **자기 row 만 확인** — 본 보드에서 본인 팀의 `ASSIGNED` 항목만 읽기. 다른 팀 row 는 무시
2. **Sibling worktree 진입** — `C:/claude/ebs-team{N}-work/` 에서 작업
3. **상태 갱신** — 보드 row → `IN_PROGRESS` 변경 + commit
4. **구현 + 자체 테스트** — pytest / dart analyze / flutter test 통과 확인
5. **PR 생성 (Draft 또는 Ready)** — `gh pr create --draft --fill --base main` (또는 ready PR)
   - **`auto-merge` 라벨 부여 절대 금지**
   - PR 본문에 자체 테스트 결과 + scope + Task ID 명시
6. **REVIEW_READY 보고** — 보드 row → `REVIEW_READY` + PR URL 기재 + commit
7. **Idle 대기** — 다음 작업은 Conductor 가 새로 등록할 때까지 시작 금지

#### 🚫 절대 규칙 (Worker)

| 금지 행위 | 이유 |
|-----------|------|
| `gh pr merge` 호출 | main 머지 권한은 Conductor 만 |
| `git push origin main` | 직접 push 금지 (PR 경로 강제) |
| `auto-merge` 라벨 부여 | V9.0 에서 워크플로우 비활성화됨 |
| 충돌 해결 시도 | rebase 충돌 시 PR 에 `conflict` 라벨 + Conductor 알림 |
| 보드 외 작업 자율 착수 | 발견 사항은 PR comment 또는 Backlog 에만 추가 |
| 다른 팀 row 갱신 | 본인 팀 row 만 수정 가능 |

### Step 3: Review, Merge & Reassign — Conductor 의 통합

Conductor (Hub) 는 단일 스레드로:

1. **PR 큐 확인** — `gh pr list --state open --label review-ready` (또는 보드의 `REVIEW_READY` 항목)
2. **순차 리뷰** — 동시 처리 금지. PR 1 개씩 리뷰
3. **자체 검증**:
   - 자체 테스트 결과 확인
   - SSOT 정합성 점검 (`docs/1. Product/`, `docs/2. Development/2.5 Shared/`)
   - WSOP LIVE 정렬 원칙 (CLAUDE.md 원칙 1) 점검
   - Type B/C 기획 공백·모순 여부 판정 (`docs/4. Operations/Spec_Gap_Triage.md`)
4. **충돌 발생 시**:
   - Conductor 가 직접 `git fetch && git checkout work/team{N}/<slug> && git rebase origin/main`
   - SSOT 기반 의미 판정 + 수동 resolve
   - `git push --force-with-lease`
5. **머지 실행** — `gh pr merge --squash --delete-branch`
6. **보드 갱신** — row → `MERGED` + 머지 PR URL 기재
7. **Reassign** — 팀에 다음 작업 등록 (`ASSIGNED`)

## 📁 표준 디렉토리 레이아웃 (V9.0 — v5.0 유지)

| 용도 | 경로 | 브랜치 |
|------|------|--------|
| Conductor (Hub) | `C:/claude/ebs/` | `main` 고정 |
| Team 1 worktree | `C:/claude/ebs-team1-work/` | `work/team1/<slug>` |
| Team 2 worktree | `C:/claude/ebs-team2-work/` | `work/team2/<slug>` |
| Team 3 worktree | `C:/claude/ebs-team3-work/` | `work/team3/<slug>` |
| Team 4 worktree | `C:/claude/ebs-team4-work/` | `work/team4/<slug>` |

**네이밍**: `ebs-team{N}-<slug>`. subdir (`ebs/team{N}-*`) 은 v5.0 부터 금지.

## 🛠 세션 환경 준비 (1회)

```bash
# Conductor 에서 팀별 sibling worktree 생성 (기존 v5.0 방식 유지)
cd C:/claude/ebs
git worktree add ../ebs-team1-work -b work/team1/work
git worktree add ../ebs-team2-work -b work/team2/work
git worktree add ../ebs-team3-work -b work/team3/work
git worktree add ../ebs-team4-work -b work/team4/work
```

이후 팀 세션:
```bash
cd C:/claude/ebs-team{N}-work
claude
```

## 🔗 V9.0 자산 맵

### Active 자산 (V9.0)

| 자산 | 역할 |
|------|------|
| `docs/4. Operations/Task_Dispatch_Board.md` | 작업 할당 + 상태 SSOT (Hub) |
| `docs/2. Development/2.5 Shared/team-policy.json` | `governance_model: conductor_centralized_review` (v9.0) |
| `.claude/skills/team/SKILL.md` | 팀 세션 worker 워크플로우 (PR 보고까지) |
| `.github/CODEOWNERS` | 자동 리뷰어 알림 (Conductor 인지 보조) |
| `tools/team_v5_merge.py` | PR 생성 단계까지만 사용 (auto-merge 라벨 부여 단계 미사용) |

### Disabled / Deprecated (V9.0)

| 자산 | 상태 |
|------|------|
| `.github/workflows/pr-auto-merge.yml` | **비활성화** (`workflow_dispatch` only). 자동 머지 차단 |
| `auto-merge` 라벨 | deprecated. 부여 금지 (V9.0 워크플로우 미동작) |
| v8.0 `concurrency: main-merge-queue` | Conductor 단일 스레드 리뷰가 대체 |
| v7.1 Mode A / Mode B 분기 | V9.0 단일 모델로 흡수 |
| v8.0 governance freeze | V9.0 결정으로 supersede |
| L0 Pre-Work Contract (v5.1) | V9.0 에서 Task_Dispatch_Board 가 대체 |

## ⚖️ 거버넌스 (V9.0)

`team-policy.json` v9.0 `conductor_centralized_review`:

- **Write access**: 모든 세션이 모든 docs 자유 편집 (free_write 유지)
- **Merge authority**: Conductor 만 main 머지 (worker 박탈)
- **Conflict resolution**: Conductor 가 SSOT 기반 직접 해결 (decision_owner 분산 모델 흡수)
- **Task dispatch**: Conductor 만 등록 / 우선순위 / 재할당 가능

### Conductor 자율 금지 영역 (V9.0 conductor_limits)

| 영역 | 처리 |
|------|------|
| vendor 외부 메일 (RFI/RFQ) | 사용자 명시 필요 |
| destructive 시스템 변경 (DB drop, prod 배포) | 사용자 명시 필요 |
| git config 자율 변경 (remote URL 등) | 사용자 명시 필요 |
| 사용자 인텐트 변경 (SG-023 같은 큰 결정) | 사용자 명시 필요 |
| memory 의 사용자 본인 결정 메모 임의 폐기 | 금지 |

## 🚫 금지 사항 (V9.0)

- 팀 세션의 `gh pr merge`, `git push origin main`, `auto-merge` 라벨 부여
- 팀 세션이 충돌 해결 시도 (PR 에 `conflict` 라벨 + Conductor 알림 → Conductor 처리)
- `.github/workflows/pr-auto-merge.yml` 활성화 시도 (V9.0 비활성 정책)
- subdir 세션 (`C:/claude/ebs/team{N}-*/`) 에서 작업
- Task_Dispatch_Board.md 외부 작업 자율 착수
- Conductor 가 동시에 여러 PR 병렬 머지 (단일 스레드 원칙)
- `~/.claude/skills/team/` v4.0 user-global 스킬 호출 (deprecation shim)

## 🌐 Free-tier 호환성

| 기능 | GitHub Team plan | EBS V9.0 대응 |
|------|:----------------:|----------------|
| Merge Queue (native) | ✓ | **Conductor 단일 스레드 리뷰** (V9.0 대체) |
| Branch protection (private) | ✓ | Conductor 인지·판단 (정책 layer) |
| Required CODEOWNERS review | ✓ | 자동 알림 + Conductor 리뷰 |
| auto-merge (private) | ✓ | **사용 안 함** (V9.0 비활성) |

## 📜 변경 이력

| 날짜 | 버전 | 변경 |
|------|------|------|
| 2026-04-29 | **v9.0** | **Hub-and-Spoke 중앙 통제형 위임 모델 채택**. 자율 머지 폐기, Conductor 단일 머지 권한, Task_Dispatch_Board.md 신설. |
| 2026-04-28 | v8.0 | L0 Pre-Work Contract 폐기 (30일 ROI 0). Phase 6 cleanup. |
| 2026-04-27 | v5.1+L4 | BLANK-3 Merge Strategy 명문화. |
| 2026-04-22 | v5.1 | L0 Pre-Work Contract 추가 (Active_Work.md). |
| 2026-04-21 | v5.0 | sibling worktree + PR + concurrency gate. v4.x manifest/safety-gate 폐기. |

> v5.x → v8.0 상세 history: `docs/4. Operations/Reports/2026-04-28-v8-phase8d-multi-session-workflow-history.md` + `2026-04-28-v8-phase8a-multi-session-workflow-v4-history.md`.

## 🔗 관련 문서

- `docs/4. Operations/Task_Dispatch_Board.md` — V9.0 작업 SSOT
- `docs/2. Development/2.5 Shared/team-policy.json` — `governance_model: conductor_centralized_review`
- `.claude/skills/team/SKILL.md` — 팀 세션 worker 워크플로우
- `.github/workflows/pr-auto-merge.yml` — V9.0 비활성 (history 보존)
- `docs/4. Operations/Spec_Gap_Triage.md` — Type A/B/C 분류 (Conductor 리뷰 시 참조)
