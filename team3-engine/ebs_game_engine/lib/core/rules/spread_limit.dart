import 'dart:math' as math;

import '../state/game_state.dart';
import 'bet_limit.dart';

/// Spread-Limit betting: bets and raises must be within a fixed range
/// [lowLimit]..[highLimit]. Common in low-stakes casino games
/// (e.g. $1-$5 spread).
class SpreadLimitBet extends BetLimit {
  /// Minimum bet/raise size.
  final int lowLimit;

  /// Maximum bet/raise size.
  final int highLimit;

  const SpreadLimitBet({required this.lowLimit, required this.highLimit});

  @override
  String get name => 'Spread Limit';

  @override
  int minBet(GameState state) {
    final stack = state.seats[state.actionOn].stack;
    return math.min(lowLimit, stack);
  }

  @override
  int maxBet(GameState state, int seatIndex) {
    final stack = state.seats[seatIndex].stack;
    return math.min(highLimit, stack);
  }

  @override
  int minRaiseTo(GameState state) {
    return state.betting.currentBet + lowLimit;
  }

  @override
  int maxRaiseTo(GameState state, int seatIndex) {
    final seat = state.seats[seatIndex];
    final raiseTo = state.betting.currentBet + highLimit;
    // Cap at the player's total possible bet
    return math.min(raiseTo, seat.stack + seat.currentBet);
  }

  @override
  int? get raiseCap => null;
}
