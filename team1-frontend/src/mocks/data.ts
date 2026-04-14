// src/mocks/data.ts — In-memory mock fixtures ported from
// ebs_lobby-react/api/mock-data.ts. Extended to 2 Series / 5 Events / 10
// Flights / 20 Tables / 100 Players / 3 Skins.

import type {
  Competition,
  Series,
  EbsEvent,
  EventFlight,
  Table,
  TableSeat,
  Player,
  BlindStructure,
  User,
  Hand,
  HandPlayer,
  HandAction,
  AuditLog,
} from 'src/types/models';
import type { Skin } from 'src/types/entities';

const NOW = '2026-04-09T12:00:00';

export const mockCompetitions: Competition[] = [
  {
    competition_id: 1,
    name: 'WSOP',
    competition_type: 1,
    competition_tag: 1,
    created_at: NOW,
    updated_at: NOW,
  },
];

export const mockSeries: Series[] = [
  {
    series_id: 1,
    competition_id: 1,
    series_name: 'WSOP Europe 2026',
    year: 2026,
    begin_at: '2026-04-01T12:00:00',
    end_at: '2026-04-20T12:00:00',
    image_url: null,
    time_zone: 'Europe/Paris',
    currency: 'EUR',
    country_code: 'FR',
    is_completed: false,
    is_displayed: true,
    is_demo: false,
    source: 'manual',
    synced_at: null,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    series_id: 2,
    competition_id: 1,
    series_name: '58th Annual WSOP',
    year: 2026,
    begin_at: '2026-05-28T12:00:00',
    end_at: '2026-07-17T12:00:00',
    image_url: null,
    time_zone: 'America/Los_Angeles',
    currency: 'USD',
    country_code: 'US',
    is_completed: false,
    is_displayed: true,
    is_demo: false,
    source: 'manual',
    synced_at: null,
    created_at: NOW,
    updated_at: NOW,
  },
];

export const mockEvents: EbsEvent[] = [
  {
    event_id: 1,
    series_id: 1,
    event_no: 1,
    event_name: '#1 €1,100 Mystery Bounty NLH',
    buy_in: 1100,
    display_buy_in: '€1,100',
    game_type: 0,
    bet_structure: 0,
    event_game_type: 0,
    game_mode: 'tournament',
    allowed_games: null,
    rotation_order: null,
    rotation_trigger: null,
    blind_structure_id: null,
    starting_chip: 30000,
    table_size: 9,
    total_entries: 542,
    players_left: 87,
    start_time: '2026-04-05T14:00:00',
    status: 'running',
    source: 'manual',
    synced_at: null,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    event_id: 2,
    series_id: 1,
    event_no: 2,
    event_name: '#2 €600 PLO/PLO8/Big O',
    buy_in: 600,
    display_buy_in: '€600',
    game_type: 21,
    bet_structure: 1,
    event_game_type: 21,
    game_mode: 'mix',
    allowed_games: '2,3,11',
    rotation_order: '2,3,11',
    rotation_trigger: 'level',
    blind_structure_id: null,
    starting_chip: 20000,
    table_size: 9,
    total_entries: 0,
    players_left: 0,
    start_time: '2026-04-10T14:00:00',
    status: 'registering',
    source: 'manual',
    synced_at: null,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    event_id: 3,
    series_id: 1,
    event_no: 3,
    event_name: '#3 €550 Deepstack NLH',
    buy_in: 550,
    display_buy_in: '€550',
    game_type: 0,
    bet_structure: 0,
    event_game_type: 0,
    game_mode: 'tournament',
    allowed_games: null,
    rotation_order: null,
    rotation_trigger: null,
    blind_structure_id: null,
    starting_chip: 40000,
    table_size: 9,
    total_entries: 388,
    players_left: 0,
    start_time: '2026-04-03T14:00:00',
    status: 'completed',
    source: 'manual',
    synced_at: null,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    event_id: 5,
    series_id: 1,
    event_no: 5,
    event_name: '#5 €5,300 Main Event NLH',
    buy_in: 5300,
    display_buy_in: '€5,300',
    game_type: 0,
    bet_structure: 0,
    event_game_type: 0,
    game_mode: 'tournament',
    allowed_games: null,
    rotation_order: null,
    rotation_trigger: null,
    blind_structure_id: null,
    starting_chip: 50000,
    table_size: 9,
    total_entries: 1486,
    players_left: 918,
    start_time: '2026-04-07T12:00:00',
    status: 'running',
    source: 'manual',
    synced_at: null,
    created_at: NOW,
    updated_at: NOW,
  },
  {
    event_id: 6,
    series_id: 1,
    event_no: 6,
    event_name: '#6 €600 Turbo NLH',
    buy_in: 600,
    display_buy_in: '€600',
    game_type: 0,
    bet_structure: 0,
    event_game_type: 0,
    game_mode: 'tournament',
    allowed_games: null,
    rotation_order: null,
    rotation_trigger: null,
    blind_structure_id: null,
    starting_chip: 15000,
    table_size: 9,
    total_entries: 0,
    players_left: 0,
    start_time: '2026-04-12T18:00:00',
    status: 'announced',
    source: 'manual',
    synced_at: null,
    created_at: NOW,
    updated_at: NOW,
  },
];

