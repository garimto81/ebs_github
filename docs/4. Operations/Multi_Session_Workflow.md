---
title: Multi-Session Workflow (v7.5 — Autonomous Conflict Triage + Pre-Work Contract + Worktree + PR + Free-tier Merge Gate)
owner: conductor
tier: contract
last-updated: 2026-04-28
reimplementability: PASS
reimplementability_checked: 2026-04-22
reimplementability_notes: "v7.5 (2026-04-28, SG-028) — Mode B 의미적 충돌 판정을 autonomous_llm_judgment 로 이전. v5.1 4-Phase 구조 유지. v5.1 (2026-04-22) — L0 Pre-Work Contract 추가. v5.0 (2026-04-21) — 업계 표준 재사용 PR 모델."
---

# Multi-Session Workflow — v7.5

## 🚀 표준 명령

```bash
/team "<task description>"     # 팀/Conductor 세션 모두 (project-local v5.1)
```

**단일 호출로 실행 (4 Phase, v5.1)**:
0. **Claim** (NEW) — `tools/active_work_claim.py` 로 scope 충돌 사전 확인 + claim 추가
1. **Work** — sibling worktree 에서 `/auto "<task>"` → commit on `work/team{N}/<slug>`
2. **PR** — `tools/team_v5_merge.py` 가 rebase + push + `gh pr create` + `auto-merge` 라벨
3. **Sync** — `.github/workflows/pr-auto-merge.yml` 이 concurrency group 기반 직렬 merge

**세션 ↔ GitHub 분리**: 팀 세션은 PR 생성까지만. merge 는 GitHub 이 백그라운드 처리. 팀은 다음 작업으로 진행.

## v5.1 추가 이유 (2026-04-22)

v5.0 의 L1-L3 는 **reactive** — 충돌이 발생한 뒤 merge 시점에 처리. 이 모델의 구조적 문제:

- 4 팀이 2 시간 작업 후 merge 시점에 conflict → 누군가의 2시간 손실
- Reactive rework 시 새로운 bug 유입 → 다음 PR 에 연쇄 → 오류 누적
- Rebase conflict 자동 해결 불가 → 수동 개입 필요

**해결**: proactive coordination layer (L0 Pre-Work Contract) 추가. 작업 시작 시점에 의도 공유로 **충돌 예방** (reactive 는 safety net 유지).

## v4.0/v4.1 → v5.0 전환 이유

### 발견된 문제 (2026-04-21 critic review)

| v4.0 약속 | 실제 | 원인 |
|-----------|------|------|
| "매 호출 완결 트랜잭션" | 4 단계 수동 조치 필요 | 플랫폼이 main push 차단 |
| "자동 commit + merge + push" | Push 실패 → 사용자 수동 수습 | PR review bypass 정책 |
| "세션 시작·종료 개념 없음" | 팀 세션 재시작 필수 | subdir 모드 shared HEAD 오염 |
| "Pre-Declaration 충돌 방지" | team1 등 manifest 미등록 | enforcement 경로 없음 |

### 2026 업계 표준 조사 결과

- **The Agentic Blog (2026-03)**: "one task → one branch → one worktree → one agent" canonical pattern
- **GitHub Merge Queue (2025 GA)**: 복잡 monorepo 표준. 24% PR cycle reduction
- **Claude Code v2.1.50**: `claude -w` 네이티브 worktree 지원
- **AddyOsmani (2026)**: 3-5 agent sweet spot. 같은 파일 2 agent 편집 금지

→ **EBS v4.0 = 업계가 이미 Git/GitHub/Claude Code 네이티브로 해결한 문제의 재발명**

---

## v7.5 — Autonomous Conflict Triage (SG-028, 2026-04-28)

사용자 STRATEGIC PIVOT 결정 (2026-04-28) 으로 Mode B 의미적 판정 권한이 `decision_owner` (CODEOWNERS) → `autonomous_llm_judgment` 로 이전. Zero-Intervention 원칙으로 멀티세션 자율 완결.

