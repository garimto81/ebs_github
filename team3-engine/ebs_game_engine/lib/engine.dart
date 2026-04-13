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

// Math
export 'core/math/equity_calculator.dart';

// State
export 'core/state/seat.dart';
export 'core/state/pot.dart';
export 'core/state/betting_round.dart';
export 'core/state/game_state.dart';
export 'core/state/card_reveal_config.dart';

// Actions & Events
export 'core/actions/action.dart';
export 'core/actions/event.dart';
export 'core/actions/output_event.dart';
export 'core/actions/reduce_result.dart';

// Variants
export 'core/variants/variant.dart';
export 'core/variants/nlh.dart';
export 'core/variants/variants.dart';

// Rules
export 'core/rules/bet_limit.dart';
export 'core/rules/no_limit.dart';
export 'core/rules/fixed_limit.dart';
export 'core/rules/pot_limit.dart';
export 'core/rules/betting_rules.dart';
export 'core/rules/street_machine.dart';
export 'core/rules/showdown.dart';
export 'core/rules/showdown_order.dart';

import 'core/cards/card.dart';
import 'core/state/game_state.dart';
import 'core/state/pot.dart';
import 'core/state/seat.dart';
import 'core/actions/action.dart';
import 'core/actions/event.dart';
import 'core/rules/betting_rules.dart';
import 'core/rules/no_limit.dart';
import 'core/rules/street_machine.dart';
import 'core/variants/variants.dart';
import 'core/actions/output_event.dart';
import 'core/actions/reduce_result.dart';

/// The main game engine. All methods are pure functions:
/// given a state and an event, produce a new state.
class Engine {
  Engine._();

  /// Apply an event to the current state, producing a new state.
  /// Legacy wrapper: returns only the new state (backward compatible).
  static GameState apply(GameState state, Event event) {
    return applyFull(state, event).state;
  }

  /// Apply an event, returning new state + output events.
  static ReduceResult applyFull(GameState state, Event event) {
    return switch (event) {
      final HandStart e => _startHandFull(state, e),
      final DealHoleCards e => _dealHoleFull(state, e),
      final DealCommunity e => _dealCommunityFull(state, e),
      final PineappleDiscard e => _pineappleDiscardFull(state, e),
      final PlayerAction e => _playerActionFull(state, e),
      final StreetAdvance e => _streetAdvanceFull(state, e),
      final PotAwarded e => _awardPotFull(state, e),
      final HandEnd _ => _endHandFull(state),
      final MisDeal _ => _handleMisDealFull(state),
      final BombPotConfig e => _handleBombPotConfigFull(state, e),
      final RunItChoice e => _handleRunItChoiceFull(state, e),
      final ManualNextHand _ => _handleManualNextHandFull(state),
      final TimeoutFold e => _handleTimeoutFoldFull(state, e),
      final MuckDecision e => _handleMuckDecisionFull(state, e),
    };
  }

  /// Check if all remaining players are all-in (no further action possible).
  /// The harness uses this to decide whether to auto-deal remaining community cards.
  static bool isAllInRunout(GameState state) {
    final active = state.seats.where((s) => s.isActive).toList();
    final allIn = state.seats.where((s) => s.isAllIn).toList();
    return active.isEmpty && allIn.length >= 2;
  }

  /// Validate that no duplicate cards exist in the current game state.
  /// Returns list of duplicate card descriptions, or empty if all valid.
  static List<String> validateCards(GameState state) {
    final seen = <Card>{};
    final duplicates = <String>[];

    // Check community cards
    for (final card in state.community) {
      if (!seen.add(card)) {
        duplicates.add('Duplicate community card: $card');
      }
    }

    // Check hole cards across all seats
    for (final seat in state.seats) {
      for (final card in seat.holeCards) {
        if (!seen.add(card)) {
          duplicates.add('Duplicate card at seat ${seat.index}: $card');
        }
      }
    }

    return duplicates;
  }

  /// Get legal actions for the current player.
  static List<LegalAction> legalActions(GameState state) =>
      BettingRules.legalActions(state);

  // ── Private handlers (Full versions returning ReduceResult) ──

