import 'package:test/test.dart';
import 'package:ebs_game_engine/engine.dart';

void main() {
  // ── Helper to parse cards ──
  Card c(String s) => Card.parse(s);

  group('7-2 Side Bet — isSevenDeuce', () {
    test('7s 2h → true (offsuit)', () {
      expect(Showdown.isSevenDeuce([c('7s'), c('2h')]), isTrue);
    });

    test('7s 2s → false (suited)', () {
      expect(Showdown.isSevenDeuce([c('7s'), c('2s')]), isFalse);
    });

    test('As Kh → false (not 7-2)', () {
      expect(Showdown.isSevenDeuce([c('As'), c('Kh')]), isFalse);
    });

    test('7h only → false (1 card)', () {
      expect(Showdown.isSevenDeuce([c('7h')]), isFalse);
    });

    test('2d 7c → true (reversed order, offsuit)', () {
      expect(Showdown.isSevenDeuce([c('2d'), c('7c')]), isTrue);
    });

    test('7h 7d → false (pair of sevens)', () {
      expect(Showdown.isSevenDeuce([c('7h'), c('7d')]), isFalse);
    });

    test('2h 2d → false (pair of deuces)', () {
      expect(Showdown.isSevenDeuce([c('2h'), c('2d')]), isFalse);
    });

    test('3 cards → false', () {
      expect(Showdown.isSevenDeuce([c('7h'), c('2d'), c('As')]), isFalse);
    });
  });

  group('7-2 Side Bet — checkSevenDeuceBonus', () {
    List<Seat> makeSeats(int count, {Map<int, List<Card>>? cards}) {
      return List.generate(count, (i) => Seat(
        index: i,
        label: 'S$i',
        stack: 1000,
        holeCards: cards?[i] ?? [c('As'), c('Ks')],
      ));
    }

    test('winner with 7-2 offsuit, 6 players → bonus = amount × 5', () {
      final seats = makeSeats(6, cards: {
        0: [c('7s'), c('2h')], // winner with 7-2
      });
      final awards = {0: 500, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      final bonus = Showdown.checkSevenDeuceBonus(
        seats: seats,
        awards: awards,
        sevenDeuceAmount: 100,
      );
      expect(bonus[0], equals(500)); // 100 × 5
    });

    test('winner without 7-2 → empty', () {
      final seats = makeSeats(6);
      final awards = {0: 500};
      final bonus = Showdown.checkSevenDeuceBonus(
        seats: seats,
        awards: awards,
        sevenDeuceAmount: 100,
      );
      expect(bonus, isEmpty);
    });

    test('multiple winners, one has 7-2 → only that one gets bonus', () {
      final seats = makeSeats(4, cards: {
        0: [c('7d'), c('2h')], // winner with 7-2
        1: [c('Ah'), c('Kh')], // winner without 7-2
      });
      final awards = {0: 250, 1: 250};
      final bonus = Showdown.checkSevenDeuceBonus(
        seats: seats,
        awards: awards,
        sevenDeuceAmount: 50,
      );
      expect(bonus[0], equals(150)); // 50 × 3
      expect(bonus.containsKey(1), isFalse);
    });

    test('winner with suited 7-2 → no bonus', () {
      final seats = makeSeats(4, cards: {
        0: [c('7s'), c('2s')], // suited 7-2
      });
      final awards = {0: 300};
      final bonus = Showdown.checkSevenDeuceBonus(
        seats: seats,
        awards: awards,
        sevenDeuceAmount: 100,
      );
      expect(bonus, isEmpty);
    });

    test('7-2 holder lost (award = 0) → no bonus', () {
      final seats = makeSeats(4, cards: {
        0: [c('7d'), c('2h')],
      });
      final awards = {0: 0, 1: 500};
      final bonus = Showdown.checkSevenDeuceBonus(
        seats: seats,
        awards: awards,
        sevenDeuceAmount: 100,
      );
      expect(bonus, isEmpty);
    });
  });

  group('Equity Calculator', () {
    test('AA vs KK preflop: AA equity > 0.75', () {
      final equity = EquityCalculator.calculate(
        hands: {
          0: [c('As'), c('Ah')],
          1: [c('Ks'), c('Kh')],
        },
        iterations: 20000,
        seed: 42,
      );
      expect(equity[0]!, greaterThan(0.75));
      expect(equity[1]!, lessThan(0.25));
    });

    test('AA vs 72o preflop: AA equity > 0.85', () {
      final equity = EquityCalculator.calculate(
        hands: {
          0: [c('As'), c('Ah')],
          1: [c('7d'), c('2c')],
        },
        iterations: 20000,
        seed: 42,
      );
      expect(equity[0]!, greaterThan(0.85));
    });

    test('set vs flush draw on flop: reasonable equity split', () {
      // Player 0 has a set of kings, player 1 has a flush draw
      final equity = EquityCalculator.calculate(
        hands: {
          0: [c('Ks'), c('Kh')],
          1: [c('Jh'), c('Th')],
        },
        board: [c('Kd'), c('9h'), c('2h')],
        iterations: 20000,
        seed: 42,
      );
      // Set should be favored but flush draw has equity
      expect(equity[0]!, greaterThan(0.55));
      expect(equity[1]!, greaterThan(0.15));
    });

    test('made hand vs draw: made hand favored', () {
      // Top pair vs open-ended straight draw
      final equity = EquityCalculator.calculate(
        hands: {
          0: [c('As'), c('Kd')],
          1: [c('Jc'), c('Tc')],
        },
        board: [c('Kh'), c('Qs'), c('3d')],
        iterations: 20000,
        seed: 42,
      );
      expect(equity[0]!, greaterThan(0.50));
    });

    test('empty board (preflop): full 5-card simulation', () {
      final equity = EquityCalculator.calculate(
        hands: {
          0: [c('As'), c('Ks')],
          1: [c('8d'), c('7d')],
        },
        iterations: 10000,
        seed: 42,
      );
      // AKs should be favored over 87s
      expect(equity[0]!, greaterThan(0.55));
      // Equities should sum to ~1.0
      expect(equity[0]! + equity[1]!, closeTo(1.0, 0.001));
    });

    test('partial board (flop): 2 cards simulated', () {
      final equity = EquityCalculator.calculate(
        hands: {
          0: [c('As'), c('Ad')],
          1: [c('Ks'), c('Qd')],
        },
        board: [c('Kh'), c('7c'), c('2d')],
        iterations: 10000,
        seed: 42,
      );
      // AA should be ahead
      expect(equity[0]!, greaterThan(0.80));
    });

    test('turn: 1 card simulated', () {
      final equity = EquityCalculator.calculate(
        hands: {
          0: [c('As'), c('Ad')],
          1: [c('Ks'), c('Kd')],
        },
        board: [c('Qh'), c('7c'), c('2d'), c('3s')],
        iterations: 10000,
        seed: 42,
      );
      // AA vs KK on blank board — AA huge favorite
      expect(equity[0]!, greaterThan(0.90));
    });

    test('river (full board): exact eval, no simulation', () {
      final equity = EquityCalculator.calculate(
        hands: {
          0: [c('As'), c('Ad')],
          1: [c('Ks'), c('Kd')],
        },
        board: [c('Qh'), c('7c'), c('2d'), c('3s'), c('8h')],
        iterations: 10000,
        seed: 42,
      );
      // AA wins on this board — exact evaluation
      expect(equity[0]!, equals(1.0));
      expect(equity[1]!, equals(0.0));
    });

    test('river: loser gets 0.0', () {
      final equity = EquityCalculator.calculate(
        hands: {
          0: [c('Ks'), c('Kd')],
          1: [c('As'), c('Ad')],
        },
        board: [c('Qh'), c('7c'), c('2d'), c('3s'), c('8h')],
      );
      expect(equity[0]!, equals(0.0));
      expect(equity[1]!, equals(1.0));
    });

    test('3 players preflop: equities sum to ~1.0', () {
      final equity = EquityCalculator.calculate(
        hands: {
          0: [c('As'), c('Ah')],
          1: [c('Ks'), c('Kh')],
          2: [c('Qs'), c('Qh')],
        },
        iterations: 20000,
        seed: 42,
      );
      final sum = equity.values.reduce((a, b) => a + b);
      expect(sum, closeTo(1.0, 0.001));
      // AA should have highest equity
      expect(equity[0]!, greaterThan(equity[1]!));
      expect(equity[1]!, greaterThan(equity[2]!));
    });

    test('tied hands: equity split equally', () {
      // Both have same hand
      final equity = EquityCalculator.calculate(
        hands: {
          0: [c('As'), c('Kd')],
          1: [c('Ah'), c('Kc')],
        },
        board: [c('Qh'), c('Jd'), c('2c'), c('3s'), c('8h')],
      );
      expect(equity[0]!, equals(0.5));
      expect(equity[1]!, equals(0.5));
    });

    test('seed reproducibility: same seed = same result', () {
      Map<int, double> run(int seed) => EquityCalculator.calculate(
        hands: {
          0: [c('As'), c('Ah')],
          1: [c('Ks'), c('Kh')],
        },
        iterations: 5000,
        seed: seed,
      );

      final r1 = run(99);
      final r2 = run(99);
      final r3 = run(100);

      expect(r1[0], equals(r2[0]));
      expect(r1[1], equals(r2[1]));
      // Different seed should (very likely) produce different result
      expect(r1[0], isNot(equals(r3[0])));
    });

    test('empty hands map returns empty', () {
      final equity = EquityCalculator.calculate(hands: {});
      expect(equity, isEmpty);
    });

    test('known matchup with seed: AKs vs QQ', () {
      final equity = EquityCalculator.calculate(
        hands: {
          0: [c('As'), c('Ks')],
          1: [c('Qd'), c('Qc')],
        },
        iterations: 20000,
        seed: 42,
      );
      // Classic race: QQ slight favorite over AKs (~55/45)
      expect(equity[1]!, greaterThan(0.48));
      expect(equity[0]!, greaterThan(0.38));
    });
  });
}
