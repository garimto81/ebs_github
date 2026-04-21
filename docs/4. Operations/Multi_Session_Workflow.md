---
title: Multi-Session Workflow (Worktree-based)
owner: conductor
tier: contract
last-updated: 2026-04-15
---

# Multi-Session Workflow — Worktree 기반

## 개요

4팀 병렬 개발에서 세션 전환 비용을 낮추고 브랜치 격리를 강화하기 위한 워크트리 기반 멀티 세션 워크플로우. 기존 `team-policy.json` v6 `free_write_with_decision_owner` 모델과 정합하며, CR draft 프로세스(폐기) 이후의 표준 운영 방식.

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

## 핵심 원칙

1. **Worktree는 격리가 아니라 비용 절감 도구** — 브랜치 단위 직접 편집 모델에 자연스럽게 매핑됨. 안전성 자체를 높이지 않음.
2. **공유 `docs/` 충돌은 worktree로 해결 안 됨** — decision_owner 규율이 유일한 게이트.
3. **Conductor 는 main worktree 고정** — 팀 작업 브랜치에서 문서 구조/통합 테스트 편집 금지.
4. **1 worktree = 1 작업 브랜치** — 브랜치 체크아웃 전환 대신 cd 전환.

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

## 표준 운영 절차

### 1. 팀 작업 시작

```bash
# Conductor (C:/claude/ebs) 에서
git worktree add -b work/team{N}/<slug> ../ebs-team{N}-<slug> main
cd ../ebs-team{N}-<slug>
# 세션 시작 → cwd 기반으로 team{N}-*/CLAUDE.md 자동 로딩
```

### 2. 팀 작업 진행

- 각 worktree 에서 독립 세션 운영
- 팀 코드 (`team{N}-*/`) + 소유 문서 경로 (`docs/2. Development/2.{N} *`) 편집 가능
- 공유 `docs/1. Product/`, `docs/2. Development/2.5 Shared/`, `docs/4. Operations/` 편집 시 **decision_owner 확인 필수**

### 3. 병합 (Conductor 세션)

```bash
# Conductor worktree (C:/claude/ebs) 에서
/team-merge  # work/team{N}/<slug> → main (rebase + ff)
```

### 4. Worktree 정리

```bash
git worktree remove ../ebs-team{N}-<slug>
git branch -D work/team{N}/<slug>  # 병합 후
```

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
| 2026-04-20 | v2.0 | MVI (Minimum Viable Isolation) 도입. Phase 1-6: Conductor Stop hook, branch_guard 확장(subdir checkout 차단), fs lock(orphan branch 대체), FIFO merge queue, subagent isolation frontmatter. Active-edits orphan branch 레지스트리 비활성화 (파일은 역사 보존) | 2026-04-20 실측 사건 (Conductor worktree 오염 + L2 5일 dormant) + 2026 트렌드 (Worktrunk FIFO queue, Claude Code subagent isolation) |
| 2026-04-15 | v1.0 | Worktree 기반 멀티 세션 워크플로우 정식화. 기존 부분 채택 상태 표준화 | CR draft 폐기 + free_write 모델 정합, critic 검토 결과 (plan: abundant-skipping-moonbeam) |
