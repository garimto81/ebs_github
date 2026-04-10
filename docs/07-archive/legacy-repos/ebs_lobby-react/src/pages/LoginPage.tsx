import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuthStore } from '../store/auth-store'
import LoginForm from '../components/auth/LoginForm'
import ConfirmDialog from '../components/common/ConfirmDialog'
import LoadingSpinner from '../components/common/LoadingSpinner'

export default function LoginPage() {
  const navigate = useNavigate()
  const { refresh, loadSession } = useAuthStore()
  const [checking, setChecking] = useState(true)
  const [restoreDialog, setRestoreDialog] = useState<{
    tableId: number
    flightId: number
  } | null>(null)

  // GAP-L-005: 유효 세션이면 /series로 리다이렉트
  useEffect(() => {
    async function checkExistingSession() {
      const refreshed = await refresh()
      if (refreshed) {
        try {
          await loadSession()
          navigate('/series', { replace: true })
          return
        } catch {
          // session invalid — show login form
        }
      }
      setChecking(false)
    }
    checkExistingSession()
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  const handleLoginSuccess = () => {
    const nav = useAuthStore.getState().navigation
    if (nav?.last_table_id && nav?.last_flight_id) {
      setRestoreDialog({ tableId: nav.last_table_id, flightId: nav.last_flight_id })
    } else {
      navigate('/series', { replace: true })
    }
  }

  if (checking) {
    return <LoadingSpinner />
  }

  return (
    <div className="login-page">
      <div className="login-card">
        <h1>EBS Lobby</h1>
        <p className="login-subtitle">Tournament Management System</p>
        <LoginForm onSuccess={handleLoginSuccess} />
      </div>

      <ConfirmDialog
        open={!!restoreDialog}
        title="Resume Previous Session?"
        message={`Return to Table #${restoreDialog?.tableId ?? ''}?`}
        onConfirm={() =>
          navigate(`/flights/${restoreDialog!.flightId}/tables`, { replace: true })
        }
        onCancel={() => navigate('/series', { replace: true })}
        confirmLabel="Continue"
        cancelLabel="Fresh Start"
      />
    </div>
  )
}