  static ReduceResult _startHandFull(GameState state, HandStart event) {
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
      seat.antePosted = 0;
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

    // Resolve variant's bet limit
    final variantFactory = variantRegistry[state.variantName];
    final resolvedBetLimit = variantFactory != null
        ? variantFactory().betLimit
        : const NoLimitBet();

    // ── Ante processing ──
    final anteType = newState.anteType;
    final anteAmt = newState.anteAmount ?? 0;
    bool bbActsFirst = false;
    bool sbActsFirst = false;

    if (anteAmt > 0 && anteType != null) {
      switch (anteType) {
        case 0: // Standard Ante — all active players post
          for (final seat in newState.seats) {
            if (seat.isActive || seat.isAllIn) {
              final post = anteAmt < seat.stack ? anteAmt : seat.stack;
              seat.stack -= post;
              seat.antePosted = post;
              newState.pot.addToMain(post);
              if (seat.stack == 0 && seat.status != SeatStatus.allIn) {
                seat.status = SeatStatus.allIn;
              }
            }
          }
        case 1: // Button Ante — dealer posts for all
          final dealer = newState.seats[event.dealerSeat];
          if (dealer.isActive || dealer.isAllIn) {
            final totalAnte = anteAmt * newState.activePlayers.length;
            final post = totalAnte < dealer.stack ? totalAnte : dealer.stack;
            dealer.stack -= post;
            dealer.antePosted = post;
            newState.pot.addToMain(post);
            if (dealer.stack == 0 && dealer.status != SeatStatus.allIn) {
              dealer.status = SeatStatus.allIn;
            }
          }
        case 2: // BB Ante — BB posts for all
          final bb = newState.seats[bbIdx];
          if (bb.isActive || bb.isAllIn) {
            final totalAnte = anteAmt * newState.activePlayers.length;
            final post = totalAnte < bb.stack ? totalAnte : bb.stack;
            bb.stack -= post;
            bb.antePosted = post;
            newState.pot.addToMain(post);
            if (bb.stack == 0 && bb.status != SeatStatus.allIn) {
              bb.status = SeatStatus.allIn;
            }
          }
        case 3: // BB Ante 1st — same as Type 2 but BB acts first
          final bb = newState.seats[bbIdx];
          if (bb.isActive || bb.isAllIn) {
            final totalAnte = anteAmt * newState.activePlayers.length;
            final post = totalAnte < bb.stack ? totalAnte : bb.stack;
            bb.stack -= post;
            bb.antePosted = post;
            newState.pot.addToMain(post);
            if (bb.stack == 0 && bb.status != SeatStatus.allIn) {
              bb.status = SeatStatus.allIn;
            }
          }
          bbActsFirst = true;
        case 4: // Live Ante — all post, counts toward bet
          for (final seat in newState.seats) {
            if (seat.isActive || seat.isAllIn) {
              final post = anteAmt < seat.stack ? anteAmt : seat.stack;
              seat.stack -= post;
              seat.antePosted = post;
              seat.currentBet += post;
              newState.pot.addToMain(post);
              if (seat.stack == 0 && seat.status != SeatStatus.allIn) {
                seat.status = SeatStatus.allIn;
              }
            }
          }
          // Current bet is max of BB and ante
          if (anteAmt > newState.betting.currentBet) {
            newState.betting.currentBet = anteAmt;
          }
        case 5: // TB Ante — SB and BB split total
          final sb = newState.seats[sbIdx];
          final bbSeat = newState.seats[bbIdx];
          final totalAnte = anteAmt * newState.activePlayers.length;
          final halfAnte = totalAnte ~/ 2;
          final otherHalf = totalAnte - halfAnte;
          if (sb.isActive || sb.isAllIn) {
            final sbPost = halfAnte < sb.stack ? halfAnte : sb.stack;
            sb.stack -= sbPost;
            sb.antePosted = sbPost;
            newState.pot.addToMain(sbPost);
            if (sb.stack == 0 && sb.status != SeatStatus.allIn) {
              sb.status = SeatStatus.allIn;
            }
          }
          if (bbSeat.isActive || bbSeat.isAllIn) {
            final bbPost = otherHalf < bbSeat.stack ? otherHalf : bbSeat.stack;
            bbSeat.stack -= bbPost;
            bbSeat.antePosted = bbPost;
            newState.pot.addToMain(bbPost);
            if (bbSeat.stack == 0 && bbSeat.status != SeatStatus.allIn) {
              bbSeat.status = SeatStatus.allIn;
            }
          }
        case 6: // TB Ante 1st — same as Type 5 but SB acts first
          final sb = newState.seats[sbIdx];
          final bbSeat = newState.seats[bbIdx];
          final totalAnte = anteAmt * newState.activePlayers.length;
          final halfAnte = totalAnte ~/ 2;
          final otherHalf = totalAnte - halfAnte;
          if (sb.isActive || sb.isAllIn) {
            final sbPost = halfAnte < sb.stack ? halfAnte : sb.stack;
            sb.stack -= sbPost;
            sb.antePosted = sbPost;
            newState.pot.addToMain(sbPost);
            if (sb.stack == 0 && sb.status != SeatStatus.allIn) {
              sb.status = SeatStatus.allIn;
            }
          }
          if (bbSeat.isActive || bbSeat.isAllIn) {
            final bbPost = otherHalf < bbSeat.stack ? otherHalf : bbSeat.stack;
            bbSeat.stack -= bbPost;
            bbSeat.antePosted = bbPost;
            newState.pot.addToMain(bbPost);
            if (bbSeat.stack == 0 && bbSeat.status != SeatStatus.allIn) {
              bbSeat.status = SeatStatus.allIn;
            }
          }
          sbActsFirst = true;
        default:
          break;
      }
    }

    // ── Bomb Pot processing ──
    if (newState.bombPotEnabled &&
        newState.bombPotAmount != null &&
        newState.bombPotAmount! > 0) {
      for (final seat in newState.seats) {
        if (seat.isActive || seat.isAllIn) {
          final post = newState.bombPotAmount! < seat.stack
              ? newState.bombPotAmount!
              : seat.stack;
          seat.stack -= post;
          newState.pot.addToMain(post);
          if (seat.stack == 0 && seat.status != SeatStatus.allIn) {
            seat.status = SeatStatus.allIn;
          }
        }
      }
      // Bomb pot skips preflop — go directly to flop
      // Reset betting for flop
      newState.betting.currentBet = 0;
      newState.betting.minRaise = bbAmount;
      newState.betting.lastRaise = 0;
      newState.betting.lastAggressor = -1;
      newState.betting.actedThisRound.clear();
      newState.betting.bbOptionPending = false;

      // First to act postflop: first active after dealer
      final first = StreetMachine.firstToAct(
        newState.copyWith(
          street: Street.flop,
          sbSeat: sbIdx,
          bbSeat: bbIdx,
          bbAmount: bbAmount,
        ),
      );
      // Reset seat currentBets for flop betting round
      for (final seat in newState.seats) {
        seat.currentBet = 0;
      }
      final bombResult = newState.copyWith(
        sbSeat: sbIdx,
        bbSeat: bbIdx,
        bbAmount: bbAmount,
        actionOn: first,
        street: Street.flop,
        betLimit: resolvedBetLimit,
      );
      return ReduceResult(state: bombResult, outputs: [
        StateChanged(fromState: state.street.name, toState: Street.flop.name),
      ]);
    }

    // ── Straddle processing ──
    int? straddleSeatIdx;
    if (newState.straddleEnabled && newState.straddleSeat != null) {
      straddleSeatIdx = newState.straddleSeat!;
      final straddleSeat = newState.seats[straddleSeatIdx];
      if (straddleSeat.isActive) {
        final straddleAmt = bbAmount * 2;
        final post =
            straddleAmt < straddleSeat.stack ? straddleAmt : straddleSeat.stack;
        straddleSeat.stack -= post;
        straddleSeat.currentBet = post;
        newState.pot.addToMain(post);
        if (straddleSeat.stack == 0) {
          straddleSeat.status = SeatStatus.allIn;
        }
        // Update betting to straddle amount
        newState.betting.currentBet = post;
        newState.betting.minRaise = post;
      }
    }

    // Find first to act
    final stateForFirstAct = newState.copyWith(
      sbSeat: sbIdx,
      bbSeat: bbIdx,
      bbAmount: bbAmount,
      straddleSeat: straddleSeatIdx,
    );

    int firstAct;
    if (bbActsFirst) {
      firstAct = bbIdx;
      newState.betting.bbOptionPending = true;
    } else if (sbActsFirst) {
      firstAct = sbIdx;
    } else {
      firstAct = StreetMachine.firstToAct(stateForFirstAct);
    }

    final resultState = newState.copyWith(
      sbSeat: sbIdx,
      bbSeat: bbIdx,
      bbAmount: bbAmount,
      actionOn: firstAct,
      betLimit: resolvedBetLimit,
    );
    return ReduceResult(state: resultState, outputs: [
      StateChanged(fromState: state.street.name, toState: Street.preflop.name),
    ]);
  }

