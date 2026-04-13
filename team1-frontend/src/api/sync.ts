// src/api/sync.ts — WSOP LIVE sync trigger/status (ported from ebs_lobby-react/api/sync.ts)

import { post, get } from './client';
import type { ApiResponse } from 'src/types/api';

interface SyncStatus {
  status: string;
  last_synced_at: string | null;
  message: string | null;
}

export function trigger(): Promise<ApiResponse<SyncStatus>> {
  return post<SyncStatus>('/sync/trigger');
}

export function getStatus(): Promise<ApiResponse<SyncStatus>> {
  return get<SyncStatus>('/sync/status');
}