### 거버넌스 변경 매트릭스

| Mode | 이전 (v7.1) | 현재 (v7.5) |
|:----:|-------------|-------------|
| Mode A 단일 세션 | `conductor_full_authority` | **변경 없음** |
| Mode B 멀티세션 (default) | `decision_owner_adjudicates` | **`autonomous_llm_judgment`** ⭐ |
| Mode B legacy (escape hatch) | — | `EBS_GOV_MODE=v71_decision_owner` 로 회복 가능 (2026-07-28 평가) |

### 4-Step Decision Logic

```
충돌 감지 (rebase or merge conflict)
  │
  ├─ Step 1. SSOT 조회 (team-policy.json contract_ownership + teams[].owns)
  ├─ Step 2. SSOT 우위 판정 (한쪽만 일치 → Overwrite)
  ├─ Step 3. Win-Win Merge (두 변경 직교 → 통합)
  └─ Step 4. Fallback (Tie-breaker)
       ├─ 1순위 종속성 평가 (side-effect 적은 쪽)
       │   ├─ contract path vs 비-contract → 비-contract 우선
       │   ├─ DB 스키마/마이그레이션 → 더 보수적 (Abort 경향)
       │   └─ API 시그니처 → subscriber 영향 최소화
       ├─ 2순위 신규 우선 (1순위 동등 시 → theirs/HEAD 채택)
       └─ 모두 실패 → Abort + Spec_Gap_Registry + user escalation
```

상세: `team-policy.json` `conflict_triage` (SSOT).

### 실행 흐름 (Local + CI 분리)

| 시점 | 컴포넌트 | 동작 |
|:----:|---------|------|
| Local rebase 충돌 | `tools/team_v5_merge.py` | 충돌 감지 → `conflict_resolver.py analyze` 호출 → 종료 (exit 4) |
| Local LLM 판정 | Claude Code session | `.conflict_request.json` 읽기 → `.conflict_decision.json` 작성 |
| Local 적용 | `tools/conflict_resolver.py apply` | 결정 적용 → 검증 (lint/syntax) → `git rebase --continue` → audit issue + Conflict_Registry 갱신 |
| Local 재호출 | `team_v5_merge.py` | rebase 완료 상태 → push + PR create |
| **CI 충돌** | `pr-auto-merge.yml` | `conflict_resolver.py ci-only` → audit issue 등록 + auto-merge 라벨 제거 → exit 1. (LLM 없음, local 재실행 안내) |

### 안전 장치

1. **Verification Mandatory**: 결정 적용 직후 lint/syntax 강제. 실패 시 자동 rollback (`rebase --abort`) + audit issue 등록.
2. **CI Fallback**: workflow 환경에는 LLM 없음 → ci-only 모드 (issue 만 등록, label 제거). 사람이 local 재실행 필요.
3. **Mode A 보존**: 본 변경은 Mode B 의미적 판정에만 적용. 사용자 인텐트 / vendor 메일 / DB drop 등 `mode_a_limits` 영역은 그대로 보호.
4. **Escape Hatch**: `EBS_GOV_MODE=v71_decision_owner` 로 v7.1 모델 회복 가능. 2026-07-28 사후 평가 후 제거 검토.

### Audit Trail

- `docs/4. Operations/Conflict_Registry.md` — 시간순 누적 인덱스 (자동 갱신)
- GitHub issue (label: `conflict-audit`) — 결정별 상세
- 100건 누적 또는 12 weeks 경과 시 SG-028b 평가 트리거

### 참조

- `Conductor_Backlog/SG-028-autonomous-conflict-triage.md` — 결정 근거
- `team-policy.json` `conflict_triage` — 4-Step Decision SSOT
- `tools/conflict_resolver.py` — 엔진 구현 (analyze / apply / ci-only / self-test)

---

