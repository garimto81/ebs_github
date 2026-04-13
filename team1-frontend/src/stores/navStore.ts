// src/stores/navStore.ts — Pinia breadcrumb store (ported from ebs_lobby-react/store/nav-store.ts)
//
// Migration notes:
// - Zustand create() → Pinia defineStore()
// - Cascading reset behavior preserved: setting a parent level
//   clears all descendant levels (setSeriesId clears event/flight/table).

import { defineStore } from 'pinia';

interface NavState {
  currentSeriesId: number | null;
  currentSeriesName: string | null;
  currentEventId: number | null;
  currentEventName: string | null;
  currentFlightId: number | null;
  currentFlightName: string | null;
  currentTableId: number | null;
  currentTableName: string | null;
}

const emptyState = (): NavState => ({
  currentSeriesId: null,
  currentSeriesName: null,
  currentEventId: null,
  currentEventName: null,
  currentFlightId: null,
  currentFlightName: null,
  currentTableId: null,
  currentTableName: null,
});

export const useNavStore = defineStore('nav', {
  state: (): NavState => emptyState(),

  actions: {
    setSeriesId(id: number | null, name?: string): void {
      this.currentSeriesId = id;
      this.currentSeriesName = name ?? null;
      this.currentEventId = null;
      this.currentEventName = null;
      this.currentFlightId = null;
      this.currentFlightName = null;
      this.currentTableId = null;
      this.currentTableName = null;
    },

    setEventId(id: number | null, name?: string): void {
      this.currentEventId = id;
      this.currentEventName = name ?? null;
      this.currentFlightId = null;
      this.currentFlightName = null;
      this.currentTableId = null;
      this.currentTableName = null;
    },

    setFlightId(id: number | null, name?: string): void {
      this.currentFlightId = id;
      this.currentFlightName = name ?? null;
      this.currentTableId = null;
      this.currentTableName = null;
    },

    setTableId(id: number | null, name?: string): void {
      this.currentTableId = id;
      this.currentTableName = name ?? null;
    },

    reset(): void {
      Object.assign(this, emptyState());
    },
  },
});
