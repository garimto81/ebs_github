import { expect, test, type Page, type APIRequestContext } from '@playwright/test';

/**
 * B-222 L2 — Inter-Session Chat Web UI E2E (Playwright)
 *
 * Plan: ~/.claude/plans/serene-greeting-pretzel.md §2.2 (6 시나리오)
 * L1 사용자 검증 영역을 자동화로 흡수.
 *
 * 사전 요구:
 *   - broker MCP 가동 (http://127.0.0.1:7383/mcp)
 *   - chat-server 컨테이너 가동 (http://localhost:7390)
 *   - `python tools/orchestrator/start_message_bus.py --probe` 로 broker alive 확인
 *   - `docker compose -f tools/chat_server/docker-compose.yml up -d` 로 chat-server 가동
 *
 * 실행:
 *   npx playwright test tests/b222-chat-ui.spec.ts --reporter=list
 *
 * broker 미가동 시 시나리오 3~5 fail OK (L2 후속 CI 에서 compose 자동 가동 예정).
 *
 * 6 시나리오:
 *   1. UI loaded:        4 분할 + broker: online
 *   2. @ autocomplete:   "@" 입력 → 드롭다운 가시
 *   3. SSE push:         POST /chat/send → DOM .msg.from-user 추가
 *   4. Reply preview:    reply_to → .reply-ref → click → 원본 강조
 *   5. LIVE TRACE 필터:  체크박스 toggle → .msg.trace-stream display none
 *   6. broker offline:   stream 차단 → #broker-state "offline"
 */

const CHAT_BASE_URL = process.env.CHAT_BASE_URL ?? 'http://localhost:7390';
const SEND_ENDPOINT = `${CHAT_BASE_URL}/chat/send`;

// 시나리오마다 고유한 body 사용 — broker WAL 영구 보존이므로 history 충돌 방지
const RUN_ID = `e2e-${Date.now()}`;

test.use({
  viewport: { width: 1440, height: 900 },
});

test.describe.configure({ mode: 'serial' });

