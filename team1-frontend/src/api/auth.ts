// src/api/auth.ts — Auth endpoints (BS-01-auth contract, CCR-017 Bit Flag).
// Ported from ebs_lobby-react/api/auth.ts and aligned with the Quasar
// stores/authStore.ts surface (refreshToken, verify2fa, forgotPassword).

import { post, get, del } from './client';
import type { ApiResponse, TokenResponse } from 'src/types/api';
import type { SessionUser, SessionNavigation } from 'src/types/entities';

export interface SessionResponse {
  user: SessionUser;
  session: SessionNavigation;
}

export function login(
  email: string,
  password: string,
): Promise<ApiResponse<TokenResponse>> {
  return post<TokenResponse>('/auth/login', { email, password });
}

/**
 * Rotate the access token using the Refresh Token cookie (HttpOnly).
 * Exposed under both `refresh()` (React-era name) and `refreshToken()`
 * (name used by stores/authStore.ts §tryRestoreSession).
 */
export function refreshToken(): Promise<ApiResponse<TokenResponse>> {
  return post<TokenResponse>('/auth/refresh');
}

export const refresh = refreshToken;

export function getSession(): Promise<ApiResponse<SessionResponse>> {
  return get<SessionResponse>('/auth/session');
}

export function logout(): Promise<ApiResponse<null>> {
  return del<null>('/auth/session');
}

/**
 * Complete the 2FA flow started by `login()` when `requires_2fa` is true.
 * Contract: BS-01 §A-18 — `POST /auth/verify-2fa` with
 * `{ temp_token, totp_code }` returns a full `TokenResponse`.
 */
export function verify2fa(
  tempToken: string,
  code: string,
): Promise<ApiResponse<TokenResponse>> {
  return post<TokenResponse>('/auth/verify-2fa', {
    temp_token: tempToken,
    totp_code: code,
  });
}

/**
 * BS-01 §A-24 Forgot Password — sends a reset email with signed token.
 * Server responds 200 with an opaque message (no account enumeration).
 */
export function forgotPassword(
  email: string,
): Promise<ApiResponse<{ message: string }>> {
  return post<{ message: string }>('/auth/forgot-password', { email });
}
