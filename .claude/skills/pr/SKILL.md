---
name: pr
description: PR review, improvement suggestions, and auto-merge workflow
triggers:
  keywords:
    - "pr"
---

# /pr

이 스킬은 `.claude/commands/pr.md` 커맨드 파일의 내용을 실행합니다.

## 서브커맨드 라우팅

| 서브커맨드 | 동작 |
|-----------|------|
| `review` | PR 코드 리뷰 |
| `improve` | 개선 제안 생성 |
| `merge` | 자동 머지 워크플로우 |
| (없음) | 현재 브랜치 PR 생성 |

## Usage

```bash
/pr                             # 현재 브랜치로 PR 생성
/pr review #15                  # PR #15 코드 리뷰
/pr improve #15                 # PR #15 개선 제안
/pr merge #15                   # PR #15 자동 머지
```

## 커맨드 파일 참조

상세 워크플로우: `.claude/commands/pr.md`
