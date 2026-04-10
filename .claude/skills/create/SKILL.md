---
name: create
description: Create PRD, PR, or documentation (prd, pr, docs)
triggers:
  keywords:
    - "create"
---

# /create

이 스킬은 `.claude/commands/create.md` 커맨드 파일의 내용을 실행합니다.

## 서브커맨드 라우팅

| 서브커맨드 | 동작 |
|-----------|------|
| `prd` | PRD 문서 생성 (`docs/00-prd/`) |
| `pr` | Pull Request 생성 |
| `docs` | 일반 문서 생성 |

## Usage

```bash
/create prd "로그인 기능"        # PRD 신규 생성
/create pr                      # 현재 브랜치로 PR 생성
/create docs "API 가이드"        # 문서 생성
```

## 커맨드 파일 참조

상세 워크플로우: `.claude/commands/create.md`
