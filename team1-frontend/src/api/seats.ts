// src/api/seats.ts — Seat operations (ported from ebs_lobby-react/api/seats.ts)

import { get, post, put } from './client';
import type { TableSeat } from 'src/types/models';
import type { ApiResponse } from 'src/types/api';

export function getByTable(
  tableId: number,
): Promise<ApiResponse<TableSeat[]>> {
  return get<TableSeat[]>(`/tables/${tableId}/seats`);
}

export function update(
  tableId: number,
  seatNo: number,
  data: Partial<TableSeat>,
): Promise<ApiResponse<TableSeat>> {
  return put<TableSeat>(`/tables/${tableId}/seats/${seatNo}`, data);
}

export function assign(
  tableId: number,
  _seatNo: number,
  data: { player_id: number; seat_no: number },
): Promise<ApiResponse<TableSeat>> {
  return post<TableSeat>(`/tables/${tableId}/seats`, data);
}
