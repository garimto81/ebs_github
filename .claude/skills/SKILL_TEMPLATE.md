# Skill Template (2025 Schema)

Skills 2025 스키마 템플릿입니다. 새 스킬 생성 또는 기존 스킬 업그레이드 시 사용합니다.

---

## YAML Frontmatter 스키마

```yaml
---
name: skill-name
description: >
  스킬에 대한 설명. 한 줄 또는 멀티라인.
version: 2.0.0

# 2025 신규 필드: 자동 트리거 조건
triggers:
  keywords:
    - "키워드1"
    - "키워드2"
  file_patterns:
    - "tests/**/*.py"
    - "**/*.spec.ts"
  context:
    - "컨텍스트 설명1"
    - "컨텍스트 설명2"

# 2025 신규 필드: 스킬 기능 선언
capabilities:
  - capability_1
  - capability_2
  - capability_3

# 2025 신규 필드: 모델 선호도
model_preference: sonnet  # sonnet | opus | haiku

# 기존 필드 (유지)
phase: [1, 2]
auto_trigger: true
dependencies:
  - other-skill-name
token_budget: 1200
---
```

---

## 필드 설명

### 기존 필드

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `name` | string | ✅ | 스킬 고유 이름 (kebab-case) |
| `description` | string | ✅ | 스킬 설명 |
| `version` | string | ✅ | 시맨틱 버전 (x.y.z) |
| `phase` | array | ❌ | 적용 Phase [1, 2, 3] |
| `auto_trigger` | boolean | ❌ | 자동 트리거 여부 (default: false) |
| `dependencies` | array | ❌ | 의존 스킬 목록 |
| `token_budget` | number | ❌ | 토큰 예산 (default: 1000) |

### 2025 신규 필드

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `triggers.keywords` | array | ❌ | 트리거 키워드 목록 |
| `triggers.file_patterns` | array | ❌ | 트리거 파일 패턴 (glob) |
| `triggers.context` | array | ❌ | 트리거 컨텍스트 설명 |
| `capabilities` | array | ❌ | 스킬이 제공하는 기능 목록 |
| `model_preference` | string | ❌ | 선호 모델 (sonnet/opus/haiku) |

---

## 예시: tdd-workflow

```yaml
---
name: tdd-workflow
description: >
  Anthropic Best Practices 기반 TDD 워크플로우. Red-Green-Refactor 강제.
version: 2.0.0

triggers:
  keywords:
    - "TDD"
    - "테스트 먼저"
    - "Red-Green"
    - "테스트 주도"
  file_patterns:
    - "tests/**/*.py"
    - "**/*.spec.ts"
    - "**/*.test.ts"
  context:
    - "테스트 작성 요청"
    - "TDD 사이클 진행"
    - "Red Phase 시작"

capabilities:
  - validate_red_phase
  - run_tdd_cycle
  - generate_test_template

model_preference: sonnet

phase: [1, 2]
auto_trigger: true
dependencies:
  - debugger
token_budget: 1200
---
```

---

## 마이그레이션 가이드

### 기존 스킬 → 2025 스키마

1. `version` 1.x.x → 2.0.0 업데이트
2. `triggers` 섹션 추가
   - 기존 description의 트리거 키워드 추출
   - 관련 파일 패턴 추가
3. `capabilities` 섹션 추가
   - 스킬이 수행하는 주요 기능 나열
4. `model_preference` 추가 (선택)
5. 기존 필드 유지 (호환성)

### 호환성

- 기존 필드는 모두 유지됨
- 새 필드는 선택적 (optional)
- 기존 스킬은 업그레이드 없이도 동작함

---

## 버전 이력

| 버전 | 날짜 | 변경 |
|------|------|------|
| 1.0.0 | 2025-12-16 | 2025 스키마 템플릿 생성 (PRD-0033 Phase 2) |
