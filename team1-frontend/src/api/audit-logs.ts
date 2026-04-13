// src/api/audit-logs.ts — Audit log list (ported from ebs_lobby-react/api/audit-logs.ts)

import { get } from './client';
import type { AuditLog } from 'src/types/models';
import type { ApiResponse } from 'src/types/api';

export function list(
  filters?: Record<string, string | number>,
): Promise<ApiResponse<AuditLog[]>> {
  return get<AuditLog[]>('/audit-logs', filters);
}
