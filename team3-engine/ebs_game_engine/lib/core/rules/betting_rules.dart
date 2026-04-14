import '../state/game_state.dart';
import '../state/seat.dart';
import '../actions/action.dart';
import 'bet_limit.dart';
import 'no_limit.dart';

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

/// Pure-function betting rules — delegates min/max calculations to [BetLimit].
class BettingRules {
  BettingRules._();

  /// Calculate valid actions for the current player (state.actionOn).
  static List<LegalAction> legalActions(GameState state) {
    if (state.actionOn < 0 || state.actionOn >= state.seats.length) return [];
    final seat = state.seats[state.actionOn];
    if (!seat.isActive) return [];

    final limit = state.betLimit ?? const NoLimitBet();
    final stack = seat.stack;
    final seatBet = seat.currentBet;
    final currentBet = state.betting.currentBet;
    final toCall = currentBet - seatBet;

    final isBbOption = state.betting.bbOptionPending &&
        state.actionOn == state.bbSeat &&
        toCall == 0;

    final actions = <LegalAction>[];
    actions.add(const LegalAction(type: 'fold'));

    if (isBbOption) {
      actions.add(const LegalAction(type: 'check'));
      if (stack > 0 && _canRaise(state, limit)) {
        final raiseMin = limit.minRaiseTo(state);
        final raiseMax = limit.maxRaiseTo(state, state.actionOn);
        if (raiseMax >= raiseMin) {
          actions.add(LegalAction(
            type: 'raise',
            minAmount: raiseMin,
            maxAmount: raiseMax,
          ));
        }
      }
    } else if (toCall == 0) {
      actions.add(const LegalAction(type: 'check'));
      if (stack > 0) {
        final betMin = limit.minBet(state);
        final betMax = limit.maxBet(state, state.actionOn);
        if (betMax >= betMin) {
          actions.add(LegalAction(
            type: 'bet',
            minAmount: betMin,
            maxAmount: betMax,
          ));
        }
      }
    } else {
      final callAmt = toCall < stack ? toCall : stack;
      actions.add(LegalAction(type: 'call', callAmount: callAmt));

      if (stack > toCall && _canRaise(state, limit)) {
        final raiseMin = limit.minRaiseTo(state);
        final raiseMax = limit.maxRaiseTo(state, state.actionOn);
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

  /// Check if raising is allowed (raise cap enforcement for FL).
  static bool _canRaise(GameState state, BetLimit limit) {
    if (limit.raiseCap == null) return true;
    // Heads-up exception: cap does not apply
    final activeCount = state.seats.where((s) => s.isActive).length;
    if (activeCount <= 2) return true;
    return state.betting.raiseCount < limit.raiseCap!;
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

      case Call():
        final toCall = betting.currentBet - seat.currentBet;
        final deduct = toCall < seat.stack ? toCall : seat.stack;
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
        betting.raiseCount += 1;
        if (seat.stack == 0) {
          seat.status = SeatStatus.allIn;
        }

      case Raise(:final toAmount):
        final minRaiseTotal = betting.currentBet + betting.minRaise;
        final rawIncrement = toAmount - seat.currentBet;
        final increment = rawIncrement.clamp(0, seat.stack);
        final actualToAmount = seat.currentBet + increment;
        final raiseSize = actualToAmount - betting.currentBet;

        // WSOP Rule 95: under-raise threshold (50%)
        if (raiseSize > 0 && raiseSize < betting.minRaise) {
          if (raiseSize < betting.minRaise * 0.5) {
            // Below 50% → convert to Call
            final toCall = betting.currentBet - seat.currentBet;
            final callDeduct = toCall < seat.stack ? toCall : seat.stack;
            seat.stack -= callDeduct;
            seat.currentBet += callDeduct;
            newState.pot.addToMain(callDeduct);
            if (seat.stack == 0) seat.status = SeatStatus.allIn;
            break;
          }
          // 50%+ → round up to min raise total
          final correctedIncrement = (minRaiseTotal - seat.currentBet).clamp(0, seat.stack);
          seat.stack -= correctedIncrement;
          final correctedTotal = seat.currentBet + correctedIncrement;
          seat.currentBet = correctedTotal;
          newState.pot.addToMain(correctedIncrement);
          betting.currentBet = correctedTotal;
          // minRaise unchanged (rounded up to exactly min raise)
          betting.lastAggressor = seatIndex;
          betting.raiseCount += 1;
          if (seat.stack == 0) seat.status = SeatStatus.allIn;
          if (betting.bbOptionPending) betting.bbOptionPending = false;
          betting.actedThisRound = {seatIndex};
          break;
        }

        // Normal raise
        seat.stack -= increment;
        if (raiseSize > betting.minRaise) {
          betting.minRaise = raiseSize;
        }
        seat.currentBet = actualToAmount;
        newState.pot.addToMain(increment);
        betting.currentBet = actualToAmount;
        betting.lastAggressor = seatIndex;
        betting.raiseCount += 1;
        if (seat.stack == 0) {
          seat.status = SeatStatus.allIn;
        }
        if (betting.bbOptionPending) {
          betting.bbOptionPending = false;
        }
        // Reset acted tracking — all players must re-act after raise
        betting.actedThisRound = {seatIndex};

      case AllIn():
        final allInAmount = seat.stack; // always go all-in for remaining stack
        seat.stack = 0;
        seat.currentBet += allInAmount;
        newState.pot.addToMain(allInAmount);
        seat.status = SeatStatus.allIn;
        if (seat.currentBet > betting.currentBet) {
          final raiseSize = seat.currentBet - betting.currentBet;
          if (raiseSize >= betting.minRaise) {
            // Complete raise — full reopen (WSOP Rule 96: full raise)
            betting.minRaise = raiseSize;
            betting.currentBet = seat.currentBet;
            betting.lastAggressor = seatIndex;
            betting.raiseCount += 1;
            betting.actedThisRound = {seatIndex};
          } else {
            // WSOP Rule 96: incomplete all-in — no reopen
            // minRaise, lastAggressor, actedThisRound unchanged
            betting.currentBet = seat.currentBet;
          }
        }
    }

    return newState;
  }

  /// Check if the current betting round is complete.
  ///
  /// BB's preflop check option is handled naturally: BB is not added to
  /// [actedThisRound] during blind posting, so the round cannot complete
  /// until BB takes an explicit action (check, raise, fold).
  static bool isRoundComplete(GameState state) {
    final active = state.seats.where((s) => s.isActive).toList();

    // All players folded or all-in — no action possible
    if (active.isEmpty) return true;

    // Single active player remaining
    if (active.length == 1) {
      // If no all-in opponents exist, everyone else folded → instant win
      final hasAllIn = state.seats.any((s) => s.isAllIn);
      if (!hasAllIn) return true;
      // All-in opponents exist: active player must act and match bet
      final s = active.first;
      return state.betting.actedThisRound.contains(s.index) &&
          s.currentBet == state.betting.currentBet;
    }

    // Multiple active players: all must act and match
    return active.every((s) =>
        state.betting.actedThisRound.contains(s.index) &&
        s.currentBet == state.betting.currentBet);
  }
}
