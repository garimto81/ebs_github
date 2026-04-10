import { useState, useCallback, useEffect } from 'react'
import { useParams } from 'react-router-dom'
import { useApiList, useApiGet } from '../hooks/use-api'
import { useAuthStore } from '../store/auth-store'
import { useNavStore } from '../store/nav-store'
import { useWebSocket } from '../hooks/use-websocket'
import * as tablesApi from '../api/tables'
import * as seatsApi from '../api/seats'
import * as playersApi from '../api/players'
import type { Table, TableSeat, Player } from '../types/models'
import { GameType, TableStatus } from '../types/enums'
import StatusBadge from '../components/common/StatusBadge'
import FormDialog from '../components/common/FormDialog'
import LoadingSpinner from '../components/common/LoadingSpinner'
import './pages.css'

const SEAT_POSITIONS: Record<number, { top: string; left: string }> = {
  0: { top: '0px', left: '50%' },
  1: { top: '60px', left: '88%' },
  2: { top: '170px', left: '95%' },
  3: { top: '280px', left: '82%' },
  4: { top: '310px', left: '60%' },
  5: { top: '310px', left: '35%' },
  6: { top: '280px', left: '12%' },
  7: { top: '170px', left: '0%' },
  8: { top: '60px', left: '6%' },
  9: { top: '0px', left: '30%' },
}

function getNextStatuses(current: string): string[] {
  switch (current) {
    case TableStatus.EMPTY:  return [TableStatus.SETUP]
    case TableStatus.SETUP:  return [TableStatus.LIVE]
    case TableStatus.LIVE:   return [TableStatus.PAUSED, TableStatus.CLOSED]
    case TableStatus.PAUSED: return [TableStatus.LIVE, TableStatus.CLOSED]
    default: return []
  }
}

// ── Expanded panel for a single table ──────────────────────────────────────
interface ExpandPanelProps {
  table: Table
  onClose: () => void
}

