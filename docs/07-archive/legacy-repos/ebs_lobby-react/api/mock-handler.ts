import type { ApiResponse } from '../types/api'
import {
  mockCompetitions,
  mockSeries,
  mockEvents,
  mockFlights,
  mockTables,
  mockSeats,
  mockPlayers,
  mockUser,
  mockBlindStructures,
} from './mock-data'

function ok<T>(data: T, meta?: ApiResponse<T>['meta']): ApiResponse<T> {
  return { data, error: null, meta }
}

function notFound(message = 'Not found'): ApiResponse<null> {
  return { data: null, error: { code: 'NOT_FOUND', message } }
}

const MOCK_TOKEN = {
  access_token: 'mock-access-token',
  token_type: 'bearer',
  requires_2fa: false,
  expires_in: 900,
  user: { user_id: 1, email: 'admin@ebs.local', role: 'admin', table_ids: [] },
}

export function mockHandle(
  method: string,
  pathname: string,
  search: string | undefined,
  body?: unknown,
): ApiResponse<unknown> {
  const params = new URLSearchParams(search ?? '')
  const m = method.toUpperCase()

  // --- Auth ---
  if (m === 'POST' && pathname === '/auth/login') {
    return ok(MOCK_TOKEN)
  }
  if (m === 'POST' && pathname === '/auth/refresh') {
    return ok(MOCK_TOKEN)
  }
  if (m === 'DELETE' && pathname === '/auth/session') {
    return ok({ message: 'Logged out successfully' })
  }
  if (m === 'POST' && pathname === '/auth/verify-2fa') {
    return ok(MOCK_TOKEN)
  }
  if (m === 'POST' && pathname === '/auth/forgot-password') {
    return ok({ message: 'Password reset email sent.' })
  }
  if (m === 'GET' && pathname === '/auth/session') {
    return ok(mockUser)
  }

  // --- Competitions ---
  if (m === 'GET' && pathname === '/competitions') {
    return ok(mockCompetitions)
  }

  // --- Series ---
  if (m === 'GET' && pathname === '/series') {
    return ok(mockSeries)
  }
  {
    const match = pathname.match(/^\/series\/(\d+)$/)
    if (match) {
      const id = Number(match[1])
      const item = mockSeries.find(s => s.series_id === id)
      return item ? ok(item) : notFound()
    }
  }

  // --- Blind Structures ---
  if (m === 'GET' && pathname === '/blind-structures') {
    return ok(mockBlindStructures)
  }

  // --- Events ---
  if (m === 'GET' && pathname === '/events') {
    const seriesId = params.get('series_id')
    const status = params.get('status')
    let filtered = seriesId
      ? mockEvents.filter(e => e.series_id === Number(seriesId))
      : mockEvents
    if (status) {
      filtered = filtered.filter(e => e.status === status)
    }
    return ok(filtered)
  }
  {
    const match = pathname.match(/^\/events\/(\d+)$/)
    if (match) {
      const id = Number(match[1])
      const item = mockEvents.find(e => e.event_id === id)
      return item ? ok(item) : notFound()
    }
  }
  {
    const match = pathname.match(/^\/events\/(\d+)\/flights$/)
    if (match) {
      if (m === 'POST') {
        return ok(null)
      }
      const eventId = Number(match[1])
      const filtered = mockFlights.filter(f => f.event_id === eventId)
      return ok(filtered)
    }
  }

  // --- Flights ---
  if (m === 'GET' && pathname === '/flights') {
    return ok(mockFlights)
  }
  {
    const match = pathname.match(/^\/flights\/(\d+)$/)
    if (match) {
      const id = Number(match[1])
      const item = mockFlights.find(f => f.event_flight_id === id)
      return item ? ok(item) : notFound()
    }
  }

  // --- Tables ---
  if (m === 'GET' && pathname === '/tables') {
    const flightId = params.get('event_flight_id')
    const filtered = flightId
      ? mockTables.filter(t => t.event_flight_id === Number(flightId))
      : mockTables
    return ok(filtered)
  }
  {
    const launchMatch = pathname.match(/^\/tables\/(\d+)\/launch-cc$/)
    if (launchMatch) {
      return ok({ url: 'about:blank' })
    }
  }
  {
    const seatsMatch = pathname.match(/^\/tables\/(\d+)\/seats$/)
    if (seatsMatch) {
      const tableId = Number(seatsMatch[1])
      const filtered = mockSeats.filter(s => s.table_id === tableId)
      return ok(filtered)
    }
  }
  {
    const match = pathname.match(/^\/tables\/(\d+)$/)
    if (match) {
      if (m === 'GET') {
        const id = Number(match[1])
        const item = mockTables.find(t => t.table_id === id)
        return item ? ok(item) : notFound()
      }
      // PUT / DELETE
      return ok(null)
    }
  }

  // --- Players ---
  if (m === 'GET' && pathname === '/players/search') {
    const q = (params.get('q') ?? '').toLowerCase()
    const filtered = q
      ? mockPlayers.filter(
          p =>
            p.first_name.toLowerCase().includes(q) ||
            p.last_name.toLowerCase().includes(q),
        )
      : mockPlayers
    return ok(filtered)
  }
  if (m === 'GET' && pathname === '/players') {
    return ok(mockPlayers)
  }
  {
    const match = pathname.match(/^\/players\/(\d+)$/)
    if (match) {
      const id = Number(match[1])
      const item = mockPlayers.find(p => p.player_id === id)
      return item ? ok(item) : notFound()
    }
  }

  // --- Fallback: POST / PUT / DELETE without specific handler ---
  if (m === 'POST' || m === 'PUT' || m === 'DELETE' || m === 'PATCH') {
    void body
    return ok(null)
  }

  return notFound(`No mock handler for ${m} ${pathname}`)
}
