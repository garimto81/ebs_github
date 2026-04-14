// src/mocks/handlers.ts — MSW 2.x request handlers.
// Covers auth, lobby (series/events/flights/tables/players), configs, skins,
// and the /ws/replay endpoint used by wsStore for gap recovery.

import { http, HttpResponse } from 'msw';
import {
  mockAuditLogs,
  mockBlindStructures,
  mockCompetitions,
  mockConfigs,
  mockEvents,
  mockFlights,
  mockHandActions,
  mockHandPlayers,
  mockHands,
  mockPlayers,
  mockSeats,
  mockSeries,
  mockSkins,
  mockTables,
  mockUser,
  mockUsers,
} from './data';
import type { WsEventEnvelope } from 'src/types/api';

const BASE = '/api/v1';

// ---- Rebalance WS event simulation (mock only) ----
let mockSeq = 100;

function makeWsFrame(event: string, payload: unknown): WsEventEnvelope {
  return {
    seq: ++mockSeq,
    channel: 'lobby',
    event,
    payload,
    ts: new Date().toISOString(),
  };
}

/**
 * Simulates the rebalance saga WS event stream.
 * Dispatches events directly into wsStore (bypassing real WebSocket).
 * Uses a global event bus so the mock layer stays decoupled from Pinia.
 */
function simulateRebalanceWsEvents(flightId: number): void {
  const steps = [
    'Validate table state',
    'Calculate optimal seating',
    'Lock affected tables',
    'Move players (batch 1)',
    'Move players (batch 2)',
    'Unlock tables',
  ];

  // Dispatch via CustomEvent on window — picked up by ws-client boot hook.
  function emit(event: string, payload: unknown): void {
    window.dispatchEvent(
      new CustomEvent('ebs:mock-ws', {
        detail: makeWsFrame(event, payload),
      }),
    );
  }

  setTimeout(() => {
    emit('rebalance_started', {
      flight_id: flightId,
      steps: steps.map(name => ({ name })),
    });

    steps.forEach((name, idx) => {
      setTimeout(() => {
        emit('rebalance_progress', {
          flight_id: flightId,
          step_name: name,
          status: 'in_progress',
          duration_ms: null,
          error: null,
        });
      }, 300 + idx * 500);

      setTimeout(() => {
        emit('rebalance_progress', {
          flight_id: flightId,
          step_name: name,
          status: 'ok',
          duration_ms: 100 + Math.floor(Math.random() * 200),
          error: null,
        });
      }, 600 + idx * 500);
    });

    setTimeout(() => {
      emit('rebalance_completed', {
        flight_id: flightId,
        moved: 3,
      });
    }, 800 + steps.length * 500);
  }, 200);
}

const MOCK_TOKEN = {
  access_token: 'mock-access-token',
  token_type: 'bearer',
  requires_2fa: false,
  expires_in: 900,
};

// Server envelope helper.
function envelope<T>(data: T) {
  return HttpResponse.json({ data, error: null });
}
function notFound(message = 'Not found') {
  return HttpResponse.json(
    { data: null, error: { code: 'NOT_FOUND', message } },
    { status: 404 },
  );
}

