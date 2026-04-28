---
name: team
description: EBS v5.1 멀티세션 워크플로우 (2026-04-22). Pre-Work Contract + worktree + PR + free-tier merge gate. 4 Phase (Claim → Work → PR → Sync). v4.0/v4.1 deprecated — 구 user-global `~/.claude/skills/team/` (v4.0) 는 deprecation shim 으로 교체 예정. project-local skill (self-modification 경계 회피).
---

# /team — EBS Multi-Session Workflow v5.1

> **버전 표기 규칙** — skill 식별자(`team`) 와 정책 버전(`v5.1`) 은 독립. 호출명은 major 경계(v4→v5) 에서만 바뀌고, minor 업데이트(v5.0→v5.1) 는 문서 내용만 갱신.

## 철학 (v8.0)

- **Reactive 안전망 (L1-L3)**: worktree 격리 + PR + Actions concurrency
- **업계 표준 재사용** — custom orchestration 폐기. git worktree + GitHub PR + concurrency 로 해결
- **3 Phase** — Work (격리) → PR (동기화) → Sync (자동 merge)
- **Free-tier 호환** — GitHub Team plan 불필요. GitHub Actions concurrency group 으로 merge queue 대체
- **Self-modification 안전** — 이 스킬은 repo-local (`.claude/skills/team/`)
- **L0 폐기**: 30일 ROI 0 실증 (v8.0 Phase 6, 2026-04-28). `Reports/2026-04-28-v8-phase6-l0-removal-record.md`

## v4.0/v4.1 폐기 이유

> 2026-04-28 v8.0 Phase 8c: history 표 archive 이동.
> 상세: `docs/4. Operations/Reports/2026-04-28-v8-phase8c-skill-md-v4-history.md`

## 3 Phase Workflow (v8.0)

> v8.0 Phase 6 (2026-04-28): Phase 0 Claim 폐기. 30일 충돌 0건 → L0 ROI 0 실증.

### Phase 1: Work (격리된 worktree 에서 작업)

**Sibling worktree** 에서 Claude Code 세션 실행:

```bash
# 최초 1회 (팀별 worktree 생성)
git worktree add ../ebs-team1-work -b work/team1/work
git worktree add ../ebs-team2-work -b work/team2/work
git worktree add ../ebs-team3-work -b work/team3/work
git worktree add ../ebs-team4-work -b work/team4/work

# 이후 매 세션
cd C:/claude/ebs-team{N}-work
claude
```

또는 Claude Code v2.1.50+ 네이티브:

```bash
claude -w --branch work/team{N}/<slug>
```

**작업**:
- 해당 팀 소유 파일만 편집 (`team-policy.json` `teams[*].owns` 참조)
- `git add && git commit` 로 work 브랜치에 커밋
- 다른 팀 경로 편집 필요 시 CODEOWNERS 자동 리뷰어 추가됨

### Phase 2: PR (GitHub 에 개방)

```bash
# tools/team_v5_merge.py 호출 (또는 수동)
python tools/team_v5_merge.py

# 내부 동작:
#   1. git fetch origin && git rebase origin/main
#   2. git push --force-with-lease origin HEAD
#   3. gh pr create --fill --base main --label auto-merge
```

PR 생성 시 자동:
- CODEOWNERS 에 따라 리뷰어 배정
- `auto-merge` 라벨로 Phase 3 트리거 준비

### Phase 3: Sync (GitHub Actions 가 자동 merge)

`.github/workflows/pr-auto-merge.yml` 가 수행:

1. `concurrency: main-merge-queue` 로 동시 1 PR 만 처리 (race condition 방지)
2. 모든 required check 가 pass 할 때까지 대기 (최대 20분)
3. PR 이 main 에 behind 이면 auto-rebase + force-push
4. `gh pr merge --squash --delete-branch` 로 머지
5. 실패 시 `auto-merge` 라벨 제거 + PR 에 실패 이유 comment

**팀 세션 측 동작**: 아무것도 없음. GitHub 이 처리. worktree 는 다음 작업을 위해 유지.

## 트리거 형태

```bash
/team "<task description>"     # 4-phase 전체 실행 (v5.1)
/team                          # 현재 상태 보고
/team --help                   # 옵션 설명
```

## 세부 실행 (args 있을 때, v5.1)

