// src/api/events.ts — Event CRUD (ported from ebs_lobby-react/api/events.ts)
// NOTE: model type renamed Event → EbsEvent to avoid DOM Event clash.

import { get, post, put, del } from './client';
import type { EbsEvent, EventFlight } from 'src/types/models';
import type { ApiResponse } from 'src/types/api';

export function list(
  seriesIdOrParams?: number | Record<string, string | number>,
): Promise<ApiResponse<EbsEvent[]>> {
  const params =
    typeof seriesIdOrParams === 'number'
      ? { series_id: seriesIdOrParams }
      : seriesIdOrParams;
  return get<EbsEvent[]>('/events', params);
}

export function getById(id: number): Promise<ApiResponse<EbsEvent>> {
  return get<EbsEvent>(`/events/${id}`);
}

export function create(
  data: Partial<EbsEvent>,
): Promise<ApiResponse<EbsEvent>> {
  return post<EbsEvent>('/events', data);
}

export function update(
  id: number,
  data: Partial<EbsEvent>,
): Promise<ApiResponse<EbsEvent>> {
  return put<EbsEvent>(`/events/${id}`, data);
}

export function remove(id: number): Promise<ApiResponse<null>> {
  return del<null>(`/events/${id}`);
}

export function getFlights(
  eventId: number,
  params?: Record<string, string | number>,
): Promise<ApiResponse<EventFlight[]>> {
  return get<EventFlight[]>(`/events/${eventId}/flights`, params);
}

export function createFlight(
  eventId: number,
  data: Partial<EventFlight>,
): Promise<ApiResponse<EventFlight>> {
  return post<EventFlight>(`/events/${eventId}/flights`, data);
}
