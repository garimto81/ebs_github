// src/api/client.ts — Thin wrapper over boot/axios.ts
// Exposes get/post/put/del helpers with the { data, error } envelope that
// React-era api modules expect. Migration shim — new code should prefer
// importing `api` from 'boot/axios' directly and awaiting AxiosResponse.

import { AxiosError } from 'axios';
import { api, ApiError } from 'boot/axios';
import type { ApiResponse } from 'src/types/api';

async function wrap<T>(promise: Promise<{ data: T }>): Promise<ApiResponse<T>> {
  try {
    const res = await promise;
    // Backend envelope: { data, error, meta } OR raw T. Normalize both.
    const body = res.data as unknown as ApiResponse<T> | T;
    if (body && typeof body === 'object' && 'data' in (body as object)) {
      return body as ApiResponse<T>;
    }
    return { data: body as T, error: null };
  } catch (err) {
    if (err instanceof ApiError) {
      return {
        data: null,
        error: { code: err.code, message: err.message },
      };
    }
    if (err instanceof AxiosError) {
      return {
        data: null,
        error: {
          code: err.code ?? 'NETWORK_ERROR',
          message: err.message,
        },
      };
    }
    return {
      data: null,
      error: { code: 'UNKNOWN', message: String(err) },
    };
  }
}

function buildQuery(params?: Record<string, string | number>): string {
  if (!params) return '';
  const entries = Object.entries(params).map(
    ([k, v]) => [k, String(v)] as [string, string],
  );
  return '?' + new URLSearchParams(entries).toString();
}

export function get<T>(
  path: string,
  params?: Record<string, string | number>,
): Promise<ApiResponse<T>> {
  return wrap<T>(api.get(`${path}${buildQuery(params)}`));
}

export function post<T>(path: string, body?: unknown): Promise<ApiResponse<T>> {
  return wrap<T>(api.post(path, body));
}

export function put<T>(path: string, body: unknown): Promise<ApiResponse<T>> {
  return wrap<T>(api.put(path, body));
}

export function del<T>(path: string): Promise<ApiResponse<T>> {
  return wrap<T>(api.delete(path));
}
