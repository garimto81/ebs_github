/**
 * Cycle 21 Wave 4 — Hand History 상세 화면 (nested hand_players + hand_actions)
 *
 * S9 Cycle 21 Wave 4 신규 (2026-05-13, issue #459).
 *
 * 목적:
 *   Cycle 21 Wave 1 (PR #444) 정합 — Hand History 의 상세 진입 동작 검증.
 *   list 화면에서 hand row 클릭 시 BO REST `GET /api/v1/hands/{id}` 가 호출되고
 *   nested `hand_players[]` + `hand_actions[]` 가 상세 화면에 렌더링되는지 확인.
 *
 * SSOT:
 *   docs/2. Development/2.2 Backend/APIs/Players_HandHistory_API.md §2.4
 *   docs/2. Development/2.1 Frontend/Lobby/Hand_History.md §2.2 Hand Detail
 *
 * 검증 case:
 *   T1 hand row 클릭 → GET /api/v1/hands/{id} 호출됨
 *   T2 응답 schema 에 hand_players[] + hand_actions[] nested 존재
 *   T3 상세 화면에 actions timeline (preflop/flop/turn/river) 노출
 *
 * 실행 사전 요구:
 *   - lobby-web (http://localhost:3000) + BO (http://localhost:18001)
 *   - Cycle 21 Wave 3 (Lobby Hand_History.dart 구현) 머지 후
 *   - BO seed 에 최소 1 hand + hand_players + hand_actions 존재
 *
 * 본 spec 은 optional — list spec (lobby-reports-removal.spec.ts) 의
 * T4/T5 가 우선. 본 spec 은 W3 frontend impl 머지 후 실행.
 */
import { expect, test, type Page, type Request, type Response } from '@playwright/test';
import * as path from 'path';
import * as fs from 'fs';

const LOBBY_BASE_URL = process.env.LOBBY_BASE_URL ?? 'http://localhost:3000';
const ADMIN_EMAIL = process.env.ADMIN_EMAIL ?? 'admin@local';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD ?? 'Admin!Local123';

const SHOT_DIR = path.resolve(
  __dirname,
  '..',
  '..',
  'evidence',
  'cycle21-hand-history-detail',
);

test.use({
  viewport: { width: 1440, height: 900 },
});

type NetworkEntry = {
  url: string;
  method: string;
  status?: number;
  body?: string;
};

function attachNetworkCapture(page: Page): { log: NetworkEntry[] } {
  const log: NetworkEntry[] = [];
  page.on('request', (req: Request) => {
    const u = req.url();
    if (/\/api\/v1\/hands/.test(u)) {
      log.push({ url: u, method: req.method() });
    }
  });
  page.on('response', async (res: Response) => {
    const u = res.url();
    if (/\/api\/v1\/hands/.test(u)) {
      const entry = [...log]
        .reverse()
        .find((e) => e.url === u && e.status === undefined);
      if (entry) {
        entry.status = res.status();
        try {
          entry.body = await res.text();
        } catch {
          /* ignore */
        }
      }
    }
  });
  return { log };
}

async function navigate(page: Page, route: string): Promise<void> {
  await page.evaluate((r) => {
    const target = r.startsWith('#') ? r : `#${r}`;
    if (window.location.hash === target) {
      window.location.hash = '';
    }
    window.location.hash = target;
    window.dispatchEvent(new HashChangeEvent('hashchange'));
    window.dispatchEvent(new PopStateEvent('popstate', { state: null }));
  }, route);
}

async function login(page: Page): Promise<void> {
  await page.goto(`${LOBBY_BASE_URL}/?enable-semantics-on-app-start=true`, {
    timeout: 15000,
  });
  await page.waitForLoadState('networkidle', { timeout: 15000 }).catch(() => {});

  const emailField = page.getByLabel(/email/i).first();
  const pwField = page.getByLabel(/password/i).first();
  await emailField.fill(ADMIN_EMAIL).catch(() => {});
  await pwField.fill(ADMIN_PASSWORD).catch(() => {});
  await page.getByRole('button', { name: /sign in|login/i }).click().catch(() => {});
  await page.waitForLoadState('networkidle', { timeout: 10000 }).catch(() => {});
}

