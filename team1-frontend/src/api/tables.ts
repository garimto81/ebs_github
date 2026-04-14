// src/api/tables.ts — Table CRUD (ported from ebs_lobby-react/api/tables.ts)

import { get, post, put, del } from './client';
import type { Table } from 'src/types/models';
import type { ApiResponse } from 'src/types/api';

export function list(
  params?: Record<string, string | number>,
): Promise<ApiResponse<Table[]>> {
  return get<Table[]>('/tables', params);
}

export function listByFlight(flightId: number): Promise<ApiResponse<Table[]>> {
  return get<Table[]>('/tables', { event_flight_id: flightId });
}

export function rebalance(flightId: number): Promise<ApiResponse<{ moved: number }>> {
  return post<{ moved: number }>(`/flights/${flightId}/rebalance`);
}

export function getById(id: number): Promise<ApiResponse<Table>> {
  return get<Table>(`/tables/${id}`);
}

export function create(data: Partial<Table>): Promise<ApiResponse<Table>> {
  return post<Table>('/tables', data);
}

export function update(
  id: number,
  data: Partial<Table>,
): Promise<ApiResponse<Table>> {
  return put<Table>(`/tables/${id}`, data);
}

export function remove(id: number): Promise<ApiResponse<null>> {
  return del<null>(`/tables/${id}`);
}

export function launchCc(id: number): Promise<ApiResponse<{ url: string }>> {
  return post<{ url: string }>(`/tables/${id}/launch-cc`);
}

export function getStatus(
  id: number,
): Promise<ApiResponse<{ status: string }>> {
  return get<{ status: string }>(`/tables/${id}/status`);
}
