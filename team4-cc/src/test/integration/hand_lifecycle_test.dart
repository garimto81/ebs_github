// Hand lifecycle integration test — multi-provider coordination.
// NEW HAND -> DEAL -> actions -> SHOWDOWN -> HAND_COMPLETE -> IDLE
//
// Verifies HandFsmNotifier + SeatNotifier + UndoStack consistency.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/command_center/providers/action_button_provider.dart';
import 'package:ebs_cc/features/command_center/providers/hand_fsm_provider.dart';
import 'package:ebs_cc/features/command_center/providers/seat_provider.dart';
import 'package:ebs_cc/features/command_center/providers/table_state_provider.dart';
import 'package:ebs_cc/features/command_center/services/undo_stack.dart';
import 'package:ebs_cc/models/enums/hand_fsm.dart';
import 'package:ebs_cc/models/enums/seat_status.dart';
import 'package:ebs_cc/models/enums/table_fsm.dart';

void main() {
  group('Hand lifecycle integration', () {
    late ProviderContainer container;
    late HandFsmNotifier handFsm;
    late SeatNotifier seats;
    late UndoStack undoStack;

    setUp(() {
      container = ProviderContainer();
      handFsm = container.read(handFsmProvider.notifier);
      seats = container.read(seatsProvider.notifier);
      undoStack = UndoStack();

      // Setup table as LIVE
      container.read(tableStateProvider.notifier).transition(TableFsm.live);
    });

    tearDown(() {
      container.dispose();
    });

    UndoableEvent _undoEvent(String type, {String desc = ''}) => UndoableEvent(
          eventType: type,
          payload: {'action': type},
          timestamp: DateTime.now(),
          description: desc.isEmpty ? type : desc,
        );

    test('full hand lifecycle: NEW HAND -> DEAL -> FLOP -> TURN -> RIVER -> SHOWDOWN -> COMPLETE -> IDLE',
        () {
      // -- SETUP: Seat players and assign dealer --
      seats.seatPlayer(
          1, PlayerInfo(id: 1, name: 'Alice', stack: 10000, countryCode: 'US'));
      seats.seatPlayer(
          2, PlayerInfo(id: 2, name: 'Bob', stack: 8000, countryCode: 'UK'));
      seats.seatPlayer(
          3, PlayerInfo(id: 3, name: 'Charlie', stack: 12000, countryCode: 'KR'));
      seats.setDealer(1);
      seats.setSB(2);
      seats.setBB(3);

      // Verify preconditions
      expect(container.read(activePlayerCountProvider), 3);
      expect(container.read(dealerSeatProvider), 1);
      expect(container.read(handFsmProvider), HandFsm.idle);
      expect(
        handFsm.canStartHand(activePlayers: 3, dealerSet: true),
        isTrue,
      );

      // Action buttons: only NEW HAND enabled
      var buttons = container.read(actionButtonProvider);
      expect(buttons.isEnabled(CcAction.newHand), isTrue);
      expect(buttons.isEnabled(CcAction.deal), isFalse);

      // -- NEW HAND --
      handFsm.startHand();
      expect(container.read(handFsmProvider), HandFsm.setupHand);

      buttons = container.read(actionButtonProvider);
      expect(buttons.isEnabled(CcAction.deal), isTrue);
      expect(buttons.isEnabled(CcAction.newHand), isFalse);

      // -- DEAL (blinds posted, cards dealt) --
      // Simulate blind posting
      seats.setCurrentBet(2, 100); // SB
      seats.setCurrentBet(3, 200); // BB

      handFsm.deal();
      expect(container.read(handFsmProvider), HandFsm.preFlop);

      // Assign holecards
      seats.setHoleCards(1, [
        const HoleCard(suit: 's', rank: 'A'),
        const HoleCard(suit: 'h', rank: 'K'),
      ]);
      seats.setHoleCards(2, [
        const HoleCard(suit: 'd', rank: 'Q'),
        const HoleCard(suit: 'c', rank: 'J'),
      ]);
      seats.setHoleCards(3, [
        const HoleCard(suit: 's', rank: 'T'),
        const HoleCard(suit: 'h', rank: '9'),
      ]);

      // Action buttons: fold, check/call, bet/raise, all-in, undo, missdeal enabled
      buttons = container.read(actionButtonProvider);
      expect(buttons.isEnabled(CcAction.fold), isTrue);
      expect(buttons.isEnabled(CcAction.checkCall), isTrue);
      expect(buttons.isEnabled(CcAction.betRaise), isTrue);
      expect(buttons.isEnabled(CcAction.allIn), isTrue);
      expect(buttons.isEnabled(CcAction.undo), isTrue);

      // -- PRE-FLOP ACTIONS --
      seats.setActionOn(1);
      expect(container.read(actionOnSeatProvider), 1);

      // Player 1 calls
      undoStack.push(_undoEvent('ActionPerformed', desc: 'Alice calls'));
      seats.setCurrentBet(1, 200);
      seats.setActionOn(2);

      // Player 2 calls
      undoStack.push(_undoEvent('ActionPerformed', desc: 'Bob calls'));
      seats.setActionOn(3);

      // Player 3 checks
      undoStack.push(_undoEvent('ActionPerformed', desc: 'Charlie checks'));
      seats.setActionOn(null);

      // -- FLOP --
      seats.clearBets();
      handFsm.advanceStreet();
      expect(container.read(handFsmProvider), HandFsm.flop);

      undoStack.push(_undoEvent('BoardCardDealt', desc: 'Flop dealt'));
      expect(undoStack.length, 4);

      // -- TURN --
      handFsm.advanceStreet();
      expect(container.read(handFsmProvider), HandFsm.turn);

      // -- RIVER --
      handFsm.advanceStreet();
      expect(container.read(handFsmProvider), HandFsm.river);

      // -- SHOWDOWN --
      handFsm.enterShowdown();
      expect(container.read(handFsmProvider), HandFsm.showdown);

      // All action buttons disabled in showdown
      buttons = container.read(actionButtonProvider);
      for (final action in CcAction.values) {
        expect(buttons.isEnabled(action), isFalse,
            reason: '$action should be disabled in showdown');
      }

      // -- HAND COMPLETE --
      handFsm.completeHand();
      expect(container.read(handFsmProvider), HandFsm.handComplete);

      // Clear undo stack on hand complete
      undoStack.clear();
      expect(undoStack.length, 0);

      // Clear cards
      seats.clearAllCards();
      for (final s in container.read(seatsProvider)) {
        expect(s.holeCards, isEmpty);
      }

      // -- RESET TO IDLE --
      buttons = container.read(actionButtonProvider);
      expect(buttons.isEnabled(CcAction.newHand), isTrue);

      handFsm.reset();
      expect(container.read(handFsmProvider), HandFsm.idle);
    });

    test('all-fold shortcut: preFlop -> handComplete', () {
      seats.seatPlayer(
          1, PlayerInfo(id: 1, name: 'Alice', stack: 10000));
      seats.seatPlayer(
          2, PlayerInfo(id: 2, name: 'Bob', stack: 8000));
      seats.setDealer(1);

      handFsm.startHand();
      handFsm.deal();
      expect(container.read(handFsmProvider), HandFsm.preFlop);

      // All fold — skip to handComplete
      seats.setActivity(2, PlayerActivity.folded);
      undoStack.push(_undoEvent('ActionPerformed', desc: 'Bob folds'));

      handFsm.completeHand(); // all-fold shortcut
      expect(container.read(handFsmProvider), HandFsm.handComplete);

      undoStack.clear();
    });

    test('undo during hand: push and pop actions', () {
      seats.seatPlayer(
          1, PlayerInfo(id: 1, name: 'Alice', stack: 10000));
      seats.seatPlayer(
          2, PlayerInfo(id: 2, name: 'Bob', stack: 8000));
      seats.setDealer(1);

      handFsm.startHand();
      handFsm.deal();

      // Push some actions
      undoStack.push(_undoEvent('ActionPerformed', desc: 'Alice bets 500'));
      undoStack.push(_undoEvent('ActionPerformed', desc: 'Bob calls'));
      expect(undoStack.length, 2);

      // Undo last action
      final undone = undoStack.pop();
      expect(undone!.description, 'Bob calls');
      expect(undoStack.length, 1);

      // Undo first action
      final undone2 = undoStack.pop();
      expect(undone2!.description, 'Alice bets 500');
      expect(undoStack.length, 0);
    });

    test('run-it-multiple path: river -> runItMultiple -> handComplete', () {
      seats.seatPlayer(1, PlayerInfo(id: 1, name: 'Alice', stack: 10000));
      seats.seatPlayer(2, PlayerInfo(id: 2, name: 'Bob', stack: 8000));
      seats.setDealer(1);

      handFsm.startHand();
      handFsm.deal();
      handFsm.advanceStreet(); // flop
      handFsm.advanceStreet(); // turn
      handFsm.advanceStreet(); // river

      // Both players all-in -> run it multiple
      seats.setActivity(1, PlayerActivity.allIn);
      seats.setActivity(2, PlayerActivity.allIn);

      handFsm.runItMultiple();
      expect(container.read(handFsmProvider), HandFsm.runItMultiple);

      // All buttons disabled
      final buttons = container.read(actionButtonProvider);
      for (final action in CcAction.values) {
        expect(buttons.isEnabled(action), isFalse);
      }

      handFsm.completeHand();
      expect(container.read(handFsmProvider), HandFsm.handComplete);
    });

    test('state consistency: seat changes reflect in derived providers', () {
      // Start with no players
      expect(container.read(activePlayerCountProvider), 0);
      expect(container.read(dealerSeatProvider), isNull);
      expect(container.read(actionOnSeatProvider), isNull);

      // Add players
      seats.seatPlayer(1, PlayerInfo(id: 1, name: 'Alice', stack: 10000));
      seats.seatPlayer(5, PlayerInfo(id: 5, name: 'Eve', stack: 7000));
      expect(container.read(activePlayerCountProvider), 2);

      // Set dealer
      seats.setDealer(1);
      expect(container.read(dealerSeatProvider), 1);

      // Sit out one player
      seats.toggleSitOut(5);
      expect(container.read(activePlayerCountProvider), 1);

      // Sit back in
      seats.toggleSitOut(5);
      expect(container.read(activePlayerCountProvider), 2);

      // Set action on
      seats.setActionOn(5);
      expect(container.read(actionOnSeatProvider), 5);

      // Clear action
      seats.setActionOn(null);
      expect(container.read(actionOnSeatProvider), isNull);
    });
  });
}
