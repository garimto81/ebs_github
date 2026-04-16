// Lobby-specific semantic colors.
//
// Status, table state, seat state, and RBAC role badge colors
// for the EBS Lobby web application.

import 'package:flutter/material.dart';

class LobbyColors {
  LobbyColors._();

  // ── Event / Flight status ──────────────────────────────────────
  static const statusActive = Color(0xFF43A047); // Green 600
  static const statusPaused = Color(0xFFFB8C00); // Orange 600
  static const statusCompleted = Color(0xFF1E88E5); // Blue 600
  static const statusCancelled = Color(0xFF757575); // Gray 600
  static const statusScheduled = Color(0xFF7E57C2); // Deep Purple 400

  // ── Table status ───────────────────────────────────────────────
  static const tableRunning = Color(0xFF2E7D32); // Green 800
  static const tableBreak = Color(0xFFFDD835); // Yellow 600
  static const tableFinished = Color(0xFF616161); // Gray 700
  static const tableFeature = Color(0xFFE53935); // Red 600 — feature table highlight

  // ── Seat status ────────────────────────────────────────────────
  static const seatVacant = Color(0xFF616161); // Gray 700
  static const seatOccupied = Color(0xFF2E7D32); // Green 800
  static const seatReserved = Color(0xFF1565C0); // Blue 800
  static const seatBlocked = Color(0xFF424242); // Gray 800

  // ── RBAC role badges ───────────────────────────────────────────
  static const roleAdmin = Color(0xFFE53935); // Red 600
  static const roleOperator = Color(0xFF1E88E5); // Blue 600
  static const roleViewer = Color(0xFF757575); // Gray 600

  // ── Connection status (WebSocket) ──────────────────────────────
  static const wsConnected = Color(0xFF43A047); // Green
  static const wsReconnecting = Color(0xFFFB8C00); // Orange
  static const wsDisconnected = Color(0xFFE53935); // Red

  // ── Misc ───────────────────────────────────────────────────────
  static const bookmarkActive = Color(0xFFFDD835); // Yellow 600
  static const filterChipSelected = Color(0xFF1E88E5);
  static const divider = Color(0xFF2A2A40);
}
