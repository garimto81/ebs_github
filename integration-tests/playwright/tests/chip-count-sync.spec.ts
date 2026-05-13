/**
 * Cycle 20 Wave 4 — WSOP LIVE Chip Count Sync E2E (issue #447)
 *
 * SSOT 의 5 인수 기준을 모두 5 개 테스트로 매핑한다:
 *   A) webhook 도착 → CC seat_cell.stack 갱신 + amber tint 1s 표시
 *   B) HMAC 위반 → 401 SIGNATURE_INVALID
 *   C) Replay attack (timestamp drift > 300s) → 401 TIMESTAMP_DRIFT
 *   D) 동일 Idempotency-Key 재전송 → 200 already_processed (DB 변화 없음)
 *   E) WS broadcast — 다중 client 가 chip_count_synced 수신
 *
 * SSOT pointer:
 *   - docs/2. Development/2.2 Backend/APIs/WSOP_LIVE_Chip_Count_Sync.md  (v1.0.0)
 *   - docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md §4.2.11   (chip_count_synced)
 *   - docs/2. Development/2.5 Shared/Chip_Count_State.md                 (state machine)
 *
 * 실 실행 사전 요구:
 *   - BO container :18001 + lobby :3000 + CC :3001 healthy
 *   - WSOP_LIVE_WEBHOOK_SECRET 환경 변수 (BO 와 동일한 값)
 *   - admin@local / Admin!Local123 (BO tools/seed_admin.py 기본값)
 *   - 테이블 17 사전 시드 (또는 SEED_TABLE_ID env override)
 *
 * 본 cycle 의 S9 가이드에 따라 실 실행은 하지 않는다 (live backend 없음).
 * `npx playwright test --list` 로 testRegistry 등록만 검증.
 * 환경 변수 미존재 시 모든 테스트는 graceful skip (CI green 보장).
 */
import { expect, test, type APIRequestContext, type Page } from '@playwright/test';
import { createHash, createHmac, randomUUID } from 'crypto';

// ── Environment ────────────────────────────────────────────────────────
const BO_BASE_URL = process.env.BO_BASE_URL ?? 'http://localhost:18001';
const CC_BASE_URL = process.env.CC_BASE_URL ?? 'http://localhost:3001';
const ADMIN_EMAIL = process.env.ADMIN_EMAIL ?? 'admin@local';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD ?? 'Admin!Local123';
const WEBHOOK_SECRET = process.env.WSOP_LIVE_WEBHOOK_SECRET ?? '';
const SEED_TABLE_ID = Number(process.env.SEED_TABLE_ID ?? '17');
const ENDPOINT = '/api/wsop-live/chip-count-snapshot';

const HAS_LIVE_BACKEND = process.env.E2E_LIVE_BACKEND === '1';
const HAS_SECRET = WEBHOOK_SECRET.length > 0;

// ── Helpers ────────────────────────────────────────────────────────────

type Seat = { seat_number: number; player_id: number | null; chip_count: number };

type SnapshotBody = {
  snapshot_id: string;
  break_id: number;
  table_id: number;
  recorded_at: string;
  seats: Seat[];
};

function nowIso(offsetMs = 0): string {
  return new Date(Date.now() + offsetMs).toISOString();
}

function sha256Hex(input: string | Buffer): string {
  return createHash('sha256').update(input).digest('hex');
}

/**
 * WSOP_LIVE_Chip_Count_Sync.md §6.1 canonical HMAC:
 *   canonical = "POST\n" + path + "\n" + timestamp + "\n" + sha256(body_bytes).hex
 *   signature = hmac_sha256(secret, canonical).hex
 */
function computeHmac(
  timestampIso: string,
  bodyJson: string,
  secret: string,
): string {
  const canonical = `POST\n${ENDPOINT}\n${timestampIso}\n${sha256Hex(bodyJson)}`;
  return createHmac('sha256', secret).update(canonical).digest('hex');
}