  static ReduceResult _dealHoleFull(GameState state, DealHoleCards event) {
    final newState = state.copyWith();
    for (final entry in event.cards.entries) {
      newState.seats[entry.key].holeCards = List.of(entry.value);
    }
    return ReduceResult(state: newState);
  }

  static ReduceResult _dealCommunityFull(GameState state, DealCommunity event) {
    final newState = state.copyWith(
      community: [...state.community, ...event.cards],
    );
    return ReduceResult(state: newState, outputs: [
      BoardUpdated(cardCount: newState.community.length),
    ]);
  }

  static ReduceResult _pineappleDiscardFull(
      GameState state, PineappleDiscard event) {
    final newState = state.copyWith();
    newState.seats[event.seatIndex].holeCards.remove(event.discarded);
    return ReduceResult(state: newState);
  }

  static ReduceResult _playerActionFull(GameState state, PlayerAction event) {
    final newState =
        BettingRules.applyAction(state, event.seatIndex, event.action);

    // Recalculate side pots when any player is all-in
    final hasAllIn = newState.seats.any((s) => s.isAllIn);
    if (hasAllIn) {
      final bets = <int, int>{};
      final folded = <int>{};
      for (final seat in newState.seats) {
        if (seat.currentBet > 0 || seat.isAllIn || seat.isActive) {
          bets[seat.index] = seat.currentBet;
        }
        if (seat.isFolded && seat.currentBet > 0) {
          folded.add(seat.index);
          bets[seat.index] = seat.currentBet;
        }
      }
      final sidePots = Pot.calculateSidePots(bets: bets, folded: folded);
      if (sidePots.length > 1) {
        newState.pot.main = sidePots[0].amount;
        newState.pot.sides = sidePots.sublist(1);
      }
    }

    // Build output events for this action
    final actionType = switch (event.action) {
      Fold() => 'fold',
      Check() => 'check',
      Call() => 'call',
      Bet() => 'bet',
      Raise() => 'raise',
      AllIn() => 'allin',
    };
    final actionAmount = switch (event.action) {
      Call(:final amount) => amount,
      Bet(:final amount) => amount,
      Raise(:final toAmount) => toAmount,
      AllIn(:final amount) => amount,
      _ => null,
    };
    final outputs = <OutputEvent>[
      ActionProcessed(
        seatIndex: event.seatIndex,
        actionType: actionType,
        amount: actionAmount,
      ),
      PotUpdated(
        mainPot: newState.pot.main,
        sidePots: newState.pot.sides.map((s) => s.amount).toList(),
      ),
    ];

    // Check if all but one folded
    final activeCount =
        newState.seats.where((s) => s.isActive || s.isAllIn).length;
    if (activeCount <= 1) {
      return ReduceResult(
        state: newState.copyWith(actionOn: -1),
        outputs: outputs,
      );
    }

    // Check if round is complete
    if (BettingRules.isRoundComplete(newState)) {
      final advanced = _autoAdvanceAndDeal(newState);
      outputs.add(StateChanged(
        fromState: state.street.name,
        toState: advanced.street.name,
      ));
      return ReduceResult(state: advanced, outputs: outputs);
    }

    // Next player to act
    final next = StreetMachine.nextToAct(newState);
    outputs.add(ActionOnChanged(seatIndex: next));
    return ReduceResult(
      state: newState.copyWith(actionOn: next),
      outputs: outputs,
    );
  }

