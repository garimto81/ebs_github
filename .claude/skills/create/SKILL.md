---
name: create
description: >
  This skill should be used when the user requests creation of PRDs, pull requests, or documentation artifacts.
version: 1.1.0
triggers:
  keywords:
    - "/create"
    - "PRD 생성"
    - "PR 생성"
    - "문서 생성"
auto_trigger: false
---

# /create - 생성 통합 커맨드

PRD, PR, 문서를 생성한다. 4가지 target으로 라우팅.

## Usage

```
/create <target> [args]

Targets:
  prd [name] [--template] [--local-only]   PRD 문서 생성 (Google Docs 마스터)
  init [name] [--priority]                  PRD+Checklist+Task 통합 생성 (로컬 전용)
  pr [base-branch]                          Pull Request 생성
  docs [path] [--format]                    API/코드 문서 생성
```

---

## /create prd - PRD 생성

Google Docs에 PRD를 생성하고 로컬에는 읽기 전용 캐시를 저장한다.

### 워크플로우
1. **대화형 질문** (A/B/C/D 형식, 3-8개): Target Users, Core Features, Tech Stack, Metrics
2. **PRD 번호 자동 할당**: `.prd-registry.json`에서 `next_prd_number` 조회
3. **Google Docs 문서 생성**: 템플릿 기반, 공유 폴더 저장
4. **로컬 참조 파일 생성**: `.prd-registry.json` 업데이트 + `PRD-NNNN.cache.md` + `docs/checklists/PRD-NNNN.md`
5. **결과 출력**: Google Docs URL + 로컬 캐시 경로

### 옵션

| 옵션 | 설명 |
|------|------|
| `--template=TYPE` | minimal / standard(기본) / junior / deep |
| `--local-only` | 로컬 Markdown만 (Google Docs 미사용) |
| `--priority=P0-P3` | 우선순위 |
| `--visualize` | HTML 목업 + Playwright 스크린샷으로 시각화 |
| `--gdocs` | Google Docs + HTML 시각화 통합 (Drive 업로드 + inline 삽입) |

### 시각화 (`--visualize` / `--gdocs`)
- `--visualize`: 로컬 MD에 이미지 삽입 (`docs/mockups/PRD-NNNN/` + `docs/images/PRD-NNNN/`)
- `--gdocs`: Google Drive 업로드 + Docs inline 삽입 (visualize 포함)
- 내부 모듈: `lib/google_docs/converter.py`, `image_inserter.py`, `notion_style.py`

---

## /create init - PRD 통합 초기화 (로컬 전용)

서브프로젝트에서 PRD + Checklist + Task를 한 번에 생성한다.

### 워크플로우
1. PRD 번호 자동 할당 (기존 PRD 스캔 → 다음 번호)
2. 폴더 구조 생성 (`docs/checklists/`, `tasks/prds/`)
3. 템플릿 기반 파일 생성: `PRD-NNNN-{slug}.md`, `docs/checklists/PRD-NNNN.md`, `tasks/NNNN-tasks-{slug}.md`
4. `.prd-registry.json` 업데이트

```bash
/create init "YouTube 챗봇 확장"              # 기본 (P1)
/create init "실시간 번역" --priority=P0      # 우선순위 지정
```

---

## /create pr - Pull Request 생성

### 워크플로우
1. Git 상태 확인 (브랜치, 클린 워킹 디렉토리, 커밋 존재)
2. `git push -u origin <branch>`
3. `git log` 분석 → PR 설명 자동 생성 (Summary, Test Plan, Related)
4. `gh pr create --title "..." --body "..."` + 자동 라벨 + 이슈 연결

```bash
/create pr              # main 대상
/create pr develop      # 특정 base branch
/create pr --draft      # Draft PR
```

---

## /create docs - 문서 생성

코드 분석 기반으로 API/클래스/모듈 문서를 자동 생성한다.

```bash
/create docs                    # 전체 프로젝트
/create docs src/auth/          # 특정 경로
/create docs --format=html      # HTML 형식
```

생성 구조: `docs/api/`, `docs/guides/`, `docs/reference/`, `docs/index.md`

---

## Target 라우팅 판단

| 사용자 요청 | Target |
|------------|--------|
| PRD/기획서 필요 | `prd` |
| 로컬 프로젝트 초기화 | `init` |
| PR 생성/코드 리뷰 요청 | `pr` |
| API 문서/코드 문서 | `docs` |

상세: `.claude/commands/create.md`
