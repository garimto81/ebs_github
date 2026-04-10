import 'package:test/test.dart';
import 'package:ebs_game_engine/core/rules/betting_rules.dart';
import 'package:ebs_game_engine/core/state/game_state.dart';
import 'package:ebs_game_engine/core/state/seat.dart';
import 'package:ebs_game_engine/core/state/betting_round.dart';
import 'package:ebs_game_engine/core/cards/deck.dart';
import 'package:ebs_game_engine/core/actions/action.dart';

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
  Street street = Street.preflop,
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
    betting: BettingRound(
      currentBet: currentBet,
      minRaise: minRaise,
      lastAggressor: lastAggressor,
      actedThisRound: actedThisRound ?? {},
      bbOptionPending: bbOptionPending,
    ),
  );
}

Seat _seat(int i, {int stack = 1000, int currentBet = 0, SeatStatus status = SeatStatus.active}) {
  return Seat(index: i, label: 'P$i', stack: stack, currentBet: currentBet, status: status);
}

void main() {
  group('BettingRules.legalActions', () {
    test('can fold/call/raise when facing a bet', () {
      final state = _makeState(
        seats: [
          _seat(0, stack: 980, currentBet: 20), // SB posted 20
          _seat(1, stack: 960, currentBet: 40), // BB posted, someone raised to 40
          _seat(2, stack: 1000), // hero
        ],
        actionOn: 2,
        currentBet: 40,
        minRaise: 20,
        bbAmount: 20,
      );
      final actions = BettingRules.legalActions(state);
      final types = actions.map((a) => a.type).toSet();
      expect(types, contains('fold'));
      expect(types, contains('call'));
      expect(types, contains('raise'));
      expect(types.contains('check'), isFalse);

      final call = actions.firstWhere((a) => a.type == 'call');
      expect(call.callAmount, 40);

      final raise = actions.firstWhere((a) => a.type == 'raise');
      expect(raise.minAmount, 60); // currentBet 40 + minRaise 20
      expect(raise.maxAmount, 1000); // stack + currentBet (0 + 1000)
    });

    test('can check when no bet', () {
      final state = _makeState(
        seats: [_seat(0), _seat(1)],
        actionOn: 0,
        currentBet: 0,
        minRaise: 20,
        bbAmount: 20,
        street: Street.flop,
      );
      final actions = BettingRules.legalActions(state);
      final types = actions.map((a) => a.type).toSet();
      expect(types, contains('fold'));
      expect(types, contains('check'));
      expect(types, contains('bet'));
      expect(types.contains('call'), isFalse);

      final bet = actions.firstWhere((a) => a.type == 'bet');
      expect(bet.minAmount, 20); // BB
      expect(bet.maxAmount, 1000);
    });

    test('all-in when stack < call amount (no raise available)', () {
      final state = _makeState(
        seats: [
          _seat(0, stack: 15), // hero with short stack
          _seat(1, stack: 950, currentBet: 50),
        ],
        actionOn: 0,
        currentBet: 50,
        minRaise: 30,
        bbAmount: 20,
      );
      final actions = BettingRules.legalActions(state);
      final types = actions.map((a) => a.type).toSet();
      expect(types, contains('fold'));
      expect(types, contains('call')); // all-in call
      expect(types.contains('raise'), isFalse); // can't raise with less than call

      final call = actions.firstWhere((a) => a.type == 'call');
      expect(call.callAmount, 15); // min(50, 15) = 15 (all-in)
    });

    test('minRaise tracks after re-raise', () {
      // Bet 20, raise to 50 (raise size = 30), re-raise min = 50 + 30 = 80
      final state = _makeState(
        seats: [
          _seat(0, stack: 950, currentBet: 50), // original raiser
          _seat(1, stack: 1000),                 // hero
        ],
        actionOn: 1,
        currentBet: 50,
        minRaise: 30, // raise size was 30 (from 20 to 50)
        bbAmount: 20,
      );
      final actions = BettingRules.legalActions(state);
      final raise = actions.firstWhere((a) => a.type == 'raise');
      expect(raise.minAmount, 80); // 50 + 30
    });

    test('BB option: can check preflop when limped to', () {
      final state = _makeState(
        seats: [
          _seat(0, stack: 980, currentBet: 20), // SB limped
          _seat(1, stack: 980, currentBet: 20), // BB
        ],
        actionOn: 1,
        currentBet: 20,
        minRaise: 20,
        bbAmount: 20,
        bbSeat: 1,
        bbOptionPending: true,
      );
      final actions = BettingRules.legalActions(state);
      final types = actions.map((a) => a.type).toSet();
      expect(types, contains('check')); // BB option
      expect(types, contains('raise'));
      expect(types.contains('call'), isFalse);
    });
  });

  group('BettingRules.applyAction', () {
    test('fold sets status to folded', () {
      final state = _makeState(
        seats: [_seat(0), _seat(1)],
        actionOn: 0,
        currentBet: 20,
        minRaise: 20,
      );
      final next = BettingRules.applyAction(state, 0, const Fold());
      expect(next.seats[0].isFolded, isTrue);
      expect(next.betting.actedThisRound, contains(0));
    });

    test('call deducts amount from stack', () {
      final state = _makeState(
        seats: [_seat(0, stack: 1000), _seat(1, stack: 980, currentBet: 20)],
        actionOn: 0,
        currentBet: 20,
        minRaise: 20,
      );
      final next = BettingRules.applyAction(state, 0, const Call(20));
      expect(next.seats[0].stack, 980);
      expect(next.seats[0].currentBet, 20);
      expect(next.pot.main, 20);
    });

    test('bet deducts and sets currentBet', () {
      final state = _makeState(
        seats: [_seat(0, stack: 1000), _seat(1, stack: 1000)],
        actionOn: 0,
        currentBet: 0,
        minRaise: 20,
        street: Street.flop,
      );
      final next = BettingRules.applyAction(state, 0, const Bet(50));
      expect(next.seats[0].stack, 950);
      expect(next.seats[0].currentBet, 50);
      expect(next.betting.currentBet, 50);
      expect(next.betting.minRaise, 50);
      expect(next.betting.lastAggressor, 0);
    });

    test('raise deducts increment and updates betting', () {
      final state = _makeState(
        seats: [
          _seat(0, stack: 980, currentBet: 20),
          _seat(1, stack: 1000),
        ],
        actionOn: 1,
        currentBet: 20,
        minRaise: 20,
      );
      final next = BettingRules.applyAction(state, 1, const Raise(60));
      expect(next.seats[1].stack, 940); // 1000 - 60
      expect(next.seats[1].currentBet, 60);
      expect(next.betting.currentBet, 60);
      expect(next.betting.minRaise, 40); // raise size = 60 - 20 = 40
      expect(next.betting.lastAggressor, 1);
    });

    test('all-in deducts entire stack', () {
      final state = _makeState(
        seats: [
          _seat(0, stack: 150),
          _seat(1, stack: 980, currentBet: 20),
        ],
        actionOn: 0,
        currentBet: 20,
        minRaise: 20,
      );
      final next = BettingRules.applyAction(state, 0, const AllIn(150));
      expect(next.seats[0].stack, 0);
      expect(next.seats[0].isAllIn, isTrue);
      expect(next.seats[0].currentBet, 150);
      expect(next.pot.main, 150);
      expect(next.betting.currentBet, 150);
      expect(next.betting.lastAggressor, 0);
    });
  });

  group('BettingRules.isRoundComplete', () {
    test('true when only 1 active player (all others folded)', () {
      final state = _makeState(
        seats: [
          _seat(0),
          _seat(1, status: SeatStatus.folded),
          _seat(2, status: SeatStatus.folded),
        ],
        currentBet: 20,
      );
      expect(BettingRules.isRoundComplete(state), isTrue);
    });

    test('true when all active have acted and matched current bet', () {
      final state = _makeState(
        seats: [
          _seat(0, stack: 980, currentBet: 20),
          _seat(1, stack: 980, currentBet: 20),
        ],
        currentBet: 20,
        actedThisRound: {0, 1},
        bbOptionPending: false,
      );
      expect(BettingRules.isRoundComplete(state), isTrue);
    });

    test('false when player has not acted', () {
      final state = _makeState(
        seats: [
          _seat(0, stack: 980, currentBet: 20),
          _seat(1, stack: 1000),
        ],
        currentBet: 20,
        actedThisRound: {0},
      );
      expect(BettingRules.isRoundComplete(state), isFalse);
    });

    test('false when BB option is pending', () {
      final state = _makeState(
        seats: [
          _seat(0, stack: 980, currentBet: 20),
          _seat(1, stack: 980, currentBet: 20),
        ],
        currentBet: 20,
        actedThisRound: {0},
        bbOptionPending: true,
        bbSeat: 1,
      );
      expect(BettingRules.isRoundComplete(state), isFalse);
    });

    test('false when 1 active + 2 allIn and active has NOT acted', () {
      final state = _makeState(
        seats: [
          _seat(0, currentBet: 200, status: SeatStatus.allIn),
          _seat(1, stack: 980, currentBet: 20),
          _seat(2, currentBet: 200, status: SeatStatus.allIn),
        ],
        currentBet: 200,
        actedThisRound: {0, 2},
      );
      expect(BettingRules.isRoundComplete(state), isFalse);
    });

    test('true when 1 active + 2 allIn and active HAS acted and matched bet', () {
      final state = _makeState(
        seats: [
          _seat(0, currentBet: 200, status: SeatStatus.allIn),
          _seat(1, stack: 800, currentBet: 200),
          _seat(2, currentBet: 200, status: SeatStatus.allIn),
        ],
        currentBet: 200,
        actedThisRound: {0, 1, 2},
      );
      expect(BettingRules.isRoundComplete(state), isTrue);
    });

    test('false when 1 active + 1 allIn and active has NOT acted', () {
      final state = _makeState(
        seats: [
          _seat(0, currentBet: 500, status: SeatStatus.allIn),
          _seat(1, stack: 980, currentBet: 20),
        ],
        currentBet: 500,
        actedThisRound: {0},
      );
      expect(BettingRules.isRoundComplete(state), isFalse);
    });

    test('true when 1 active + 1 allIn and active called', () {
      final state = _makeState(
        seats: [
          _seat(0, currentBet: 500, status: SeatStatus.allIn),
          _seat(1, stack: 500, currentBet: 500),
        ],
        currentBet: 500,
        actedThisRound: {0, 1},
      );
      expect(BettingRules.isRoundComplete(state), isTrue);
    });

    test('false when BB option pending with BB active and others allIn', () {
      final state = _makeState(
        seats: [
          _seat(0, currentBet: 20, status: SeatStatus.allIn),
          _seat(1, stack: 980, currentBet: 20),
          _seat(2, currentBet: 20, status: SeatStatus.allIn),
        ],
        currentBet: 20,
        actedThisRound: {0, 2},
        bbOptionPending: true,
        bbSeat: 1,
      );
      expect(BettingRules.isRoundComplete(state), isFalse);
    });
  });
}
