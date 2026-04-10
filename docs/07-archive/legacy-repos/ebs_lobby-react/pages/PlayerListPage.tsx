import { useState } from 'react'
import { useApiList } from '../hooks/use-api'
import * as playersApi from '../api/players'
import type { Player } from '../types/models'
import LoadingSpinner from '../components/common/LoadingSpinner'
import FormDialog from '../components/common/FormDialog'
import './pages.css'

export default function PlayerListPage() {
  const [search, setSearch] = useState('')
  const { data: players, loading, error, reload } = useApiList<Player>(
    playersApi.list,
    search.length >= 2 ? { q: search } : {},
    [search],
  )

  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({
    first_name: '',
    last_name: '',
    wsop_id: '',
    nationality: '',
    country_code: '',
  })

  const handleSave = async () => {
    await playersApi.create({
      ...form,
      wsop_id: form.wsop_id || null,
      nationality: form.nationality || null,
      country_code: form.country_code || null,
    })
    setShowForm(false)
    setForm({ first_name: '', last_name: '', wsop_id: '', nationality: '', country_code: '' })
    reload()
  }

  if (loading) return <LoadingSpinner />

  return (
    <div className="page-container">
      <div className="page-header">
        <div>
          <h1 className="page-title">Players</h1>
          <p className="page-subtitle">{players.length} registered</p>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <input
            placeholder="Search players..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            style={{ padding: '6px 12px', borderRadius: 6, border: '1px solid var(--border)', fontSize: 13 }}
          />
          <button className="btn btn-primary" onClick={() => setShowForm(true)}>New Player</button>
        </div>
      </div>

      {error && <div className="page-error">{error}</div>}

      <div className="data-table-wrapper">
        <table className="data-table">
          <thead>
            <tr>
              <th>WSOP ID</th>
              <th>Name</th>
              <th>Nationality</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {players.length === 0 ? (
              <tr><td colSpan={4} className="empty-row">No players found</td></tr>
            ) : (
              players.map((p) => (
                <tr key={p.player_id}>
                  <td>{p.wsop_id ?? '—'}</td>
                  <td>{p.first_name} {p.last_name}</td>
                  <td>{p.nationality ?? p.country_code ?? '—'}</td>
                  <td style={{ textTransform: 'capitalize' }}>{p.player_status}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <FormDialog open={showForm} title="New Player" onSave={handleSave} onCancel={() => setShowForm(false)}>
        <div className="form-group">
          <label>First Name *</label>
          <input value={form.first_name} onChange={(e) => setForm({ ...form, first_name: e.target.value })} required />
        </div>
        <div className="form-group">
          <label>Last Name *</label>
          <input value={form.last_name} onChange={(e) => setForm({ ...form, last_name: e.target.value })} required />
        </div>
        <div className="form-group">
          <label>WSOP ID</label>
          <input value={form.wsop_id} onChange={(e) => setForm({ ...form, wsop_id: e.target.value })} />
        </div>
        <div className="form-group">
          <label>Nationality</label>
          <input value={form.nationality} onChange={(e) => setForm({ ...form, nationality: e.target.value })} />
        </div>
        <div className="form-group">
          <label>Country Code</label>
          <input
            value={form.country_code}
            maxLength={2}
            onChange={(e) => setForm({ ...form, country_code: e.target.value.toUpperCase() })}
            placeholder="US"
          />
        </div>
      </FormDialog>
    </div>
  )
}
