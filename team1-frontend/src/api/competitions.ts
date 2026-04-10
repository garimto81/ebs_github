import { get, post, put, del } from './client'
import type { Competition } from '../types/models'
import type { ApiResponse } from '../types/api'

export function list(params?: Record<string, string | number>): Promise<ApiResponse<Competition[]>> {
  return get<Competition[]>('/competitions', params)
}

export function getById(id: number): Promise<ApiResponse<Competition>> {
  return get<Competition>(`/competitions/${id}`)
}

export function create(data: Partial<Competition>): Promise<ApiResponse<Competition>> {
  return post<Competition>('/competitions', data)
}

export function update(id: number, data: Partial<Competition>): Promise<ApiResponse<Competition>> {
  return put<Competition>(`/competitions/${id}`, data)
}

export function remove(id: number): Promise<ApiResponse<null>> {
  return del<null>(`/competitions/${id}`)
}
