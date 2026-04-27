---
title: B-Q16 — 개발 환경 표준화 (Session 1 — SG-027 cascade)
owner: conductor
tier: internal
status: PENDING
type: backlog
linked-sg: SG-027
linked-decision: Session 1 task — 개발 환경 표준화
last-updated: 2026-04-27
---

## 개요

Session 1 (Foundation & Infrastructure) 의 명시 task "개발 환경 표준화". 본 turn 에는 추상적 → 구체화 후 별도 turn 진행.

## 표준화 대상

### Python (team2-backend)
- 버전: Python 3.12 (현재 베이스)
- 의존성 관리: pyproject.toml (PEP 621)
- lint: ruff (현재 적용됨)
- formatter: ruff format
- type checker: mypy 또는 pyright (현재 미명시)
- test: pytest (현재 261 passed)
- coverage: pytest-cov (현재 90%, 목표 95% — B-Q10)

### Dart / Flutter (team1-frontend, team3-engine, team4-cc)
- Flutter version: ? (현재 자세히 미명시 — pubspec.yaml read 필요)
- Dart version: ?
- lint: analysis_options.yaml (현재 존재)
- formatter: dart format
- test: flutter test / dart test
- coverage: 미명시 (B-Q10 cascade)

### TypeScript / Node (있다면)
- Node version: ?
- package manager: npm / pnpm / yarn?
- lint: ESLint
- formatter: Prettier
- test: jest / vitest

### 인프라
- Docker: 24+ (현재 베이스)
- docker-compose: v2 (compose plugin)
- git: 2.40+

## 처리 작업

1. 각 팀의 build manifest read 후 정확한 버전 명시
2. `docs/2. Development/2.{N}/Engineering.md` 또는 신규 `docs/4. Operations/Development_Standards.md`
3. CI 워크플로우 (`.github/workflows/`) 통일
4. `.editorconfig` 통일 (현재 존재 여부 미확인)
5. pre-commit hook 통일 (lint/format/typecheck)

## 우선순위

P2 — Production 인텐트 (B-Q7 ㉠) 와 결합. Phase 0 (~ 2026-12) 중반 권장.

## 참조

- B-Q10 95% coverage roadmap
- B-Q11 OWASP audit
- 각 팀 Engineering.md
- team2-backend baseline: 261 passed, 90% coverage, ruff
