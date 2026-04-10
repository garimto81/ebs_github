import { post, get } from './client'
import type { ApiResponse } from '../types/api'

interface SyncStatus {
  status: string
  last_synced_at: string | null
  message: string | null
}

export function trigger(): Promise<ApiResponse<SyncStatus>> {
  return post<SyncStatus>('/sync/trigger')
}

export function getStatus(): Promise<ApiResponse<SyncStatus>> {
  return get<SyncStatus>('/sync/status')
}
