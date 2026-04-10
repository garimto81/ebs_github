import { get, post, put, del } from './client'
import type { Skin } from '../types/models'
import type { ApiResponse } from '../types/api'

export function list(params?: Record<string, string | number>): Promise<ApiResponse<Skin[]>> {
  return get<Skin[]>('/skins', params)
}

export function getById(id: number): Promise<ApiResponse<Skin>> {
  return get<Skin>(`/skins/${id}`)
}

export function create(data: Partial<Skin>): Promise<ApiResponse<Skin>> {
  return post<Skin>('/skins', data)
}

export function update(id: number, data: Partial<Skin>): Promise<ApiResponse<Skin>> {
  return put<Skin>(`/skins/${id}`, data)
}

export function remove(id: number): Promise<ApiResponse<null>> {
  return del<null>(`/skins/${id}`)
}

export function activate(id: number): Promise<ApiResponse<Skin>> {
  return post<Skin>(`/skins/${id}/activate`)
}
