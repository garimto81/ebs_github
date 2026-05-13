// Card suit and state colors for CC card display (OKLCH-sourced).
//
// Cycle 19 Wave 2 — re-sourced from `EbsOklch` Broadcast Dark Amber palette.
// Previous Material palette (Red 600 / Blue 600 / Green 600 / Blue 800)
// replaced.
//
// Note: the HTML SSOT `tokens.css` defines `--card-red` and `--card-black`
// only — a 2-color deck convention. The 4-color broadcast convention
// (Heart=red, Diamond=blue, Spade=black, Club=green) is *not* yet
// represented in the SSOT. We keep the 4-color mapping by deriving blue
// (Diamond) and green (Club) from semantic OKLCH tokens (`info` and `ok`).
// TODO(cycle-19+): if PRD adopts 2-color broadcast, collapse Diamond→cardRed
// and Club→cardBlack to match HTML SSOT verbatim.

import 'ebs_oklch.dart';

class CardColors {
  CardColors._();

  // ── Suit colors (4-color broadcast standard) ───────────────────
  /// Spade — black suit (`--card-black`).
  static const spade = EbsOklch.cardBlack;

  /// Heart — red suit (`--card-red`).
  static const heart = EbsOklch.cardRed;

  /// Diamond — blue (broadcast 4-color convention).
  /// Source: `--info` (semantic blue). See file header for caveat.
  static const diamond = EbsOklch.info;

  /// Club — green (broadcast 4-color convention).
  /// Source: `--ok` (semantic green). See file header for caveat.
  static const club = EbsOklch.ok;

  // ── Card backgrounds ──────────────────────────────────────────
  /// Face-up — warm off-white (`--card-bg`).
  static const cardFaceUp = EbsOklch.cardBg;

  /// Face-down — accent-strong amber back (replaces Blue 800).
  /// Broadcast amber theme — see `Command_Center.md` §16 (deck back skin).
  static const cardFaceDown = EbsOklch.accentStrong;

  /// Used / out — bg-3 raised surface (duplicate-prevention picker).
  static const cardUsed = EbsOklch.bg3;
}
