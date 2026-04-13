// src/types/entities.ts — New domain types added for the React→Quasar port
// that are NOT in the legacy `src/types/models.ts`. Re-exports the legacy
// types as well so new code can do `import { Series, Permission, ... } from
// 'src/types/entities'` without having to remember which file hosts which.
//
// Legacy types (Series, EbsEvent, EventFlight, Table, TableSeat, Player,
// Hand, Skin, Config, BlindStructure, etc.) live in `models.ts` and were
// ported directly from ebs_lobby-react/types/models.ts.
//
// New additions (this file):
//   - Permission enum + helpers (CCR-017 Bit Flag RBAC)
//   - SettingsSection string-literal union
//   - SessionUser / SessionNavigation (permissions map included)
//   - SkinMetadata (structured metadata separate from Skin envelope)

export type {
  Competition,
  Series,
  EbsEvent,
  EventFlight,
  Table,
  TableSeat,
  Player,
  User,
  Hand,
  HandPlayer,
  HandAction,
  Config,
  OutputPreset,
  BlindStructure,
  BlindStructureLevel,
  AuditLog,
} from 'src/types/models';

// NOTE: the legacy `Skin` in models.ts is pre-CCR-011 (just theme_data blob).
// Graphic Editor code uses the richer shape defined below.

// Alias so new code can say `Event` without colliding with DOM Event inside
// this module (it re-exports as a type only, never as a value).
export type { EbsEvent as Event } from 'src/types/models';

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
