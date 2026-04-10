import { useState, useEffect } from 'react'
import { Outlet } from 'react-router-dom'
import Sidebar from './Sidebar'
import Breadcrumb from './Breadcrumb'
import { useAuthStore } from '../../store/auth-store'
import { useWebSocket } from '../../hooks/use-websocket'
import type { WsStatus } from '../../hooks/use-websocket'
import DegradationBanner from '../common/DegradationBanner'
import type { DegradationLevel } from '../common/DegradationBanner'

function wsStatusToDegradation(status: WsStatus): { level: DegradationLevel; message: string } | null {
  switch (status) {
    case 'reconnecting':
      return { level: 'warn', message: 'Connection lost — reconnecting...' }
    case 'disconnected':
      return { level: 'error', message: 'Server connection failed — some features unavailable' }
    default:
      return null
  }
}

export default function AppLayout() {
  const user = useAuthStore((s) => s.user)
  const logout = useAuthStore((s) => s.logout)
  const { status: wsStatus, lastMessage } = useWebSocket('lobby')
  const degradation = wsStatusToDegradation(wsStatus)

  const [activeCcCount, setActiveCcCount] = useState(0)

  useEffect(() => {
    if (!lastMessage) return
    if (lastMessage.type === 'cc:count_updated' && typeof (lastMessage.payload as { count?: unknown })?.count === 'number') {
      setActiveCcCount((lastMessage.payload as { count: number }).count)
    }
  }, [lastMessage])

  return (
    <div className="app-layout">
      <Sidebar />
      <div className="app-main">
        {degradation && (
          <DegradationBanner level={degradation.level} message={degradation.message} />
        )}
        <header className="app-topbar">
          <Breadcrumb />
          <div className="topbar-right">
            {activeCcCount > 0 && (
              <span className="cc-indicator" style={{
                fontSize: 12,
                padding: '2px 8px',
                background: 'var(--bg-tertiary)',
                borderRadius: 12,
                marginRight: 8,
              }}>
                CC Active: {activeCcCount}
              </span>
            )}
            {user && (
              <>
                <span className="user-info">{user.display_name}</span>
                <span className="user-role">{user.role}</span>
                <button className="btn-logout" onClick={logout}>Logout</button>
              </>
            )}
          </div>
        </header>
        <main className="app-content">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
