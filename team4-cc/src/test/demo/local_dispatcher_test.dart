// LocalDispatcher — WS 없이 이벤트 주입 검증.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/command_center/demo/local_dispatcher.dart';
import 'package:ebs_cc/features/command_center/providers/hand_display_provider.dart';
import 'package:ebs_cc/features/command_center/providers/hand_fsm_provider.dart';
import 'package:ebs_cc/features/command_center/providers/seat_provider.dart';
import 'package:ebs_cc/foundation/audio/audio_player_provider.dart';
import 'package:ebs_cc/models/enums/hand_fsm.dart';

ProviderContainer _container() => ProviderContainer(overrides: [
      audioSfxPortProvider.overrideWithValue(SilentAudioSfxPort()),
    ]);

void main() {
  group('dispatchLocalEvent', () {
    test('HandStarted advances FSM to preFlop', () {
      final c = _container();
      addTearDown(c.dispose);

      dispatchLocalEvent(c, {
        'type': 'HandStarted',
        'hand_id': 1,
        'hand_number': 10,
        'dealer_seat': 3,
      });

      expect(c.read(handFsmProvider), HandFsm.preFlop);
      expect(c.read(handNumberProvider), 10);
    });

    test('ActionPerformed updates pot', () {
      final c = _container();
      addTearDown(c.dispose);

      dispatchLocalEvent(c, {
        'type': 'HandStarted',
        'hand_id': 1,
        'hand_number': 1,
        'dealer_seat': 1,
      });

      dispatchLocalEvent(c, {
        'type': 'ActionPerformed',
        'seat': 1,
        'action_type': 'bet',
        'amount': 500,
        'pot_after': 500,
      });

      expect(c.read(potTotalProvider), 500);
    });

    test('CardDetected appends to board', () {
      final c = _container();
      addTearDown(c.dispose);

      dispatchLocalEvent(c, {
        'type': 'CardDetected',
        'is_board': true,
        'suit': 'h',
        'rank': 'A',
      });

      expect(c.read(boardCardsProvider), ['Ah']);
    });

    test('HandEnded advances to handComplete', () {
      final c = _container();
      addTearDown(c.dispose);

      dispatchLocalEvent(c, {
        'type': 'HandStarted',
        'hand_id': 1,
        'hand_number': 1,
        'dealer_seat': 1,
      });

      dispatchLocalEvent(c, {'type': 'HandEnded', 'hand_id': 1});

      expect(c.read(handFsmProvider), HandFsm.handComplete);
    });
  });

  group('seedDemoPlayers', () {
    test('seeds 3 players at S1, S4, S7 with dealer at S1', () {
      final c = _container();
      addTearDown(c.dispose);

      seedDemoPlayers(c);

      final seats = c.read(seatsProvider);
      expect(seats[0].player?.name, 'Alice');
      expect(seats[3].player?.name, 'Bob');
      expect(seats[6].player?.name, 'Charlie');
      expect(seats[0].isDealer, true);
    });
  });

  group('resetDemoState', () {
    test('clears all seats and resets FSM', () {
      final c = _container();
      addTearDown(c.dispose);

      seedDemoPlayers(c);
      dispatchLocalEvent(c, {
        'type': 'HandStarted',
        'hand_id': 1,
        'hand_number': 5,
        'dealer_seat': 1,
      });

      resetDemoState(c);

      expect(c.read(handFsmProvider), HandFsm.idle);
      expect(c.read(potTotalProvider), 0);
      expect(c.read(boardCardsProvider), isEmpty);
      expect(c.read(seatsProvider).every((s) => s.player == null), true);
    });
  });
}