function makeBody(overrides: Partial<SnapshotBody> = {}): SnapshotBody {
  const snapshot_id = overrides.snapshot_id ?? randomUUID();
  const recorded_at = overrides.recorded_at ?? nowIso();
  const seats = overrides.seats ?? [
    { seat_number: 1, player_id: 901, chip_count: 125000 },
    { seat_number: 2, player_id: 902, chip_count: 87500 },
    { seat_number: 3, player_id: null, chip_count: 0 },
    { seat_number: 4, player_id: 904, chip_count: 211000 },
    { seat_number: 5, player_id: 905, chip_count: 64000 },
    { seat_number: 6, player_id: 906, chip_count: 150500 },
    { seat_number: 7, player_id: 907, chip_count: 92000 },
    { seat_number: 8, player_id: 908, chip_count: 175500 },
    { seat_number: 9, player_id: 909, chip_count: 0 },
  ];
  return {
    snapshot_id,
    break_id: overrides.break_id ?? 1024,
    table_id: overrides.table_id ?? SEED_TABLE_ID,
    recorded_at,
    seats,
  };
}

type WebhookOpts = {
  body: SnapshotBody;
  signature?: string;
  timestamp?: string;
  idempotencyKey?: string;
};

async function postWebhook(
  request: APIRequestContext,
  opts: WebhookOpts,
): Promise<{ status: number; bodyJson: unknown }> {
  const bodyJson = JSON.stringify(opts.body);
  const timestamp = opts.timestamp ?? opts.body.recorded_at;
  const signature = opts.signature ?? computeHmac(timestamp, bodyJson, WEBHOOK_SECRET);
  const idempotencyKey = opts.idempotencyKey ?? opts.body.snapshot_id;

  const res = await request.post(`${BO_BASE_URL}${ENDPOINT}`, {
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'X-WSOP-Signature': signature,
      'X-WSOP-Timestamp': timestamp,
      'Idempotency-Key': idempotencyKey,
      'User-Agent': 'WSOPLive-ChipCountSync-S9-E2E/1.0.0',
    },
    data: bodyJson,
  });

  return { status: res.status(), bodyJson: await res.json().catch(() => null) };
}

async function loginAdmin(request: APIRequestContext): Promise<string> {
  // SSOT: Backend_HTTP.md L87 — /auth/* 는 root, /api/v1 prefix 없음
  const res = await request.post(`${BO_BASE_URL}/auth/login`, {
    data: { email: ADMIN_EMAIL, password: ADMIN_PASSWORD },
  });
  expect(res.status(), 'admin login should succeed').toBe(200);
  const body = await res.json();
  const token = body?.data?.accessToken as string | undefined;
  expect(token, 'accessToken in response').toBeTruthy();
  return token!;
}

async function openCcForTable(page: Page, tableId: number, token: string): Promise<void> {
  // CC UI 가 query string 토큰 또는 cookie/storage 토큰 양쪽을 지원한다고 가정.
  // 실제 구현 detail 은 S3 cycle 이 결정 — 본 helper 는 spec 시점의 placeholder.
  await page.addInitScript(([t]) => {
    try {
      window.localStorage.setItem('ebs_admin_token', String(t));
    } catch {
      /* storage unavailable — page-level token query string fallback */
    }
  }, [token]);
  await page.goto(`${CC_BASE_URL}/cc/${tableId}`);
  await page.waitForLoadState('domcontentloaded');
}

// ── Tests ──────────────────────────────────────────────────────────────