## v7.2 — 5-Session Pipeline (SG-027, 2026-04-27)

대규모 production cascade (수만 line 코드 + 다중 영역) 의 **분량 분할 워크플로우**. v7.1 Mode A/B (권한 모델) 와 **직교** — 본 모델은 multi-turn 분량 모델.

### 5 Sessions 정의

| Session | 목표 | 가상 팀 | 전형 작업 |
|:-------:|------|---------|----------|
| **1. Foundation & Infrastructure** | 기획 SSOT 분석 + 인프라 정합성 | Conductor (Team 4 가상) | Broken URL 정렬, 도커 좀비 정리, 개발 환경 표준화 |
| **2. Core Logic & Backend Engine** | API + 엔진 구현 | Team 2 + Team 3 | DB 스키마 (Alembic), endpoint 구현, Coverage 95% 목표 |
| **3. Frontend Interface & Routing** | 클라이언트 + 백엔드 연동 | Team 1 | 단일 Desktop 라우팅, UI 컴포넌트, 100ms SLA 클라이언트 측정 |
| **4. System Integration & QA Harness** | 통합 + E2E 검증 | Team 1~4 + QA | 통합 하네스, 예외 케이스, 부분 재구현 (Surgical Edit) |
| **5. Final Production & Audit** | 보안 + 최종 빌드 | Conductor + QA | OWASP audit, PHASE-FINAL-REPORT, Main 통합 commit |

### Session Isolation

각 session 은 **자신의 scope 내 작업만**. 예: Session 2 에서 UI 코딩 금지, Session 3 에서 DB schema 변경 금지. Conductor 가 cross-session 변경 필요 시 **즉시 escalation** + handoff.

### State Handoff Protocol

각 session 종료 시 **`SESSION_X_HANDOFF.md`** 출력:
- 진행 결과 요약
- 커밋 hash
- 미해결 백로그
- 다음 session 권고

다음 session 시작 시 그 handoff 를 read.

### Mode 조합 (v7.2)

| Mode | Session 모델 | 권한 |
|:----:|------------|------|
| **Mode A + 5-Session** | Conductor 단일 세션, 5 turns 분할 | 단일 세션 권한 + multi-turn 분량 |
| Mode A + Single Session | Conductor 단일 세션, 단일 turn | 단일 세션 권한 + 단일 turn 분량 (v7.1 default) |
| Mode B + 5-Session | 멀티세션, 5 단계 분할 | decision_owner 회복 + multi-turn |
| Mode B + Single Session | 멀티세션, 단일 turn | v5.1 표준 |

5-Session 모델은 **분량이 단일 turn 한계 초과 시** default 권장.

### Zero-Regression 검증

- 새 코드 작성 시 기존 통과 테스트 100% 보존
- pytest / flutter test / dart test 등 baseline 유지

### 참조

- `Conductor_Backlog/SG-027-multi-session-pipeline.md`
- `Conductor_Backlog/SESSION_1_HANDOFF.md` (현재 session)
- `team-policy.json` v7.1 (Mode A/B)

---

## v7.1 — 단일 세션 모드 (Mode A, SG-024, 2026-04-27)

사용자 B-Q5 ㉠ 채택으로 거버넌스 확장. **Conductor 세션 단독 활동 시** v5.1 멀티세션 워크플로우는 옵션이며, Conductor 가 모든 영역 직접 편집 + 결정 가능.