/** Raw flight rows — legacy API shape (event_flight_id / display_name).
 *  The `mockFlights` export below augments each with Team-1 Lobby
 *  aliases (flight_id / flight_name / day_index) so TableListPage +
 *  DayTabs can consume EventFlight directly. */
const rawFlights = [
  { event_flight_id: 1, event_id: 5, display_name: 'Day 1A', start_time: '2026-04-07T12:00:00', is_tbd: false, entries: 336, players_left: 0, table_count: 136, status: 'completed', play_level: 12, remain_time: null, source: 'manual', synced_at: null, created_at: NOW, updated_at: NOW },
  { event_flight_id: 2, event_id: 5, display_name: 'Day 1B', start_time: '2026-04-07T17:00:00', is_tbd: false, entries: 269, players_left: 0, table_count: 140, status: 'completed', play_level: 12, remain_time: null, source: 'manual', synced_at: null, created_at: NOW, updated_at: NOW },
  { event_flight_id: 3, event_id: 5, display_name: 'Day 1C', start_time: '2026-04-08T12:00:00', is_tbd: false, entries: 299, players_left: 0, table_count: 154, status: 'completed', play_level: 12, remain_time: null, source: 'manual', synced_at: null, created_at: NOW, updated_at: NOW },
  { event_flight_id: 4, event_id: 5, display_name: 'Day 2',  start_time: '2026-04-09T12:00:00', is_tbd: false, entries: 918, players_left: 918, table_count: 124, status: 'running',   play_level: 3,  remain_time: 3240, source: 'manual', synced_at: null, created_at: NOW, updated_at: NOW },
  { event_flight_id: 5, event_id: 5, display_name: 'Day 3',  start_time: '2026-04-10T12:00:00', is_tbd: false, entries: 0,   players_left: 0,   table_count: 0,   status: 'announced', play_level: 0,  remain_time: null, source: 'manual', synced_at: null, created_at: NOW, updated_at: NOW },
  { event_flight_id: 6, event_id: 5, display_name: 'Day 4',  start_time: '2026-04-11T12:00:00', is_tbd: false, entries: 0,   players_left: 0,   table_count: 0,   status: 'announced', play_level: 0,  remain_time: null, source: 'manual', synced_at: null, created_at: NOW, updated_at: NOW },
  { event_flight_id: 7, event_id: 1, display_name: 'Day 1',  start_time: '2026-04-05T14:00:00', is_tbd: false, entries: 542, players_left: 87,  table_count: 60,  status: 'running',   play_level: 8,  remain_time: 900,  source: 'manual', synced_at: null, created_at: NOW, updated_at: NOW },
  { event_flight_id: 8, event_id: 3, display_name: 'Day 1',  start_time: '2026-04-03T14:00:00', is_tbd: false, entries: 388, players_left: 0,   table_count: 0,   status: 'completed', play_level: 20, remain_time: null, source: 'manual', synced_at: null, created_at: NOW, updated_at: NOW },
  { event_flight_id: 9, event_id: 2, display_name: 'Day 1',  start_time: '2026-04-10T14:00:00', is_tbd: false, entries: 0,   players_left: 0,   table_count: 0,   status: 'announced', play_level: 0,  remain_time: null, source: 'manual', synced_at: null, created_at: NOW, updated_at: NOW },
  { event_flight_id: 10, event_id: 6, display_name: 'Day 1', start_time: '2026-04-12T18:00:00', is_tbd: false, entries: 0,   players_left: 0,   table_count: 0,   status: 'announced', play_level: 0,  remain_time: null, source: 'manual', synced_at: null, created_at: NOW, updated_at: NOW },
];