test.describe('Cycle 20 W4 — WSOP LIVE Chip Count Sync', () => {
  test.beforeAll(() => {
    if (!HAS_LIVE_BACKEND) {
      // 본 cycle 가이드: 실 실행 X. --list 로 등록만 검증.
      // CI 기본 mode = skip 전체. E2E_LIVE_BACKEND=1 + WSOP_LIVE_WEBHOOK_SECRET 시 활성.
    }
  });

  test.beforeEach(({}, testInfo) => {
    test.skip(
      !HAS_LIVE_BACKEND,
      `live backend 비활성 (E2E_LIVE_BACKEND≠1) — ${testInfo.title}: --list 등록만 검증`,
    );
    test.skip(
      !HAS_SECRET,
      `WSOP_LIVE_WEBHOOK_SECRET 미설정 — HMAC 계산 불가, ${testInfo.title} skip`,
    );
  });

  // ── A. Webhook 도착 → CC seat_cell.stack 갱신 + amber tint 1s ──────
  test('A: webhook fires → CC seat_cell stack updates with amber tint (1s)', async ({
    browser,
    request,
  }) => {
    const token = await loginAdmin(request);

    // 두 개 CC 페이지 (single-client 검증; multi-client 는 Test E)
    const ccContext = await browser.newContext();
    const ccPage = await ccContext.newPage();
    await openCcForTable(ccPage, SEED_TABLE_ID, token);

    // Baseline: seat 4 의 현재 stack 값 캡쳐
    const seat4 = ccPage.locator(`[data-seat="4"] [data-role="stack"]`);
    await expect(seat4, 'seat 4 stack indicator visible').toBeVisible({ timeout: 5_000 });
    const baselineText = (await seat4.innerText()).trim();

    // Webhook 발사 — seat 4 stack 211000 truth
    const body = makeBody({ table_id: SEED_TABLE_ID });
    const result = await postWebhook(request, { body });
    expect(result.status, 'webhook 202 Accepted').toBe(202);
    expect((result.bodyJson as { status?: string })?.status).toBe('accepted');

    // CC seat 4 갱신 검증
    await expect(seat4, 'seat 4 stack updates to 211,000').toContainText('211', {
      timeout: 5_000,
    });

    // Amber tint 1s 시각 효과 — data-state="just-synced" or class .chip-just-synced
    const tinted = ccPage.locator(`[data-seat="4"][data-state="just-synced"]`);
    await expect(tinted, 'amber tint appears').toBeVisible({ timeout: 1_500 });
    await expect(tinted, 'amber tint disappears within 1.5s').toBeHidden({ timeout: 2_000 });

    expect(baselineText, 'baseline ≠ updated value (sanity)').not.toEqual('211,000');

    await ccContext.close();
  });

  // ── B. HMAC invalid → 401 ─────────────────────────────────────────
  test('B: HMAC invalid → 401 SIGNATURE_INVALID', async ({ request }) => {
    const body = makeBody({ table_id: SEED_TABLE_ID });
    const result = await postWebhook(request, {
      body,
      signature:
        'deadbeef0000000000000000000000000000000000000000000000000000beef',
    });
    expect(result.status, 'invalid HMAC → 401').toBe(401);
    expect((result.bodyJson as { error?: string })?.error).toBe('SIGNATURE_INVALID');
  });

  // ── C. Replay (timestamp > 300s drift) → 401 ──────────────────────
  test('C: replay attack (timestamp drift > 300s) → 401 TIMESTAMP_DRIFT', async ({
    request,
  }) => {
    // 1 시간 과거 timestamp + 같은 timestamp 로 HMAC 정상 계산
    const oldTimestamp = nowIso(-60 * 60 * 1000);
    const body = makeBody({ table_id: SEED_TABLE_ID, recorded_at: oldTimestamp });
    const result = await postWebhook(request, { body, timestamp: oldTimestamp });
    expect(result.status, 'replay → 401').toBe(401);
    const errBody = result.bodyJson as { error?: string; received?: string; now?: string };
    expect(errBody?.error).toBe('TIMESTAMP_DRIFT');
    expect(errBody?.received, 'echo received timestamp').toBeTruthy();
    expect(errBody?.now, 'echo current server time').toBeTruthy();
  });

  // ── D. Idempotent: 동일 Idempotency-Key 두 번 → 200 already_processed ─
  test('D: idempotent — same Idempotency-Key twice → 200 same body (already_processed)', async ({
    request,
  }) => {
    const body = makeBody({
      table_id: SEED_TABLE_ID,
      snapshot_id: randomUUID(),
    });

    // 1st: 정상 commit
    const first = await postWebhook(request, { body });
    expect(first.status, '1st 202 Accepted').toBe(202);
    const firstBody = first.bodyJson as {
      status: string;
      snapshot_id: string;
      ws_event_dispatched: boolean;
    };
    expect(firstBody.status).toBe('accepted');
    expect(firstBody.snapshot_id).toBe(body.snapshot_id);
    expect(firstBody.ws_event_dispatched).toBe(true);

    // 2nd: 동일 snapshot_id 재전송. body 의 chip_count 값을 일부 변경해도
    // immutable append (§7.3) 에 따라 첫 commit 데이터만 truth.
    const replayBody = {
      ...body,
      seats: body.seats.map((s) => ({ ...s, chip_count: s.chip_count + 999 })),
    };
    const second = await postWebhook(request, { body: replayBody });
    expect(second.status, '2nd 200 (idempotency hit)').toBe(200);
    const secondBody = second.bodyJson as {
      status: string;
      snapshot_id: string;
      ws_event_dispatched: boolean;
    };
    expect(secondBody.status, 'already_processed').toBe('already_processed');
    expect(secondBody.snapshot_id, 'echo same snapshot_id').toBe(body.snapshot_id);
    expect(
      secondBody.ws_event_dispatched,
      'broadcast 재발행 안 함 (§7.2)',
    ).toBe(false);
  });

  // ── E. WS broadcast: 다중 client 가 chip_count_synced 수신 ────────
  test('E: WS broadcast — multiple clients receive chip_count_synced event', async ({
    browser,
    request,
  }) => {
    const token = await loginAdmin(request);

    // 2 browser context = 2 독립 client
    const clientA = await browser.newContext();
    const pageA = await clientA.newPage();
    await openCcForTable(pageA, SEED_TABLE_ID, token);

    const clientB = await browser.newContext();
    const pageB = await clientB.newPage();
    await openCcForTable(pageB, SEED_TABLE_ID, token);

    // 양쪽 page 의 console 또는 window event 로 ws 메시지 수집.
    // CC UI 가 chip_count_synced 수신 시 window.dispatchEvent(new CustomEvent('ebs:chip_count_synced', {detail}))
    // 를 발행한다고 가정 (S3 cycle 합의 — Overview.md §1.1.1 참고).
    const collect = async (page: Page) =>
      page.evaluate(
        () =>
          new Promise<{ snapshot_id: string; table_id: number }>((resolve, reject) => {
            const timer = setTimeout(
              () => reject(new Error('ebs:chip_count_synced not received in 5s')),
              5_000,
            );
            window.addEventListener(
              'ebs:chip_count_synced',
              (ev) => {
                clearTimeout(timer);
                resolve(((ev as CustomEvent).detail) as {
                  snapshot_id: string;
                  table_id: number;
                });
              },
              { once: true },
            );
          }),
      );

    const collectA = collect(pageA);
    const collectB = collect(pageB);

    // Webhook 발사
    const body = makeBody({ table_id: SEED_TABLE_ID, snapshot_id: randomUUID() });
    const webhookRes = await postWebhook(request, { body });
    expect(webhookRes.status, 'webhook 202').toBe(202);

    const [eventA, eventB] = await Promise.all([collectA, collectB]);
    expect(eventA.snapshot_id, 'client A 수신 snapshot_id 일치').toBe(body.snapshot_id);
    expect(eventA.table_id, 'client A table_id 일치').toBe(SEED_TABLE_ID);
    expect(eventB.snapshot_id, 'client B 수신 snapshot_id 일치').toBe(body.snapshot_id);
    expect(eventB.table_id, 'client B table_id 일치').toBe(SEED_TABLE_ID);

    await clientA.close();
    await clientB.close();
  });
});
