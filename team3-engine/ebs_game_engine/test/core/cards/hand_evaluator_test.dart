import 'package:test/test.dart';
import 'package:ebs_game_engine/core/cards/card.dart';
import 'package:ebs_game_engine/core/cards/hand_evaluator.dart';

List<Card> p(String s) => s.split(' ').map(Card.parse).toList();

void main() {
  group('HandEvaluator - category detection', () {
    test('royal flush', () {
      final r = HandEvaluator.bestHand(p('As Ks Qs Js Ts 3h 2d'));
      expect(r.category, HandCategory.royalFlush);
    });

    test('straight flush', () {
      final r = HandEvaluator.bestHand(p('9h 8h 7h 6h 5h 2d 3c'));
      expect(r.category, HandCategory.straightFlush);
    });

    test('four of a kind', () {
      final r = HandEvaluator.bestHand(p('Ks Kh Kd Kc As 3h 2d'));
      expect(r.category, HandCategory.fourOfAKind);
    });

    test('full house', () {
      final r = HandEvaluator.bestHand(p('As Ah Ad Ks Kh 3d 2c'));
      expect(r.category, HandCategory.fullHouse);
    });

    test('flush', () {
      final r = HandEvaluator.bestHand(p('As Js 8s 4s 2s Kh Qd'));
      expect(r.category, HandCategory.flush);
    });

    test('straight', () {
      final r = HandEvaluator.bestHand(p('Ts 9h 8d 7c 6s 2h 3d'));
      expect(r.category, HandCategory.straight);
    });

    test('wheel straight (A-2-3-4-5)', () {
      final r = HandEvaluator.bestHand(p('As 2h 3d 4c 5s Kh Qd'));
      expect(r.category, HandCategory.straight);
    });

    test('three of a kind', () {
      final r = HandEvaluator.bestHand(p('Qs Qh Qd 7c 3s 2h 9d'));
      expect(r.category, HandCategory.threeOfAKind);
    });

    test('two pair', () {
      final r = HandEvaluator.bestHand(p('As Ah Ks Kh 7d 3c 2s'));
      expect(r.category, HandCategory.twoPair);
    });

    test('one pair', () {
      final r = HandEvaluator.bestHand(p('Js Jh 9d 7c 3s 2h Ad'));
      expect(r.category, HandCategory.onePair);
    });

    test('high card', () {
      final r = HandEvaluator.bestHand(p('As Kh 9d 7c 3s 2h 5d'));
      expect(r.category, HandCategory.highCard);
    });
  });

  group('HandEvaluator - comparison', () {
    test('flush beats straight', () {
      final flush = HandEvaluator.bestHand(p('As Js 8s 4s 2s Kh Qd'));
      final straight = HandEvaluator.bestHand(p('Ts 9h 8d 7c 6s 2h 3d'));
      expect(flush.compareTo(straight), greaterThan(0));
    });

    test('higher pair beats lower pair', () {
      final aa = HandEvaluator.bestHand(p('As Ah 9d 7c 3s 2h 5d'));
      final kk = HandEvaluator.bestHand(p('Ks Kh 9d 7c 3s 2h 5d'));
      expect(aa.compareTo(kk), greaterThan(0));
    });

    test('same hand split (compareTo == 0)', () {
      final a = HandEvaluator.bestHand(p('As Kh Ts 9h 8d 7c 6s'));
      final b = HandEvaluator.bestHand(p('Ad Kc Ts 9h 8d 7c 6s'));
      expect(a.compareTo(b), 0);
    });

    test('kicker breaks tie', () {
      final ak = HandEvaluator.bestHand(p('As Ah Kd 7c 3s 2h 5d'));
      final aq = HandEvaluator.bestHand(p('As Ah Qd 7c 3s 2h 5d'));
      expect(ak.compareTo(aq), greaterThan(0));
    });
  });

  group('HandEvaluator - Omaha must-use', () {
    test('board 4 hearts but only 1 hole heart = no flush', () {
      final r = HandEvaluator.bestOmaha(
        hole: p('Ah 9d Kc Qs'),
        community: p('Jh Th 8h 2h 3d'),
      );
      expect(r.category, isNot(HandCategory.flush));
      expect(r.category, isNot(HandCategory.straightFlush));
    });

    test('valid flush with 2 hole hearts', () {
      final r = HandEvaluator.bestOmaha(
        hole: p('Ah 9h Kc Qs'),
        community: p('Jh Th 8h 2d 3d'),
      );
      expect(r.category, HandCategory.flush);
    });

    test('must use exactly 2 hole cards', () {
      // All 4 hole cards are aces, but can only use 2
      final r = HandEvaluator.bestOmaha(
        hole: p('As Ah Ad Ac'),
        community: p('Ks Kh 2d 3c 4s'),
      );
      // Can use AA + KK2 or AA + KK3 etc = full house (AA over KK)
      // But NOT four aces (would need 4 hole cards)
      expect(r.category, isNot(HandCategory.fourOfAKind));
    });
  });

  group('HandEvaluator - Hi-Lo', () {
    test('8-or-better lo qualifies', () {
      final lo = HandEvaluator.evaluateLo(p('As 2h 3d 4c 8s'));
      expect(lo, isNotNull);
    });

    test('9 disqualifies', () {
      final lo = HandEvaluator.evaluateLo(p('As 2h 3d 4c 9s'));
      expect(lo, isNull);
    });

    test('pair disqualifies', () {
      final lo = HandEvaluator.evaluateLo(p('As Ah 3d 4c 5s'));
      expect(lo, isNull);
    });

    test('lower lo beats higher lo', () {
      final lo1 = HandEvaluator.evaluateLo(p('As 2h 3d 4c 5s'))!;
      final lo2 = HandEvaluator.evaluateLo(p('As 2h 3d 4c 8s'))!;
      expect(lo1.compareTo(lo2), greaterThan(0));
    });

    test('A-2-3-4-5 is the best lo (wheel)', () {
      final wheel = HandEvaluator.evaluateLo(p('As 2h 3d 4c 5s'))!;
      final sixLo = HandEvaluator.evaluateLo(p('As 2h 3d 4c 6s'))!;
      expect(wheel.compareTo(sixLo), greaterThan(0));
    });

    test('face cards disqualify', () {
      final lo = HandEvaluator.evaluateLo(p('As 2h 3d 4c Ks'));
      expect(lo, isNull);
    });
  });

  group('HandEvaluator - wheel and edge cases', () {
    test('wheel straight is 5-high', () {
      final wheel = HandEvaluator.bestHand(p('As 2h 3d 4c 5s 9h 8d'));
      final sixHigh = HandEvaluator.bestHand(p('6s 2h 3d 4c 5s 9h 8d'));
      expect(wheel.category, HandCategory.straight);
      expect(sixHigh.category, HandCategory.straight);
      // 6-high straight should beat 5-high wheel
      expect(sixHigh.compareTo(wheel), greaterThan(0));
    });

    test('ace-high straight beats king-high', () {
      final aceHigh = HandEvaluator.bestHand(p('As Kh Qd Jc Ts 3h 2d'));
      final kingHigh = HandEvaluator.bestHand(p('Ks Qh Jd Tc 9s 3h 2d'));
      expect(aceHigh.compareTo(kingHigh), greaterThan(0));
    });

    test('steel wheel (A-2-3-4-5 suited)', () {
      final r = HandEvaluator.bestHand(p('As 2s 3s 4s 5s Kh Qd'));
      expect(r.category, HandCategory.straightFlush);
    });

    test('higher straight flush beats lower', () {
      final high = HandEvaluator.bestHand(p('Kh Qh Jh Th 9h 2d 3c'));
      final low = HandEvaluator.bestHand(p('9h 8h 7h 6h 5h 2d 3c'));
      expect(high.compareTo(low), greaterThan(0));
    });

    test('full house: higher trips beats lower trips', () {
      final aaa = HandEvaluator.bestHand(p('As Ah Ad 2s 2h 7c 9d'));
      final kkk = HandEvaluator.bestHand(p('Ks Kh Kd 2s 2h 7c 9d'));
      expect(aaa.compareTo(kkk), greaterThan(0));
    });

    test('exactly 5 cards works', () {
      final r = HandEvaluator.bestHand(p('As Kh Qd Jc Ts'));
      expect(r.category, HandCategory.straight);
    });
  });

  group('HandEvaluator - short deck category order', () {
    test('6+ order: flush beats full house', () {
      final flush = HandEvaluator.bestHand(
        p('As Js 8s 7s 6s'),
        categoryOrder: HandCategory.shortDeck6PlusOrder,
      );
      final fullHouse = HandEvaluator.bestHand(
        p('As Ah Ad Ks Kh'),
        categoryOrder: HandCategory.shortDeck6PlusOrder,
      );
      expect(flush.compareTo(fullHouse), greaterThan(0));
    });

    test('Triton order: trips beats straight', () {
      final trips = HandEvaluator.bestHand(
        p('As Ah Ad Ks Qd'),
        categoryOrder: HandCategory.shortDeckTritonOrder,
      );
      final straight = HandEvaluator.bestHand(
        p('As Kh Qd Jc Ts'),
        categoryOrder: HandCategory.shortDeckTritonOrder,
      );
      expect(trips.compareTo(straight), greaterThan(0));
    });
  });

  group('HandEvaluator - Omaha Lo', () {
    test('bestOmahaLo finds qualifying lo', () {
      final lo = HandEvaluator.bestOmahaLo(
        hole: p('As 2h Kc Qd'),
        community: p('3s 4h 5d Ks Kh'),
      );
      expect(lo, isNotNull);
    });

    test('bestOmahaLo returns null when no qualifying lo', () {
      final lo = HandEvaluator.bestOmahaLo(
        hole: p('Ks Kh Qc Qd'),
        community: p('Js Jh Td 9s 9h'),
      );
      expect(lo, isNull);
    });
  });

  group('HandRank - equality and comparison', () {
    test('equal hands have compareTo == 0', () {
      final a = HandEvaluator.bestHand(p('As Ah Kd Qc Js 7h 2d'));
      final b = HandEvaluator.bestHand(p('Ad Ac Kh Qs Jc 7s 2h'));
      expect(a.compareTo(b), 0);
    });

    test('toString includes category name', () {
      final r = HandEvaluator.bestHand(p('As Ks Qs Js Ts 3h 2d'));
      expect(r.toString(), contains('royalFlush'));
    });
  });
}
