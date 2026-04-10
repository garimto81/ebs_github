import { useState, useEffect } from 'react'
import * as configsApi from '../../api/configs'
import type { Config } from '../../types/models'
import LoadingSpinner from '../../components/common/LoadingSpinner'
import '../pages.css'

const SECTIONS = ['output', 'overlay', 'game', 'rfid', 'system', 'statistics'] as const

export default function SettingsPage() {
  const [activeTab, setActiveTab] = useState<string>(SECTIONS[0])
  const [configs, setConfigs] = useState<Config[]>([])
  const [values, setValues] = useState<Record<string, string>>({})
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false
    setLoading(true)
    configsApi.getSection(activeTab).then((res) => {
      if (cancelled) return
      if (res.data) {
        setConfigs(res.data)
        const vals: Record<string, string> = {}
        for (const c of res.data) vals[c.key] = c.value
        setValues(vals)
      } else if (res.error) {
        setError(res.error.message)
      }
      setLoading(false)
    })
    return () => { cancelled = true }
  }, [activeTab])

  const handleSave = async () => {
    setSaving(true)
    setError(null)
    const res = await configsApi.updateSection(activeTab, values)
    if (res.error) setError(res.error.message)
    setSaving(false)
  }

  return (
    <div className="page-container">
      <div className="page-header">
        <h1 className="page-title">Settings</h1>
      </div>

      {error && <div className="page-error">{error}</div>}

      <div className="tab-bar">
        {SECTIONS.map((s) => (
          <button
            key={s}
            className={`tab-btn${activeTab === s ? ' active' : ''}`}
            onClick={() => setActiveTab(s)}
            style={{ textTransform: 'capitalize' }}
          >
            {s}
          </button>
        ))}
      </div>

      {loading ? (
        <LoadingSpinner />
      ) : (
        <div>
          {configs.map((c) => (
            <div key={c.key} className="config-row">
              <div className="config-key" title={c.description ?? ''}>{c.key}</div>
              <input
                className="config-value-input"
                value={values[c.key] ?? ''}
                onChange={(e) => setValues({ ...values, [c.key]: e.target.value })}
              />
            </div>
          ))}
          {configs.length === 0 && (
            <p style={{ color: 'var(--text-secondary)', padding: 20 }}>No configuration entries for this section.</p>
          )}
          {configs.length > 0 && (
            <div style={{ marginTop: 20 }}>
              <button className="btn btn-primary" onClick={handleSave} disabled={saving}>
                {saving ? 'Saving...' : 'Save'}
              </button>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
