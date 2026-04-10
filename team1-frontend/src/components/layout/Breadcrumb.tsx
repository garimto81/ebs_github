import { Link, useLocation } from 'react-router-dom'
import { useNavStore } from '../../store/nav-store'

export default function Breadcrumb() {
  const location = useLocation()
  const nav = useNavStore()

  const crumbs: { label: string; path: string }[] = []

  // Admin pages — fall back to path-based breadcrumbs
  if (location.pathname.startsWith('/admin')) {
    crumbs.push({ label: 'Admin', path: '/admin/settings' })
    const sub = location.pathname.split('/')[2]
    const labels: Record<string, string> = {
      settings: 'Settings', users: 'Users', skins: 'Skins',
      'blind-structures': 'Blind Structures', 'audit-log': 'Audit Log',
      reports: 'Reports', sync: 'WSOP Sync',
    }
    if (sub && labels[sub]) {
      crumbs.push({ label: labels[sub], path: location.pathname })
    }
  } else {
    // Lobby navigation — context-based breadcrumbs
    crumbs.push({ label: 'EBS', path: '/series' })

    if (nav.currentSeriesId != null) {
      crumbs.push({
        label: nav.currentSeriesName ?? `Series #${nav.currentSeriesId}`,
        path: `/series/${nav.currentSeriesId}/events`,
      })
    }
    if (nav.currentEventId != null) {
      crumbs.push({
        label: nav.currentEventName ?? `Event #${nav.currentEventId}`,
        path: `/series/${nav.currentSeriesId}/events`,
      })
    }
    if (nav.currentFlightId != null) {
      crumbs.push({
        label: nav.currentFlightName ?? `Flight #${nav.currentFlightId}`,
        path: `/flights/${nav.currentFlightId}/tables`,
      })
    }
    if (nav.currentTableId != null) {
      crumbs.push({
        label: nav.currentTableName ?? `Table #${nav.currentTableId}`,
        path: `/flights/${nav.currentFlightId}/tables`,
      })
    }
  }

  return (
    <nav className="breadcrumb">
      {crumbs.map((crumb, i) => (
        <span key={`${crumb.path}-${i}`}>
          {i > 0 && <span className="breadcrumb-sep">/</span>}
          {i < crumbs.length - 1 ? (
            <Link to={crumb.path} className="breadcrumb-link">{crumb.label}</Link>
          ) : (
            <span className="breadcrumb-current">{crumb.label}</span>
          )}
        </span>
      ))}
    </nav>
  )
}
