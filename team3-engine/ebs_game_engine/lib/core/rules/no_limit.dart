import 'dart:math' as math;

import '../state/game_state.dart';
import 'bet_limit.dart';

/// No-Limit betting: any amount from the minimum up to the player's
/// entire stack.
class NoLimitBet extends BetLimit {
  const NoLimitBet();

  @override
  String get name => 'No Limit';

  @override
  int minBet(GameState state) {
    final bb = state.bbAmount;
    final stack = state.seats[state.actionOn].stack;
    return math.min(bb, stack);
  }

  @override
  int maxBet(GameState state, int seatIndex) {
    return state.seats[seatIndex].stack;
  }

  @override
  int minRaiseTo(GameState state) {
    return state.betting.currentBet + state.betting.minRaise;
  }

  @override
  int maxRaiseTo(GameState state, int seatIndex) {
    final seat = state.seats[seatIndex];
    return seat.stack + seat.currentBet;
  }

  @override
  int? get raiseCap => null;
}
