// src/types/api.ts — API response envelope + auth + ws event types.

// ---- REST envelope ---------------------------------------------

export interface PaginationMeta {
  page: number;
  limit: number;
  total: number;
}

export interface ErrorDetail {
  code: string;
  message: string;
  details?: unknown;
}

export interface ApiResponse<T> {
  data: T | null;
  error: ErrorDetail | null;
  meta?: PaginationMeta | null;
}

// ---- Auth --------------------------------------------------------

export interface TokenResponse {
  access_token: string;
  token_type: string;
  requires_2fa?: boolean;
  temp_token?: string;
  expires_in: number;
}

export interface LoginSuccess {
  success: true;
  requires2fa: false;
}

export interface Login2faRequired {
  success: false;
  requires2fa: true;
  tempToken: string;
}

export interface LoginFailure {
  success: false;
  requires2fa: false;
  errorCode?: string;
  errorMessage?: string;
}

export type LoginResult = LoginSuccess | Login2faRequired | LoginFailure;

// ---- WebSocket events (CCR-021 sequence contract) ---------------

/**
 * Envelope for all server→client WS frames.
 * `seq` is monotonic per connection. Gaps trigger replay via POST /ws/replay.
 */
export interface WsEventEnvelope<T = unknown> {
  seq: number;
  channel: 'lobby' | 'cc' | 'system';
  event: string;
  payload: T;
  ts: string;
}

/** Client→server frames (subscribe, heartbeat). */
export interface WsClientFrame {
  type: 'subscribe' | 'unsubscribe' | 'ping';
  channel?: string;
  filter?: Record<string, unknown>;
}

export type WsStatus = 'disconnected' | 'connecting' | 'connected' | 'reconnecting' | 'error';
