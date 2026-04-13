# QA-LOBBY-06 — Quasar Frontend 테스트 전략

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | Quasar(Vue 3)+TS 테스트 피라미드(Vitest unit/component + Playwright E2E + MSW mock + CI 통합) |

---

## 1. 범위와 목표

본 문서는 `team1-frontend` (Quasar Framework + Vue 3 + TypeScript) 의 **자동화 테스트 전략**을 정의한다. 과거 `QA-LOBBY-04/05` 는 Flutter/React 기준이었으므로 DEPRECATED 처리되었고, 본 문서가 Quasar 전환 후 신규 SSOT 역할을 한다.

### 1.1 품질 목표

| 지표 | 목표 | 측정 |
|------|:----:|------|
| **Unit test coverage** | statements ≥ 80%, branches ≥ 70% | Vitest `--coverage` |
| **Component test coverage** | 모든 `src/pages/*.vue` + 공용 컴포넌트 | @vue/test-utils mount |
| **E2E critical flows** | 최소 10개 핵심 시나리오 PASS | Playwright |
| **CI 실행 시간** | Unit+Component < 3분, E2E < 5분 | GitHub Actions timing |
| **Flaky rate** | < 1% | 재실행 통계 |

### 1.2 스택

| 계층 | 도구 | 버전 | 근거 |
|------|------|:----:|------|
| Unit | **Vitest** | `^2.1` | Vite 기반 Quasar 와 동일 런타임. TS 지원 우수 |
| Component | **Vitest + `@vue/test-utils`** | `^2.4` | Vue 3 공식 |
| Mocking | **MSW 2.x (node mode)** | `^2.4` | UI-A1 §6 재사용. 동일 handler |
| E2E | **Playwright** | `^1.48` | Quasar 공식 추천, multi-browser |
| Coverage | **c8** (Vitest 내장) | — | v8 coverage provider |
| CI | **GitHub Actions** | — | `ubuntu-latest` + Node 20 |

### 1.3 무엇을 테스트하지 않는가

- **Backend (Team 2)**: 별도 팀 소관. Team 1 은 API contract 만 검증 (contract test).
- **Game Engine (Team 3)**: 직접 호출하지 않음.
- **CC/Overlay (Team 4)**: Team 4 소관.
- **실제 Rive 렌더링**: `@rive-app/canvas` 내부 로직은 라이브러리 신뢰. Team 1 은 mount/cleanup + 에러 처리만 테스트.

---

## 2. 테스트 피라미드

```
          ╱╲
         ╱  ╲
        ╱ E2E╲  ← 10~15 scenarios, Playwright
       ╱──────╲     느리지만 고신뢰
      ╱        ╲
     ╱Component ╲ ← pages × 9 + common components
    ╱────────────╲    mount + user interaction
   ╱              ╲
  ╱     Unit       ╲ ← stores + api + utils + composables
 ╱──────────────────╲    함수 단위, 빠름
```

**투자 배분**: Unit 60% / Component 30% / E2E 10%.

---

## 3. Unit Tests (Vitest)

### 3.1 대상

| 모듈 | 테스트 포커스 |
|------|--------------|
| `src/stores/authStore.ts` | login, tryRestoreSession, hasPermission (Bit Flag) |
| `src/stores/lobbyStore.ts` | fetchSeries, applyRemoteChange, select mutations |
| `src/stores/settingsStore.ts` | updateField dirty, saveSection, revertSection |
| `src/stores/geStore.ts` | uploadSkin 검증 단계, activateSkin 상태 전이 |
| `src/stores/wsStore.ts` | seq 검증 (CCR-021), reconnect backoff, dispatch 라우팅 |
| `src/api/client.ts` | Idempotency-Key 주입 (CCR-019), 401 refresh, 5xx 재시도 |
| `src/api/*.ts` | 각 API 모듈의 URL/params/body 정확성 |
| `src/utils/permissions.ts` | Bit Flag 연산 (Read/Write/Delete) |
| `src/utils/date.ts` | 시간 포맷 |
| `src/utils/idempotency.ts` | UUID v4 형식 |

