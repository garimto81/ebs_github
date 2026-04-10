import { get, post, put, del } from './client'
import type { EventFlight } from '../types/models'
import type { ApiResponse } from '../types/api'

export function list(params?: Record<string, string | number>): Promise<ApiResponse<EventFlight[]>> {
  return get<EventFlight[]>('/flights', params)
}

export function getById(id: number): Promise<ApiResponse<EventFlight>> {
  return get<EventFlight>(`/flights/${id}`)
}

export function create(data: Partial<EventFlight>): Promise<ApiResponse<EventFlight>> {
  return post<EventFlight>('/flights', data)
}

export function update(id: number, data: Partial<EventFlight>): Promise<ApiResponse<EventFlight>> {
  return put<EventFlight>(`/flights/${id}`, data)
}

export function remove(id: number): Promise<ApiResponse<null>> {
  return del<null>(`/flights/${id}`)
}
