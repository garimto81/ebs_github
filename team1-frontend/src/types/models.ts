export interface Competition {
  competition_id: number
  name: string
  competition_type: number
  competition_tag: number
  created_at: string
  updated_at: string
}

export interface Series {
  series_id: number
  competition_id: number
  series_name: string
  year: number
  begin_at: string
  end_at: string
  image_url: string | null
  time_zone: string
  currency: string
  country_code: string | null
  is_completed: boolean
  is_displayed: boolean
  is_demo: boolean
  source: string
  synced_at: string | null
  created_at: string
  updated_at: string
}

export interface Event {
  event_id: number
  series_id: number
  event_no: number
  event_name: string
  buy_in: number | null
  display_buy_in: string | null
  game_type: number
  bet_structure: number
  event_game_type: number
  game_mode: string
  allowed_games: string | null
  rotation_order: string | null
  rotation_trigger: string | null
  blind_structure_id: number | null
  starting_chip: number | null
  table_size: number
  total_entries: number
  players_left: number
  start_time: string | null
  status: string
  source: string
  synced_at: string | null
  created_at: string
  updated_at: string
}

export interface EventFlight {
  event_flight_id: number
  event_id: number
  display_name: string
  start_time: string | null
  is_tbd: boolean
  entries: number
  players_left: number
  table_count: number
  status: string
  play_level: number
  remain_time: number | null
  source: string
  synced_at: string | null
  created_at: string
  updated_at: string
}

export interface Table {
  table_id: number
  event_flight_id: number
  table_no: number
  name: string
  type: string
  status: string
  max_players: number
  game_type: number
  small_blind: number | null
  big_blind: number | null
  ante_type: number
  ante_amount: number
  rfid_reader_id: number | null
  deck_registered: boolean
  output_type: string | null
  current_game: number | null
  delay_seconds: number
  ring: number | null
  is_breaking_table: boolean
  source: string
  created_at: string
  updated_at: string
}

export interface TableSeat {
  seat_id: number
  table_id: number
  seat_no: number
  player_id: number | null
  wsop_id: string | null
  player_name: string | null
  nationality: string | null
  country_code: string | null
  chip_count: number
  profile_image: string | null
  status: string
  player_move_status: string | null
  created_at: string
  updated_at: string
}

export interface Player {
  player_id: number
  wsop_id: string | null
  first_name: string
  last_name: string
  nationality: string | null
  country_code: string | null
  profile_image: string | null
  player_status: string
  is_demo: boolean
  source: string
  synced_at: string | null
  created_at: string
  updated_at: string
}

export interface User {
  user_id: number
  email: string
  display_name: string
  role: string
  is_active: boolean
  totp_enabled: boolean
  last_login_at: string | null
  created_at: string
  updated_at: string
}

export interface Hand {
  hand_id: number
  table_id: number
  hand_number: number
  game_type: number
  bet_structure: number
  dealer_seat: number
  board_cards: string
  pot_total: number
  side_pots: string
  current_street: string | null
  started_at: string
  ended_at: string | null
  duration_sec: number
  created_at: string
}

export interface HandPlayer {
  id: number
  hand_id: number
  seat_no: number
  player_id: number | null
  player_name: string
  hole_cards: string
  start_stack: number
  end_stack: number
  final_action: string | null
  is_winner: boolean
  pnl: number
  hand_rank: string | null
  win_probability: number | null
  vpip: boolean
  pfr: boolean
}

export interface HandAction {
  id: number
  hand_id: number
  seat_no: number
  action_type: string
  action_amount: number
  pot_after: number | null
  street: string
  action_order: number
  board_cards: string | null
  action_time: string | null
}

export interface Config {
  id: number
  key: string
  value: string
  category: string
  description: string | null
}

export interface Skin {
  skin_id: number
  name: string
  description: string | null
  theme_data: string
  is_default: boolean
  created_at: string
  updated_at: string
}

export interface OutputPreset {
  preset_id: number
  name: string
  output_type: string
  width: number
  height: number
  framerate: number
  security_delay_sec: number
  chroma_key: boolean
  is_default: boolean
}

export interface BlindStructure {
  blind_structure_id: number
  name: string
  created_at: string
  updated_at: string
}

export interface BlindStructureLevel {
  id: number
  blind_structure_id: number
  level_no: number
  small_blind: number
  big_blind: number
  ante: number
  duration_minutes: number
}

export interface AuditLog {
  id: number
  user_id: number
  entity_type: string
  entity_id: number | null
  action: string
  detail: string | null
  ip_address: string | null
  created_at: string
}