### 3.2 패턴 예시 — authStore 로그인 성공

```typescript
// src/stores/__tests__/authStore.test.ts
import { describe, it, expect, beforeEach } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { useAuthStore } from '../authStore';
import { server } from 'src/mocks/server';
import { http, HttpResponse } from 'msw';

describe('useAuthStore', () => {
  beforeEach(() => setActivePinia(createPinia()));

  it('login 성공 시 status=authenticated 로 전이', async () => {
    server.use(
      http.post('/api/v1/auth/login', () =>
        HttpResponse.json({
          user: { id: 'u1', email: 'admin@wsop', displayName: 'Admin' },
          accessToken: 'token-abc',
          role: 'admin',
          permissions: { Series: 7, Table: 7 },
        }),
      ),
    );

    const auth = useAuthStore();
    await auth.login('admin@wsop', 'password');

    expect(auth.status).toBe('authenticated');
    expect(auth.accessToken).toBe('token-abc');
    expect(auth.hasPermission('Series', 'Write')).toBe(true);
  });

  it('login 실패 시 에러 저장', async () => {
    server.use(
      http.post('/api/v1/auth/login', () =>
        HttpResponse.json({ error: { code: 'INVALID_CREDENTIALS', message: '...' } }, { status: 401 }),
      ),
    );

    const auth = useAuthStore();
    await expect(auth.login('wrong@wsop', 'nope')).rejects.toThrow();
    expect(auth.status).toBe('error');
  });
});
```

### 3.3 패턴 예시 — wsStore seq 검증

```typescript
// src/stores/__tests__/wsStore.test.ts
describe('useWsStore seq validation (CCR-021)', () => {
  it('단조증가 시 정상 dispatch', () => {
    const ws = useWsStore();
    ws.lastSeq = 10;
    ws.handleMessage(JSON.stringify({ seq: 11, type: 'ConfigChanged', payload: {} }));
    expect(ws.lastSeq).toBe(11);
  });

  it('gap 감지 시 replay 호출', async () => {
    const ws = useWsStore();
    ws.lastSeq = 10;
    const replaySpy = vi.spyOn(ws, 'replay');
    ws.handleMessage(JSON.stringify({ seq: 15, type: 'ConfigChanged', payload: {} }));
    expect(replaySpy).toHaveBeenCalledWith(11);
  });

  it('중복 seq 무시', () => {
    const ws = useWsStore();
    ws.lastSeq = 10;
    ws.handleMessage(JSON.stringify({ seq: 10, type: 'ConfigChanged', payload: {} }));
    expect(ws.lastSeq).toBe(10); // 변화 없음
  });
});
```

### 3.4 패턴 예시 — API client Idempotency-Key (CCR-019)

```typescript
// src/api/__tests__/client.test.ts
describe('API client Idempotency-Key (CCR-019)', () => {
  it('POST 요청에 Idempotency-Key 자동 주입', async () => {
    let capturedHeader: string | undefined;
    server.use(
      http.post('/api/v1/series', ({ request }) => {
        capturedHeader = request.headers.get('Idempotency-Key') ?? undefined;
        return HttpResponse.json({ id: 's1' });
      }),
    );

    await api.post('/series', { name: 'WSOP' });
    expect(capturedHeader).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/);
  });

  it('GET 요청에는 주입하지 않음', async () => {
    let capturedHeader: string | null = null;
    server.use(
      http.get('/api/v1/series', ({ request }) => {
        capturedHeader = request.headers.get('Idempotency-Key');
        return HttpResponse.json([]);
      }),
    );
    await api.get('/series');
    expect(capturedHeader).toBeNull();
  });
});
```

### 3.5 실행

