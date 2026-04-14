// Game configuration provider (BS-05-08).
//
// Holds table-level game settings that affect CC behavior:
//   - Game type and bet structure
//   - Blind levels (SB/BB/ante)
//   - Straddle configuration
//   - Timer settings
//
// Settings come from server via WebSocket (Settings tab in Lobby).
// CC is a consumer only — no local editing (BS-03 settings are global).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/enums/game_type.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class GameConfig {
  const GameConfig({
    this.gameType = GameType.holdem,
    this.betStructure = BetStructure.noLimit,
    this.smallBlind = 100,
    this.bigBlind = 200,
    this.ante = 0,
    this.bigBlindAnte = false,
    this.straddleSeats = const [],
    this.blindStructureId,
    this.timeBankSeconds = 30,
    this.shotClockSeconds = 0,
    this.maxBuyIn = 0,
    this.minBuyIn = 0,
    this.tableName = '',
    this.tableNumber = 0,
  });

  final GameType gameType;
  final BetStructure betStructure;
  final int smallBlind;
  final int bigBlind;
  final int ante;
  final bool bigBlindAnte; // ante collected from BB position only
  final List<int> straddleSeats; // seat numbers allowed to straddle
  final String? blindStructureId; // tournament blind level ID
  final int timeBankSeconds;
  final int shotClockSeconds; // 0 = disabled
  final int maxBuyIn;
  final int minBuyIn;
  final String tableName;
  final int tableNumber;

  /// Whether this is a tournament (has blind structure) or cash game.
  bool get isTournament => blindStructureId != null;

  /// Short display label (e.g., "NL Hold'em 100/200").
  String get displayLabel {
    final prefix = betStructure == BetStructure.noLimit
        ? 'NL'
        : betStructure == BetStructure.potLimit
            ? 'PL'
            : 'FL';
    final game = gameType.name[0].toUpperCase() + gameType.name.substring(1);
    return '$prefix $game $smallBlind/$bigBlind';
  }

  GameConfig copyWith({
    GameType? gameType,
    BetStructure? betStructure,
    int? smallBlind,
    int? bigBlind,
    int? ante,
    bool? bigBlindAnte,
    List<int>? straddleSeats,
    String? blindStructureId,
    bool clearBlindStructureId = false,
    int? timeBankSeconds,
    int? shotClockSeconds,
    int? maxBuyIn,
    int? minBuyIn,
    String? tableName,
    int? tableNumber,
  }) =>
      GameConfig(
        gameType: gameType ?? this.gameType,
        betStructure: betStructure ?? this.betStructure,
        smallBlind: smallBlind ?? this.smallBlind,
        bigBlind: bigBlind ?? this.bigBlind,
        ante: ante ?? this.ante,
        bigBlindAnte: bigBlindAnte ?? this.bigBlindAnte,
        straddleSeats: straddleSeats ?? this.straddleSeats,
        blindStructureId: clearBlindStructureId
            ? null
            : (blindStructureId ?? this.blindStructureId),
        timeBankSeconds: timeBankSeconds ?? this.timeBankSeconds,
        shotClockSeconds: shotClockSeconds ?? this.shotClockSeconds,
        maxBuyIn: maxBuyIn ?? this.maxBuyIn,
        minBuyIn: minBuyIn ?? this.minBuyIn,
        tableName: tableName ?? this.tableName,
        tableNumber: tableNumber ?? this.tableNumber,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ConfigNotifier extends StateNotifier<GameConfig> {
  ConfigNotifier() : super(const GameConfig());

  /// Full replacement from server settings push.
  void updateFromServer(GameConfig config) => state = config;

  /// Update blind level (tournament level change).
  void updateBlinds({
    required int smallBlind,
    required int bigBlind,
    int? ante,
  }) {
    state = state.copyWith(
      smallBlind: smallBlind,
      bigBlind: bigBlind,
      ante: ante,
    );
  }

  /// Update game type (Mix game rotation).
  void updateGameType(GameType gameType) {
    state = state.copyWith(gameType: gameType);
  }

  /// Force state (server sync / reconnect).
  void forceState(GameConfig config) => state = config;
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final configProvider = StateNotifierProvider<ConfigNotifier, GameConfig>(
  (ref) => ConfigNotifier(),
);

/// Derived: game type shorthand for display.
final gameDisplayLabelProvider = Provider<String>((ref) {
  return ref.watch(configProvider).displayLabel;
});

/// Derived: whether ante is active.
final hasAnteProvider = Provider<bool>((ref) {
  return ref.watch(configProvider).ante > 0;
});
