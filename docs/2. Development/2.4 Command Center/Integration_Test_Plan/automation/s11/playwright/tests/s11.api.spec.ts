import { test, expect, request } from '@playwright/test';
import fixtures from '../../fixtures/fixtures.json';
import { login, authHeaders } from './helpers/auth';
import { todayStartIso, yesterdayStartIso, yesterdayEndIso } from './helpers/time';

const BASE = process.env.BACKEND_HTTP_URL ?? fixtures.base_urls.backend_http;

test.describe('S-11 @api — Lobby Hand History API + RBAC', () => {
  test('step 2 @rbac — Admin filter event_id=1 & table_id=1 & date_from=today 00:00', async () => {
    const api = await request.newContext({ baseURL: BASE });
    const admin = fixtures.accounts.find(a => a.role === 'admin')!;
    const { token } = await login(api, admin.username, admin.password);

    const res = await api.get('/api/v1/hands', {
      params: { event_id: 1, table_id: 1, date_from: todayStartIso() },
      headers: authHeaders(token)
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    const rows: Array<{ hand_id: number; table_id: number; event_id: number }> =
      body.data?.items ?? body.items ?? body.data ?? body;
    expect(Array.isArray(rows)).toBe(true);
    for (const row of rows) {
      expect(row.table_id).toBe(1);
      expect(row.event_id).toBe(1);
    }
    await api.dispose();
  });

  test('step 3 @rbac — Admin hand detail triplet (hand/actions/players) unmasked', async () => {
    const api = await request.newContext({ baseURL: BASE });
    const admin = fixtures.accounts.find(a => a.role === 'admin')!;
    const { token } = await login(api, admin.username, admin.password);

    const handId = 101;
    const [hand, actions, players] = await Promise.all([
      api.get(`/api/v1/hands/${handId}`, { headers: authHeaders(token) }),
      api.get(`/api/v1/hands/${handId}/actions`, { headers: authHeaders(token) }),
      api.get(`/api/v1/hands/${handId}/players`, { headers: authHeaders(token) })
    ]);
    expect(hand.status()).toBe(200);
    expect(actions.status()).toBe(200);
    expect(players.status()).toBe(200);

    const playersBody = await players.json();
    const seats = playersBody.data?.seats ?? playersBody.seats ?? playersBody;
    for (const seat of seats) {
      if (seat.hole_card_1) expect(seat.hole_card_1).not.toBe('★');
      if (seat.hole_card_2) expect(seat.hole_card_2).not.toBe('★');
    }
    await api.dispose();
  });

  test('step 6 @rbac — Operator sees only assigned table_id=1', async () => {
    const api = await request.newContext({ baseURL: BASE });
    const op = fixtures.accounts.find(a => a.role === 'operator')!;
    const { token } = await login(api, op.username, op.password);

    const res = await api.get('/api/v1/hands', {
      params: { event_id: 1, table_id: 1, date_from: todayStartIso() },
      headers: authHeaders(token)
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    const rows: Array<{ table_id: number }> = body.data?.items ?? body.items ?? body;
    for (const row of rows) expect(row.table_id).toBe(1);
    await api.dispose();
  });

  test('step 7 @rbac — Operator unassigned table returns empty (NOT 403)', async () => {
    const api = await request.newContext({ baseURL: BASE });
    const op = fixtures.accounts.find(a => a.role === 'operator')!;
    const { token } = await login(api, op.username, op.password);

    const res = await api.get('/api/v1/hands', {
      params: { event_id: 1, table_id: 2, date_from: todayStartIso() },
      headers: authHeaders(token)
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    const rows: Array<unknown> = body.data?.items ?? body.items ?? body.data ?? [];
    expect(rows.length).toBe(0);
    await api.dispose();
  });

  test('step 8 @rbac — Viewer hole_card masked with ★', async () => {
    const api = await request.newContext({ baseURL: BASE });
    const viewer = fixtures.accounts.find(a => a.role === 'viewer')!;
    const { token } = await login(api, viewer.username, viewer.password);

    const res = await api.get('/api/v1/hands/101/players', { headers: authHeaders(token) });
    expect(res.status()).toBe(200);
    const body = await res.json();
    const seats = body.data?.seats ?? body.seats ?? body;
    for (const seat of seats) {
      if (seat.hole_card_1 != null) expect(seat.hole_card_1).toBe(viewer.expected_hole_card_mask);
      if (seat.hole_card_2 != null) expect(seat.hole_card_2).toBe(viewer.expected_hole_card_mask);
    }
    await api.dispose();
  });

  test('step 10 — Yesterday filter returns empty (당일 한정 정책)', async () => {
    const api = await request.newContext({ baseURL: BASE });
    const admin = fixtures.accounts.find(a => a.role === 'admin')!;
    const { token } = await login(api, admin.username, admin.password);

    const res = await api.get('/api/v1/hands', {
      params: { event_id: 1, date_from: yesterdayStartIso(), date_to: yesterdayEndIso() },
      headers: authHeaders(token)
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    const rows: Array<unknown> = body.data?.items ?? body.items ?? body.data ?? [];
    expect(rows.length).toBe(0);
    await api.dispose();
  });

  test('pagination @api — page=1 vs page=2 hand_id 비중복', async () => {
    const api = await request.newContext({ baseURL: BASE });
    const admin = fixtures.accounts.find(a => a.role === 'admin')!;
    const { token } = await login(api, admin.username, admin.password);

    const [p1, p2] = await Promise.all([
      api.get('/api/v1/hands', {
        params: { event_id: 1, page: 1, page_size: 20 },
        headers: authHeaders(token)
      }),
      api.get('/api/v1/hands', {
        params: { event_id: 1, page: 2, page_size: 20 },
        headers: authHeaders(token)
      })
    ]);
    const b1 = await p1.json();
    const b2 = await p2.json();
    const ids1 = (b1.data?.items ?? b1.items ?? []).map((r: any) => r.hand_id);
    const ids2 = (b2.data?.items ?? b2.items ?? []).map((r: any) => r.hand_id);
    const overlap = ids1.filter((id: number) => ids2.includes(id));
    expect(overlap.length).toBe(0);
    await api.dispose();
  });
});
