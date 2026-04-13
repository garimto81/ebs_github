// src/mocks/handlers.ts — MSW 2.x request handlers.
// Covers auth, lobby (series/events/flights/tables/players), configs, skins,
// and the /ws/replay endpoint used by wsStore for gap recovery.

import { http, HttpResponse } from 'msw';
import {
  mockBlindStructures,
  mockCompetitions,
  mockConfigs,
  mockEvents,
  mockFlights,
  mockPlayers,
  mockSeats,
  mockSeries,
  mockSkins,
  mockTables,
  mockUser,
} from './data';

const BASE = '/api/v1';

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
  http.post(`${BASE}/flights/:id/rebalance`, () => envelope({ moved: 3 })),

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
  http.post(`${BASE}/tables/:id/launch-cc`, () => envelope({ url: 'about:blank' })),
  http.get(`${BASE}/tables/:id/seats`, ({ params }) => {
    const tid = Number(params.id);
    return envelope(mockSeats.filter((s) => s.table_id === tid));
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

  // ---- WebSocket replay (CCR-021 gap recovery) -----------------
  http.post(`${BASE}/ws/replay`, () => envelope({ events: [] })),

  // ---- Fallback for other mutations -----------------------------
  http.post(`${BASE}/*`, () => envelope(null)),
  http.put(`${BASE}/*`, () => envelope(null)),
  http.patch(`${BASE}/*`, () => envelope(null)),
  http.delete(`${BASE}/*`, () => envelope(null)),
];
