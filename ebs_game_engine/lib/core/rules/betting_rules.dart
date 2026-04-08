import '../state/game_state.dart';
import '../state/seat.dart';
import '../actions/action.dart';

/// Describes a single legal action available to the current player.
class LegalAction {
  final String type; // fold, check, call, bet, raise
  final int? minAmount;
  final int? maxAmount;
  final int? callAmount;

  const LegalAction({
    required this.type,
    this.minAmount,
    this.maxAmount,
    this.callAmount,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        if (minAmount != null) 'minAmount': minAmount,
        if (maxAmount != null) 'maxAmount': maxAmount,
        if (callAmount != null) 'callAmount': callAmount,
      };
}

/// Pure-function betting rules for No-Limit poker.
class BettingRules {
  BettingRules._();

  /// Calculate valid actions for the current player (state.actionOn).
  static List<LegalAction> legalActions(GameState state) {
    if (state.actionOn < 0 || state.actionOn >= state.seats.length) return [];
    final seat = state.seats[state.actionOn];
    if (!seat.isActive) return [];

    final stack = seat.stack;
    final seatBet = seat.currentBet;
    final currentBet = state.betting.currentBet;
    final minRaise = state.betting.minRaise;
    final toCall = currentBet - seatBet;
    final bb = state.bbAmount;

    // BB option: hero is BB, currentBet == BB, and option pending
    final isBbOption = state.betting.bbOptionPending &&
        state.actionOn == state.bbSeat &&
        toCall == 0;

    final actions = <LegalAction>[];

    // Fold: always available
    actions.add(const LegalAction(type: 'fold'));

    if (isBbOption) {
      // BB option: check or raise
      actions.add(const LegalAction(type: 'check'));
      if (stack > 0) {
        final raiseMin = currentBet + minRaise;
        final raiseMax = stack + seatBet;
        if (raiseMax >= raiseMin) {
          actions.add(LegalAction(
            type: 'raise',
            minAmount: raiseMin,
            maxAmount: raiseMax,
          ));
        }
      }
    } else if (toCall == 0) {
      // No bet to call: check or bet
      actions.add(const LegalAction(type: 'check'));
      if (stack > 0) {
        final betMin = bb > 0 ? bb : minRaise;
        actions.add(LegalAction(
          type: 'bet',
          minAmount: betMin > stack ? stack : betMin,
          maxAmount: stack,
        ));
      }
    } else {
      // Facing a bet/raise
      final callAmt = toCall < stack ? toCall : stack;
      actions.add(LegalAction(type: 'call', callAmount: callAmt));

      // Can only raise if stack > toCall
      if (stack > toCall) {
        final raiseMin = currentBet + minRaise;
        final raiseMax = stack + seatBet;
        if (raiseMax >= raiseMin) {
          actions.add(LegalAction(
            type: 'raise',
            minAmount: raiseMin,
            maxAmount: raiseMax,
          ));
        }
      }
    }

    return actions;
  }

  /// Apply an action to the game state, returning a new state.
  static GameState applyAction(GameState state, int seatIndex, Action action) {
    final newState = state.copyWith();
    final seat = newState.seats[seatIndex];
    final betting = newState.betting;

    betting.actedThisRound.add(seatIndex);

    switch (action) {
      case Fold():
        seat.status = SeatStatus.folded;

      case Check():
        // No change to stack/bets
        if (betting.bbOptionPending && seatIndex == state.bbSeat) {
          betting.bbOptionPending = false;
        }

      case Call(:final amount):
        final deduct = amount < seat.stack ? amount : seat.stack;
        seat.stack -= deduct;
        seat.currentBet += deduct;
        newState.pot.addToMain(deduct);
        if (seat.stack == 0) {
          seat.status = SeatStatus.allIn;
        }

      case Bet(:final amount):
        seat.stack -= amount;
        seat.currentBet += amount;
        newState.pot.addToMain(amount);
        betting.currentBet = seat.currentBet;
        betting.minRaise = amount;
        betting.lastAggressor = seatIndex;
        if (seat.stack == 0) {
          seat.status = SeatStatus.allIn;
        }

      case Raise(:final toAmount):
        final increment = toAmount - seat.currentBet;
        seat.stack -= increment;
        final raiseSize = toAmount - betting.currentBet;
        if (raiseSize > betting.minRaise) {
          betting.minRaise = raiseSize;
        }
        seat.currentBet = toAmount;
        newState.pot.addToMain(increment);
        betting.currentBet = toAmount;
        betting.lastAggressor = seatIndex;
        if (seat.stack == 0) {
          seat.status = SeatStatus.allIn;
        }
        if (betting.bbOptionPending) {
          betting.bbOptionPending = false;
        }

      case AllIn(:final amount):
        seat.stack -= amount;
        seat.currentBet += amount;
        newState.pot.addToMain(amount);
        seat.status = SeatStatus.allIn;
        if (seat.currentBet > betting.currentBet) {
          final raiseSize = seat.currentBet - betting.currentBet;
          if (raiseSize > betting.minRaise) {
            betting.minRaise = raiseSize;
          }
          betting.currentBet = seat.currentBet;
          betting.lastAggressor = seatIndex;
        }
    }

    return newState;
  }

  /// Check if the current betting round is complete.
  static bool isRoundComplete(GameState state) {
    final active = state.seats.where((s) => s.isActive).toList();
    if (active.length <= 1) return true;

    // BB option still pending
    if (state.betting.bbOptionPending) return false;

    return active.every((s) =>
        state.betting.actedThisRound.contains(s.index) &&
        s.currentBet == state.betting.currentBet);
  }
}
