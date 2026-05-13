// SSOT for CC and Overlay seat / position colors (OKLCH-sourced).
//
// Defined in BS-05-03 §시각 규격 and BS-07-01 §시각 규격 (CCR-032, CCR-034).
// Both CC (`features/command_center/widgets/seat_cell.dart`) and
// Overlay (`features/overlay/layer1/player_info.dart`) must import from here.
//
// Cycle 19 Wave 2 — re-sourced from `EbsOklch` Broadcast Dark Amber palette.
// Previous Material palette (Red 600 / Yellow 600 / Blue 600) replaced.
//
// Rationale: CC (operator) and Overlay (viewer) must share the same visual
// language sourced from the HTML SSOT (`docs/mockups/EBS Command Center/
// tokens.css`).

import 'ebs_oklch.dart';

class SeatColors {
  SeatColors._();

  // ── Position markers (BS-05-03 §시각 규격) ───────────────────
  /// Dealer puck — bone white (`--pos-d`).
  static const dealer = EbsOklch.posD;

  /// Small blind — cool blue (`--pos-sb`).
  static const sb = EbsOklch.posSb;

  /// Big blind — magenta-pink (`--pos-bb`).
  static const bb = EbsOklch.posBb;

  /// UTG — no dedicated OKLCH token; reuse semantic OK (success/green)
  /// for first-to-act emphasis. TODO(cycle-19+): introduce `--pos-utg`
  /// if PRD differentiates.
  static const utg = EbsOklch.ok;

  /// Default position (neutral) — light text fg-0.
  static const positionDefault = EbsOklch.fg0;

  // ── Seat state backgrounds (BS-05-03 §시각 규격) ─────────────
  /// Vacant seat — bg-3 raised surface (no player).
  static const vacant = EbsOklch.bg3;

  /// Active hand — green success token, repurposed for "in hand".
  static const active = EbsOklch.ok;

  /// All-in — deepest frame surface bg-0 (matches HTML mockup).
  static const allIn = EbsOklch.bg0;

  // Folded uses `vacant` base with opacity 0.4
  static const foldedOpacity = 0.4;

  // Sitting out uses `vacant` base with opacity 0.6
  static const sittingOutOpacity = 0.6;

  // ── action-glow pulse animation (BS-05-03 §시각 규격) ────────
  // HTML SSOT: `--glow-action: 0 0 0 2px var(--accent), 0 0 28px var(--accent-soft)`
  // Pulse animates the seat from accent-soft (low alpha) → accent (full).
  static const actionGlowDuration = Duration(milliseconds: 800);

  /// Pulse start — accent-soft (alpha 0x2E ≈ 0.18).
  static const actionGlowFrom = EbsOklch.accentSoft;

  /// Pulse end — accent full opacity.
  static const actionGlowTo = EbsOklch.accent;
}
