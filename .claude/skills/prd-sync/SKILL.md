---
name: prd-sync
description: PRD 동기화 (Google Docs -> 로컬)
triggers:
  keywords:
    - "prd-sync"
---

# /prd-sync

이 스킬은 `.claude/commands/prd-sync.md` 커맨드 파일의 내용을 실행합니다.

## 동작 요약

Google Docs에 작성된 PRD를 로컬 `docs/00-prd/` 디렉토리로 동기화합니다. OAuth 인증 기반.

## Usage

```bash
/prd-sync                       # 전체 PRD 동기화
/prd-sync "문서 URL"             # 특정 Google Docs 동기화
/prd-sync --dry-run             # 변경 미리보기 (실제 저장 안 함)
```

## 커맨드 파일 참조

상세 워크플로우: `.claude/commands/prd-sync.md`
