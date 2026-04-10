import { get, post, put, del } from './client'
import type { Table } from '../types/models'
import type { ApiResponse } from '../types/api'

export function list(params?: Record<string, string | number>): Promise<ApiResponse<Table[]>> {
  return get<Table[]>('/tables', params)
}

export function getById(id: number): Promise<ApiResponse<Table>> {
  return get<Table>(`/tables/${id}`)
}

export function create(data: Partial<Table>): Promise<ApiResponse<Table>> {
  return post<Table>('/tables', data)
}

export function update(id: number, data: Partial<Table>): Promise<ApiResponse<Table>> {
  return put<Table>(`/tables/${id}`, data)
}

export function remove(id: number): Promise<ApiResponse<null>> {
  return del<null>(`/tables/${id}`)
}

export function launchCc(id: number): Promise<ApiResponse<{ url: string }>> {
  return post<{ url: string }>(`/tables/${id}/launch-cc`)
}

export function getStatus(id: number): Promise<ApiResponse<{ status: string }>> {
  return get<{ status: string }>(`/tables/${id}/status`)
}
