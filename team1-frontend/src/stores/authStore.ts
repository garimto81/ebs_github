// src/stores/authStore.ts — Pinia auth store (Options API style).
// Port of ebs_lobby-react/store/auth-store.ts adapted for:
//   - Pinia (not zustand)
//   - Session navigation separate state
//   - Bit Flag RBAC (CCR-017): permissions are a resource→bitmask map
//   - hasPermission() wrapper consumed by router-guards and templates
//
// UI-A1 §3.1.

import { defineStore } from 'pinia';
import * as authApi from 'src/api/auth';
import { checkResource } from 'src/utils/permissions';
import type { PermissionAction, SessionNavigation, SessionUser } from 'src/types/entities';
import type { LoginResult } from 'src/types/api';

export type AuthStatus = 'anonymous' | 'authenticating' | 'authenticated' | 'error';

interface AuthState {
  user: SessionUser | null;
  navigation: SessionNavigation | null;
  accessToken: string | null;
  tempToken: string | null; // during 2FA flow
  status: AuthStatus;
  error: string | null;
}

export const useAuthStore = defineStore('auth', {
  state: (): AuthState => ({
    user: null,
    navigation: null,
    accessToken: null,
    tempToken: null,
    status: 'anonymous',
    error: null,
  }),

  getters: {
    isAuthenticated(state): boolean {
      return state.status === 'authenticated' && !!state.accessToken;
    },
    role(state): string | null {
      return state.user?.role ?? null;
    },
    displayName(state): string {
      return state.user?.display_name ?? state.user?.email ?? '';
    },
  },

  actions: {
    async login(email: string, password: string): Promise<LoginResult> {
      this.status = 'authenticating';
      this.error = null;
      try {
        const res = await authApi.login(email, password);
        if (res.data) {
          if (res.data.requires_2fa) {
            this.tempToken = res.data.temp_token ?? null;
            this.status = 'anonymous';
            return {
              success: false,
              requires2fa: true,
              tempToken: res.data.temp_token ?? '',
            };
          }
          this.accessToken = res.data.access_token;
          await this.loadSession();
          this.status = 'authenticated';
          return { success: true, requires2fa: false };
        }
        const msg = res.error?.message ?? 'Login failed';
        this.error = msg;
        this.status = 'error';
        return {
          success: false,
          requires2fa: false,
          errorCode: res.error?.code,
          errorMessage: msg,
        };
      } catch (err) {
        const msg = err instanceof Error ? err.message : 'Login failed';
        this.error = msg;
        this.status = 'error';
        return { success: false, requires2fa: false, errorMessage: msg };
      }
    },

    async verify2fa(code: string): Promise<LoginResult> {
      if (!this.tempToken) {
        return { success: false, requires2fa: false, errorMessage: 'No pending 2FA session' };
      }
      this.status = 'authenticating';
      try {
        const res = await authApi.verify2fa(this.tempToken, code);
        if (res.data) {
          this.accessToken = res.data.access_token;
          this.tempToken = null;
          await this.loadSession();
          this.status = 'authenticated';
          return { success: true, requires2fa: false };
        }
        this.error = res.error?.message ?? '2FA failed';
        this.status = 'error';
        return { success: false, requires2fa: false, errorMessage: this.error };
      } catch (err) {
        const msg = err instanceof Error ? err.message : '2FA failed';
        this.error = msg;
        this.status = 'error';
        return { success: false, requires2fa: false, errorMessage: msg };
      }
    },

    async loadSession(): Promise<void> {
      const res = await authApi.getSession();
      if (res.data) {
        this.user = res.data.user;
        this.navigation = res.data.session;
      } else {
        await this.logout();
        throw new Error(res.error?.message ?? 'Session invalid');
      }
    },

    /**
     * Attempt to restore a session from the Refresh Token cookie.
     * Called on app boot + on 401 responses.
     */
    async tryRestoreSession(): Promise<boolean> {
      try {
        const res = await authApi.refreshToken();
        if (res.data?.access_token) {
          this.accessToken = res.data.access_token;
          try {
            await this.loadSession();
            this.status = 'authenticated';
            return true;
          } catch {
            // fall through to failure path
          }
        }
      } catch {
        // ignore — treat as unauthenticated
      }
      this.accessToken = null;
      this.user = null;
      this.navigation = null;
      this.status = 'anonymous';
      return false;
    },

    async logout(): Promise<void> {
      try {
        await authApi.logout();
      } catch {
        // server may be unreachable; clear state anyway
      }
      this.user = null;
      this.navigation = null;
      this.accessToken = null;
      this.tempToken = null;
      this.status = 'anonymous';
      this.error = null;
    },

    /** Bit Flag permission check (CCR-017). */
    hasPermission(resource: string, action: PermissionAction): boolean {
      // Admin bypass
      if (this.user?.role === 'admin') return true;
      return checkResource(this.user?.permissions, resource, action);
    },
  },
});
