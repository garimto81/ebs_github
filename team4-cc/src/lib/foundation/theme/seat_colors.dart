// SSOT for CC and Overlay seat/position colors.
//
// Defined in BS-05-03 §시각 규격 and BS-07-01 §시각 규격 (CCR-032, CCR-034).
// Both CC (`features/command_center/widgets/seat_cell.dart`) and
// Overlay (`features/overlay/layer1/player_info.dart`) must import from here.
//
// Rationale: CC (operator) and Overlay (viewer) must share the same visual
// language. Hardcoding colors in either location violates the SSOT principle.

import 'package:flutter/material.dart';

class SeatColors {
  SeatColors._();

  // ── Position markers (BS-05-03 §시각 규격) ───────────────────
  static const dealer = Color(0xFFE53935); // Material Red 600
  static const sb = Color(0xFFFDD835); // Material Yellow 600
  static const bb = Color(0xFF1E88E5); // Material Blue 600
  static const utg = Color(0xFF43A047); // Material Green 600
  static const positionDefault = Color(0xFFFFFFFF);

  // ── Seat state backgrounds (BS-05-03 §시각 규격) ─────────────
  static const vacant = Color(0xFF616161); // Gray 700
  static const active = Color(0xFF2E7D32); // Green 800
  static const allIn = Color(0xFF000000);

  // Folded uses `vacant` base with opacity 0.4
  static const foldedOpacity = 0.4;

  // Sitting out uses `vacant` base with opacity 0.6
  static const sittingOutOpacity = 0.6;

  // ── action-glow pulse animation (BS-05-03 §시각 규격) ────────
  static const actionGlowDuration = Duration(milliseconds: 800);
  static const actionGlowFrom = Color(0x66FDD835); // alpha 0.4
  static const actionGlowTo = Color(0xFFFDD835); // alpha 1.0
}
