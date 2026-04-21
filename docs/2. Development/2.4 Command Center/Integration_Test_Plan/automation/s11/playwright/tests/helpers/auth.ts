import { APIRequestContext, expect } from '@playwright/test';

export interface LoginResult {
  token: string;
  role: 'admin' | 'operator' | 'viewer';
  user_id: number;
}

export async function login(
  api: APIRequestContext,
  username: string,
  password: string
): Promise<LoginResult> {
  const res = await api.post('/api/v1/auth/login', {
    data: { username, password }
  });
  expect(res.status(), `login ${username} status`).toBe(200);
  const body = await res.json();
  const token = body.data?.access_token ?? body.access_token;
  const role = body.data?.role ?? body.role;
  const user_id = body.data?.user_id ?? body.user_id;
  expect(token, 'access_token present').toBeTruthy();
  return { token, role, user_id };
}

export function authHeaders(token: string): Record<string, string> {
  return { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };
}
