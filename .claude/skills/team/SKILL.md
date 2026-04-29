---
name: team
description: EBS V9.0 Hub-and-Spoke 멀티세션 워크플로우 (2026-04-29). 팀 세션 = Worker. Conductor = Hub. Worker 는 PR 보고까지만, main 머지 절대 금지. Task_Dispatch_Board.md 가 SSOT. v8.0 자율 머지 폐기.
---

# /team — EBS Multi-Session Workflow V9.0

> **버전 표기 규칙** — skill 식별자(`team`) 와 정책 버전(`V9.0`) 은 독립.

## 🎯 V9.0 패러다임 (Hub-and-Spoke)

- **Conductor (Hub)** — 작업 dispatch + 리뷰 + 머지 권한 독점
- **팀 세션 (Worker, Spoke)** — 할당 작업 구현 + PR 보고까지만
- **Task_Dispatch_Board.md** — 작업 + 상태 SSOT (`docs/4. Operations/Task_Dispatch_Board.md`)
- **자율 머지 폐기** — `auto-merge` 라벨 / `pr-auto-merge.yml` 워크플로우 비활성

## 🚫 절대 규칙 (Worker)

| 금지 행위 | 이유 |
|-----------|------|
| `gh pr merge` 호출 | main 머지 권한은 Conductor 만 |
| `git push origin main` | 직접 push 금지 (PR 경로 강제) |
| `auto-merge` 라벨 부여 | V9.0 워크플로우 비활성. 부여해도 머지 미발생 |
| 충돌 해결 시도 | rebase 충돌 시 PR 에 `conflict` 라벨 + Conductor 알림 |
| 보드 외 작업 자율 착수 | 발견 사항은 PR comment 또는 Backlog 에만 추가 |
| Idle 상태 무시 | `REVIEW_READY` 보고 후 다음 작업 받을 때까지 대기 |

## 🔄 V9.0 3-Step Worker SOP

### Step 1: Pickup — 보드에서 자기 task 확인

```bash
# 1. 본 보드 열기
$EDITOR "docs/4. Operations/Task_Dispatch_Board.md"

# 2. 본인 팀 row 의 ASSIGNED 항목만 확인 (다른 팀 row 무시)
# 3. 등록된 작업이 없으면 Idle 대기. 자율 작업 시작 금지
```

**금지**: Conductor 가 등록하지 않은 작업 자율 착수.

### Step 2: Execute — Sibling worktree 에서 구현 + 테스트

```bash
# 1. Sibling worktree 진입
cd C:/claude/ebs-team{N}-work

# 2. 보드 row → IN_PROGRESS 갱신 후 commit
git add "docs/4. Operations/Task_Dispatch_Board.md"
git commit -m "chore(board): TDB-NNN IN_PROGRESS"

# 3. /auto "<task description>" 위임 (PDCA 워크플로우)
# 4. 자체 테스트 (pytest / dart analyze / flutter test) 통과 확인
# 5. work/team{N}/<slug> 브랜치에 commit
```

**범위 규칙**: 보드의 scope 컬럼 명시 파일만 편집. 발견된 추가 작업은 PR comment / Backlog 추가.

### Step 3: Report — Draft/Ready PR 생성 + REVIEW_READY 보고

```bash
# 1. Push + PR 생성 (Draft 또는 Ready, auto-merge 라벨 금지)
git push -u origin work/team{N}/<slug>
gh pr create --draft --fill --base main \
  --title "feat(team{N}): TDB-NNN <task title>" \
  --body "$(cat <<'EOF'
## Task ID
TDB-NNN

## Scope
- file1.py
- file2.dart

## 자체 테스트
- [x] pytest (or dart analyze, flutter test)
- [x] scope 외 파일 미편집 확인

## V9.0 보고
REVIEW_READY 상태로 Conductor 리뷰 대기.
EOF
)"

# 2. 보드 row → REVIEW_READY + PR URL 기재 + commit + push
git add "docs/4. Operations/Task_Dispatch_Board.md"
git commit -m "chore(board): TDB-NNN REVIEW_READY (PR #NN)"
git push

# 3. Idle 대기. Conductor 가 다음 task 등록할 때까지 시작 금지
```

**금지**: `gh pr merge`, `--label auto-merge`, `gh pr edit --add-label auto-merge`.

## 🛠 트리거 형태

```bash
/team "<task description>"     # V9.0 3-Step Worker SOP 실행
/team                          # 현재 상태 보고 (보드 자기 row 출력)
/team --help                   # 옵션 설명
```

## 📋 세부 실행 (args 있을 때, V9.0)

