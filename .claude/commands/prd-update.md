---
name: prd-update
description: 로컬 PRD 업데이트 (브랜치 기반 자동 탐지)
---

# /prd-update — 로컬 PRD 업데이트 커맨드

로컬 PRD 파일을 업데이트하는 전담 커맨드. Google Docs 동기화(`/prd-sync`)와 역할이 다름.

## 사용법

```
/prd-update              # 현재 브랜치 기반 PRD 자동 탐지 + 업데이트
/prd-update "feature"    # 특정 feature PRD 업데이트
/prd-update --new        # PRD 없을 때 신규 생성
/prd-update --diff       # 구현 내용 vs 현재 PRD 차이 분석
/prd-update --list       # docs/00-prd/ 내 모든 PRD 목록 표시
```

## 실행 워크플로우

### 기본 실행 (`/prd-update`)

```
Step 1: 브랜치/커밋 분석
  - 현재 브랜치명 추출 (git rev-parse --abbrev-ref HEAD)
  - 최근 10개 커밋에서 feat/fix 커밋 식별
  - 구현된 내용 파악

Step 2: PRD 탐색
  - docs/00-prd/ 에서 브랜치명 패턴 매칭
  - feat/xxx-yyy → prd-xxx-yyy.prd.md 또는 xxx-yyy.prd.md 검색
  - 키워드 매칭으로 관련 PRD 탐색

Step 3: PRD 업데이트
  - PRD 있음 → ## Changelog 섹션에 변경사항 추가
  - PRD 없음 → 경고 출력 후 --new 플래그 사용 안내

Step 4: 커밋
  - 변경사항 있으면: docs(prd): {feature} 요구사항 반영
```

### `--new` 플래그 (신규 PRD 생성)

```
Step 1: 기능명 확정
  - 브랜치명 기반 자동 추출 또는 인수로 전달된 feature명 사용

Step 2: PRD 스켈레톤 생성
  - docs/00-prd/prd-{feature}.prd.md 생성
  - 최소 PRD 구조로 초기화 (개요, 요구사항, Changelog)

Step 3: 커밋
  - docs(prd): {feature} PRD 최초 작성
```

### `--diff` 플래그 (갭 분석)

```
Step 1: 구현 현황 파악
  - git log --oneline -20 에서 feat/fix 커밋 목록 추출
  - 구현된 기능 목록 생성

Step 2: PRD 현황 파악
  - docs/00-prd/ 에서 관련 PRD 로드
  - ## 구현 상태 섹션 파싱

Step 3: 갭 분석 출력
  - 구현됐지만 PRD에 없는 항목 → "미문서화 구현"
  - PRD에 있지만 구현 안 된 항목 → "미구현 요구사항"
  - 일치하는 항목 → "동기화됨"
```

## PRD Changelog 업데이트 형식

업데이트 시 `## Changelog` 섹션에 아래 형식으로 추가:

```markdown
| {오늘날짜} | v{N+1} | {변경 내용 1줄 요약} | {결정 근거} |
```

예시:
```markdown
| 2026-02-24 | v1.2 | check_prd_sync_status() 감지 로직 추가 | session_init.py PRD 드리프트 자동 감지 |
```

## PRD 파일 최소 구조 (--new 생성 시)

```markdown
# {기능명} PRD

**작성일**: {오늘날짜}
**브랜치**: {현재 브랜치}

## 개요

- **목적**:
- **배경**:
- **범위**:

## 요구사항

### 기능 요구사항

1.

### 비기능 요구사항

1.

## 구현 상태

| 항목 | 상태 | 비고 |
|------|------|------|
| | 예정 | |

## Changelog

| 날짜 | 버전 | 변경 내용 | 결정 근거 |
|------|------|-----------|----------|
| {오늘날짜} | v1.0 | 최초 작성 | - |
```

## 역할 구분

| 커맨드 | 역할 |
|--------|------|
| `/prd-update` | **로컬** PRD 파일 생성/수정 (이 커맨드) |
| `/prd-sync` | Google Docs → 로컬 동기화 (별도 커맨드) |

## 실행 에이전트

- **explore**: docs/00-prd/ 탐색, git log 분석
- **executor**: PRD 파일 Write/Edit
- **writer**: Changelog 항목 작성

## 관련 규칙

- `.claude/rules/13-requirements-prd.md` — PRD-First 강제 규칙
- `.claude/rules/12-large-document-protocol.md` — 대형 문서 프로토콜
