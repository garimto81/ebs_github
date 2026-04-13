import 'dart:math' as math;

import '../state/game_state.dart';
import 'bet_limit.dart';

/// Fixed-Limit betting: bets and raises are a fixed amount that depends
/// on the street. Preflop and flop use the small bet; turn and river
/// use the big bet. A maximum of 4 bets per street (1 bet + 3 raises).
class FixedLimitBet extends BetLimit {
  /// The small bet size (used on preflop and flop).
  final int smallBet;

  /// The big bet size (used on turn and river), typically 2x [smallBet].
  final int bigBet;

  const FixedLimitBet({required this.smallBet, required this.bigBet});

  /// Returns the fixed bet size for the current street.
  int _betSize(GameState state) {
    return switch (state.street) {
      Street.idle || Street.setupHand || Street.preflop || Street.flop => smallBet,
      Street.turn || Street.river || Street.showdown ||
      Street.handComplete || Street.runItMultiple =>
        bigBet,
    };
  }

  @override
  String get name => 'Fixed Limit';

  @override
  int minBet(GameState state) {
    final size = _betSize(state);
    final stack = state.seats[state.actionOn].stack;
    return math.min(size, stack);
  }

  @override
  int maxBet(GameState state, int seatIndex) {
    final size = _betSize(state);
    final stack = state.seats[seatIndex].stack;
    return math.min(size, stack);
  }

  @override
  int minRaiseTo(GameState state) {
    return state.betting.currentBet + _betSize(state);
  }

  @override
  int maxRaiseTo(GameState state, int seatIndex) {
    final seat = state.seats[seatIndex];
    final raiseTo = state.betting.currentBet + _betSize(state);
    // Cap at the player's total possible bet
    return math.min(raiseTo, seat.stack + seat.currentBet);
  }

  @override
  int? get raiseCap => 4;
}