| 모드 | trigger | workflow |
|------|---------|----------|
| **Mode A — 단일 세션 (default in v7.1)** | Conductor 단독 활동 | `/team` 워크플로우 생략 가능. Conductor 가 main 직접 commit (또는 work/conductor/* 브랜치 + PR). decision_owner override 자율. |
| **Mode B — 멀티 세션 (옵션)** | 팀 세션 (team1~4) 활성화 자동 회복 | 아래 v5.1 4 Layer (L0-L4) 워크플로우 그대로 적용. decision_owner 권한 회복. |

> **자동 모드 전환**: 팀 세션 (예: `cd team1-frontend` + Claude Code) 활성화 → Mode B 자동 회복. Conductor 단독 → Mode A default.

> **Mode A 한계 (Conductor 자율 금지)**:
> - vendor 외부 메일 발송 (RFI/RFQ — Slack/Gmail)
> - destructive 시스템 변경 (DB drop, prod 배포, 거대 dependency 변경)
> - git config 자율 변경 (예: remote URL)
> - 사용자 인텐트 변경 (SG-023 같은 큰 결정)
> - memory 의 사용자 본인 결정 메모 임의 폐기
>
> 자세히: `Conductor_Backlog/SG-024-governance-expansion.md`, `team-policy.json` v7.1 `mode_a_limits`.

---

## v5.1 아키텍처 (4 Layer — Proactive + Reactive)

```
┌──────────────────────────────────────────────────────┐
│  L3  Free-tier Merge Gate (REACTIVE)                │
│      .github/workflows/pr-auto-merge.yml            │
│      concurrency: main-merge-queue (직렬 1개)        │
├──────────────────────────────────────────────────────┤
│  L2  GitHub PR 동기화 (REACTIVE)                    │
│      gh pr create --fill --base main                │
│      CODEOWNERS 자동 리뷰어 배정                    │
├──────────────────────────────────────────────────────┤
│  L1  git worktree 격리 (REACTIVE, 파일시스템)       │
│      C:/claude/ebs-team{N}-work/                    │
│      work/team{N}/<slug> 브랜치                     │
├──────────────────────────────────────────────────────┤
│  L0  Pre-Work Contract (PROACTIVE, v5.1 NEW) ⭐      │
│      docs/4. Operations/Active_Work.md (SSOT)       │
│      tools/active_work_claim.py (CLI)               │
│      .claude/hooks/active_work_reminder.py (hook)   │
└──────────────────────────────────────────────────────┘
```

### L0 Pre-Work Contract 동작

- **작업 시작 전**: 팀이 `tools/active_work_claim.py check --scope "..."` 로 충돌 확인
- **Claim 추가**: 충돌 없으면 `add --team <team> --task "..." --scope "..."`
- **Session-start hook**: `.claude/hooks/active_work_reminder.py` 가 현 claims 전시
- **작업 완료**: `team_v5_merge.py` 가 PR 생성 후 자동 release

### CCR draft (deprecated) 와 차이

| CCR draft | Active Work (v5.1) |
|-----------|---------------------|
| Governance (heavy review) | Coordination (lightweight visibility) |
| per-change 파일 | 단일 SSOT |
| 승인 cycle 필요 | 바로 claim 추가 |
| 수 시간~일 | 수 초~분 |
| docs/3. Change Requests/ | docs/4. Operations/Active_Work.md |

**결론**: v7 에서 폐기한 CCR 재탄생이 아님. 목적과 오버헤드가 근본적으로 다름.

## 표준 디렉토리 레이아웃

| 용도 | 경로 | 브랜치 |
|------|------|--------|
| Conductor (main) | `C:/claude/ebs/` | `main` 고정 |
| Team 1 worktree | `C:/claude/ebs-team1-work/` | `work/team1/<slug>` |
| Team 2 worktree | `C:/claude/ebs-team2-work/` | `work/team2/<slug>` |
| Team 3 worktree | `C:/claude/ebs-team3-work/` | `work/team3/<slug>` |
| Team 4 worktree | `C:/claude/ebs-team4-work/` | `work/team4/<slug>` |

**네이밍**: `ebs-team{N}-<slug>`. `ebs-wt-*`, `.worktrees/*`, subdir (`ebs/team{N}-*`) 은 v5.0 금지.

## 세션 환경 준비 (1회)

```bash
# Conductor 에서 팀별 sibling worktree 생성
cd C:/claude/ebs
python tools/setup_team_worktrees.py --team all
```

결과:
- `C:/claude/ebs-team1-work/` ~ `C:/claude/ebs-team4-work/`
- 각 worktree 는 `work/team{N}/work` 브랜치 (또는 기존 브랜치 재사용)

이후 팀 세션:
```bash
cd C:/claude/ebs-team2-work
claude
# 또는 Claude Code v2.1.50+ 네이티브:
cd C:/claude/ebs && claude -w --branch work/team2/<slug>
```

## 4-Phase 실행 상세 (v5.1)

### Phase 0 — Claim (NEW, Pre-Work Contract)

작업 시작 시점 의도 공유:

```bash
# 1. 현재 모든 claim 전시
python tools/active_work_claim.py list

# 2. 내 scope 가 다른 claim 과 겹치는지 확인
python tools/active_work_claim.py check --scope "team2-backend/**,docs/2*/APIs/*"

# 3a. 충돌 없음: claim 추가
python tools/active_work_claim.py add --commit \
    --team team2 --task "API-01 path rename" \
    --scope "team2-backend/src/routers/series.py,docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md" \
    --eta 2h

# 3b. 충돌 있음: 해당 claim owner 와 조율 → scope 축소, 순서 조정, 또는 병합
```

**규칙**:
- Conductor 도 claim 필수 (uniform 원칙)
- Scope 는 task-level semantic (glob 패턴 지원)
- TTL 없음 — 작업 완료 (Phase 2 merge) 까지 유지
- 작업 중 discovery → `update --add-scope` 로 확장
- `--force` 로 충돌 무시 가능 but commit msg 에 사유 필수

### Phase 1 — Work

팀 세션이 `/team "<task>"` 호출 (project-local v5.1 skill):

1. **Context detect**: cwd 가 sibling worktree 인지 확인. subdir 이면 error
2. **`/auto "<task>"` 위임**: 기존 PDCA 워크플로우 (drift/test/scope guard 포함)
3. **Commit**: conventional commit + `Co-Authored-By` 자동

work 브랜치에 commit 완료. 이 시점까지 GitHub 에는 아무것도 push 되지 않음.

### Phase 2 — PR

`tools/team_v5_merge.py` 실행:

```bash
python tools/team_v5_merge.py
```

내부 동작:
1. `git fetch origin`
2. `git rebase origin/main` (work 브랜치 최신화)
3. `git push --force-with-lease origin HEAD` (work 브랜치 publish)
4. `gh pr create --fill --base main --head <branch>`
5. `gh pr edit <branch> --add-label auto-merge`

PR 생성 완료. CODEOWNERS 가 해당 팀 owner 에게 리뷰 요청 전송.

### Phase 3 — Sync

`.github/workflows/pr-auto-merge.yml` 가 수행 (자동):

1. `concurrency: main-merge-queue` 획득 대기 (동시 1개 PR 만 처리)
2. 모든 required check 완료 대기 (최대 20분)
3. main 에 behind 이면 auto-rebase + force-push
4. `gh pr merge --squash --delete-branch`

팀 세션 측 동작: 없음. worktree 는 다음 작업을 위해 유지.

## Conflict Handling (4 Layer)

### L0 (Pre-Work Contract) — 의도 공유 (v5.1 NEW)
- 작업 시작 전 `tools/active_work_claim.py check` 로 scope 겹침 탐지
- 겹치면 해당 팀과 조율 (scope 축소 / 순서 / 병합)
- **90% 충돌 예방** — 대부분의 "merge 때 알게 되는 충돌" 은 이 단계에서 제거됨

### L1 (worktree) — 파일시스템 격리
- Git 자체 제약: **같은 브랜치 2개 worktree 체크아웃 불가** → branch 수준 race 원천 차단
- 다른 worktree 의 commit 이 내 HEAD 이동 안 함 (HEAD 는 per-worktree)

### L2 (PR) — 의미적 충돌 (L0 가 미리 못 잡은 잔여)
- 같은 파일을 2 팀이 수정 → 첫 PR merge 후 두 번째 PR rebase 강제
- `tools/team_v5_merge.py` 의 rebase 단계가 자동 처리
- rebase conflict 발생 시 workflow 가 `auto-merge` 라벨 제거 + PR 에 comment

### L3 (Merge queue) — 순서 보장
- `concurrency: main-merge-queue` 가 동시 1개 PR 만 merge
- 선착순 (`cancel-in-progress: false`)
- CI 실패 시 해당 PR 만 탈락, 다음 PR 은 정상 진행

## L4. Merge Strategy (BLANK-3 결정, 2026-04-27)

다중 세션 worktree merge 충돌 해소 규칙. Phase_1_Decision_Queue.md C.4 결정에 따른 명문화.

### Default 전략

- **worktree-based fast-forward merge** (Conductor `/team-merge` 커맨드 사용)
- 비-worktree (subdir) 모델은 v5.0 에서 deprecated, **사용 금지**

### Conflict 사전 검출

- pre-push hook (`.claude/hooks/pre_push_conflict_check.py` — 신규 권고, 후속 PR 대상)
- 검사 내용: `git diff origin/main` 의 변경 파일 목록 vs 다른 활성 worktree 브랜치의 변경 파일 목록 cross-overlap
- overlap 감지 시: push 차단 + 경고 메시지 + 해소 안내

### Resolution 절차

1. 충돌 감지 → Conductor 세션이 중재
2. `git pull --rebase origin/{branch}` 으로 base 동기화
3. conflict 해소는 의미적 (decision_owner 판정 — `team-policy.json` `contract_ownership` 참조)
4. Conductor `/team-merge` 가 최종 fast-forward 판정

### Active Worktree 우선순위

- **sibling-dir worktree** (예: `C:/claude/ebs-team1-flutter`) — **현재 채택 모델**
- subdir worktree (예: `ebs/team1-frontend/`) — **deprecated v5.0**

### 현재 활성 worktree (참고, 2026-04-27 시점)

- 8개 active. `git worktree list` 로 실시간 확인.

### 참조

- Spec_Gap_Registry BLANK-3
- `docs/4. Operations/Phase_1_Decision_Queue.md` (2026-04-27 C.4)
- `team-policy.json` `governance_model: free_write_with_decision_owner`

## 거버넌스 (v7.5)

`team-policy.json` v7.5 `free_write_with_autonomous_triage_or_full_authority` 모델:

- **Write access**: 모든 세션이 모든 docs 자유 편집 (v7 부터 동일)
- **Decision authority** (v7.5):
  - Mode A (Conductor 단독) → `conductor_full_authority`
  - Mode B (멀티세션, default) → `autonomous_llm_judgment` (`tools/conflict_resolver.py` 4-Step Decision)
  - Mode B legacy (escape hatch) → `EBS_GOV_MODE=v71_decision_owner` 시 v7.1 CODEOWNERS 회복
- **Conflict resolution**:
  - syntactic = rebase (`team_v5_merge.py`)
  - semantic Mode A = Conductor adjudicates
  - semantic Mode B = `tools/conflict_resolver.py` 자율 + audit (`Conflict_Registry.md` + GH issue)
  - escalation = user (autonomous Step 4 fallback 도 실패 시)

## Free-tier 제약 (GitHub 플랜)

| 기능 | GitHub Pro/Team plan | EBS Free tier 대응 |
|------|:--------------------:|---------------------|
| Merge Queue (native) | ✓ | `concurrency:` group in workflow |
| Branch protection (private repo) | ✓ | workflow 가 gate 역할 대체 |
| Required CODEOWNERS review | ✓ | 자동 알림만, 강제 block 아님 |
| auto-merge (private) | ✓ | `auto-merge` 라벨 + workflow trigger |

**위험 수용**: free-tier 는 서버측 강제 없음. `gh pr merge --admin` 으로 CI/concurrency 우회 가능. **EBS 단일 소유자 repo 에서는 실질 위험 없음** (소유자=사용자 자신).

## 금지 (v5.0)

- subdir 세션 (`C:/claude/ebs/team{N}-*/`) 에서 `/team` 호출 — **sibling worktree 강제**
- Conductor 직접 `git push origin main` — **PR 경로 사용**
- `--no-pr` flag 로 v4.0 동작 요청 — **v5.0 은 PR-only**
- `gh pr merge --admin` 으로 CI/concurrency 우회 — **긴급 hotfix 제외**
- `~/.claude/skills/team/` v4.0 user-global 스킬 — **deprecated**. project-local `.claude/skills/team/` (v5.1) 이 호출 우선순위에서 덮어쓴다. v4.0 user-global 은 deprecation shim 으로 교체 예정

## 마이그레이션 로드맵

`docs/4. Operations/V5_Migration_Plan.md` 참조.

## 관련 자산

### Repo-local (v5.0 active)
- `.claude/skills/team/SKILL.md` — project-local skill (2026-04-22 rename from `team-v5`)
- `.github/workflows/pr-auto-merge.yml` — Phase 3 free-tier gate
- `.github/CODEOWNERS` — Phase 2 자동 리뷰어
- `tools/team_v5_merge.py` — Phase 2 구현
- `tools/setup_team_worktrees.py` — Phase 1 setup
- `tools/team_pr_merge.py` — v4.1 호환 (2026-05-05 까지 유지)

### Deprecated (2026-05-05 제거 예정)
- `~/.claude/skills/team/SKILL.md` (user-global v4.0)
- `~/.claude/skills/team/scripts/*.py` 11 files
- `.claude/hooks/session_branch_init.py` → `claude -w` 가 대체
- `.claude/hooks/branch_guard.py` → GitHub workflow 가 대체 (Pro/Team plan 필요시 Pro/Team plan 필요시 복원)

## 변경 이력

| 날짜 | 버전 | 요약 |
|------|------|------|
| 2026-04-10 | v4.0 | Pre-Declaration manifest + conflict scan + safety gate 도입 |
| 2026-04-21 | v4.1 | Hybrid PR (Team=PR / Conductor=direct) patch |
| 2026-04-21 | v5.0 | 전체 재설계. 업계 표준 재사용. 3-Phase. free-tier 호환. v4.0/v4.1 deprecated |
| 2026-04-22 | **v5.1** | **L0 Pre-Work Contract 추가** (Active_Work.md). proactive coordination + reactive merge gate 이중 안전망. 4-Phase |
| 2026-04-27 | **v5.1+L4** | **L4 Merge Strategy 추가** (BLANK-3). worktree fast-forward + pre-push hook 명문화. Phase_1_Decision_Queue C.4 결정 |
| 2026-04-28 | **v7.5** | **Autonomous Conflict Triage** (SG-028). Mode B 의미적 판정 → autonomous_llm_judgment. 4-Step Decision Logic + Conflict_Registry.md audit. CI fallback (ci-only mode) 분리. |

## 근거 Research (2026-04-21)

- [Multi-Agent AI Coding Workflow: Git Worktrees That Scale](https://blog.appxlab.io/2026/03/31/multi-agent-ai-coding-workflow-git-worktrees/)
- [How GitHub uses merge queue to ship hundreds of changes every day](https://github.blog/engineering/engineering-principles/how-github-uses-merge-queue-to-ship-hundreds-of-changes-every-day/)
- [Claude Code Common Workflows (official)](https://code.claude.com/docs/en/common-workflows)
- [The Code Agent Orchestra — AddyOsmani](https://addyosmani.com/blog/code-agent-orchestra/)
- [Git Worktree Documentation — git-scm.com](https://git-scm.com/docs/git-worktree)
