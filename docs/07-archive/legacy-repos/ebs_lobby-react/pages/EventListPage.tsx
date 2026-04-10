import { useState, useEffect, Fragment } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useApiList } from '../hooks/use-api'
import { useAuthStore } from '../store/auth-store'
import { useNavStore } from '../store/nav-store'
import * as eventsApi from '../api/events'
import * as blindStructuresApi from '../api/blind-structures'
import type { Event, EventFlight, BlindStructure } from '../types/models'
import { GameType } from '../types/enums'
import LoadingSpinner from '../components/common/LoadingSpinner'
import StatusBadge from '../components/common/StatusBadge'
import FormDialog from '../components/common/FormDialog'
import './pages.css'

const MIX_PRESETS: Record<string, { name: string; games: number[] }> = {
  HORSE: { name: 'HORSE', games: [1, 4, 5, 6, 2] },
  '8-Game': { name: '8-Game', games: [0, 1, 3, 2, 4, 5, 6, 7] },
  PPC: { name: 'PPC', games: [0, 3, 2, 9, 16] },
}

const STATUS_TABS = ['all', 'created', 'announced', 'registering', 'running', 'completed'] as const

const CLICKABLE_FLIGHT_STATUSES = new Set(['running', 'registering'])

function formatTime(t: string | null): string {
  return t?.slice(0, 16).replace('T', ' ') ?? '—'
}

