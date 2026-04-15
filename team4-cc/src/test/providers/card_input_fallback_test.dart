// CardInputNotifier — fallback / WRONG_CARD revert behavior
// (Manual_Card_Input.md §6.5).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebs_cc/features/command_center/providers/card_input_provider.dart';
import 'package:ebs_cc/models/enums/card.dart';

void main() {
  group('CardInputNotifier.requestManualForSlot', () {
    test('skips 5s timer and forces FALLBACK immediately', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      c.read(cardInputProvider.notifier).enterCardInput(3);
      c.read(cardInputProvider.notifier).requestManualForSlot(0);

      final state = c.read(cardInputProvider);
      expect(state.slots[0].status, CardSlotStatus.fallback);
    });

    test('cancels existing DETECTING timer when forced', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      c.read(cardInputProvider.notifier).enterCardInput(3);
      c.read(cardInputProvider.notifier).startDetecting(0);
      expect(c.read(cardInputProvider).slots[0].status,
          CardSlotStatus.detecting);

      c.read(cardInputProvider.notifier).requestManualForSlot(0);
      expect(c.read(cardInputProvider).slots[0].status,
          CardSlotStatus.fallback);
    });
  });

  group('CardInputNotifier.cardDetected — WRONG_CARD 1s revert', () {
    test('duplicate card -> WRONG_CARD then auto-revert after ~1s',
        () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      // Seat 1: deal A♠ first.
      c.read(cardInputProvider.notifier).enterCardInput(1);
      c.read(cardInputProvider.notifier)
          .cardDetected(0, Suit.spade, Rank.ace);

      // Seat 2: try to deal the same card -> WRONG_CARD.
      c.read(cardInputProvider.notifier).enterCardInput(2);
      c.read(cardInputProvider.notifier).startDetecting(0);
      c.read(cardInputProvider.notifier)
          .cardDetected(0, Suit.spade, Rank.ace);

      expect(c.read(cardInputProvider).slots[0].status,
          CardSlotStatus.wrongCard);

      // After ~1s, slot reverts to its prior status (DETECTING in this case).
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      final s = c.read(cardInputProvider).slots[0].status;
      expect(s == CardSlotStatus.detecting || s == CardSlotStatus.empty,
          true,
          reason: 'WRONG_CARD should auto-revert; got $s');
    });
  });
}
