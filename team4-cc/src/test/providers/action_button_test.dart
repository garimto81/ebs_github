// ActionButtonState tests (BS-05-02 — 8 buttons x 9 states matrix).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/command_center/providers/action_button_provider.dart';
import 'package:ebs_cc/features/command_center/providers/hand_fsm_provider.dart';
import 'package:ebs_cc/features/command_center/providers/table_state_provider.dart';
import 'package:ebs_cc/models/enums/hand_fsm.dart';
import 'package:ebs_cc/models/enums/table_fsm.dart';

void main() {
  late ProviderContainer container;

  /// Create a container with table LIVE and given hand state + bet context.
  ProviderContainer _liveContainer({
    HandFsm handState = HandFsm.idle,
    bool hasBet = false,
  }) {
    final c = ProviderContainer();
    c.read(tableStateProvider.notifier).transition(TableFsm.live);
    c.read(handFsmProvider.notifier).forceState(handState);
    c.read(hasBetToMatchProvider.notifier).state = hasBet;
    return c;
  }

  tearDown(() {
    container.dispose();
  });

  group('ActionButton — table not LIVE', () {
    test('all buttons disabled when table is empty', () {
      container = ProviderContainer();
      // Default table state is empty
      final state = container.read(actionButtonProvider);
      for (final action in CcAction.values) {
        expect(state.isEnabled(action), isFalse,
            reason: '$action should be disabled');
      }
    });

    test('all buttons disabled when table is setup', () {
      container = ProviderContainer();
      container.read(tableStateProvider.notifier).transition(TableFsm.setup);
      final state = container.read(actionButtonProvider);
      for (final action in CcAction.values) {
        expect(state.isEnabled(action), isFalse);
      }
    });

    test('all buttons disabled when table is paused', () {
      container = ProviderContainer();
      container.read(tableStateProvider.notifier).transition(TableFsm.paused);
      final state = container.read(actionButtonProvider);
      for (final action in CcAction.values) {
        expect(state.isEnabled(action), isFalse);
      }
    });

    test('all buttons disabled when table is closed', () {
      container = ProviderContainer();
      container.read(tableStateProvider.notifier).transition(TableFsm.closed);
      final state = container.read(actionButtonProvider);
      for (final action in CcAction.values) {
        expect(state.isEnabled(action), isFalse);
      }
    });
  });

  group('ActionButton — IDLE state', () {
    test('only newHand enabled', () {
      container = _liveContainer(handState: HandFsm.idle);
      final state = container.read(actionButtonProvider);

      expect(state.isEnabled(CcAction.newHand), isTrue);
      expect(state.isEnabled(CcAction.deal), isFalse);
      expect(state.isEnabled(CcAction.fold), isFalse);
      expect(state.isEnabled(CcAction.checkCall), isFalse);
      expect(state.isEnabled(CcAction.betRaise), isFalse);
      expect(state.isEnabled(CcAction.allIn), isFalse);
      expect(state.isEnabled(CcAction.undo), isFalse);
      expect(state.isEnabled(CcAction.missDeal), isFalse);
    });
  });

  group('ActionButton — SETUP_HAND state', () {
    test('deal and undo enabled', () {
      container = _liveContainer(handState: HandFsm.setupHand);
      final state = container.read(actionButtonProvider);

      expect(state.isEnabled(CcAction.newHand), isFalse);
      expect(state.isEnabled(CcAction.deal), isTrue);
      expect(state.isEnabled(CcAction.fold), isFalse);
      expect(state.isEnabled(CcAction.checkCall), isFalse);
      expect(state.isEnabled(CcAction.betRaise), isFalse);
      expect(state.isEnabled(CcAction.allIn), isFalse);
      expect(state.isEnabled(CcAction.undo), isTrue);
      expect(state.isEnabled(CcAction.missDeal), isFalse);
    });
  });

  group('ActionButton — PRE_FLOP state', () {
    test('fold, checkCall, betRaise, allIn, undo, missDeal enabled', () {
      container = _liveContainer(handState: HandFsm.preFlop);
      final state = container.read(actionButtonProvider);

      expect(state.isEnabled(CcAction.newHand), isFalse);
      expect(state.isEnabled(CcAction.deal), isFalse);
      expect(state.isEnabled(CcAction.fold), isTrue);
      expect(state.isEnabled(CcAction.checkCall), isTrue);
      expect(state.isEnabled(CcAction.betRaise), isTrue);
      expect(state.isEnabled(CcAction.allIn), isTrue);
      expect(state.isEnabled(CcAction.undo), isTrue);
      expect(state.isEnabled(CcAction.missDeal), isTrue);
    });
  });

  group('ActionButton — FLOP/TURN/RIVER same as PRE_FLOP', () {
    for (final handState in [HandFsm.flop, HandFsm.turn, HandFsm.river]) {
      test('$handState: action buttons enabled', () {
        container = _liveContainer(handState: handState);
        final state = container.read(actionButtonProvider);

        expect(state.isEnabled(CcAction.fold), isTrue);
        expect(state.isEnabled(CcAction.checkCall), isTrue);
        expect(state.isEnabled(CcAction.betRaise), isTrue);
        expect(state.isEnabled(CcAction.allIn), isTrue);
        expect(state.isEnabled(CcAction.undo), isTrue);
        expect(state.isEnabled(CcAction.missDeal), isTrue);
        expect(state.isEnabled(CcAction.newHand), isFalse);
        expect(state.isEnabled(CcAction.deal), isFalse);
      });
    }
  });

  group('ActionButton — SHOWDOWN state', () {
    test('all disabled (engine-driven)', () {
      container = _liveContainer(handState: HandFsm.showdown);
      final state = container.read(actionButtonProvider);

      for (final action in CcAction.values) {
        expect(state.isEnabled(action), isFalse,
            reason: '$action should be disabled in showdown');
      }
    });
  });

  group('ActionButton — HAND_COMPLETE state', () {
    test('only newHand enabled', () {
      container = _liveContainer(handState: HandFsm.handComplete);
      final state = container.read(actionButtonProvider);

      expect(state.isEnabled(CcAction.newHand), isTrue);
      expect(state.isEnabled(CcAction.deal), isFalse);
      expect(state.isEnabled(CcAction.fold), isFalse);
      expect(state.isEnabled(CcAction.checkCall), isFalse);
      expect(state.isEnabled(CcAction.betRaise), isFalse);
      expect(state.isEnabled(CcAction.allIn), isFalse);
      expect(state.isEnabled(CcAction.undo), isFalse);
      expect(state.isEnabled(CcAction.missDeal), isFalse);
    });
  });

  group('ActionButton — RUN_IT_MULTIPLE state', () {
    test('all disabled (engine-driven)', () {
      container = _liveContainer(handState: HandFsm.runItMultiple);
      final state = container.read(actionButtonProvider);

      for (final action in CcAction.values) {
        expect(state.isEnabled(action), isFalse,
            reason: '$action should be disabled in runItMultiple');
      }
    });
  });

  group('ActionButton — dynamic labels', () {
    test('CHECK when no bet to match', () {
      container = _liveContainer(handState: HandFsm.preFlop, hasBet: false);
      final state = container.read(actionButtonProvider);
      expect(state.checkCallLabel, 'CHECK');
      expect(state.betRaiseLabel, 'BET');
    });

    test('CALL when bet to match', () {
      container = _liveContainer(handState: HandFsm.preFlop, hasBet: true);
      final state = container.read(actionButtonProvider);
      expect(state.checkCallLabel, 'CALL');
      expect(state.betRaiseLabel, 'RAISE');
    });
  });
}
