import 'package:test/test.dart';
import 'package:ebs_game_engine/core/state/pot.dart';

void main() {
  group('Pot', () {
    test('initial pot is zero', () {
      final pot = Pot();
      expect(pot.total, 0);
    });

    test('add to main pot', () {
      final pot = Pot()..addToMain(100);
      expect(pot.main, 100);
      expect(pot.total, 100);
    });

    test('calculate side pots for 3-way all-in', () {
      final pots = Pot.calculateSidePots(
        bets: {0: 100, 1: 300, 2: 500},
        folded: {},
      );
      expect(pots.length, 3);
      expect(pots[0].amount, 300);
      expect(pots[0].eligible, {0, 1, 2});
      expect(pots[1].amount, 400);
      expect(pots[1].eligible, {1, 2});
      expect(pots[2].amount, 200);
      expect(pots[2].eligible, {2});
    });

    test('folded players contribute but are not eligible', () {
      final pots = Pot.calculateSidePots(
        bets: {0: 50, 1: 100, 2: 100},
        folded: {0},
      );
      expect(pots.length, 2);
      expect(pots[0].amount, 150);
      expect(pots[0].eligible, {1, 2});
      expect(pots[1].amount, 100);
      expect(pots[1].eligible, {1, 2});
    });

    test('heads-up no side pot', () {
      final pots = Pot.calculateSidePots(
        bets: {0: 200, 1: 200},
        folded: {},
      );
      expect(pots.length, 1);
      expect(pots[0].amount, 400);
      expect(pots[0].eligible, {0, 1});
    });
  });
}
