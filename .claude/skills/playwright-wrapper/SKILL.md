---
name: playwright-wrapper
description: >
  This skill should be used when the user needs Playwright browser automation via CLI or Python SDK for E2E testing, screenshots, Docker-based testing, or web automation.
version: 1.0.0

triggers:
  keywords:
    - "playwright"
    - "브라우저 테스트"
    - "E2E 테스트"
    - "스크린샷"
    - "웹 자동화"
    - "webapp test"
    - "E2E docker"
  file_patterns:
    - "**/*.spec.ts"
    - "**/e2e/**"
    - "playwright.config.ts"
  context:
    - "E2E 테스트 실행"
    - "브라우저 자동화"
    - "웹앱 E2E 테스트"
    - "Docker 환경 테스트"

auto_trigger: false
---

# Playwright Wrapper

Playwright CLI 및 Python SDK를 사용한 브라우저 자동화 + Docker 환경 E2E 테스트.

## 명령어

### E2E 테스트 실행

```bash
# 전체 테스트
npx playwright test

# 특정 파일
npx playwright test tests/e2e/auth.spec.ts

# UI 모드
npx playwright test --ui

# 헤드리스 모드 (기본)
npx playwright test --headed
```

### 스크린샷 촬영

```bash
# 단일 페이지 스크린샷
npx playwright screenshot https://example.com screenshot.png

# 전체 페이지
npx playwright screenshot --full-page https://example.com full.png
```

### 코드 생성 (녹화)

```bash
npx playwright codegen https://example.com
```

### PDF 생성

```bash
npx playwright pdf https://example.com page.pdf
```

## 테스트 작성 예시

```typescript
import { test, expect } from '@playwright/test';

test('로그인 테스트', async ({ page }) => {
  await page.goto('https://example.com/login');
  await page.fill('#email', 'test@example.com');
  await page.fill('#password', 'password');
  await page.click('button[type="submit"]');
  await expect(page).toHaveURL('/dashboard');
});
```

## 설정 파일

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  timeout: 60000,
  expect: { timeout: 10000 },
  use: {
    headless: true,
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    trace: 'retain-on-failure',
    actionTimeout: 15000,
    navigationTimeout: 30000,
  },
  workers: 2,
  retries: 1,
  reporter: [['html', { open: 'never' }], ['list']],
});
```

## Docker 환경 테스트

Docker Compose로 서버를 관리하는 환경에서의 E2E 테스트 흐름:

```
1. Docker 서버 확인
   docker ps | grep -E "frontend|backend"
       ↓
2. 서버 미실행 시 시작
   docker-compose up -d
       ↓
3. 헬스체크 대기
   curl -s http://localhost:3000/health || sleep 5
       ↓
4. Playwright 테스트 (타임아웃 설정)
   npx playwright test --timeout=60000
       ↓
5. 브라우저 종료 확인
   tasklist | findstr "chromium"
```

서버 라이프사이클 관리: `scripts/with_server.py`

## 브라우저 종료 보장 (Python SDK)

### safe_browser 컨텍스트 매니저

```python
from playwright.sync_api import sync_playwright
from contextlib import contextmanager

@contextmanager
def safe_browser(headless=True):
    """브라우저 자동 종료 보장"""
    p = sync_playwright().start()
    browser = p.chromium.launch(headless=headless)
    try:
        yield browser
    finally:
        browser.close()
        p.stop()

# 사용
with safe_browser() as browser:
    page = browser.new_page()
    page.goto('http://localhost:3000')
    # 자동 종료됨
```

### try-finally 패턴

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = None
    try:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.set_default_timeout(30000)
        page.goto('http://localhost:3000')
        page.wait_for_load_state('networkidle')
    finally:
        if browser:
            browser.close()
```

## Anti-Patterns

| 금지 | 이유 | 대안 |
|------|------|------|
| `browser.close()` 누락 | 좀비 프로세스 | try-finally 필수 |
| 무한 타임아웃 | 테스트 행 | 명시적 타임아웃 설정 |
| `sleep()` 남용 | 불안정, 느림 | `wait_for_selector()` |
| headless=False (CI) | 리소스 낭비 | headless=True |

## 트러블슈팅

### 브라우저 미종료

```bash
tasklist | findstr "chromium"
npx playwright install --force
```

### Docker 서버 연결 실패

```bash
docker ps -a
docker logs frontend -f
curl http://localhost:3000
```

## 관련 커맨드

| 커맨드 | 용도 |
|--------|------|
| `/check --e2e` | E2E 포함 전체 검사 |
| `/tdd` | TDD 워크플로우 |
