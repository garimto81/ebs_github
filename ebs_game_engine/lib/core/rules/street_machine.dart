import '../state/game_state.dart';

/// Pure-function street progression logic.
class StreetMachine {
  StreetMachine._();

  /// Get the next street after [current].
  static Street nextStreet(Street current) => switch (current) {
        Street.preflop => Street.flop,
        Street.flop => Street.turn,
        Street.turn => Street.river,
        Street.river => Street.showdown,
        Street.showdown => throw StateError('No street after showdown'),
      };

  /// Number of community cards to deal for a given street.
  static int communityCardsToDeal(Street street) => switch (street) {
        Street.flop => 3,
        Street.turn => 1,
        Street.river => 1,
        _ => 0,
      };

  /// Determine which seat acts first for the current street.
  ///
  /// Preflop: UTG (first active seat after BB).
  /// Heads-up preflop: SB/BTN acts first.
  /// Postflop: first active seat after dealer.
  static int firstToAct(GameState state) {
    final n = state.seats.length;

    if (state.street == Street.preflop) {
      // Heads-up: SB (== dealer) acts first preflop
      if (n == 2) {
        return state.sbSeat;
      }
      // Multi-way: UTG = first active after BB
      return _nextActiveSeat(state, state.bbSeat);
    }

    // Postflop: first active after dealer
    return _nextActiveSeat(state, state.dealerSeat);
  }

  /// Find the next active (not folded, not allIn) seat after [fromSeat].
  static int _nextActiveSeat(GameState state, int fromSeat) {
    final n = state.seats.length;
    for (var i = 1; i <= n; i++) {
      final idx = (fromSeat + i) % n;
      if (state.seats[idx].isActive) return idx;
    }
    return -1; // No active seat found
  }

  /// Find the next seat to act after [state.actionOn].
  static int nextToAct(GameState state) {
    return _nextActiveSeat(state, state.actionOn);
  }

  /// Advance to the next street: reset bets, create new betting round,
  /// set firstToAct.
  static GameState advanceStreet(GameState state) {
    final next = nextStreet(state.street);
    final newState = state.copyWith(street: next);

    // Reset all seat currentBets
    for (final seat in newState.seats) {
      seat.currentBet = 0;
    }

    // Fresh betting round
    newState.betting.currentBet = 0;
    newState.betting.minRaise = state.bbAmount;
    newState.betting.lastRaise = 0;
    newState.betting.lastAggressor = -1;
    newState.betting.actedThisRound.clear();
    newState.betting.bbOptionPending = false;

    // Set first to act (use newState which has updated street)
    final first = firstToAct(newState);
    return newState.copyWith(actionOn: first);
  }
}
