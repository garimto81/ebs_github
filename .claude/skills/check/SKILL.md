---
name: check
description: 코드 품질 및 보안 검사
version: 3.0.0
team_pattern: true
agents:
  - qa-tester
  - architect
triggers:
  keywords:
    - "check"
    - "/check"
    - "검사"
---

# /check - 코드 품질 검사

## Agent Teams 실행

이 스킬은 Agent Teams 패턴으로 QA 사이클을 실행합니다.

### 실행 방법

```
# Step 1: 팀 생성
TeamCreate(team_name="check-{scope}")

# Step 2: QA 에이전트 스폰
Agent(
  subagent_type="qa-tester",
  name="qa-checker",
  description="코드 품질 및 보안 검사 실행",
  team_name="check-{scope}",
  model="sonnet",
  prompt="코드 품질 검사를 실행하세요.

  검사 항목:
  1. ruff check src/ --fix (린트)
  2. pytest tests/ -v (테스트)
  3. 보안 취약점 스캔

  실패 시 자동 수정 후 재실행 (최대 3회)."
)

# Step 3: 완료 후 정리
SendMessage(to="qa-checker", message={type: "shutdown_request"})
TeamDelete()
```

### QA 사이클
1. 테스트 실행
2. 실패 시 수정
3. 통과까지 반복

## 서브커맨드

### --e2e

설계 문서 + 코드 분석 → QA 정의 → spec 자동 생성 → Playwright CLI 실행.

```
# Step 1: 팀 생성
TeamCreate(team_name="check-e2e")

# Step 2: QA 에이전트 스폰
Agent(
  subagent_type="qa-tester",
  name="e2e-checker",
  description="E2E QA 정의 및 Playwright 실행",
  team_name="check-e2e",
  model="sonnet",
  prompt="[E2E QA 검증]

  대상 프로젝트: {현재 작업 디렉토리}

  Phase 1: QA 정의
  1. docs/00-prd/, contracts/specs/, docs/design/ 에서 기능 목록 추출
  2. src/, app/ 에서 data-testid/id/role 선택자 grep
  3. router/ 에서 URL 경로 목록 추출
  4. [TC-NNN] 형식 QA 정의서 터미널 출력

  Phase 2: Playwright CLI 실행
  5. node --version 확인 (18+ 필요)
  6. cmd /c npx playwright --version 확인 (실패 시 node_modules/.bin/playwright fallback)
  7. playwright.config.ts의 webServer.url로 앱 실행 여부 확인
  8. tests/e2e/auto-qa.spec.ts 생성/업데이트
  9. cmd /c npx playwright test tests/e2e/auto-qa.spec.ts --reporter=list
  10. 실패 시 최대 3회 재시도 (선택자 수정 → 재실행)"
)

# Step 3: 완료 후 정리
SendMessage(to="e2e-checker", message={type: "shutdown_request"})
TeamDelete()
```

### --fix, --perf, --security, --all

기본 QA 사이클 (lint + test) 또는 조합 실행. qa-tester 프롬프트에 해당 옵션 명시.

## 직접 실행 (옵션)

```bash
# 린트
ruff check src/ --fix

# 단위 테스트
pytest tests/test_specific.py -v

# E2E (Windows)
cmd /c npx playwright test tests/e2e/auto-qa.spec.ts --reporter=list
```
