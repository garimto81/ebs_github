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
export 'core/cards/badugi_evaluator.dart';

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
export 'core/rules/bring_in.dart';
export 'core/rules/coalescence.dart';

import 'core/cards/card.dart';
import 'core/state/game_state.dart';
import 'core/state/pot.dart';
import 'core/state/seat.dart';
import 'core/actions/action.dart';
import 'core/actions/event.dart';
import 'core/rules/betting_rules.dart';
import 'core/rules/no_limit.dart';
import 'core/rules/showdown.dart';
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
      final AnteOverride e => _handleAnteOverrideFull(state, e),
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

    // ── Missed Blind detection ──
    // Mark sittingOut seats at blind positions
    for (var i = 0; i < n; i++) {
      final idx = (event.dealerSeat + 1 + i) % n;
      final seat = newState.seats[idx];
      if (seat.status == SeatStatus.sittingOut) {
        // If this sittingOut seat is where SB would be (first after dealer)
        if (i == 0 || (n == 2 && idx == event.dealerSeat)) {
          seat.missedSb = true;
        }
        // If this sittingOut seat is where BB would be (second after dealer)
        if (i == 1 || (n == 2 && idx != event.dealerSeat)) {
          seat.missedBb = true;
        }
      }
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
    final sbBlindAmount = event.blinds[sbIdx] ?? 0;

    // ── Missed Blind posting for returning players ──
    // Active seats with missed blind flags must post before regular action
    for (final seat in newState.seats) {
      if (!seat.isActive) continue;
      if (!seat.missedBb && !seat.missedSb) continue;

      int deadBlind = 0;
      int liveBlind = 0;

      if (seat.missedBb) {
        // Dead blind (SB amount) + live blind (BB amount)
        deadBlind = sbBlindAmount;
        liveBlind = bbAmount;
      } else if (seat.missedSb) {
        // Dead blind (SB amount) only
        deadBlind = sbBlindAmount;
      }

      final totalPost = deadBlind + liveBlind;
      if (totalPost > 0) {
        final post = totalPost < seat.stack ? totalPost : seat.stack;
        seat.stack -= post;
        pot.addToMain(post);
        // Live blind counts toward current bet
        if (liveBlind > 0 && post > deadBlind) {
          seat.currentBet += post - deadBlind;
        }
        if (seat.stack == 0) {
          seat.status = SeatStatus.allIn;
        }
      }

      // Reset flags after posting
      seat.missedSb = false;
      seat.missedBb = false;
    }

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

  /// RunItChoice: state 전환 + (v03, river-trigger 시) board 2 카드 생성.
  ///
  /// v03 (Cycle 6, issue #310) — times=2 + community.length == 5 시:
  ///   - board 2 community = state.community 의 flop 3장 공유 + 새 turn/river 2장
  ///     deal (river 트리거 표준 패턴; spec §3.3)
  ///   - `runItBoard2Cards` 필드에 보존
  ///   - pot/seat 은 건드리지 않음. 실제 award 는 `runItAwards` helper 또는
  ///     명시적 `PotAwarded` event 로 계산/적용 (legacy scenario 호환).
  ///
  /// 그 외 경우 (times=3, variant 미등록, community < 5) — 기존 동작 (state 전환만).
  ///
  /// Spec: docs/2. Development/2.3 Game Engine/Rules/Multi_Hand_v03.md §3
  static ReduceResult _handleRunItChoiceFull(GameState state, RunItChoice event) {
    if (event.times != 2 && event.times != 3) return ReduceResult(state: state);

    final variantFactory = variantRegistry[state.variantName];
    final canSplit = event.times == 2 &&
        variantFactory != null &&
        state.community.length == 5;

    if (!canSplit) {
      // v02 legacy: 단순 state 전환
      final resultState = state.copyWith(
        runItTimes: event.times,
        street: Street.runItMultiple,
      );
      return ReduceResult(state: resultState, outputs: [
        StateChanged(fromState: state.street.name, toState: Street.runItMultiple.name),
      ]);
    }

    // v03 river-trigger: board 2 카드 생성 (pot/seat 은 건드리지 않음)
    final newState = state.copyWith();
    final board2 = <Card>[];
    // flop 3장 공유
    for (var i = 0; i < 3; i++) {
      board2.add(state.community[i]);
    }
    // 새 turn + river deal
    while (board2.length < 5) {
      board2.add(newState.deck.draw());
    }

    final resultState = newState.copyWith(
      runItTimes: event.times,
      runItBoard2Cards: board2,
      street: Street.runItMultiple,
    );
    return ReduceResult(state: resultState, outputs: [
      StateChanged(fromState: state.street.name, toState: Street.runItMultiple.name),
    ]);
  }

  /// Compute split-pot awards for run-it-twice (v03, Cycle 6 issue #310).
  ///
  /// 호출 조건:
  ///   - `state.runItTimes == 2`
  ///   - `state.runItBoard2Cards != null` (RunItChoice river-trigger 후)
  ///   - variantRegistry 에 `state.variantName` 등록
  ///
  /// 동작:
  ///   - totalPot = state.pot.main + sum(state.pot.sides[].amount)
  ///   - board2Pot = totalPot ~/ 2; board1Pot = totalPot - board2Pot  (board1 odd chip 흡수)
  ///   - 각 board 의 winners 산출 (Showdown.evaluate) → awards 합산 반환
  ///
  /// Side-effect 없음 — 반환된 Map 을 사용자가 명시 PotAwarded event 로 적용.
  /// 반환값이 null 이면 호출 조건 미충족 (호출 측에서 fallback 처리).
  ///
  /// Spec: docs/2. Development/2.3 Game Engine/Rules/Multi_Hand_v03.md §3.4
  static Map<int, int>? runItAwards(GameState state) {
    if (state.runItTimes != 2 || state.runItBoard2Cards == null) return null;
    final variantFactory = variantRegistry[state.variantName];
    if (variantFactory == null) return null;
    final variant = variantFactory();

    final totalPot = state.pot.main +
        state.pot.sides.fold<int>(0, (sum, sp) => sum + sp.amount);
    if (totalPot <= 0) return <int, int>{};

    final sidePots = state.pot.sides.isEmpty
        ? <SidePot>[SidePot(state.pot.main, _eligibleSeatIndices(state))]
        : List<SidePot>.of(state.pot.sides);

    final board1Pots = <SidePot>[];
    final board2Pots = <SidePot>[];
    for (final sp in sidePots) {
      final spBoard2 = sp.amount ~/ 2;
      final spBoard1 = sp.amount - spBoard2;
      board1Pots.add(SidePot(spBoard1, Set<int>.of(sp.eligible)));
      board2Pots.add(SidePot(spBoard2, Set<int>.of(sp.eligible)));
    }

    final board1Awards = Showdown.evaluate(
      seats: state.seats,
      community: state.community,
      pots: board1Pots,
      variant: variant,
      dealerSeat: state.dealerSeat,
    );
    final board2Awards = Showdown.evaluate(
      seats: state.seats,
      community: state.runItBoard2Cards!,
      pots: board2Pots,
      variant: variant,
      dealerSeat: state.dealerSeat,
    );

    final merged = <int, int>{};
    for (final e in board1Awards.entries) {
      merged[e.key] = (merged[e.key] ?? 0) + e.value;
    }
    for (final e in board2Awards.entries) {
      merged[e.key] = (merged[e.key] ?? 0) + e.value;
    }
    return merged;
  }

  /// RIT helper: 분할 pot 에 사용할 eligible seat indices (non-folded).
  static Set<int> _eligibleSeatIndices(GameState state) {
    final result = <int>{};
    for (var i = 0; i < state.seats.length; i++) {
      if (!state.seats[i].isFolded && state.seats[i].holeCards.isNotEmpty) {
        result.add(i);
      }
    }
    return result;
  }

  /// ManualNextHand: rotate button + SB/BB to next active seats, increment
  /// handNumber, reset board/hole cards for the next hand.
  ///
  /// Rotation rules (Cycle 5 v02, issue #287):
  ///   - dealerSeat advances to the next non-sittingOut seat (skipping
  ///     sittingOut seats). If no other active seat exists, dealer stays put.
  ///   - 3+ active seats: SB = first active after dealer; BB = second active
  ///     after dealer.
  ///   - heads-up (exactly 2 active seats): dealer = SB; the other = BB
  ///     (standard hold'em rule; preserved by _startHandFull).
  ///   - handNumber += 1.
  ///   - Street to idle, community/hole cards cleared, bombPot flag reset.
  ///
  /// Spec: docs/2. Development/2.3 Game Engine/Rules/Multi_Hand_State.md
  static ReduceResult _handleManualNextHandFull(GameState state) {
    final n = state.seats.length;

    // 1) Rotate dealer: skip sittingOut seats
    int nextDealer = state.dealerSeat;
    for (var i = 1; i <= n; i++) {
      final idx = (state.dealerSeat + i) % n;
      if (state.seats[idx].status != SeatStatus.sittingOut) {
        nextDealer = idx;
        break;
      }
    }

    // 2) Compute SB/BB from new dealer (exclude dealer itself: i < n)
    final activeAfterDealer = <int>[];
    for (var i = 1; i < n; i++) {
      final idx = (nextDealer + i) % n;
      if (state.seats[idx].status != SeatStatus.sittingOut) {
        activeAfterDealer.add(idx);
      }
    }

    int nextSb = state.sbSeat;
    int nextBb = state.bbSeat;
    final dealerActive =
        state.seats[nextDealer].status != SeatStatus.sittingOut;
    final totalActive = (dealerActive ? 1 : 0) + activeAfterDealer.length;

    if (totalActive >= 3 && activeAfterDealer.length >= 2) {
      nextSb = activeAfterDealer[0];
      nextBb = activeAfterDealer[1];
    } else if (totalActive == 2 && activeAfterDealer.isNotEmpty) {
      // Heads-up: dealer = SB, the other active seat = BB
      nextSb = nextDealer;
      nextBb = activeAfterDealer[0];
    }

    // 3) Compute straddle rotation (Cycle 6 v03, issue #310)
    //   - heads-up 진입 (totalActive == 2): straddle 무효화
    //   - 활성 seat ≥ 3 + straddle 활성: next non-sittingOut seat 으로 1칸 회전
    //   - 그 외: 기존 straddleSeat 유지
    bool nextStraddleEnabled = state.straddleEnabled;
    int? nextStraddleSeat = state.straddleSeat;
    if (state.straddleEnabled && state.straddleSeat != null) {
      if (totalActive == 2) {
        nextStraddleEnabled = false;
        // straddleSeat 은 그대로 두지만 enabled=false 로 무효화
      } else if (totalActive >= 3) {
        final s = state.straddleSeat!;
        for (var i = 1; i <= n; i++) {
          final idx = (s + i) % n;
          if (state.seats[idx].status != SeatStatus.sittingOut) {
            nextStraddleSeat = idx;
            break;
          }
        }
      }
    }

    // 4) Reset per-hand state
    final newState = state.copyWith(
      handInProgress: false,
      actionOn: -1,
      street: Street.idle,
      community: [],
      bombPotEnabled: false,
      dealerSeat: nextDealer,
      sbSeat: nextSb,
      bbSeat: nextBb,
      handNumber: state.handNumber + 1,
      straddleEnabled: nextStraddleEnabled,
      straddleSeat: nextStraddleSeat,
    );

    for (final seat in newState.seats) {
      seat.holeCards = [];
      seat.currentBet = 0;
      seat.antePosted = 0;
      seat.isDealer = (seat.index == nextDealer);
      if (seat.status == SeatStatus.folded) {
        seat.status = SeatStatus.active;
      }
    }

    newState.pot.main = 0;
    newState.pot.sides = [];

    return ReduceResult(state: newState, outputs: [
      StateChanged(fromState: state.street.name, toState: Street.idle.name),
    ]);
  }

  /// AnteOverride: 다음 hand 의 ante amount 및 (선택) type 변경.
  /// amount <= 0 은 무시. type 미지정 시 기존 anteType 유지.
  ///
  /// Spec: docs/2. Development/2.3 Game Engine/Rules/Multi_Hand_v03.md §2
  static ReduceResult _handleAnteOverrideFull(GameState state, AnteOverride event) {
    if (event.amount <= 0) return ReduceResult(state: state);
    final newState = state.copyWith(
      anteAmount: event.amount,
      anteType: event.type ?? state.anteType,
    );
    return ReduceResult(state: newState);
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
