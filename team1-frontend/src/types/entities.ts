// src/types/entities.ts — Domain types owner for the Quasar port.
//
// This file is the SOLE definition site for core business entities
// (Competition, Series, EbsEvent, EventFlight, Table, TableSeat, Player,
// BlindStructure) plus Quasar-era additions (Permission, Skin, SessionUser,
// SessionNavigation, SkinMetadata).
//
// Admin / history / config shapes (User, Hand*, Config, OutputPreset,
// BlindStructureLevel, AuditLog) continue to live in `src/types/models.ts`
// and are re-exported here for convenience. The prior circular re-export
// between this file and models.ts is intentionally removed — types flow
// models.ts → entities.ts (one way), and all 8 core domain types are now
// owned here directly.

// ---- Re-exports from models.ts (admin / history / config shapes) ----

export type {
  User,
  Hand,
  HandPlayer,
  HandAction,
  Config,
  OutputPreset,
  BlindStructureLevel,
  AuditLog,
} from 'src/types/models';

// ---- Core domain entities (owned here; ported from ebs_lobby-react) --

/** Shared escape hatch: allows `payload as Series` casts from WS envelopes
 *  and ad-hoc writes like `(tbl as Record<string, unknown>).seated_count`.
 *  Typed fields still win over the index for strong-typed access. */
interface DomainEntity {
  [key: string]: unknown;
}

export interface Competition extends DomainEntity {
  competition_id: number;
  name: string;
  competition_type: number;
  competition_tag: number;
  created_at: string;
  updated_at: string;
}

export interface Series extends DomainEntity {
  series_id: number;
  competition_id: number;
  series_name: string;
  year: number;
  begin_at: string;
  end_at: string;
  image_url: string | null;
  time_zone: string;
  currency: string;
  country_code: string | null;
  is_completed: boolean;
  is_displayed: boolean;
  is_demo: boolean;
  source: string;
  synced_at: string | null;
  created_at: string;
  updated_at: string;
}

/** Domain `Event` aliased as `EbsEvent` to avoid collision with the DOM
 *  Event global. Consumers that want the short name can import it under
 *  `Event` via the alias at the bottom of this file. */
export interface EbsEvent extends DomainEntity {
  event_id: number;
  series_id: number;
  event_no: number;
  event_name: string;
  buy_in: number | null;
  display_buy_in: string | null;
  game_type: number;
  bet_structure: number;
  event_game_type: number;
  game_mode: string;
  allowed_games: string | null;
  rotation_order: string | null;
  rotation_trigger: string | null;
  blind_structure_id: number | null;
  starting_chip: number | null;
  table_size: number;
  total_entries: number;
  players_left: number;
  start_time: string | null;
  status: string;
  source: string;
  synced_at: string | null;
  created_at: string;
  updated_at: string;
}

export type { EbsEvent as Event };

export interface EventFlight extends DomainEntity {
  event_flight_id: number;
  event_id: number;
  display_name: string;
  start_time: string | null;
  is_tbd: boolean;
  entries: number;
  players_left: number;
  table_count: number;
  status: string;
  play_level: number;
  remain_time: number | null;
  source: string;
  synced_at: string | null;
  created_at: string;
  updated_at: string;
  /** Team-1 Lobby shorthand alias for `event_flight_id`. */
  flight_id: number;
  /** Flight's index within its parent Event (1=Day 1A, 2=Day 1B, …). */
  day_index: number;
  /** Team-1 Lobby shorthand alias for `display_name`. */
  flight_name: string;
  player_count?: number;
}

export interface Table extends DomainEntity {
  table_id: number;
  event_flight_id: number;
  table_no: number;
  name: string;
  type: string;
  status: string;
  max_players: number;
  game_type: number;
  small_blind: number | null;
  big_blind: number | null;
  ante_type: number;
  ante_amount: number;
  rfid_reader_id: number | null;
  deck_registered: boolean;
  output_type: string | null;
  current_game: number | null;
  delay_seconds: number;
  ring: number | null;
  is_breaking_table: boolean;
  source: string;
  created_at: string;
  updated_at: string;
  /** Seated player count. Populated by lobbyStore WS updates; absent on
   *  initial REST response. */
  seated_count?: number;
}

export interface TableSeat extends DomainEntity {
  seat_id: number;
  table_id: number;
  seat_no: number;
  player_id: number | null;
  wsop_id: string | null;
  player_name: string | null;
  nationality: string | null;
  country_code: string | null;
  chip_count: number;
  profile_image: string | null;
  status: string;
  player_move_status: string | null;
  created_at: string;
  updated_at: string;
}

export interface Player extends DomainEntity {
  player_id: number;
  wsop_id: string | null;
  first_name: string;
  last_name: string;
  nationality: string | null;
  country_code: string | null;
  profile_image: string | null;
  player_status: string;
  is_demo: boolean;
  source: string;
  synced_at: string | null;
  created_at: string;
  updated_at: string;
  /** Lobby/PlayerDetail derived fields — absent on raw REST response. */
  stack?: number;
  table_name?: string;
  seat_index?: number;
}

export interface BlindStructure extends DomainEntity {
  blind_structure_id: number;
  name: string;
  created_at: string;
  updated_at: string;
}

// ---- Permission (CCR-017 Bit Flag) ------------------------------

export enum Permission {
  None = 0,
  Read = 1,
  Write = 2,
  Delete = 4,
  All = 7,
}

export type PermissionAction = 'Read' | 'Write' | 'Delete';

// ---- Settings / Config sections (DATA-03) -----------------------

export type SettingsSection =
  | 'outputs'
  | 'gfx'
  | 'display'
  | 'rules'
  | 'stats'
  | 'preferences';

// ---- Graphic Editor / Skins (API-07, CCR-011) -------------------

export type SkinStatus = 'draft' | 'validated' | 'active' | 'archived';

export interface SkinMetadata {
  title: string;
  description: string;
  author: string | null;
  tags: string[];
}

/**
 * Rich Skin shape used by the Graphic Editor. Replaces the legacy
 * `Skin` in models.ts (which only carried a theme_data blob).
 */
export interface Skin {
  skin_id: number;
  name: string;
  version: string;
  status: SkinStatus;
  metadata: SkinMetadata;
  file_size: number;
  uploaded_at: string;
  activated_at: string | null;
  preview_url: string | null;
}

// ---- Auth session -----------------------------------------------

export type UserRole = 'admin' | 'operator' | 'viewer';

/**
 * Session payload delivered by GET /auth/session.
 * Extended with `permissions` (Bit Flag map) and `display_name` from CCR-017.
 */
export interface SessionUser {
  user_id: number;
  email: string;
  display_name: string;
  role: UserRole;
  /** Bit Flag permission map keyed by resource name (CCR-017). */
  permissions: Record<string, number>;
  /** Operator role only: tables this user is assigned to. */
  table_ids: number[];
}

export interface SessionNavigation {
  last_series_id: number | null;
  last_event_id: number | null;
  last_flight_id: number | null;
  last_table_id: number | null;
}