export default function EventListPage() {
  const { seriesId } = useParams<{ seriesId: string }>()
  const navigate = useNavigate()
  const role = useAuthStore((s) => s.user?.role)
  const { setSeriesId, setEventId, setFlightId } = useNavStore()
  const sid = Number(seriesId)

  const [activeTab, setActiveTab] = useState<string>('all')

  const { data: events, loading, error, reload } = useApiList<Event>(
    eventsApi.list,
    { series_id: sid, ...(activeTab !== 'all' ? { status: activeTab } : {}) },
    [sid, activeTab],
  )

  const { data: blindStructures } = useApiList<BlindStructure>(blindStructuresApi.list, {}, [])

  const [expandedEventId, setExpandedEventId] = useState<number | null>(null)
  const [flights, setFlights] = useState<EventFlight[]>([])
  const [flightsLoading, setFlightsLoading] = useState(false)

  const [showFlightForm, setShowFlightForm] = useState(false)
  const [flightForm, setFlightForm] = useState({ display_name: '', start_time: '', starting_stack: 60000, starting_blind_level: 1, is_tbd: false })

  const handleFlightSave = async () => {
    if (expandedEventId === null) return
    await eventsApi.createFlight(expandedEventId, {
      ...flightForm,
      start_time: flightForm.start_time ? new Date(flightForm.start_time).toISOString() : null,
    })
    setShowFlightForm(false)
    setFlightForm({ display_name: '', start_time: '', starting_stack: 60000, starting_blind_level: 1, is_tbd: false })
    const res = await eventsApi.getFlights(expandedEventId)
    setFlights(res.data ?? [])
  }

  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({
    event_name: '',
    event_no: 1,
    game_type: 0,
    buy_in: 0,
    table_size: 9,
    start_time: '',
    starting_chip: 60000,
    game_mode: 'single' as 'single' | 'fixed_rotation' | 'dealers_choice',
    allowed_games: [] as number[],
    rotation_order: [] as number[],
    rotation_trigger: 'hands' as 'hands' | 'time' | 'orbit',
    hands_per_rotation: 8,
    mix_preset: '',
    blind_structure_id: null as number | null,
    blind_mode: 'existing' as 'existing' | 'new',
    blind_levels: [{ level_no: 1, small_blind: 100, big_blind: 200, ante: 0, duration_minutes: 20 }],
  })

  // Set series context on mount
  useEffect(() => {
    setSeriesId(sid)
  }, [sid, setSeriesId])

  // Fetch flights when expandedEventId changes
  useEffect(() => {
    if (expandedEventId === null) {
      setFlights([])
      return
    }
    let cancelled = false
    setFlightsLoading(true)
    eventsApi.getFlights(expandedEventId).then((res) => {
      if (!cancelled) {
        setFlights(res.data ?? [])
        setFlightsLoading(false)
      }
    }).catch(() => {
      if (!cancelled) setFlightsLoading(false)
    })
    return () => { cancelled = true }
  }, [expandedEventId])

  const handleEventClick = (event: Event) => {
    const nextId = expandedEventId === event.event_id ? null : event.event_id
    setExpandedEventId(nextId)
    if (nextId !== null) {
      setEventId(event.event_id, event.event_name)
    } else {
      setEventId(null)
    }
  }

  const handleFlightClick = (flight: EventFlight) => {
    if (!CLICKABLE_FLIGHT_STATUSES.has(flight.status.toLowerCase())) return
    setFlightId(flight.event_flight_id, flight.display_name)
    navigate(`/flights/${flight.event_flight_id}/tables`)
  }

  const handleSave = async () => {
    const payload: Record<string, unknown> = {
      ...form,
      series_id: sid,
      start_time: form.start_time ? new Date(form.start_time).toISOString() : null,
      allowed_games: form.allowed_games.length > 0 ? JSON.stringify(form.allowed_games) : null,
      rotation_order: form.rotation_order.length > 0 ? JSON.stringify(form.rotation_order) : null,
      rotation_trigger: form.game_mode !== 'single' ? form.rotation_trigger : null,
    }
    delete payload.blind_mode
    delete payload.blind_levels
    delete payload.mix_preset
    delete payload.hands_per_rotation
    await eventsApi.create(payload as Partial<Event>)
    setShowForm(false)
    setForm({
      event_name: '', event_no: 1, game_type: 0, buy_in: 0, table_size: 9,
      start_time: '', starting_chip: 60000,
      game_mode: 'single', allowed_games: [], rotation_order: [],
      rotation_trigger: 'hands', hands_per_rotation: 8, mix_preset: '',
      blind_structure_id: null, blind_mode: 'existing',
      blind_levels: [{ level_no: 1, small_blind: 100, big_blind: 200, ante: 0, duration_minutes: 20 }],
    })
    reload()
  }

  const EVENT_HEADERS = ['Event #', 'Name', 'Game Type', 'Buy-In', 'Table Size', 'Status', 'Start Time']
  const FLIGHT_HEADERS = ['Flight', 'Start Time', 'Entries', 'Players Left', 'Tables', 'Level', 'Status']

  return (
    <div className="page-container">
      <div className="page-header">
        <div>
          <h1 className="page-title">Events</h1>
          <p className="page-subtitle">Series #{seriesId}</p>
        </div>
        {role === 'admin' && (
          <button className="btn btn-primary" onClick={() => setShowForm(true)}>New Event</button>
        )}
      </div>

      {error && <div className="page-error">{error}</div>}

      <div className="tab-bar" style={{ display: 'flex', gap: 4, marginBottom: 16 }}>
        {STATUS_TABS.map(tab => (
          <button
            key={tab}
            className={`btn btn-sm ${activeTab === tab ? 'btn-primary' : 'btn-secondary'}`}
            onClick={() => setActiveTab(tab)}
            style={{ textTransform: 'capitalize' }}
          >
            {tab}
          </button>
        ))}
      </div>

      {loading ? (
        <LoadingSpinner />
      ) : (
        <div className="data-table-wrapper">
          <table className="data-table">
            <thead>
              <tr>
                {EVENT_HEADERS.map((h) => <th key={h}>{h}</th>)}
              </tr>
            </thead>
            <tbody>
              {events.length === 0 ? (
                <tr>
                  <td colSpan={EVENT_HEADERS.length} className="empty-row">No events in this series</td>
                </tr>
              ) : (
                events.map((event) => {
                  const isExpanded = expandedEventId === event.event_id
                  return (
                    <Fragment key={event.event_id}>
                      <tr
                        className={`clickable${isExpanded ? ' event-row-expanded' : ''}`}
                        onClick={() => handleEventClick(event)}
                      >
                        <td>{event.event_no}</td>
                        <td>
                          <span className="event-expand-indicator">{isExpanded ? '▼' : '▶'}</span>
                          {event.event_name}
                        </td>
                        <td>{GameType[event.game_type] ?? `#${event.game_type}`}</td>
                        <td>{event.display_buy_in ?? (event.buy_in != null ? `$${event.buy_in.toLocaleString()}` : '—')}</td>
                        <td>{event.table_size}</td>
                        <td><StatusBadge status={event.status} /></td>
                        <td>{formatTime(event.start_time)}</td>
                      </tr>

                      {isExpanded && (
                        <tr key={`${event.event_id}-accordion`} className="accordion-row">
                          <td colSpan={EVENT_HEADERS.length} className="accordion-cell">
                            <div className="flight-accordion">
                              <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 8 }}>
                                {role === 'admin' && (
                                  <button className="btn btn-secondary btn-sm" onClick={(e) => { e.stopPropagation(); setShowFlightForm(true) }}>
                                    + New Flight
                                  </button>
                                )}
                              </div>
                              {flightsLoading ? (
                                <div className="flight-loading">Loading flights...</div>
                              ) : flights.length === 0 ? (
                                <div className="flight-empty">No flights for this event</div>
                              ) : (
                                <table className="data-table flight-table">
                                  <thead>
                                    <tr>
                                      {FLIGHT_HEADERS.map((h) => <th key={h}>{h}</th>)}
                                    </tr>
                                  </thead>
                                  <tbody>
                                    {flights.map((flight) => {
                                      const clickable = CLICKABLE_FLIGHT_STATUSES.has(flight.status.toLowerCase())
                                      return (
                                        <tr
                                          key={flight.event_flight_id}
                                          className={`flight-row ${clickable ? 'flight-row-clickable' : 'flight-row-disabled'}`}
                                          onClick={() => handleFlightClick(flight)}
                                        >
                                          <td>{flight.display_name}</td>
                                          <td>{formatTime(flight.start_time)}</td>
                                          <td>{flight.entries}</td>
                                          <td>{flight.players_left}</td>
                                          <td>{flight.table_count}</td>
                                          <td>{flight.play_level}</td>
                                          <td><StatusBadge status={flight.status} /></td>
                                        </tr>
                                      )
                                    })}
                                  </tbody>
                                </table>
                              )}
                            </div>
                          </td>
                        </tr>
                      )}
                    </Fragment>
                  )
                })
              )}
            </tbody>
          </table>
        </div>
      )}

      <FormDialog open={showForm} title="New Event" onSave={handleSave} onCancel={() => setShowForm(false)}>
        <div className="form-group">
          <label>Event #</label>
          <input type="number" value={form.event_no} onChange={(e) => setForm({ ...form, event_no: Number(e.target.value) })} />
        </div>
        <div className="form-group">
          <label>Event Name</label>
          <input value={form.event_name} onChange={(e) => setForm({ ...form, event_name: e.target.value })} />
        </div>
        <div className="form-group">
          <label>Game Type</label>
          <select value={form.game_type} onChange={(e) => setForm({ ...form, game_type: Number(e.target.value) })}>
            {Object.entries(GameType).map(([k, v]) => (
              <option key={k} value={k}>{v}</option>
            ))}
          </select>
        </div>

        {/* Game Mode */}
        <div className="form-group">
          <label>Game Mode *</label>
          <select value={form.game_mode} onChange={(e) => {
            const mode = e.target.value as typeof form.game_mode
            setForm({ ...form, game_mode: mode, mix_preset: '', allowed_games: [], rotation_order: [] })
          }}>
            <option value="single">Single</option>
            <option value="fixed_rotation">Fixed Rotation</option>
            <option value="dealers_choice">Dealer's Choice</option>
          </select>
        </div>

        {/* Mix Preset - only for fixed_rotation */}
        {form.game_mode === 'fixed_rotation' && (
          <>
            <div className="form-group">
              <label>Mix Preset</label>
              <select value={form.mix_preset} onChange={(e) => {
                const preset = MIX_PRESETS[e.target.value]
                if (preset) {
                  setForm({ ...form, mix_preset: e.target.value, allowed_games: preset.games, rotation_order: preset.games })
                } else {
                  setForm({ ...form, mix_preset: '', allowed_games: [], rotation_order: [] })
                }
              }}>
                <option value="">Custom</option>
                {Object.entries(MIX_PRESETS).map(([k, v]) => (
                  <option key={k} value={k}>{v.name}</option>
                ))}
              </select>
            </div>
            <div className="form-group">
              <label>Allowed Games</label>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                {Object.entries(GameType).map(([id, name]) => {
                  const numId = Number(id)
                  const checked = form.allowed_games.includes(numId)
                  return (
                    <label key={id} style={{ fontSize: 12, display: 'flex', alignItems: 'center', gap: 4, width: '48%' }}>
                      <input type="checkbox" checked={checked} onChange={() => {
                        const next = checked
                          ? form.allowed_games.filter(g => g !== numId)
                          : [...form.allowed_games, numId]
                        setForm({ ...form, allowed_games: next, rotation_order: next, mix_preset: '' })
                      }} />
                      {name}
                    </label>
                  )
                })}
              </div>
            </div>
            <div className="form-group">
              <label>Hands per Rotation</label>
              <input type="number" min={1} max={20} value={form.hands_per_rotation}
                onChange={(e) => setForm({ ...form, hands_per_rotation: Number(e.target.value) })} />
            </div>
          </>
        )}

        {/* Dealer's Choice: just show allowed games */}
        {form.game_mode === 'dealers_choice' && (
          <div className="form-group">
            <label>Allowed Games</label>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
              {Object.entries(GameType).map(([id, name]) => {
                const numId = Number(id)
                const checked = form.allowed_games.includes(numId)
                return (
                  <label key={id} style={{ fontSize: 12, display: 'flex', alignItems: 'center', gap: 4, width: '48%' }}>
                    <input type="checkbox" checked={checked} onChange={() => {
                      const next = checked
                        ? form.allowed_games.filter(g => g !== numId)
                        : [...form.allowed_games, numId]
                      setForm({ ...form, allowed_games: next })
                    }} />
                    {name}
                  </label>
                )
              })}
            </div>
          </div>
        )}

        <div className="form-group">
          <label>Buy-In ($)</label>
          <input type="number" value={form.buy_in} onChange={(e) => setForm({ ...form, buy_in: Number(e.target.value) })} />
        </div>

        {/* Blind Structure */}
        <div className="form-group">
          <label>Blind Structure *</label>
          <div style={{ display: 'flex', gap: 12, marginBottom: 8 }}>
            <label style={{ fontSize: 13 }}>
              <input type="radio" value="existing" checked={form.blind_mode === 'existing'}
                onChange={() => setForm({ ...form, blind_mode: 'existing' })} />
              {' '}Use existing
            </label>
            <label style={{ fontSize: 13 }}>
              <input type="radio" value="new" checked={form.blind_mode === 'new'}
                onChange={() => setForm({ ...form, blind_mode: 'new' })} />
              {' '}Create inline
            </label>
          </div>

          {form.blind_mode === 'existing' ? (
            <select value={form.blind_structure_id ?? ''} onChange={(e) =>
              setForm({ ...form, blind_structure_id: e.target.value ? Number(e.target.value) : null })
            }>
              <option value="">Select...</option>
              {blindStructures.map(bs => (
                <option key={bs.blind_structure_id} value={bs.blind_structure_id}>{bs.name}</option>
              ))}
            </select>
          ) : (
            <div>
              <table className="data-table" style={{ fontSize: 12 }}>
                <thead>
                  <tr><th>Level</th><th>SB</th><th>BB</th><th>Ante</th><th>Min</th><th></th></tr>
                </thead>
                <tbody>
                  {form.blind_levels.map((lvl, i) => (
                    <tr key={i}>
                      <td>{lvl.level_no}</td>
                      <td><input type="number" value={lvl.small_blind} style={{ width: 60 }}
                        onChange={(e) => {
                          const next = [...form.blind_levels]
                          next[i] = { ...next[i], small_blind: Number(e.target.value) }
                          setForm({ ...form, blind_levels: next })
                        }} /></td>
                      <td><input type="number" value={lvl.big_blind} style={{ width: 60 }}
                        onChange={(e) => {
                          const next = [...form.blind_levels]
                          next[i] = { ...next[i], big_blind: Number(e.target.value) }
                          setForm({ ...form, blind_levels: next })
                        }} /></td>
                      <td><input type="number" value={lvl.ante} style={{ width: 60 }}
                        onChange={(e) => {
                          const next = [...form.blind_levels]
                          next[i] = { ...next[i], ante: Number(e.target.value) }
                          setForm({ ...form, blind_levels: next })
                        }} /></td>
                      <td><input type="number" value={lvl.duration_minutes} style={{ width: 50 }}
                        onChange={(e) => {
                          const next = [...form.blind_levels]
                          next[i] = { ...next[i], duration_minutes: Number(e.target.value) }
                          setForm({ ...form, blind_levels: next })
                        }} /></td>
                      <td>
                        {form.blind_levels.length > 1 && (
                          <button type="button" className="btn btn-danger btn-sm" onClick={() => {
                            const next = form.blind_levels.filter((_, j) => j !== i)
                              .map((l, j) => ({ ...l, level_no: j + 1 }))
                            setForm({ ...form, blind_levels: next })
                          }}>✕</button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              <button type="button" className="btn btn-secondary btn-sm" style={{ marginTop: 4 }} onClick={() => {
                const last = form.blind_levels[form.blind_levels.length - 1]
                setForm({ ...form, blind_levels: [...form.blind_levels, {
                  level_no: last.level_no + 1,
                  small_blind: last.small_blind * 2,
                  big_blind: last.big_blind * 2,
                  ante: last.ante,
                  duration_minutes: last.duration_minutes,
                }] })
              }}>+ Add Level</button>
            </div>
          )}
        </div>

        <div className="form-group">
          <label>Table Size</label>
          <input type="number" value={form.table_size} onChange={(e) => setForm({ ...form, table_size: Number(e.target.value) })} />
        </div>

        {/* Start Date */}
        <div className="form-group">
          <label>Start Date *</label>
          <input type="datetime-local" value={form.start_time}
            onChange={(e) => setForm({ ...form, start_time: e.target.value })} />
        </div>

        {/* Starting Chip */}
        <div className="form-group">
          <label>Starting Chip *</label>
          <input type="number" min={1} value={form.starting_chip}
            onChange={(e) => setForm({ ...form, starting_chip: Number(e.target.value) })} />
        </div>
      </FormDialog>

      <FormDialog open={showFlightForm} title="New Flight" onSave={handleFlightSave} onCancel={() => setShowFlightForm(false)}>
        <div className="form-group">
          <label>Flight Name *</label>
          <input value={flightForm.display_name} onChange={(e) => setFlightForm({ ...flightForm, display_name: e.target.value })} required />
        </div>
        <div className="form-group">
          <label>Start Time</label>
          <input type="datetime-local" value={flightForm.start_time} onChange={(e) => setFlightForm({ ...flightForm, start_time: e.target.value })} />
        </div>
        <div className="form-group">
          <label>Starting Stack</label>
          <input type="number" min={1} value={flightForm.starting_stack} onChange={(e) => setFlightForm({ ...flightForm, starting_stack: Number(e.target.value) })} />
        </div>
        <div className="form-group">
          <label>Starting Blind Level</label>
          <input type="number" min={1} value={flightForm.starting_blind_level} onChange={(e) => setFlightForm({ ...flightForm, starting_blind_level: Number(e.target.value) })} />
        </div>
        <div className="form-group">
          <label style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 13 }}>
            <input type="checkbox" checked={flightForm.is_tbd} onChange={(e) => setFlightForm({ ...flightForm, is_tbd: e.target.checked })} />
            TBD (Time to be determined)
          </label>
        </div>
      </FormDialog>
    </div>
  )
}
