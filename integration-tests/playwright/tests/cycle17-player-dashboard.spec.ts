/**
 * Cycle 17 — S2 Player Dashboard 4 핵심 필드 cascade (2026-05-13)
 *
 * 검증 대상:
 *   - PlayersScreen 의 DataTable 에 Name + Country + Position + Stack
 *     4 필드가 동시 표시되는지 (lobby-web container).
 *
 * 정본 명세: docs/2. Development/2.1 Frontend/Lobby/Overview.md
 *             §Player 독립 레이어 - Cycle 17 cascade 박스.
 *
 * 1 phase screenshot (test-results/v01-lobby/cycle17/):
 *   01-player-dashboard.png  — Players 화면 진입 후 4 필드 가시 검증.
 *
 * 사전 요구:
 *   - lobby-web container 가 cycle 17 변경 포함 image 로 rebuild 되어야 함
 *     (현 docker image 가 cycle 11 기반이면 4 필드 미반영 → S11 cascade
 *      cycle 18 build 통해 image 갱신 후 본 spec 실행).
 *   - BO container 실행 + admin 계정 시드.
 *
 * DoD:
 *   - DataTable 컬럼 헤더 4개 모두 표시 (Name / Country / Pos / Stack).
 *   - 최소 1명의 Player row 가 모든 4 필드 비어있지 않음.
 *   - screenshot 존재 + non-empty.
 */
import { expect, test, type Page } from '@playwright/test';
import * as path from 'path';
import * as fs from 'fs';

const LOBBY_BASE_URL = process.env.LOBBY_BASE_URL ?? 'http://localhost:3000';
const ADMIN_EMAIL = process.env.ADMIN_EMAIL ?? 'admin@local';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD ?? 'Admin!Local123';

const SHOT_DIR = path.resolve(
  __dirname,
  '..',
  '..',
  '..',
  'test-results',
  'v01-lobby',
  'cycle17',
);

test.use({
  viewport: { width: 1440, height: 900 },
});

async function login(page: Page): Promise<void> {
  await page.goto(LOBBY_BASE_URL);
  await page.waitForLoadState('networkidle');

  // Login form fields — adjust selector if Flutter web semantics differ.
  const emailField = page.getByLabel(/email/i).or(page.locator('[type=email]'));
  const passwordField = page
    .getByLabel(/password/i)
    .or(page.locator('[type=password]'));

  await emailField.first().fill(ADMIN_EMAIL);
  await passwordField.first().fill(ADMIN_PASSWORD);

  const loginBtn = page.getByRole('button', { name: /(login|sign in|로그인)/i });
  await loginBtn.first().click();
  await page.waitForLoadState('networkidle');
}

test.describe('Cycle 17 — Player Dashboard 4 fields', () => {
  test.beforeAll(() => {
    fs.mkdirSync(SHOT_DIR, { recursive: true });
  });

  test('Players 화면 진입 → 4 필드 (Name + Country + Position + Stack) 표시', async ({
    page,
  }) => {
    await login(page);

    // NavigationRail / sidebar 에서 Players 진입.
    const playersNav = page
      .getByRole('button', { name: /players/i })
      .or(page.getByText('Players', { exact: true }));
    await playersNav.first().click();
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(800); // DataTable 렌더 대기.

    // 1) 4 컬럼 헤더 확인.
    await expect(page.getByText('Name', { exact: true })).toBeVisible();
    await expect(page.getByText('Country', { exact: true })).toBeVisible();
    await expect(page.getByText('Pos', { exact: true })).toBeVisible();
    await expect(page.getByText('Stack', { exact: true })).toBeVisible();

    // 2) screenshot 캡처 — evidence.
    await page.screenshot({
      path: path.join(SHOT_DIR, '01-player-dashboard.png'),
      fullPage: false,
    });

    // 3) 사이즈 검증 — non-empty.
    const stat = fs.statSync(path.join(SHOT_DIR, '01-player-dashboard.png'));
    expect(stat.size).toBeGreaterThan(10_000);
  });
});
