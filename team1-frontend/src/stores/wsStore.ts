// src/stores/wsStore.ts — WebSocket client store (CCR-021).
// Manages a single ws://[host]/ws/lobby connection used by Team 1 for
// read-only monitoring updates.
//
// Responsibilities:
//   - connect / disconnect with exponential backoff reconnection
//   - sequence number validation (CCR-021):
//       if incoming seq > lastSeq + 1, POST /ws/replay to fill the gap
//   - dispatch events to lobbyStore / settingsStore / geStore
//
// UI-A1 §5.1.

import { defineStore } from 'pinia';
import { api } from 'src/boot/axios';
import { useAuthStore } from 'stores/authStore';
import { useLobbyStore } from 'stores/lobbyStore';
import { useSettingsStore } from 'stores/settingsStore';
import { useGeStore } from 'stores/geStore';
import type { WsEventEnvelope, WsStatus } from 'src/types/api';

interface WsState {
  status: WsStatus;
  lastSeq: number;
  subscriptions: string[];
  eventBuffer: WsEventEnvelope[]; // buffered while out-of-order
  reconnectAttempts: number;
  reconnectDelay: number; // ms
  socket: WebSocket | null;
}

const INITIAL_BACKOFF_MS = 1000;
const MAX_BACKOFF_MS = 30_000;

function resolveWsUrl(path = '/ws/lobby'): string {
  const base = import.meta.env.VITE_WS_BASE_URL as string | undefined;
  if (base) return `${base}${path}`;
  // Derive from current location.
  if (typeof window === 'undefined') return `ws://localhost:8000${path}`;
  const proto = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  return `${proto}//${window.location.host}${path}`;
}

export const useWsStore = defineStore('ws', {
  state: (): WsState => ({
    status: 'disconnected',
    lastSeq: 0,
    subscriptions: [],
    eventBuffer: [],
    reconnectAttempts: 0,
    reconnectDelay: INITIAL_BACKOFF_MS,
    socket: null,
  }),

  actions: {
    connect(): void {
      if (this.status === 'connected' || this.status === 'connecting') return;

      const auth = useAuthStore();
      if (!auth.isAuthenticated) {
        // eslint-disable-next-line no-console
        console.warn('[ws] refusing to connect — not authenticated');
        return;
      }

      this.status = 'connecting';
      try {
        const url = resolveWsUrl('/ws/lobby');
        const socket = new WebSocket(url);
        this.socket = socket;

        socket.onopen = () => {
          this.status = 'connected';
          this.reconnectAttempts = 0;
          this.reconnectDelay = INITIAL_BACKOFF_MS;
        };

        socket.onmessage = (ev: MessageEvent<string>) => {
          try {
            const frame = JSON.parse(ev.data) as WsEventEnvelope;
            void this.handleMessage(frame);
          } catch (err) {
            console.error('[ws] failed to parse frame', err);
          }
        };

        socket.onerror = () => {
          this.status = 'error';
        };

        socket.onclose = () => {
          this.socket = null;
          if (this.status !== 'disconnected') {
            this.scheduleReconnect();
          }
        };
      } catch (err) {
        console.error('[ws] connect failed', err);
        this.status = 'error';
        this.scheduleReconnect();
      }
    },

    disconnect(): void {
      this.status = 'disconnected';
      if (this.socket) {
        try {
          this.socket.close();
        } catch {
          /* ignore */
        }
        this.socket = null;
      }
      this.lastSeq = 0;
      this.eventBuffer = [];
    },

    async handleMessage(frame: WsEventEnvelope): Promise<void> {
      // CCR-021 sequence validation
      if (this.lastSeq === 0) {
        // First frame — accept and baseline
        this.lastSeq = frame.seq;
        this.dispatch(frame);
        return;
      }
      if (frame.seq === this.lastSeq + 1) {
        this.lastSeq = frame.seq;
        this.dispatch(frame);
        // Drain any buffered consecutive events
        this.drainBuffer();
        return;
      }
      if (frame.seq <= this.lastSeq) {
        // Duplicate / out-of-date — ignore
        return;
      }
      // Gap detected: buffer and request replay
      this.eventBuffer.push(frame);
      await this.replay(this.lastSeq + 1, frame.seq - 1);
    },

    drainBuffer(): void {
      this.eventBuffer.sort((a, b) => a.seq - b.seq);
      while (this.eventBuffer.length > 0 && this.eventBuffer[0]!.seq === this.lastSeq + 1) {
        const next = this.eventBuffer.shift()!;
        this.lastSeq = next.seq;
        this.dispatch(next);
      }
    },

    async replay(fromSeq: number, toSeq: number): Promise<void> {
      try {
        const res = await api.post<{ events: WsEventEnvelope[] }>('/ws/replay', {
          from_seq: fromSeq,
          to_seq: toSeq,
        });
        const events = res.data?.events ?? [];
        for (const e of events.sort((a, b) => a.seq - b.seq)) {
          if (e.seq === this.lastSeq + 1) {
            this.lastSeq = e.seq;
            this.dispatch(e);
          }
        }
        this.drainBuffer();
      } catch (err) {
        console.error('[ws] replay failed', err);
      }
    },

    dispatch(event: WsEventEnvelope): void {
      const lobby = useLobbyStore();
      const settings = useSettingsStore();
      const ge = useGeStore();

      if (event.event.startsWith('skin.')) {
        ge.applyRemoteSkinUpdate(event);
      } else if (event.event === 'config.updated') {
        settings.applyRemoteChange(event);
      } else {
        lobby.applyRemoteChange(event);
      }
    },

    scheduleReconnect(): void {
      this.status = 'reconnecting';
      this.reconnectAttempts += 1;
      const delay = Math.min(
        this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1),
        MAX_BACKOFF_MS,
      );
      setTimeout(() => {
        if (this.status === 'reconnecting') this.connect();
      }, delay);
    },
  },
});
