---
title: NOTIFY-S3 — PR #171 CI FAILURE (4 checks) — owner fix 필요
owner: conductor (audit trail)
target: stream:S3 (Command Center)
tier: notify
status: OPEN
pr: 171
issue: 162
last-updated: 2026-05-08
mirror: none
---

# NOTIFY-S3 — PR #171 CI FAILURE (4 checks)

## 트리거

2026-05-08 정합성 감사 (#168) Phase 1 (open PR review) 결과. PR #171 `docs(s3-cc): consistency audit 2026-05-08` 의 CI 가 4개 체크 FAILURE. main baseline 은 정상 (최근 5개 run SUCCESS) → PR 자체 변경사항의 결함.

## 실패 체크 (4)

| 체크 | workflow | 추정 원인 |
|------|----------|----------|
| `Validate frontmatter + legacy-id` | Spec Aggregate | frontmatter `legacy-id` 매핑 누락 또는 형식 위반 (BS-07-XX cleanup 잔여 가능) |
| `scope-check` | V9.2 Scope Check | S3 owner 영역 외 파일 변경 또는 cascade 동시 변경 누락 |
| `Validate relative links (conductor)` | Validate Markdown Links | conductor 영역 (docs/4. Operations 등) 으로의 dead-link |
| `Validate relative links (team1)` | Validate Markdown Links | team1 (Lobby) 영역으로의 dead-link |

상세 로그: PR #171 → Checks 탭

## 처리 요청 (S3 worktree)

`work/s3/2026-05-08-init` 브랜치에서:

1. **frontmatter 검증**: `python tools/validate_frontmatter.py` (있다면) 또는 변경 파일의 `legacy-id` 필드 형식 점검 (`BS-07-00` 등 표준 형식)
2. **scope_check 재현**: `.github/workflows/scope_check.yml` 의 `verify-scope` 잡과 동일한 검증을 로컬 실행
3. **relative links**: `find . -name "*.md" -newer <merge-base>` 로 변경 파일 list → 각 파일의 markdown link 가 유효한지 확인 (특히 conductor / team1 영역 인용)
4. fix commit 후 push → CI green 시 main 자동 머지 가능

## main 직접 fix 금지 사유

worktree 룰 (team-policy.json `branch_strategy.subdir_mode: forbidden`): S3 영역 (`docs/2. Development/2.4 Command Center/`) 은 S3 worktree 만 수정 가능. main(conductor) 직접 수정은 owner 권한 침해.

## 의존성

- 본 issue 차단 시 Conductor Phase B (#168) 진입 불가
- drift sub-issue #178/#179/#182 는 본 PR 이 머지된 후에야 starting baseline 확보

## 참조

- PR #171: https://github.com/garimto81/ebs_github/pull/171
- Issue #162: 메타 (S3 정합성 감사)
- Conductor spec: `docs/4. Operations/orchestration/2026-05-08-consistency-audit/conductor-spec.md` Phase 1
- 본 audit 발견 source: 2026-05-08 정합성 감사 Phase 1 PR review
