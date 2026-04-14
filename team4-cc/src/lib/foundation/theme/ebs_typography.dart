// EBS Command Center typography scale.
//
// Optimized for broadcast environments — high contrast, clear hierarchy.
// Monospace for numeric values (stacks, pots, equity) for alignment.

import 'package:flutter/material.dart';

class EbsTypography {
  EbsTypography._();

  // Action buttons — large and unambiguous
  static const actionButton = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );

  // Seat player name
  static const playerName = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  // Stack amount (monospace for digit alignment)
  static const stackAmount = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    fontFamily: 'monospace',
  );

  // Pot display (largest numeric text)
  static const potAmount = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    fontFamily: 'monospace',
  );

  // Info bar (blind level, hand number)
  static const infoBar = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  // Toolbar title
  static const toolbarTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // Card rank/suit
  static const cardLabel = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w900,
  );

  // Modal title
  static const modalTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  // Equity percentage (monospace for alignment)
  static const equity = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    fontFamily: 'monospace',
  );

  // Keyboard shortcut hint
  static const shortcutHint = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: Color(0xFF9E9E9E),
  );
}
