// e2e/01-login-to-series.spec.ts — Critical flow 1
// Reference: QA-LOBBY-06-quasar-test-strategy.md §5.1

import { test, expect } from '@playwright/test';

test.describe('Login → Series flow', () => {
  test('로그인 성공 시 Series 목록으로 이동', async ({ page }) => {
    await page.goto('/login');
    await expect(page).toHaveURL(/\/login/);

    // Fill credentials (MSW mock accepts admin@wsop / secret)
    await page.getByLabel(/이메일|Email/i).fill('admin@wsop');
    await page.getByLabel(/비밀번호|Password/i).fill('secret');
    await page.getByRole('button', { name: /로그인|Login/i }).click();

    // Should redirect to /series
    await expect(page).toHaveURL(/\/series/);
  });

  test('잘못된 비밀번호 시 에러 표시', async ({ page }) => {
    await page.goto('/login');
    await page.getByLabel(/이메일|Email/i).fill('admin@wsop');
    await page.getByLabel(/비밀번호|Password/i).fill('wrong');
    await page.getByRole('button', { name: /로그인|Login/i }).click();

    // Should remain on /login with error banner
    await expect(page).toHaveURL(/\/login/);
    await expect(page.locator('.q-banner').or(page.locator('[role="alert"]'))).toBeVisible();
  });
});
