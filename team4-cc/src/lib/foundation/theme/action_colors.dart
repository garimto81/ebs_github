// Action button colors for CC hand lifecycle controls (OKLCH-sourced).
//
// Follows BS-05-02 action button spec. Each game action has a distinct
// color for instant visual recognition during live broadcast.
//
// Cycle 19 Wave 2 — re-sourced from `EbsOklch` Broadcast Dark Amber palette.
// Previous Material palette (Gray / Green / Orange / Red / Black-Gold)
// replaced.
//
// Action color mapping derives from the §13 Action Indicator spec
// (CHECK / BET / RAISE / FOLD) — combined with semantic OKLCH tokens.

import 'ebs_oklch.dart';

class ActionColors {
  ActionColors._();

  // ── Game actions ───────────────────────────────────────────────
  /// FOLD — gray/neutral (no token; reuse fg-3 muted text token).
  static const fold = EbsOklch.fg3;

  /// CHECK — semantic OK (success green). Visual indicator: blue chip
  /// per §13 (`#1976d2`), but for the button we keep semantic green for
  /// "safe / no commitment".
  static const check = EbsOklch.ok;

  /// CALL — same as CHECK (matches behavior pairing in §13.3).
  static const call = EbsOklch.ok;

  /// BET — accent (broadcast amber). Visual indicator §13: yellow.
  static const bet = EbsOklch.accent;

  /// RAISE — accentStrong (emphasis amber). Visual indicator §13: red.
  /// TODO(cycle-19+): if PRD wants RAISE=err (red), swap to `EbsOklch.err`.
  static const raise_ = EbsOklch.accentStrong;

  /// ALL-IN — deepest frame bg-0 with accent border (replaces black+gold).
  static const allIn = EbsOklch.bg0;

  /// ALL-IN border — accent (broadcast amber).
  static const allInBorder = EbsOklch.accent;

  // ── Hand lifecycle ─────────────────────────────────────────────
  /// New Hand — semantic info (blue).
  static const newHand = EbsOklch.info;

  /// Deal — semantic info (matches New Hand pairing).
  static const deal = EbsOklch.info;

  /// Undo — fg-2 muted text token (low emphasis).
  static const undo = EbsOklch.fg2;

  /// Miss-Deal — semantic err (red, destructive recovery).
  static const missDeal = EbsOklch.err;

  // ── Disabled state ─────────────────────────────────────────────
  /// Disabled background — bg-3 raised surface.
  static const disabled = EbsOklch.bg3;

  /// Disabled text — fg-3 muted text.
  static const disabledText = EbsOklch.fg3;
}
