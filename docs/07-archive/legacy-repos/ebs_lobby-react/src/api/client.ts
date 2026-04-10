import { useAuthStore } from '../store/auth-store'
import type { ApiResponse } from '../types/api'
import { mockHandle } from './mock-handler'

const BASE_URL = '/api/v1'
const MOCK = import.meta.env.VITE_MOCK === 'true'

async function apiFetch<T>(path: string, options: RequestInit = {}): Promise<ApiResponse<T>> {
  if (MOCK) {
    await new Promise(resolve => setTimeout(resolve, 50))
    const method = (options.method ?? 'GET').toUpperCase()
    const [pathname, search] = path.split('?')
    const body = options.body ? JSON.parse(options.body as string) : undefined
    return mockHandle(method, pathname, search, body) as ApiResponse<T>
  }

  const { accessToken, refresh, logout } = useAuthStore.getState()

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  }

  if (accessToken) {
    headers['Authorization'] = `Bearer ${accessToken}`
  }

  let response = await fetch(`${BASE_URL}${path}`, { ...options, headers, credentials: 'include' })

  // Auto-refresh on 401
  if (response.status === 401 && accessToken) {
    const refreshed = await refresh()
    if (refreshed) {
      const newToken = useAuthStore.getState().accessToken
      headers['Authorization'] = `Bearer ${newToken}`
      response = await fetch(`${BASE_URL}${path}`, { ...options, headers, credentials: 'include' })
    } else {
      logout()
      throw new Error('Session expired')
    }
  }

  if (!response.ok) {
    const error = await response.json().catch(() => ({
      data: null,
      error: { code: 'UNKNOWN', message: response.statusText },
    }))
    return error as ApiResponse<T>
  }

  return response.json()
}

export function get<T>(path: string, params?: Record<string, string | number>) {
  const query = params
    ? '?' + new URLSearchParams(
        Object.entries(params).reduce((acc, [k, v]) => ({ ...acc, [k]: String(v) }), {} as Record<string, string>)
      ).toString()
    : ''
  return apiFetch<T>(`${path}${query}`)
}

export function post<T>(path: string, body?: unknown) {
  return apiFetch<T>(path, {
    method: 'POST',
    body: body ? JSON.stringify(body) : undefined,
  })
}

export function put<T>(path: string, body: unknown) {
  return apiFetch<T>(path, {
    method: 'PUT',
    body: JSON.stringify(body),
  })
}

export function del<T>(path: string) {
  return apiFetch<T>(path, { method: 'DELETE' })
}
