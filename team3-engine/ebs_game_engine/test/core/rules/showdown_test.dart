import 'package:test/test.dart';
import 'package:ebs_game_engine/core/rules/showdown.dart';
import 'package:ebs_game_engine/core/state/seat.dart';
import 'package:ebs_game_engine/core/state/pot.dart';
import 'package:ebs_game_engine/core/cards/card.dart';
import 'package:ebs_game_engine/core/variants/nlh.dart';

Seat _seat(int i, {
  int stack = 0,
  required List<String> hole,
  SeatStatus status = SeatStatus.active,
}) {
  return Seat(
    index: i,
    label: 'P$i',
    stack: stack,
    holeCards: hole.map(Card.parse).toList(),
    status: status,
  );
}

List<Card> _cards(List<String> notations) =>
    notations.map(Card.parse).toList();

void main() {
  final variant = Nlh();

  group('Showdown.evaluate', () {
    test('single winner takes whole pot', () {
      final seats = [
        _seat(0, hole: ['As', 'Ah']), // pocket aces
        _seat(1, hole: ['Ks', 'Kh']), // pocket kings
      ];
      final community = _cards(['2d', '5c', '8h', 'Td', '3s']);
      final pots = [const SidePot(200, {0, 1})];

      final awards = Showdown.evaluate(
        seats: seats,
        community: community,
        pots: pots,
        variant: variant,
      );

      expect(awards[0], 200); // AA wins
      expect(awards.containsKey(1), isFalse);
    });

    test('split pot on tie (same straight from board)', () {
      final seats = [
        _seat(0, hole: ['2s', '3h']), // irrelevant low cards
        _seat(1, hole: ['2d', '4h']), // irrelevant low cards
      ];
      // Board makes a straight: T-J-Q-K-A — both play the board
      final community = _cards(['Ts', 'Jd', 'Qc', 'Kh', 'Ac']);
      final pots = [const SidePot(200, {0, 1})];

      final awards = Showdown.evaluate(
        seats: seats,
        community: community,
        pots: pots,
        variant: variant,
      );

      expect(awards[0], 100);
      expect(awards[1], 100);
    });

    test('side pot awarded separately (3-way, short stack all-in)', () {
      // Player 0: AA (short stack, all-in early) — wins main pot
      // Player 1: KK — wins side pot
      // Player 2: QQ — loses both
      final seats = [
        _seat(0, hole: ['As', 'Ah'], status: SeatStatus.allIn),
        _seat(1, hole: ['Ks', 'Kh']),
        _seat(2, hole: ['Qs', 'Qh']),
      ];
      final community = _cards(['2d', '5c', '8h', 'Td', '3s']);

      // Main pot: 300 (all 3 eligible)
      // Side pot: 200 (only 1 and 2 eligible)
      final pots = [
        const SidePot(300, {0, 1, 2}),
        const SidePot(200, {1, 2}),
      ];

      final awards = Showdown.evaluate(
        seats: seats,
        community: community,
        pots: pots,
        variant: variant,
      );

      expect(awards[0], 300); // AA wins main
      expect(awards[1], 200); // KK wins side
      expect(awards.containsKey(2), isFalse); // QQ gets nothing
    });

    test('remainder chip goes to first winner', () {
      final seats = [
        _seat(0, hole: ['2s', '3h']),
        _seat(1, hole: ['2d', '3c']),
        _seat(2, hole: ['2c', '3d']),
      ];
      // Board straight: all play the board
      final community = _cards(['Ts', 'Jd', 'Qc', 'Kh', 'Ac']);
      final pots = [const SidePot(100, {0, 1, 2})]; // 100 / 3 = 33 r 1

      final awards = Showdown.evaluate(
        seats: seats,
        community: community,
        pots: pots,
        variant: variant,
      );

      // 33 each, remainder 1 to first eligible
      final total = (awards[0] ?? 0) + (awards[1] ?? 0) + (awards[2] ?? 0);
      expect(total, 100);
      expect(awards[0], 34); // first winner gets remainder
      expect(awards[1], 33);
      expect(awards[2], 33);
    });

    test('folded seats are excluded even if eligible in pot', () {
      final seats = [
        _seat(0, hole: ['2s', '3h'], status: SeatStatus.folded),
        _seat(1, hole: ['Ks', 'Kh']),
      ];
      final community = _cards(['As', 'Ah', '2d', '5c', '8h']);
      // Pot still lists seat 0 as eligible (from bets before fold)
      // but folded players should not win
      final pots = [const SidePot(200, {0, 1})];

      final awards = Showdown.evaluate(
        seats: seats,
        community: community,
        pots: pots,
        variant: variant,
      );

      expect(awards[1], 200);
      expect(awards.containsKey(0), isFalse);
    });
  });
}