/** Per-event running counter yields day_index (1..N within one event). */
const _dayCounters: Record<number, number> = {};
export const mockFlights: EventFlight[] = rawFlights.map(f => {
  _dayCounters[f.event_id] = (_dayCounters[f.event_id] ?? 0) + 1;
  return {
    ...f,
    flight_id: f.event_flight_id,
    flight_name: f.display_name,
    day_index: _dayCounters[f.event_id]!,
  };
});

function makeTable(id: number, flightId: number, tableNo: number, status: Table['status'] = 'live'): Table {
  return {
    table_id: id,
    event_flight_id: flightId,
    table_no: tableNo,
    name: `Table-${String(tableNo).padStart(3, '0')}`,
    type: tableNo <= 2 ? 'feature' : 'general',
    status,
    max_players: 9,
    game_type: 0,
    small_blind: status === 'empty' ? null : 1200,
    big_blind: status === 'empty' ? null : 2400,
    ante_type: 1,
    ante_amount: 2400,
    rfid_reader_id: tableNo <= 2 ? tableNo : null,
    deck_registered: tableNo === 1,
    output_type: tableNo <= 2 ? 'NDI' : null,
    current_game: status === 'live' ? 47 : null,
    delay_seconds: tableNo <= 2 ? 30 : 0,
    ring: null,
    is_breaking_table: false,
    source: 'manual',
    created_at: NOW,
    updated_at: NOW,
  };
}

export const mockTables: Table[] = Array.from({ length: 20 }, (_, i) => {
  const tableNo = i + 1;
  const status: Table['status'] = i < 15 ? 'live' : i < 18 ? 'setup' : 'empty';
  return makeTable(i + 1, 4, tableNo, status);
});

const FAMOUS = [
  ['Phil', 'Hellmuth', 'US', 'American'],
  ['Daniel', 'Negreanu', 'CA', 'Canadian'],
  ['Doyle', 'Brunson', 'US', 'American'],
  ['Johnny', 'Chan', 'US', 'American'],
  ['Stu', 'Ungar', 'US', 'American'],
  ['Erik', 'Seidel', 'US', 'American'],
  ['Chris', 'Moneymaker', 'US', 'American'],
  ['Vanessa', 'Selbst', 'US', 'American'],
  ['Fedor', 'Holz', 'DE', 'German'],
  ['Justin', 'Bonomo', 'US', 'American'],
] as const;

export const mockPlayers: Player[] = Array.from({ length: 100 }, (_, i) => {
  const template = FAMOUS[i % FAMOUS.length]!;
  return {
    player_id: i + 1,
    wsop_id: `P-${String(i + 1).padStart(5, '0')}`,
    first_name: template[0],
    last_name: i < 10 ? template[1] : `${template[1]}-${i + 1}`,
    nationality: template[3],
    country_code: template[2],
    profile_image: null,
    player_status: 'active',
    is_demo: false,
    source: 'manual',
    synced_at: null,
    created_at: NOW,
    updated_at: NOW,
  };
});

export const mockSeats: TableSeat[] = Array.from({ length: 9 }, (_, i) => ({
  seat_id: i + 1,
  table_id: 1,
  seat_no: i + 1,
  player_id: i + 1,
  wsop_id: `P-${String(i + 1).padStart(5, '0')}`,
  player_name: `${FAMOUS[i]![0]} ${FAMOUS[i]![1]}`,
  nationality: FAMOUS[i]![3],
  country_code: FAMOUS[i]![2],
  chip_count: (i + 1) * 25000,
  profile_image: null,
  status: 'occupied',
  player_move_status: null,
  created_at: NOW,
  updated_at: NOW,
}));