```bash
pnpm test                    # 전체 unit + component
pnpm test:watch              # TDD 모드
pnpm test -- stores          # 특정 디렉터리
pnpm test -- --coverage      # 커버리지 리포트 → coverage/
```

---

## 4. Component Tests (Vitest + @vue/test-utils)

### 4.1 대상

| 카테고리 | 범위 |
|----------|------|
| Pages | `src/pages/**/*.vue` 전체 (Login, Series, Event, Flight, Table, Player, Settings 6탭, GE 허브) |
| 공용 컴포넌트 | `src/components/common/*` (LoadingState, ErrorBanner, EmptyState) |
| 도메인 컴포넌트 | `src/components/lobby/*`, `src/components/graphic-editor/*` |

### 4.2 Quasar 초기화

Quasar 컴포넌트 사용 시 mount 전에 plugin 설치 필요:

```typescript
// vitest.setup.ts
import { config } from '@vue/test-utils';
import { Quasar } from 'quasar';
import { createI18n } from 'vue-i18n';
import ko from 'src/i18n/ko.json';

const i18n = createI18n({ locale: 'ko', messages: { ko } });

config.global.plugins = [[Quasar, { plugins: {} }], i18n];
config.global.stubs = {
  'router-link': true,
  'router-view': true,
};
```

### 4.3 패턴 예시 — LoginPage

```typescript
// src/pages/__tests__/LoginPage.test.ts
import { mount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import LoginPage from '../LoginPage.vue';

describe('LoginPage', () => {
  it('이메일/비밀번호 입력 + Submit 클릭 시 authStore.login 호출', async () => {
    const wrapper = mount(LoginPage, {
      global: { plugins: [createTestingPinia({ stubActions: false })] },
    });

    await wrapper.find('input[type="email"]').setValue('admin@wsop');
    await wrapper.find('input[type="password"]').setValue('secret');
    await wrapper.find('form').trigger('submit.prevent');

    // store action 호출 확인
    const auth = useAuthStore();
    expect(auth.login).toHaveBeenCalledWith('admin@wsop', 'secret', undefined);
  });

  it('2FA 필요 응답 시 TOTP 화면으로 전환', async () => {
    server.use(
      http.post('/api/v1/auth/login', () =>
        HttpResponse.json({ requires2FA: true, partialToken: 'p-abc' }),
      ),
    );
    const wrapper = mount(LoginPage, { global: { plugins: [createTestingPinia({ stubActions: false })] } });
    await wrapper.find('input[type="email"]').setValue('admin@wsop');
    await wrapper.find('input[type="password"]').setValue('secret');
    await wrapper.find('form').trigger('submit.prevent');
    await flushPromises();

    expect(wrapper.findComponent({ name: 'TotpInput' }).exists()).toBe(true);
  });
});
```

### 4.4 Snapshot 사용

- **원칙**: snapshot 은 디자인 시스템 공용 컴포넌트(Button/Input/Badge 등) 에만 사용. 페이지 수준 snapshot 은 깨지기 쉬워 **금지**.
- Obsolete snapshot 제거: `pnpm test -- -u`

---

## 5. E2E Tests (Playwright)

### 5.1 대상 플로우 (최소 10개)

| # | 플로우 | 경로 | 중요도 |
|---|--------|------|:-----:|
| 1 | 로그인 성공 → Series 목록 | `/login` → `/series` | 🔴 |
| 2 | 로그인 실패 → 에러 표시 | `/login` | 🔴 |
| 3 | 2FA 활성 계정 로그인 → TOTP 입력 → 성공 | `/login` → 2FA → `/series` | 🟡 |
| 4 | Forgot Password 3단계 | `/forgot-password` | 🟡 |
| 5 | Session restore dialog — Continue | reload → dialog → 이전 테이블 | 🟡 |
| 6 | 네비게이션 3계층 | Series → Event(Day) → Table + Player 독립 | 🔴 |
| 7 | Settings 6탭 전환 + 값 저장 | `/settings/outputs` → save → ConfigChanged WS | 🔴 |
| 8 | Graphic Editor Upload → Preview → Metadata → Activate | `/lobby/graphic-editor` | 🔴 |
| 9 | Table Rebalance Saga 진행 표시 | `/flights/:id/tables` → Rebalance | 🟡 |
| 10 | RBAC — Viewer 가 Settings 접근 시 차단 | `/settings` guard | 🔴 |
| 11 (선택) | Logout | `/logout` | 🟢 |
| 12 (선택) | i18n locale 전환 | Preferences → Language | 🟢 |

