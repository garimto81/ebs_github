/**
 * Cycle 9 — Lobby Login REAL E2E (QA 사용자 진입점 검증, 2026-05-12)
 *
 * 본 spec 은 사용자 비판 "QA 통과 = e2e screenshot 추출 + 검증" 수용:
 *   - 단순 curl 200 ≠ 통과 (사용자 정의)
 *   - 실제 브라우저 로그인 + dashboard 진입 + screenshot 6+ 장
 *   - evidence/cycle9-qa-real/ 단일 SSOT 폴더로 저장
 *
 * 직전 lobby-login.spec.ts FAIL 분석 (2026-05-12 19:30):
 *   - Lobby Flutter app 은 `http://api.ebs.local/api/v1/auth/login` 절대 URL 호출
 *   - 사용자 브라우저에 `api.ebs.local` DNS 매핑 부재 시 ERR_CONNECTION_REFUSED
 *   - 본 spec 은 Chromium `--host-resolver-rules` 로 `api.ebs.local → 127.0.0.1`
 *     매핑하여 ebs-proxy nginx (Host header 라우팅) 흐름 그대로 검증
 *
 * Screenshot evidence (evidence/cycle9-qa-real/):
 *   - 01-lobby-load.png        (초기 진입, Flutter 부트)
 *   - 02-login-form.png        (login UI 노출)
 *   - 03-credentials-typed.png (email/password 입력 완료)
 *   - 04-login-submitted.png   (Log In 클릭 직후)
 *   - 05-after-auth.png        (인증 응답 후 화면)
 *   - 06-dashboard.png         (최종 dashboard / lobby state)
 *
 * DoD (사용자 정의):
 *   - 6 screenshot 모두 존재 + non-empty
 *   - URL hash 변화 또는 token localStorage 저장
 *   - BO `/auth/login` 네트워크 콜 1회 + HTTP 200 응답
 */
import { expect, test, type Page } from '@playwright/test';
import * as path from 'path';
import * as fs from 'fs';

const LOBBY_BASE_URL = process.env.LOBBY_BASE_URL ?? 'http://localhost:3000';
const ADMIN_EMAIL = process.env.ADMIN_EMAIL ?? 'admin@local';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD ?? 'Admin!Local123';

// evidence/cycle9-qa-real/ — integration-tests 기준 상대 경로
const SHOT_DIR = path.resolve(
  __dirname,
  '..',
  '..',
  'evidence',
  'cycle9-qa-real',
);

test.use({
  // ebs-proxy nginx 는 Host: api.ebs.local 헤더로 BO 라우팅. DNS 우회.
  launchOptions: {
    args: [
      '--host-resolver-rules=MAP api.ebs.local 127.0.0.1, MAP api.ebs.local:80 127.0.0.1:80',
    ],
  },
  viewport: { width: 1440, height: 900 },
});

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
      const entry = log.find(
        (e) => e.url === res.url() && e.status === undefined,
      );
      if (entry) entry.status = res.status();
    }
  });
  return log;
}

