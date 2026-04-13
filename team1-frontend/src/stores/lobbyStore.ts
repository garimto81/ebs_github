// src/stores/lobbyStore.ts — Pinia store for 3-layer lobby nav + independent layers
// Main: Series → Event(Day) → Table. Independent: Player, Staff, Settings.
//
// Ported concept from ebs_lobby-react/store/nav-store.ts but expanded to:
//   - hold actual record maps (not just currentId)
//   - expose fetch actions that delegate to src/api/*
//   - receive WS updates via applyRemoteChange()
//
// UI-A1 §3.2.

import { defineStore } from 'pinia';
import * as seriesApi from 'src/api/series';
import * as eventsApi from 'src/api/events';
import * as flightsApi from 'src/api/flights';
import * as tablesApi from 'src/api/tables';
import * as playersApi from 'src/api/players';
import type { Event, EventFlight, Player, Series, Table } from 'src/types/entities';
import type { WsEventEnvelope } from 'src/types/api';

type LoadStatus = 'idle' | 'loading' | 'success' | 'error';

interface SectionState {
  status: LoadStatus;
  error: string | null;
}

interface LobbyState {
  series: Record<number, Series>;
  events: Record<number, Event>;
  flights: Record<number, EventFlight>;
  tables: Record<number, Table>;
  players: Record<number, Player>;

  // Selection (mirrors UI breadcrumb)
  currentSeriesId: number | null;
  currentEventId: number | null;
  currentFlightId: number | null;
  currentTableId: number | null;

  // Per-section load status
  seriesState: SectionState;
  eventsState: SectionState;
  flightsState: SectionState;
  tablesState: SectionState;
  playersState: SectionState;
}

function idle(): SectionState {
  return { status: 'idle', error: null };
}

