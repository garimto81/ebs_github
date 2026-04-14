// HandFsmNotifier unit tests (BS-05-01, BS-06-01 — 9-state lifecycle).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/command_center/providers/hand_fsm_provider.dart';
import 'package:ebs_cc/models/enums/hand_fsm.dart';

void main() {
  late ProviderContainer container;
  late HandFsmNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(handFsmProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  group('HandFsmNotifier — state transitions', () {
    test('initial state is idle', () {
      expect(container.read(handFsmProvider), HandFsm.idle);
    });

    test('startHand: idle -> setupHand', () {
      notifier.startHand();
      expect(container.read(handFsmProvider), HandFsm.setupHand);
    });

    test('deal: setupHand -> preFlop', () {
      notifier.startHand();
      notifier.deal();
      expect(container.read(handFsmProvider), HandFsm.preFlop);
    });

    test('advanceStreet: preFlop -> flop -> turn -> river', () {
      notifier.startHand();
      notifier.deal();
      expect(container.read(handFsmProvider), HandFsm.preFlop);

      notifier.advanceStreet();
      expect(container.read(handFsmProvider), HandFsm.flop);

      notifier.advanceStreet();
      expect(container.read(handFsmProvider), HandFsm.turn);

      notifier.advanceStreet();
      expect(container.read(handFsmProvider), HandFsm.river);
    });

    test('enterShowdown: river -> showdown', () {
      notifier.startHand();
      notifier.deal();
      notifier.advanceStreet(); // flop
      notifier.advanceStreet(); // turn
      notifier.advanceStreet(); // river
      notifier.enterShowdown();
      expect(container.read(handFsmProvider), HandFsm.showdown);
    });

    test('completeHand: showdown -> handComplete', () {
      notifier.startHand();
      notifier.deal();
      notifier.advanceStreet(); // flop
      notifier.advanceStreet(); // turn
      notifier.advanceStreet(); // river
      notifier.enterShowdown();
      notifier.completeHand();
      expect(container.read(handFsmProvider), HandFsm.handComplete);
    });

    test('reset: handComplete -> idle', () {
      notifier.startHand();
      notifier.deal();
      notifier.advanceStreet(); // flop
      notifier.advanceStreet(); // turn
      notifier.advanceStreet(); // river
      notifier.enterShowdown();
      notifier.completeHand();
      notifier.reset();
      expect(container.read(handFsmProvider), HandFsm.idle);
    });

    test('runItMultiple: river -> runItMultiple', () {
      notifier.startHand();
      notifier.deal();
      notifier.advanceStreet(); // flop
      notifier.advanceStreet(); // turn
      notifier.advanceStreet(); // river
      notifier.runItMultiple();
      expect(container.read(handFsmProvider), HandFsm.runItMultiple);
    });

    test('completeHand from runItMultiple -> handComplete', () {
      notifier.startHand();
      notifier.deal();
      notifier.advanceStreet(); // flop
      notifier.advanceStreet(); // turn
      notifier.advanceStreet(); // river
      notifier.runItMultiple();
      notifier.completeHand();
      expect(container.read(handFsmProvider), HandFsm.handComplete);
    });

    test('all-fold shortcut: any street -> handComplete', () {
      // From preFlop
      notifier.startHand();
      notifier.deal();
      expect(notifier.canCompleteHand, isTrue);
      notifier.completeHand();
      expect(container.read(handFsmProvider), HandFsm.handComplete);
    });

    test('all-fold from flop', () {
      notifier.startHand();
      notifier.deal();
      notifier.advanceStreet(); // flop
      notifier.completeHand();
      expect(container.read(handFsmProvider), HandFsm.handComplete);
    });

    test('all-fold from turn', () {
      notifier.startHand();
      notifier.deal();
      notifier.advanceStreet(); // flop
      notifier.advanceStreet(); // turn
      notifier.completeHand();
      expect(container.read(handFsmProvider), HandFsm.handComplete);
    });

    test('startHand from handComplete (loop)', () {
      notifier.startHand();
      notifier.deal();
      notifier.advanceStreet();
      notifier.advanceStreet();
      notifier.advanceStreet();
      notifier.enterShowdown();
      notifier.completeHand();
      // Don't need reset — startHand accepts handComplete too
      notifier.startHand();
      expect(container.read(handFsmProvider), HandFsm.setupHand);
    });
  });

  group('HandFsmNotifier — guards', () {
    test('canStartHand requires 2+ active players and dealer set', () {
      expect(
        notifier.canStartHand(activePlayers: 2, dealerSet: true),
        isTrue,
      );
      expect(
        notifier.canStartHand(activePlayers: 1, dealerSet: true),
        isFalse,
      );
      expect(
        notifier.canStartHand(activePlayers: 2, dealerSet: false),
        isFalse,
      );
      expect(
        notifier.canStartHand(activePlayers: 0, dealerSet: true),
        isFalse,
      );
    });

    test('canStartHand false when not idle or handComplete', () {
      notifier.startHand();
      expect(
        notifier.canStartHand(activePlayers: 2, dealerSet: true),
        isFalse,
      );
    });

    test('canDeal requires setupHand state', () {
      expect(notifier.canDeal, isFalse); // idle
      notifier.startHand();
      expect(notifier.canDeal, isTrue); // setupHand
      notifier.deal();
      expect(notifier.canDeal, isFalse); // preFlop
    });

    test('canAdvanceStreet valid during preFlop-turn, invalid at river', () {
      notifier.startHand();
      notifier.deal();
      expect(notifier.canAdvanceStreet, isTrue); // preFlop
      notifier.advanceStreet();
      expect(notifier.canAdvanceStreet, isTrue); // flop
      notifier.advanceStreet();
      expect(notifier.canAdvanceStreet, isTrue); // turn
      notifier.advanceStreet();
      expect(notifier.canAdvanceStreet, isFalse); // river — last street
    });

    test('canEnterShowdown requires river', () {
      expect(notifier.canEnterShowdown, isFalse); // idle
      notifier.startHand();
      expect(notifier.canEnterShowdown, isFalse); // setupHand
      notifier.deal();
      expect(notifier.canEnterShowdown, isFalse); // preFlop

      notifier.advanceStreet();
      notifier.advanceStreet();
      notifier.advanceStreet();
      expect(notifier.canEnterShowdown, isTrue); // river
    });

    test('canRunItMultiple requires river', () {
      expect(notifier.canRunItMultiple, isFalse);
      notifier.startHand();
      notifier.deal();
      notifier.advanceStreet();
      notifier.advanceStreet();
      notifier.advanceStreet();
      expect(notifier.canRunItMultiple, isTrue);
    });

    test('canCompleteHand from showdown or runItMultiple or any street', () {
      notifier.startHand();
      notifier.deal();
      expect(notifier.canCompleteHand, isTrue); // preFlop = street

      notifier.advanceStreet();
      notifier.advanceStreet();
      notifier.advanceStreet();
      notifier.enterShowdown();
      expect(notifier.canCompleteHand, isTrue); // showdown
    });

    test('canCompleteHand false from idle/setupHand', () {
      expect(notifier.canCompleteHand, isFalse); // idle
      notifier.startHand();
      expect(notifier.canCompleteHand, isFalse); // setupHand
    });
  });

  group('HandFsmNotifier — forceState', () {
    test('forceState sets any state unconditionally', () {
      notifier.forceState(HandFsm.river);
      expect(container.read(handFsmProvider), HandFsm.river);

      notifier.forceState(HandFsm.idle);
      expect(container.read(handFsmProvider), HandFsm.idle);
    });
  });
}
