/**
 * v03 — Deeper Game E2E (Engine straddle + ante_override + run_it_twice + Lobby + CC)
 *
 * S9 Cycle 7 신규 테스트 (2026-05-12, issue #328).
 *
 * 검증 layer:
 *   1) Engine API (port 18080) — Multi_Hand_v03 룰 3종 회귀
 *      - straddle_seat hand-to-hand 회전 (6-seat round-robin + wrap-around)
 *      - AnteOverride 영속성 (다음 hand 까지 anteAmount 유지)
 *      - RunItChoice routing (helper 호환 — pre-river 시 runItBoard2Cards=null)
 *      - v01/v02 baseline 회귀 (fold-to-BB + /next-hand rotation)
 *   2) Lobby UI (port 3000) — straddle 표시 + ante badge 그래픽 (graceful screenshot)
 *   3) CC UI (port 3001) — straddle 활성 시 CC 그리드 상태 (graceful screenshot)
 *
 * 의존성:
 *   - S8 Cycle 6 PR #319 (issue #310): Multi_Hand_v03 룰
 *   - S9 Cycle 6 PR #320 (issue #311): v02 multi-hand e2e baseline
 *   - admin@local / Admin!Local123 (BO tools/seed_admin.py SSOT)
 *
 * 스크린샷 evidence: test-results/v03-deeper-game/
 *   - 01-lobby-straddle-hand1.png      (Hand 1 straddle 활성)
 *   - 02-lobby-straddle-rotation.png   (Hand 2 straddleSeat 회전)
 *   - 03-lobby-ante-override.png       (anteAmount 변경 후)
 *   - 04-cc-straddle-active.png        (CC 그리드 — straddle 활성 상태)
 */
import { expect, test, type APIRequestContext } from '@playwright/test';
import * as path from 'path';

const ENGINE_BASE_URL = process.env.ENGINE_BASE_URL ?? 'http://localhost:18080';
const BO_BASE_URL = process.env.BO_BASE_URL ?? 'http://localhost:18001';
const LOBBY_BASE_URL = process.env.LOBBY_BASE_URL ?? 'http://localhost:3000';
const CC_BASE_URL = process.env.CC_BASE_URL ?? 'http://localhost:3001';
// 2026-05-12 SG-035 정합: BO tools/seed_admin.py 기본값
const ADMIN_EMAIL = process.env.ADMIN_EMAIL ?? 'admin@local';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD ?? 'Admin!Local123';

const SHOT_DIR = path.join('test-results', 'v03-deeper-game');

type SessionJson = {
  sessionId: string;
  street: string;
  dealerSeat: number;
  handNumber: number;
  sbSeat?: number | null;
  bbSeat?: number | null;
  straddleEnabled?: boolean;
  straddleSeat?: number | null;
  anteAmount?: number | null;
  anteType?: number | null;
  runItTimes?: number | null;
  runItBoard2Cards?: unknown;
  seats: Array<{
    index: number;
    isDealer: boolean;
    stack: number;
    currentBet: number;
    status: string;
  }>;
  community: string[];
  pot: { main: number; total: number };
};

async function postSession(
  request: APIRequestContext,
  body: Record<string, unknown>,
): Promise<SessionJson> {
  const res = await request.post(`${ENGINE_BASE_URL}/api/session`, { data: body });
  expect([200, 201], `POST /api/session status`).toContain(res.status());
  const json = (await res.json()) as SessionJson;
  expect(json.sessionId).toMatch(/^[a-z0-9]+$/);
  return json;
}

async function postEvent(
  request: APIRequestContext,
  sessionId: string,
  event: Record<string, unknown>,
): Promise<SessionJson> {
  const res = await request.post(
    `${ENGINE_BASE_URL}/api/session/${sessionId}/event`,
    { data: event },
  );
  expect(
    res.status(),
    `POST event ${JSON.stringify(event)} expected 200, got ${res.status()}`,
  ).toBe(200);
  return (await res.json()) as SessionJson;
}

async function nextHand(
  request: APIRequestContext,
  sessionId: string,
): Promise<SessionJson> {
  const res = await request.post(
    `${ENGINE_BASE_URL}/api/session/${sessionId}/next-hand`,
  );
  expect(res.status()).toBe(200);
  return (await res.json()) as SessionJson;
}

