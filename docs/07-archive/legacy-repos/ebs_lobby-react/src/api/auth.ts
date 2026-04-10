import { post, get, del } from './client'
import type { ApiResponse } from '../types/api'

interface TokenResponse {
  access_token: string
  token_type: string
  requires_2fa?: boolean
  temp_token?: string
  expires_in: number
}

interface SessionUser {
  user_id: number
  email: string
  display_name: string
  role: string
  table_ids: number[]
}

interface SessionNavigation {
  last_series_id: number | null
  last_event_id: number | null
  last_flight_id: number | null
  last_table_id: number | null
}

interface SessionResponse {
  user: SessionUser
  session: SessionNavigation
}

export function login(email: string, password: string): Promise<ApiResponse<TokenResponse>> {
  return post<TokenResponse>('/auth/login', { email, password })
}

export function refresh(): Promise<ApiResponse<TokenResponse>> {
  return post<TokenResponse>('/auth/refresh')
}

export function getSession(): Promise<ApiResponse<SessionResponse>> {
  return get<SessionResponse>('/auth/session')
}

export function logout(): Promise<ApiResponse<null>> {
  return del<null>('/auth/session')
}

export function verify2fa(tempToken: string, code: string): Promise<ApiResponse<TokenResponse>> {
  return post<TokenResponse>('/auth/verify-2fa', { temp_token: tempToken, totp_code: code })
}

export function forgotPassword(email: string): Promise<ApiResponse<{ message: string }>> {
  return post<{ message: string }>('/auth/forgot-password', { email })
}
