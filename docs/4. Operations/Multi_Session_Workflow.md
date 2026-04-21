---
title: Multi-Session Workflow (v4.1 — Hybrid PR + Worktree 강제)
owner: conductor
tier: contract
last-updated: 2026-04-21
reimplementability: PASS
reimplementability_checked: 2026-04-21
reimplementability_notes: "v4.1 Hybrid PR (Team=PR auto-merge / Conductor=direct) + subdir 차단 hook + PR 2-bis 별도 트랙"
---

# Multi-Session Workflow — v4.1 (Hybrid PR + Worktree)

## 🚀 표준 명령 (v4.1)

```bash
/team "<task description>"     # 팀/Conductor 세션 모두
```

**단일 호출로 다음 자동 실행 (10 Phase, v4.0 Pre-Declaration)**:
0. Declaration — 수정 대상 manifest 선언 (Lease TTL 5분)
0.5. Conflict Scan — 타 세션 manifest 와 대조
0.6. Plan Revision — 충돌 파일 제외 + cohesion_ratio 계산
0.7. Safety Gate — cohesion 기반 go/no-go
1. Context detect
2. Pre-sync (fetch + 다른 세션 활동 표시 + rebase)
3. Branch prep (초단기 work 브랜치)
4. `/auto "<task>"` 위임
5. Verify (drift + test + scope guard)
6. Auto commit (conventional + notify 태그)
7. **[v4.1 Hybrid]** Merge:
   - **Team 세션**: `tools/team_pr_merge.py --branch work/team{N}/*` → PR create + auto-merge
   - **Conductor**: main 직접 push 시도, 플랫폼 차단 시 PR fallback
8. Report (변경 / drift 변화 / 다른 세션 활동)

**세션 시작·종료 개념 없음** — 매 `/team` 이 완결된 트랜잭션.

## v4.1 변경 사항 (2026-04-21)

### 배경
- **Main push 차단**: Claude Code 플랫폼이 "bypasses PR review" 사유로 team session `git push origin main` 거부. v3.0 의 "팀도 main 직접 ff-merge" 가 실질적으로 차단됨.
- **Multi-session race**: subdir 모드 (`C:/claude/ebs/team{N}-*/`) 에서 실행한 `session_branch_init` 이 shared HEAD 를 이동 → Conductor worktree 오염 (reflog 증거 확인, 2026-04-21)
- **Manifest 비준수**: v4.0 Pre-Declaration 도입했으나 subdir 세션이 manifest 미등록한 채 편집

### v4.1 해결책

| 항목 | v3.0/v4.0 동작 | v4.1 동작 |
|------|---------------|-----------|
| **Team 세션 merge** | `git push origin main` 직접 | `gh pr create --fill --base main` + `gh pr merge --auto --squash --delete-branch` |
| **Conductor merge** | `git push origin main` | 동일 (변경 없음) — 플랫폼 차단 시 PR fallback |
| **subdir 세션 auto-branch** | `session_branch_init` 이 shared HEAD 이동 | **차단** — subdir 감지 시 skip + sibling worktree 사용 안내 |
| **Worktree 정책** | sibling 권장 (optional) | sibling **필수** (subdir 은 session_branch_init 이 거부) |

### 마이그레이션 (2026-04-21 진행중)

1. **worktree 생성**: `python tools/setup_team_worktrees.py` → `C:/claude/ebs-team{N}-work/` 일괄 생성
2. **팀 세션 재시작**: `cd C:/claude/ebs-team{N}-work && claude` — sibling worktree 에서 Claude Code 시작
3. **기존 subdir 세션 종료**: `C:/claude/ebs/team{N}-*/` 에서 띄운 세션은 session_branch_init 이 브랜치 전환을 skip 하므로 작업 불가 → 중단 후 sibling 으로 이동
4. **SKILL.md 반영**: `~/.claude/skills/team/SKILL.md` Phase 7 을 PR 모드로 업데이트 필요 — **user approval 필요** (self-modification 경계)