export const useLobbyStore = defineStore('lobby', {
  state: (): LobbyState => ({
    series: {},
    events: {},
    flights: {},
    tables: {},
    players: {},

    currentSeriesId: null,
    currentEventId: null,
    currentFlightId: null,
    currentTableId: null,

    seriesState: idle(),
    eventsState: idle(),
    flightsState: idle(),
    tablesState: idle(),
    playersState: idle(),
  }),

  getters: {
    seriesList(state): Series[] {
      return Object.values(state.series);
    },
    eventsList(state): Event[] {
      return Object.values(state.events);
    },
    flightsList(state): EventFlight[] {
      return Object.values(state.flights);
    },
    tablesList(state): Table[] {
      return Object.values(state.tables);
    },
    playersList(state): Player[] {
      return Object.values(state.players);
    },
    eventsBySeriesId:
      (state) =>
      (seriesId: number): Event[] =>
        Object.values(state.events).filter((e) => e.series_id === seriesId),
    flightsByEventId:
      (state) =>
      (eventId: number): EventFlight[] =>
        Object.values(state.flights).filter((f) => f.event_id === eventId),
    tablesByFlightId:
      (state) =>
      (flightId: number): Table[] =>
        Object.values(state.tables).filter((t) => t.event_flight_id === flightId),
  },

  actions: {
    // ---- Fetch ---------------------------------------------------

    async fetchSeries(): Promise<void> {
      this.seriesState = { status: 'loading', error: null };
      try {
        const res = await seriesApi.list();
        if (res.data) {
          this.series = Object.fromEntries(res.data.map((s) => [s.series_id, s]));
          this.seriesState = { status: 'success', error: null };
        } else {
          this.seriesState = { status: 'error', error: res.error?.message ?? 'Failed' };
        }
      } catch (err) {
        this.seriesState = {
          status: 'error',
          error: err instanceof Error ? err.message : 'Failed',
        };
      }
    },

    async fetchEvents(seriesId?: number): Promise<void> {
      this.eventsState = { status: 'loading', error: null };
      try {
        const res = await eventsApi.list(seriesId);
        if (res.data) {
          // Merge (do not drop unrelated events)
          for (const e of res.data) {
            this.events[e.event_id] = e;
          }
          this.eventsState = { status: 'success', error: null };
        } else {
          this.eventsState = { status: 'error', error: res.error?.message ?? 'Failed' };
        }
      } catch (err) {
        this.eventsState = {
          status: 'error',
          error: err instanceof Error ? err.message : 'Failed',
        };
      }
    },

    async fetchFlights(eventId: number): Promise<void> {
      this.flightsState = { status: 'loading', error: null };
      try {
        const res = await flightsApi.listByEvent(eventId);
        if (res.data) {
          for (const f of res.data) {
            this.flights[f.event_flight_id] = f;
          }
          this.flightsState = { status: 'success', error: null };
        } else {
          this.flightsState = { status: 'error', error: res.error?.message ?? 'Failed' };
        }
      } catch (err) {
        this.flightsState = {
          status: 'error',
          error: err instanceof Error ? err.message : 'Failed',
        };
      }
    },

    async fetchTables(flightId: number): Promise<void> {
      this.tablesState = { status: 'loading', error: null };
      try {
        const res = await tablesApi.listByFlight(flightId);
        if (res.data) {
          for (const t of res.data) {
            this.tables[t.table_id] = t;
          }
          this.tablesState = { status: 'success', error: null };
        } else {
          this.tablesState = { status: 'error', error: res.error?.message ?? 'Failed' };
        }
      } catch (err) {
        this.tablesState = {
          status: 'error',
          error: err instanceof Error ? err.message : 'Failed',
        };
      }
    },

    async fetchPlayers(query?: string): Promise<void> {
      this.playersState = { status: 'loading', error: null };
      try {
        const res = query ? await playersApi.search(query) : await playersApi.list();
        if (res.data) {
          for (const p of res.data) {
            this.players[p.player_id] = p;
          }
          this.playersState = { status: 'success', error: null };
        } else {
          this.playersState = { status: 'error', error: res.error?.message ?? 'Failed' };
        }
      } catch (err) {
        this.playersState = {
          status: 'error',
          error: err instanceof Error ? err.message : 'Failed',
        };
      }
    },

    // ---- Selection ----------------------------------------------

    selectSeries(id: number | null): void {
      this.currentSeriesId = id;
      this.currentEventId = null;
      this.currentFlightId = null;
      this.currentTableId = null;
    },
    selectEvent(id: number | null): void {
      this.currentEventId = id;
      this.currentFlightId = null;
      this.currentTableId = null;
    },
    selectFlight(id: number | null): void {
      this.currentFlightId = id;
      this.currentTableId = null;
    },
    selectTable(id: number | null): void {
      this.currentTableId = id;
    },

    // ---- WS remote updates --------------------------------------

    /**
     * Apply a remote change delivered via WebSocket (CCR-021).
     * The wsStore handles seq validation + replay; by the time an event
     * reaches this method it is guaranteed in-order.
     */
    applyRemoteChange(event: WsEventEnvelope): void {
      const payload = event.payload as Record<string, unknown> | undefined;
      if (!payload) return;

      switch (event.event) {
        case 'series.updated': {
          const s = payload as Series;
          if (s.series_id) this.series[s.series_id] = s;
          break;
        }
        case 'event.updated': {
          const e = payload as Event;
          if (e.event_id) this.events[e.event_id] = e;
          break;
        }
        case 'flight.updated': {
          const f = payload as EventFlight;
          if (f.event_flight_id) this.flights[f.event_flight_id] = f;
          break;
        }
        case 'table.updated': {
          const t = payload as Table;
          if (t.table_id) this.tables[t.table_id] = t;
          break;
        }
        case 'player.updated': {
          const p = payload as Player;
          if (p.player_id) this.players[p.player_id] = p;
          break;
        }
        default:
          // Unknown events are intentionally ignored; other stores may handle.
          break;
      }
    },

    // ---- Mutations ----------------------------------------------

    async rebalance(flightId: number): Promise<void> {
      await tablesApi.rebalance(flightId);
      await this.fetchTables(flightId);
    },
  },
});
