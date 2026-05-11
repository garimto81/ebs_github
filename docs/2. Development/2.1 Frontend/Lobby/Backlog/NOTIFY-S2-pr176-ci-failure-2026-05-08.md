---
title: NOTIFY-S2 — PR #176 CI FAILURE (3 checks) — owner fix 필요
owner: conductor (audit trail)
target: stream:S2 (Lobby)
tier: notify
status: RESOLVED
pr: 176
issue: 161
last-updated: 2026-05-11
resolved-at: 2026-05-11
resolved-by: stream:S2 (v10.4 cascade audit)
mirror: none
---

# NOTIFY-S2 — PR #176 CI FAILURE (3 checks) — RESOLVED 2026-05-11

> **RESOLVED (2026-05-11, v10.4 cascade audit)**: PR #176 은 머지 후 main 의 후속 commit 들 (특히 `c5e862ce fix(ci): orchestration frontmatter owner + dead links — root cause for 4 PR CI fail`) 로 인해 모든 CI 체크가 통과 상태. `gh pr checks 176` 결과 fail/pending = 0. 추가 fix commit 불필요.

## 트리거

2026-05-08 정합성 감사 (#168) Phase 1 (open PR review) 결과. PR #176 `docs(s2-lobby): consistency audit 2026-05-08` 의 CI 가 3개 체크 FAILURE. main baseline 은 정상 → PR 자체 변경사항의 결함.

## 실패 체크 (3)

| 체크 | workflow | 추정 원인 |
|------|----------|----------|
| `Validate frontmatter + legacy-id` | Spec Aggregate | frontmatter `legacy-id` 매핑 누락 또는 형식 위반 |
| `Validate relative links (conductor)` | Validate Markdown Links | conductor 영역 (docs/4. Operations 등) 으로의 dead-link |
| `Validate relative links (team1)` | Validate Markdown Links | team1 영역 내 dead-link (S2 영역은 team1 owns) |

성공 체크 (참고): scope-check, verify-scope, verify-phase, verify-deps, WSOP LIVE alignment, EBS structure alignment 모두 SUCCESS — 즉 의미적 cascade 는 정합. 형식적 link/frontmatter 만 결함.

## 처리 요청 (S2 worktree)

`work/s2/2026-05-08-init` 브랜치에서:

1. **frontmatter 검증**: 변경 파일의 frontmatter `legacy-id` 필드 형식 점검
2. **relative links**: 변경 파일에서 conductor / team1(Lobby) 영역 markdown link 재검증
3. fix commit 후 push → CI green 시 자동 merge 가능

## drift sub-issue 동시 처리 가능

PR #176 fix 시 issue **#181** (Lobby/Overview.md `CC = Flutter Web` vs Foundation §A.4 `Flutter Desktop` drift) 도 같은 PR 에 포함 가능. 단, S4 PR #177 의 cross-stream advisory 와 정합 결정 필요 (옵션 a/b/c — 본 NOTIFY 와 별개로 #181 본문 참조).

## main 직접 fix 금지 사유

worktree 룰: S2 영역 (`docs/2. Development/2.1 Frontend/`) 은 S2 worktree 만 수정 가능.

## 의존성

- 본 PR 차단 시 Conductor Phase B (#168) 진입 불가
- drift sub-issue #181 은 본 PR 또는 후속 PR 에서 처리

## 참조

- PR #176: https://github.com/garimto81/ebs_github/pull/176
- Issue #161: 메타 (S2 정합성 감사)
- Issue #181: drift sub-issue (CC=Flutter Web 표기)
- Conductor spec: `docs/4. Operations/orchestration/2026-05-08-consistency-audit/conductor-spec.md` Phase 1
