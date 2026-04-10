import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useApiList } from '../hooks/use-api'
import { useAuthStore } from '../store/auth-store'
import { useNavStore } from '../store/nav-store'
import * as seriesApi from '../api/series'
import * as competitionsApi from '../api/competitions'
import type { Series, Competition } from '../types/models'
import StatusBadge from '../components/common/StatusBadge'
import FormDialog from '../components/common/FormDialog'
import LoadingSpinner from '../components/common/LoadingSpinner'
import './pages.css'

function formatMonth(key: string): string {
  if (key === 'Unknown') return 'Unknown'
  const [y, m] = key.split('-')
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
  return `${months[Number(m) - 1]} ${y}`
}

export default function SeriesListPage() {
  const navigate = useNavigate()
  const role = useAuthStore((s) => s.user?.role)
  const setSeriesId = useNavStore((s) => s.setSeriesId)
  const { data: seriesList, loading, error, reload } = useApiList<Series>(seriesApi.list)
  const { data: competitions } = useApiList<Competition>(competitionsApi.list)

  const [showForm, setShowForm] = useState(false)
  const [search, setSearch] = useState('')
  const [form, setForm] = useState({
    series_name: '',
    year: new Date().getFullYear(),
    begin_at: '',
    end_at: '',
    competition_id: 0,
    time_zone: 'UTC',
    country_code: '',
    is_displayed: true,
    is_demo: false,
    image_url: '',
  })

  const competitionMap = new Map(competitions.map((c) => [c.competition_id, c.name]))

  const handleClick = (s: Series) => {
    setSeriesId(s.series_id, s.series_name)
    navigate(`/series/${s.series_id}/events`)
  }

  const handleSave = async () => {
    await seriesApi.create({
      ...form,
      image_url: form.image_url || null,
      country_code: form.country_code || null,
    })
    setShowForm(false)
    setForm({ series_name: '', year: new Date().getFullYear(), begin_at: '', end_at: '', competition_id: 0, time_zone: 'UTC', country_code: '', is_displayed: true, is_demo: false, image_url: '' })
    reload()
  }

  const filtered = seriesList.filter((s) =>
    s.series_name.toLowerCase().includes(search.toLowerCase())
  )

  const grouped = filtered.reduce((acc, s) => {
    const key = s.begin_at?.slice(0, 7) ?? 'Unknown'
    ;(acc[key] ??= []).push(s)
    return acc
  }, {} as Record<string, Series[]>)

  const sortedMonths = Object.keys(grouped).sort().reverse()

  if (loading) return <LoadingSpinner />

  return (
    <div className="page-container">
      <div className="page-header">
        <div>
          <h1 className="page-title">Series</h1>
          <p className="page-subtitle">{seriesList.length} series total</p>
        </div>
        <div style={{ display: 'flex', alignItems: 'center' }}>
          <input
            placeholder="Search series..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            style={{ padding: '6px 12px', borderRadius: 6, border: '1px solid var(--border)', fontSize: 13, marginRight: 8 }}
          />
          {role === 'admin' && (
            <button className="btn btn-primary" onClick={() => setShowForm(true)}>New Series</button>
          )}
        </div>
      </div>

      {error && <div className="page-error">{error}</div>}

      {sortedMonths.map((month) => (
        <div key={month}>
          <h2 style={{ fontSize: 14, color: 'var(--text-secondary)', margin: '16px 0 8px', fontWeight: 600 }}>
            {formatMonth(month)} ({grouped[month].length})
          </h2>
          <div className="card-grid">
            {grouped[month].map((s) => (
              <div key={s.series_id} className="card" onClick={() => handleClick(s)}>
                <div className="card-title">{s.series_name}</div>
                <div className="card-meta">Year: {s.year}</div>
                <div className="card-meta">
                  {s.begin_at?.slice(0, 10)} &rarr; {s.end_at?.slice(0, 10)}
                </div>
                <div className="card-meta">Competition: {competitionMap.get(s.competition_id) ?? '—'}</div>
                <div className="card-footer">
                  <StatusBadge status={s.is_completed ? 'completed' : 'running'} />
                  <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{s.currency}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      ))}
      {filtered.length === 0 && !loading && (
        <div style={{ color: 'var(--text-secondary)', padding: 40 }}>No series found.</div>
      )}

      <FormDialog open={showForm} title="New Series" onSave={handleSave} onCancel={() => setShowForm(false)}>
        <div className="form-group">
          <label>Series Name</label>
          <input value={form.series_name} onChange={(e) => setForm({ ...form, series_name: e.target.value })} />
        </div>
        <div className="form-group">
          <label>Year</label>
          <input type="number" value={form.year} onChange={(e) => setForm({ ...form, year: Number(e.target.value) })} />
        </div>
        <div className="form-group">
          <label>Begin Date</label>
          <input type="date" value={form.begin_at} onChange={(e) => setForm({ ...form, begin_at: e.target.value })} />
        </div>
        <div className="form-group">
          <label>End Date</label>
          <input type="date" value={form.end_at} onChange={(e) => setForm({ ...form, end_at: e.target.value })} />
        </div>
        <div className="form-group">
          <label>Competition</label>
          <select value={form.competition_id} onChange={(e) => setForm({ ...form, competition_id: Number(e.target.value) })}>
            <option value={0}>Select...</option>
            {competitions.map((c) => (
              <option key={c.competition_id} value={c.competition_id}>{c.name}</option>
            ))}
          </select>
        </div>
        <div className="form-group">
          <label>Time Zone *</label>
          <select value={form.time_zone} onChange={(e) => setForm({ ...form, time_zone: e.target.value })}>
            <option value="UTC">UTC</option>
            <option value="America/Los_Angeles">America/Los_Angeles (PT)</option>
            <option value="America/New_York">America/New_York (ET)</option>
            <option value="Europe/London">Europe/London (GMT)</option>
            <option value="Europe/Paris">Europe/Paris (CET)</option>
            <option value="Asia/Seoul">Asia/Seoul (KST)</option>
          </select>
        </div>
        <div className="form-group">
          <label>Country Code</label>
          <input value={form.country_code} maxLength={2} onChange={(e) => setForm({ ...form, country_code: e.target.value.toUpperCase() })} placeholder="US" />
        </div>
        <div className="form-group">
          <label>Series Image URL</label>
          <input value={form.image_url} onChange={(e) => setForm({ ...form, image_url: e.target.value })} placeholder="https://..." />
        </div>
        <div className="form-group" style={{ display: 'flex', gap: 16 }}>
          <label style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 13 }}>
            <input type="checkbox" checked={form.is_displayed} onChange={(e) => setForm({ ...form, is_displayed: e.target.checked })} />
            Is Displayed
          </label>
          <label style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 13 }}>
            <input type="checkbox" checked={form.is_demo} onChange={(e) => setForm({ ...form, is_demo: e.target.checked })} />
            Is Demo
          </label>
        </div>
      </FormDialog>
    </div>
  )
}
