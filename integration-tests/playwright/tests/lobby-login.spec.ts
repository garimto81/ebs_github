/**
 * Cycle 9 — Lobby Login E2E (UI-level, screenshot evidence)
 *
 * S9 Cycle 9 신규 테스트 (2026-05-12).
 *
 * 사용자 비판 수용 ("e2e screenshot 검증 안 했다"):
 *   직전 cycle 들의 v95-ui-login / v02 / v03 spec 은 screenshot 캡처 했으나
 *   evidence 폴더 일관성 부족. 본 spec 은 lan-2026-05-12 evidence 폴더로
 *   통합하여 LAN 환경 실 검증 단일 SSOT 형성.
 *
 * 검증 대상:
 *   1) Lobby UI (http://localhost:3000) 진입
 *   2) Email/password 입력 (admin@local / Admin!Local123)
 *   3) Log In 버튼 클릭
 *   4) Dashboard 화면 전환 (URL 변경 또는 token 저장)
 *
 * 의존성:
 *   - S2 (Lobby) cycle 9 fix PR 머지 후 실행
 *   - S7 (BO) admin@local / Admin!Local123 seed (SG-035)
 *   - S11 (DevOps) Docker stack 가용 (lobby-web:3000, BO:18001)
 *
 * Screenshot evidence (test-results/lan-2026-05-12/lobby-login/):
 *   - 01-lobby-entry.png       (초기 진입)
 *   - 02-login-page.png        (login form 노출)
 *   - 03-credentials-filled.png (email/password 입력 후)
 *   - 04-after-login.png       (인증 후 dashboard)
 *   - 05-dashboard-state.png   (full state — token + URL evidence)
 *   - 06-final-viewport.png    (network 호출 추적 viewport)
 *
 * broker MCP publish: pipeline:qa-pass (이 spec 단독 PASS 시).
 */
import { expect, test, type Page } from '@playwright/test';
import * as path from 'path';

const LOBBY_BASE_URL = process.env.LOBBY_BASE_URL ?? 'http://localhost:3000';
// 2026-05-12 SG-035 정합: BO tools/seed_admin.py 기본값
const ADMIN_EMAIL = process.env.ADMIN_EMAIL ?? 'admin@local';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD ?? 'Admin!Local123';

const SHOT_DIR = path.join('test-results', 'lan-2026-05-12', 'lobby-login');

type NetworkEntry = { url: string; method: string; status?: number };

function attachNetworkCapture(page: Page): NetworkEntry[] {
  const log: NetworkEntry[] = [];
  page.on('request', (req) => {
    if (/\/auth\/|\/api\//.test(req.url())) {
      log.push({ url: req.url(), method: req.method() });
    }
  });
  page.on('response', (res) => {
    if (/\/auth\/|\/api\//.test(res.url())) {
      const entry = log.find((e) => e.url === res.url() && e.status === undefined);
      if (entry) entry.status = res.status();
    }
  });
  return log;
}

async function fillCredentials(
  page: Page,
  email: string,
  password: string,
): Promise<'dom' | 'canvas-fallback'> {
  // Flutter Web 은 a11y semantics 가 default off — 클릭으로 활성화
  await page.evaluate(() => {
    document.body.dispatchEvent(new MouseEvent('click', { bubbles: true }));
  });
  await page.waitForTimeout(500);

  // Strategy 1: DOM/semantic locator
  const emailLocators = [
    page.getByLabel('Email Address'),
    page.getByLabel(/email/i),
    page.getByPlaceholder(/email/i),
    page.locator('input[type="email"]'),
    page.locator('input').first(),
  ];
  const passwordLocators = [
    page.getByLabel('Password'),
    page.getByPlaceholder('Password'),
    page.locator('input[type="password"]'),
    page.locator('input').nth(1),
  ];

  let emailInput = null;
  for (const loc of emailLocators) {
    try {
      if ((await loc.count()) > 0) {
        emailInput = loc.first();
        break;
      }
    } catch {}
  }
  let passwordInput = null;
  for (const loc of passwordLocators) {
    try {
      if ((await loc.count()) > 0) {
        passwordInput = loc.first();
        break;
      }
    } catch {}
  }

  if (emailInput && passwordInput) {
    await emailInput.fill(email);
    await passwordInput.fill(password);
    return 'dom';
  }

  // Strategy 2: Coordinate fallback (Flutter Web canvas)
  // 1280x720 viewport 기준 form 좌표
  await page.mouse.click(640, 307);
  await page.waitForTimeout(200);
  await page.keyboard.type(email, { delay: 30 });
  await page.mouse.click(640, 354);
  await page.waitForTimeout(200);
  await page.keyboard.type(password, { delay: 30 });
  return 'canvas-fallback';
}

