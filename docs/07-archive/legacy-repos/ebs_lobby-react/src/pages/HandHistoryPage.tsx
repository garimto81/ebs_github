import { useState } from 'react'
import { useApiList } from '../hooks/use-api'
import * as handsApi from '../api/hands'
import type { Hand, HandPlayer, HandAction } from '../types/models'
import { GameType } from '../types/enums'
import DataTable from '../components/common/DataTable'
import type { Column } from '../components/common/DataTable'
import './pages.css'

export default function HandHistoryPage() {
  const [tableFilter, setTableFilter] = useState('')

  const params: Record<string, string | number> = {}
  if (tableFilter) params.table_id = Number(tableFilter)

  const { data: hands, loading, error } = useApiList<Hand>(handsApi.list, params, [tableFilter])

  const [expandedId, setExpandedId] = useState<number | null>(null)
  const [players, setPlayers] = useState<HandPlayer[]>([])
  const [actions, setActions] = useState<HandAction[]>([])

  const toggleExpand = async (hand: Hand) => {
    if (expandedId === hand.hand_id) {
      setExpandedId(null)
      return
    }
    setExpandedId(hand.hand_id)
    const [pRes, aRes] = await Promise.all([
      handsApi.getPlayers(hand.hand_id),
      handsApi.getActions(hand.hand_id),
    ])
    setPlayers(pRes.data ?? [])
    setActions(aRes.data ?? [])
  }

  const columns: Column<Hand>[] = [
    { header: 'Hand #', accessor: 'hand_number' },
    { header: 'Game Type', accessor: (r) => GameType[r.game_type] ?? `#${r.game_type}` },
    { header: 'Pot Total', accessor: (r) => `$${r.pot_total.toLocaleString()}` },
    { header: 'Street', accessor: (r) => r.current_street ?? '—' },
    { header: 'Duration', accessor: (r) => `${r.duration_sec}s` },
    { header: 'Started At', accessor: (r) => r.started_at?.slice(0, 19).replace('T', ' ') ?? '—' },
  ]

  // Group actions by street
  const groupedActions = actions.reduce<Record<string, HandAction[]>>((acc, a) => {
    const street = a.street || 'unknown'
    if (!acc[street]) acc[street] = []
    acc[street].push(a)
    return acc
  }, {})

  return (
    <div className="page-container">
      <div className="page-header">
        <h1 className="page-title">Hand History</h1>
      </div>

      {error && <div className="page-error">{error}</div>}

      <div className="filter-bar">
        <input
          placeholder="Filter by Table ID..."
          value={tableFilter}
          onChange={(e) => setTableFilter(e.target.value)}
          style={{ width: 200 }}
        />
      </div>

      <DataTable<Hand>
        columns={columns}
        data={hands}
        loading={loading}
        emptyMessage="No hands recorded"
        onRowClick={toggleExpand}
      />

      {expandedId && (
        <div className="hand-expand">
          <h4>Players</h4>
          <table className="data-table" style={{ marginBottom: 16 }}>
            <thead>
              <tr>
                <th>Seat</th><th>Name</th><th>Cards</th><th>P&amp;L</th><th>Winner</th>
              </tr>
            </thead>
            <tbody>
              {players.map((p) => (
                <tr key={p.id}>
                  <td>{p.seat_no}</td>
                  <td>{p.player_name}</td>
                  <td style={{ fontFamily: 'monospace' }}>{p.hole_cards || '—'}</td>
                  <td style={{ color: p.pnl >= 0 ? 'var(--success)' : 'var(--danger)' }}>
                    {p.pnl >= 0 ? '+' : ''}{p.pnl.toLocaleString()}
                  </td>
                  <td>{p.is_winner && <span className="winner-badge">Winner</span>}</td>
                </tr>
              ))}
            </tbody>
          </table>

          <h4>Actions</h4>
          {Object.entries(groupedActions).map(([street, acts]) => (
            <div key={street}>
              <div className="street-header">{street}</div>
              {acts.map((a) => (
                <div key={a.id} className="action-line">
                  Seat {a.seat_no}: {a.action_type} {a.action_amount > 0 ? `$${a.action_amount.toLocaleString()}` : ''}
                </div>
              ))}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