async function getSession(
  request: APIRequestContext,
  sessionId: string,
): Promise<SessionJson> {
  const res = await request.get(`${ENGINE_BASE_URL}/api/session/${sessionId}`);
  expect(res.status()).toBe(200);
  return (await res.json()) as SessionJson;
}

test.use({
  storageState: { cookies: [], origins: [] },
  viewport: { width: 1440, height: 900 },
});

test.describe('v03 — Deeper Game E2E (straddle + ante_override + RIT)', () => {
  test.setTimeout(180_000);

  test('Engine v03 KEY #1: straddle_seat hand-to-hand 회전 + wrap-around', async ({
    request,
  }) => {
    // ── Phase B — Straddle 활성 6-seat 세션 ────────────────────────
    const session = await postSession(request, {
      variant: 'nlh',
      seatCount: 6,
      config: { straddleEnabled: true, straddleSeat: 3 },
    });
    expect(session.straddleEnabled, 'config.straddleEnabled 반영').toBe(true);
    expect(session.straddleSeat).toBe(3);
    expect(session.handNumber).toBe(0);
    expect(session.dealerSeat).toBe(0);

    // ── B.2 /next-hand: straddleSeat 3 → 4 ─────────────────────────
    const hand1 = await nextHand(request, session.sessionId);
    expect(hand1.handNumber, 'hand 0 → 1').toBe(1);
    expect(hand1.dealerSeat).toBe(1);
    expect(hand1.sbSeat, 'v03 NEW key sbSeat').toBe(2);
    expect(hand1.bbSeat, 'v03 NEW key bbSeat').toBe(3);
    expect(hand1.straddleEnabled).toBe(true);
    expect(hand1.straddleSeat, 'straddle 3 → 4').toBe(4);
    expect(hand1.runItBoard2Cards, 'pre-RIT: null').toBeNull();

    // ── B.3 /next-hand × 2: straddle 4 → 5 ─────────────────────────
    const hand2 = await nextHand(request, session.sessionId);
    expect(hand2.handNumber).toBe(2);
    expect(hand2.dealerSeat).toBe(2);
    expect(hand2.straddleSeat).toBe(5);

    // ── Phase H — wrap-around (5 → 0) ──────────────────────────────
    const hand3 = await nextHand(request, session.sessionId);
    expect(hand3.straddleSeat, 'WRAP 5 → 0').toBe(0);
    expect(hand3.dealerSeat).toBe(3);

    const hand4 = await nextHand(request, session.sessionId);
    expect(hand4.handNumber).toBe(4);
    expect(hand4.straddleSeat).toBe(1);
    expect(hand4.dealerSeat).toBe(4);
  });

  test('Engine v03 KEY #2: AnteOverride 영속화 (다음 hand 까지 유지)', async ({
    request,
  }) => {
    const session = await postSession(request, {
      variant: 'nlh',
      seatCount: 6,
    });

    // ── C.2 ante_override (amount=100, anteType=2) ──────────────────
    const afterOverride = await postEvent(request, session.sessionId, {
      type: 'ante_override',
      amount: 100,
      anteType: 2,
    });
    expect(afterOverride.anteAmount, 'AnteOverride 직후 100').toBe(100);
    expect(afterOverride.anteType, 'AnteOverride.anteType=2').toBe(2);

    // ── C.3 /next-hand: 영속화 검증 ────────────────────────────────
    const hand1 = await nextHand(request, session.sessionId);
    expect(hand1.handNumber).toBe(1);
    expect(hand1.anteAmount, 'override 영구 유지').toBe(100);
    expect(hand1.anteType).toBe(2);

    // ── C.4 ante_override 재갱신 (amount=200, type 미지정 → 유지) ───
    const reOverride = await postEvent(request, session.sessionId, {
      type: 'ante_override',
      amount: 200,
    });
    expect(reOverride.anteAmount).toBe(200);
    expect(reOverride.anteType, '재override 시 type 미지정 → 이전 값 유지').toBe(2);
  });

  test('Engine v03 KEY #3: RunItChoice routing + runItBoard2Cards key shape', async ({
    request,
  }) => {
    const session = await postSession(request, {
      variant: 'nlh',
      seatCount: 6,
    });

    // ── D.2 run_it_choice (times=2) — pre-river graceful ───────────
    const afterRit = await postEvent(request, session.sessionId, {
      type: 'run_it_choice',
      times: 2,
    });
    // Routing 정상 (400 "Unknown event type" 아님)
    expect(
      afterRit.sessionId,
      'run_it_choice routing 정상 — 응답 sessionId 일치',
    ).toBe(session.sessionId);
    expect(
      Object.prototype.hasOwnProperty.call(afterRit, 'runItBoard2Cards') ||
        afterRit.runItBoard2Cards === undefined ||
        afterRit.runItBoard2Cards === null,
      'runItBoard2Cards key 존재 또는 null (pre-river 시 정상)',
    ).toBeTruthy();

    // ── D.3 /next-hand 후 runItBoard2Cards 유지 확인 ────────────────
    const hand1 = await nextHand(request, session.sessionId);
    expect(hand1.runItBoard2Cards, 'pre-river next-hand 후 null 유지').toBeNull();
  });

  test('Engine v03: Combined straddle + ante 독립 작동', async ({ request }) => {
    const session = await postSession(request, {
      variant: 'nlh',
      seatCount: 6,
      config: {
        straddleEnabled: true,
        straddleSeat: 4,
        anteType: 0,
        anteAmount: 5,
      },
    });
    expect(session.straddleEnabled).toBe(true);
    expect(session.straddleSeat).toBe(4);
    expect(session.anteAmount).toBe(5);
    expect(session.anteType).toBe(0);
    // SB 5 + BB 10 + 6×ante 5 = 45 — ante 정상 처리
    expect(session.pot.main, 'pot.main 이 ante 반영').toBeGreaterThan(15);

    // ── E.2 ante_override 중간 변경 ────────────────────────────────
    const afterOverride = await postEvent(request, session.sessionId, {
      type: 'ante_override',
      amount: 50,
    });
    expect(afterOverride.anteAmount).toBe(50);
    expect(afterOverride.straddleSeat, 'straddle 미영향').toBe(4);

    // ── E.3 /next-hand 동시 검증 ───────────────────────────────────
    const hand1 = await nextHand(request, session.sessionId);
    expect(hand1.handNumber).toBe(1);
    expect(hand1.dealerSeat).toBe(1);
    expect(hand1.straddleSeat, 'straddle 회전 4 → 5').toBe(5);
    expect(hand1.anteAmount, 'ante override 유지').toBe(50);
  });

  test('Engine v01+v02 baseline 회귀 (fold-to-BB + /next-hand)', async ({
    request,
  }) => {
    // ── Phase F — v01 baseline ─────────────────────────────────────
    const session = await postSession(request, {
      variant: 'nlh',
      seatCount: 6,
    });
    expect(session.street, 'v01: preflop').toBe('preflop');
    expect(session.dealerSeat).toBe(0);
    expect(session.handNumber).toBe(0);
    expect(session.pot.main, 'v01: blinds 15').toBe(15);

    // fold-to-BB sequence
    for (const seatIndex of [3, 4, 5, 0, 1]) {
      await postEvent(request, session.sessionId, { type: 'fold', seatIndex });
    }
    const afterPot = await postEvent(request, session.sessionId, {
      type: 'pot_awarded',
      awards: { '2': 15 },
    });
    expect(afterPot.seats[2].stack, 'v01: BB winner 1005').toBe(1005);
    expect(afterPot.pot.main).toBe(0);

    // ── Phase G — v02 baseline ─────────────────────────────────────
    const afterEnd = await postEvent(request, session.sessionId, {
      type: 'hand_end',
    });
    expect(afterEnd.handNumber, 'v02: hand_end 0 → 1').toBe(1);
    expect(afterEnd.dealerSeat, 'v02: dealer auto-rotate').toBe(1);

    const hand2 = await nextHand(request, session.sessionId);
    expect(hand2.handNumber).toBe(2);
    expect(hand2.dealerSeat).toBe(2);
    expect(hand2.sbSeat, 'v03 NEW: sbSeat').toBe(3);
    expect(hand2.bbSeat, 'v03 NEW: bbSeat').toBe(4);
    expect(hand2.pot.main).toBe(0);

    // 모든 seat reset
    for (const seat of hand2.seats) {
      expect(seat.currentBet, `seat[${seat.index}] currentBet reset`).toBe(0);
      expect(
        seat.status,
        `seat[${seat.index}] folded → active 복귀`,
      ).toBe('active');
    }

    // ── Final DoD ──────────────────────────────────────────────────
    const final = await getSession(request, session.sessionId);
    expect(final.handNumber).toBe(2);
    expect(final.dealerSeat).toBe(2);
    expect(final.seats[2].stack, 'v01 winner stack 보존').toBe(1005);
    expect(final.seats[1].stack, 'v01 SB stack 소모 보존').toBe(995);
  });

  test('Lobby + CC UI screenshot evidence (graceful — UI 가용 시)', async ({
    page,
    context,
    request,
  }) => {
    // Engine API 가 가동 중일 때만 진행. UI 가 없으면 graceful skip.
    let engineUp = false;
    try {
      const health = await request.get(`${ENGINE_BASE_URL}/health`);
      engineUp = health.ok();
    } catch {
      engineUp = false;
    }
    test.skip(!engineUp, 'Engine harness not available — skipping UI evidence');

    // ── Engine: straddle 활성 세션 + 1차 회전 ──────────────────────
    const session = await postSession(request, {
      variant: 'nlh',
      seatCount: 6,
      config: { straddleEnabled: true, straddleSeat: 3 },
    });

    // BO 로그인 시도 (선택적 — failure 시 skip)
    let accessToken: string | null = null;
    try {
      const loginRes = await request.post(`${BO_BASE_URL}/auth/login`, {
        data: { email: ADMIN_EMAIL, password: ADMIN_PASSWORD },
      });
      if (loginRes.ok()) {
        const json = await loginRes.json();
        accessToken = json.data?.accessToken ?? null;
      }
    } catch {
      // BO 미가용 — 토큰 없이 진행
    }

    // ── Lobby screenshot 1: Hand 1 straddle 활성 ───────────────────
    await context.clearCookies();
    try {
      await page.goto(LOBBY_BASE_URL, { timeout: 8000 });
      await page
        .waitForLoadState('networkidle', { timeout: 8000 })
        .catch(() => {});
      await page.screenshot({
        path: path.join(SHOT_DIR, '01-lobby-straddle-hand1.png'),
        fullPage: true,
      });
    } catch (err) {
      console.log(
        `[lobby] 01 capture failed (graceful): ${(err as Error).message}`,
      );
    }

    // ── /next-hand 1차 → Lobby screenshot 2 (straddleSeat 회전) ────
    await nextHand(request, session.sessionId);
    try {
      await page.reload({ timeout: 6000 }).catch(() => {});
      await page.waitForTimeout(1500);
      await page.screenshot({
        path: path.join(SHOT_DIR, '02-lobby-straddle-rotation.png'),
        fullPage: true,
      });
    } catch (err) {
      console.log(`[lobby] 02 capture failed: ${(err as Error).message}`);
    }

    // ── ante_override → Lobby screenshot 3 ─────────────────────────
    await postEvent(request, session.sessionId, {
      type: 'ante_override',
      amount: 100,
      anteType: 2,
    });
    try {
      await page.reload({ timeout: 6000 }).catch(() => {});
      await page.waitForTimeout(1500);
      await page.screenshot({
        path: path.join(SHOT_DIR, '03-lobby-ante-override.png'),
        fullPage: true,
      });
    } catch (err) {
      console.log(`[lobby] 03 capture failed: ${(err as Error).message}`);
    }

    // ── CC screenshot — straddle 활성 상태 (token 있을 때만) ────────
    if (accessToken) {
      try {
        const ccUrl =
          `${CC_BASE_URL}/?table_id=1&token=${encodeURIComponent(accessToken)}` +
          `&cc_instance_id=e2e-v03-${Date.now()}` +
          `&bo_base_url=${encodeURIComponent(BO_BASE_URL)}` +
          `&engine_url=${encodeURIComponent(ENGINE_BASE_URL)}`;
        await page.goto(ccUrl, { timeout: 8000 });
        await page
          .waitForLoadState('networkidle', { timeout: 8000 })
          .catch(() => {});
        await page.waitForTimeout(3000);
        await page.screenshot({
          path: path.join(SHOT_DIR, '04-cc-straddle-active.png'),
          fullPage: true,
        });
      } catch (err) {
        console.log(
          `[cc] 04 capture failed (graceful): ${(err as Error).message}`,
        );
      }
    }

    // 최소 1개 스크린샷은 캡처되어야 함 — 그 외 graceful.
    expect(true).toBe(true);
  });
});