### 관련 자산

- `tools/team_pr_merge.py` (NEW) — v4.1 Hybrid PR merge 구현. SKILL.md 업데이트 전 수동 호출용
- `tools/setup_team_worktrees.py` (NEW) — sibling worktree 일괄 생성 헬퍼
- `.claude/hooks/session_branch_init.py` — v4.1: subdir 세션 자동 브랜치 전환 차단
- `.claude/hooks/branch_guard.py` — team session main push 차단 (유지)

### Self-Modification 경계

User-global `~/.claude/skills/team/` 파일은 세션이 자동 수정할 수 없다. v4.1 SKILL.md + team_merge_loop.py 변경은 사용자가 직접 수행 필요. 우회:
- repo-local `tools/team_pr_merge.py` 가 동등 기능 제공
- SKILL.md 업데이트 전까지 사용자가 Phase 7 대신 수동 호출: `python tools/team_pr_merge.py --branch <work-branch>`

## 개요

4팀 병렬 개발에서 세션 전환 비용을 낮추고 브랜치 격리를 강화하기 위한 워크트리 기반 멀티 세션 워크플로우. 기존 `team-policy.json` v6 `free_write_with_decision_owner` 모델과 정합.

> **역할 구분** (두 멀티세션 문서):
> - **이 문서 (`Multi_Session_Workflow.md`)** — **영구 운영 방법**: 브랜치 전략, worktree vs subdir, 팀 작업 표준 절차, 금지·리스크. "How to run multi-session?"
> - **`Multi_Session_Handoff.md`** — **현재 이관 스냅샷**: 2026-04-21 구조 재정비 완료 상태, 각 팀 우선 작업, 이관 체크리스트. "What to work on now?"
> 팀 세션 시작 시 둘 다 읽기 권장. Handoff 는 주기적으로 갱신.

## 배경

| 항목 | 내용 |
|------|------|
| 거버넌스 모델 | `free_write_with_decision_owner` (`docs/2. Development/2.5 Shared/team-policy.json` v6) |
| 브랜치 전략 | 팀별 작업 브랜치 `work/team{N}/*` → `/team-merge` 로 main 통합 |
| 실 안전 게이트 | decision_owner 규율 + L1/L2 hook (commit `4b41699`, `2ed152a` 이후) |
| 결정 날짜 | 2026-04-15 |

## 핵심 원칙 (v3.0)

1. **`/team` 이 표준 명령** — 모든 팀/Conductor 세션이 `/team "<task>"` 로 작업. 수동 git 조작 최소화.
2. **매 작업이 완결된 트랜잭션** — 1 `/team` 호출 = 1 commit + main 동기화. 세션 종료 불필요.
3. **팀도 main 직접 ff-merge** — 기존 Conductor 독점 정책 완화. work 브랜치는 `/team` 1회 내로 초단기 수명.
4. **Conflict 시 Pause + user confirm** — 자동화 한계선. 다른 모든 실패는 자동 retry 또는 rollback.
5. **Worktree는 격리가 아니라 비용 절감 도구** — 브랜치 단위 직접 편집 모델에 자연스럽게 매핑됨.
6. **공유 `docs/` 충돌은 worktree로 해결 안 됨** — decision_owner 규율 + `/team` scope guard 의 notify 태그가 게이트.
7. **Conductor 는 main worktree 고정** — 팀 작업 브랜치에서 문서 구조/통합 테스트 편집 금지 (`/team` scope guard 가 경고).

## 표준 디렉토리 레이아웃

