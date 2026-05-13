// EBS OKLCH Design Tokens — Broadcast Dark Amber palette.
//
// SSOT: `docs/mockups/EBS Command Center/tokens.css`
// Spec: `docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md` §13
//
// OKLCH → sRGB conversion is static (compile-time). The 25 sRGB values below
// match the Overview.md §13.1 conversion table verbatim (HTML mockup SSOT
// → Flutter target).
//
// Dynamic tweaks (accentHue slider, table-felt picker) can be added later
// via a separate runtime lookup. This file is the compile-time fixture.

import 'package:flutter/material.dart';

class EbsOklch {
  EbsOklch._();

  // ─── Surfaces — broadcast-ops dark ────────────────────────────────
  /// `oklch(0.16 0.012 240)` — deepest, frame
  static const Color bg0 = Color(0xFF1F2326);

  /// `oklch(0.20 0.014 240)` — status/action panels
  static const Color bg1 = Color(0xFF272C30);

  /// `oklch(0.24 0.014 240)` — cards, seats, controls
  static const Color bg2 = Color(0xFF2F343A);

  /// `oklch(0.29 0.014 240)` — raised/hover
  static const Color bg3 = Color(0xFF393F46);

  /// `oklch(0.27 0.045 165)` — table felt (default, runtime-tweakable)
  static const Color bgFelt = Color(0xFF2E4038);

  /// `oklch(0.20 0.035 165)` — felt rim
  static const Color bgFeltRim = Color(0xFF223027);

  // ─── Borders / dividers ───────────────────────────────────────────
  /// `oklch(0.34 0.014 240)`
  static const Color line = Color(0xFF42484F);

  /// `oklch(0.28 0.014 240 / 0.7)` — soft divider (alpha 0xB3 ≈ 0.7)
  static const Color lineSoft = Color(0xB33A3F45);

  // ─── Text ─────────────────────────────────────────────────────────
  /// `oklch(0.98 0.005 240)`
  static const Color fg0 = Color(0xFFF5F6F7);

  /// `oklch(0.84 0.010 240)`
  static const Color fg1 = Color(0xFFCDD1D6);

  /// `oklch(0.62 0.010 240)`
  static const Color fg2 = Color(0xFF909599);

  /// `oklch(0.45 0.010 240)`
  static const Color fg3 = Color(0xFF636770);

  // ─── Accent — broadcast amber (tweakable) ─────────────────────────
  /// `oklch(0.78 0.16 65)` — primary accent
  static const Color accent = Color(0xFFF4A028);

  /// `oklch(0.72 0.18 60)` — emphasis (hover, pressed)
  static const Color accentStrong = Color(0xFFE08A1A);

  /// `oklch(0.78 0.16 65 / 0.18)` — soft tint overlay (alpha 0x2E ≈ 0.18)
  static const Color accentSoft = Color(0x2EF4A028);

  // ─── Semantic ─────────────────────────────────────────────────────
  /// `oklch(0.74 0.14 150)` — success / OK
  static const Color ok = Color(0xFF53B981);

  /// `oklch(0.80 0.16 80)` — warning
  static const Color warn = Color(0xFFE0B23F);

  /// `oklch(0.66 0.20 25)` — error
  static const Color err = Color(0xFFD8593A);

  /// `oklch(0.72 0.13 230)` — info
  static const Color info = Color(0xFF5A98D8);

  // ─── Position roles ───────────────────────────────────────────────
  /// `oklch(0.92 0.04 90)` — dealer puck (bone white)
  static const Color posD = Color(0xFFE8E0CC);

  /// `oklch(0.74 0.14 230)` — small blind
  static const Color posSb = Color(0xFF5B98D6);

  /// `oklch(0.72 0.16 320)` — big blind
  static const Color posBb = Color(0xFFCB7AB8);

  // ─── Card colors ──────────────────────────────────────────────────
  /// `oklch(0.96 0.005 90)` — card background (off-white, warm)
  static const Color cardBg = Color(0xFFF5F2EC);

  /// `oklch(0.55 0.21 25)` — red suits (H, D)
  static const Color cardRed = Color(0xFFCC3B20);

  /// `oklch(0.18 0.02 240)` — black suits (S, C)
  static const Color cardBlack = Color(0xFF242830);
}
