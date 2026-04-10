import { get, put } from './client'
import type { TableSeat } from '../types/models'
import type { ApiResponse } from '../types/api'

export function getByTable(tableId: number): Promise<ApiResponse<TableSeat[]>> {
  return get<TableSeat[]>(`/tables/${tableId}/seats`)
}

export function update(tableId: number, seatNo: number, data: Partial<TableSeat>): Promise<ApiResponse<TableSeat>> {
  return put<TableSeat>(`/tables/${tableId}/seats/${seatNo}`, data)
}
