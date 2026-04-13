// src/api/skins.ts — Graphic Editor skin endpoints (API-07, CCR-011).
// Uses the richer Skin type from src/types/entities.ts (not the legacy
// theme_data blob in models.ts).

import { get, post, put, del } from './client';
import { api } from 'boot/axios';
import type { Skin, SkinMetadata } from 'src/types/entities';
import type { ApiResponse } from 'src/types/api';

export function list(): Promise<ApiResponse<Skin[]>> {
  return get<Skin[]>('/skins');
}

export function getById(id: number): Promise<ApiResponse<Skin>> {
  return get<Skin>(`/skins/${id}`);
}

export async function upload(
  file: File,
  onProgress?: (pct: number) => void,
): Promise<ApiResponse<Skin>> {
  const form = new FormData();
  form.append('file', file);
  try {
    const res = await api.post<Skin>('/skins/upload', form, {
      headers: { 'Content-Type': 'multipart/form-data' },
      onUploadProgress: (e) => {
        if (onProgress && e.total) {
          onProgress(Math.round((e.loaded / e.total) * 100));
        }
      },
    });
    const body = res.data as unknown;
    if (body && typeof body === 'object' && 'data' in (body as object)) {
      return body as ApiResponse<Skin>;
    }
    return { data: res.data, error: null };
  } catch (err) {
    return {
      data: null,
      error: { code: 'UPLOAD_FAILED', message: err instanceof Error ? err.message : String(err) },
    };
  }
}

export function updateMetadata(
  id: number,
  metadata: SkinMetadata,
): Promise<ApiResponse<Skin>> {
  return put<Skin>(`/skins/${id}/metadata`, metadata);
}

export function activate(id: number): Promise<ApiResponse<Skin>> {
  return post<Skin>(`/skins/${id}/activate`);
}

export function deactivate(id: number): Promise<ApiResponse<Skin>> {
  return post<Skin>(`/skins/${id}/deactivate`);
}

export function remove(id: number): Promise<ApiResponse<null>> {
  return del<null>(`/skins/${id}`);
}
