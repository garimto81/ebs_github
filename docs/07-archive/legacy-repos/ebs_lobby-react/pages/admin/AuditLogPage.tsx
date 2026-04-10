import { useState } from 'react'
import { useApiList } from '../../hooks/use-api'
import * as auditLogsApi from '../../api/audit-logs'
import type { AuditLog } from '../../types/models'
import DataTable from '../../components/common/DataTable'
import type { Column } from '../../components/common/DataTable'
import '../pages.css'

export default function AuditLogPage() {
  const [entityType, setEntityType] = useState('')
  const [action, setAction] = useState('')
  const [userId, setUserId] = useState('')
  const [dateFrom, setDateFrom] = useState('')
  const [dateTo, setDateTo] = useState('')

  const filters: Record<string, string | number> = {}
  if (entityType) filters.entity_type = entityType
  if (action) filters.action = action
  if (userId) filters.user_id = Number(userId)
  if (dateFrom) filters.date_from = dateFrom
  if (dateTo) filters.date_to = dateTo

  const { data: logs, loading, error } = useApiList<AuditLog>(
    auditLogsApi.list,
    filters,
    [entityType, action, userId, dateFrom, dateTo],
  )

  const columns: Column<AuditLog>[] = [
    { header: 'Timestamp', accessor: (r) => r.created_at?.slice(0, 19).replace('T', ' ') ?? '' },
    { header: 'User', accessor: (r) => `#${r.user_id}` },
    { header: 'Entity Type', accessor: 'entity_type' },
    { header: 'Entity ID', accessor: (r) => r.entity_id ?? '—' },
    { header: 'Action', accessor: 'action' },
    { header: 'Detail', accessor: (r) => r.detail ?? '—' },
  ]

  return (
    <div className="page-container">
      <div className="page-header">
        <h1 className="page-title">Audit Log</h1>
      </div>

      {error && <div className="page-error">{error}</div>}

      <div className="filter-bar">
        <select value={entityType} onChange={(e) => setEntityType(e.target.value)}>
          <option value="">All Entity Types</option>
          {['series', 'event', 'flight', 'table', 'seat', 'user', 'config', 'skin', 'blind_structure'].map((t) => (
            <option key={t} value={t}>{t}</option>
          ))}
        </select>
        <select value={action} onChange={(e) => setAction(e.target.value)}>
          <option value="">All Actions</option>
          {['create', 'update', 'delete', 'login', 'logout', 'status_change'].map((a) => (
            <option key={a} value={a}>{a}</option>
          ))}
        </select>
        <input placeholder="User ID" value={userId} onChange={(e) => setUserId(e.target.value)} style={{ width: 100 }} />
        <input type="date" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} />
        <input type="date" value={dateTo} onChange={(e) => setDateTo(e.target.value)} />
      </div>

      <DataTable<AuditLog>
        columns={columns}
        data={logs}
        loading={loading}
        emptyMessage="No audit log entries"
      />
    </div>
  )
}
