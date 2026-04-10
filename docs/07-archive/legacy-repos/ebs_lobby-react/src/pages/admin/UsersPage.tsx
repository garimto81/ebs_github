import { useState } from 'react'
import { useApiList } from '../../hooks/use-api'
import * as usersApi from '../../api/users'
import type { User } from '../../types/models'
import { UserRole } from '../../types/enums'
import DataTable from '../../components/common/DataTable'
import type { Column } from '../../components/common/DataTable'
import StatusBadge from '../../components/common/StatusBadge'
import FormDialog from '../../components/common/FormDialog'
import ConfirmDialog from '../../components/common/ConfirmDialog'
import '../pages.css'

export default function UsersPage() {
  const { data: users, loading, error, reload } = useApiList<User>(usersApi.list)

  const [showForm, setShowForm] = useState(false)
  const [editUser, setEditUser] = useState<User | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<User | null>(null)
  const [form, setForm] = useState({ email: '', display_name: '', role: 'viewer', password: '' })

  const openCreate = () => {
    setEditUser(null)
    setForm({ email: '', display_name: '', role: 'viewer', password: '' })
    setShowForm(true)
  }

  const openEdit = (u: User) => {
    setEditUser(u)
    setForm({ email: u.email, display_name: u.display_name, role: u.role, password: '' })
    setShowForm(true)
  }

  const handleSave = async () => {
    if (editUser) {
      await usersApi.update(editUser.user_id, { email: form.email, display_name: form.display_name, role: form.role })
    } else {
      await usersApi.create({ email: form.email, display_name: form.display_name, role: form.role, password: form.password })
    }
    setShowForm(false)
    reload()
  }

  const handleDelete = async () => {
    if (!deleteTarget) return
    await usersApi.remove(deleteTarget.user_id)
    setDeleteTarget(null)
    reload()
  }

  const columns: Column<User>[] = [
    { header: 'Email', accessor: 'email' },
    { header: 'Display Name', accessor: 'display_name' },
    { header: 'Role', accessor: 'role', render: (_v, row) => <StatusBadge status={row.role} /> },
    { header: 'Active', accessor: (r) => r.is_active ? 'Yes' : 'No' },
    { header: 'Last Login', accessor: (r) => r.last_login_at?.slice(0, 19).replace('T', ' ') ?? 'Never' },
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

  return (
    <div className="page-container">
      <div className="page-header">
        <h1 className="page-title">Users</h1>
        <button className="btn btn-primary" onClick={openCreate}>Create User</button>
      </div>

      {error && <div className="page-error">{error}</div>}

      <DataTable<User> columns={columns} data={users} loading={loading} emptyMessage="No users" />

      <FormDialog
        open={showForm}
        title={editUser ? 'Edit User' : 'Create User'}
        onSave={handleSave}
        onCancel={() => setShowForm(false)}
      >
        <div className="form-group">
          <label>Email</label>
          <input value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} />
        </div>
        <div className="form-group">
          <label>Display Name</label>
          <input value={form.display_name} onChange={(e) => setForm({ ...form, display_name: e.target.value })} />
        </div>
        <div className="form-group">
          <label>Role</label>
          <select value={form.role} onChange={(e) => setForm({ ...form, role: e.target.value })}>
            <option value={UserRole.ADMIN}>Admin</option>
            <option value={UserRole.OPERATOR}>Operator</option>
            <option value={UserRole.VIEWER}>Viewer</option>
          </select>
        </div>
        {!editUser && (
          <div className="form-group">
            <label>Password</label>
            <input type="password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} />
          </div>
        )}
      </FormDialog>

      <ConfirmDialog
        open={!!deleteTarget}
        title="Delete User"
        message={`Are you sure you want to delete ${deleteTarget?.display_name}?`}
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
        confirmLabel="Delete"
      />
    </div>
  )
}