export const mockUser = {
  user: {
    user_id: 1,
    email: 'admin@ebs.local',
    display_name: 'Admin',
    role: 'admin' as const,
    permissions: {
      Lobby: 7,
      Settings: 7,
      GraphicEditor: 7,
    },
    table_ids: [] as number[],
  },
  session: {
    last_series_id: 1,
    last_event_id: 5,
    last_flight_id: 4,
    last_table_id: 1,
  },
};

export const mockBlindStructures: BlindStructure[] = [
  { blind_structure_id: 1, name: 'Standard 20min', created_at: NOW, updated_at: NOW },
  { blind_structure_id: 2, name: 'Turbo 12min', created_at: NOW, updated_at: NOW },
  { blind_structure_id: 3, name: 'Deep Stack 30min', created_at: NOW, updated_at: NOW },
];

export const mockSkins: Skin[] = [
  {
    skin_id: 1,
    name: 'Default WSOP',
    version: '1.0.0',
    status: 'active',
    metadata: {
      title: 'Default WSOP',
      description: 'Standard WSOP broadcast overlay',
      author: 'EBS Team',
      tags: ['wsop', 'default'],
    },
    file_size: 2_457_600,
    uploaded_at: NOW,
    activated_at: NOW,
    preview_url: null,
  },
  {
    skin_id: 2,
    name: 'Neon Nights',
    version: '0.9.1',
    status: 'validated',
    metadata: {
      title: 'Neon Nights',
      description: 'Vibrant neon theme for late-night broadcasts',
      author: 'Design Team',
      tags: ['neon', 'dark'],
    },
    file_size: 3_145_728,
    uploaded_at: NOW,
    activated_at: null,
    preview_url: null,
  },
  {
    skin_id: 3,
    name: 'Classic Green',
    version: '1.2.0',
    status: 'draft',
    metadata: {
      title: 'Classic Green',
      description: 'Traditional felt green theme',
      author: null,
      tags: ['classic'],
    },
    file_size: 1_843_200,
    uploaded_at: NOW,
    activated_at: null,
    preview_url: null,
  },
];

export const mockUsers: User[] = [
  { user_id: 1, email: 'admin@ebs.local', display_name: 'Admin', role: 'admin', is_active: true, totp_enabled: false, last_login_at: NOW, created_at: NOW, updated_at: NOW },
  { user_id: 2, email: 'operator1@ebs.local', display_name: 'Operator 1', role: 'operator', is_active: true, totp_enabled: false, last_login_at: '2026-04-09T10:00:00', created_at: NOW, updated_at: NOW },
  { user_id: 3, email: 'operator2@ebs.local', display_name: 'Operator 2', role: 'operator', is_active: true, totp_enabled: false, last_login_at: '2026-04-08T18:00:00', created_at: NOW, updated_at: NOW },
  { user_id: 4, email: 'viewer@ebs.local', display_name: 'Viewer', role: 'viewer', is_active: false, totp_enabled: false, last_login_at: null, created_at: NOW, updated_at: NOW },
];

export const mockHands: Hand[] = Array.from({ length: 10 }, (_, i) => ({
  hand_id: i + 1,
  table_id: 1,
  hand_number: 1001 + i,
  game_type: 0,
  bet_structure: 0,
  dealer_seat: (i % 9) + 1,
  board_cards: i < 8 ? 'Ah Kd 7c 2s 9h' : 'Jc Td 5s',
  pot_total: (i + 1) * 12000,
  side_pots: '',
  current_street: null,
  started_at: new Date(Date.now() - (10 - i) * 600_000).toISOString(),
  ended_at: new Date(Date.now() - (10 - i) * 600_000 + 120_000).toISOString(),
  duration_sec: 120,
  created_at: NOW,
}));

