import 'package:test/test.dart';
import 'package:ebs_game_engine/core/state/betting_round.dart';

void main() {
  group('BettingRound', () {
    test('initial state', () {
      final br = BettingRound(currentBet: 10, minRaise: 10);
      expect(br.currentBet, 10);
      expect(br.minRaise, 10);
      expect(br.actedThisRound, isEmpty);
    });

    test('copy is independent', () {
      final br = BettingRound(currentBet: 10, minRaise: 10);
      br.actedThisRound.add(0);
      final copy = br.copy();
      copy.actedThisRound.add(1);
      expect(br.actedThisRound.length, 1);
      expect(copy.actedThisRound.length, 2);
    });
  });
}