```markdown
1. Context detect
   - cwd 가 sibling worktree (`ebs-team{N}-...`) 인지 확인
   - subdir 감지 시 error: "sibling worktree 필요. `git worktree add ../ebs-team{N}-<slug> -b work/team{N}/<slug>`"

2. Phase 0 Claim (v5.1 NEW)
   - python tools/active_work_claim.py list  (현 claim 전시)
   - python tools/active_work_claim.py check --scope "<예상 scope>"  (충돌 확인)
   - 충돌 있음 → 사용자에게 조율 요청 + return
   - 충돌 없음 → python tools/active_work_claim.py add --commit ...

3. Phase 1 /auto "<task>" 위임
   - 기존 PDCA 워크플로우 그대로 사용
   - work/team{N}/<slug> 브랜치에 commit
   - 동적 discovery 시 active_work_claim.py update --add-scope 로 scope 갱신

4. Phase 2 PR 생성
   - python tools/team_v5_merge.py
   - 출력 PR URL 을 사용자에게 보고
   - claim 자동 release (team_v5_merge.py 가 호출)

5. 보고 (Sync 는 백그라운드 CI 가 처리)
   - PR URL, 추정 merge 시간, 다음 Phase 모니터링 방법
```

## Edge Cases

| 상황 | v5.0 대응 |
|------|-----------|
| PR CI 실패 | workflow 가 `auto-merge` 라벨 제거 + comment. 수정 push 후 재부여 |
| Rebase conflict | workflow 가 라벨 제거 + assign 에게 알림 |
| 동시 PR 2개 | `concurrency: main-merge-queue` 가 직렬화 — 한 번에 1개 merge |
| Worktree 미생성 | Phase 1 detect 에서 error + setup 스크립트 안내 |
| 팀 소유 외 파일 편집 | CODEOWNERS 가 해당 owner 자동 리뷰어 지정 (차단 아님, v7 free_write) |
| gh CLI 미설치 | tools/team_v5_merge.py 가 에러 + 설치 가이드 출력 |

## 자산 맵

### Repo 파일
- `.github/workflows/pr-auto-merge.yml` — Phase 3 free-tier merge gate
- `.github/CODEOWNERS` — 팀별 자동 리뷰어 배정
- `tools/team_v5_merge.py` — Phase 2 PR 생성 + label 부착 + claim release
- ~~`tools/setup_team_worktrees.py`~~ — 2026-04-28 제거 (v8.0 Phase 7). `git worktree add` 직접 사용
- ~~`tools/team_pr_merge.py`~~ — 2026-04-28 제거 (v8.0 Phase 1)
- `tools/active_work_claim.py` — **v5.1 Pre-Work Contract CLI**
- `docs/4. Operations/Active_Work.md` — **v5.1 Pre-Work Contract SSOT**
- `docs/4. Operations/Multi_Session_Workflow.md` — v5.1 공식 정책
- `docs/4. Operations/V5_Migration_Plan.md` — 전환 로드맵
- `.claude/hooks/active_work_reminder.py` — v5.1 SessionStart 전시 훅 (수동 등록 필요)

### Deprecated (2026-05-05 제거 예정)
- `~/.claude/skills/team/` — v4.0 글로벌 스킬. `/team-v5` 가 대체
- `.claude/hooks/session_branch_init.py` — `claude -w` 네이티브가 대체
- `.claude/hooks/branch_guard.py` — GitHub branch protection 이 대체 (단, branch protection 은 public repo 만 free tier 지원)
- `~/.claude/skills/team/scripts/team_declare.py` / `team_conflict_scan.py` / `team_plan_revise.py` / `team_safety_gate.py` — GitHub merge gate 가 대체

## Free-tier 제약 및 우회

| 기능 | GitHub Team plan | EBS Free tier 우회 |
|------|:----------------:|--------------------|
| Merge Queue | ✓ | `concurrency:` group in Actions |
| Branch protection (private) | ✓ | `pr-auto-merge.yml` 이 CI gate 역할 |
| Required reviewer (CODEOWNERS) | ✓ | 자동 알림만. 강제 block 아님 |
| auto-merge (private) | ✓ | `auto-merge` 라벨 + workflow trigger |

**위험**: free-tier 는 **서버측 강제**가 없음. 악의적 사용자가 `gh pr merge --admin` 으로 CI 우회 가능. EBS 단일 소유자 repo 에서는 실질 영향 없음.

## 금지

- subdir 세션 (`C:/claude/ebs/team{N}-*/`) 에서 이 스킬 호출 금지 — sibling 강제
- Conductor 직접 `git push origin main` 금지 — PR 경로 사용
- `--no-pr` flag 로 기존 v4.0 동작 요청 금지 — v5.0 은 PR-only
- `auto-merge` 라벨 수동 부여 후 CI 미완료 상태에서 `--admin` merge 금지

## 관련

- 공식 정책: `docs/4. Operations/Multi_Session_Workflow.md`
- 마이그레이션 계획: `docs/4. Operations/V5_Migration_Plan.md`
- Research 근거: 2026-04-21 /team critic review (conversation history)
