import { useState } from 'react'
import { useApiList } from '../../hooks/use-api'
import * as skinsApi from '../../api/skins'
import type { Skin } from '../../types/models'
import StatusBadge from '../../components/common/StatusBadge'
import FormDialog from '../../components/common/FormDialog'
import ConfirmDialog from '../../components/common/ConfirmDialog'
import LoadingSpinner from '../../components/common/LoadingSpinner'
import '../pages.css'

function parseThemeColors(themeData: string): string[] {
  try {
    const parsed = JSON.parse(themeData)
    if (typeof parsed === 'object' && parsed !== null) {
      return Object.values(parsed).filter((v): v is string => typeof v === 'string' && v.startsWith('#')).slice(0, 6)
    }
  } catch { /* ignore */ }
  return []
}

export default function SkinsPage() {
  const { data: skins, loading, error, reload } = useApiList<Skin>(skinsApi.list)

  const [showForm, setShowForm] = useState(false)
  const [editSkin, setEditSkin] = useState<Skin | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<Skin | null>(null)
  const [form, setForm] = useState({ name: '', description: '', theme_data: '{}' })

  const openCreate = () => {
    setEditSkin(null)
    setForm({ name: '', description: '', theme_data: '{}' })
    setShowForm(true)
  }

  const openEdit = (s: Skin) => {
    setEditSkin(s)
    setForm({ name: s.name, description: s.description ?? '', theme_data: s.theme_data })
    setShowForm(true)
  }

  const handleSave = async () => {
    if (editSkin) {
      await skinsApi.update(editSkin.skin_id, form)
    } else {
      await skinsApi.create(form)
    }
    setShowForm(false)
    reload()
  }

  const handleDelete = async () => {
    if (!deleteTarget) return
    await skinsApi.remove(deleteTarget.skin_id)
    setDeleteTarget(null)
    reload()
  }

  const handleActivate = async (id: number) => {
    await skinsApi.activate(id)
    reload()
  }

  if (loading) return <LoadingSpinner />

  return (
    <div className="page-container">
      <div className="page-header">
        <h1 className="page-title">Skins</h1>
        <button className="btn btn-primary" onClick={openCreate}>New Skin</button>
      </div>

      {error && <div className="page-error">{error}</div>}

      <div className="card-grid">
        {skins.map((s) => {
          const colors = parseThemeColors(s.theme_data)
          return (
            <div key={s.skin_id} className="card" style={{ cursor: 'default' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
                <div className="card-title">{s.name}</div>
                {s.is_default && <StatusBadge status="live" />}
              </div>
              {s.description && <div className="card-meta">{s.description}</div>}
              {colors.length > 0 && (
                <div className="color-swatches">
                  {colors.map((c, i) => <div key={i} className="color-swatch" style={{ backgroundColor: c }} />)}
                </div>
              )}
              <div className="card-footer">
                <div style={{ display: 'flex', gap: 6 }}>
                  <button className="btn btn-sm btn-secondary" onClick={() => openEdit(s)}>Edit</button>
                  <button className="btn btn-sm btn-danger" onClick={() => setDeleteTarget(s)}>Delete</button>
                </div>
                {!s.is_default && (
                  <button className="btn btn-sm btn-primary" onClick={() => handleActivate(s.skin_id)}>Activate</button>
                )}
              </div>
            </div>
          )
        })}
        {skins.length === 0 && (
          <div style={{ color: 'var(--text-secondary)', padding: 40 }}>No skins configured.</div>
        )}
      </div>

      <FormDialog
        open={showForm}
        title={editSkin ? 'Edit Skin' : 'New Skin'}
        onSave={handleSave}
        onCancel={() => setShowForm(false)}
      >
        <div className="form-group">
          <label>Name</label>
          <input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
        </div>
        <div className="form-group">
          <label>Description</label>
          <input value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} />
        </div>
        <div className="form-group">
          <label>Theme Data (JSON)</label>
          <textarea
            value={form.theme_data}
            onChange={(e) => setForm({ ...form, theme_data: e.target.value })}
            rows={6}
            style={{ fontFamily: 'monospace', fontSize: 12 }}
          />
        </div>
      </FormDialog>

      <ConfirmDialog
        open={!!deleteTarget}
        title="Delete Skin"
        message={`Delete skin "${deleteTarget?.name}"?`}
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
        confirmLabel="Delete"
      />
    </div>
  )
}
