// src/api/reports.ts — Reports (ported from ebs_lobby-react/api/reports.ts)

import { get } from './client';
import type { ApiResponse } from 'src/types/api';

export function getReport<T = unknown>(
  type: string,
  params?: Record<string, string | number>,
): Promise<ApiResponse<T>> {
  return get<T>(`/reports/${type}`, params);
}
