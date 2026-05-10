---
title: NOTIFY-S8 — PR #180 CI FAILURE (5 checks) — owner fix 필요
owner: conductor (audit trail)
target: stream:S8 (Game Engine)
tier: notify
status: OPEN
pr: 180
issue: 167
last-updated: 2026-05-08
mirror: none
---

# NOTIFY-S8 — PR #180 CI FAILURE (5 checks)

## 트리거

2026-05-08 정합성 감사 (#168) Phase 1 (open PR review) 결과. PR #180 `docs(s8-engine): consistency audit 2026-05-08` 의 CI 가 5개 체크 FAILURE. main baseline 은 정상 → PR 자체 변경사항의 결함.

## 실패 체크 (5)

| 체크 | workflow | 추정 원인 |
|------|----------|----------|
| `Validate frontmatter + legacy-id` | Spec Aggregate | frontmatter `legacy-id` 매핑 누락 또는 형식 위반 |
| `Validate relative links (conductor)` | Validate Markdown Links | conductor 영역 (docs/4. Operations 등) 으로의 dead-link |
| `Validate relative links (team1)` | Validate Markdown Links | team1 영역 dead-link |
| `verify-phase` | phase_gate_check | 변경 파일이 Phase gate 단계와 정합하지 않음 |
| `verify-scope` | scope_check | S8 owner 영역 외 파일 변경 또는 cascade 동시 변경 누락 |

성공 체크 (참고): scope-check (V9.2), WSOP LIVE alignment, verify-deps, validate links (team2/3/4), GitGuardian 모두 SUCCESS.

## 처리 요청 (S8 worktree)

`work/s8/2026-05-08-init` 브랜치에서:

1. **scope 위반 점검**: `git diff main...work/s8/2026-05-08-init --name-only` 결과가 `docs/2. Development/2.3 Game Engine/**` + 허용된 cascade 만 포함하는지 확인. team-policy.json `team3.owns` (Engine) 외 파일 변경 시 NOTIFY 또는 별도 PR 분리.
2. **phase_gate**: 변경 파일이 P2 (Wave 2 — S2~S4,S7,S8) phase 와 정합한지 확인
3. **frontmatter / links**: 위와 동일
4. fix commit 후 push → CI green 시 자동 merge 가능

## main 직접 fix 금지 사유

worktree 룰: S8 영역 (`docs/2. Development/2.3 Game Engine/`) 은 S8 worktree 만 수정 가능.

## 의존성

- 본 PR 차단 시 Conductor Phase B (#168) 진입 불가
- Wave 2 의 마지막 stream (S2~S4,S7,S8) — 본 PR 머지 후 Wave 3 (S5/S6) dispatch 가능

## 참조

- PR #180: https://github.com/garimto81/ebs_github/pull/180
- Issue #167: 메타 (S8 정합성 감사)
- Conductor spec: `docs/4. Operations/orchestration/2026-05-08-consistency-audit/conductor-spec.md` Phase 1
