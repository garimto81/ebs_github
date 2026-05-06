// EBS Lobby — Active CC session provider (Phase 3, 2026-05-06).
//
// Tracks the count of active Command Center sessions for display in the
// LobbyTopBar's `cc-pill`. Wire-up details:
//
// - Default value: 0 (no CC active).
// - Updated by `lobby_websocket_client.dart` when `/ws/lobby` emits
//   `cc_session_count` events (publisher: team2 backend, see API-05 WS Events).
// - Until backend publishes the event, the provider stays at 0; the pill
//   gracefully renders "Active CC · 0" with the idle dot.
//
// Design SSOT reference: `EBS_Lobby_Design/shell.jsx:53` cc-pill.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active CC session count. Drives the LobbyTopBar `activeCcCount` pill.
///
/// Mutate via `ref.read(activeCcCountProvider.notifier).state = N`. The
/// WebSocket dispatcher listens for `cc_session_count` events on
/// `/ws/lobby` and updates this state when wired up (Phase 3 backend).
final activeCcCountProvider = StateProvider<int>((ref) => 0);

/// Levels strip data — current / next / after + countdown.
///
/// Populated from the flight metadata API once team2 publishes
/// `GET /flights/:flightId/levels`. Until then, callers receive `null`
/// and the LevelsStrip widget falls back to its hardcoded mock visuals.
class LobbyLevelInfo {
  const LobbyLevelInfo({
    required this.role,
    required this.blinds,
    required this.meta,
  });

  final String role;
  final String blinds;
  final String meta;
}

class LobbyLevelsSnapshot {
  const LobbyLevelsSnapshot({
    required this.now,
    required this.next,
    required this.after,
    required this.countdownLabel,
    required this.countdown,
  });

  final LobbyLevelInfo now;
  final LobbyLevelInfo next;
  final LobbyLevelInfo after;
  final String countdownLabel;
  final String countdown;
}

/// Per-flight level snapshot. Returns null until the backend ships the
/// `GET /flights/:flightId/levels` endpoint (Phase 3 backend follow-up).
final flightLevelsProvider =
    StateProvider.family<LobbyLevelsSnapshot?, int>((ref, flightId) => null);
