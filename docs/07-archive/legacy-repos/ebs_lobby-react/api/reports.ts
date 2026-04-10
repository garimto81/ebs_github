import { get } from './client'
import type { ApiResponse } from '../types/api'

export function getReport<T = unknown>(type: string, params?: Record<string, string | number>): Promise<ApiResponse<T>> {
  return get<T>(`/reports/${type}`, params)
}
