import { test, expect, request } from '@playwright/test';
import WebSocket from 'ws';
import fixtures from '../../fixtures/fixtures.json';
import { login } from './helpers/auth';

const BASE = process.env.BACKEND_HTTP_URL ?? fixtures.base_urls.backend_http;
const WS_URL = process.env.BACKEND_WS_URL ?? fixtures.base_urls.backend_ws_lobby;

interface WsMessage {
  type: string;
  seq?: number;
  version?: string;
  hand_id?: number;
  hand_number?: number;
  table_id?: number;
  [key: string]: unknown;
}

async function connectLobbyWs(token: string): Promise<WebSocket> {
  const url = `${WS_URL}?token=${encodeURIComponent(token)}`;
  const ws = new WebSocket(url);
  await new Promise<void>((resolve, reject) => {
    const to = setTimeout(() => reject(new Error('WS connect timeout')), 5_000);
    ws.once('open', () => { clearTimeout(to); resolve(); });
    ws.once('error', (e) => { clearTimeout(to); reject(e); });
  });
  ws.send(JSON.stringify({
    type: 'Subscribe',
    event_types: ['HandStarted', 'ActionPerformed', 'HandEnded']
  }));
  return ws;
}

function waitForType(
  ws: WebSocket,
  type: string,
  predicate?: (msg: WsMessage) => boolean,
  timeoutMs = 8_000
): Promise<WsMessage> {
  return new Promise((resolve, reject) => {
    const to = setTimeout(() => {
      ws.off('message', onMsg);
      reject(new Error(`timeout waiting for WS type=${type}`));
    }, timeoutMs);
    const onMsg = (data: WebSocket.RawData) => {
      try {
        const msg: WsMessage = JSON.parse(data.toString());
        if (msg.type === type && (!predicate || predicate(msg))) {
          clearTimeout(to);
          ws.off('message', onMsg);
          resolve(msg);
        }
      } catch {
      }
    };
    ws.on('message', onMsg);
  });
}

test.describe('S-11 @ws — WebSocket real-time Hand Browser updates', () => {
  test('step 4 @ws — HandStarted prepend signal reaches Lobby subscriber', async () => {
    const api = await request.newContext({ baseURL: BASE });
    const admin = fixtures.accounts.find(a => a.role === 'admin')!;
    const { token } = await login(api, admin.username, admin.password);

    const ws = await connectLobbyWs(token);
    try {
      const trigger = process.env.NEW_HAND_TRIGGER_MODE ?? 'wait';
      if (trigger === 'wait') {
        test.info().annotations.push({
          type: 'manual-trigger',
          description: 'Start a new hand via CC during next 8s'
        });
      }

      const msg = await waitForType(ws, 'HandStarted');
      expect(msg.hand_id).toBeGreaterThan(0);
      expect(msg.hand_number).toBeGreaterThan(0);
      expect(typeof msg.seq === 'number' || msg.seq === undefined).toBe(true);
    } finally {
      ws.close();
      await api.dispose();
    }
  });

  test('step 5 @ws — ActionPerformed for different hand_id ignored by detail view (contract-only check)', async () => {
    const api = await request.newContext({ baseURL: BASE });
    const admin = fixtures.accounts.find(a => a.role === 'admin')!;
    const { token } = await login(api, admin.username, admin.password);

    const ws = await connectLobbyWs(token);
    try {
      const msg = await waitForType(ws, 'ActionPerformed', undefined, 10_000);
      expect(msg.hand_id).toBeGreaterThan(0);
      expect(msg).toHaveProperty('seat');
      expect(msg).toHaveProperty('action_type');
    } finally {
      ws.close();
      await api.dispose();
    }
  });

  test('seq monotonicity @ws — consecutive events strictly increasing seq', async () => {
    const api = await request.newContext({ baseURL: BASE });
    const admin = fixtures.accounts.find(a => a.role === 'admin')!;
    const { token } = await login(api, admin.username, admin.password);

    const ws = await connectLobbyWs(token);
    const seen: number[] = [];
    try {
      await new Promise<void>((resolve) => {
        ws.on('message', (data) => {
          try {
            const msg: WsMessage = JSON.parse(data.toString());
            if (typeof msg.seq === 'number') seen.push(msg.seq);
            if (seen.length >= 3) resolve();
          } catch {}
        });
        setTimeout(resolve, 10_000);
      });
      for (let i = 1; i < seen.length; i++) {
        expect(seen[i], `seq[${i}] > seq[${i - 1}]`).toBeGreaterThan(seen[i - 1]);
      }
    } finally {
      ws.close();
      await api.dispose();
    }
  });
});
