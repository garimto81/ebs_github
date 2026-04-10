import { create } from 'zustand'

interface NavState {
  currentSeriesId: number | null
  currentSeriesName: string | null
  currentEventId: number | null
  currentEventName: string | null
  currentFlightId: number | null
  currentFlightName: string | null
  currentTableId: number | null
  currentTableName: string | null
  setSeriesId: (id: number | null, name?: string) => void
  setEventId: (id: number | null, name?: string) => void
  setFlightId: (id: number | null, name?: string) => void
  setTableId: (id: number | null, name?: string) => void
  reset: () => void
}

export const useNavStore = create<NavState>((set) => ({
  currentSeriesId: null,
  currentSeriesName: null,
  currentEventId: null,
  currentEventName: null,
  currentFlightId: null,
  currentFlightName: null,
  currentTableId: null,
  currentTableName: null,
  setSeriesId: (id, name) => set({
    currentSeriesId: id, currentSeriesName: name ?? null,
    currentEventId: null, currentEventName: null,
    currentFlightId: null, currentFlightName: null,
    currentTableId: null, currentTableName: null,
  }),
  setEventId: (id, name) => set({
    currentEventId: id, currentEventName: name ?? null,
    currentFlightId: null, currentFlightName: null,
    currentTableId: null, currentTableName: null,
  }),
  setFlightId: (id, name) => set({
    currentFlightId: id, currentFlightName: name ?? null,
    currentTableId: null, currentTableName: null,
  }),
  setTableId: (id, name) => set({
    currentTableId: id, currentTableName: name ?? null,
  }),
  reset: () => set({
    currentSeriesId: null, currentSeriesName: null,
    currentEventId: null, currentEventName: null,
    currentFlightId: null, currentFlightName: null,
    currentTableId: null, currentTableName: null,
  }),
}))
