import 'package:test/test.dart';
import 'package:ebs_game_engine/core/cards/card.dart';
import 'package:ebs_game_engine/core/cards/hand_evaluator.dart';
import 'package:ebs_game_engine/core/variants/omaha.dart';
import 'package:ebs_game_engine/core/variants/five_card_omaha.dart';
import 'package:ebs_game_engine/core/variants/six_card_omaha.dart';
import 'package:ebs_game_engine/core/variants/courchevel.dart';

List<Card> p(String s) => s.split(' ').map(Card.parse).toList();

void main() {
  group('Omaha', () {
    final omaha = Omaha();

    test('4 hole cards, mustUseHole=2', () {
      expect(omaha.holeCardCount, 4);
      expect(omaha.mustUseHole, 2);
    });

    test('board flush with only 1 hole heart is NOT flush', () {
      final r = omaha.evaluateHi(p('Ah 9d Kc Qs'), p('Jh Th 8h 2h 3d'));
      expect(r.category, isNot(HandCategory.flush));
      expect(r.category, isNot(HandCategory.straightFlush));
    });

    test('valid flush with 2 hole hearts', () {
      final r = omaha.evaluateHi(p('Ah 9h Kc Qs'), p('Jh Th 8h 2d 3d'));
      expect(r.category, HandCategory.flush);
    });
  });

  group('Five-Card Omaha', () {
    final fco = FiveCardOmaha();
    test('5 hole cards, mustUseHole=2', () {
      expect(fco.holeCardCount, 5);
      expect(fco.mustUseHole, 2);
    });
    test('not hi-lo by default', () => expect(fco.isHiLo, false));
    test('hi-lo variant', () {
      expect(FiveCardOmaha(hiLo: true).isHiLo, true);
    });
  });

  group('Six-Card Omaha', () {
    final sco = SixCardOmaha();
    test('6 hole cards', () => expect(sco.holeCardCount, 6));
    test('mustUseHole=2', () => expect(sco.mustUseHole, 2));
  });

  group('Courchevel', () {
    final cour = Courchevel();
    test('5 hole cards', () => expect(cour.holeCardCount, 5));
    test('1 preflop community', () => expect(cour.preflopCommunityCount, 1));
    test('mustUseHole=2', () => expect(cour.mustUseHole, 2));
    test('hi-lo variant', () {
      expect(Courchevel(hiLo: true).isHiLo, true);
    });
  });
}
