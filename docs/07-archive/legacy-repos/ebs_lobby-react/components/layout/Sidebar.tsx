import { NavLink } from 'react-router-dom'
import { useAuthStore } from '../../store/auth-store'

export default function Sidebar() {
  const user = useAuthStore((s) => s.user)
  const isAdmin = user?.role === 'admin'

  return (
    <aside className="sidebar">
      <div className="sidebar-header">
        <h2>EBS Lobby</h2>
      </div>
      <nav className="sidebar-nav">
        <div className="nav-section">
          <span className="nav-section-title">Tournament</span>
          <NavLink to="/series" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
            Series
          </NavLink>
          <NavLink to="/hands" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
            Hand History
          </NavLink>
          <NavLink to="/players" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
            Players
          </NavLink>
        </div>
        {isAdmin && (
          <div className="nav-section">
            <span className="nav-section-title">Admin</span>
            <NavLink to="/admin/users" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
              Users
            </NavLink>
            <NavLink to="/admin/settings" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
              Settings
            </NavLink>
            <NavLink to="/admin/skins" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
              Skins
            </NavLink>
            <NavLink to="/admin/blind-structures" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
              Blind Structures
            </NavLink>
            <NavLink to="/admin/audit-log" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
              Audit Log
            </NavLink>
            <NavLink to="/admin/reports" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
              Reports
            </NavLink>
            <NavLink to="/admin/sync" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
              WSOP Sync
            </NavLink>
          </div>
        )}
      </nav>
    </aside>
  )
}
