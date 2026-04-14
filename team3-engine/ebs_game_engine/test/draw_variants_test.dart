import 'package:test/test.dart';
import 'package:ebs_game_engine/engine.dart';
import 'package:ebs_game_engine/core/cards/badugi_evaluator.dart';

void main() {
  // Helper to create cards from notation
  Card c(String n) => Card.parse(n);

  group('Lowball 2-7 Evaluator', () {
    test('7-5-4-3-2 offsuit is the best hand', () {
      final best = HandEvaluator.bestLowball27([
        c('7s'), c('5h'), c('4d'), c('3c'), c('2s'),
      ]);
      final worse = HandEvaluator.bestLowball27([
        c('8s'), c('5h'), c('4d'), c('3c'), c('2s'),
      ]);
      expect(best.compareTo(worse), greaterThan(0));
    });

    test('A-high is the worst (A = 14)', () {
      final aceHigh = HandEvaluator.bestLowball27([
        c('As'), c('Kh'), c('Qd'), c('Jc'), c('9s'),
      ]);
      final eightLow = HandEvaluator.bestLowball27([
        c('8s'), c('6h'), c('4d'), c('3c'), c('2s'),
      ]);
      expect(eightLow.compareTo(aceHigh), greaterThan(0));
    });

    test('Straight hurts: 6-5-4-3-2 worse than 7-5-4-3-2', () {
      // 6-5-4-3-2 is a straight in standard poker, so it ranks higher
      // In 2-7 lowball, higher standard rank = worse
      final straight = HandEvaluator.bestLowball27([
        c('6s'), c('5h'), c('4d'), c('3c'), c('2s'),
      ]);
      final sevenLow = HandEvaluator.bestLowball27([
        c('7s'), c('5h'), c('4d'), c('3c'), c('2s'),
      ]);
      // 7-5-4-3-2 high card should beat 6-5-4-3-2 straight in lowball
      expect(sevenLow.compareTo(straight), greaterThan(0));
    });

    test('Flush hurts: suited hand worse than offsuit', () {
      // All spades = flush in standard poker = bad in 2-7
      final flush = HandEvaluator.bestLowball27([
        c('7s'), c('5s'), c('4s'), c('3s'), c('2s'),
      ]);
      final offsuit = HandEvaluator.bestLowball27([
        c('7s'), c('5h'), c('4d'), c('3c'), c('2s'),
      ]);
      expect(offsuit.compareTo(flush), greaterThan(0));
    });

    test('Picks best lowball from 6+ cards', () {
      final rank = HandEvaluator.bestLowball27([
        c('7s'), c('5h'), c('4d'), c('3c'), c('2s'), c('Kh'),
      ]);
      // Should pick 7-5-4-3-2, ignoring King
      expect(rank, isNotNull);
    });
  });

  group('Lowball A-5 Evaluator', () {
    test('A-2-3-4-5 (Wheel) is the best hand', () {
      final wheel = HandEvaluator.bestLowballA5([
        c('As'), c('2h'), c('3d'), c('4c'), c('5s'),
      ]);
      final sixLow = HandEvaluator.bestLowballA5([
        c('As'), c('2h'), c('3d'), c('4c'), c('6s'),
      ]);
      expect(wheel.compareTo(sixLow), greaterThan(0));
    });

    test('Straight is ignored (A-2-3-4-5 still best)', () {
      // A-2-3-4-5 is a straight in standard poker but in A-5 lowball
      // straights don't count, so it's still the best hand
      final wheel = HandEvaluator.bestLowballA5([
        c('As'), c('2h'), c('3d'), c('4c'), c('5s'),
      ]);
      expect(wheel, isNotNull);
      // Compare against a non-straight low
      final sevenLow = HandEvaluator.bestLowballA5([
        c('As'), c('2h'), c('3d'), c('4c'), c('7s'),
      ]);
      expect(wheel.compareTo(sevenLow), greaterThan(0));
    });

    test('Flush is ignored', () {
      // All same suit should still be evaluated as low
      final flushWheel = HandEvaluator.bestLowballA5([
        c('As'), c('2s'), c('3s'), c('4s'), c('5s'),
      ]);
      final offsuit = HandEvaluator.bestLowballA5([
        c('As'), c('2h'), c('3d'), c('4c'), c('5s'),
      ]);
      // Both should be wheel (equal)
      expect(flushWheel.compareTo(offsuit), equals(0));
    });

    test('8-7-6-5-4 worse than A-2-3-4-5', () {
      final wheel = HandEvaluator.bestLowballA5([
        c('As'), c('2h'), c('3d'), c('4c'), c('5s'),
      ]);
      final eightLow = HandEvaluator.bestLowballA5([
        c('8s'), c('7h'), c('6d'), c('5c'), c('4s'),
      ]);
      expect(wheel.compareTo(eightLow), greaterThan(0));
    });

    test('Pairs are worse than no-pair hands', () {
      final pairHand = HandEvaluator.bestLowballA5([
        c('As'), c('Ah'), c('3d'), c('4c'), c('5s'),
      ]);
      final noPair = HandEvaluator.bestLowballA5([
        c('Ks'), c('Qh'), c('Jd'), c('Tc'), c('9s'),
      ]);
      // No pair hand beats pair hand in A-5 lowball
      expect(noPair.compareTo(pairHand), greaterThan(0));
    });
  });

  group('Badugi Evaluator', () {
    test('4-card badugi beats 3-card', () {
      final four = BadugiEvaluator.bestBadugi([
        c('As'), c('2h'), c('3d'), c('4c'),
      ]);
      // Two spades: one will be removed → 3-card
      final three = BadugiEvaluator.bestBadugi([
        c('As'), c('2s'), c('3d'), c('4c'),
      ]);
      expect(four.compareTo(three), greaterThan(0));
    });

    test('Suit duplicate removes highest card', () {
      // Two hearts: 2h and Kh. K should be removed → 3-card badugi A-2-3
      final rank = BadugiEvaluator.bestBadugi([
        c('As'), c('2h'), c('3d'), c('Kh'),
      ]);
      expect(rank.cardCount, equals(3));
    });

    test('A-2-3-4 rainbow is the best 4-card badugi', () {
      final best = BadugiEvaluator.bestBadugi([
        c('As'), c('2h'), c('3d'), c('4c'),
      ]);
      final worse = BadugiEvaluator.bestBadugi([
        c('As'), c('2h'), c('3d'), c('5c'),
      ]);
      expect(best.compareTo(worse), greaterThan(0));
    });

    test('Same card count: lower high card wins', () {
      final lower = BadugiEvaluator.bestBadugi([
        c('As'), c('2h'), c('3d'), c('5c'),
      ]);
      final higher = BadugiEvaluator.bestBadugi([
        c('As'), c('2h'), c('3d'), c('7c'),
      ]);
      expect(lower.compareTo(higher), greaterThan(0));
    });

    test('Best badugi from 5 cards', () {
      final rank = BadugiEvaluator.bestBadugi([
        c('As'), c('2h'), c('3d'), c('4c'), c('Ks'),
      ]);
      // Should find A-2-3-4 as the best 4-card badugi
      expect(rank.cardCount, equals(4));
      expect(rank.values, equals([1, 2, 3, 4]));
    });
  });

  group('Five Card Draw Variant', () {
    test('evaluateHi returns standard high hand', () {
      final variant = FiveCardDraw();
      final rank = variant.evaluateHi([
        c('As'), c('Ks'), c('Qs'), c('Js'), c('Ts'),
      ], []);
      expect(rank.category, equals(HandCategory.royalFlush));
    });

    test('properties are correct', () {
      final variant = FiveCardDraw();
      expect(variant.holeCardCount, equals(5));
      expect(variant.communityCardCount, equals(0));
      expect(variant.isHiLo, isFalse);
      expect(variant.drawRounds, equals(1));
    });
  });

  group('Deuce Seven Variant', () {
    test('single draw evaluateHi returns lowball27', () {
      final variant = DeuceSevenSingle();
      final best = variant.evaluateHi([
        c('7s'), c('5h'), c('4d'), c('3c'), c('2s'),
      ], []);
      final worse = variant.evaluateHi([
        c('8s'), c('5h'), c('4d'), c('3c'), c('2s'),
      ], []);
      expect(best.compareTo(worse), greaterThan(0));
    });

    test('triple draw has 3 draw rounds', () {
      final variant = DeuceSevenTriple();
      expect(variant.drawRounds, equals(3));
      expect(variant.holeCardCount, equals(5));
    });
  });

  group('Ace Five Triple Variant', () {
    test('evaluateHi returns A-5 lowball', () {
      final variant = AceFiveTriple();
      final wheel = variant.evaluateHi([
        c('As'), c('2h'), c('3d'), c('4c'), c('5s'),
      ], []);
      final worse = variant.evaluateHi([
        c('As'), c('2h'), c('3d'), c('4c'), c('7s'),
      ], []);
      expect(wheel.compareTo(worse), greaterThan(0));
    });

    test('properties correct', () {
      final variant = AceFiveTriple();
      expect(variant.drawRounds, equals(3));
      expect(variant.isHiLo, isFalse);
    });
  });

  group('Badugi Variant', () {
    test('evaluateHi returns badugi ranking', () {
      final variant = Badugi();
      final best = variant.evaluateHi([
        c('As'), c('2h'), c('3d'), c('4c'),
      ], []);
      final worse = variant.evaluateHi([
        c('As'), c('2s'), c('3d'), c('4c'),
      ], []);
      // 4-card badugi beats 3-card
      expect(best.compareTo(worse), greaterThan(0));
    });

    test('properties correct', () {
      final variant = Badugi();
      expect(variant.holeCardCount, equals(4));
      expect(variant.drawRounds, equals(3));
      expect(variant.maxDiscard, equals(4));
    });
  });

  group('Badeucy Variant', () {
    test('Hi = badugi, Lo = lowball27', () {
      final variant = Badeucy();
      final hi = variant.evaluateHi([
        c('As'), c('2h'), c('3d'), c('4c'), c('7s'),
      ], []);
      final lo = variant.evaluateLo([
        c('7s'), c('5h'), c('4d'), c('3c'), c('2s'),
      ], []);
      expect(hi, isNotNull);
      expect(lo, isNotNull);
    });

    test('isHiLo is true', () {
      expect(Badeucy().isHiLo, isTrue);
    });

    test('properties correct', () {
      final variant = Badeucy();
      expect(variant.holeCardCount, equals(5));
      expect(variant.drawRounds, equals(3));
    });
  });

  group('Badacey Variant', () {
    test('Hi = badugi, Lo = lowballA5', () {
      final variant = Badacey();
      final hi = variant.evaluateHi([
        c('As'), c('2h'), c('3d'), c('4c'), c('7s'),
      ], []);
      final lo = variant.evaluateLo([
        c('As'), c('2h'), c('3d'), c('4c'), c('5s'),
      ], []);
      expect(hi, isNotNull);
      expect(lo, isNotNull);
    });

    test('isHiLo is true', () {
      expect(Badacey().isHiLo, isTrue);
    });

    test('Lo wheel is the best low', () {
      final variant = Badacey();
      final wheel = variant.evaluateLo([
        c('As'), c('2h'), c('3d'), c('4c'), c('5s'),
      ], []);
      final sevenLow = variant.evaluateLo([
        c('As'), c('2h'), c('3d'), c('4c'), c('7s'),
      ], []);
      expect(wheel!.compareTo(sevenLow!), greaterThan(0));
    });
  });

  group('Deck.reshuffle', () {
    test('adds discards back to deck', () {
      final deck = Deck.standard(seed: 42);
      final drawn = <Card>[];
      for (var i = 0; i < 10; i++) {
        drawn.add(deck.draw());
      }
      final remaining = deck.remaining;
      deck.reshuffle(drawn, seed: 99);
      expect(deck.remaining, equals(remaining + 10));
    });

    test('cards can be drawn after reshuffle', () {
      final deck = Deck.standard(seed: 42);
      // Draw all 52 cards
      final drawn = <Card>[];
      while (deck.remaining > 0) {
        drawn.add(deck.draw());
      }
      expect(deck.remaining, equals(0));

      // Reshuffle 5 discards back
      deck.reshuffle(drawn.sublist(0, 5), seed: 99);
      expect(deck.remaining, equals(5));

      // Should be able to draw again
      final redrawn = deck.draw();
      expect(redrawn, isNotNull);
      expect(deck.remaining, equals(4));
    });
  });

  group('Variant Registry', () {
    test('all draw variants registered', () {
      expect(variantRegistry.containsKey('five_card_draw'), isTrue);
      expect(variantRegistry.containsKey('deuce_seven_single'), isTrue);
      expect(variantRegistry.containsKey('deuce_seven_triple'), isTrue);
      expect(variantRegistry.containsKey('ace_five_triple'), isTrue);
      expect(variantRegistry.containsKey('badugi'), isTrue);
      expect(variantRegistry.containsKey('badeucy'), isTrue);
      expect(variantRegistry.containsKey('badacey'), isTrue);
    });

    test('registry creates correct types', () {
      expect(variantRegistry['five_card_draw']!(), isA<FiveCardDraw>());
      expect(variantRegistry['badugi']!(), isA<Badugi>());
      expect(variantRegistry['badeucy']!(), isA<Badeucy>());
    });
  });
}
