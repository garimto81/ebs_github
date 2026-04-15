// WebSocket_Events §3.3 consumer contract tests — publisher-emitted event
// names (HandStarted / ActionPerformed / HandEnded / CardDetected) mapped
// to CC Riverpod providers.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/data/remote/ws_provider.dart';
import 'package:ebs_cc/foundation/audio/audio_player_provider.dart';
import 'package:ebs_cc/rfid/providers/rfid_reader_provider.dart';
import 'package:ebs_cc/features/command_center/providers/action_button_provider.dart';
import 'package:ebs_cc/features/command_center/providers/hand_display_provider.dart';
import 'package:ebs_cc/features/command_center/providers/hand_fsm_provider.dart';
import 'package:ebs_cc/features/command_center/providers/undo_provider.dart';
import 'package:ebs_cc/features/command_center/services/undo_stack.dart';
import 'package:ebs_cc/models/enums/hand_fsm.dart';

void main() {
  // Audio SFX dispatch uses platform channels; binding must exist.
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  ProviderContainer _freshContainer() => ProviderContainer(overrides: [
        audioSfxPortProvider.overrideWithValue(SilentAudioSfxPort()),
      ]);

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

  group('WS dispatch — §3.3.4 CardDetected derives street', () {
    test('3rd board card advances HandFSM to FLOP + resets hasBet', () {
      container = _freshContainer();
      container.read(boardCardsProvider.notifier).state = const ['As', 'Kh'];
      container.read(handFsmProvider.notifier).forceState(HandFsm.preFlop);
      container.read(hasBetToMatchProvider.notifier).state = true;

      dispatchIncomingEventForTest(container, <String, dynamic>{
        'type': 'CardDetected',
        'is_board': true,
        'suit': 'd',
        'rank': 'Q',
      });

      expect(container.read(boardCardsProvider), ['As', 'Kh', 'Qd']);
      expect(container.read(handFsmProvider), HandFsm.flop);
      expect(container.read(hasBetToMatchProvider), false);
    });

    test('4th board card advances to TURN', () {
      container = _freshContainer();
      container.read(boardCardsProvider.notifier).state =
          const ['As', 'Kh', 'Qd'];
      container.read(handFsmProvider.notifier).forceState(HandFsm.flop);

      dispatchIncomingEventForTest(container, <String, dynamic>{
        'type': 'CardDetected',
        'is_board': true,
        'suit': 's',
        'rank': 'J',
      });

      expect(container.read(boardCardsProvider).length, 4);
      expect(container.read(handFsmProvider), HandFsm.turn);
    });

    test('5th board card advances to RIVER', () {
      container = _freshContainer();
      container.read(boardCardsProvider.notifier).state =
          const ['As', 'Kh', 'Qd', 'Js'];
      container.read(handFsmProvider.notifier).forceState(HandFsm.turn);

      dispatchIncomingEventForTest(container, <String, dynamic>{
        'type': 'CardDetected',
        'is_board': true,
        'suit': 'c',
        'rank': 'T',
      });

      expect(container.read(boardCardsProvider).length, 5);
      expect(container.read(handFsmProvider), HandFsm.river);
    });
  });

  group('WS dispatch — §3.3.4 CardDetected (board/hole branch)', () {
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

  group('WS dispatch — RfidStatusChanged (Manual_Fallback §5.5/§5.6)', () {
    final cases = <String, ({bool? isError, String? messageContains})>{
      'connected': (isError: null, messageContains: null),
      'connecting': (isError: false, messageContains: '연결 중'),
      'reconnecting': (isError: false, messageContains: '재연결 중'),
      'connectionFailed': (isError: true, messageContains: '연결 실패'),
      'disconnected': (isError: true, messageContains: '장애'),
    };
    cases.forEach((status, expected) {
      test('$status -> ${expected.isError == null ? 'no banner' : expected.messageContains}', () {
        container = _freshContainer();
        dispatchIncomingEventForTest(container, <String, dynamic>{
          'type': 'RfidStatusChanged',
          'status': status,
        });
        final n = container.read(rfidNotificationProvider);
        if (expected.isError == null) {
          expect(n, isNull);
        } else {
          expect(n, isNotNull);
          expect(n!.isError, expected.isError);
          expect(n.message, contains(expected.messageContains!));
        }
      });
    });
  });

  group('WS dispatch — CCR-015 skin_updated', () {
    test('valid payload forwards to SkinConsumer (no throw)', () {
      container = _freshContainer();
      expect(
        () => dispatchIncomingEventForTest(container, <String, dynamic>{
          'type': 'skin_updated',
          'skin_id': 'wsop-2026',
        }),
        returnsNormally,
      );
    });

    test('missing skin_id is tolerated (SkinConsumer logs warning)', () {
      container = _freshContainer();
      expect(
        () => dispatchIncomingEventForTest(container, <String, dynamic>{
          'type': 'skin_updated',
        }),
        returnsNormally,
      );
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