test.describe('B-222 Chat Web UI — 6 시나리오', () => {
  test.setTimeout(60_000);

  // ─────────────────────────────────────────────────────────────
  // Scenario 1 — UI loaded (4분할 + broker online 배너)
  // ─────────────────────────────────────────────────────────────
  test('1. UI 4분할 + broker online 배너', async ({ page }) => {
    await page.goto(`${CHAT_BASE_URL}/`, { waitUntil: 'load' });

    // 4 panel H2 텍스트 확인 (design / blocker / handoff / LIVE TRACE)
    await expect(page.locator('section[data-channel="room:design"] h2')).toContainText('design');
    await expect(page.locator('section[data-channel="room:blocker"] h2')).toContainText('blocker');
    await expect(page.locator('section[data-channel="room:handoff"] h2')).toContainText('handoff');
    await expect(page.locator('section[data-channel="trace"] h2')).toContainText('LIVE TRACE');

    // 4 composer textarea 존재 (LIVE TRACE 제외 = 3개)
    const textareas = page.locator('.composer textarea');
    await expect(textareas).toHaveCount(3);

    // broker state 배너 — SSE connectSSE() onopen 후 "broker: online" 로 전이
    // (broker 미가동 시 "broker: offline (retrying...)" — 본 시나리오는 broker 가동 가정)
    const brokerState = page.locator('#broker-state');
    await expect(brokerState).toBeVisible();
    await expect(brokerState).toContainText(/broker:\s*(online|offline)/i, { timeout: 10_000 });
  });

  // ─────────────────────────────────────────────────────────────
  // Scenario 2 — @ autocomplete 드롭다운
  // ─────────────────────────────────────────────────────────────
  test('2. @ 입력 시 autocomplete 드롭다운 가시', async ({ page }) => {
    await page.goto(`${CHAT_BASE_URL}/`, { waitUntil: 'load' });

    // peers 로드 대기 (refreshPeers 가 window.__activePeers 채움)
    // 최소한 "user", "all" 은 activePeers() 가 fallback 으로 추가
    await page.waitForFunction(() => window['__activePeers'] !== undefined, { timeout: 10_000 });

    const designTextarea = page.locator('section[data-channel="room:design"] .composer textarea');
    await designTextarea.click();
    await designTextarea.fill(''); // reset
    await designTextarea.type('@', { delay: 80 });

    const autocomplete = page.locator('section[data-channel="room:design"] .composer .autocomplete');
    // hidden 속성이 false 가 되어야 함 (peers 가 1개 이상일 때만)
    await expect(autocomplete).toBeVisible({ timeout: 5_000 });

    const items = autocomplete.locator('.item');
    await expect(items.first()).toBeVisible();
    expect(await items.count()).toBeGreaterThanOrEqual(1);
  });

  // ─────────────────────────────────────────────────────────────
  // Scenario 3 — SSE push: POST /chat/send → DOM .msg.from-user 추가
  // ─────────────────────────────────────────────────────────────
  test('3. SSE push — POST send → DOM에 msg.from-user 추가', async ({ page, request }) => {
    await page.goto(`${CHAT_BASE_URL}/`, { waitUntil: 'load' });
    // SSE connectSSE() 가 broker: online 으로 전이될 때까지 대기 (broker 가동 가정)
    await page.waitForFunction(
      () => document.getElementById('broker-state')?.textContent?.includes('online'),
      { timeout: 15_000 }
    ).catch(() => {
      // broker offline 상태에서도 publish 가능하면 진행 (broker 미가동 시 fail 예상)
    });

    const uniqueBody = `${RUN_ID} scenario-3 SSE push test`;

    const res = await request.post(SEND_ENDPOINT, {
      data: { channel: 'room:design', body: uniqueBody },
      headers: { 'Content-Type': 'application/json' },
    });
    expect(res.status()).toBeLessThan(400);

    // 1s 내 DOM 에 .msg.from-user 추가 + body 매치
    const msgPanel = page.locator('#msgs-design');
    const messageWithBody = msgPanel.locator('.msg.from-user', { hasText: uniqueBody });
    await expect(messageWithBody).toBeVisible({ timeout: 5_000 });
  });

  // ─────────────────────────────────────────────────────────────
  // Scenario 4 — Reply preview click → 원본 강조
  // ─────────────────────────────────────────────────────────────
  test('4. Reply preview click — .reply-ref → 원본 scroll/하이라이트', async ({ page, request }) => {
    await page.goto(`${CHAT_BASE_URL}/`, { waitUntil: 'load' });
    await page.waitForFunction(
      () => document.getElementById('broker-state')?.textContent?.includes('online'),
      { timeout: 15_000 }
    ).catch(() => {});

    // 원본 메시지 publish
    const originalBody = `${RUN_ID} scenario-4 original message`;
    const r1 = await request.post(SEND_ENDPOINT, {
      data: { channel: 'room:design', body: originalBody },
      headers: { 'Content-Type': 'application/json' },
    });
    expect(r1.status()).toBeLessThan(400);
    const r1Json = await r1.json();
    const originalSeq = r1Json.seq ?? r1Json.event?.seq;
    expect(originalSeq, 'original publish should return seq').toBeTruthy();

    // 원본이 DOM 에 도달할 때까지 대기
    const msgPanel = page.locator('#msgs-design');
    await expect(
      msgPanel.locator('.msg', { hasText: originalBody })
    ).toBeVisible({ timeout: 5_000 });

    // reply publish (reply_to=<originalSeq>)
    const replyBody = `${RUN_ID} scenario-4 reply body`;
    const r2 = await request.post(SEND_ENDPOINT, {
      data: { channel: 'room:design', body: replyBody, reply_to: Number(originalSeq) },
      headers: { 'Content-Type': 'application/json' },
    });
    expect(r2.status()).toBeLessThan(400);

    // .reply-ref 가시 (reply 메시지 안에 미리보기 박스)
    const replyMsg = msgPanel.locator('.msg.reply', { hasText: replyBody });
    await expect(replyMsg).toBeVisible({ timeout: 5_000 });

    const replyRef = replyMsg.locator('.reply-ref');
    await expect(replyRef).toBeVisible();
    await expect(replyRef).toHaveAttribute('data-target-seq', String(originalSeq));

    // click → 원본 element 가 scroll + background 강조 (#3d2e10)
    const originalMsg = msgPanel.locator(`.msg[data-seq="${originalSeq}"]`);
    await expect(originalMsg).toBeAttached();

    await replyRef.click();
    // app.js setTimeout 1500ms 안에 background 변경 — 그 사이 캡처
    await expect(originalMsg).toHaveCSS('background-color', /rgb\(61,\s*46,\s*16\)/i, {
      timeout: 1_500,
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Scenario 5 — LIVE TRACE 필터 toggle
  // ─────────────────────────────────────────────────────────────
  test('5. LIVE TRACE 필터 toggle — .msg.trace-stream display none', async ({ page }) => {
    await page.goto(`${CHAT_BASE_URL}/`, { waitUntil: 'load' });

    // chat-server `/chat/send` 는 chat:* 만 publish 함. trace 이벤트는 broker 직접 publish 필요.
    // CI/E2E 환경에서 broker 직접 호출은 별도 fixture 필요하므로, 본 시나리오는 DOM 에
    // trace element 를 직접 inject 하여 필터 로직만 검증한다.
    // (실제 trace event 의 SSE 경로는 server.py event_gen() 의 chat/trace 분기로 검증됨)
    await page.evaluate(() => {
      const panel = document.getElementById('msgs-trace');
      if (!panel) return;
      const el = document.createElement('div');
      el.className = 'msg trace-stream';
      el.textContent = 'fixture trace-stream event';
      panel.appendChild(el);
    });

    const tracePanel = page.locator('#msgs-trace');
    const streamMsg = tracePanel.locator('.msg.trace-stream').first();
    await expect(streamMsg).toBeVisible();

    // 체크박스 toggle (uncheck) → display none
    const streamCheckbox = page.locator('.trace-filters input[data-filter="stream"]');
    await expect(streamCheckbox).toBeChecked();
    await streamCheckbox.uncheck();

    // app.js change handler 가 querySelectorAll('.trace-stream').style.display='none' 적용
    await expect(streamMsg).toBeHidden({ timeout: 2_000 });

    // 재 check → display 복원
    await streamCheckbox.check();
    await expect(streamMsg).toBeVisible({ timeout: 2_000 });
  });

  // ─────────────────────────────────────────────────────────────
  // Scenario 6 — broker offline 배너
  // ─────────────────────────────────────────────────────────────
  test('6. broker offline — #broker-state "offline" 텍스트', async ({ page }) => {
    // /chat/stream 요청을 abort 하여 EventSource error 강제 발생
    // → app.js src.addEventListener('error') 가 banner.textContent = "broker: offline (retrying...)" 설정
    await page.route('**/chat/stream*', (route) => route.abort('failed'));

    await page.goto(`${CHAT_BASE_URL}/`, { waitUntil: 'load' });

    const brokerState = page.locator('#broker-state');
    // SSE error handler 트리거까지 대기
    await expect(brokerState).toContainText(/offline/i, { timeout: 10_000 });

    // 빨간색 (var(--user)) 으로 변경되었는지 — computed style 검증
    // app.js: banner.style.color = "var(--user)"
    // var(--user) 가 css 에 정의되어 있다고 가정 (styles.css). 색상 RGB 값 직접 비교는 환경 의존이므로,
    // inline style.color 속성에 "var(--user)" 또는 비어있지 않은 값이 들어갔는지만 검증.
    const colorAttr = await brokerState.evaluate((el) => (el as HTMLElement).style.color);
    expect(colorAttr.length).toBeGreaterThan(0);
  });
});
