// ScenarioRunner — step-by-step scenario execution.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/command_center/demo/local_dispatcher.dart';
import 'package:ebs_cc/features/command_center/demo/scenario_runner.dart';
import 'package:ebs_cc/features/command_center/demo/scenarios.dart';
import 'package:ebs_cc/features/command_center/providers/demo_provider.dart';
import 'package:ebs_cc/features/command_center/providers/hand_display_provider.dart';
import 'package:ebs_cc/features/command_center/providers/hand_fsm_provider.dart';
import 'package:ebs_cc/features/command_center/providers/seat_provider.dart';
import 'package:ebs_cc/foundation/audio/audio_player_provider.dart';
import 'package:ebs_cc/models/enums/hand_fsm.dart';

ProviderContainer _container() => ProviderContainer(overrides: [
      audioSfxPortProvider.overrideWithValue(SilentAudioSfxPort()),
    ]);

void main() {
  group('ScenarioRunner.step', () {
    test('Quick Hand — step through all events', () {
      final c = _container();
      addTearDown(c.dispose);

      seedDemoPlayers(c);
      final runner = ScenarioRunner(c);
      runner.load(quickHand);

      // Step through all events
      var hasMore = true;
      while (hasMore) {
        hasMore = runner.step();
      }

      // After Quick Hand: hand should be complete
      expect(c.read(handFsmProvider), HandFsm.handComplete);
      expect(c.read(handNumberProvider), 1);
      // Board should have 5 cards (flop 3 + turn 1 + river 1)
      expect(c.read(boardCardsProvider).length, 5);

      runner.dispose();
    });

    test('step returns false when scenario is complete', () {
      final c = _container();
      addTearDown(c.dispose);

      seedDemoPlayers(c);
      final runner = ScenarioRunner(c);
      runner.load(missDeal); // shortest scenario (3 events)

      expect(runner.step(), true);  // event 1
      expect(runner.step(), true);  // event 2
      expect(runner.step(), false); // event 3 (last)

      runner.dispose();
    });
  });

  group('ScenarioRunner.reset', () {
    test('resets state and re-seeds players', () {
      final c = _container();
      addTearDown(c.dispose);

      seedDemoPlayers(c);
      final runner = ScenarioRunner(c);
      runner.load(quickHand);

      // Run a few steps
      runner.step();
      runner.step();
      expect(c.read(handFsmProvider), HandFsm.preFlop);

      // Reset
      runner.reset();
      expect(c.read(handFsmProvider), HandFsm.idle);
      expect(c.read(seatsProvider)[0].player?.name, 'Alice');
      expect(runner.currentStep, 0);

      runner.dispose();
    });
  });

  group('ScenarioRunner.play (auto)', () {
    test('auto-play completes scenario after delays', () async {
      final c = _container();
      addTearDown(c.dispose);

      seedDemoPlayers(c);
      final runner = ScenarioRunner(c);

      // Use missDeal (3 events, shortest)
      runner.load(missDeal);
      runner.play();

      // Wait for all events to fire (3 × 500ms + buffer)
      await Future<void>.delayed(const Duration(milliseconds: 2500));

      expect(c.read(handFsmProvider), HandFsm.handComplete);
      expect(runner.isRunning, false);

      runner.dispose();
    });
  });

  group('DemoProvider log', () {
    test('log entries capped at 50', () {
      final c = _container();
      addTearDown(c.dispose);

      final notifier = c.read(demoProvider.notifier);
      for (var i = 0; i < 60; i++) {
        notifier.log('Test', 'entry $i');
      }

      expect(c.read(demoProvider).eventLog.length, 50);
      // Most recent should be the last logged
      expect(c.read(demoProvider).eventLog.last.message, 'entry 59');
    });
  });
}
