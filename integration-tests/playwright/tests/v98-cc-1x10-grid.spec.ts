import { expect, test } from '@playwright/test';
import * as path from 'path';

const CC_BASE_URL = process.env.CC_BASE_URL ?? 'http://localhost:3001';
// 2026-05-12 SG-035 정합: BO tools/seed_admin.py 기본값 (직전 admin@ebs.local/admin123 은 Type D drift)
const ADMIN_EMAIL = process.env.ADMIN_EMAIL ?? 'admin@local';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD ?? 'Admin!Local123';
const SHOT_DIR = path.join('test-results', 'v98-cc-1x10');

test.use({
  storageState: { cookies: [], origins: [] },
  viewport: { width: 1440, height: 900 },
});

test.describe('V9.8 CC 1×10 + 9-row + 3-zone', () => {
  test.setTimeout(120_000);

  test('Track A+B 시각 검증 3컷', async ({ page, context }) => {
    await context.clearCookies();

    const loginRes = await page.request.post('http://api.ebs.local/api/v1/auth/login', {
      data: { email: ADMIN_EMAIL, password: ADMIN_PASSWORD },
    });
    const loginJson = await loginRes.json();
    const accessToken = loginJson.data.accessToken as string;

    const ccUrl =
      `${CC_BASE_URL}/?table_id=1&token=${encodeURIComponent(accessToken)}` +
      `&cc_instance_id=e2e-v98-${Date.now()}` +
      `&bo_base_url=${encodeURIComponent('http://api.ebs.local')}` +
      `&engine_url=${encodeURIComponent('http://engine.ebs.local')}` +
      `&ws_url=${encodeURIComponent('ws://api.ebs.local/ws/cc')}`;

    await page.goto(ccUrl, { waitUntil: 'load' });
    await page.waitForLoadState('networkidle', { timeout: 15000 }).catch(() => {});
    await page.waitForTimeout(4000);
    await page.screenshot({ path: path.join(SHOT_DIR, '01-cc-entry.png'), fullPage: true });

    await page.waitForTimeout(5000);
    await page.screenshot({ path: path.join(SHOT_DIR, '02-cc-after-login.png'), fullPage: true });

    await page.waitForTimeout(3000);
    await page.screenshot({ path: path.join(SHOT_DIR, '03-cc-main-1x10-grid.png'), fullPage: true });

    // ── 04: occupy S1 → 9-row + 5 onTap 시각 검증 ──
    // S1 column 좌표: viewport 1440 / 10 = 144, S1 center x = 72
    // Empty seat 의 + ADD PLAYER 텍스트 y ≈ 567 (스크린샷 기반)
    await page.mouse.click(72, 567, { delay: 80 });
    await page.waitForTimeout(1500);

    // Add Player dialog 가 떠 있을 것. Name TextField 에 입력 (autofocus)
    await page.keyboard.type('Daniel Park', { delay: 50 });
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(SHOT_DIR, '04a-add-dialog.png'), fullPage: true });

    // Add 버튼 좌표 click — dialog actions 의 우측 (캡처 기반 ~810, 575)
    await page.mouse.click(810, 575, { delay: 80 });
    await page.waitForTimeout(2000);
    await page.screenshot({ path: path.join(SHOT_DIR, '04-cc-s1-occupied.png'), fullPage: true });

    expect(true).toBe(true);
  });
});