  /// Auto-advance street and deal community cards when betting round completes.
  /// Handles all-in runout by chaining flop→turn→river→showdown.
  static GameState _autoAdvanceAndDeal(GameState state) {
    final nextStreet = StreetMachine.nextStreet(state.street);

    // Showdown or handComplete: no cards to deal, signal completion
    if (nextStreet == Street.showdown || nextStreet == Street.handComplete) {
      return state.copyWith(street: nextStreet, actionOn: -1);
    }

    // Advance street (resets bets, sets firstToAct)
    var advanced = StreetMachine.advanceStreet(state);

    // Deal community cards from deck
    final cardCount = StreetMachine.communityCardsToDeal(nextStreet);
    if (cardCount > 0) {
      final cards = <Card>[];
      for (var i = 0; i < cardCount; i++) {
        cards.add(advanced.deck.draw());
      }
      advanced = advanced.copyWith(
        community: [...advanced.community, ...cards],
      );
    }

    // All-in runout: no active players left, chain to next street
    final activeAfter = advanced.seats.where((s) => s.isActive).length;
    if (activeAfter == 0 && nextStreet != Street.showdown) {
      return _autoAdvanceAndDeal(advanced.copyWith(actionOn: -1));
    }

    return advanced;
  }

  static ReduceResult _streetAdvanceFull(GameState state, StreetAdvance event) {
    // Validate transition: must follow sequential order
    const validNext = {
      Street.idle: {Street.setupHand},
      Street.setupHand: {Street.preflop},
      Street.preflop: {Street.flop},
      Street.flop: {Street.turn},
      Street.turn: {Street.river},
      Street.river: {Street.showdown, Street.runItMultiple},
      Street.runItMultiple: {Street.showdown, Street.handComplete},
      Street.showdown: {Street.handComplete},
    };
    final allowed = validNext[state.street];
    if (allowed != null && !allowed.contains(event.next)) {
      return ReduceResult(state: state); // reject invalid transition
    }

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
    newState.betting.raiseCount = 0;

    // First to act for new street
    final first = StreetMachine.firstToAct(newState);
    final resultState = newState.copyWith(actionOn: first);
    return ReduceResult(state: resultState, outputs: [
      StateChanged(fromState: state.street.name, toState: event.next.name),
    ]);
  }

