import 'package:ebs_game_engine/engine.dart';
import 'package:test/test.dart';

GameState _makeState({
  required List<Seat> seats,
  int actionOn = 0,
  int currentBet = 0,
  int minRaise = 0,
  int lastAggressor = -1,
  Set<int>? actedThisRound,
  bool bbOptionPending = false,
  int bbAmount = 20,
  int bbSeat = 1,
  int raiseCount = 0,
  Street street = Street.preflop,
  BetLimit? betLimit,
}) {
  return GameState(
    sessionId: 'test',
    variantName: 'nlh',
    seats: seats,
    deck: Deck.standard(seed: 1),
    actionOn: actionOn,
    bbAmount: bbAmount,
    bbSeat: bbSeat,
    street: street,
    handInProgress: true,
    betLimit: betLimit,
    betting: BettingRound(
      currentBet: currentBet,
      minRaise: minRaise,
      lastAggressor: lastAggressor,
      actedThisRound: actedThisRound ?? {},
      bbOptionPending: bbOptionPending,
      raiseCount: raiseCount,
    ),
  );
}

Seat _seat(int i,
    {int stack = 1000,
    int currentBet = 0,
    SeatStatus status = SeatStatus.active}) {
  return Seat(
      index: i, label: 'P$i', stack: stack, currentBet: currentBet,
      status: status);
}

void main() {
  group('Fixed Limit legalActions', () {
    final fl = FixedLimitBet(smallBet: 10, bigBet: 20);

    test('bet amount is exactly smallBet on flop', () {
      final state = _makeState(
        seats: [_seat(0, stack: 500), _seat(1, stack: 500)],
        actionOn: 0,
        currentBet: 0,
        minRaise: 10,
        bbAmount: 10,
        street: Street.flop,
        betLimit: fl,
      );
      final actions = BettingRules.legalActions(state);
      final bet = actions.firstWhere((a) => a.type == 'bet');
      expect(bet.minAmount, 10);
      expect(bet.maxAmount, 10);
    });

    test('raise cap of 4 enforced (no raise after 4 bets/raises)', () {
      final state = _makeState(
        seats: [
          _seat(0, stack: 460, currentBet: 40),
          _seat(1, stack: 460, currentBet: 40),
          _seat(2, stack: 1000),
        ],
        actionOn: 2,
        currentBet: 40,
        minRaise: 10,
        bbAmount: 10,
        street: Street.flop,
        betLimit: fl,
        raiseCount: 4,
      );
      final actions = BettingRules.legalActions(state);
      final types = actions.map((a) => a.type).toSet();
      expect(types.contains('raise'), isFalse,
          reason: 'Raise should not be available after 4 raises');
      expect(types, contains('call'));
      expect(types, contains('fold'));
    });

    test('heads-up ignores raise cap', () {
      final state = _makeState(
        seats: [
          _seat(0, stack: 460, currentBet: 40),
          _seat(1, stack: 1000),
        ],
        actionOn: 1,
        currentBet: 40,
        minRaise: 10,
        bbAmount: 10,
        street: Street.flop,
        betLimit: fl,
        raiseCount: 4,
      );
      final actions = BettingRules.legalActions(state);
      final types = actions.map((a) => a.type).toSet();
      expect(types, contains('raise'),
          reason: 'Heads-up should ignore raise cap');
    });
  });

  group('Pot Limit legalActions', () {
    final pl = PotLimitBet();

    test('max raise is pot-sized', () {
      final state = _makeState(
        seats: [_seat(0, stack: 500), _seat(1, stack: 500)],
        actionOn: 0,
        currentBet: 0,
        minRaise: 20,
        bbAmount: 20,
        street: Street.flop,
        betLimit: pl,
      );
      // Set pot to have some value
      state.pot.main = 100;

      final actions = BettingRules.legalActions(state);
      final bet = actions.firstWhere((a) => a.type == 'bet');
      expect(bet.minAmount, 20); // BB
      expect(bet.maxAmount, 100); // pot size
    });
  });

  group('No Limit regression', () {
    test('NL max bet is full stack', () {
      final state = _makeState(
        seats: [_seat(0, stack: 500), _seat(1, stack: 500)],
        actionOn: 0,
        currentBet: 0,
        minRaise: 20,
        bbAmount: 20,
        street: Street.flop,
        betLimit: const NoLimitBet(),
      );
      final actions = BettingRules.legalActions(state);
      final bet = actions.firstWhere((a) => a.type == 'bet');
      expect(bet.minAmount, 20);
      expect(bet.maxAmount, 500); // full stack
    });
  });
}
