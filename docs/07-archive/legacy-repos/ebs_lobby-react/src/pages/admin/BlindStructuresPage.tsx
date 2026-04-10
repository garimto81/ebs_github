import { useState, useEffect, useCallback } from 'react'
import { useApiList } from '../../hooks/use-api'
import * as bsApi from '../../api/blind-structures'
import * as bslApi from '../../api/blind-structure-levels'
import type { BlindStructure, BlindStructureLevel } from '../../types/models'
import DataTable from '../../components/common/DataTable'
import type { Column } from '../../components/common/DataTable'
import FormDialog from '../../components/common/FormDialog'
import ConfirmDialog from '../../components/common/ConfirmDialog'
import '../pages.css'

interface LevelDraft {
  level_no: number
  small_blind: number
  big_blind: number
  ante: number
  duration_minutes: number
}

export default function BlindStructuresPage() {
  const { data: structures, loading, error, reload } = useApiList<BlindStructure>(bsApi.list)

  const [selectedId, setSelectedId] = useState<number | null>(null)
  const [levels, setLevels] = useState<BlindStructureLevel[]>([])
  const [levelsLoading, setLevelsLoading] = useState(false)

  const [showForm, setShowForm] = useState(false)
  const [formName, setFormName] = useState('')
  const [formLevels, setFormLevels] = useState<LevelDraft[]>([])
  const [editTarget, setEditTarget] = useState<BlindStructure | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<BlindStructure | null>(null)

  const loadLevels = useCallback(async (bsId: number) => {
    setLevelsLoading(true)
    const res = await bslApi.list(bsId)
    setLevels(res.data ?? [])
    setLevelsLoading(false)
  }, [])

  useEffect(() => {
    if (selectedId) loadLevels(selectedId)
  }, [selectedId, loadLevels])

  const openCreate = () => {
    setEditTarget(null)
    setFormName('')
    setFormLevels([{ level_no: 1, small_blind: 25, big_blind: 50, ante: 0, duration_minutes: 20 }])
    setShowForm(true)
  }

  const openEdit = (bs: BlindStructure) => {
    setEditTarget(bs)
    setFormName(bs.name)
    // Load existing levels into form
    if (selectedId === bs.blind_structure_id) {
      setFormLevels(levels.map((l) => ({
        level_no: l.level_no,
        small_blind: l.small_blind,
        big_blind: l.big_blind,
        ante: l.ante,
        duration_minutes: l.duration_minutes,
      })))
    } else {
      setFormLevels([])
    }
    setShowForm(true)
  }

  const handleSave = async () => {
    if (editTarget) {
      await bsApi.update(editTarget.blind_structure_id, { name: formName })
    } else {
      const res = await bsApi.create({ name: formName })
      if (res.data) {
        for (const lvl of formLevels) {
          await bslApi.create(res.data.blind_structure_id, lvl)
        }
      }
    }
    setShowForm(false)
    reload()
  }

  const handleDelete = async () => {
    if (!deleteTarget) return
    await bsApi.remove(deleteTarget.blind_structure_id)
    setDeleteTarget(null)
    if (selectedId === deleteTarget.blind_structure_id) {
      setSelectedId(null)
      setLevels([])
    }
    reload()
  }

  const addLevel = () => {
    const next = formLevels.length + 1
    const prev = formLevels[formLevels.length - 1]
    setFormLevels([...formLevels, {
      level_no: next,
      small_blind: prev ? prev.small_blind * 2 : 25,
      big_blind: prev ? prev.big_blind * 2 : 50,
      ante: prev ? prev.ante : 0,
      duration_minutes: prev ? prev.duration_minutes : 20,
    }])
  }

  const removeLevel = (idx: number) => {
    setFormLevels(formLevels.filter((_, i) => i !== idx))
  }

  const updateLevel = (idx: number, field: keyof LevelDraft, val: number) => {
    const updated = [...formLevels]
    updated[idx] = { ...updated[idx], [field]: val }
    setFormLevels(updated)
  }

  const structureColumns: Column<BlindStructure>[] = [
    { header: 'Name', accessor: 'name' },
    { header: 'Created', accessor: (r) => r.created_at?.slice(0, 10) ?? '' },
    {
      header: 'Actions',
      accessor: () => null,
      render: (_v, row) => (
        <div style={{ display: 'flex', gap: 6 }}>
          <button className="btn btn-sm btn-secondary" onClick={(e) => { e.stopPropagation(); openEdit(row) }}>Edit</button>
          <button className="btn btn-sm btn-danger" onClick={(e) => { e.stopPropagation(); setDeleteTarget(row) }}>Delete</button>
        </div>
      ),
    },
  ]

  const levelColumns: Column<BlindStructureLevel>[] = [
    { header: 'Level', accessor: 'level_no' },
    { header: 'SB', accessor: (r) => r.small_blind.toLocaleString() },
    { header: 'BB', accessor: (r) => r.big_blind.toLocaleString() },
    { header: 'Ante', accessor: (r) => r.ante.toLocaleString() },
    { header: 'Duration', accessor: (r) => `${r.duration_minutes} min` },
  ]

  return (
    <div className="page-container">
      <div className="page-header">
        <h1 className="page-title">Blind Structures</h1>
        <button className="btn btn-primary" onClick={openCreate}>New Structure</button>
      </div>

      {error && <div className="page-error">{error}</div>}

      <DataTable<BlindStructure>
        columns={structureColumns}
        data={structures}
        loading={loading}
        emptyMessage="No blind structures"
        onRowClick={(row) => setSelectedId(row.blind_structure_id)}
      />

      {selectedId && (
        <div style={{ marginTop: 24 }}>
          <h2 style={{ fontSize: 18, fontWeight: 600, marginBottom: 12 }}>
            Levels — {structures.find((s) => s.blind_structure_id === selectedId)?.name}
          </h2>
          <DataTable<BlindStructureLevel>
            columns={levelColumns}
            data={levels}
            loading={levelsLoading}
            emptyMessage="No levels defined"
          />
        </div>
      )}

      <FormDialog
        open={showForm}
        title={editTarget ? 'Edit Blind Structure' : 'New Blind Structure'}
        onSave={handleSave}
        onCancel={() => setShowForm(false)}
      >
        <div className="form-group">
          <label>Name</label>
          <input value={formName} onChange={(e) => setFormName(e.target.value)} />
        </div>
        {!editTarget && (
          <>
            <h4 style={{ fontSize: 14, marginBottom: 8 }}>Levels</h4>
            <div className="level-row">
              <span className="level-header">#</span>
              <span className="level-header">SB</span>
              <span className="level-header">BB</span>
              <span className="level-header">Ante</span>
              <span className="level-header">Min</span>
              <span />
            </div>
            {formLevels.map((lvl, i) => (
              <div key={i} className="level-row">
                <span style={{ fontSize: 13, textAlign: 'center' }}>{lvl.level_no}</span>
                <input type="number" value={lvl.small_blind} onChange={(e) => updateLevel(i, 'small_blind', Number(e.target.value))} />
                <input type="number" value={lvl.big_blind} onChange={(e) => updateLevel(i, 'big_blind', Number(e.target.value))} />
                <input type="number" value={lvl.ante} onChange={(e) => updateLevel(i, 'ante', Number(e.target.value))} />
                <input type="number" value={lvl.duration_minutes} onChange={(e) => updateLevel(i, 'duration_minutes', Number(e.target.value))} />
                <button className="btn btn-sm btn-danger" onClick={() => removeLevel(i)} style={{ padding: '2px 6px' }}>X</button>
              </div>
            ))}
            <button className="btn btn-sm btn-secondary" onClick={addLevel} style={{ marginTop: 8 }}>+ Add Level</button>
          </>
        )}
      </FormDialog>

      <ConfirmDialog
        open={!!deleteTarget}
        title="Delete Blind Structure"
        message={`Delete "${deleteTarget?.name}" and all its levels?`}
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
        confirmLabel="Delete"
      />
    </div>
  )
}
