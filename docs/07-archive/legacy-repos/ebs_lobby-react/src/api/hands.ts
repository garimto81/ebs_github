import { get } from './client'
import type { Hand, HandAction, HandPlayer } from '../types/models'
import type { ApiResponse } from '../types/api'

export function list(params?: Record<string, string | number>): Promise<ApiResponse<Hand[]>> {
  return get<Hand[]>('/hands', params)
}

export function getById(id: number): Promise<ApiResponse<Hand>> {
  return get<Hand>(`/hands/${id}`)
}

export function getActions(handId: number): Promise<ApiResponse<HandAction[]>> {
  return get<HandAction[]>(`/hands/${handId}/actions`)
}

export function getPlayers(handId: number): Promise<ApiResponse<HandPlayer[]>> {
  return get<HandPlayer[]>(`/hands/${handId}/players`)
}