| 용도 | 경로 | 브랜치 |
|------|------|--------|
| Conductor (main) | `C:/claude/ebs/` | `main` 고정 |
| Team 1 작업 | `C:/claude/ebs-team1-<slug>/` | `work/team1/<slug>` |
| Team 2 작업 | `C:/claude/ebs-team2-<slug>/` | `work/team2/<slug>` |
| Team 3 작업 | `C:/claude/ebs-team3-<slug>/` | `work/team3/<slug>` |
| Team 4 작업 | `C:/claude/ebs-team4-<slug>/` | `work/team4/<slug>` |

**네이밍 규약**: `ebs-team{N}-<kebab-slug>`. `-wt-` 중간 접두사는 폐기 (과거 `ebs-wt-team1-*` → 신규 생성 시 `ebs-team1-*`).

**이유**: sibling-dir 패턴 채택 (repo 내부 `.worktrees/` 회피). 기존 `ebs-team3-wsop` 와 일관성 유지.

## 표준 운영 절차 (v3.0 — /team 스킬)

### 1. 세션 환경 준비 (1회)

```bash
# Conductor (C:/claude/ebs) 에서 (필요 시 팀 worktree 생성)
git worktree add -b work/team{N}/_wt ../ebs-team{N}-<slug> main  # 선택적
cd ../ebs-team{N}-<slug>
```

**또는 subdir 모드** (worktree 없이):
```bash
cd C:/claude/ebs/team{N}-frontend
```

### 2. 작업 실행 (반복)

```bash
/team "<task description>"
```

매 호출이 자동으로:
- ✓ Pre-sync (fetch + rebase + 다른 세션 표시)
- ✓ `/auto` 실행
- ✓ Verify (drift + test + scope guard)
- ✓ Commit (conventional)
- ✓ Main ff-merge + push
- ✓ Report

세션 종료 불필요 — 항상 동기화 상태 유지.

### 3. 수동 병합 (fallback, 거의 불필요)

`/team` 이 실패하거나 여러 팀 브랜치를 Conductor 가 일괄 병합할 때:
```bash
# Conductor worktree 에서
/team-merge  # work/team{N}/<slug> → main (rebase + ff)
```

### 4. Worktree 정리 (필요 시)

```bash
git worktree remove ../ebs-team{N}-<slug>
```

**수명 길게 가진 work 브랜치** 는 `/team` 사용 안 할 때만 필요 (구식). `/team` 은 매 호출마다 초단기 work 브랜치 자동 생성·삭제.

## 금지

| 금지 | 이유 |
|------|------|
| Conductor worktree (`C:/claude/ebs/`) 에서 `work/team{N}/*` 브랜치 체크아웃 | 세션 경계 오염. Conductor 는 main 고정 |
| 팀 worktree 에서 다른 팀 문서 폴더 (`docs/2. Development/2.{다른팀}/`) 편집 | Scope 위반 |
| 팀 worktree 에서 `docs/1. Product/`, `docs/4. Operations/` 직접 편집 | Conductor 소유 (decision_owner 우회) |
| `ebs-wt-*` 접두사 신규 worktree 생성 | 네이밍 규약 위반 |
| `.worktrees/` 하위에 worktree 생성 | sibling-dir 규약 위반 |

## Hybrid Support — Subdir · Worktree 동시 지원

Worktree 모델은 **선택적**이며 기존 in-repo subdir 모델과 **공존 가능**. 두 모델은 동일한 자산(브랜치 이름 `work/team{N}/*`, `/team-merge`, `meta/active-edits`)을 공유하고, 차이는 오직 **작업자의 물리적 위치** 뿐.

| 용도 | Subdir 모델 | Worktree 모델 |
|------|-------------|---------------|
| Team 세션 CWD | `C:/claude/ebs/team{N}-frontend/` 등 | `C:/claude/ebs-team{N}-<slug>/` |
| 브랜치 전환 | 세션 시작 시 `git checkout work/team{N}/*` | 각 worktree = 1 브랜치 상주 |
| 병렬 팀 세션 | ❌ 한 repo에서 본질적 직렬 | ✅ 5 worktree 동시 |
| 디스크 비용 | repo 1개 | × 팀 수 |
| hook 지원 | ✅ `detect_team` Pattern B | ✅ `detect_team` Pattern A |