export const handlers = [
  // ---- Auth -----------------------------------------------------
  http.post(`${BASE}/auth/login`, () => envelope(MOCK_TOKEN)),
  http.post(`${BASE}/auth/refresh`, () => envelope(MOCK_TOKEN)),
  http.post(`${BASE}/auth/verify-2fa`, () => envelope(MOCK_TOKEN)),
  http.post(`${BASE}/auth/forgot-password`, () =>
    envelope({ message: 'Password reset email sent.' }),
  ),
  http.post(`${BASE}/auth/verify-reset-code`, () =>
    envelope({ reset_token: 'mock-reset-token' }),
  ),
  http.post(`${BASE}/auth/reset-password`, () =>
    envelope({ message: 'Password updated.' }),
  ),
  http.get(`${BASE}/auth/google`, () => {
    // Mock: redirect to callback with fake code
    return new Response(null, {
      status: 302,
      headers: { Location: `${BASE}/auth/google/callback?code=mock_code` },
    });
  }),
  http.get(`${BASE}/auth/google/callback`, () => {
    // Mock: return same response as login
    return envelope({
      ...MOCK_TOKEN,
      user: {
        user_id: 1,
        email: 'admin@ebs.local',
        display_name: 'Admin',
        role: 'admin',
      },
    });
  }),
  http.get(`${BASE}/auth/session`, () => envelope(mockUser)),
  http.delete(`${BASE}/auth/session`, () =>
    envelope({ message: 'Logged out successfully' }),
  ),

  // ---- Competitions / Series -----------------------------------
  http.get(`${BASE}/competitions`, () => envelope(mockCompetitions)),

  http.get(`${BASE}/series`, () => envelope(mockSeries)),
  http.get(`${BASE}/series/:id`, ({ params }) => {
    const s = mockSeries.find((x) => x.series_id === Number(params.id));
    return s ? envelope(s) : notFound();
  }),
  http.post(`${BASE}/series`, () => envelope(mockSeries[0]!)),

  // ---- Events ---------------------------------------------------
  http.get(`${BASE}/events`, ({ request }) => {
    const url = new URL(request.url);
    const seriesId = url.searchParams.get('series_id');
    const status = url.searchParams.get('status');
    let filtered = seriesId
      ? mockEvents.filter((e) => e.series_id === Number(seriesId))
      : mockEvents;
    if (status) filtered = filtered.filter((e) => e.status === status);
    return envelope(filtered);
  }),
  http.get(`${BASE}/events/:id`, ({ params }) => {
    const e = mockEvents.find((x) => x.event_id === Number(params.id));
    return e ? envelope(e) : notFound();
  }),
  http.get(`${BASE}/events/:id/flights`, ({ params }) => {
    const eventId = Number(params.id);
    return envelope(mockFlights.filter((f) => f.event_id === eventId));
  }),
  http.post(`${BASE}/events/:id/flights`, () => envelope(mockFlights[0]!)),

  // ---- Flights --------------------------------------------------
  http.get(`${BASE}/flights`, () => envelope(mockFlights)),
  http.get(`${BASE}/flights/:id`, ({ params }) => {
    const f = mockFlights.find((x) => x.event_flight_id === Number(params.id));
    return f ? envelope(f) : notFound();
  }),
  http.post(`${BASE}/flights/:id/rebalance`, ({ params }) => {
    // Simulate WS rebalance saga events after HTTP response
    const flightId = Number(params.id);
    simulateRebalanceWsEvents(flightId);
    return envelope({ moved: 3 });
  }),

  // ---- Tables ---------------------------------------------------
  http.get(`${BASE}/tables`, ({ request }) => {
    const url = new URL(request.url);
    const flightId = url.searchParams.get('event_flight_id');
    const filtered = flightId
      ? mockTables.filter((t) => t.event_flight_id === Number(flightId))
      : mockTables;
    return envelope(filtered);
  }),
  http.get(`${BASE}/tables/:id`, ({ params }) => {
    const t = mockTables.find((x) => x.table_id === Number(params.id));
    return t ? envelope(t) : notFound();
  }),
  http.post(`${BASE}/tables`, async ({ request }) => {
    const body = (await request.json()) as Record<string, unknown>;
    const newTable = {
      table_id: mockTables.length + 1,
      event_flight_id: body.event_flight_id as number,
      table_no: body.table_no as number,
      name: body.name as string,
      type: (body.type as string) ?? 'general',
      status: 'setup' as const,
      max_players: (body.max_players as number) ?? 9,
      game_type: 0,
      small_blind: (body.small_blind as number) ?? null,
      big_blind: (body.big_blind as number) ?? null,
      ante_type: 0,
      ante_amount: (body.ante_amount as number) ?? 0,
      rfid_reader_id: null,
      deck_registered: false,
      output_type: null,
      current_game: null,
      delay_seconds: 0,
      ring: null,
      is_breaking_table: false,
      source: 'manual' as const,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    mockTables.push(newTable as typeof mockTables[number]);
    return envelope(newTable);
  }),
  http.put(`${BASE}/tables/:id`, async ({ params, request }) => {
    const id = Number(params.id);
    const table = mockTables.find((t) => t.table_id === id);
    if (!table) return notFound();
    const patch = (await request.json()) as Record<string, unknown>;
    Object.assign(table, patch, { updated_at: new Date().toISOString() });
    return envelope(table);
  }),
  http.post(`${BASE}/tables/:id/launch-cc`, () => envelope({ url: 'about:blank' })),
  http.get(`${BASE}/tables/:id/seats`, ({ params }) => {
    const tid = Number(params.id);
    return envelope(mockSeats.filter((s) => s.table_id === tid));
  }),
  http.post(`${BASE}/tables/:id/seats`, async ({ params, request }) => {
    const tid = Number(params.id);
    const body = (await request.json()) as Record<string, unknown>;
    const playerId = body.player_id as number;
    const seatNo = body.seat_no as number;
    const player = mockPlayers.find((p) => p.player_id === playerId);
    const newSeat = {
      seat_id: mockSeats.length + 1,
      table_id: tid,
      seat_no: seatNo,
      player_id: playerId,
      wsop_id: player?.wsop_id ?? `P-${String(playerId).padStart(5, '0')}`,
      player_name: player ? `${player.first_name} ${player.last_name}` : 'Unknown',
      nationality: player?.nationality ?? '',
      country_code: player?.country_code ?? '',
      chip_count: 20000,
      profile_image: null,
      status: 'occupied' as const,
      player_move_status: null,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    mockSeats.push(newSeat as typeof mockSeats[number]);
    return envelope(newSeat);
  }),

  // ---- Players --------------------------------------------------
  http.get(`${BASE}/players/search`, ({ request }) => {
    const url = new URL(request.url);
    const q = (url.searchParams.get('q') ?? '').toLowerCase();
    if (!q) return envelope(mockPlayers);
    return envelope(
      mockPlayers.filter(
        (p) =>
          p.first_name.toLowerCase().includes(q) ||
          p.last_name.toLowerCase().includes(q),
      ),
    );
  }),
  http.get(`${BASE}/players`, () => envelope(mockPlayers)),
  http.get(`${BASE}/players/:id`, ({ params }) => {
    const p = mockPlayers.find((x) => x.player_id === Number(params.id));
    return p ? envelope(p) : notFound();
  }),

  // ---- Users (Staff Management) ---------------------------------
  http.get(`${BASE}/users`, () => envelope(mockUsers)),
  http.get(`${BASE}/users/:id`, ({ params }) => {
    const u = mockUsers.find((x) => x.user_id === Number(params.id));
    return u ? envelope(u) : notFound();
  }),
  http.post(`${BASE}/users`, async ({ request }) => {
    const body = (await request.json()) as Record<string, unknown>;
    const newUser = {
      user_id: mockUsers.length + 1,
      email: body.email as string,
      display_name: body.display_name as string,
      role: body.role as string,
      is_active: (body.is_active as boolean) ?? true,
      totp_enabled: false,
      last_login_at: null,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    mockUsers.push(newUser);
    return envelope(newUser);
  }),
  http.put(`${BASE}/users/:id`, async ({ params, request }) => {
    const id = Number(params.id);
    const user = mockUsers.find((u) => u.user_id === id);
    if (!user) return notFound();
    const patch = (await request.json()) as Record<string, unknown>;
    Object.assign(user, patch, { updated_at: new Date().toISOString() });
    return envelope(user);
  }),
  http.delete(`${BASE}/users/:id`, ({ params }) => {
    const idx = mockUsers.findIndex((u) => u.user_id === Number(params.id));
    if (idx < 0) return notFound();
    mockUsers.splice(idx, 1);
    return envelope(null);
  }),
  http.post(`${BASE}/users/:id/force-logout`, ({ params }) => {
    const u = mockUsers.find((x) => x.user_id === Number(params.id));
    return u ? envelope({ message: 'User logged out' }) : notFound();
  }),

  // ---- Blind Structures ----------------------------------------
  http.get(`${BASE}/blind-structures`, () => envelope(mockBlindStructures)),

  // ---- Configs / Settings (API-05) -----------------------------
  http.get(`${BASE}/configs/:section`, ({ params }) => {
    const section = String(params.section);
    return envelope(mockConfigs[section] ?? {});
  }),
  http.put(`${BASE}/configs/:section`, async ({ params, request }) => {
    const section = String(params.section);
    const body = (await request.json()) as Record<string, unknown>;
    mockConfigs[section] = { ...(mockConfigs[section] ?? {}), ...body };
    return envelope(mockConfigs[section]);
  }),
  http.get(`${BASE}/configs`, () => envelope(mockConfigs)),

  // ---- Skins (API-07, CCR-011) ---------------------------------
  http.get(`${BASE}/skins`, () => envelope(mockSkins)),
  http.get(`${BASE}/skins/:id`, ({ params }) => {
    const s = mockSkins.find((x) => x.skin_id === Number(params.id));
    return s ? envelope(s) : notFound();
  }),
  http.post(`${BASE}/skins/upload`, () => envelope(mockSkins[1]!)),
  http.put(`${BASE}/skins/:id/metadata`, async ({ params, request }) => {
    const id = Number(params.id);
    const skin = mockSkins.find((s) => s.skin_id === id);
    if (!skin) return notFound();
    const patch = (await request.json()) as Record<string, unknown>;
    skin.metadata = { ...skin.metadata, ...patch } as typeof skin.metadata;
    return envelope(skin);
  }),
  http.post(`${BASE}/skins/:id/activate`, ({ params }) => {
    const id = Number(params.id);
    const skin = mockSkins.find((s) => s.skin_id === id);
    if (!skin) return notFound();
    for (const s of mockSkins) {
      if (s.skin_id === id) s.status = 'active';
      else if (s.status === 'active') s.status = 'validated';
    }
    return envelope(skin);
  }),
  http.post(`${BASE}/skins/:id/deactivate`, ({ params }) => {
    const id = Number(params.id);
    const skin = mockSkins.find((s) => s.skin_id === id);
    if (!skin) return notFound();
    skin.status = 'validated';
    return envelope(skin);
  }),

  // ---- Hands (Hand History) --------------------------------------
  http.get(`${BASE}/hands`, ({ request }) => {
    const url = new URL(request.url);
    const tableId = url.searchParams.get('table_id');
    const filtered = tableId
      ? mockHands.filter((h) => h.table_id === Number(tableId))
      : mockHands;
    return envelope(filtered);
  }),
  http.get(`${BASE}/hands/:id`, ({ params }) => {
    const h = mockHands.find((x) => x.hand_id === Number(params.id));
    return h ? envelope(h) : notFound();
  }),
  http.get(`${BASE}/hands/:id/players`, ({ params }) => {
    return envelope(mockHandPlayers.filter((p) => p.hand_id === Number(params.id)));
  }),
  http.get(`${BASE}/hands/:id/actions`, ({ params }) => {
    return envelope(mockHandActions.filter((a) => a.hand_id === Number(params.id)));
  }),

  // ---- Audit Logs ------------------------------------------------
  http.get(`${BASE}/audit-logs`, () => envelope(mockAuditLogs)),

  // ---- 2FA Setup / Disable (BS-01) -------------------------------
  http.post(`${BASE}/auth/2fa/setup`, () =>
    envelope({
      secret: 'JBSWY3DPEHPK3PXP',
      qr_code_url: '',
    }),
  ),
  http.post(`${BASE}/auth/2fa/confirm`, () => envelope({ enabled: true })),
  http.post(`${BASE}/auth/2fa/disable`, () => envelope({ disabled: true })),

  // ---- WebSocket replay (CCR-021 gap recovery) -----------------
  http.post(`${BASE}/ws/replay`, () => envelope({ events: [] })),

  // ---- Fallback for other mutations -----------------------------
  http.post(`${BASE}/*`, () => envelope(null)),
  http.put(`${BASE}/*`, () => envelope(null)),
  http.patch(`${BASE}/*`, () => envelope(null)),
  http.delete(`${BASE}/*`, () => envelope(null)),
];
