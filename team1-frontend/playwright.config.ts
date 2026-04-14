// playwright.config.ts — E2E test configuration
// Reference: QA-LOBBY-06-quasar-test-strategy.md §5

import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  timeout: 30_000,
  expect: { timeout: 5_000 },
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 2 : 4,
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  reporter: [['html'], ['list']],

  use: {
    baseURL: 'http://localhost:9000',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    actionTimeout: 10_000,
  },

  webServer: {
    command: 'pnpm dev',
    url: 'http://localhost:9000',
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
    env: {
      VITE_USE_MOCK: 'true',
    },
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    // Uncomment for multi-browser testing
    // { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    // { name: 'webkit', use: { ...devices['Desktop Safari'] } },
  ],
});