### 5.2 설정

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  timeout: 30_000,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 2 : 4,
  reporter: [['html'], ['list']],
  use: {
    baseURL: 'http://localhost:9000',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  webServer: {
    command: 'pnpm dev',
    url: 'http://localhost:9000',
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    // { name: 'firefox', use: { ...devices['Desktop Firefox'] } }, // 옵션
  ],
});
```

### 5.3 패턴 예시 — 로그인 → Series

```typescript
// e2e/01-login-to-series.spec.ts
import { test, expect } from '@playwright/test';

test('로그인 성공 시 Series 목록으로 이동', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('이메일').fill('admin@wsop');
  await page.getByLabel('비밀번호').fill('secret');
  await page.getByRole('button', { name: '로그인' }).click();

  await expect(page).toHaveURL('/series');
  await expect(page.getByRole('heading', { name: '시리즈 목록' })).toBeVisible();
});
```

### 5.4 MSW in E2E

E2E 는 **실제 dev server + MSW browser mode** 사용 (`VITE_USE_MOCK=true`).  
테스트별로 다른 mock 이 필요하면 `page.route()` 로 Playwright 가 직접 가로채거나, MSW handler 를 test별 reset.

### 5.5 실행

```bash
pnpm e2e                     # headless
pnpm e2e -- --headed         # 브라우저 보이게
pnpm e2e:ui                  # Playwright UI 모드 (TDD)
pnpm e2e -- --debug          # 디버거
pnpm e2e -- 01-login         # 특정 스펙
```

---

## 6. Mock Server (MSW)

### 6.1 재사용 전략

UI-A1 §6 에서 정의한 `src/mocks/` 를 **dev + test + E2E 전부에서 재사용**한다:

| 환경 | 모드 | 진입점 |
|------|------|--------|
| Dev (`pnpm dev`) | browser worker | `src/mocks/browser.ts` |
| Unit/Component (`pnpm test`) | node server | `src/mocks/server.ts` |
| E2E (`pnpm e2e`) | browser worker (dev server 경유) | `src/mocks/browser.ts` |

### 6.2 Seed Data 일관성

`src/mocks/data.ts` 의 seed 는 DATA-02 엔티티 타입을 strict 하게 따른다:

```typescript
import type { Series, Event, Flight, Table, Player } from 'src/types/entities';

export const series: Series[] = [
  { id: 's1', name: 'WSOP Main 2026', startDate: '2026-05-20', status: 'Running' },
  // ...
];
```

테스트 간 격리를 위해 **각 test 시작 시 seed 를 deep clone** 후 handler 에 바인딩.

### 6.3 Test-specific override

```typescript
// test-specific
import { server } from 'src/mocks/server';
import { http, HttpResponse } from 'msw';

beforeEach(() => {
  server.use(
    http.get('/api/v1/series', () => HttpResponse.json([{ id: 'test-s', name: 'Test' }])),
  );
});
afterEach(() => server.resetHandlers());
```

---

## 7. CI 통합 (GitHub Actions)

### 7.1 Workflow 구조

```yaml
# .github/workflows/frontend-test.yml
name: Frontend Tests
on:
  push:
    branches: [main]
    paths: ['team1-frontend/**']
  pull_request:
    paths: ['team1-frontend/**']

