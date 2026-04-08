/// EBS Game Engine — public API.
///
/// Import this single file to access all engine types:
/// ```dart
/// import 'package:ebs_game_engine/engine.dart';
/// ```
library;

// Cards
export 'core/cards/card.dart';
export 'core/cards/deck.dart';
export 'core/cards/hand_evaluator.dart';

// State
export 'core/state/seat.dart';
export 'core/state/pot.dart';
export 'core/state/betting_round.dart';
export 'core/state/game_state.dart';

// Actions & Events
export 'core/actions/action.dart';
export 'core/actions/event.dart';

// Variants
export 'core/variants/variant.dart';
export 'core/variants/nlh.dart';
export 'core/variants/variants.dart';

// Rules
export 'core/rules/betting_rules.dart';
export 'core/rules/street_machine.dart';
export 'core/rules/showdown.dart';

import 'core/state/game_state.dart';
import 'core/state/seat.dart';
import 'core/actions/event.dart';
import 'core/rules/betting_rules.dart';
import 'core/rules/street_machine.dart';

/// The main game engine. All methods are pure functions:
/// given a state and an event, produce a new state.
class Engine {
  Engine._();

  /// Apply an event to the current state, producing a new state.
  static GameState apply(GameState state, Event event) {
    return switch (event) {
      final HandStart e => _startHand(state, e),
      final DealHoleCards e => _dealHole(state, e),
      final DealCommunity e => _dealCommunity(state, e),
      final PineappleDiscard e => _pineappleDiscard(state, e),
      final PlayerAction e => _playerAction(state, e),
      final StreetAdvance e => _streetAdvance(state, e),
      final PotAwarded e => _awardPot(state, e),
      final HandEnd _ => _endHand(state),
    };
  }

  /// Get legal actions for the current player.
  static List<LegalAction> legalActions(GameState state) =>
      BettingRules.legalActions(state);

  // ── Private handlers ──

  static GameState _startHand(GameState state, HandStart event) {
    final newState = state.copyWith(
      handInProgress: true,
      dealerSeat: event.dealerSeat,
      street: Street.preflop,
      community: [],
    );

    // Reset all seats for new hand
    for (final seat in newState.seats) {
      if (seat.status != SeatStatus.sittingOut) {
        seat.status = SeatStatus.active;
      }
      seat.currentBet = 0;
      seat.holeCards = [];
    }

    // Determine SB/BB positions
    final n = newState.seats.length;
    final activeSeatIndices = <int>[];
    for (var i = 0; i < n; i++) {
      final idx = (event.dealerSeat + 1 + i) % n;
      if (newState.seats[idx].isActive) {
        activeSeatIndices.add(idx);
      }
    }

    int sbIdx, bbIdx;
    if (n == 2) {
      // Heads-up: dealer is SB
      sbIdx = event.dealerSeat;
      bbIdx = activeSeatIndices.firstWhere((i) => i != event.dealerSeat);
    } else {
      sbIdx = activeSeatIndices[0];
      bbIdx = activeSeatIndices[1];
    }

    // Post blinds from event.blinds map
    final pot = newState.pot;
    pot.main = 0;
    pot.sides = [];

    for (final entry in event.blinds.entries) {
      final seat = newState.seats[entry.key];
      final amount = entry.value < seat.stack ? entry.value : seat.stack;
      seat.stack -= amount;
      seat.currentBet = amount;
      pot.addToMain(amount);
      if (seat.stack == 0) {
        seat.status = SeatStatus.allIn;
      }
    }

    // Determine BB amount from blinds
    final bbAmount = event.blinds[bbIdx] ?? 0;

    // Set betting round
    newState.betting.currentBet = bbAmount;
    newState.betting.minRaise = bbAmount;
    newState.betting.lastRaise = 0;
    newState.betting.lastAggressor = -1;
    newState.betting.actedThisRound.clear();
    newState.betting.bbOptionPending = true;

    // Find first to act
    final firstAct = StreetMachine.firstToAct(newState.copyWith(
      sbSeat: sbIdx,
      bbSeat: bbIdx,
      bbAmount: bbAmount,
    ));

    return newState.copyWith(
      sbSeat: sbIdx,
      bbSeat: bbIdx,
      bbAmount: bbAmount,
      actionOn: firstAct,
    );
  }

  static GameState _dealHole(GameState state, DealHoleCards event) {
    final newState = state.copyWith();
    for (final entry in event.cards.entries) {
      newState.seats[entry.key].holeCards = List.of(entry.value);
    }
    return newState;
  }

  static GameState _dealCommunity(GameState state, DealCommunity event) {
    return state.copyWith(
      community: [...state.community, ...event.cards],
    );
  }

  static GameState _pineappleDiscard(
      GameState state, PineappleDiscard event) {
    final newState = state.copyWith();
    newState.seats[event.seatIndex].holeCards.remove(event.discarded);
    return newState;
  }

  static GameState _playerAction(GameState state, PlayerAction event) {
    final newState =
        BettingRules.applyAction(state, event.seatIndex, event.action);

    // Check if all but one folded
    final activeCount =
        newState.seats.where((s) => s.isActive || s.isAllIn).length;
    if (activeCount <= 1) {
      return newState.copyWith(actionOn: -1);
    }

    // Check if round is complete
    if (BettingRules.isRoundComplete(newState)) {
      return newState.copyWith(actionOn: -1); // Signal: advance street
    }

    // Next player to act
    final next = StreetMachine.nextToAct(newState);
    return newState.copyWith(actionOn: next);
  }

  static GameState _streetAdvance(GameState state, StreetAdvance event) {
    // Override target street from event
    final newState = state.copyWith(street: event.next);

    // Reset seat bets
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

    // First to act for new street
    final first = StreetMachine.firstToAct(newState);
    return newState.copyWith(actionOn: first);
  }

  static GameState _awardPot(GameState state, PotAwarded event) {
    final newState = state.copyWith();
    for (final entry in event.awards.entries) {
      newState.seats[entry.key].stack += entry.value;
    }
    // Clear pot
    newState.pot.main = 0;
    newState.pot.sides = [];
    return newState;
  }

  static GameState _endHand(GameState state) {
    return state.copyWith(handInProgress: false, actionOn: -1);
  }
}
