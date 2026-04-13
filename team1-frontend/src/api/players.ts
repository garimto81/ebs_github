// src/api/players.ts — Player CRUD (ported from ebs_lobby-react/api/players.ts)

import { get, post, put, del } from './client';
import type { Player } from 'src/types/models';
import type { ApiResponse } from 'src/types/api';

export function list(
  params?: Record<string, string | number>,
): Promise<ApiResponse<Player[]>> {
  return get<Player[]>('/players', params);
}

export function getById(id: number): Promise<ApiResponse<Player>> {
  return get<Player>(`/players/${id}`);
}

export function create(data: Partial<Player>): Promise<ApiResponse<Player>> {
  return post<Player>('/players', data);
}

export function update(
  id: number,
  data: Partial<Player>,
): Promise<ApiResponse<Player>> {
  return put<Player>(`/players/${id}`, data);
}

export function remove(id: number): Promise<ApiResponse<null>> {
  return del<null>(`/players/${id}`);
}

export function search(
  query: string,
  params?: Record<string, string | number>,
): Promise<ApiResponse<Player[]>> {
  return get<Player[]>('/players/search', { q: query, ...params });
}
