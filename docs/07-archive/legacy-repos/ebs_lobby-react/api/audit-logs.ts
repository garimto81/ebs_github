import { get } from './client'
import type { AuditLog } from '../types/models'
import type { ApiResponse } from '../types/api'

export function list(filters?: Record<string, string | number>): Promise<ApiResponse<AuditLog[]>> {
  return get<AuditLog[]>('/audit-logs', filters)
}
