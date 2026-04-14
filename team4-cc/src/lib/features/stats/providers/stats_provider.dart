// Stats provider — 10-seat VPIP/PFR/3Bet/AF/Hands/WTSD feed (BS-05-07).
//
// Holds per-player statistics and hand history for AT-04 Statistics screen.
// Data fed from engine OutputEvents or BO REST API.

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Player Stats
// ---------------------------------------------------------------------------

class PlayerStats {
  const PlayerStats({
    required this.seatNo,
    required this.playerName,
    this.vpip = 0.0,
    this.pfr = 0.0,
    this.threeBet = 0.0,
    this.af = 0.0,
    this.hands = 0,
    this.wtsd = 0.0,
  });

  final int seatNo;
  final String playerName;
  final double vpip; // Voluntarily Put $ In Pot %
  final double pfr; // Pre-Flop Raise %
  final double threeBet; // 3-Bet %
  final double af; // Aggression Factor
  final int hands; // Hands played
  final double wtsd; // Went To ShowDown %

  PlayerStats copyWith({
    int? seatNo,
    String? playerName,
    double? vpip,
    double? pfr,
    double? threeBet,
    double? af,
    int? hands,
    double? wtsd,
  }) =>
      PlayerStats(
        seatNo: seatNo ?? this.seatNo,
        playerName: playerName ?? this.playerName,
        vpip: vpip ?? this.vpip,
        pfr: pfr ?? this.pfr,
        threeBet: threeBet ?? this.threeBet,
        af: af ?? this.af,
        hands: hands ?? this.hands,
        wtsd: wtsd ?? this.wtsd,
      );
}

// ---------------------------------------------------------------------------
// Hand History
// ---------------------------------------------------------------------------

class HandHistoryEntry {
  const HandHistoryEntry({
    required this.handNumber,
    required this.winnerName,
    required this.loserNames,
    required this.potSize,
    this.boardCards = const [],
    this.actions = const [],
    this.timestamp,
  });

  final int handNumber;
  final String winnerName;
  final List<String> loserNames;
  final int potSize;
  final List<String> boardCards; // e.g. ["As", "Kd", "Qh", "Jc", "Ts"]
  final List<String> actions; // e.g. ["S1 raises 200", "S3 calls 200"]
  final DateTime? timestamp;
}

// ---------------------------------------------------------------------------
// Stats Notifier
// ---------------------------------------------------------------------------

class StatsNotifier extends StateNotifier<List<PlayerStats>> {
  StatsNotifier() : super(const []);

  /// Full replacement from server push.
  void updateAll(List<PlayerStats> stats) => state = stats;

  /// Update stats for a single seat.
  void updateSeat(int seatNo, PlayerStats stats) {
    state = [
      for (final s in state)
        if (s.seatNo == seatNo) stats else s,
    ];
  }

  /// Clear all stats (table reset).
  void clear() => state = const [];
}

// ---------------------------------------------------------------------------
// Hand History Notifier
// ---------------------------------------------------------------------------

class HandHistoryNotifier extends StateNotifier<List<HandHistoryEntry>> {
  HandHistoryNotifier() : super(const []);

  /// Add a completed hand to history (prepend — newest first).
  void addHand(HandHistoryEntry entry) {
    state = [entry, ...state];
  }

  /// Full replacement from server sync.
  void replaceAll(List<HandHistoryEntry> entries) => state = entries;

  /// Clear all history.
  void clear() => state = const [];
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final statsProvider = StateNotifierProvider<StatsNotifier, List<PlayerStats>>(
  (ref) => StatsNotifier(),
);

final handHistoryProvider =
    StateNotifierProvider<HandHistoryNotifier, List<HandHistoryEntry>>(
  (ref) => HandHistoryNotifier(),
);

/// Derived: session hand count.
final sessionHandCountProvider = Provider<int>((ref) {
  return ref.watch(handHistoryProvider).length;
});

/// Derived: total hands across all players (max of individual counts).
final totalHandCountProvider = Provider<int>((ref) {
  final stats = ref.watch(statsProvider);
  if (stats.isEmpty) return 0;
  return stats.fold<int>(0, (max, s) => s.hands > max ? s.hands : max);
});
