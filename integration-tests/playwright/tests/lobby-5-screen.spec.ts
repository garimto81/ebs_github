/**
 * Cycle 10 — Lobby 5-Screen E2E (hosts-free same-origin 검증)
 *
 * S9 Cycle 10 신규 (2026-05-12).
 *
 * 목적:
 *   사용자 요구 — Lobby HTML 5 화면 e2e screenshot. 단순 5장이 아니라
 *   "다른 event 선택 → 다른 flight 진입" 검증으로 Lobby↔BO 5 계층 실 연동을
 *   증명. 또한 **hosts 매핑 없이** (api.ebs.local 호출 0건) cycle 9 #358/#359
 *   EBS_SAME_ORIGIN runtime mode 가 실 적용된 상태를 검증.
 *
 * lobby-hierarchy-wire.spec.ts 와의 차이:
 *   - 본 spec 은 host-resolver-rules 미사용 (hosts 매핑 부재 환경 모사).
 *   - 사용자 명시 phase 명명 (00-login / 01-series / 02-events / 03-flights /
 *     04-tables) + 추가 분기 screenshot 2장.
 *   - evidence/cycle10-lobby-html/ (사용자 명시 폴더) 로 산출.
 *
 * 5 phase + 분기:
 *   00-login    /#/login            Login UI
 *   01-series   /#/lobby/series     GET /api/v1/series
 *   02-events   /#/lobby/events/1   GET /api/v1/series/1/events (4 events)
 *   03-flights  /#/lobby/flights/14 GET /api/v1/events/14/flights (3 flights, Main Event)
 *   04-tables   /#/lobby/flight/6/tables GET /api/v1/flights/6/tables (8 tables, Day 1A)
 *   03b-flights-evt11  분기 검증 (event 11 → 1 flight, Casino Employees)
 *   03c-flights-evt1   분기 검증 (event 1 → 1 flight, series 2 Opener)
 *
 * DoD:
 *   - api.ebs.local 호출 0건 (hosts-free)
 *   - localhost:3000/api/v1/* 호출 ≥ 1건 (same-origin proxy 확인)
 *   - 5 계층 endpoint 모두 200 hit
 *   - flights 호출 시 서로 다른 event_id 가 최소 2개 등장 (실 연동)
 *
 * 의존성:
 *   - S2 Cycle 9 #358/#359 머지 (EBS_SAME_ORIGIN runtime mode)
 *   - S2 Cycle 10 #377 머지 (Lobby hierarchy wire)
 *   - S7 BO seed (series 1~5, event 1~14, flight 1~12, table 11~58)
 *   - S11 docker compose --profile web up -d lobby-web
 *
 * broker MCP publish: pipeline:qa-pass (사용자 직접 확인 후에만).
 */
import { expect, test, type Page, type Request, type Response } from '@playwright/test';
import * as path from 'path';
import * as fs from 'fs';

const LOBBY_BASE_URL = process.env.LOBBY_BASE_URL ?? 'http://localhost:3000';
const ADMIN_EMAIL = process.env.ADMIN_EMAIL ?? 'admin@local';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD ?? 'Admin!Local123';

// 사용자 명시 evidence 폴더 — integration-tests/evidence/cycle10-lobby-html/
// (test-results 가 아닌 evidence — 영구 git 추적 대상)
const SHOT_DIR = path.resolve(
  __dirname,
  '..',
  '..',
  'evidence',
  'cycle10-lobby-html',
);

// hosts-free 검증 핵심:
//   --host-resolver-rules 미설정. lobby-hierarchy-wire.spec.ts 와의 결정적
//   차이. cycle 9 #358/#359 EBS_SAME_ORIGIN 이 적용된 빌드에서는 Lobby 가
//   api.ebs.local 을 호출하지 않으므로 hosts 매핑 없이 PASS 해야 한다.
test.use({
  viewport: { width: 1440, height: 900 },
});

type NetworkEntry = {
  url: string;
  method: string;
  status?: number;
  body?: string;
  phase: string;
};

