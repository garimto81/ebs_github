import { useState, useEffect } from 'react'
import * as syncApi from '../../api/sync'
import StatusBadge from '../../components/common/StatusBadge'
import '../pages.css'

export default function WsopSyncPage() {
  const [status, setStatus] = useState('idle')
  const [lastSynced, setLastSynced] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadStatus = async () => {
    const res = await syncApi.getStatus()
    if (res.data) {
      setStatus(res.data.status)
      setLastSynced(res.data.last_synced_at)
      setMessage(res.data.message)
    }
  }

  useEffect(() => {
    loadStatus()
  }, [])

  const handleTrigger = async () => {
    setLoading(true)
    setError(null)
    const res = await syncApi.trigger()
    if (res.data) {
      setStatus(res.data.status)
      setLastSynced(res.data.last_synced_at)
      setMessage(res.data.message)
    } else if (res.error) {
      setError(res.error.message)
    }
    setLoading(false)
    // Refresh status after a short delay
    setTimeout(loadStatus, 3000)
  }

  const statusColor = status === 'running' ? 'running' : status === 'error' ? 'closed' : 'setup'

  return (
    <div className="page-container">
      <div className="page-header">
        <h1 className="page-title">WSOP Sync</h1>
      </div>

      {error && <div className="page-error">{error}</div>}

      <div className="sync-card">
        <h3 style={{ marginBottom: 16 }}>Synchronization Status</h3>
        <div className="sync-status">
          <StatusBadge status={statusColor} />
          <span style={{ marginLeft: 8, textTransform: 'capitalize' }}>{status}</span>
        </div>
        <div className="sync-timestamp">
          Last synced: {lastSynced ? lastSynced.slice(0, 19).replace('T', ' ') : 'Never'}
        </div>
        {message && (
          <p style={{ fontSize: 13, color: 'var(--text-secondary)', marginBottom: 16 }}>{message}</p>
        )}
        <button
          className="btn btn-primary"
          onClick={handleTrigger}
          disabled={loading || status === 'running'}
        >
          {loading ? 'Triggering...' : 'Trigger Sync'}
        </button>
      </div>
    </div>
  )
}
