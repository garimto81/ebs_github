import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 30_000,
  expect: { timeout: 5_000 },
  fullyParallel: false,
  retries: 0,
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL: process.env.BACKEND_HTTP_URL ?? 'http://localhost:8000',
    extraHTTPHeaders: { 'Content-Type': 'application/json' },
    trace: 'retain-on-failure'
  },
  projects: [
    {
      name: 'api-rbac',
      testMatch: /s11\.api\.spec\.ts/
    },
    {
      name: 'ws-realtime',
      testMatch: /s11\.ws\.spec\.ts/
    }
  ]
});
