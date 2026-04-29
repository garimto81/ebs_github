// Lobby-specific semantic colors.
//
// Adapter that maps EBS Lobby semantic roles (event status / table state /
// seat state / RBAC / WebSocket) onto the design system tokens.
//
// SSOT: `design_tokens.dart` (oklch→sRGB pinned values).

import 'design_tokens.dart';

class LobbyColors {
  LobbyColors._();

  // ── Event / Flight status ──────────────────────────────────────
  // Maps to the `.b-running` / `.b-registering` / `.b-announced` / `.b-completed`
  // / `.b-created` badges in styles.css.
  static const statusRunning = DesignTokens.liveBase;
  static const statusRunningBg = DesignTokens.liveBg;
  static const statusRunningInk = DesignTokens.liveInk;

  static const statusRegistering = DesignTokens.warnBase;
  static const statusRegisteringBg = DesignTokens.warnBg;
  static const statusRegisteringInk = DesignTokens.warnInk;

  static const statusAnnounced = DesignTokens.infoBase;
  static const statusAnnouncedBg = DesignTokens.infoBg;
  static const statusAnnouncedInk = DesignTokens.infoInk;

  static const statusCompleted = DesignTokens.lightInk5;
  static const statusCompletedBg = DesignTokens.lightBgSunken;
  static const statusCompletedInk = DesignTokens.lightInk3;

  static const statusCreated = DesignTokens.lightInk5;
  static const statusCreatedBg = DesignTokens.lightBgSunken;
  static const statusCreatedInk = DesignTokens.lightInk3;

  // Backwards-compatible aliases for prior consumers (Material-MD names →
  // semantic-token mapping). Same identifiers, retargeted to design tokens.
  static const statusActive = DesignTokens.liveBase; // was Green 600
  static const statusPaused = DesignTokens.warnBase; // was Orange 600
  static const statusCancelled = DesignTokens.lightInk4; // was Gray 600
  static const statusScheduled = DesignTokens.infoBase; // was Deep Purple 400

  // ── Table state ────────────────────────────────────────────────
  static const tableRunning = DesignTokens.liveInk;
  static const tableBreak = DesignTokens.warnBase;
  static const tableFinished = DesignTokens.lightInk4;
  static const tableFeature = DesignTokens.featInk; // gold star highlight

  // ── Seat state — mirrors `.seat.s-a/.s-e/.s-r/.s-w/.s-d` in styles.css ──
  // s-a (active)
  static const seatActive = DesignTokens.liveInk;
  static const seatActiveBg = DesignTokens.liveBg;
  // s-e (empty / dashed)
  static const seatEmpty = DesignTokens.lightInk5;
  static const seatEmptyBg = DesignTokens.lightBgSunken;
  // s-r (recently eliminated, strike-through)
  static const seatEliminated = DesignTokens.dangerInk;
  static const seatEliminatedBg = DesignTokens.dangerBg;
  // s-w (waiting)
  static const seatWaiting = DesignTokens.warnInk;
  static const seatWaitingBg = DesignTokens.warnBg;
  // s-d (dealer-only)
  static const seatDealer = DesignTokens.lightInk3;
  static const seatDealerBg = DesignTokens.lightBgSunken;

  // Backwards-compat aliases for prior `seatVacant / seatOccupied / seatReserved
  // / seatBlocked` consumers.
  static const seatVacant = DesignTokens.lightInk4;
  static const seatOccupied = DesignTokens.liveInk;
  static const seatReserved = DesignTokens.infoInk;
  static const seatBlocked = DesignTokens.lightInk2;

  // ── RBAC role badges ───────────────────────────────────────────
  static const roleAdmin = DesignTokens.dangerBase;
  static const roleOperator = DesignTokens.infoBase;
  static const roleViewer = DesignTokens.lightInk4;

  // ── Connection status (WebSocket) ──────────────────────────────
  static const wsConnected = DesignTokens.liveBase;
  static const wsReconnecting = DesignTokens.warnBase;
  static const wsDisconnected = DesignTokens.dangerBase;

  // ── Misc ───────────────────────────────────────────────────────
  static const bookmarkActive = DesignTokens.featInk;
  static const filterChipSelected = DesignTokens.infoBase;
  static const divider = DesignTokens.lightLine;

  // ── CC pill states (TopBar Active CC indicator) ────────────────
  static const ccPillLive = DesignTokens.liveBase;
  static const ccPillIdle = DesignTokens.lightInk5;
  static const ccPillError = DesignTokens.dangerBase;
}