**선택 기준**:
- 세션 자주 재시작 + 디스크 제약 → **Subdir**
- 세션 유지 + 5팀 상시 병렬 → **Worktree**
- 혼합 가능 (일부 팀만 worktree)

## 알려진 리스크

1. **격리 착시**: worktree 가 별개 폴더라는 이유로 공유 `docs/` 규율이 이완될 수 있음. decision_owner 규율 강화 필요.
2. **Scope-block hook 미구현**: PreToolUse 기반 경로 소유권 차단은 없음 (v6 `free_write` 정책상 의도적). L1(branch) · L2(active-edits) hook은 구현됨.
3. **디스크 비용**: 팀별 worktree 상주 시 repo 파일 × N 배. SSD 용량 모니터링.
4. **Subdir 세션의 공유 HEAD race (v3.0 → v3.1 완화)**: Conductor 가 main 에 있고 subdir 팀 세션이 `git checkout -b work/teamN/...` 를 실행하면 subdir 이 공유 `.git/HEAD` 를 움직여 Conductor 도 그 브랜치로 따라 이동함. v3.1 의 session-pinned branch tracking 으로 감지 힌트 제공 (§"Phase 5 강화" 참조). **근본 해결은 sibling worktree 사용**.

## Phase 5 강화 (v3.1, 2026-04-21)

멀티 세션 동시 실행 시 관찰된 증상을 해소하기 위한 hook 보강. v3.0 정책은 유지.

### 관찰된 증상

| 증상 | 원인 |
|------|------|
| branch-guard 가 Conductor 에게 "team branch 에 올라감" 재경고 (override 무효화) | override key 가 `sid+cur` 기반이어서 다른 세션이 cur 을 또 다른 team 브랜치로 바꾸면 재발급 |
| "File has been modified since read, either by the user or by a linter" | 다른 세션이 동일 파일을 동시에 편집 + 같은 cwd 의 `git status` 재생성 |
| `git commit` 이 다른 파일까지 포함해서 커밋됨 | 다른 세션의 staged 변경이 같은 shared index 에 남아있는 상태 |
| subdir 팀 세션의 `session_branch_init` 이 Conductor HEAD 도 움직임 | subdir 은 공유 `.git` 을 사용하므로 `git checkout -b` 가 전역 영향 |

### Hook 보강

**`.claude/hooks/branch_guard.py` (v3.1)**:

| 개선 | 효과 |
|------|------|
| **Override key 를 `sid` 에만 의존** (`kind='conductor-commit-on-team-branch'`, `cur` 제거) | 다른 세션이 branch 를 움직여도 override 5분 내 유지 |
| **`_wait_for_index_lock()`**: `.git/index.lock` 존재 시 100ms × 30회 대기 | 다른 세션 `git add/commit` 과의 race 완화, 차단 대신 순차화 |
| **`_pin_session_branch()` / `_get_pinned_branch()`**: Conductor 가 main 에서 commit 할 때 session_id 를 key 로 "main" 기록 | 다음 commit 시 HEAD 가 움직였으면 "다른 세션 탓" 힌트를 경고문에 추가 |

**파일**: `.claude/.session-branches/<sid>.pin` (TTL 1h), `.claude/.branch-guard-overrides/<hash>.flag` (TTL 5분).

### 권장 운영 (v3.1)

- **Conductor 세션**: 항상 main 에 유지. subdir 세션과 동시 실행 시 **sibling worktree 로 분리** 권장.
- **Subdir 팀 세션**: `session_branch_init` 이 자동 생성한 branch 유지. 명시적 `git checkout` 금지 (branch_guard Rule 4 차단).
- **Sibling worktree 팀 세션**: 자체 HEAD 소유 → 자유 checkout 허용.
- **동시 실행 시**: 한 세션의 `/team` 이 진행 중인 동안 다른 세션은 편집 중단 또는 다른 파일 편집 권장.

