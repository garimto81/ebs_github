import { get, put } from './client'
import type { Config } from '../types/models'
import type { ApiResponse } from '../types/api'

export function getSection(section: string): Promise<ApiResponse<Config[]>> {
  return get<Config[]>(`/configs/${section}`)
}

export function updateSection(section: string, values: Record<string, string>): Promise<ApiResponse<Config[]>> {
  return put<Config[]>(`/configs/${section}`, values)
}