```markdown
1. Context detect
   - cwd 가 sibling worktree (`ebs-team{N}-...`) 인지 확인
   - subdir 감지 시 error: "sibling worktree 필요"
   - Conductor 세션이면 → "Worker SOP 가 아니라 Hub SOP 입니다. Multi_Session_Workflow.md 참조" error

2. Step 1 Pickup
   - docs/4. Operations/Task_Dispatch_Board.md 의 본인 팀 row 확인
   - ASSIGNED 항목과 args 의 task description 매칭 확인
   - 매칭 안 되면 Conductor 등록 대기 + return

3. Step 2 Execute
   - 보드 row → IN_PROGRESS commit
   - /auto "<task>" 위임 (PDCA 워크플로우 그대로)
   - 자체 테스트 확인

4. Step 3 Report
   - git push + gh pr create --draft (auto-merge 라벨 부여 금지)
   - 보드 row → REVIEW_READY + PR URL commit + push
   - PR URL 사용자에게 보고
   - Idle 상태 진입 안내
```

## 🔍 Edge Cases

| 상황 | V9.0 대응 |
|------|-----------|
| 보드에 ASSIGNED 가 없음 | Idle 대기 + Conductor 알림. 자율 착수 금지 |
| Rebase conflict | PR 에 `conflict` 라벨 부여 + Conductor 알림. 직접 해결 금지 |
| CI 실패 | PR 본문에 결과 기재 + 보드 row 는 REVIEW_READY 유지 (Conductor 판단) |
| 동시 PR 보고 | Conductor 가 단일 스레드 리뷰. Worker 는 추가 작업 받을 때까지 대기 |
| 다른 팀 영역 편집 필요 | PR comment 로 사유 명시 + Conductor 결정 대기 |
| 보드 외 작업 발견 | Backlog (`팀별 Backlog.md`) 추가 후 Conductor 결정 대기 |
| gh CLI 미설치 | error + 설치 가이드 출력 |

## 📂 자산 맵

### Active (V9.0)

| 자산 | 역할 |
|------|------|
| `docs/4. Operations/Task_Dispatch_Board.md` | 작업 + 상태 SSOT |
| `docs/4. Operations/Multi_Session_Workflow.md` | V9.0 정책 본문 |
| `.github/CODEOWNERS` | 자동 리뷰어 알림 (Conductor 인지 보조) |
| `tools/team_v5_merge.py` | PR 생성 단계까지만 사용. **auto-merge 라벨 부여 단계 사용 금지** |
| `docs/2. Development/2.5 Shared/team-policy.json` | `governance_model: conductor_centralized_review` |

### Disabled / Deprecated (V9.0)

| 자산 | 상태 |
|------|------|
| `.github/workflows/pr-auto-merge.yml` | 비활성 (`workflow_dispatch` only) |
| `auto-merge` 라벨 | deprecated. 부여 금지 |
| v5.1 L0 Pre-Work Contract (`Active_Work.md`, `active_work_claim.py`) | V9.0 에서 Task_Dispatch_Board.md 가 대체 |
| v8.0 `concurrency: main-merge-queue` | Conductor 단일 스레드 리뷰가 대체 |
| `~/.claude/skills/team/` (v4.0 user-global) | deprecation shim |
| `.claude/hooks/session_branch_init.py` | `claude -w` 네이티브 대체 |

## 🌐 Free-tier 호환성

| 기능 | GitHub Team plan | EBS V9.0 대응 |
|------|:----------------:|----------------|
| Merge Queue | ✓ | **Conductor 단일 스레드 리뷰** |
| Branch protection | ✓ | Conductor 인지·판단 (정책 layer) |
| auto-merge | ✓ | **사용 안 함** |
| CODEOWNERS 강제 | ✓ | 자동 알림 + Conductor 리뷰 |

## 🚫 금지 (V9.0)

- subdir 세션 (`C:/claude/ebs/team{N}-*/`) 에서 본 스킬 호출
- 팀 세션의 `gh pr merge`, `git push origin main`, `auto-merge` 라벨 부여
- 팀 세션 자율 충돌 해결
- 보드 외 작업 자율 착수
- `--no-pr` flag 로 v4.0 동작 요청 (V9.0 은 PR-only)
- Conductor 동시 다중 PR 머지 (Hub 단일 스레드 원칙)

## 🔗 관련 문서

- `docs/4. Operations/Multi_Session_Workflow.md` — V9.0 SOP (정책 본문)
- `docs/4. Operations/Task_Dispatch_Board.md` — V9.0 작업 SSOT
- `docs/2. Development/2.5 Shared/team-policy.json` — `governance_model.merge_authority`
- `.github/workflows/pr-auto-merge.yml` — V9.0 비활성화 표기
