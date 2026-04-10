import { create } from 'zustand'
import * as authApi from '../api/auth'

interface SessionUser {
  user_id: number
  email: string
  display_name: string
  role: string
  table_ids: number[]
}

interface SessionNavigation {
  last_series_id: number | null
  last_event_id: number | null
  last_flight_id: number | null
  last_table_id: number | null
}

interface LoginResult {
  success: boolean
  requires2fa?: boolean
  tempToken?: string
  session?: SessionUser | null
  navigation?: SessionNavigation | null
}

interface AuthState {
  user: SessionUser | null
  navigation: SessionNavigation | null
  accessToken: string | null
  isAuthenticated: boolean
  login: (email: string, password: string) => Promise<LoginResult>
  complete2fa: (tempToken: string, code: string) => Promise<LoginResult>
  logout: () => Promise<void>
  refresh: () => Promise<boolean>
  loadSession: () => Promise<void>
}

export const useAuthStore = create<AuthState>((set, get) => ({
  user: null,
  navigation: null,
  accessToken: null,
  isAuthenticated: false,

  login: async (email, password) => {
    const res = await authApi.login(email, password)
    if (res.data) {
      if (res.data.requires_2fa) {
        return { success: false, requires2fa: true, tempToken: res.data.temp_token }
      }
      set({
        accessToken: res.data.access_token,
        isAuthenticated: true,
      })
      await get().loadSession()
      const { user, navigation } = get()
      return { success: true, session: user, navigation }
    }
    return { success: false }
  },

  complete2fa: async (tempToken, code) => {
    const res = await authApi.verify2fa(tempToken, code)
    if (res.data) {
      set({
        accessToken: res.data.access_token,
        isAuthenticated: true,
      })
      await get().loadSession()
      const { user, navigation } = get()
      return { success: true, session: user, navigation }
    }
    return { success: false }
  },

  logout: async () => {
    try {
      await authApi.logout()
    } catch {
      // ignore — server may be unreachable
    }
    set({ user: null, navigation: null, accessToken: null, isAuthenticated: false })
  },

  refresh: async () => {
    const res = await authApi.refresh()
    if (res.data) {
      set({ accessToken: res.data.access_token })
      return true
    }
    return false
  },

  loadSession: async () => {
    const res = await authApi.getSession()
    if (res.data) {
      set({
        user: res.data.user,
        navigation: res.data.session,
      })
    } else {
      await get().logout()
      throw new Error('Session invalid')
    }
  },
}))