export const mockHandPlayers: HandPlayer[] = Array.from({ length: 9 }, (_, i) => ({
  id: i + 1,
  hand_id: 1,
  seat_no: i + 1,
  player_id: i + 1,
  player_name: `${FAMOUS[i]![0]} ${FAMOUS[i]![1]}`,
  hole_cards: i === 0 ? 'As Ks' : i === 1 ? 'Qh Jh' : '',
  start_stack: 50000 + i * 5000,
  end_stack: i === 0 ? 74000 : 50000 + i * 5000 - (i < 3 ? 8000 : 0),
  final_action: i === 0 ? 'win' : i < 3 ? 'fold' : null,
  is_winner: i === 0,
  pnl: i === 0 ? 24000 : i < 3 ? -8000 : 0,
  hand_rank: i === 0 ? 'Flush' : null,
  win_probability: null,
  vpip: i < 4,
  pfr: i < 2,
}));

export const mockHandActions: HandAction[] = [
  { id: 1, hand_id: 1, seat_no: 3, action_type: 'post_sb', action_amount: 1200, pot_after: 1200, street: 'Preflop', action_order: 1, board_cards: null, action_time: null },
  { id: 2, hand_id: 1, seat_no: 4, action_type: 'post_bb', action_amount: 2400, pot_after: 3600, street: 'Preflop', action_order: 2, board_cards: null, action_time: null },
  { id: 3, hand_id: 1, seat_no: 1, action_type: 'raise', action_amount: 6000, pot_after: 9600, street: 'Preflop', action_order: 3, board_cards: null, action_time: null },
  { id: 4, hand_id: 1, seat_no: 2, action_type: 'call', action_amount: 6000, pot_after: 15600, street: 'Preflop', action_order: 4, board_cards: null, action_time: null },
  { id: 5, hand_id: 1, seat_no: 3, action_type: 'fold', action_amount: 0, pot_after: 15600, street: 'Preflop', action_order: 5, board_cards: null, action_time: null },
  { id: 6, hand_id: 1, seat_no: 1, action_type: 'bet', action_amount: 8000, pot_after: 23600, street: 'Flop', action_order: 6, board_cards: 'Ah Kd 7c', action_time: null },
  { id: 7, hand_id: 1, seat_no: 2, action_type: 'call', action_amount: 8000, pot_after: 31600, street: 'Flop', action_order: 7, board_cards: null, action_time: null },
  { id: 8, hand_id: 1, seat_no: 1, action_type: 'check', action_amount: 0, pot_after: 31600, street: 'Turn', action_order: 8, board_cards: '2s', action_time: null },
  { id: 9, hand_id: 1, seat_no: 2, action_type: 'check', action_amount: 0, pot_after: 31600, street: 'Turn', action_order: 9, board_cards: null, action_time: null },
  { id: 10, hand_id: 1, seat_no: 1, action_type: 'bet', action_amount: 16000, pot_after: 47600, street: 'River', action_order: 10, board_cards: '9h', action_time: null },
  { id: 11, hand_id: 1, seat_no: 2, action_type: 'fold', action_amount: 0, pot_after: 47600, street: 'River', action_order: 11, board_cards: null, action_time: null },
];

export const mockAuditLogs: AuditLog[] = Array.from({ length: 15 }, (_, i) => ({
  id: i + 1,
  user_id: (i % 3) + 1,
  entity_type: ['table', 'event', 'user', 'skin', 'config'][i % 5]!,
  entity_id: i + 1,
  action: ['create', 'update', 'delete', 'activate', 'login'][i % 5]!,
  detail: `Mock audit action ${i + 1}`,
  ip_address: '192.168.1.' + (10 + i),
  created_at: new Date(Date.now() - i * 3_600_000).toISOString(),
}));

export const mockConfigs: Record<string, Record<string, unknown>> = {
  outputs: {
    primary_output: 'NDI',
    ndi_port: 5960,
    hdmi_enabled: false,
    delay_seconds: 30,
  },
  gfx: {
    theme: 'default',
    overlay_position: 'bottom',
    font_size: 'medium',
  },
  display: {
    language: 'en',
    timezone: 'Europe/Paris',
    date_format: 'YYYY-MM-DD',
  },
  rules: {
    late_registration_minutes: 180,
    break_interval_hours: 2,
    break_duration_minutes: 15,
  },
  stats: {
    show_vpip: true,
    show_pfr: true,
    show_chip_count: true,
  },
  preferences: {
    auto_refresh: true,
    refresh_interval_seconds: 5,
    confirm_destructive: true,
  },
};