  static ReduceResult _awardPotFull(GameState state, PotAwarded event) {
    final newState = state.copyWith();
    for (final entry in event.awards.entries) {
      newState.seats[entry.key].stack += entry.value;
    }
    // Clear pot
    newState.pot.main = 0;
    newState.pot.sides = [];
    return ReduceResult(state: newState, outputs: [
      WinnerDetermined(awards: event.awards),
    ]);
  }

  static ReduceResult _endHandFull(GameState state) {
    // Find next dealer: skip sitting-out seats
    final n = state.seats.length;
    int nextDealer = state.dealerSeat;
    for (var i = 1; i <= n; i++) {
      final idx = (state.dealerSeat + i) % n;
      if (state.seats[idx].status != SeatStatus.sittingOut) {
        nextDealer = idx;
        break;
      }
    }

    final resultState = state.copyWith(
      handInProgress: false,
      actionOn: -1,
      dealerSeat: nextDealer,
      handNumber: state.handNumber + 1,
    );
    return ReduceResult(state: resultState, outputs: [
      HandCompleted(handNumber: state.handNumber),
      StateChanged(fromState: state.street.name, toState: Street.idle.name),
    ]);
  }

  static ReduceResult _handleMisDealFull(GameState state) {
    final newState = state.copyWith();
    // Return each seat's currentBet back to their stack, reset status
    for (final seat in newState.seats) {
      seat.stack += seat.currentBet + seat.antePosted;
      seat.currentBet = 0;
      seat.antePosted = 0;
      seat.holeCards = [];
      if (seat.status == SeatStatus.allIn || seat.status == SeatStatus.folded) {
        seat.status = SeatStatus.active;
      }
    }
    // Clear pot
    newState.pot.main = 0;
    newState.pot.sides = [];
    final resultState = newState.copyWith(
      handInProgress: false,
      actionOn: -1,
      street: Street.idle,
      community: [],
    );
    return ReduceResult(state: resultState, outputs: [
      StateChanged(fromState: state.street.name, toState: Street.idle.name),
    ]);
  }

  static ReduceResult _handleBombPotConfigFull(GameState state, BombPotConfig event) {
    if (event.amount <= 0) return ReduceResult(state: state);
    return ReduceResult(state: state.copyWith(
      bombPotEnabled: true,
      bombPotAmount: event.amount,
    ));
  }

  static ReduceResult _handleRunItChoiceFull(GameState state, RunItChoice event) {
    if (event.times != 2 && event.times != 3) return ReduceResult(state: state);
    final resultState = state.copyWith(
      runItTimes: event.times,
      street: Street.runItMultiple,
    );
    return ReduceResult(state: resultState, outputs: [
      StateChanged(fromState: state.street.name, toState: Street.runItMultiple.name),
    ]);
  }

  static ReduceResult _handleManualNextHandFull(GameState state) {
    final newState = state.copyWith(
      handInProgress: false,
      actionOn: -1,
      street: Street.idle,
      community: [],
      bombPotEnabled: false,
    );
    // Clear hole cards for all seats
    for (final seat in newState.seats) {
      seat.holeCards = [];
    }
    return ReduceResult(state: newState, outputs: [
      StateChanged(fromState: state.street.name, toState: Street.idle.name),
    ]);
  }

  static ReduceResult _handleTimeoutFoldFull(GameState state, TimeoutFold event) {
    // Treat timeout as a fold action
    final result = _playerActionFull(state, PlayerAction(event.seatIndex, const Fold()));
    // Replace the ActionProcessed actionType with the timeout context
    final outputs = result.outputs.map((o) {
      if (o is ActionProcessed) {
        return ActionProcessed(
          seatIndex: o.seatIndex,
          actionType: 'fold',
          amount: o.amount,
        );
      }
      return o;
    }).toList();
    return ReduceResult(state: result.state, outputs: outputs);
  }

  static ReduceResult _handleMuckDecisionFull(GameState state, MuckDecision event) {
    if (!event.showCards) {
      final newState = state.copyWith();
      newState.seats[event.seatIndex].holeCards = [];
      return ReduceResult(state: newState);
    }
    return ReduceResult(state: state);
  }
}
