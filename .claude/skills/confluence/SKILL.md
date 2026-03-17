---
name: confluence
version: 1.0.0
description: >
  This skill should be used when the user needs to convert Markdown files to Confluence format and publish them to Confluence pages.
triggers:
  keywords:
    - "--con"
    - "confluence"
    - "컨플루언스"
    - "confluence upload"
---

# Confluence 발행 스킬 (`--con`)

> `/auto "작업" --con <page_id> [file]` — Markdown 문서를 Confluence 페이지로 변환 발행

## 개요

Markdown 파일을 Confluence Storage Format으로 변환하여 지정 페이지에 발행한다.
이미지 첨부, Mermaid→PNG 렌더링, 테이블 auto-width 스타일링을 자동 처리한다.

## 사용법

```
/auto "기능 구현" --con <page_id>           # PRD/Plan 문서 자동 발행
/auto "기능 구현" --con <page_id> <file.md>  # 지정 파일 발행
```

### 파라미터

| 파라미터 | 필수 | 설명 |
|----------|:----:|------|
| `<page_id>` | YES | Confluence 페이지 ID (숫자) |
| `<file.md>` | NO | 발행할 MD 파일 경로. 미지정 시 PRD 또는 Plan 문서 자동 탐지 |

### 옵션

| 옵션 | 효과 |
|------|------|
| `--dry-run` | 업로드 없이 미리보기 HTML만 생성 |

## 변환 파이프라인

```
MD 파일 읽기
     |
     v
Mermaid 블록 추출 → mmdc → PNG 렌더링
     |
     v
pandoc MD→HTML 변환
     |
     v
이미지 수집 + 너비 측정 (PIL)
     |
     v
HTML 후처리:
  - <img> → <ac:image> 매크로 (ri:attachment)
  - 720px 초과 이미지 → ac:width="720" 속성 추가
  - <table> → data-layout="default" (auto-width)
  - <th>/<td> 내용 → <p> 래핑
     |
     v
첨부파일 업로드 (이미지 + Mermaid PNG)
     |
     v
페이지 본문 업데이트 (version +1)
```

## 필수 도구

| 도구 | 용도 | 설치 |
|------|------|------|
| `pandoc` | MD→HTML 변환 | `scoop install pandoc` |
| `mmdc` | Mermaid→PNG 렌더링 | `npm i -g @mermaid-js/mermaid-cli` |
| `requests` | Confluence REST API | `pip install requests` |
| `Pillow` | 이미지 너비 측정 (720px 제한) | `pip install Pillow` |

## 환경변수

| 변수 | 필수 | 설명 |
|------|:----:|------|
| `ATLASSIAN_EMAIL` | YES | Confluence 사용자 이메일 |
| `ATLASSIAN_API_TOKEN` | YES | Atlassian API 토큰 |
| `CONFLUENCE_BASE_URL` | NO | 기본값: `https://ggnetwork.atlassian.net/wiki` |

## 실행 스크립트

**핵심 스크립트**: `lib/confluence/md2confluence.py`

```bash
# 직접 실행
python lib/confluence/md2confluence.py <file.md> <page_id>

# dry-run
python lib/confluence/md2confluence.py <file.md> <page_id> --dry-run
```

## /auto 통합 동작

`--con` 옵션이 `/auto`에 전달되면 **Step 2.0 (옵션 처리)** 단계에서 실행:

1. `page_id` 파라미터 파싱
2. 발행 대상 파일 결정:
   - 명시적 파일 경로 → 해당 파일
   - 미지정 시 → `docs/00-prd/{feature}.prd.md` 또는 `docs/01-plan/{feature}.plan.md`
3. `lib/confluence/md2confluence.py` 실행
4. 결과 보고 (성공/실패 + 페이지 버전)

## 에러 처리

| 에러 | 처리 |
|------|------|
| 인증 실패 (401) | 환경변수 확인 안내 + 중단 |
| 페이지 미존재 (404) | page_id 확인 안내 + 중단 |
| mmdc 미설치 | Mermaid 블록을 코드 블록으로 유지 + 경고 |
| 이미지 파일 누락 | 누락 파일 목록 출력 + 나머지 계속 진행 |
| pandoc 실패 | 에러 메시지 출력 + 중단 |

**옵션 실패 시: 에러 출력, 절대 조용히 스킵 금지.**
