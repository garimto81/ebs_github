---
name: check
description: >
  This skill should be used when the user requests code quality checks, security audits, lint, type checks, or QA cycles.
version: 2.0.0
triggers:
  keywords:
    - "/check"
    - "코드 검사"
    - "품질 검사"
    - "QA 실행"
    - "린트"
    - "코드 체크"
    - "보안 스캔"
    - "ruff"
    - "mypy"
    - "eslint"
    - "React 검사"
    - "React 성능"
  file_patterns:
    - "src/**/*.py"
    - "src/**/*.ts"
    - "**/*.tsx"
    - "**/*.jsx"
  context:
    - "코드 품질 개선"
    - "린트 오류 수정"
    - "React 성능 최적화"

auto_trigger: false
---

# /check - 코드 품질 검사

## Quick Start

```bash
# 전체 품질 검사
python .claude/skills/check/scripts/run_quality_check.py

# Python만 검사
python .claude/skills/check/scripts/run_quality_check.py --python-only

# 자동 수정 적용
python .claude/skills/check/scripts/run_quality_check.py --fix

# React 성능 검사
/check --react
```

## 서브커맨드

| 서브커맨드 | 설명 |
|-----------|------|
| `--fix` | 자동 수정 가능한 이슈 수정 |
| `--e2e` | E2E 테스트 실행 |
| `--perf` | 성능 검사 |
| `--security` | 보안 스캔 (Level 3) |
| `--all` | 전체 검사 (Level 1-3 + React) |
| `--react` | React 성능 규칙 검사 |
| `--level <1\|2\|3>` | 검사 수준 지정 |

## QA 사이클

1. 테스트 실행
2. 실패 시 수정
3. 통과까지 반복

## 검사 수준

### Level 1: 기본 (CI 필수)

```bash
# Python
ruff check src/
black --check src/

# TypeScript
npx eslint src/
npx prettier --check src/
```

### Level 2: 타입 검사 (권장)

```bash
# Python
mypy src/ --strict

# TypeScript
npx tsc --noEmit --strict
```

### Level 3: 보안 (배포 전 필수)

```bash
# Python
pip-audit --strict
bandit -r src/

# TypeScript
npm audit --audit-level=high
```

## 검사 항목

### Python

| 도구 | 용도 | 명령어 |
|------|------|--------|
| **ruff** | 린트 + 포맷 | `ruff check src/` |
| **black** | 포맷팅 | `black --check src/` |
| **mypy** | 타입 체크 | `mypy src/` |
| **pip-audit** | 보안 취약점 | `pip-audit` |

### TypeScript/JavaScript

| 도구 | 용도 | 명령어 |
|------|------|--------|
| **eslint** | 린트 | `npx eslint src/` |
| **prettier** | 포맷팅 | `npx prettier --check src/` |
| **tsc** | 타입 체크 | `npx tsc --noEmit` |
| **npm audit** | 보안 취약점 | `npm audit` |

## 자동 수정

### 안전한 자동 수정

```bash
# Python
black src/
ruff check src/ --fix

# TypeScript
npx prettier --write src/
npx eslint src/ --fix
```

### 수동 확인 필요

| 이슈 | 이유 |
|------|------|
| 타입 오류 | 로직 변경 가능성 |
| 보안 취약점 | 의존성 호환성 |
| 복잡한 린트 규칙 | 의도적일 수 있음 |

## React 성능 검사

### 사용법

```bash
# React 성능 규칙 검사
/check --react

# 특정 디렉토리만
/check --react src/components/

# 품질 + React 검사 조합
python .claude/skills/check/scripts/run_quality_check.py --react
```

### 검사 항목

| 우선순위 | 카테고리 | 검사 내용 |
|:--------:|----------|----------|
| CRITICAL | Waterfall | sequential await 감지 |
| CRITICAL | Bundle | barrel file import 감지 |
| HIGH | Server | RSC 직렬화 최적화 |
| MEDIUM | Re-render | stale closure, 불필요한 렌더링 |

`vercel-react-best-practices` 스킬의 47개 규칙을 기반으로 검사합니다.

## 관련 도구

| 도구 | 용도 |
|------|------|
| `scripts/run_quality_check.py` | 통합 검사 스크립트 |
| `code-reviewer` 에이전트 | 코드 리뷰 |
| `security-reviewer` 에이전트 | 보안 검사 |
| `vercel-react-best-practices` | React 47개 규칙 |