### 복구 절차 (다른 세션이 HEAD 움직였을 때)

```bash
# 1. 증상 확인
git branch --show-current
# 현재 branch 가 의도와 다름

# 2. 내 작업 보존
git stash push -m "branch-race-recovery"

# 3. 원래 branch 복귀
git checkout main  # Conductor 의 경우

# 4. 작업 복원
git stash pop
```

## 관련 자산

| 자산 | 경로 |
|------|------|
| 팀 정책 SSOT | `docs/2. Development/2.5 Shared/team-policy.json` |
| 병합 스킬 | `/team-merge` |
| Superpowers 가이드 | `superpowers:using-git-worktrees` |
| Active-edits (정보성) | `meta/active-edits` orphan branch |

## Changelog

| 날짜 | 버전 | 변경 내용 | 결정 근거 |
|------|------|-----------|----------|
| 2026-04-21 | **v4.0** | **Pre-Declaration + Exclude+Revise 모델 구현**. 10 Phase 확장 (0/0.5/0.6/0.7 신설), session-manifest JSON (`.claude/.session-manifests/{sid}.json`) Lease TTL 5분, team-policy.json 자동 ownership 체크, cohesion_ratio 4 case 분기. 6 scripts: `team_manifest.py`, `team_declare.py`, `team_conflict_scan.py`, `team_plan_revise.py`, `team_safety_gate.py`, `team_cleanup.py`. Hook 연동: `session_branch_init.py` + `conductor_stop_cleanup.py` 에 stale cleanup 추가 | 사용자 지시 "충돌 사전 방지" + 2026 업계 검증 (Kubernetes Lease, Augment Intent, Beads, Cursor locking 실패 교훈). Plan: `Plans/Multi_Session_Workflow_v4_Conflict_Prevention_Plan_2026-04-21.md` (3 revisions) |
| 2026-04-21 | **v3.1** | Phase 5 Hook 강화: branch_guard 의 override key 를 session_id 만 의존으로 변경 (cur 독립), git index.lock 대기 (100ms × 30회), session-pinned branch tracking (`.claude/.session-branches/`). "알려진 리스크" §4 + "Phase 5 강화" 섹션 신설. | 2026-04-21 실측: 동시 세션 5회 이상 branch-guard 재경고 + `git add` 시 다른 세션 staged 변경 혼입. 근본 해결은 sibling worktree 이나 hook 으로 감지 힌트 추가 |
| 2026-04-21 | **v3.0** | **`/team` 스킬 도입**. 팀 main 직접 ff-merge 허용, work 브랜치 초단기 수명(`/team` 1회 내), 매 작업 auto commit+merge+push. `/team-merge` 는 fallback 으로 격하. 글로벌 스킬 `~/.claude/skills/team/` | 사용자 요구: "항상 동기화 유지", "세션 종료 개념 제거", 충돌 사전 방지를 작업 단위 분해로 해결 |
| 2026-04-20 | v2.0 | MVI (Minimum Viable Isolation) 도입. Phase 1-6: Conductor Stop hook, branch_guard 확장(subdir checkout 차단), fs lock(orphan branch 대체), FIFO merge queue, subagent isolation frontmatter. Active-edits orphan branch 레지스트리 비활성화 (파일은 역사 보존) | 2026-04-20 실측 사건 (Conductor worktree 오염 + L2 5일 dormant) + 2026 트렌드 (Worktrunk FIFO queue, Claude Code subagent isolation) |
| 2026-04-15 | v1.0 | Worktree 기반 멀티 세션 워크플로우 정식화. 기존 부분 채택 상태 표준화 | CR draft 폐기 + free_write 모델 정합, critic 검토 결과 (plan: abundant-skipping-moonbeam) |
