---
name: chunk
description: PDF 청킹 - 토큰 기반(텍스트) 또는 페이지 기반(레이아웃 보존) 분할
triggers:
  keywords:
    - "chunk"
---

# /chunk

이 스킬은 `.claude/commands/chunk.md` 커맨드 파일의 내용을 실행합니다.

## 서브커맨드 라우팅

| 서브커맨드 | 동작 |
|-----------|------|
| `text` | 토큰 기반 청킹 (텍스트 추출 후 분할) |
| `page` | 페이지 기반 청킹 (레이아웃 보존) |

## Usage

```bash
/chunk text "report.pdf" --tokens 2000    # 2000 토큰 단위 분할
/chunk page "report.pdf" --pages 5        # 5페이지 단위 분할
/chunk "report.pdf"                       # 자동 모드 선택
```

## 커맨드 파일 참조

상세 워크플로우: `.claude/commands/chunk.md`
