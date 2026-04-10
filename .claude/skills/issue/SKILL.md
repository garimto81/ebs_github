---
name: issue
description: GitHub issue lifecycle management (list, create, fix, failed)
triggers:
  keywords:
    - "issue"
---

# /issue

이 스킬은 `.claude/commands/issue.md` 커맨드 파일의 내용을 실행합니다.

## 서브커맨드 라우팅

| 서브커맨드 | 동작 |
|-----------|------|
| `list` | 이슈 목록 조회 |
| `create` | 새 이슈 생성 |
| `fix` | 이슈 기반 버그 수정 워크플로우 |
| `failed` | 실패한 이슈 재시도 |

## Usage

```bash
/issue list                     # 열린 이슈 목록
/issue create "버그 제목"        # 새 이슈 생성
/issue fix #42                  # 이슈 #42 수정 워크플로우
/issue failed #42               # 실패한 수정 재시도
```

## 커맨드 파일 참조

상세 워크플로우: `.claude/commands/issue.md`