jobs:
  lint-typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'pnpm'
      - run: cd team1-frontend && pnpm install --frozen-lockfile
      - run: cd team1-frontend && pnpm lint
      - run: cd team1-frontend && pnpm typecheck

  unit-component:
    runs-on: ubuntu-latest
    needs: lint-typecheck
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: 'pnpm' }
      - run: cd team1-frontend && pnpm install --frozen-lockfile
      - run: cd team1-frontend && pnpm test -- --coverage
      - uses: codecov/codecov-action@v4
        with:
          directory: team1-frontend/coverage

  e2e:
    runs-on: ubuntu-latest
    needs: lint-typecheck
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: 'pnpm' }
      - run: cd team1-frontend && pnpm install --frozen-lockfile
      - run: cd team1-frontend && pnpm exec playwright install --with-deps chromium
      - run: cd team1-frontend && pnpm e2e
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: playwright-report
          path: team1-frontend/playwright-report/
```

### 7.2 성능 목표

- Lint + typecheck: < 1분
- Unit + component: < 3분
- E2E (chromium only): < 5분
- 전체 CI: < 10분

### 7.3 실패 정책

- 모든 job PASS 해야 merge 가능 (branch protection rule)
- E2E flaky 발견 시: 즉시 skip 하지 말고 `test.fixme` 로 마킹 후 원인 분석
- Coverage 감소 시 PR 에서 경고 (blocking 아님)

---

## 8. 테스트 작성 원칙

### 8.1 네이밍

```typescript
describe('ComponentName 또는 functionName', () => {
  it('조건 → 기대 결과', () => { ... });
  // 예: it('login 성공 시 status=authenticated 로 전이')
});
```

### 8.2 AAA 패턴

```typescript
it('...', async () => {
  // Arrange — mock, 초기 state
  server.use(...);
  const store = useStore();

  // Act — 실행
  await store.doSomething();

  // Assert — 검증
  expect(store.result).toBe(...);
});
```

### 8.3 금지 사항

- **구현 세부사항 테스트 금지** — public API (actions, getters, props/events) 만 테스트. `store.$state.privateField` 같은 내부 접근 지양.
- **실제 네트워크 호출 금지** — 모든 HTTP/WS 는 MSW 로 가로챔.
- **`setTimeout` 으로 대기 금지** — `flushPromises`, `waitFor`, `await ... .wait()` 사용.
- **snapshot 남발 금지** — 의미 있는 단위에만.

---

## 9. 관련 문서

| 문서 | 역할 |
|------|------|
| `UI-A1-architecture.md` §6 | Mock server 설계 원본 |
| `UI-00-design-system.md` §9 | Quasar q-* 매핑 (컴포넌트 테스트 셀렉터 근거) |
| `UI-01-lobby.md` §0 | Login/2FA/Forgot/Session restore (E2E 시나리오 2-5) |
| `UI-04-graphic-editor.md` | GE 허브 (E2E 시나리오 8) |
| `UI-03-settings.md` | Settings 6탭 (E2E 시나리오 7) |
| `QA-LOBBY-02-checklist.md` (DEPRECATED) | 참조용 — React 기준 체크리스트 |
| `QA-LOBBY-05-frontend-todo.md` (DEPRECATED) | 참조용 — React 기준 TODO |
| `contracts/api/API-01` 외 | Contract test 의 근거 |

---

## 10. 향후 확장 (Phase 2)

이번 Phase 에서 다루지 않고 후속 세션에 남기는 항목:

- **Visual regression testing** (Percy, Chromatic) — 디자인 시스템 안정화 후
- **Performance regression** (`lighthouse-ci` 상세 설정) — 프로덕션 배포 파이프라인 수립 후
- **Accessibility automation** (`axe-playwright`) — UI-00 §10 접근성 체크리스트 자동화
- **Contract testing** (Pact) — Team 2 backend 가 실제 구현된 후 실제 BO 서버와 cross-team
- **Load testing** — 백엔드 부하는 Team 2 소관, Team 1 은 bundle size + runtime profiling 만
