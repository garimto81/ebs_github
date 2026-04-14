// Action button colors for CC hand lifecycle controls.
//
// Follows BS-05-02 action button spec. Each game action has a distinct
// color for instant visual recognition during live broadcast.

import 'package:flutter/material.dart';

class ActionColors {
  ActionColors._();

  // ── Game actions ───────────────────────────────────────────────
  static const fold = Color(0xFF616161); // Gray
  static const check = Color(0xFF43A047); // Green
  static const call = Color(0xFF43A047); // Green (same as check)
  static const bet = Color(0xFFFB8C00); // Orange
  static const raise_ = Color(0xFFE53935); // Red
  static const allIn = Color(0xFF000000); // Black with gold border
  static const allInBorder = Color(0xFFFDD835); // Gold

  // ── Hand lifecycle ─────────────────────────────────────────────
  static const newHand = Color(0xFF1E88E5); // Blue
  static const deal = Color(0xFF1E88E5); // Blue
  static const undo = Color(0xFF78909C); // BlueGray
  static const missDeal = Color(0xFFD32F2F); // Dark Red

  // ── Disabled state ─────────────────────────────────────────────
  static const disabled = Color(0xFF424242);
  static const disabledText = Color(0xFF757575);
}
