---
name: chunk
version: 1.1.0
description: >
  This skill should be used when the user needs to split PDF files using token-based (text) or page-based (layout-preserving) chunking strategies.
triggers:
  keywords:
    - "chunk"
    - "/chunk"
    - "청킹"
    - "pdf 분할"
    - "토큰 분할"
---

# /chunk - PDF 청킹

PDF/MD를 LLM 입력용 청크로 분할한다. 모든 청킹 작업은 **백그라운드 실행** (Claude Code 멈춤 방지).

## 3가지 모드

| 모드 | 옵션 | 특징 | 용도 |
|------|------|------|------|
| **토큰** (기본) | - | 텍스트만 추출 | 순수 텍스트 분석 |
| **페이지** | `--page` | 레이아웃 100% 보존 | 이미지/표 포함, 멀티모달 LLM |
| **PRD** | `--prd` | 계층형 청킹, 섹션 메타데이터 | PRD/기획서 MD/PDF |

## Usage

```
/chunk <path>                          # 기본 토큰 청킹 (4000토큰, 200 오버랩)
/chunk <path> --tokens 2000            # 토큰 수 지정
/chunk <path> --overlap 100            # 오버랩 지정
/chunk <path> --info                   # PDF 정보만 확인 (빠름)
/chunk <path> --preview 3              # 처음 3개 청크 미리보기
/chunk <path> --page                   # 페이지 모드 (10페이지씩)
/chunk <path> --page --pages 20        # 페이지 수 지정
/chunk <path> --page --inline          # Base64 JSON (API용)
/chunk <path>.md --prd                 # PRD 계층형 청킹
/chunk <path>.md --prd --strategy semantic  # 표/목록 집중
/chunk <path>.md --prd --strategy fixed     # 고정 크기
```

## 옵션

### 공통

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `--info` | PDF 정보만 출력 (foreground) | - |
| `-o, --output` | 출력 경로 | 자동 생성 |

### 토큰 모드

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `-t, --tokens` | 청크당 최대 토큰 수 | 4000 |
| `--overlap` | 오버랩 토큰 수 | 200 |
| `--encoding` | tiktoken 인코딩 | cl100k_base |
| `--preview N` | 처음 N개 미리보기 | - |

### 페이지 모드

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `--pages N` | 청크당 페이지 수 | 10 |
| `--inline` | Base64 JSON 출력 | file |

### PRD 모드

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `--strategy` | 전략 강제 (hierarchical/semantic/fixed) | auto |
| `--threshold N` | 청킹 임계 토큰 수 | 60000 |
| `--yes` | 확인 스킵 (자동화용) | - |

## 실행 워크플로우

### Step 1: 경로 유효성 검사
PDF/MD 파일 존재 확인. `--info` 시 foreground로 정보만 출력.

### Step 2: 모드 선택 실행

**토큰 모드** (백그라운드):
```bash
python -m lib.pdf_utils chunk <path> --tokens <N> --overlap <N> -o <output.json>
```

**페이지 모드** (백그라운드):
```bash
python -m lib.pdf_utils chunk <path> --page --pages <N> [-o <dir>]
```

**PRD 모드**: `--strategy` 미지정 시 분석 결과 출력 후 AskUserQuestion으로 전략 선택 요청. 선택 후 백그라운드 실행:
```bash
python C:\claude\ebs\tools\pdf_chunker.py <path> --prd --strategy <chosen>
```

### Step 3: 결과 안내
완료 시 JSON 파일 경로 + 청크 수 + 토큰 요약 출력.

## 안전 규칙

- **120초 타임아웃**: 백그라운드에서도 안전하게
- **대용량 (100+ 페이지)**: 자동 백그라운드 전환
- **의존성**: `pymupdf` (필수), `tiktoken` (선택, 없으면 간이 추정)

## 모드 선택 가이드

| 상황 | 권장 |
|------|------|
| 순수 텍스트 분석 | (기본) |
| 이미지/표 포함 | `--page` |
| Claude Vision API | `--page --inline` |
| PRD/기획서 구조 보존 | `--prd` |

상세: `.claude/commands/chunk.md`
