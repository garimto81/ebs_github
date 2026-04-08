import 'package:test/test.dart';
import 'package:ebs_game_engine/core/cards/card.dart';
import 'package:ebs_game_engine/core/cards/hand_evaluator.dart';
import 'package:ebs_game_engine/core/variants/nlh.dart';

void main() {
  group('NLH Variant', () {
    final nlh = Nlh();

    test('name', () => expect(nlh.name, "NL Hold'em"));
    test('hole cards = 2', () => expect(nlh.holeCardCount, 2));
    test('community = 5', () => expect(nlh.communityCardCount, 5));
    test('not hi-lo', () => expect(nlh.isHiLo, false));
    test('52-card deck', () => expect(nlh.createDeck(seed: 42).remaining, 52));
    test('mustUseHole = 0', () => expect(nlh.mustUseHole, 0));
    test('no preflop community', () => expect(nlh.preflopCommunityCount, 0));
    test('no discard', () => expect(nlh.requiresDiscard, false));

    test('evaluateHi returns correct hand', () {
      final hole = [Card.parse('As'), Card.parse('Ks')];
      final community = [
        Card.parse('Qs'),
        Card.parse('Js'),
        Card.parse('Ts'),
        Card.parse('3h'),
        Card.parse('2d'),
      ];
      final rank = nlh.evaluateHi(hole, community);
      expect(rank.category, HandCategory.royalFlush);
    });

    test('evaluateLo returns null (not hi-lo)', () {
      final hole = [Card.parse('As'), Card.parse('2h')];
      final community = [
        Card.parse('3d'),
        Card.parse('4c'),
        Card.parse('5s'),
        Card.parse('Kh'),
        Card.parse('Qd'),
      ];
      expect(nlh.evaluateLo(hole, community), isNull);
    });

    test('standard category order', () {
      expect(nlh.categoryOrder, HandCategory.standardOrder);
    });
  });
}
