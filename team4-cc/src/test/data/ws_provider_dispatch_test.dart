// WebSocket_Events §3.3 consumer contract tests — publisher-emitted event
// names (HandStarted / ActionPerformed / HandEnded / CardDetected) mapped
// to CC Riverpod providers.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/data/remote/ws_provider.dart';
import 'package:ebs_cc/features/command_center/providers/action_button_provider.dart';
import 'package:ebs_cc/features/command_center/providers/hand_display_provider.dart';
import 'package:ebs_cc/features/command_center/providers/hand_fsm_provider.dart';
import 'package:ebs_cc/features/command_center/providers/undo_provider.dart';
import 'package:ebs_cc/features/command_center/services/undo_stack.dart';
import 'package:ebs_cc/models/enums/hand_fsm.dart';

void main() {
  late ProviderContainer container;

  ProviderContainer _freshContainer() => ProviderContainer();

  tearDown(() => container.dispose());

  group('WS dispatch — §3.3.1 HandStarted', () {
    test('advances HandFSM to PRE_FLOP + resets pot/board/bet context', () {
      container = _freshContainer();

      // Seed some pre-existing state to ensure reset happens.
      container.read(handFsmProvider.notifier).forceState(HandFsm.handComplete);
      container.read(potTotalProvider.notifier).state = 9999;
      container.read(boardCardsProvider.notifier).state = ['As', 'Kd'];
      container.read(hasBetToMatchProvider.notifier).state = true;

      dispatchIncomingEventForTest(
        container,
        <String, dynamic>{
          'type': 'HandStarted',
          'hand_id': 42,
          'hand_number': 15,
          'dealer_seat': 3,
        },
      );

      expect(container.read(handFsmProvider), HandFsm.preFlop);
      expect(container.read(handNumberProvider), 15);
      expect(container.read(potTotalProvider), 0);
      expect(container.read(boardCardsProvider), isEmpty);
      expect(container.read(hasBetToMatchProvider), false);
    });
  });

  group('WS dispatch — §3.3.1 ActionPerformed', () {
    test('raise/bet/allin sets hasBetToMatch=true and updates pot', () {
      for (final actionType in ['raise', 'bet', 'allin']) {
        final c = _freshContainer();
        c.read(hasBetToMatchProvider.notifier).state = false;

        dispatchIncomingEventForTest(
          c,
          <String, dynamic>{
            'type': 'ActionPerformed',
            'hand_id': 42,
            'seat': 5,
            'action_type': actionType,
            'amount': 500,
            'pot_after': 1200,
          },
        );

        expect(c.read(potTotalProvider), 1200,
            reason: '$actionType should update pot');
        expect(c.read(hasBetToMatchProvider), true,
            reason: '$actionType should set hasBetToMatch');
        c.dispose();
      }
      container = _freshContainer();
    });

    test('check/call/fold does NOT set hasBetToMatch, still updates pot', () {
      container = _freshContainer();
      container.read(hasBetToMatchProvider.notifier).state = false;

      dispatchIncomingEventForTest(
        container,
        <String, dynamic>{
          'type': 'ActionPerformed',
          'action_type': 'call',
          'pot_after': 800,
        },
      );

      expect(container.read(potTotalProvider), 800);
      expect(container.read(hasBetToMatchProvider), false);
    });
  });

  group('WS dispatch — §3.3.1 HandEnded', () {
    test('advances to HAND_COMPLETE + clears undo stack', () {
      container = _freshContainer();
      container.read(handFsmProvider.notifier).forceState(HandFsm.river);
      container.read(hasBetToMatchProvider.notifier).state = true;

      // Seed one undo entry to verify clearOnHandComplete fires.
      container.read(undoStackProvider.notifier).push(
            UndoableEvent(
              eventType: 'ActionPerformed',
              payload: const {'seat': 0, 'action_type': 'fold'},
              timestamp: DateTime.now(),
              description: 'fold @ seat 0',
            ),
          );
      expect(container.read(undoStackProvider), isNotEmpty);

      dispatchIncomingEventForTest(
        container,
        <String, dynamic>{'type': 'HandEnded', 'hand_id': 42},
      );

      expect(container.read(handFsmProvider), HandFsm.handComplete);
      expect(container.read(hasBetToMatchProvider), false);
      expect(container.read(undoStackProvider), isEmpty);
    });
  });

  group('WS dispatch — §3.3.4 CardDetected (board only)', () {
    test('is_board=true appends to boardCardsProvider', () {
      container = _freshContainer();
      container.read(boardCardsProvider.notifier).state = ['As'];

      dispatchIncomingEventForTest(
        container,
        <String, dynamic>{
          'type': 'CardDetected',
          'is_board': true,
          'suit': 'h',
          'rank': 'K',
        },
      );

      expect(container.read(boardCardsProvider), ['As', 'Kh']);
    });

    test('is_board=false (hole card) is ignored by CC', () {
      container = _freshContainer();
      container.read(boardCardsProvider.notifier).state = const [];

      dispatchIncomingEventForTest(
        container,
        <String, dynamic>{
          'type': 'CardDetected',
          'is_board': false,
          'suit': 'h',
          'rank': 'A',
        },
      );

      expect(container.read(boardCardsProvider), isEmpty);
    });
  });

  group('WS dispatch — forward compatibility (§3.3 version drift)', () {
    test('unknown event types are ignored without throwing', () {
      container = _freshContainer();

      expect(
        () => dispatchIncomingEventForTest(
          container,
          <String, dynamic>{'type': 'SomeFutureEvent', 'foo': 'bar'},
        ),
        returnsNormally,
      );
    });
  });
}
