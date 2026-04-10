import 'dart:math' as math;

import '../state/game_state.dart';
import 'bet_limit.dart';

/// Pot-Limit betting: any amount from the minimum up to the current
/// pot size (including the amount needed to call).
class PotLimitBet extends BetLimit {
  const PotLimitBet();

  @override
  String get name => 'Pot Limit';

  /// Total pot = main pot + side pots + all current bets on the table.
  int _totalPot(GameState state) {
    final mainPot = state.pot.main;
    final sidePots = state.pot.sides.fold<int>(0, (s, p) => s + p.amount);
    final tableBets = state.seats.fold<int>(0, (s, seat) => s + seat.currentBet);
    return mainPot + sidePots + tableBets;
  }

  @override
  int minBet(GameState state) {
    final bb = state.bbAmount;
    final stack = state.seats[state.actionOn].stack;
    return math.min(bb, stack);
  }

  @override
  int maxBet(GameState state, int seatIndex) {
    final stack = state.seats[seatIndex].stack;
    final potSize = _totalPot(state);
    return math.min(stack, potSize);
  }

  @override
  int minRaiseTo(GameState state) {
    return state.betting.currentBet + state.betting.minRaise;
  }

  @override
  int maxRaiseTo(GameState state, int seatIndex) {
    final seat = state.seats[seatIndex];
    final currentBet = state.betting.currentBet;
    final seatBet = seat.currentBet;

    // Standard pot-limit raise formula:
    // 1. Call amount to match the current bet
    final callAmount = currentBet - seatBet;
    // 2. Pot after the call
    final potAfterCall = _totalPot(state) + callAmount;
    // 3. Maximum raise size = pot after call
    final maxRaiseSize = potAfterCall;
    // 4. Maximum raise-to = current bet + raise size
    final maxRaise = currentBet + maxRaiseSize;

    // Cap at the player's total possible bet (stack + what they've already put in)
    return math.min(maxRaise, seat.stack + seatBet);
  }

  @override
  int? get raiseCap => null;
}
