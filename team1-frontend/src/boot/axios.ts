// src/boot/axios.ts — Quasar boot file
// Registers the API client (createApiClient) after Pinia is ready.
// Implements CCR-019 Idempotency-Key automatic injection.
// Refer to UI-A1-architecture.md §4.1.

import { defineBoot } from '#q-app/wrappers';
import axios, { type AxiosInstance, type AxiosError } from 'axios';
import { useAuthStore } from 'stores/authStore';

export class ApiError extends Error {
  constructor(
    public status: number,
    public code: string,
    message: string,
    public details?: unknown,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

// Shared axios instance — imported by src/api/*.ts modules.
export const api: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api/v1',
  withCredentials: true, // Refresh Token cookie (HttpOnly)
  timeout: 10_000,
});

export default defineBoot(({ app }) => {
  // Request interceptor: Bearer token + Idempotency-Key (CCR-019)
  api.interceptors.request.use((config) => {
    const auth = useAuthStore();
    if (auth.accessToken) {
      config.headers.Authorization = `Bearer ${auth.accessToken}`;
    }

    // CCR-019: all mutations get an auto-generated Idempotency-Key (UUIDv4).
    // Retries must reuse the same key so the server can deduplicate.
    const method = (config.method ?? 'get').toLowerCase();
    if (['post', 'put', 'patch', 'delete'].includes(method)) {
      if (!config.headers['Idempotency-Key']) {
        config.headers['Idempotency-Key'] = crypto.randomUUID();
      }
    }

    return config;
  });

  // Response interceptor: normalize errors + auto-refresh on 401
  api.interceptors.response.use(
    (res) => res,
    async (err: AxiosError<{ error?: { code: string; message: string; details?: unknown } }>) => {
      const config = err.config as (typeof err.config & { _retry?: boolean }) | undefined;

      if (err.response?.status === 401 && config && !config._retry) {
        const auth = useAuthStore();
        const refreshed = await auth.tryRestoreSession();
        if (refreshed) {
          config._retry = true;
          return api(config);
        }
      }

      const body = err.response?.data?.error;
      throw new ApiError(
        err.response?.status ?? 0,
        body?.code ?? 'UNKNOWN',
        body?.message ?? err.message,
        body?.details,
      );
    },
  );

  // Inject into Vue app for template access if needed (e.g. `this.$api`)
  app.config.globalProperties.$api = api;
});
