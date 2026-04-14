import 'package:test/test.dart';
import 'package:ebs_game_engine/engine.dart';

void main() {
  group('StudVariant properties', () {
    test('holeCardCount is 7 for all Stud variants', () {
      expect(SevenCardStud().holeCardCount, 7);
      expect(SevenCardStudHiLo().holeCardCount, 7);
      expect(Razz().holeCardCount, 7);
    });

    test('communityCardCount is 0 for all Stud variants', () {
      expect(SevenCardStud().communityCardCount, 0);
      expect(SevenCardStudHiLo().communityCardCount, 0);
      expect(Razz().communityCardCount, 0);
    });

    test('streetCount is 5', () {
      expect(SevenCardStud().streetCount, 5);
    });

    test('initialDownCards is 2 and initialUpCards is 1', () {
      final stud = SevenCardStud();
      expect(stud.initialDownCards, 2);
      expect(stud.initialUpCards, 1);
    });
  });

  group('SevenCardStud evaluateHi', () {
    test('best 5 from 7 cards — full house beats two pair', () {
      final stud = SevenCardStud();
      // 7 cards: three Aces + two Kings + 5h + 3d → full house A-A-A-K-K
      final hole = [
        Card.parse('As'),
        Card.parse('Ah'),
        Card.parse('Ad'),
        Card.parse('Ks'),
        Card.parse('Kh'),
        Card.parse('5h'),
        Card.parse('3d'),
      ];
      final result = stud.evaluateHi(hole, []);
      expect(result.category, HandCategory.fullHouse);
    });

    test('flush from 7 cards', () {
      final stud = SevenCardStud();
      // 5 hearts + 2 non-hearts → flush
      final hole = [
        Card.parse('Ah'),
        Card.parse('Kh'),
        Card.parse('Th'),
        Card.parse('7h'),
        Card.parse('3h'),
        Card.parse('2d'),
        Card.parse('4c'),
      ];
      final result = stud.evaluateHi(hole, []);
      expect(result.category, HandCategory.flush);
    });

    test('straight from 7 cards', () {
      final stud = SevenCardStud();
      final hole = [
        Card.parse('9s'),
        Card.parse('8h'),
        Card.parse('7d'),
        Card.parse('6c'),
        Card.parse('5s'),
        Card.parse('2h'),
        Card.parse('3d'),
      ];
      final result = stud.evaluateHi(hole, []);
      expect(result.category, HandCategory.straight);
    });
  });

  group('SevenCardStudHiLo', () {
    test('evaluateHi returns best high hand', () {
      final variant = SevenCardStudHiLo();
      final hole = [
        Card.parse('As'),
        Card.parse('Ah'),
        Card.parse('Ks'),
        Card.parse('Kh'),
        Card.parse('3d'),
        Card.parse('3c'),
        Card.parse('7s'),
      ];
      final result = variant.evaluateHi(hole, []);
      // A-A-K-K-7 or A-A-3-3-K → two pair, best is A-A-K-K
      expect(result.category, HandCategory.twoPair);
    });

    test('evaluateLo returns qualifying 8-or-better low', () {
      final variant = SevenCardStudHiLo();
      // Cards with good low potential: A,2,3,5,7 + K,Q
      final hole = [
        Card.parse('As'),
        Card.parse('2h'),
        Card.parse('3d'),
        Card.parse('5c'),
        Card.parse('7s'),
        Card.parse('Kh'),
        Card.parse('Qd'),
      ];
      final lo = variant.evaluateLo(hole, []);
      expect(lo, isNotNull); // A-2-3-5-7 qualifies
    });

    test('evaluateLo returns null when no qualifying low', () {
      final variant = SevenCardStudHiLo();
      // All cards > 8 except one Ace
      final hole = [
        Card.parse('As'),
        Card.parse('9h'),
        Card.parse('Td'),
        Card.parse('Jc'),
        Card.parse('Qs'),
        Card.parse('Kh'),
        Card.parse('9d'),
      ];
      final lo = variant.evaluateLo(hole, []);
      expect(lo, isNull); // Cannot make 5 unpaired cards all ≤ 8
    });
  });

  group('Razz', () {
    test('A-2-3-4-5 is the best hand (Wheel)', () {
      final razz = Razz();
      final wheel = [
        Card.parse('As'),
        Card.parse('2h'),
        Card.parse('3d'),
        Card.parse('4c'),
        Card.parse('5s'),
        Card.parse('Kh'),
        Card.parse('Qd'),
      ];
      final result = razz.evaluateHi(wheel, []);
      // Should be the best possible Razz hand
      // Compare against a worse low
      final worse = [
        Card.parse('As'),
        Card.parse('2h'),
        Card.parse('3d'),
        Card.parse('4c'),
        Card.parse('6s'),
        Card.parse('Kh'),
        Card.parse('Qd'),
      ];
      final worseResult = razz.evaluateHi(worse, []);
      // Wheel (A-2-3-4-5) should beat A-2-3-4-6
      expect(result.compareTo(worseResult), greaterThan(0));
    });

    test('lower hand beats higher hand', () {
      final razz = Razz();
      // Hand 1: A-2-3-4-7 (7-low)
      final hand1 = [
        Card.parse('As'),
        Card.parse('2h'),
        Card.parse('3d'),
        Card.parse('4c'),
        Card.parse('7s'),
        Card.parse('Kh'),
        Card.parse('Qd'),
      ];
      // Hand 2: A-2-3-5-8 (8-low)
      final hand2 = [
        Card.parse('As'),
        Card.parse('2h'),
        Card.parse('3d'),
        Card.parse('5c'),
        Card.parse('8s'),
        Card.parse('Kh'),
        Card.parse('Qd'),
      ];
      final r1 = razz.evaluateHi(hand1, []);
      final r2 = razz.evaluateHi(hand2, []);
      // 7-low should beat 8-low
      expect(r1.compareTo(r2), greaterThan(0));
    });

    test('pair hand is worse than non-pair hand', () {
      final razz = Razz();
      // No pair: A-2-3-4-8 + junk
      final noPair = [
        Card.parse('As'),
        Card.parse('2h'),
        Card.parse('3d'),
        Card.parse('4c'),
        Card.parse('8s'),
        Card.parse('Kh'),
        Card.parse('Qd'),
      ];
      // Pair of 2s (can't make unpaired 5): 2s,2h,3d,4c,5s,6h,7d
      // Actually this CAN make unpaired: 3-4-5-6-7. Let's force pair.
      final pairOnly = [
        Card.parse('2s'),
        Card.parse('2h'),
        Card.parse('Kd'),
        Card.parse('Qc'),
        Card.parse('Js'),
        Card.parse('Th'),
        Card.parse('9d'),
      ];
      final noPairResult = razz.evaluateHi(noPair, []);
      final pairResult = razz.evaluateHi(pairOnly, []);
      // Non-pair hand should beat pair hand
      expect(noPairResult.compareTo(pairResult), greaterThan(0));
    });

    test('bringInLowest is false for Razz', () {
      expect(Razz().bringInLowest, false);
    });

    test('isHiLo is false for Razz', () {
      expect(Razz().isHiLo, false);
    });
  });

  group('BringIn', () {
    test('lowest door card brings in for Stud', () {
      // Seat 0: 7h, Seat 1: 3d, Seat 2: Ks
      final upCards = {
        0: Card.parse('7h'),
        1: Card.parse('3d'),
        2: Card.parse('Ks'),
      };
      final result = BringIn.determineBringIn(upCards, bringInLowest: true);
      expect(result, 1); // 3d is lowest
    });

    test('suit tiebreaker: clubs < diamonds < hearts < spades', () {
      // Same rank (5), different suits
      final upCards = {
        0: Card.parse('5h'), // heart = rank 2
        1: Card.parse('5c'), // club = rank 0 (lowest)
        2: Card.parse('5s'), // spade = rank 3
      };
      final result = BringIn.determineBringIn(upCards, bringInLowest: true);
      expect(result, 1); // 5c (clubs) is lowest suit → brings in
    });

    test('highest door card brings in for Razz', () {
      final upCards = {
        0: Card.parse('7h'),
        1: Card.parse('Ks'),
        2: Card.parse('3d'),
      };
      final result = BringIn.determineBringIn(upCards, bringInLowest: false);
      expect(result, 1); // Ks is highest
    });

    test('Razz suit tiebreaker: highest suit brings in', () {
      final upCards = {
        0: Card.parse('Kh'), // heart = rank 2
        1: Card.parse('Ks'), // spade = rank 3 (highest)
        2: Card.parse('Kc'), // club = rank 0
      };
      final result = BringIn.determineBringIn(upCards, bringInLowest: false);
      expect(result, 1); // Ks (spades) is highest suit → brings in
    });

    test('bestVisibleHand: pair beats high card', () {
      final visibleHands = {
        0: [Card.parse('Ah'), Card.parse('Kd')], // A-K high
        1: [Card.parse('3s'), Card.parse('3h')], // pair of 3s
      };
      final result = BringIn.bestVisibleHand(visibleHands);
      expect(result, 1); // pair beats high card
    });
  });

  group('Variant registry', () {
    test('seven_card_stud is registered', () {
      expect(variantRegistry.containsKey('seven_card_stud'), true);
      expect(variantRegistry['seven_card_stud']!().name, '7-Card Stud');
    });

    test('seven_card_stud_hilo is registered', () {
      expect(variantRegistry.containsKey('seven_card_stud_hilo'), true);
      expect(
          variantRegistry['seven_card_stud_hilo']!().name, '7-Card Stud Hi-Lo');
    });

    test('razz is registered', () {
      expect(variantRegistry.containsKey('razz'), true);
      expect(variantRegistry['razz']!().name, 'Razz');
    });
  });

  group('HandEvaluator.bestLow8', () {
    test('finds qualifying low from 7 cards', () {
      final cards = [
        Card.parse('As'),
        Card.parse('2h'),
        Card.parse('4d'),
        Card.parse('5c'),
        Card.parse('7s'),
        Card.parse('Kh'),
        Card.parse('Qd'),
      ];
      final result = HandEvaluator.bestLow8(cards);
      expect(result, isNotNull);
    });

    test('returns null when no 5 unpaired cards ≤ 8', () {
      final cards = [
        Card.parse('9s'),
        Card.parse('Th'),
        Card.parse('Jd'),
        Card.parse('Qc'),
        Card.parse('Ks'),
        Card.parse('Ah'),
        Card.parse('2d'),
      ];
      // Only A and 2 are ≤ 8, need 5 → no qualifying low
      final result = HandEvaluator.bestLow8(cards);
      expect(result, isNull);
    });

    test('wheel is best possible low', () {
      final wheel = [
        Card.parse('As'),
        Card.parse('2h'),
        Card.parse('3d'),
        Card.parse('4c'),
        Card.parse('5s'),
        Card.parse('Kh'),
        Card.parse('Qd'),
      ];
      final worse = [
        Card.parse('As'),
        Card.parse('2h'),
        Card.parse('3d'),
        Card.parse('4c'),
        Card.parse('8s'),
        Card.parse('Kh'),
        Card.parse('Qd'),
      ];
      final wheelLo = HandEvaluator.bestLow8(wheel);
      final worseLo = HandEvaluator.bestLow8(worse);
      expect(wheelLo, isNotNull);
      expect(worseLo, isNotNull);
      // Wheel should beat 8-low
      expect(wheelLo!.compareTo(worseLo!), greaterThan(0));
    });
  });
}