async function clickSubmit(page: Page): Promise<boolean> {
  const submitLocators = [
    page.getByRole('button', { name: /log in|로그인|sign in/i }),
    page.getByText('Log In', { exact: true }),
    page.locator('button[type="submit"]'),
  ];
  for (const loc of submitLocators) {
    try {
      if ((await loc.count()) > 0) {
        await loc.first().click();
        return true;
      }
    } catch {}
  }
  // Coordinate fallback
  await page.mouse.click(640, 391);
  return false;
}

test.describe('Cycle 9 — Lobby Login E2E (LAN 환경 실 검증)', () => {
  test.setTimeout(120_000);

  test('Lobby → login form → 인증 → dashboard 진입 (screenshot 6 phase)', async ({
    page,
  }) => {
    const networkLog = attachNetworkCapture(page);

    // ── Phase 1: Lobby 초기 진입 ─────────────────────────────────────
    await page.goto(LOBBY_BASE_URL);
    await page
      .waitForLoadState('networkidle', { timeout: 15000 })
      .catch(() => {});
    await page.screenshot({
      path: path.join(SHOT_DIR, '01-lobby-entry.png'),
      fullPage: true,
    });
    expect(page.url()).toContain(LOBBY_BASE_URL.replace(/\/$/, ''));

    // ── Phase 2: Login page (자동 redirect 또는 명시 navigate) ────────
    const entryUrl = page.url();
    if (
      !entryUrl.includes('/login') &&
      !entryUrl.includes('/auth')
    ) {
      await page.goto(`${LOBBY_BASE_URL}/login`).catch(() => {});
      await page
        .waitForLoadState('networkidle', { timeout: 10000 })
        .catch(() => {});
    }
    await page.screenshot({
      path: path.join(SHOT_DIR, '02-login-page.png'),
      fullPage: true,
    });

    // ── Phase 3: Credentials 입력 ────────────────────────────────────
    const strategy = await fillCredentials(page, ADMIN_EMAIL, ADMIN_PASSWORD);
    console.log(`[lobby-login] credential input strategy: ${strategy}`);
    await page.screenshot({
      path: path.join(SHOT_DIR, '03-credentials-filled.png'),
      fullPage: true,
    });

    // ── Phase 4: Submit + 인증 응답 대기 ──────────────────────────────
    const submitMatched = await clickSubmit(page);
    console.log(`[lobby-login] submit locator matched: ${submitMatched}`);
    await page
      .waitForLoadState('networkidle', { timeout: 15000 })
      .catch(() => {});
    await page.waitForTimeout(2000);
    await page.screenshot({
      path: path.join(SHOT_DIR, '04-after-login.png'),
      fullPage: true,
    });

    // ── Phase 5: Dashboard state 확인 (token 또는 URL 변화) ───────────
    const afterUrl = page.url();
    const hasToken = await page.evaluate(() => {
      try {
        return Object.keys(localStorage).some((k) =>
          /token|auth|session/i.test(k),
        );
      } catch {
        return false;
      }
    });
    await page.screenshot({
      path: path.join(SHOT_DIR, '05-dashboard-state.png'),
      fullPage: true,
    });

    // ── Phase 6: Network log capture (root cause 진단 evidence) ──────
    console.log('\n=== Lobby login network log ===');
    for (const entry of networkLog) {
      console.log(`  ${entry.method} ${entry.url} → ${entry.status ?? '?'}`);
    }
    // 추가 viewport screenshot (network panel proxy)
    await page.screenshot({
      path: path.join(SHOT_DIR, '06-final-viewport.png'),
      fullPage: false,
    });

    // ── DoD: URL 변화 또는 token 저장 (둘 중 하나) ────────────────────
    const loginSucceeded = afterUrl !== entryUrl || hasToken;
    expect(
      loginSucceeded,
      `login DoD: URL change (${entryUrl} → ${afterUrl}) or token stored (${hasToken})`,
    ).toBe(true);

    // ── 부가 evidence: BO auth 호출 1회 이상 발생 ────────────────────
    const authCalls = networkLog.filter((e) => /\/auth\//.test(e.url));
    expect(
      authCalls.length,
      `lobby → BO auth call should occur at least once (got ${authCalls.length})`,
    ).toBeGreaterThan(0);
  });
});
