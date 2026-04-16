// EBS Lobby typography scale.
//
// Adapted from team4 EbsTypography for desktop web (larger screens).
// Sizes are slightly bumped vs CC mobile for comfortable desktop reading.
// Monospace for numeric values (stacks, pots, stats) for alignment.

import 'package:flutter/material.dart';

class EbsTypography {
  EbsTypography._();

  // ── Page titles (Lobby sections) ───────────────────────────────
  static const pageTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  // ── Section headers (Settings tab titles, card headers) ────────
  static const sectionHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  // ── Toolbar / AppBar title ─────────────────────────────────────
  static const toolbarTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  // ── Data table header ──────────────────────────────────────────
  static const tableHeader = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Color(0xFFB0B0B0),
  );

  // ── Data table cell ────────────────────────────────────────────
  static const tableCell = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  // ── Numeric values in tables (monospace for digit alignment) ───
  static const tableNumeric = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: 'monospace',
  );

  // ── Body text ──────────────────────────────────────────────────
  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ── Form label ─────────────────────────────────────────────────
  static const formLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  // ── Form input ─────────────────────────────────────────────────
  static const formInput = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  // ── Navigation item ────────────────────────────────────────────
  static const navItem = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  // ── Status badge ───────────────────────────────────────────────
  static const statusBadge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // ── Caption / hint text ────────────────────────────────────────
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Color(0xFF9E9E9E),
  );

  // ── Modal title ────────────────────────────────────────────────
  static const modalTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  // ── Pot / stack amount (monospace, large) ──────────────────────
  static const amountLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    fontFamily: 'monospace',
  );

  // ── Small monospace (hand #, seat #) ───────────────────────────
  static const monoSmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    fontFamily: 'monospace',
  );

  // ── Tab label ──────────────────────────────────────────────────
  static const tabLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
}
