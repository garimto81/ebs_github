import 'package:test/test.dart';
import 'package:ebs_game_engine/core/variants/pineapple.dart';

void main() {
  group('Pineapple', () {
    final pine = Pineapple();

    test('name', () => expect(pine.name, 'Pineapple'));
    test('deals 3 hole cards', () => expect(pine.holeCardCount, 3));
    test('community = 5', () => expect(pine.communityCardCount, 5));
    test('not hi-lo', () => expect(pine.isHiLo, false));
    test('requires discard', () => expect(pine.requiresDiscard, true));
    test('discard after preflop', () => expect(pine.discardAfterStreet, 0));
    test('mustUseHole = 0', () => expect(pine.mustUseHole, 0));
    test('standard 52-card deck', () {
      expect(pine.createDeck(seed: 42).remaining, 52);
    });
  });
}
