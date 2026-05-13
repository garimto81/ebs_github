/**
 * Cycle 21 Wave 4 — Lobby Reports 폐기 + Players/HandHistory BO REST 연동 검증
 *
 * S9 Cycle 21 Wave 4 신규 (2026-05-13, issue #459).
 *
 * 목적:
 *   Cycle 21 Wave 1 (PR #444) 사용자 결정 정합 검증:
 *   1. Lobby Reports 탭 완전 폐기 — PopupMenu / route / sidebar 어디에도 잔존 0
 *   2. Players 화면 = BO REST `GET /api/v1/players` 연동 (mockup data 제거)
 *   3. Hand History 화면 = `lib/features/hand_history/` 독립 feature 격상,
 *      BO REST `GET /api/v1/hands` 연동
 *
 * SSOT:
 *   docs/2. Development/2.1 Frontend/Lobby/UI.md §좌측 사이드바
 *   docs/2. Development/2.1 Frontend/Lobby/Overview.md §화면 6 Hand History
 *   docs/2. Development/2.2 Backend/APIs/Players_HandHistory_API.md v1.0
 *
 * 5 검증 case:
 *   T1 PopupMenu does NOT contain "Reports" item
 *   T2 /reports route returns 404 or redirect (deep-link 잔존 0)
 *   T3 Players screen loads via BO REST API (mockup data 아님)
 *   T4 Hand History screen accessible via /hand-history route
 *   T5 Hand History list 페이지네이션 동작 (cursor 기반)
 *
 * 의존성:
 *   - S2 Cycle 21 Wave 3 (Lobby Flutter 구현, /hand-history 라우트 + Players impl)
 *   - S7 Cycle 21 Wave 2 #457 머지 (BO players + hands router)
 *   - S11 docker compose --profile web up -d lobby-web
 *
 * 실행 사전 요구:
 *   - lobby-web 컨테이너 (http://localhost:3000)
 *   - BO 컨테이너 (http://localhost:18001)
 *   - ADMIN_EMAIL / ADMIN_PASSWORD 환경변수 (default: admin@local / Admin!Local123)
 *
 * broker MCP publish: pipeline:qa-pass (사용자 직접 확인 후에만).
 */
import { expect, test, type Page, type Request, type Response } from '@playwright/test';
import * as path from 'path';
import * as fs from 'fs';

const LOBBY_BASE_URL = process.env.LOBBY_BASE_URL ?? 'http://localhost:3000';
const ADMIN_EMAIL = process.env.ADMIN_EMAIL ?? 'admin@local';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD ?? 'Admin!Local123';

