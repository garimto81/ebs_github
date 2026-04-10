/// KI Critical Bug Reproduction Tests
/// These tests MUST FAIL on the current codebase to prove the bugs exist.
/// After fixes, they should pass.
import 'package:test/test.dart';
import 'package:ebs_game_engine/engine.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // KI-01: Short Deck Wheel (A-6-7-8-9) not recognized as straight
  // File: hand_evaluator.dart _checkStraight()
  // WSOP Rule: In Short Deck (36-card), A-6-7-8-9 is the lowest straight
  // ═══════════════════════════════════════════════════════════════════════════
  group('KI-01: Short Deck Wheel', () {
    test('A-6-7-8-9 should be recognized as a straight', () {
      final hole = [Card.parse('As'), Card.parse('6s')];
      final board = [
        Card.parse('7h'),
        Card.parse('8d'),
        Card.parse('9c'),
        Card.parse('Kd'),
        Card.parse('Qh'),
      ];

      final rank = HandEvaluator.bestHand(
        [...hole, ...board],
        categoryOrder: HandCategory.shortDeck6PlusOrder,
      );

      expect(rank.category, equals(HandCategory.straight),
          reason: 'A-6-7-8-9 is a valid straight in Short Deck');
    });

    test('A-6-7-8-9 same suit should be a straight flush', () {
      final hole = [Card.parse('As'), Card.parse('6s')];
      final board = [
        Card.parse('7s'),
        Card.parse('8s'),
        Card.parse('9s'),
        Card.parse('Kd'),
        Card.parse('Qh'),
      ];

      final rank = HandEvaluator.bestHand(
        [...hole, ...board],
        categoryOrder: HandCategory.shortDeck6PlusOrder,
      );

      expect(rank.category, equals(HandCategory.straightFlush),
          reason: 'A-6-7-8-9 suited is a straight flush in Short Deck');
    });

    test('ShortDeck variant evaluateHi recognizes wheel', () {
      final variant = ShortDeck();
      final hole = [Card.parse('As'), Card.parse('6h')];
      final community = [
        Card.parse('7d'),
        Card.parse('8c'),
        Card.parse('9s'),
        Card.parse('Kh'),
        Card.parse('Jd'),
      ];

      final rank = variant.evaluateHi(hole, community);
      expect(rank.category, equals(HandCategory.straight),
          reason: 'ShortDeck variant must recognize A-6-7-8-9 wheel');
    });

    test('standard wheel A-2-3-4-5 still works', () {
      final rank = HandEvaluator.bestHand(
        [
          Card.parse('As'),
          Card.parse('2h'),
          Card.parse('3d'),
          Card.parse('4c'),
          Card.parse('5s'),
          Card.parse('Kd'),
          Card.parse('Qh'),
        ],
        categoryOrder: HandCategory.standardOrder,
      );

      expect(rank.category, equals(HandCategory.straight),
          reason: 'Standard wheel A-2-3-4-5 must still work');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // KI-02: Hi/Lo odd chip assigned to Lo (should be Hi per WSOP Rule 73)
  // File: showdown.dart _awardHiLo() L92-93
  // WSOP Rule 73: "odd chip in the total pot goes to the high side"
  // ═══════════════════════════════════════════════════════════════════════════
  group('KI-02: Hi/Lo Odd Chip', () {
    test('odd pot (101) should give extra chip to Hi, not Lo', () {
      final variant = OmahaHiLo();

      // P0: strong Hi hand, P1: qualifying Lo hand
      final seats = [
        Seat(
          index: 0,
          label: 'P0',
          stack: 0,
          holeCards: [
            Card.parse('Ks'),
            Card.parse('Kh'),
            Card.parse('Qs'),
            Card.parse('Js'),
          ],
        ),
        Seat(
          index: 1,
          label: 'P1',
          stack: 0,
          holeCards: [
            Card.parse('Ah'),
            Card.parse('2h'),
            Card.parse('3c'),
            Card.parse('4d'),
          ],
        ),
      ];

      // Board that gives P0 Hi (two pair KK+77) and P1 Lo (A-2-3-4-7)
      final community = [
        Card.parse('7d'),
        Card.parse('7c'),
        Card.parse('8s'),
        Card.parse('Td'),
        Card.parse('5c'),
      ];

      // Verify P0 wins Hi and P1 wins Lo
      final hiP0 = variant.evaluateHi(seats[0].holeCards, community);
      final hiP1 = variant.evaluateHi(seats[1].holeCards, community);
      final loP1 = variant.evaluateLo(seats[1].holeCards, community);

      // P0 should have better Hi hand
      expect(hiP0.compareTo(hiP1), greaterThan(0),
          reason: 'P0 must win Hi');
      // P1 should have qualifying Lo
      expect(loP1, isNotNull, reason: 'P1 must have qualifying Lo');

      // Now test the odd chip allocation
      final pots = [SidePot(101, {0, 1})];

      final awards = Showdown.evaluate(
        seats: seats,
        community: community,
        pots: pots,
        variant: variant,
        dealerSeat: 0,
      );

      final hiAward = awards[0] ?? 0;
      final loAward = awards[1] ?? 0;

      expect(hiAward + loAward, equals(101), reason: 'Total must be 101');
      expect(hiAward, equals(51),
          reason: 'WSOP Rule 73: Hi gets 51 (odd chip to high side)');
      expect(loAward, equals(50),
          reason: 'Lo gets 50 (floor of 101/2)');
    });

    test('even pot (100) splits equally', () {
      final variant = OmahaHiLo();

      final seats = [
        Seat(
          index: 0,
          label: 'P0',
          stack: 0,
          holeCards: [
            Card.parse('Ks'),
            Card.parse('Kh'),
            Card.parse('Qs'),
            Card.parse('Js'),
          ],
        ),
        Seat(
          index: 1,
          label: 'P1',
          stack: 0,
          holeCards: [
            Card.parse('Ah'),
            Card.parse('2h'),
            Card.parse('3c'),
            Card.parse('4d'),
          ],
        ),
      ];

      final community = [
        Card.parse('7d'),
        Card.parse('7c'),
        Card.parse('8s'),
        Card.parse('Td'),
        Card.parse('5c'),
      ];

      final pots = [SidePot(100, {0, 1})];

      final awards = Showdown.evaluate(
        seats: seats,
        community: community,
        pots: pots,
        variant: variant,
        dealerSeat: 0,
      );

      expect(awards[0], equals(50));
      expect(awards[1], equals(50));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // KI-03: calculateSidePots() — unit test (algorithm itself is correct,
  // but engine integration is broken)
  // ═══════════════════════════════════════════════════════════════════════════
  group('KI-03: Side Pot Calculation', () {
    test('calculateSidePots unit: 3 different stacks', () {
      final pots = Pot.calculateSidePots(
        bets: {0: 500, 1: 1000, 2: 1000},
        folded: {},
      );

      expect(pots.length, equals(2));
      expect(pots[0].amount, equals(1500)); // 500 × 3
      expect(pots[0].eligible, equals({0, 1, 2}));
      expect(pots[1].amount, equals(1000)); // 500 × 2
      expect(pots[1].eligible, equals({1, 2}));
    });

    test('calculateSidePots with fold: dead money stays in pot', () {
      // P0: 500 (folded), P1: 1000, P2: 1000
      final pots = Pot.calculateSidePots(
        bets: {0: 500, 1: 1000, 2: 1000},
        folded: {0},
      );

      expect(pots.length, equals(2));
      // Main pot: 500 × 3 = 1500, but P0 folded → eligible = {1, 2}
      expect(pots[0].amount, equals(1500));
      expect(pots[0].eligible, equals({1, 2}));
      // Side pot: 500 × 2 = 1000, eligible = {1, 2}
      expect(pots[1].amount, equals(1000));
      expect(pots[1].eligible, equals({1, 2}));
    });

    test('Engine side pot integration: all-in via harness API', () async {
      // Test via HTTP API to verify engine integration
      // Create session with 3 players, different stacks
      // This tests if the running engine at 8888 correctly handles side pots
      // (Skipped here — requires HTTP client, tested in harness integration)
    }, skip: 'Requires running harness at localhost:8888');
  });
}
