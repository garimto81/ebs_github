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

import '../../../data/remote/bo_api_client.dart';

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

/// Per-flight level snapshot — fetches `GET /api/v1/flights/:flightId/levels`
/// (team2 endpoint, 2026-05-06 Phase 3.B). Auto-refreshes when watched.
///
/// Returns null when:
///   · 404 (flight 미존재) / 401 (인증 실패) → caller 가 placeholder 표시
///   · backend `data: null` (flight 의 blind_structure 미할당)
final flightLevelsProvider =
    FutureProvider.family<LobbyLevelsSnapshot?, int>((ref, flightId) async {
  final client = ref.watch(boApiClientProvider);
  try {
    final raw = await client.get<Map<String, dynamic>?>(
      '/flights/$flightId/levels',
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          final data = json['data'];
          return data is Map<String, dynamic> ? data : null;
        }
        return null;
      },
    );
    if (raw == null) return null;

    LobbyLevelInfo? parseLevel(dynamic m) {
      if (m is! Map<String, dynamic>) return null;
      return LobbyLevelInfo(
        role: m['role'] as String? ?? '',
        blinds: m['blinds'] as String? ?? '',
        meta: m['meta'] as String? ?? '',
      );
    }

    final now = parseLevel(raw['now']);
    final next = parseLevel(raw['next']);
    final after = parseLevel(raw['after']);
    if (now == null || next == null || after == null) return null;

    return LobbyLevelsSnapshot(
      now: now,
      next: next,
      after: after,
      countdownLabel: raw['countdownLabel'] as String? ?? '—',
      countdown: raw['countdown'] as String? ?? '—',
    );
  } catch (_) {
    return null;
  }
});
