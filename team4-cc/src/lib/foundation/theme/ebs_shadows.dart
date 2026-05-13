// EBS OKLCH Shadow tokens — Broadcast Dark Amber depth system.
//
// SSOT: `docs/mockups/EBS Command Center/tokens.css` (`--shadow-card`,
// `--shadow-pop`, `--glow-action`).
//
// Note: Flutter does NOT support inset BoxShadow. Outer-shadow components
// from the HTML SSOT are reproduced; inset highlights are dropped (would
// require custom painters to render — outside the token-layer scope).

import 'package:flutter/material.dart';

import 'ebs_oklch.dart';

class EbsShadows {
  EbsShadows._();

  /// `--shadow-card`: outer drop for cards, seats, panels.
  ///
  /// HTML: `0 1px 0 rgba(255,255,255,0.04) inset, 0 4px 16px rgba(0,0,0,0.35)`
  /// Flutter: outer only (inset highlight dropped, see file header).
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x59000000), // rgba(0,0,0,0.35) — 0x59 ≈ 0.35 × 255
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// `--shadow-pop`: elevated drop for dialogs, popovers, dropdowns.
  ///
  /// HTML: `0 12px 36px rgba(0,0,0,0.55), 0 2px 0 rgba(255,255,255,0.04) inset`
  /// Flutter: outer only.
  static const List<BoxShadow> pop = [
    BoxShadow(
      color: Color(0x8C000000), // rgba(0,0,0,0.55) — 0x8C ≈ 0.55 × 255
      blurRadius: 36,
      offset: Offset(0, 12),
    ),
  ];

  /// `--glow-action`: acting-seat emphasis — accent ring + soft outer glow.
  ///
  /// HTML: `0 0 0 2px var(--accent), 0 0 28px var(--accent-soft)`
  /// Flutter: 2px solid spread (ring) + 28px blur (soft glow).
  static const List<BoxShadow> glowAction = [
    // 2px solid ring (spreadRadius emulates `0 0 0 2px <color>`)
    BoxShadow(
      color: EbsOklch.accent,
      spreadRadius: 2,
      blurRadius: 0,
    ),
    // 28px soft outer glow
    BoxShadow(
      color: EbsOklch.accentSoft,
      blurRadius: 28,
      spreadRadius: 0,
    ),
  ];
}
