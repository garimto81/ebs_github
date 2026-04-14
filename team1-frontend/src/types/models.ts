// src/types/models.ts — Compatibility layer.
//
// The primary domain types live in `entities.ts` (aligned with DATA-02 +
// CCR-017 Bit Flag permissions). This file re-exports them under the
// names used by the React-era ported API modules in `src/api/*.ts`, plus
// defines the few shapes that only exist in the legacy code path
// (User admin row, Hand history detail, Config row, OutputPreset, etc.).
//
// When adding new API modules prefer importing from `src/types/entities`
// directly. This shim exists to keep the ported api/*.ts surface stable.

export type {
  Competition,
  Series,
  EventFlight,
  Table,
  TableSeat,
  Player,
  BlindStructure,
  Skin,
} from './entities';

// Legacy `Event` name was renamed to `EbsEvent` inside api/events.ts to
// avoid clashing with the DOM `Event` global. Re-export the canonical
// entity under both names.
export type { Event as EbsEvent } from './entities';

// ---- Types NOT present in entities.ts (admin / history / config) -----

export interface User {
  user_id: number;
  email: string;
  display_name: string;
  role: string;
  is_active: boolean;
  totp_enabled: boolean;
  last_login_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface Hand {
  hand_id: number;
  table_id: number;
  hand_number: number;
  game_type: number;
  bet_structure: number;
  dealer_seat: number;
  board_cards: string;
  pot_total: number;
  side_pots: string;
  current_street: string | null;
  started_at: string;
  ended_at: string | null;
  duration_sec: number;
  created_at: string;
}

export interface HandPlayer {
  id: number;
  hand_id: number;
  seat_no: number;
  player_id: number | null;
  player_name: string;
  hole_cards: string;
  start_stack: number;
  end_stack: number;
  final_action: string | null;
  is_winner: boolean;
  pnl: number;
  hand_rank: string | null;
  win_probability: number | null;
  vpip: boolean;
  pfr: boolean;
}

export interface HandAction {
  id: number;
  hand_id: number;
  seat_no: number;
  action_type: string;
  action_amount: number;
  pot_after: number | null;
  street: string;
  action_order: number;
  board_cards: string | null;
  action_time: string | null;
}

export interface Config {
  id: number;
  key: string;
  value: string;
  category: string;
  description: string | null;
}

export interface OutputPreset {
  preset_id: number;
  name: string;
  output_type: string;
  width: number;
  height: number;
  framerate: number;
  security_delay_sec: number;
  chroma_key: boolean;
  is_default: boolean;
}

export interface BlindStructureLevel {
  id: number;
  blind_structure_id: number;
  level_no: number;
  small_blind: number;
  big_blind: number;
  ante: number;
  duration_minutes: number;
}

export interface AuditLog {
  id: number;
  user_id: number;
  entity_type: string;
  entity_id: number | null;
  action: string;
  detail: string | null;
  ip_address: string | null;
  created_at: string;
}
