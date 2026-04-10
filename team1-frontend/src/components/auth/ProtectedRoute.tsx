import { useEffect, useState } from 'react'
import { Navigate, Outlet } from 'react-router-dom'
import { useAuthStore } from '../../store/auth-store'
import LoadingSpinner from '../common/LoadingSpinner'

export default function ProtectedRoute() {
  const { isAuthenticated, accessToken, refresh, loadSession, logout } = useAuthStore()
  const [checking, setChecking] = useState(true)

  useEffect(() => {
    async function verify() {
      let token = accessToken

      // 새로고침 시 accessToken이 메모리에서 소멸 → refresh로 재발급
      if (!token) {
        const refreshed = await refresh()
        if (!refreshed) {
          setChecking(false)
          return
        }
        token = useAuthStore.getState().accessToken
      }

      // 서버에서 세션 검증 (GAP-L-001)
      try {
        await loadSession()
      } catch {
        await logout()
      }
      setChecking(false)
    }
    verify()
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  if (checking) {
    return <LoadingSpinner />
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />
  }

  return <Outlet />
}