function TableExpandPanel({ table, onClose }: ExpandPanelProps) {
  const tid = table.table_id

  const fetchSeats = useCallback(
    () => seatsApi.getByTable(tid) as ReturnType<typeof seatsApi.getByTable>,
    [tid],
  )
  const { data: seats, reload: reloadSeats } = useApiList<TableSeat>(fetchSeats, {}, [tid])

  const { data: freshTable, reload: reloadTable } = useApiGet<Table>(
    () => tablesApi.getById(tid),
    [tid],
  )

  const current = freshTable ?? table

  const [seatDialog, setSeatDialog] = useState<{ open: boolean; seatNo: number }>({ open: false, seatNo: 0 })
  const [playerSearch, setPlayerSearch] = useState('')
  const [searchResults, setSearchResults] = useState<Player[]>([])
  const [selectedPlayer, setSelectedPlayer] = useState<Player | null>(null)

  const handleSearchPlayers = async (q: string) => {
    setPlayerSearch(q)
    if (q.length < 2) { setSearchResults([]); return }
    const res = await playersApi.search(q)
    if (res.data) setSearchResults(res.data)
  }

  const handleAssignPlayer = async () => {
    if (!selectedPlayer) return
    await seatsApi.update(tid, seatDialog.seatNo, {
      player_id: selectedPlayer.player_id,
      player_name: `${selectedPlayer.first_name} ${selectedPlayer.last_name}`,
      status: 'occupied',
    })
    setSeatDialog({ open: false, seatNo: 0 })
    setSelectedPlayer(null)
    setPlayerSearch('')
    setSearchResults([])
    reloadSeats()
  }

  const handleStatusChange = async (newStatus: string) => {
    // Feature Table: Setup → Live 시 RFID + 덱 확인 필수
    if (newStatus === 'live' && current.type === 'feature') {
      if (!current.rfid_reader_id) {
        alert('Feature Table requires RFID reader assigned before going Live.')
        return
      }
      if (!current.deck_registered) {
        alert('Feature Table requires deck registered before going Live.')
        return
      }
    }
    await tablesApi.update(tid, { status: newStatus })
    reloadTable()
  }

  const handleLaunchCc = async () => {
    const res = await tablesApi.launchCc(tid)
    if (res.data?.url) {
      window.open(res.data.url, '_blank')
    }
  }

  // WebSocket: real-time seat/hand updates
  const { lastMessage } = useWebSocket(`table:${tid}`)
  useEffect(() => {
    if (!lastMessage) return
    if (lastMessage.type === 'table:player_seated' || lastMessage.type === 'table:player_unseated') {
      reloadSeats()
    }
    if (lastMessage.type === 'table:status_changed') {
      reloadTable()
    }
  }, [lastMessage, reloadSeats, reloadTable])

  const seatMap = new Map(seats.map((s) => [s.seat_no, s]))
  const nextStatuses = getNextStatuses(current.status)

  return (
    <div className="table-expand-panel">
      <div className="expand-panel-close" onClick={onClose}>✕</div>

      <div className="table-detail-layout">
        {/* Left: Table Info */}
        <div className="detail-panel">
          <h3>Table Info</h3>
          <div className="detail-row"><span className="detail-label">Name</span><span className="detail-value">{current.name}</span></div>
          <div className="detail-row"><span className="detail-label">Type</span><span className="detail-value" style={{ textTransform: 'capitalize' }}>{current.type}</span></div>
          <div className="detail-row"><span className="detail-label">Game</span><span className="detail-value">{GameType[current.game_type] ?? '—'}</span></div>
          <div className="detail-row"><span className="detail-label">Blinds</span><span className="detail-value">{current.small_blind ?? 0}/{current.big_blind ?? 0}</span></div>
          <div className="detail-row"><span className="detail-label">Status</span><span className="detail-value"><StatusBadge status={current.status} /></span></div>
          <div className="detail-row"><span className="detail-label">RFID</span><span className="detail-value">{current.rfid_reader_id ? `Reader #${current.rfid_reader_id}` : 'None'}</span></div>
          <div className="detail-row"><span className="detail-label">Output</span><span className="detail-value">{current.output_type ?? 'None'}</span></div>
          <div className="detail-row"><span className="detail-label">Delay</span><span className="detail-value">{current.delay_seconds}s</span></div>
        </div>

        {/* Center: Oval seat diagram */}
        <div className="detail-panel" style={{ display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
          <div className="oval-table-container">
            <div className="oval-felt">{current.name}</div>
            {Array.from({ length: current.max_players }, (_, i) => {
              const seat = seatMap.get(i)
              const pos = SEAT_POSITIONS[i] ?? { top: '0px', left: '0px' }
              const isOccupied = seat && seat.status === 'occupied'
              return (
                <div
                  key={i}
                  className="seat-node"
                  style={{ top: pos.top, left: pos.left, transform: 'translateX(-50%)' }}
                  onClick={() => {
                    setSeatDialog({ open: true, seatNo: i })
                    setSelectedPlayer(null)
                    setPlayerSearch('')
                    setSearchResults([])
                  }}
                >
                  <div className={`seat-circle ${isOccupied ? 'occupied' : 'vacant'}`}>{i}</div>
                  <div className="seat-name">{isOccupied ? seat.player_name : 'Empty'}</div>
                  {isOccupied && <div className="seat-chips">{seat.chip_count.toLocaleString()}</div>}
                </div>
              )
            })}
          </div>
        </div>

        {/* Right: Controls */}
        <div className="detail-panel">
          <h3>Controls</h3>
          {nextStatuses.length > 0 ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {nextStatuses.map((ns) => (
                <button
                  key={ns}
                  className={`btn ${ns === 'live' ? 'btn-primary' : ns === 'closed' ? 'btn-danger' : 'btn-secondary'}`}
                  onClick={() => handleStatusChange(ns)}
                  style={{ textTransform: 'capitalize' }}
                >
                  Go {ns}
                </button>
              ))}
            </div>
          ) : (
            <p style={{ color: 'var(--text-secondary)', fontSize: 13 }}>No transitions available.</p>
          )}
          <div className="detail-actions" style={{ flexDirection: 'column' }}>
            <button className="btn btn-secondary" onClick={handleLaunchCc}>Launch CC</button>
          </div>
        </div>
      </div>

      {/* Seat assignment dialog */}
      <FormDialog
        open={seatDialog.open}
        title={`Assign Player — Seat ${seatDialog.seatNo}`}
        onSave={handleAssignPlayer}
        onCancel={() => setSeatDialog({ open: false, seatNo: 0 })}
        saveLabel="Assign"
      >
        <div className="form-group">
          <label>Search Player</label>
          <input
            value={playerSearch}
            onChange={(e) => handleSearchPlayers(e.target.value)}
            placeholder="Type name to search..."
          />
        </div>
        {searchResults.length > 0 && (
          <div style={{ maxHeight: 200, overflowY: 'auto', marginBottom: 12 }}>
            {searchResults.map((p) => (
              <div
                key={p.player_id}
                onClick={() => setSelectedPlayer(p)}
                style={{
                  padding: '8px 12px',
                  cursor: 'pointer',
                  background: selectedPlayer?.player_id === p.player_id ? 'var(--bg-tertiary)' : 'transparent',
                  borderRadius: 4,
                  fontSize: 13,
                }}
              >
                {p.first_name} {p.last_name}{' '}
                {p.wsop_id && <span style={{ color: 'var(--text-secondary)' }}>({p.wsop_id})</span>}
              </div>
            ))}
          </div>
        )}
        {selectedPlayer && (
          <div style={{ padding: 8, background: 'var(--bg-tertiary)', borderRadius: 6, fontSize: 13 }}>
            Selected: <strong>{selectedPlayer.first_name} {selectedPlayer.last_name}</strong>
          </div>
        )}
      </FormDialog>
    </div>
  )
}

// ── Main page ───────────────────────────────────────────────────────────────
export default function TableListPage() {
  const { flightId } = useParams<{ flightId: string }>()
  const role = useAuthStore((s) => s.user?.role)
  const setFlightId = useNavStore((s) => s.setFlightId)
  const setTableId = useNavStore((s) => s.setTableId)
  const fid = Number(flightId)

  useEffect(() => {
    setFlightId(fid)
  }, [fid, setFlightId])

  const { data: tables, loading, error, reload } = useApiList<Table>(
    tablesApi.list,
    { event_flight_id: fid, ...(role === 'operator' ? { assigned_to_me: 1 } : {}) },
    [fid, role],
  )

  const [typeFilter, setTypeFilter] = useState<string>('all')
  const [statusFilter, setStatusFilter] = useState<string>('all')

  const filtered = tables.filter((t) =>
    (typeFilter === 'all' || t.type === typeFilter) &&
    (statusFilter === 'all' || t.status === statusFilter),
  )

  // WebSocket: real-time table list updates
  const { lastMessage: flightMsg } = useWebSocket(`flight:${fid}`)
  useEffect(() => {
    if (!flightMsg) return
    if (flightMsg.type === 'table:status_changed' || flightMsg.type === 'table:created' || flightMsg.type === 'table:player_seated') {
      reload()
    }
  }, [flightMsg, reload])

  const [expandedTableId, setExpandedTableId] = useState<number | null>(null)
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({ name: '', type: 'general', max_players: 9, game_type: 0, small_blind: 0, big_blind: 0, ante_amount: 0, delay_seconds: 0 })

  const handleCardClick = (t: Table) => {
    const next = expandedTableId === t.table_id ? null : t.table_id
    setExpandedTableId(next)
    setTableId(next, next ? t.name : undefined)
  }

  const handleLaunchCc = async (tid: number) => {
    const res = await tablesApi.launchCc(tid)
    if (res.data?.url) {
      window.open(res.data.url, '_blank')
    }
  }

  const handleSave = async () => {
    await tablesApi.create({ ...form, event_flight_id: fid })
    setShowForm(false)
    setForm({ name: '', type: 'general', max_players: 9, game_type: 0, small_blind: 0, big_blind: 0, ante_amount: 0, delay_seconds: 0 })
    reload()
  }

  if (loading) return <LoadingSpinner />

  return (
    <div className="page-container">
      <div className="page-header">
        <div>
          <h1 className="page-title">Tables</h1>
          <p className="page-subtitle">Flight #{flightId}</p>
        </div>
        {role === 'admin' && (
          <button className="btn btn-primary" onClick={() => setShowForm(true)}>New Table</button>
        )}
      </div>

      {error && <div className="page-error">{error}</div>}

      {/* Summary bar */}
      <div style={{ display: 'flex', gap: 16, padding: '8px 0', fontSize: 13, color: 'var(--text-secondary)' }}>
        <span>Tables: {filtered.length}</span>
        <span>Players: {filtered.reduce((n, t) => n + t.max_players, 0)}</span>
      </div>

      {/* Filters */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
        <select value={typeFilter} onChange={(e) => setTypeFilter(e.target.value)} style={{ fontSize: 13 }}>
          <option value="all">All Types</option>
          <option value="general">General</option>
          <option value="feature">Feature</option>
        </select>
        <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} style={{ fontSize: 13 }}>
          <option value="all">All Status</option>
          <option value="empty">Empty</option>
          <option value="setup">Setup</option>
          <option value="live">Live</option>
          <option value="paused">Paused</option>
          <option value="closed">Closed</option>
        </select>
      </div>

      <div className="card-grid">
        {filtered.map((t) => {
          const isExpanded = expandedTableId === t.table_id
          return (
            <div key={t.table_id} className="card-with-panel">
              {/* Card */}
              <div
                className={`card${t.type === 'feature' ? ' feature' : ''}${isExpanded ? ' expanded' : ''}`}
                onClick={() => handleCardClick(t)}
              >
                <div className="card-title">{t.name}</div>
                <div className="card-meta">{GameType[t.game_type] ?? `Game #${t.game_type}`}</div>
                <div className="card-meta">Max Players: {t.max_players}</div>

                {/* Feature table inline indicators */}
                {t.type === 'feature' && (
                  <div className="card-indicators">
                    <span className={`rfid-indicator${t.rfid_reader_id ? '' : ' off'}`}>
                      RFID {t.rfid_reader_id ? 'ON' : 'OFF'}
                    </span>
                    {t.output_type && (
                      <span className="rfid-indicator">
                        {t.output_type}
                      </span>
                    )}
                  </div>
                )}

                <div className="card-footer">
                  <StatusBadge status={t.status} />
                  <div className="card-footer-actions">
                    <span style={{ fontSize: 12, color: 'var(--text-secondary)', textTransform: 'capitalize' }}>{t.type}</span>
                    <button
                      className="btn btn-primary btn-sm"
                      onClick={(e) => {
                        e.stopPropagation()
                        handleLaunchCc(t.table_id)
                      }}
                    >
                      Enter CC
                    </button>
                  </div>
                </div>
              </div>

              {/* Expand panel — spans full grid width */}
              {isExpanded && (
                <TableExpandPanel
                  table={t}
                  onClose={() => {
                    setExpandedTableId(null)
                    setTableId(null)
                  }}
                />
              )}
            </div>
          )
        })}

        {filtered.length === 0 && (
          <div style={{ color: 'var(--text-secondary)', padding: 40 }}>
            {tables.length === 0 ? 'No tables in this flight.' : 'No tables match the selected filters.'}
          </div>
        )}
      </div>

      <FormDialog open={showForm} title="New Table" onSave={handleSave} onCancel={() => setShowForm(false)}>
        <div className="form-group">
          <label>Table Name</label>
          <input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
        </div>
        <div className="form-group">
          <label>Type</label>
          <select value={form.type} onChange={(e) => setForm({ ...form, type: e.target.value })}>
            <option value="general">General</option>
            <option value="feature">Feature</option>
          </select>
        </div>
        <div className="form-group">
          <label>Max Players</label>
          <input type="number" value={form.max_players} onChange={(e) => setForm({ ...form, max_players: Number(e.target.value) })} />
        </div>
        <div className="form-group">
          <label>Game Type</label>
          <select value={form.game_type} onChange={(e) => setForm({ ...form, game_type: Number(e.target.value) })}>
            {Object.entries(GameType).map(([k, v]) => (
              <option key={k} value={k}>{v}</option>
            ))}
          </select>
        </div>
        <div className="form-group">
          <label>Small Blind</label>
          <input type="number" min={0} value={form.small_blind} onChange={(e) => setForm({ ...form, small_blind: Number(e.target.value) })} />
        </div>
        <div className="form-group">
          <label>Big Blind</label>
          <input type="number" min={0} value={form.big_blind} onChange={(e) => setForm({ ...form, big_blind: Number(e.target.value) })} />
        </div>
        <div className="form-group">
          <label>Ante</label>
          <input type="number" min={0} value={form.ante_amount} onChange={(e) => setForm({ ...form, ante_amount: Number(e.target.value) })} />
        </div>
        <div className="form-group">
          <label>Output Delay (seconds)</label>
          <input type="number" min={0} value={form.delay_seconds} onChange={(e) => setForm({ ...form, delay_seconds: Number(e.target.value) })} />
        </div>
      </FormDialog>
    </div>
  )
}