test.describe('Cycle 21 Wave 4 — Hand History Detail (nested hand_players + hand_actions)', () => {
  test.setTimeout(180_000);

  test.beforeAll(() => {
    fs.mkdirSync(SHOT_DIR, { recursive: true });
  });

  test('T1+T2 hand row 클릭 → GET /api/v1/hands/{id} + nested schema 검증', async ({ page }) => {
    const { log: networkLog } = attachNetworkCapture(page);
    await login(page);
    await navigate(page, '/hand-history');
    await page.waitForLoadState('networkidle', { timeout: 10000 }).catch(() => {});
    await page.waitForTimeout(1500);

    // 첫 번째 hand row 클릭 — list 화면의 row / clickable card.
    // semantics tree 기반 — "hand" label / table row / list tile.
    const firstHandRow = page
      .getByRole('button', { name: /hand\s*#?\d+|hand\s*number/i })
      .first();
    await firstHandRow.click().catch(async () => {
      // fallback: 첫 번째 listitem / row 클릭.
      await page.getByRole('listitem').first().click().catch(() => {});
    });
    await page.waitForTimeout(2000);

    // GET /api/v1/hands/{id} 호출 확인.
    const detailHits = networkLog.filter(
      (e) => /\/api\/v1\/hands\/\d+(\?|$)/.test(e.url) && e.method === 'GET',
    );

    await page.screenshot({
      path: path.join(SHOT_DIR, 'T1-hand-detail-fetched.png'),
      fullPage: true,
    });

    expect(
      detailHits.length,
      `GET /api/v1/hands/{id} 호출 0건 = hand row 클릭이 상세 fetch 미발동`,
    ).toBeGreaterThanOrEqual(1);

    // 응답 schema 검증 (Players_HandHistory_API.md §2.4).
    const okHit = detailHits.find((e) => e.status === 200);
    expect(okHit, 'GET /api/v1/hands/{id} 200 응답 없음').toBeTruthy();
    if (okHit?.body) {
      const parsed = JSON.parse(okHit.body) as {
        hand_id?: number;
        hand_players?: unknown[];
        hand_actions?: unknown[];
      };
      expect(typeof parsed.hand_id, 'hand_id 필드 부재').toBe('number');
      expect(
        Array.isArray(parsed.hand_players),
        'hand_players[] nested 배열 부재 = §2.4 schema 위반',
      ).toBeTruthy();
      expect(
        Array.isArray(parsed.hand_actions),
        'hand_actions[] nested 배열 부재 = §2.4 schema 위반',
      ).toBeTruthy();
    }
  });

  test('T3 상세 화면에 actions timeline (preflop/flop/turn/river) 렌더링', async ({ page }) => {
    await login(page);
    await navigate(page, '/hand-history');
    await page.waitForLoadState('networkidle', { timeout: 10000 }).catch(() => {});
    await page.waitForTimeout(1500);

    // 첫 번째 hand row 클릭.
    const firstHandRow = page
      .getByRole('button', { name: /hand\s*#?\d+|hand\s*number/i })
      .first();
    await firstHandRow.click().catch(async () => {
      await page.getByRole('listitem').first().click().catch(() => {});
    });
    await page.waitForTimeout(2500);

    // street label 노출 검증 — preflop / flop / turn / river 중 하나 이상.
    const bodyText = await page.locator('body').innerText().catch(() => '');
    const hasStreetLabel = /\b(preflop|flop|turn|river|showdown)\b/i.test(bodyText);

    await page.screenshot({
      path: path.join(SHOT_DIR, 'T3-actions-timeline.png'),
      fullPage: true,
    });

    expect(
      hasStreetLabel,
      'actions timeline 의 street label (preflop/flop/turn/river) 미노출 = hand_actions 미렌더',
    ).toBeTruthy();
  });
});