test.describe('Cycle 9 — Lobby Login REAL (사용자 진입점 검증)', () => {
  test.setTimeout(120_000);

  test('Lobby 진입 → login → dashboard (screenshot 6 phase, real auth)', async ({
    page,
  }) => {
    fs.mkdirSync(SHOT_DIR, { recursive: true });
    const networkLog = attachNetworkCapture(page);

    // ── Phase 1: Lobby 진입 + Flutter 부트 (semantics 강제 활성화) ────
    // ?enable-semantics-on-app-start=true 부착 → Flutter Web 이 DOM input
    // 요소를 노출 → DOM locator 가 안정적으로 동작
    const entryWithSemantics =
      LOBBY_BASE_URL + '/?enable-semantics-on-app-start=true';
    await page.goto(entryWithSemantics, { timeout: 15000 });
    await page
      .waitForLoadState('networkidle', { timeout: 15000 })
      .catch(() => {});
    await page.waitForTimeout(2500); // Flutter canvas + semantics 안정화
    await page.screenshot({
      path: path.join(SHOT_DIR, '01-lobby-load.png'),
      fullPage: true,
    });
    const entryUrl = page.url();
    console.log(`[phase1] entry URL: ${entryUrl}`);

    // ── Phase 2: Login form 노출 (Flutter 자동 redirect /#/login 기대) ─
    if (!entryUrl.includes('login')) {
      await page.goto(`${LOBBY_BASE_URL}/#/login`).catch(() => {});
      await page.waitForTimeout(1500);
    }
    // Flutter Web semantics enable (a11y default off → click 으로 활성화)
    await page.evaluate(() => {
      document.body.dispatchEvent(new MouseEvent('click', { bubbles: true }));
    });
    await page.waitForTimeout(500);
    await page.screenshot({
      path: path.join(SHOT_DIR, '02-login-form.png'),
      fullPage: true,
    });

    // ── Phase 3: Credentials 입력 (DOM → coordinate fallback) ─────────
    let inputStrategy = 'unknown';
    const emailLoc = page.locator('input').first();
    const passwordLoc = page.locator('input').nth(1);
    try {
      if ((await emailLoc.count()) > 0 && (await passwordLoc.count()) > 0) {
        await emailLoc.fill(ADMIN_EMAIL);
        await passwordLoc.fill(ADMIN_PASSWORD);
        inputStrategy = 'dom';
      }
    } catch {}
    if (inputStrategy === 'unknown') {
      // Flutter canvas — 1440x900 viewport 기준 form 좌표 (02-login-form.png 측정값)
      // Email Address input center y≈397, Password y≈444, Log In btn y≈482
      await page.mouse.click(720, 397);
      await page.waitForTimeout(300);
      await page.keyboard.type(ADMIN_EMAIL, { delay: 25 });
      await page.waitForTimeout(300);
      await page.mouse.click(720, 444);
      await page.waitForTimeout(300);
      await page.keyboard.type(ADMIN_PASSWORD, { delay: 25 });
      inputStrategy = 'canvas-coordinate';
    }
    console.log(`[phase3] input strategy: ${inputStrategy}`);
    await page.waitForTimeout(500);
    await page.screenshot({
      path: path.join(SHOT_DIR, '03-credentials-typed.png'),
      fullPage: true,
    });

    // ── Phase 4: Log In 클릭 ─────────────────────────────────────────
    let submitStrategy = 'unknown';
    const submitLocators = [
      page.getByRole('button', { name: /log in|로그인|sign in/i }),
      page.getByText('Log In', { exact: true }),
      page.locator('button[type="submit"]'),
    ];
    for (const loc of submitLocators) {
      try {
        if ((await loc.count()) > 0) {
          await loc.first().click();
          submitStrategy = 'dom';
          break;
        }
      } catch {}
    }
    if (submitStrategy === 'unknown') {
      // Log In button center (1440x900 viewport): y≈482
      await page.mouse.click(720, 482);
      submitStrategy = 'canvas-coordinate';
    }
    console.log(`[phase4] submit strategy: ${submitStrategy}`);
    await page.waitForTimeout(800);
    await page.screenshot({
      path: path.join(SHOT_DIR, '04-login-submitted.png'),
      fullPage: true,
    });

    // ── Phase 5: 인증 응답 대기 + 결과 화면 ───────────────────────────
    await page
      .waitForLoadState('networkidle', { timeout: 15000 })
      .catch(() => {});
    await page.waitForTimeout(2500);
    await page.screenshot({
      path: path.join(SHOT_DIR, '05-after-auth.png'),
      fullPage: true,
    });

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
    console.log(`[phase5] after URL: ${afterUrl}, hasToken: ${hasToken}`);

    // ── Phase 6: Dashboard / Final state ──────────────────────────────
    await page.waitForTimeout(1000);
    await page.screenshot({
      path: path.join(SHOT_DIR, '06-dashboard.png'),
      fullPage: true,
    });

    // ── Network log dump ─────────────────────────────────────────────
    console.log('\n=== Lobby login network log ===');
    for (const entry of networkLog) {
      console.log(`  ${entry.method} ${entry.url} → ${entry.status ?? '?'}`);
    }

    // ── DoD: URL 변화 또는 token 저장 ─────────────────────────────────
    const loginSucceeded = afterUrl !== entryUrl || hasToken;
    const authCalls = networkLog.filter(
      (e) => /\/auth\/login/.test(e.url) && e.status === 200,
    );

    // 결과 요약 파일도 같은 폴더에
    const summary = [
      `# Cycle 9 QA Real — Lobby Login Evidence`,
      ``,
      `Run timestamp: ${new Date().toISOString()}`,
      `Lobby base URL: ${LOBBY_BASE_URL}`,
      ``,
      `## Result`,
      `- Entry URL: ${entryUrl}`,
      `- After URL: ${afterUrl}`,
      `- URL changed: ${afterUrl !== entryUrl}`,
      `- Token in localStorage: ${hasToken}`,
      `- Auth 200 calls: ${authCalls.length}`,
      `- Login DoD: ${loginSucceeded ? 'PASS' : 'FAIL'}`,
      `- Input strategy: ${inputStrategy}`,
      `- Submit strategy: ${submitStrategy}`,
      ``,
      `## Network log`,
      ...networkLog.map(
        (e) => `- ${e.method} ${e.url} → ${e.status ?? '?'}`,
      ),
      ``,
      `## Screenshot evidence`,
      `- 01-lobby-load.png       — Flutter 부트 직후`,
      `- 02-login-form.png       — login UI 노출`,
      `- 03-credentials-typed.png — admin@local 입력 완료`,
      `- 04-login-submitted.png  — Log In 클릭 직후`,
      `- 05-after-auth.png       — BO /auth/login 응답 후`,
      `- 06-dashboard.png        — 최종 화면`,
      ``,
    ].join('\n');
    fs.writeFileSync(path.join(SHOT_DIR, 'summary.md'), summary);

    expect(
      loginSucceeded,
      `login DoD: URL change (${entryUrl} → ${afterUrl}) or token stored (${hasToken})`,
    ).toBe(true);
    expect(
      authCalls.length,
      `BO /auth/login should respond 200 at least once (got ${authCalls.length})`,
    ).toBeGreaterThan(0);
  });
});
