import { get, post, put, del } from './client'
import type { Event, EventFlight } from '../types/models'
import type { ApiResponse } from '../types/api'

export function list(params?: Record<string, string | number>): Promise<ApiResponse<Event[]>> {
  return get<Event[]>('/events', params)
}

export function getById(id: number): Promise<ApiResponse<Event>> {
  return get<Event>(`/events/${id}`)
}

export function create(data: Partial<Event>): Promise<ApiResponse<Event>> {
  return post<Event>('/events', data)
}

export function update(id: number, data: Partial<Event>): Promise<ApiResponse<Event>> {
  return put<Event>(`/events/${id}`, data)
}

export function remove(id: number): Promise<ApiResponse<null>> {
  return del<null>(`/events/${id}`)
}

export function getFlights(eventId: number, params?: Record<string, string | number>): Promise<ApiResponse<EventFlight[]>> {
  return get<EventFlight[]>(`/events/${eventId}/flights`, params)
}

export function createFlight(eventId: number, data: Partial<EventFlight>): Promise<ApiResponse<EventFlight>> {
  return post<EventFlight>(`/events/${eventId}/flights`, data)
}
