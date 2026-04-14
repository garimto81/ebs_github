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

/**
 * Returns the Google OAuth login URL. The backend handles the OAuth flow
 * and redirects back with tokens on success.
 */
export function getGoogleLoginUrl(): string {
  return `${import.meta.env.VITE_API_BASE_URL || '/api/v1'}/auth/google`;
}

// ---- 2FA Setup / Disable ------------------------------------------

export interface TwoFactorSetupResponse {
  secret: string;
  qr_code_url: string;
}

/**
 * BS-01 §A-20 — Initialize TOTP 2FA setup. Returns a secret and QR code URL
 * that the user scans with their authenticator app.
 */
export function setup2fa(): Promise<ApiResponse<TwoFactorSetupResponse>> {
  return post<TwoFactorSetupResponse>('/auth/2fa/setup');
}

/**
 * BS-01 §A-21 — Confirm 2FA setup by verifying an initial TOTP code.
 */
export function confirm2fa(code: string): Promise<ApiResponse<{ enabled: boolean }>> {
  return post<{ enabled: boolean }>('/auth/2fa/confirm', { totp_code: code });
}

/**
 * BS-01 §A-22 — Disable 2FA for the current user.
 */
export function disable2fa(code: string): Promise<ApiResponse<{ disabled: boolean }>> {
  return post<{ disabled: boolean }>('/auth/2fa/disable', { totp_code: code });
}
