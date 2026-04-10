import { get, post, put, del } from './client'
import type { Series } from '../types/models'
import type { ApiResponse } from '../types/api'

export function list(params?: Record<string, string | number>): Promise<ApiResponse<Series[]>> {
  return get<Series[]>('/series', params)
}

export function getById(id: number): Promise<ApiResponse<Series>> {
  return get<Series>(`/series/${id}`)
}

export function create(data: Partial<Series>): Promise<ApiResponse<Series>> {
  return post<Series>('/series', data)
}

export function update(id: number, data: Partial<Series>): Promise<ApiResponse<Series>> {
  return put<Series>(`/series/${id}`, data)
}

export function remove(id: number): Promise<ApiResponse<null>> {
  return del<null>(`/series/${id}`)
}
