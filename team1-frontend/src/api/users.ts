// src/api/users.ts — User CRUD (ported from ebs_lobby-react/api/users.ts)

import { get, post, put, del } from './client';
import type { User } from 'src/types/models';
import type { ApiResponse } from 'src/types/api';

export function list(
  params?: Record<string, string | number>,
): Promise<ApiResponse<User[]>> {
  return get<User[]>('/users', params);
}

export function getById(id: number): Promise<ApiResponse<User>> {
  return get<User>(`/users/${id}`);
}

export function create(
  data: Partial<User> & { password?: string },
): Promise<ApiResponse<User>> {
  return post<User>('/users', data);
}

export function update(
  id: number,
  data: Partial<User>,
): Promise<ApiResponse<User>> {
  return put<User>(`/users/${id}`, data);
}

export function remove(id: number): Promise<ApiResponse<null>> {
  return del<null>(`/users/${id}`);
}
