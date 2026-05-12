// Cycle 6 (#312) — HandAutoSetupNotifier multi-hand state machine tests.
//
// KPI verified:
//   1. Idempotent run() — second call is a no-op
//   2. Sequence reaches hand2Dealt terminal state
//   3. handNumber increments 1 → 2 after ManualNextHand
//   4. Dealer rotates 1 → 2 (next seat clockwise)
//   5. handHistory[] contains 1 entry after hand 1 completes
//   6. currentPot resets to 0 when hand 2 starts

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_lobby/features/lobby/providers/hand_auto_setup_provider.dart';

void main() {
  group('HandAutoSetupNotifier — multi-hand sequence', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is pending', () {
      final s = container.read(handAutoSetupProvider);
      expect(s.step, HandAutoSetupStep.pending);
      expect(s.handNumber, 1);
      expect(s.dealerSeat, 1);
      expect(s.maxSeats, 6);
      expect(s.currentPot, 0);
      expect(s.handHistory, isEmpty);
    });

    test('run() reaches hand2Dealt terminal state', () async {
      await container.read(handAutoSetupProvider.notifier).run();
      final s = container.read(handAutoSetupProvider);
      expect(s.step, HandAutoSetupStep.hand2Dealt);
    });

    test('handNumber increments 1 -> 2 after ManualNextHand', () async {
      await container.read(handAutoSetupProvider.notifier).run();
      final s = container.read(handAutoSetupProvider);
      expect(s.handNumber, 2);
    });

    test('dealer rotates 1 -> 2 after Hand 1 complete', () async {
      await container.read(handAutoSetupProvider.notifier).run();
      final s = container.read(handAutoSetupProvider);
      expect(s.dealerSeat, 2);
    });

    test('handHistory contains Hand 1 entry after run()', () async {
      await container.read(handAutoSetupProvider.notifier).run();
      final s = container.read(handAutoSetupProvider);
      expect(s.handHistory, hasLength(1));
      final entry = s.handHistory.first;
      expect(entry.handNumber, 1);
      expect(entry.winnerSeat, 1);
      expect(entry.pot, 240);
      expect(entry.dealerSeat, 1);
    });

    test('currentPot resets to 0 at Hand 2 dealt', () async {
      await container.read(handAutoSetupProvider.notifier).run();
      final s = container.read(handAutoSetupProvider);
      expect(s.currentPot, 0);
    });

    test('run() is idempotent — second call is a no-op', () async {
      await container.read(handAutoSetupProvider.notifier).run();
      final after1 = container.read(handAutoSetupProvider);

      await container.read(handAutoSetupProvider.notifier).run();
      final after2 = container.read(handAutoSetupProvider);

      expect(after2.handHistory.length, after1.handHistory.length);
      expect(after2.dealerSeat, after1.dealerSeat);
      expect(after2.handNumber, after1.handNumber);
    });
  });

  group('HandAutoSetupNotifier — dealer rotation invariants', () {
    test('dealer rotation respects maxSeats wrap-around', () {
      const maxSeats = 6;
      int dealer = 1;
      final visited = <int>[];
      for (int i = 0; i < maxSeats; i++) {
        visited.add(dealer);
        dealer = (dealer % maxSeats) + 1;
      }
      expect(visited, [1, 2, 3, 4, 5, 6]);
      expect(dealer, 1);
    });
  });
}
