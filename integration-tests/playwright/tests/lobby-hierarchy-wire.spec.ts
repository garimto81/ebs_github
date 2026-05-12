/**
 * Cycle 10 — S2 Lobby hierarchy wire (real BO, 2026-05-12)
 *
 * 검증 대상:
 *   - Lobby UI 가 `/api/v1/series` → `/series/{id}/events`
 *     → `/events/{id}/flights` → `/flights/{id}/tables` nested 경로로
 *     실 BO 와 통신하는지 (PR #357 이후 #369 login 통과를 전제로).
 *
 * 사용자 비판 수용:
 *   - "series-event-flight 매핑 mock 처리 — 모든 event 동일 flight" → 해소.
 *   - 본 spec 은 distinct event 2건을 차례로 열고, BO 가 서로 다른
 *     flight id 를 돌려주는지 네트워크 로그로 단언.
 *
 * 설계 노트 — single-page session:
 *   Auth 토큰이 localStorage 가 아니라 Riverpod 메모리 상태로만 보관되므로
 *   `page.goto()` 가 SPA 를 재부팅하면 로그인 상태가 즉시 휘발한다.  따라서
 *   본 spec 은 **로그인 후 reload 0회** 를 원칙으로 in-app router 만 사용
 *   (`history.pushState` + `popstate`).
 *
 * 6 phase screenshot (test-results/v01-lobby/):
 *   01-series-list.png   — 로그인 직후 자동 진입한 Series 목록
 *   02-event-list.png    — Series 1 의 event 목록 (count ≥ 1)
 *   03-flight-list.png   — Event A 의 flight 목록 (count ≥ 1)
 *   04-table-list.png    — Flight A 의 table 목록
 *   05-player-view.png   — Flight A 의 players view
 *   06-different-event-different-flight.png — KPI 증명 (Event B → Flight B)
 *
 * DoD:
 *   - BO 4 endpoint 모두 200 (series / series/:id/events /
 *     events/:id/flights / flights/:id/tables)
 *   - Event A 와 Event B 의 flight id 가 다름 (KPI 증명)
 *   - 6 screenshot 모두 존재 + non-empty
 *
 * 직전 patch (Cycle 10 S2):
 *   - event_repository.dart  listBySeries(id)  추가 (nested)
 *   - table_repository.dart  listByFlight(id)  추가 (nested)
 *   - event_provider.dart / table_provider.dart  nested 호출로 전환
 *   - mock_dio_adapter.dart  /series/:id/events  /flights/:id/tables 추가
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
  '..',
  'test-results',
  'v01-lobby',
);

test.use({
  launchOptions: {
    args: [
      '--host-resolver-rules=MAP api.ebs.local 127.0.0.1, MAP api.ebs.local:80 127.0.0.1:80',
    ],
  },
  viewport: { width: 1440, height: 900 },
});

type NetworkEntry = {
  url: string;
  method: string;
  status?: number;
  body?: string;
};

function attachNetworkCapture(page: Page): NetworkEntry[] {
  const log: NetworkEntry[] = [];
  page.on('request', (req: Request) => {
    if (/\/api\/v1\//.test(req.url())) {
      log.push({ url: req.url(), method: req.method() });
    }
  });
  page.on('response', async (res: Response) => {
    if (/\/api\/v1\//.test(res.url())) {
      const entry = log.find(
        (e) => e.url === res.url() && e.status === undefined,
      );
      if (entry) {
        entry.status = res.status();
        try {
          entry.body = await res.text();
        } catch {
          /* ignore body capture failure */
        }
      }
    }
  });
  return log;
}

function flightIdsFromBody(body?: string): number[] {
  if (!body) return [];
  try {
    const parsed = JSON.parse(body) as { data?: Array<{ eventFlightId?: number }> };
    return (parsed.data ?? [])
      .map((f) => f.eventFlightId)
      .filter((v): v is number => typeof v === 'number');
  } catch {
    return [];
  }
}

