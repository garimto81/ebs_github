import { get, post, put, del } from './client'
import type { BlindStructure } from '../types/models'
import type { ApiResponse } from '../types/api'

export function list(params?: Record<string, string | number>): Promise<ApiResponse<BlindStructure[]>> {
  return get<BlindStructure[]>('/blind-structures', params)
}

export function getById(id: number): Promise<ApiResponse<BlindStructure>> {
  return get<BlindStructure>(`/blind-structures/${id}`)
}

export function create(data: Partial<BlindStructure>): Promise<ApiResponse<BlindStructure>> {
  return post<BlindStructure>('/blind-structures', data)
}

export function update(id: number, data: Partial<BlindStructure>): Promise<ApiResponse<BlindStructure>> {
  return put<BlindStructure>(`/blind-structures/${id}`, data)
}

export function remove(id: number): Promise<ApiResponse<null>> {
  return del<null>(`/blind-structures/${id}`)
}
