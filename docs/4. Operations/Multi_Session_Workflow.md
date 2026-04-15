---
title: Multi-Session Workflow (Worktree-based)
owner: conductor
tier: contract
last-updated: 2026-04-15
---

# Multi-Session Workflow — Worktree 기반

## 개요

4팀 병렬 개발에서 세션 전환 비용을 낮추고 브랜치 격리를 강화하기 위한 워크트리 기반 멀티 세션 워크플로우. 기존 `team-policy.json` v6 `free_write_with_decision_owner` 모델과 정합하며, CR draft 프로세스(폐기) 이후의 표준 운영 방식.

## 배경

| 항목 | 내용 |
|------|------|
| 거버넌스 모델 | `free_write_with_decision_owner` (`docs/2. Development/2.5 Shared/team-policy.json` v6) |
| 브랜치 전략 | 팀별 작업 브랜치 `work/team{N}/*` → `/team-merge` 로 main 통합 |
| 실 안전 게이트 | decision_owner 규율 (hook 강제는 미구현) |
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

## 알려진 리스크

1. **격리 착시**: worktree 가 별개 폴더라는 이유로 공유 `docs/` 규율이 이완될 수 있음. decision_owner 규율 강화 필요.
2. **hook 미구현**: PreToolUse 기반 scope 차단이 없음. 위반은 리뷰 단계에서만 포착됨.
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
| 2026-04-15 | v1.0 | Worktree 기반 멀티 세션 워크플로우 정식화. 기존 부분 채택 상태 표준화 | CR draft 폐기 + free_write 모델 정합, critic 검토 결과 (plan: abundant-skipping-moonbeam) |
