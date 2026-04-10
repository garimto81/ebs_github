import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import AppLayout from './components/layout/AppLayout'
import ProtectedRoute from './components/auth/ProtectedRoute'
import LoginPage from './pages/LoginPage'
import SeriesListPage from './pages/SeriesListPage'
import EventListPage from './pages/EventListPage'
import TableListPage from './pages/TableListPage'
import HandHistoryPage from './pages/HandHistoryPage'
import PlayerListPage from './pages/PlayerListPage'
import UsersPage from './pages/admin/UsersPage'
import SettingsPage from './pages/admin/SettingsPage'
import SkinsPage from './pages/admin/SkinsPage'
import BlindStructuresPage from './pages/admin/BlindStructuresPage'
import AuditLogPage from './pages/admin/AuditLogPage'
import ReportsPage from './pages/admin/ReportsPage'
import WsopSyncPage from './pages/sync/WsopSyncPage'

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route element={<ProtectedRoute />}>
          <Route element={<AppLayout />}>
            <Route path="/" element={<Navigate to="/series" replace />} />
            <Route path="/series" element={<SeriesListPage />} />
            <Route path="/series/:seriesId/events" element={<EventListPage />} />
            <Route path="/flights/:flightId/tables" element={<TableListPage />} />
            <Route path="/players" element={<PlayerListPage />} />
            <Route path="/hands" element={<HandHistoryPage />} />
            <Route path="/admin/users" element={<UsersPage />} />
            <Route path="/admin/settings" element={<SettingsPage />} />
            <Route path="/admin/skins" element={<SkinsPage />} />
            <Route path="/admin/blind-structures" element={<BlindStructuresPage />} />
            <Route path="/admin/audit-log" element={<AuditLogPage />} />
            <Route path="/admin/reports" element={<ReportsPage />} />
            <Route path="/admin/sync" element={<WsopSyncPage />} />
          </Route>
        </Route>
      </Routes>
    </BrowserRouter>
  )
}
