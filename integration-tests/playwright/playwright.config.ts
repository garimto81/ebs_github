import { defineConfig, devices } from '@playwright/test';

/**
 * V9.5 P14 — Playwright E2E scaffold
 *
 * 검증 대상: lobby-web (team1) + BO (team2) browser-level integration
 * 실행 사전 요구:
 *   - BO container 실행 중 (http://localhost:8000)
 *   - lobby-web container 실행 중 (http://localhost:3000)
 *   - 환경 변수 ADMIN_USERNAME, ADMIN_PASSWORD (또는 기본 test 계정)
 */
export default defineConfig({
  testDir: './tests',
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: [['list'], ['html', { open: 'never' }]],

  timeout: 30_000,
  expect: { timeout: 5_000 },

  use: {
    baseURL: process.env.LOBBY_BASE_URL ?? 'http://localhost:3000',
    extraHTTPHeaders: {
      Accept: 'application/json',
    },
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
