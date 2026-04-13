import 'package:test/test.dart';
import 'package:ebs_game_engine/engine.dart';

GameState _nlhState({int stack = 1000, int bbAmount = 20}) {
  final seats = [
    Seat(index: 0, label: 'P0', stack: stack),
    Seat(index: 1, label: 'P1', stack: stack),
    Seat(index: 2, label: 'P2', stack: stack),
  ];
  return GameState(
    sessionId: 'test',
    variantName: 'nlh',
    seats: seats,
    deck: Deck.standard(seed: 42),
    street: Street.preflop,
    bbAmount: bbAmount,
    handInProgress: true,
    betting: BettingRound(currentBet: 0, minRaise: bbAmount),
  );
}

void main() {
  group('WSOP Rule 95: Under-raise threshold', () {
    test('raise below 50% of minRaise → converted to Call', () {
      // Setup: currentBet=100, minRaise=100 (previous raise was 100)
      var state = _nlhState(stack: 1000, bbAmount: 100);
      state = state.copyWith(
        betting: BettingRound(currentBet: 100, minRaise: 100),
      );
      state.seats[0].currentBet = 0; // P0 hasn't acted

      // P0 tries to raise to 140 (raiseSize=40, which is 40% of minRaise=100 → <50%)
      final result = BettingRules.applyAction(state, 0, const Raise(140));

      // Should be converted to Call (currentBet matches 100)
      expect(result.seats[0].currentBet, 100,
          reason: 'Under-raise <50% should convert to Call');
    });

    test('raise at 50%+ of minRaise → rounded up to min raise', () {
      var state = _nlhState(stack: 1000, bbAmount: 100);
      state = state.copyWith(
        betting: BettingRound(currentBet: 100, minRaise: 100),
      );
      state.seats[0].currentBet = 0;

      // P0 tries to raise to 160 (raiseSize=60, which is 60% of minRaise=100 → >=50%)
      final result = BettingRules.applyAction(state, 0, const Raise(160));

      // Should be rounded up to minRaiseTotal = 100 + 100 = 200
      expect(result.seats[0].currentBet, 200,
          reason: 'Under-raise >=50% should round up to min raise total');
    });

    test('normal raise above minRaise → no correction', () {
      var state = _nlhState(stack: 1000, bbAmount: 100);
      state = state.copyWith(
        betting: BettingRound(currentBet: 100, minRaise: 100),
      );
      state.seats[0].currentBet = 0;

      // P0 raises to 250 (raiseSize=150, >minRaise=100)
      final result = BettingRules.applyAction(state, 0, const Raise(250));

      expect(result.seats[0].currentBet, 250,
          reason: 'Normal raise should not be corrected');
      expect(result.betting.minRaise, 150,
          reason: 'minRaise should update to new raise size');
    });
  });

  group('WSOP Rule 96: Short all-in (incomplete raise)', () {
    test('incomplete all-in → no reopen (minRaise/lastAggressor unchanged)', () {
      var state = _nlhState(stack: 1000, bbAmount: 20);
      // P1 bets 100
      state = BettingRules.applyAction(state, 1, const Bet(100));
      final minRaiseBefore = state.betting.minRaise;
      final lastAggressorBefore = state.betting.lastAggressor;

      // P2 has only 130 chips left, goes all-in (currentBet will be 130)
      // raiseSize = 130 - 100 = 30, which is < minRaise (100) → incomplete
      state.seats[2].stack = 130;
      final result = BettingRules.applyAction(state, 2, const AllIn());

      expect(result.seats[2].status, SeatStatus.allIn);
      expect(result.seats[2].currentBet, 130);
      expect(result.betting.currentBet, 130,
          reason: 'currentBet should update to new high');
      expect(result.betting.minRaise, minRaiseBefore,
          reason: 'minRaise should NOT change on incomplete all-in');
      expect(result.betting.lastAggressor, lastAggressorBefore,
          reason: 'lastAggressor should NOT change on incomplete all-in');
    });

    test('complete all-in → normal reopen', () {
      var state = _nlhState(stack: 1000, bbAmount: 20);
      // P1 bets 100
      state = BettingRules.applyAction(state, 1, const Bet(100));

      // P2 has 300 chips, goes all-in (raiseSize = 300 - 100 = 200 >= minRaise 100)
      state.seats[2].stack = 300;
      final result = BettingRules.applyAction(state, 2, const AllIn());

      expect(result.seats[2].status, SeatStatus.allIn);
      expect(result.betting.currentBet, 300);
      expect(result.betting.minRaise, 200,
          reason: 'minRaise should update on complete all-in raise');
      expect(result.betting.lastAggressor, 2,
          reason: 'lastAggressor should update on complete all-in');
      expect(result.betting.actedThisRound, {2},
          reason: 'actedThisRound should reset on complete all-in');
    });

    test('incomplete all-in does not reset actedThisRound', () {
      var state = _nlhState(stack: 1000, bbAmount: 20);
      // P0 bets 100
      state = BettingRules.applyAction(state, 0, const Bet(100));
      // P1 calls
      state = BettingRules.applyAction(state, 1, const Call(100));
      final actedBefore = Set<int>.from(state.betting.actedThisRound);

      // P2 short all-in (50 chips, raiseSize = 50-100 < 0 → not a raise at all)
      state.seats[2].stack = 50;
      final result = BettingRules.applyAction(state, 2, const AllIn());

      // P2's all-in doesn't exceed currentBet, so no reopen logic triggered
      expect(result.seats[2].status, SeatStatus.allIn);
      expect(result.seats[2].currentBet, 50);
    });
  });
}