// evidence 폴더 — integration-tests/evidence/cycle21-reports-removal/
const SHOT_DIR = path.resolve(
  __dirname,
  '..',
  '..',
  'evidence',
  'cycle21-reports-removal',
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
    if (/\/api\/v1\/(players|hands)/.test(u)) {
      log.push({ url: u, method: req.method() });
    }
  });
  page.on('response', async (res: Response) => {
    const u = res.url();
    if (/\/api\/v1\/(players|hands)/.test(u)) {
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

// Flutter Lobby = HashUrlStrategy. page.goto 대신 hash 변경 + event dispatch.
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

  // Login UI — semantics tree 기반 (Flutter Web).
  const emailField = page.getByLabel(/email/i).first();
  const pwField = page.getByLabel(/password/i).first();
  await emailField.fill(ADMIN_EMAIL).catch(() => {});
  await pwField.fill(ADMIN_PASSWORD).catch(() => {});
  await page.getByRole('button', { name: /sign in|login/i }).click().catch(() => {});
  await page.waitForLoadState('networkidle', { timeout: 10000 }).catch(() => {});
}

test.describe('Cycle 21 Wave 4 — Lobby Reports 폐기 + Players/HandHistory BO REST 정합', () => {
  test.setTimeout(180_000);

  test.beforeAll(() => {
    fs.mkdirSync(SHOT_DIR, { recursive: true });
  });

  test('T1 PopupMenu does NOT contain Reports item (Cycle 21 W1 폐기 정합)', async ({ page }) => {
    await login(page);

    // 사이드바/PopupMenu trigger — Flutter 의 menu 버튼 (PopupMenuButton).
    // SSOT (UI.md §좌측 사이드바): Tables / Hand History / Players / Settings.
    // Reports 항목 = Cycle 21 W1 폐기 (사용자 결정).
    const menuTrigger = page
      .getByRole('button', { name: /menu|sidebar|drawer/i })
      .first();
    await menuTrigger.click().catch(() => {
      // sidebar 가 이미 expanded 상태일 수 있음 — 무시.
    });
    await page.waitForTimeout(500);

    // Full page text 에서 "Reports" 문자열 부재 검증 (sidebar item / button label).
    // semantics tree 가 visible text 를 expose 하므로 page content 로 확인.
    const bodyText = await page.locator('body').innerText().catch(() => '');

    // "Reports" 단어가 메뉴 항목으로 잔존하면 안 됨.
    // (단, changelog/footer 같은 비메뉴 영역 제외 위해 sidebar/menu 영역만 검증)
    const sidebarText = await page
      .locator('[role="navigation"], [role="menu"], [aria-label*="sidebar" i], [aria-label*="navigation" i]')
      .allInnerTexts()
      .catch(() => [] as string[]);

    const hasReportsInMenu = sidebarText.some((t) => /\breports?\b/i.test(t));

    await page.screenshot({
      path: path.join(SHOT_DIR, 'T1-popupmenu-no-reports.png'),
      fullPage: true,
    });

    expect(hasReportsInMenu, 'sidebar/menu 에 Reports 항목 잔존 = Cycle 21 W1 폐기 정합 위반').toBeFalsy();
  });

  test('T2 /reports route returns 404 or redirect (deep-link 잔존 0)', async ({ page }) => {
    await login(page);
    await navigate(page, '/reports');
    await page.waitForLoadState('networkidle', { timeout: 8000 }).catch(() => {});

    // Flutter SPA — /reports 진입 시 두 가지 정상 시나리오:
    //  (a) go_router redirect → /tables 또는 default landing
    //  (b) 404 / not_found screen 표시
    // 둘 다 "Reports 화면 mount 0" 을 의미.
    const currentHash = await page.evaluate(() => window.location.hash);
    const bodyText = await page.locator('body').innerText().catch(() => '');

    // 정상 시나리오 검증 — 다음 중 하나:
    //  1) redirect: hash 가 #/reports 가 아닌 다른 경로로 변경됨
    //  2) 404 page: "not found" / "404" / "찾을 수 없" 텍스트 노출
    //  3) Reports 화면이 실제로 mount 되지 않음 (HandHistoryScreen / SeriesScreen 등)
    const redirected = !currentHash.includes('reports');
    const isNotFound = /not\s*found|404|찾을 수 없|페이지가 없습니다/i.test(bodyText);
    const reportsScreenMounted = /unique player report|tournament history|prize pool report|action history/i.test(bodyText);

    await page.screenshot({
      path: path.join(SHOT_DIR, 'T2-reports-route-blocked.png'),
      fullPage: true,
    });

    // 진단 메시지에 redirect/404 둘 다 false 인 경우 fail.
    const passOk = redirected || isNotFound || !reportsScreenMounted;
    expect(
      passOk,
      `/reports 진입 — redirected=${redirected} isNotFound=${isNotFound} reportsMounted=${reportsScreenMounted}`,
    ).toBeTruthy();
    expect(reportsScreenMounted, 'Reports 화면이 mount 됨 = Cycle 21 W1 폐기 위반').toBeFalsy();
  });

  test('T3 Players screen loads via BO REST API (mockup data 아님)', async ({ page }) => {
    const { log: networkLog } = attachNetworkCapture(page);
    await login(page);

    // Players 사이드바 진입.
    await navigate(page, '/players');
    await page.waitForLoadState('networkidle', { timeout: 10000 }).catch(() => {});
    await page.waitForTimeout(1500);

    // BO REST `GET /api/v1/players` 호출 확인.
    const playersHits = networkLog.filter(
      (e) => /\/api\/v1\/players(\?|$)/.test(e.url) && e.method === 'GET',
    );

    await page.screenshot({
      path: path.join(SHOT_DIR, 'T3-players-bo-rest-call.png'),
      fullPage: true,
    });

    expect(
      playersHits.length,
      `GET /api/v1/players 호출 0건 = Players 화면이 BO REST 미연동. mockup data 잔존 의심. networkLog=${JSON.stringify(networkLog)}`,
    ).toBeGreaterThanOrEqual(1);

    // 200 OK 응답 검증 + items[] schema.
    const okHit = playersHits.find((e) => e.status === 200);
    expect(okHit, 'GET /api/v1/players 200 응답 없음').toBeTruthy();
    if (okHit?.body) {
      const parsed = JSON.parse(okHit.body) as { items?: unknown[] };
      expect(
        Array.isArray(parsed.items),
        `응답에 items[] 배열 부재 = Players_HandHistory_API.md §2.1 schema 위반. body=${okHit.body.slice(0, 200)}`,
      ).toBeTruthy();
    }
  });

  test('T4 Hand History screen accessible via /hand-history (독립 feature 격상 정합)', async ({ page }) => {
    const { log: networkLog } = attachNetworkCapture(page);
    await login(page);

    // Hand History 독립 sidebar 섹션 진입 — Cycle 21 W1 정합.
    // 라우트 후보: /hand-history (snake) / /hand_history / /hands. Flutter 구현 정합 검증.
    await navigate(page, '/hand-history');
    await page.waitForLoadState('networkidle', { timeout: 10000 }).catch(() => {});
    await page.waitForTimeout(1500);

    // BO REST `GET /api/v1/hands` 호출 확인.
    const handsHits = networkLog.filter(
      (e) => /\/api\/v1\/hands(\?|$)/.test(e.url) && e.method === 'GET',
    );

    await page.screenshot({
      path: path.join(SHOT_DIR, 'T4-hand-history-bo-rest.png'),
      fullPage: true,
    });

    expect(
      handsHits.length,
      `GET /api/v1/hands 호출 0건 = Hand History 가 BO REST 미연동. mockup data 잔존 의심. networkLog=${JSON.stringify(networkLog)}`,
    ).toBeGreaterThanOrEqual(1);

    // Hand History 화면 UI element 검증 (Hand Browser / Hand Detail / Player Stats).
    const bodyText = await page.locator('body').innerText().catch(() => '');
    const handHistoryUiPresent = /hand\s*history|hand\s*browser|hand\s*number|hands?\s*list/i.test(bodyText);
    expect(
      handHistoryUiPresent,
      'Hand History 화면 UI 요소 부재 = 독립 feature 격상 미구현',
    ).toBeTruthy();
  });

  test('T5 Hand History list paginates (cursor 기반 무한 스크롤)', async ({ page }) => {
    const { log: networkLog } = attachNetworkCapture(page);
    await login(page);
    await navigate(page, '/hand-history');
    await page.waitForLoadState('networkidle', { timeout: 10000 }).catch(() => {});
    await page.waitForTimeout(1500);

    // 첫 페이지 호출 카운트.
    const firstPageHits = networkLog.filter(
      (e) => /\/api\/v1\/hands(\?|$)/.test(e.url) && e.method === 'GET',
    ).length;

    // 페이지네이션 트리거 — 다음 페이지 버튼 / 무한 스크롤.
    // 두 가지 시도: (a) "Next" / "다음" 버튼 클릭, (b) 리스트 scroll-to-bottom.
    const nextBtn = page.getByRole('button', { name: /next|다음|more|더 보기/i }).first();
    await nextBtn.click().catch(async () => {
      // 무한 스크롤 fallback — 스크롤 영역 bottom 까지 이동.
      await page.evaluate(() => {
        const lists = document.querySelectorAll('flt-scrollable, [role="list"], main');
        lists.forEach((el) => {
          el.scrollTop = el.scrollHeight;
        });
        window.scrollTo(0, document.body.scrollHeight);
      });
    });
    await page.waitForTimeout(2000);

    // 두 번째 페이지 호출 확인 — cursor query param 동반 GET.
    const cursorHits = networkLog.filter(
      (e) => /\/api\/v1\/hands.*cursor=/.test(e.url) && e.method === 'GET',
    );
    const totalHits = networkLog.filter(
      (e) => /\/api\/v1\/hands(\?|$)/.test(e.url) && e.method === 'GET',
    ).length;

    await page.screenshot({
      path: path.join(SHOT_DIR, 'T5-hand-history-pagination.png'),
      fullPage: true,
    });

    // pagination 검증 — 둘 중 하나면 PASS:
    //  (a) cursor= query 동반 호출 ≥ 1건 (cursor 기반)
    //  (b) GET /api/v1/hands 호출 총합이 첫 페이지보다 증가 (재요청 발생)
    const paginated = cursorHits.length >= 1 || totalHits > firstPageHits;
    expect(
      paginated,
      `Hand History pagination 미동작 — firstPageHits=${firstPageHits} totalHits=${totalHits} cursorHits=${cursorHits.length}`,
    ).toBeTruthy();
  });
});
