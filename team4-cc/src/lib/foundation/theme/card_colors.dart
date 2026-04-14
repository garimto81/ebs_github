// Card suit and state colors for CC card display.
//
// Diamond = blue follows broadcast standard (4-color deck).
// Used by seat_cell card indicators and deck management UI.

import 'package:flutter/material.dart';

class CardColors {
  CardColors._();

  // ── Suit colors (4-color broadcast standard) ───────────────────
  static const spade = Color(0xFF212121); // Black
  static const heart = Color(0xFFE53935); // Red
  static const diamond = Color(0xFF1E88E5); // Blue (broadcast standard)
  static const club = Color(0xFF2E7D32); // Green

  // ── Card backgrounds ──────────────────────────────────────────
  static const cardFaceUp = Color(0xFFFAFAFA);
  static const cardFaceDown = Color(0xFF1565C0); // Blue 800
  static const cardUsed = Color(0xFF424242); // Grayed out (duplicate prevention)
}