function eventIdsFromBody(body?: string): number[] {
  if (!body) return [];
  try {
    const parsed = JSON.parse(body) as { data?: Array<{ eventId?: number }> };
    return (parsed.data ?? [])
      .map((e) => e.eventId)
      .filter((v): v is number => typeof v === 'number');
  } catch {
    return [];
  }
}

// In-app navigation.  Flutter Lobby uses HashUrlStrategy (default for go_router
// on Flutter Web 3.x), so the canonical route is in the URL fragment.  Set the
// hash + fire hashchange/popstate to trigger go_router's URL listener **without**
// reloading the page, preserving the Riverpod auth state.
async function navigate(page: Page, route: string): Promise<void> {
  await page.evaluate((r) => {
    const target = r.startsWith('#') ? r : `#${r}`;
    if (window.location.hash === target) {
      // Force re-listen even when navigating back to the same hash.
      window.location.hash = '';
    }
    window.location.hash = target;
    window.dispatchEvent(new HashChangeEvent('hashchange'));
    window.dispatchEvent(new PopStateEvent('popstate', { state: null }));
  }, route);
}

test.describe('Cycle 10 — S2 Lobby hierarchy wire (real BO)', () => {
  test.setTimeout(180_000);

  test('series -> event -> flight -> table drill-down + distinct flights per event', async ({
    page,
  }) => {
    fs.mkdirSync(SHOT_DIR, { recursive: true });
    const networkLog = attachNetworkCapture(page);

    // ── Login (ONE page.goto for the whole test) ──────────────────────
    await page.goto(LOBBY_BASE_URL + '/?enable-semantics-on-app-start=true', {
      timeout: 15000,
    });
    await page
      .waitForLoadState('networkidle', { timeout: 15000 })
      .catch(() => {});
    await page.waitForTimeout(2500);
    await page.evaluate(() => {
      document.body.dispatchEvent(new MouseEvent('click', { bubbles: true }));
    });
    await page.waitForTimeout(500);
    const emailLoc = page.locator('input').first();
    const passwordLoc = page.locator('input').nth(1);
    let loginVia = 'unknown';
    try {
      if ((await emailLoc.count()) > 0 && (await passwordLoc.count()) > 0) {
        await emailLoc.fill(ADMIN_EMAIL);
        await passwordLoc.fill(ADMIN_PASSWORD);
        loginVia = 'dom';
      }
    } catch {}
    if (loginVia === 'unknown') {
      await page.mouse.click(720, 397);
      await page.waitForTimeout(300);
      await page.keyboard.type(ADMIN_EMAIL, { delay: 25 });
      await page.mouse.click(720, 444);
      await page.waitForTimeout(300);
      await page.keyboard.type(ADMIN_PASSWORD, { delay: 25 });
      loginVia = 'canvas-coordinate';
    }
    console.log(`[login] input strategy: ${loginVia}`);
    const submitLoc = page.getByRole('button', { name: /log in|로그인|sign in/i });
    try {
      if ((await submitLoc.count()) > 0) {
        await submitLoc.first().click();
      } else {
        await page.mouse.click(720, 482);
      }
    } catch {
      await page.mouse.click(720, 482);
    }
    // 로그인 → /lobby/series 자동 redirect → /api/v1/series 호출 대기.
    await page
      .waitForResponse(
        (res) =>
          /\/api\/v1\/series(\?|$)/.test(res.url()) && res.status() === 200,
        { timeout: 20000 },
      )
      .catch(() => {});
    await page.waitForTimeout(2500);

    // ── Phase 01: Series list (자동 진입) ──────────────────────────────
    await page.screenshot({
      path: path.join(SHOT_DIR, '01-series-list.png'),
      fullPage: true,
    });
    const seriesResp = networkLog.find(
      (e) => /\/api\/v1\/series(\?|$)/.test(e.url) && e.status === 200,
    );
    console.log('[phase01] /series →', seriesResp?.status);

    // ── Phase 02: Series 1 events (in-app pushState) ───────────────────
    await navigate(page, '/lobby/events/1');
    await page
      .waitForResponse(
        (res) =>
          /\/api\/v1\/series\/1\/events/.test(res.url()) && res.status() === 200,
        { timeout: 20000 },
      )
      .catch(() => {});
    await page.waitForTimeout(2000);
    await page.screenshot({
      path: path.join(SHOT_DIR, '02-event-list.png'),
      fullPage: true,
    });
    const eventsResp = networkLog.find(
      (e) => /\/api\/v1\/series\/1\/events/.test(e.url) && e.status === 200,
    );
    const eventIds = eventIdsFromBody(eventsResp?.body);
    const eventIdA = eventIds[0] ?? 11;
    const eventIdB = eventIds.length > 1 ? eventIds[1] : 12;
    console.log(
      `[phase02] /series/1/events → ${eventsResp?.status} ids=${eventIds.join(',')}`,
    );

    // ── Phase 03: Event A flights ──────────────────────────────────────
    await navigate(page, `/lobby/flights/${eventIdA}`);
    await page
      .waitForResponse(
        (res) =>
          new RegExp(`/api/v1/events/${eventIdA}/flights`).test(res.url()) &&
          res.status() === 200,
        { timeout: 20000 },
      )
      .catch(() => {});
    await page.waitForTimeout(2000);
    await page.screenshot({
      path: path.join(SHOT_DIR, '03-flight-list.png'),
      fullPage: true,
    });
    const flightsRespA = networkLog.find(
      (e) =>
        new RegExp(`/api/v1/events/${eventIdA}/flights`).test(e.url) &&
        e.status === 200,
    );
    const flightIdsA = flightIdsFromBody(flightsRespA?.body);
    console.log(
      `[phase03] event ${eventIdA} flights = ${flightIdsA.join(',')} (status ${flightsRespA?.status})`,
    );

    // ── Phase 04: Flight A tables ──────────────────────────────────────
    const flightA = flightIdsA[0] ?? 9;
    await navigate(page, `/lobby/flight/${flightA}/tables`);
    await page
      .waitForResponse(
        (res) =>
          new RegExp(`/api/v1/flights/${flightA}/tables`).test(res.url()) &&
          res.status() === 200,
        { timeout: 20000 },
      )
      .catch(() => {});
    await page.waitForTimeout(2000);
    await page.screenshot({
      path: path.join(SHOT_DIR, '04-table-list.png'),
      fullPage: true,
    });
    const tablesRespA = networkLog.find(
      (e) =>
        new RegExp(`/api/v1/flights/${flightA}/tables`).test(e.url) &&
        e.status === 200,
    );
    console.log(`[phase04] flight ${flightA} tables → ${tablesRespA?.status}`);

    // ── Phase 05: Players view ─────────────────────────────────────────
    await navigate(page, `/lobby/flight/${flightA}/players`);
    await page.waitForTimeout(2000);
    await page.screenshot({
      path: path.join(SHOT_DIR, '05-player-view.png'),
      fullPage: true,
    });

    // ── Phase 06: KPI — different event → different flight ─────────────
    await navigate(page, `/lobby/flights/${eventIdB}`);
    await page
      .waitForResponse(
        (res) =>
          new RegExp(`/api/v1/events/${eventIdB}/flights`).test(res.url()) &&
          res.status() === 200,
        { timeout: 20000 },
      )
      .catch(() => {});
    await page.waitForTimeout(2000);
    await page.screenshot({
      path: path.join(SHOT_DIR, '06-different-event-different-flight.png'),
      fullPage: true,
    });
    const flightsRespB = networkLog.find(
      (e) =>
        new RegExp(`/api/v1/events/${eventIdB}/flights`).test(e.url) &&
        e.status === 200,
    );
    const flightIdsB = flightIdsFromBody(flightsRespB?.body);
    console.log(
      `[phase06] event ${eventIdB} flights = ${flightIdsB.join(',')} (status ${flightsRespB?.status})`,
    );

    // ── Summary ────────────────────────────────────────────────────────
    const distinct =
      flightIdsA.length > 0 &&
      flightIdsB.length > 0 &&
      !flightIdsA.every((id) => flightIdsB.includes(id));
    console.log(
      `[KPI] flightIdsA=${flightIdsA.join(',')} flightIdsB=${flightIdsB.join(',')} distinct=${distinct}`,
    );

    const summary = [
      `# Cycle 10 — S2 Lobby hierarchy wire evidence`,
      ``,
      `Run timestamp: ${new Date().toISOString()}`,
      `Lobby base URL: ${LOBBY_BASE_URL}`,
      `Login strategy: ${loginVia}`,
      `Navigation: in-app pushState + popstate (page.goto reload disabled)`,
      ``,
      `## BO endpoint chain`,
      `- GET /api/v1/series                         → ${seriesResp?.status ?? 'NO-CALL'}`,
      `- GET /api/v1/series/1/events                → ${eventsResp?.status ?? 'NO-CALL'}`,
      `- GET /api/v1/events/${eventIdA}/flights     → ${flightsRespA?.status ?? 'NO-CALL'}`,
      `- GET /api/v1/flights/${flightA}/tables      → ${tablesRespA?.status ?? 'NO-CALL'}`,
      `- GET /api/v1/events/${eventIdB}/flights     → ${flightsRespB?.status ?? 'NO-CALL'}`,
      ``,
      `## KPI — distinct flights per event`,
      `- Event ${eventIdA} flights: [${flightIdsA.join(', ')}]`,
      `- Event ${eventIdB} flights: [${flightIdsB.join(', ')}]`,
      `- Distinct: **${distinct ? 'PASS' : 'FAIL'}**`,
      ``,
      `## Screenshot evidence`,
      `- 01-series-list.png   — Series 목록 (로그인 직후 자동 진입)`,
      `- 02-event-list.png    — Series 1 events`,
      `- 03-flight-list.png   — Event ${eventIdA} flights`,
      `- 04-table-list.png    — Flight ${flightA} tables`,
      `- 05-player-view.png   — Players view`,
      `- 06-different-event-different-flight.png — Event ${eventIdB} flights (KPI)`,
      ``,
      `## Network log (api/v1 only)`,
      ...networkLog.map((e) => `- ${e.method} ${e.url} → ${e.status ?? '?'}`),
      ``,
    ].join('\n');
    fs.writeFileSync(path.join(SHOT_DIR, 'summary.md'), summary);

    // ── DoD assertions ─────────────────────────────────────────────────
    expect(
      seriesResp?.status,
      `BO /api/v1/series must return 200 (got ${seriesResp?.status})`,
    ).toBe(200);
    expect(
      eventsResp?.status,
      `BO /api/v1/series/1/events must return 200 (got ${eventsResp?.status})`,
    ).toBe(200);
    expect(
      flightsRespA?.status,
      `BO /api/v1/events/${eventIdA}/flights must return 200 (got ${flightsRespA?.status})`,
    ).toBe(200);
    expect(
      tablesRespA?.status,
      `BO /api/v1/flights/${flightA}/tables must return 200 (got ${tablesRespA?.status})`,
    ).toBe(200);
    expect(
      flightsRespB?.status,
      `BO /api/v1/events/${eventIdB}/flights must return 200 (got ${flightsRespB?.status})`,
    ).toBe(200);
    expect(
      distinct,
      `KPI: event ${eventIdA} and event ${eventIdB} must show distinct flight ids (A=${flightIdsA.join(',')}, B=${flightIdsB.join(',')})`,
    ).toBe(true);
  });
});