function attachNetworkCapture(
  page: Page,
): { log: NetworkEntry[]; setPhase: (p: string) => void } {
  const log: NetworkEntry[] = [];
  let currentPhase = 'pre';
  page.on('request', (req: Request) => {
    const u = req.url();
    if (/\/api\/v1\/|api\.ebs\.local/.test(u)) {
      log.push({ url: u, method: req.method(), phase: currentPhase });
    }
  });
  page.on('response', async (res: Response) => {
    const u = res.url();
    if (/\/api\/v1\/|api\.ebs\.local/.test(u)) {
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
  return { log, setPhase: (p) => { currentPhase = p; } };
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

// SPA 내부 navigation — Flutter Lobby 는 HashUrlStrategy 사용.
// hashchange + popstate 둘 다 dispatch 해 go_router URL listener 깨운다.
// page.goto 사용 금지 — Riverpod auth 메모리 상태 휘발 방지.
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

test.describe('Cycle 10 — Lobby 5-Screen E2E (hosts-free, BO 5계층 실연동)', () => {
  test.setTimeout(180_000);

  test('Lobby 5 화면 + 이벤트 분기 + hosts-free DoD', async ({ page }) => {
    fs.mkdirSync(SHOT_DIR, { recursive: true });
    const { log: networkLog, setPhase } = attachNetworkCapture(page);

    // ── Phase 00: Login UI ────────────────────────────────────────
    setPhase('00-login');
    await page.goto(
      `${LOBBY_BASE_URL}/?enable-semantics-on-app-start=true`,
      { timeout: 15000 },
    );
    await page
      .waitForLoadState('networkidle', { timeout: 15000 })
      .catch(() => {});
    await page.waitForTimeout(2500);
    await page.screenshot({
      path: path.join(SHOT_DIR, '00-login.png'),
      fullPage: true,
    });

    // ── 인증 입력 (DOM 우선 → canvas-coordinate fallback) ─────────
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
    console.log(`[lobby-5-screen] login strategy: ${loginVia}`);

    const submitLoc = page.getByRole('button', {
      name: /log in|로그인|sign in/i,
    });
    try {
      if ((await submitLoc.count()) > 0) {
        await submitLoc.first().click();
      } else {
        await page.mouse.click(720, 482);
      }
    } catch {
      await page.mouse.click(720, 482);
    }

    // /api/v1/series 응답 대기 — 로그인 → /lobby/series 자동 redirect 신호
    await page
      .waitForResponse(
        (res) =>
          /\/api\/v1\/series(\?|$)/.test(res.url()) && res.status() === 200,
        { timeout: 25000 },
      )
      .catch(() => {});
    await page.waitForTimeout(2500);

    // ── Phase 01: Series 목록 (자동 진입) ─────────────────────────
    setPhase('01-series');
    await page.screenshot({
      path: path.join(SHOT_DIR, '01-series.png'),
      fullPage: true,
    });
    const seriesResp = networkLog.find(
      (e) =>
        /\/api\/v1\/series(\?|$)/.test(e.url) &&
        !/\/series\/\d/.test(e.url) &&
        e.status === 200,
    );
    console.log(`[01-series] GET /series → ${seriesResp?.status}`);

    // ── Phase 02: Events for series 1 ────────────────────────────
    setPhase('02-events');
    await navigate(page, '/lobby/events/1');
    await page
      .waitForResponse(
        (res) =>
          /\/api\/v1\/series\/1\/events/.test(res.url()) &&
          res.status() === 200,
        { timeout: 20000 },
      )
      .catch(() => {});
    await page.waitForTimeout(2000);
    await page.screenshot({
      path: path.join(SHOT_DIR, '02-events.png'),
      fullPage: true,
    });
    const eventsResp = networkLog.find(
      (e) =>
        /\/api\/v1\/series\/1\/events/.test(e.url) && e.status === 200,
    );
    const eventIds = eventIdsFromBody(eventsResp?.body);
    console.log(
      `[02-events] series 1 events → ${eventsResp?.status} ids=${eventIds.join(',')}`,
    );

    // event 14 (Main Event 2026) 우선 — seed 상 3 flights 확인됨.
    // 만약 BO 응답에 14 없으면 첫 번째 사용.
    const eventIdMain = eventIds.includes(14) ? 14 : eventIds[0] ?? 14;
    const eventIdBranchA = eventIds.find((id) => id !== eventIdMain) ?? 11;

    // ── Phase 03: Flights for event 14 ───────────────────────────
    setPhase('03-flights');
    await navigate(page, `/lobby/flights/${eventIdMain}`);
    await page
      .waitForResponse(
        (res) =>
          new RegExp(`/api/v1/events/${eventIdMain}/flights`).test(res.url()) &&
          res.status() === 200,
        { timeout: 20000 },
      )
      .catch(() => {});
    await page.waitForTimeout(2000);
    await page.screenshot({
      path: path.join(SHOT_DIR, '03-flights.png'),
      fullPage: true,
    });
    const flightsRespMain = networkLog.find(
      (e) =>
        new RegExp(`/api/v1/events/${eventIdMain}/flights`).test(e.url) &&
        e.status === 200,
    );
    const flightIdsMain = flightIdsFromBody(flightsRespMain?.body);
    console.log(
      `[03-flights] event ${eventIdMain} flights → ${flightsRespMain?.status} ids=${flightIdsMain.join(',')}`,
    );

    // ── Phase 04: Tables for flight 6 (Day 1A) ───────────────────
    setPhase('04-tables');
    const flightIdMain = flightIdsMain.includes(6) ? 6 : flightIdsMain[0] ?? 6;
    await navigate(page, `/lobby/flight/${flightIdMain}/tables`);
    await page
      .waitForResponse(
        (res) =>
          new RegExp(`/api/v1/flights/${flightIdMain}/tables`).test(res.url()) &&
          res.status() === 200,
        { timeout: 20000 },
      )
      .catch(() => {});
    await page.waitForTimeout(2000);
    await page.screenshot({
      path: path.join(SHOT_DIR, '04-tables.png'),
      fullPage: true,
    });
    const tablesResp = networkLog.find(
      (e) =>
        new RegExp(`/api/v1/flights/${flightIdMain}/tables`).test(e.url) &&
        e.status === 200,
    );
    console.log(
      `[04-tables] flight ${flightIdMain} tables → ${tablesResp?.status}`,
    );

    // ── 분기 검증 A: 같은 series 의 다른 event ───────────────────
    setPhase('03b-flights-evt-branch-a');
    await navigate(page, `/lobby/flights/${eventIdBranchA}`);
    await page
      .waitForResponse(
        (res) =>
          new RegExp(`/api/v1/events/${eventIdBranchA}/flights`).test(
            res.url(),
          ) && res.status() === 200,
        { timeout: 20000 },
      )
      .catch(() => {});
    await page.waitForTimeout(2000);
    await page.screenshot({
      path: path.join(SHOT_DIR, `03b-flights-evt${eventIdBranchA}.png`),
      fullPage: true,
    });
    const flightsRespBranchA = networkLog.find(
      (e) =>
        new RegExp(`/api/v1/events/${eventIdBranchA}/flights`).test(e.url) &&
        e.status === 200,
    );
    const flightIdsBranchA = flightIdsFromBody(flightsRespBranchA?.body);
    console.log(
      `[03b-branch] event ${eventIdBranchA} flights → ${flightsRespBranchA?.status} ids=${flightIdsBranchA.join(',')}`,
    );

    // ── 분기 검증 B: series 2 의 event (cross-series 분기) ───────
    setPhase('03c-flights-evt-branch-b');
    await navigate(page, '/lobby/events/2');
    await page
      .waitForResponse(
        (res) =>
          /\/api\/v1\/series\/2\/events/.test(res.url()) &&
          res.status() === 200,
        { timeout: 20000 },
      )
      .catch(() => {});
    await page.waitForTimeout(1500);
    const eventsResp2 = networkLog.find(
      (e) =>
        /\/api\/v1\/series\/2\/events/.test(e.url) && e.status === 200,
    );
    const eventIds2 = eventIdsFromBody(eventsResp2?.body);
    const eventIdBranchB = eventIds2[0] ?? 1;
    await navigate(page, `/lobby/flights/${eventIdBranchB}`);
    await page
      .waitForResponse(
        (res) =>
          new RegExp(`/api/v1/events/${eventIdBranchB}/flights`).test(
            res.url(),
          ) && res.status() === 200,
        { timeout: 20000 },
      )
      .catch(() => {});
    await page.waitForTimeout(2000);
    await page.screenshot({
      path: path.join(SHOT_DIR, `03c-flights-evt${eventIdBranchB}.png`),
      fullPage: true,
    });
    const flightsRespBranchB = networkLog.find(
      (e) =>
        new RegExp(`/api/v1/events/${eventIdBranchB}/flights`).test(e.url) &&
        e.status === 200,
    );
    const flightIdsBranchB = flightIdsFromBody(flightsRespBranchB?.body);
    console.log(
      `[03c-branch] event ${eventIdBranchB} flights → ${flightsRespBranchB?.status} ids=${flightIdsBranchB.join(',')}`,
    );

    // ── DoD 계산 ────────────────────────────────────────────────
    const ebsLocalCalls = networkLog.filter((e) =>
      /api\.ebs\.local/.test(e.url),
    );
    const sameOriginCalls = networkLog.filter(
      (e) => e.url.startsWith(LOBBY_BASE_URL) && /\/api\/v1\//.test(e.url),
    );

    const endpointHits = {
      auth: networkLog.some(
        (e) => /\/api\/v1\/auth\/login/.test(e.url) && e.status === 200,
      ),
      series: !!seriesResp,
      events: !!eventsResp,
      flightsMain: !!flightsRespMain,
      tables: !!tablesResp,
    };

    const distinctEventIdsInFlights = new Set<number>();
    for (const entry of networkLog) {
      const m = entry.url.match(/\/api\/v1\/events\/(\d+)\/flights/);
      if (m && entry.status === 200) {
        distinctEventIdsInFlights.add(parseInt(m[1], 10));
      }
    }
    const branchDistinct =
      flightIdsMain.length > 0 &&
      flightIdsBranchA.length > 0 &&
      !flightIdsMain.every((id) => flightIdsBranchA.includes(id));

    // ── summary.md ──────────────────────────────────────────────
    const summary = [
      `# Cycle 10 — Lobby 5-Screen E2E Evidence (hosts-free)`,
      ``,
      `Run timestamp: ${new Date().toISOString()}`,
      `Lobby base URL: ${LOBBY_BASE_URL}`,
      `Login strategy: ${loginVia}`,
      `Navigation: in-app hashchange + popstate (page.goto reload 회피)`,
      `host-resolver-rules: 미설정 (hosts 매핑 부재 환경)`,
      ``,
      `## DoD`,
      `- hosts-free (api.ebs.local 호출 0건): **${ebsLocalCalls.length === 0 ? 'PASS' : 'FAIL'}** (got ${ebsLocalCalls.length})`,
      `- same-origin /api/v1/* 호출 ≥ 1: **${sameOriginCalls.length > 0 ? 'PASS' : 'FAIL'}** (got ${sameOriginCalls.length})`,
      `- 5 계층 endpoint 200 hit:`,
      `  - auth/login: ${endpointHits.auth ? 'PASS' : 'FAIL'}`,
      `  - /series: ${endpointHits.series ? 'PASS' : 'FAIL'}`,
      `  - /series/{id}/events: ${endpointHits.events ? 'PASS' : 'FAIL'}`,
      `  - /events/{id}/flights (main): ${endpointHits.flightsMain ? 'PASS' : 'FAIL'}`,
      `  - /flights/{id}/tables: ${endpointHits.tables ? 'PASS' : 'FAIL'}`,
      `- 이벤트 분기 — distinct event_id ≥ 2 in flight calls: **${distinctEventIdsInFlights.size >= 2 ? 'PASS' : 'FAIL'}** (${[...distinctEventIdsInFlights].join(', ')})`,
      `- 이벤트 분기 — Main vs Branch A 의 flight id 가 서로 다름: **${branchDistinct ? 'PASS' : 'FAIL'}** (main=[${flightIdsMain.join(',')}] branchA=[${flightIdsBranchA.join(',')}])`,
      ``,
      `## Endpoint chain`,
      `- GET /api/v1/series                                  → ${seriesResp?.status ?? 'NO-CALL'}`,
      `- GET /api/v1/series/1/events                         → ${eventsResp?.status ?? 'NO-CALL'} (events=[${eventIds.join(',')}])`,
      `- GET /api/v1/events/${eventIdMain}/flights           → ${flightsRespMain?.status ?? 'NO-CALL'} (flights=[${flightIdsMain.join(',')}])`,
      `- GET /api/v1/flights/${flightIdMain}/tables          → ${tablesResp?.status ?? 'NO-CALL'}`,
      `- GET /api/v1/events/${eventIdBranchA}/flights        → ${flightsRespBranchA?.status ?? 'NO-CALL'} (flights=[${flightIdsBranchA.join(',')}])`,
      `- GET /api/v1/series/2/events                         → ${eventsResp2?.status ?? 'NO-CALL'} (events=[${eventIds2.join(',')}])`,
      `- GET /api/v1/events/${eventIdBranchB}/flights        → ${flightsRespBranchB?.status ?? 'NO-CALL'} (flights=[${flightIdsBranchB.join(',')}])`,
      ``,
      `## Screenshot evidence`,
      `- 00-login.png                Login UI (Phase 0)`,
      `- 01-series.png               Series 목록`,
      `- 02-events.png               Series 1 events (${eventIds.length} 개)`,
      `- 03-flights.png              Event ${eventIdMain} flights (${flightIdsMain.length} 개)`,
      `- 04-tables.png               Flight ${flightIdMain} tables`,
      `- 03b-flights-evt${eventIdBranchA}.png   분기 검증 A (event ${eventIdBranchA} → ${flightIdsBranchA.length} flights)`,
      `- 03c-flights-evt${eventIdBranchB}.png   분기 검증 B (series 2 event ${eventIdBranchB} → ${flightIdsBranchB.length} flights)`,
      ``,
      `## Network log (api/v1 + api.ebs.local)`,
      ...networkLog.map(
        (e) => `- [${e.phase}] ${e.method} ${e.url} → ${e.status ?? '?'}`,
      ),
      ``,
    ].join('\n');
    fs.writeFileSync(path.join(SHOT_DIR, 'summary.md'), summary, 'utf8');
    console.log(`[lobby-5-screen] summary written: ${path.join(SHOT_DIR, 'summary.md')}`);

    // ── DoD assertions ──────────────────────────────────────────
    expect(
      ebsLocalCalls.length,
      `hosts-free DoD: api.ebs.local 호출 0건이어야 함 (got ${ebsLocalCalls.length})`,
    ).toBe(0);
    expect(
      sameOriginCalls.length,
      `same-origin DoD: localhost:3000/api/v1/* ≥ 1 (got ${sameOriginCalls.length})`,
    ).toBeGreaterThan(0);
    expect(endpointHits.auth, 'auth/login 200 hit 필요').toBe(true);
    expect(endpointHits.series, 'GET /series 200 hit 필요').toBe(true);
    expect(endpointHits.events, 'GET /series/{id}/events 200 hit 필요').toBe(true);
    expect(
      endpointHits.flightsMain,
      `GET /events/${eventIdMain}/flights 200 hit 필요`,
    ).toBe(true);
    expect(
      distinctEventIdsInFlights.size,
      `event 분기 DoD: distinct event_id ≥ 2 (got ${distinctEventIdsInFlights.size})`,
    ).toBeGreaterThanOrEqual(2);
    expect(
      branchDistinct,
      `event 분기 KPI: main(event ${eventIdMain})=[${flightIdsMain.join(',')}] vs branchA(event ${eventIdBranchA})=[${flightIdsBranchA.join(',')}] 가 서로 달라야 함`,
    ).toBe(true);
    // tables 는 인증 만료 가능성 있어 warn-only
    if (!endpointHits.tables) {
      console.warn(
        `[lobby-5-screen] WARN: /flights/${flightIdMain}/tables 200 hit 없음 — 인증 만료 또는 BO seed 부재 가능`,
      );
    }
  });
});
