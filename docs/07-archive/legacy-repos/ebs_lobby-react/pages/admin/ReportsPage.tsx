import { useState, useEffect } from 'react'
import * as reportsApi from '../../api/reports'
import LoadingSpinner from '../../components/common/LoadingSpinner'
import '../pages.css'

type ReportTab = 'hands_summary' | 'player_stats' | 'table_activity' | 'session_log'

const TABS: { key: ReportTab; label: string }[] = [
  { key: 'hands_summary', label: 'Hands Summary' },
  { key: 'player_stats', label: 'Player Stats' },
  { key: 'table_activity', label: 'Table Activity' },
  { key: 'session_log', label: 'Session Log' },
]

interface ReportRow {
  [key: string]: unknown
}

export default function ReportsPage() {
  const [activeTab, setActiveTab] = useState<ReportTab>('hands_summary')
  const [data, setData] = useState<ReportRow[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Filters
  const [dateFrom, setDateFrom] = useState('')
  const [dateTo, setDateTo] = useState('')

  useEffect(() => {
    let cancelled = false
    setLoading(true)
    setError(null)
    const params: Record<string, string | number> = {}
    if (dateFrom) params.date_from = dateFrom
    if (dateTo) params.date_to = dateTo

    reportsApi.getReport<ReportRow[]>(activeTab, params).then((res) => {
      if (cancelled) return
      if (res.data && Array.isArray(res.data)) {
        setData(res.data)
      } else if (res.error) {
        setError(res.error.message)
        setData([])
      } else {
        setData([])
      }
      setLoading(false)
    })
    return () => { cancelled = true }
  }, [activeTab, dateFrom, dateTo])

  const columns = data.length > 0 ? Object.keys(data[0]) : []

  return (
    <div className="page-container">
      <div className="page-header">
        <h1 className="page-title">Reports</h1>
      </div>

      {error && <div className="page-error">{error}</div>}

      <div className="tab-bar">
        {TABS.map((t) => (
          <button
            key={t.key}
            className={`tab-btn${activeTab === t.key ? ' active' : ''}`}
            onClick={() => setActiveTab(t.key)}
          >
            {t.label}
          </button>
        ))}
      </div>

      <div className="filter-bar">
        <input type="date" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} />
        <input type="date" value={dateTo} onChange={(e) => setDateTo(e.target.value)} />
      </div>

      {loading ? (
        <LoadingSpinner />
      ) : data.length === 0 ? (
        <p style={{ color: 'var(--text-secondary)', padding: 20 }}>No data for this report.</p>
      ) : (
        <div className="data-table-wrapper">
          <table className="data-table">
            <thead>
              <tr>
                {columns.map((col) => (
                  <th key={col}>{col.replace(/_/g, ' ')}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {data.map((row, i) => (
                <tr key={i}>
                  {columns.map((col) => (
                    <td key={col}>{String(row[col] ?? '—')}</td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
