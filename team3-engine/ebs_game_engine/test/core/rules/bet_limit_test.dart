import 'package:test/test.dart';
import 'package:ebs_game_engine/core/state/game_state.dart';
import 'package:ebs_game_engine/core/state/seat.dart';
import 'package:ebs_game_engine/core/state/pot.dart';
import 'package:ebs_game_engine/core/state/betting_round.dart';
import 'package:ebs_game_engine/core/cards/deck.dart';
import 'package:ebs_game_engine/core/rules/bet_limit.dart';
import 'package:ebs_game_engine/core/rules/no_limit.dart';
import 'package:ebs_game_engine/core/rules/pot_limit.dart';
import 'package:ebs_game_engine/core/rules/fixed_limit.dart';
import 'package:ebs_game_engine/core/rules/spread_limit.dart';

// ── Test helpers ──

GameState _makeState({
  required List<Seat> seats,
  int actionOn = 0,
  int currentBet = 0,
  int minRaise = 0,
  int potMain = 0,
  List<int> sidePotAmounts = const [],
  int bbAmount = 20,
  Street street = Street.preflop,
}) {
  final pot = Pot(main: potMain);
  for (final amount in sidePotAmounts) {
    pot.sides.add(SidePot(amount, const {}));
  }
  return GameState(
    sessionId: 'test',
    variantName: 'nlh',
    seats: seats,
    deck: Deck.standard(seed: 42),
    street: street,
    actionOn: actionOn,
    bbAmount: bbAmount,
    pot: pot,
    betting: BettingRound(
      currentBet: currentBet,
      minRaise: minRaise > 0 ? minRaise : bbAmount,
    ),
  );
}

Seat _seat(int i, {int stack = 1000, int currentBet = 0}) {
  return Seat(index: i, label: 'P$i', stack: stack, currentBet: currentBet);
}

void main() {
  // ════════════════════════════════════════════════════════════════════
  // NoLimitBet
  // ════════════════════════════════════════════════════════════════════
  group('NoLimitBet', () {
    const nl = NoLimitBet();

    test('name is "No Limit"', () {
      expect(nl.name, 'No Limit');
    });

    test('raiseCap is null (unlimited)', () {
      expect(nl.raiseCap, isNull);
    });

    test('minBet equals BB amount', () {
      final state = _makeState(
        seats: [_seat(0), _seat(1)],
        bbAmount: 20,
      );
      expect(nl.minBet(state), 20);
    });

    test('minBet with different BB amount', () {
      final state = _makeState(
        seats: [_seat(0), _seat(1)],
        bbAmount: 50,
      );
      expect(nl.minBet(state), 50);
    });

    test('minBet capped at stack when stack < BB', () {
      final state = _makeState(
        seats: [_seat(0, stack: 10), _seat(1)],
        bbAmount: 20,
      );
      expect(nl.minBet(state), 10);
    });

    test('maxBet equals full stack', () {
      final state = _makeState(
        seats: [_seat(0, stack: 1000), _seat(1)],
      );
      expect(nl.maxBet(state, 0), 1000);
    });

    test('maxBet for different seat', () {
      final state = _makeState(
        seats: [_seat(0, stack: 500), _seat(1, stack: 2000)],
      );
      expect(nl.maxBet(state, 1), 2000);
    });

    test('maxBet with small stack', () {
      final state = _makeState(
        seats: [_seat(0, stack: 5), _seat(1)],
      );
      expect(nl.maxBet(state, 0), 5);
    });

    test('minRaiseTo equals currentBet + minRaise', () {
      final state = _makeState(
        seats: [_seat(0), _seat(1)],
        currentBet: 40,
        minRaise: 20,
      );
      expect(nl.minRaiseTo(state), 60);
    });

    test('minRaiseTo preflop with BB as minRaise', () {
      final state = _makeState(
        seats: [_seat(0), _seat(1)],
        currentBet: 20,
        bbAmount: 20,
      );
      // minRaise defaults to bbAmount (20)
      expect(nl.minRaiseTo(state), 40);
    });

    test('maxRaiseTo equals stack + seatBet', () {
      final state = _makeState(
        seats: [_seat(0, stack: 980, currentBet: 20), _seat(1)],
        currentBet: 40,
      );
      // stack(980) + currentBet(20) = 1000
      expect(nl.maxRaiseTo(state, 0), 1000);
    });

    test('maxRaiseTo with no prior bet', () {
      final state = _makeState(
        seats: [_seat(0, stack: 1000), _seat(1)],
      );
      expect(nl.maxRaiseTo(state, 0), 1000);
    });

    test('maxRaiseTo with short stack', () {
      final state = _makeState(
        seats: [_seat(0, stack: 50, currentBet: 20), _seat(1)],
        currentBet: 40,
      );
      // stack(50) + currentBet(20) = 70
      expect(nl.maxRaiseTo(state, 0), 70);
    });

    test('minBet with zero stack returns 0', () {
      final state = _makeState(
        seats: [_seat(0, stack: 0), _seat(1)],
        bbAmount: 20,
      );
      expect(nl.minBet(state), 0);
    });

    test('maxBet with zero stack returns 0', () {
      final state = _makeState(
        seats: [_seat(0, stack: 0), _seat(1)],
      );
      expect(nl.maxBet(state, 0), 0);
    });

    test('minRaiseTo after multiple raises', () {
      final state = _makeState(
        seats: [_seat(0), _seat(1)],
        currentBet: 100,
        minRaise: 40,
      );
      expect(nl.minRaiseTo(state), 140);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // PotLimitBet
  // ════════════════════════════════════════════════════════════════════
  group('PotLimitBet', () {
    const pl = PotLimitBet();

    test('name is "Pot Limit"', () {
      expect(pl.name, 'Pot Limit');
    });

    test('raiseCap is null (unlimited)', () {
      expect(pl.raiseCap, isNull);
    });

    test('minBet equals BB amount', () {
      final state = _makeState(
        seats: [_seat(0), _seat(1)],
        bbAmount: 20,
      );
      expect(pl.minBet(state), 20);
    });

    test('minBet capped at stack when stack < BB', () {
      final state = _makeState(
        seats: [_seat(0, stack: 10), _seat(1)],
        bbAmount: 20,
      );
      expect(pl.minBet(state), 10);
    });

    test('maxBet with empty pot and no bets equals 0', () {
      // pot = 0, no seat bets => total pot = 0
      final state = _makeState(
        seats: [_seat(0, stack: 1000), _seat(1)],
        potMain: 0,
      );
      expect(pl.maxBet(state, 0), 0);
    });

    test('maxBet with pot 100 and no current bets', () {
      final state = _makeState(
        seats: [_seat(0, stack: 1000), _seat(1)],
        potMain: 100,
      );
      // totalPot = 100 + 0 + 0 = 100
      expect(pl.maxBet(state, 0), 100);
    });

    test('maxBet includes seat current bets in pot', () {
      final state = _makeState(
        seats: [_seat(0, stack: 1000, currentBet: 20), _seat(1, currentBet: 40)],
        potMain: 0,
      );
      // totalPot = 0 + 0 + (20 + 40) = 60
      expect(pl.maxBet(state, 0), 60);
    });

    test('maxBet capped at stack', () {
      final state = _makeState(
        seats: [_seat(0, stack: 50), _seat(1)],
        potMain: 200,
      );
      expect(pl.maxBet(state, 0), 50);
    });

    test('maxBet with side pots contributing', () {
      final state = _makeState(
        seats: [_seat(0, stack: 1000), _seat(1)],
        potMain: 100,
        sidePotAmounts: [50, 30],
      );
      // totalPot = 100 + 50 + 30 + 0 = 180
      expect(pl.maxBet(state, 0), 180);
    });

    test('minRaiseTo equals currentBet + minRaise', () {
      final state = _makeState(
        seats: [_seat(0), _seat(1)],
        currentBet: 40,
        minRaise: 20,
      );
      expect(pl.minRaiseTo(state), 60);
    });

    test('maxRaiseTo with pot 100 facing bet 50', () {
      // Seat 0 has not yet put anything in; facing bet of 50
      // callAmount = 50 - 0 = 50
      // totalPot = 100 + 0 + (0 + 50) = 150 (pot + seat bets on table)
      // potAfterCall = 150 + 50 = 200
      // maxRaiseTo = 50 + 200 = 250
      final state = _makeState(
        seats: [_seat(0, stack: 1000), _seat(1, currentBet: 50)],
        potMain: 100,
        currentBet: 50,
        minRaise: 50,
      );
      expect(pl.maxRaiseTo(state, 0), 250);
    });

    test('maxRaiseTo with pot 200 and both players have bets', () {
      // Seat 0 has bet 20, seat 1 has bet 40, currentBet = 40
      // callAmount = 40 - 20 = 20
      // totalPot = 200 + 0 + (20 + 40) = 260
      // potAfterCall = 260 + 20 = 280
      // maxRaiseTo = 40 + 280 = 320
      final state = _makeState(
        seats: [
          _seat(0, stack: 980, currentBet: 20),
          _seat(1, stack: 960, currentBet: 40),
        ],
        potMain: 200,
        currentBet: 40,
        minRaise: 20,
      );
      expect(pl.maxRaiseTo(state, 0), 320);
    });

    test('maxRaiseTo capped at stack + seatBet', () {
      // Pot is huge but player is short-stacked
      final state = _makeState(
        seats: [_seat(0, stack: 30, currentBet: 20), _seat(1, currentBet: 50)],
        potMain: 500,
        currentBet: 50,
        minRaise: 30,
      );
      // stack(30) + seatBet(20) = 50
      expect(pl.maxRaiseTo(state, 0), 50);
    });

    test('maxRaiseTo with side pots included', () {
      // callAmount = 40 - 0 = 40
      // totalPot = 100 + 60 + (0 + 40) = 200
      // potAfterCall = 200 + 40 = 240
      // maxRaiseTo = 40 + 240 = 280
      final state = _makeState(
        seats: [_seat(0, stack: 1000), _seat(1, currentBet: 40)],
        potMain: 100,
        sidePotAmounts: [60],
        currentBet: 40,
        minRaise: 40,
      );
      expect(pl.maxRaiseTo(state, 0), 280);
    });

    test('maxRaiseTo with no prior bet (pot raise from zero)', () {
      // No current bet, pot = 100
      // callAmount = 0 - 0 = 0
      // totalPot = 100 + 0 + 0 = 100
      // potAfterCall = 100 + 0 = 100
      // maxRaiseTo = 0 + 100 = 100
      final state = _makeState(
        seats: [_seat(0, stack: 1000), _seat(1)],
        potMain: 100,
        currentBet: 0,
      );
      expect(pl.maxRaiseTo(state, 0), 100);
    });

    test('maxRaiseTo with multiple players contributing bets', () {
      // 3 players, seat 0 facing, seat 1 bet 50, seat 2 called 50
      // callAmount = 50 - 0 = 50
      // totalPot = 0 + 0 + (0 + 50 + 50) = 100
      // potAfterCall = 100 + 50 = 150
      // maxRaiseTo = 50 + 150 = 200
      final state = _makeState(
        seats: [
          _seat(0, stack: 1000),
          _seat(1, currentBet: 50),
          _seat(2, currentBet: 50),
        ],
        potMain: 0,
        currentBet: 50,
        minRaise: 50,
      );
      expect(pl.maxRaiseTo(state, 0), 200);
    });

    test('maxBet with large stack exceeding pot', () {
      final state = _makeState(
        seats: [_seat(0, stack: 10000), _seat(1)],
        potMain: 50,
      );
      // totalPot = 50 => maxBet = 50 (pot capped, not stack)
      expect(pl.maxBet(state, 0), 50);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // FixedLimitBet
  // ════════════════════════════════════════════════════════════════════
  group('FixedLimitBet', () {
    const fl24 = FixedLimitBet(smallBet: 2, bigBet: 4);
    const fl510 = FixedLimitBet(smallBet: 5, bigBet: 10);

    test('name is "Fixed Limit"', () {
      expect(fl24.name, 'Fixed Limit');
    });

    test('raiseCap is 4', () {
      expect(fl24.raiseCap, 4);
    });

    test('preflop minBet equals smallBet', () {
      final state = _makeState(
        seats: [_seat(0), _seat(1)],
        street: Street.preflop,
        bbAmount: 2,
      );
      expect(fl24.minBet(state), 2);
    });

    test('flop minBet equals smallBet', () {
      final state = _makeState(
        seats: [_seat(0), _seat(1)],
        street: Street.flop,
        bbAmount: 2,
      );
      expect(fl24.minBet(state), 2);
    });

    test('turn minBet equals bigBet', () {
      final state = _makeState(
        seats: [_seat(0), _seat(1)],
        street: Street.turn,
        bbAmount: 2,
      );
      expect(fl24.minBet(state), 4);
    });

    test('river minBet equals bigBet', () {
      final state = _makeState(
        seats: [_seat(0), _seat(1)],
        street: Street.river,
        bbAmount: 2,
      );
      expect(fl24.minBet(state), 4);
    });

    test('minBet equals maxBet (fixed size) preflop', () {
      final state = _makeState(
        seats: [_seat(0), _seat(1)],
        street: Street.preflop,
        bbAmount: 2,
        actionOn: 0,
      );
      expect(fl24.minBet(state), fl24.maxBet(state, 0));
    });

    test('minBet equals maxBet (fixed size) on turn', () {
      final state = _makeState(
        seats: [_seat(0), _seat(1)],
        street: Street.turn,
        bbAmount: 2,
        actionOn: 0,
      );
      expect(fl24.minBet(state), fl24.maxBet(state, 0));
    });

    test('minRaiseTo equals maxRaiseTo (fixed raise)', () {
      final state = _makeState(
        seats: [_seat(0), _seat(1)],
        currentBet: 2,
        minRaise: 2,
        street: Street.preflop,
      );
      expect(fl24.minRaiseTo(state), fl24.maxRaiseTo(state, 0));
    });

    test('minRaiseTo on preflop = currentBet + smallBet', () {
      final state = _makeState(
        seats: [_seat(0), _seat(1)],
        currentBet: 2,
        street: Street.preflop,
      );
      expect(fl24.minRaiseTo(state), 4);
    });

    test('minRaiseTo on turn = currentBet + bigBet', () {
      final state = _makeState(
        seats: [_seat(0), _seat(1)],
        currentBet: 4,
        street: Street.turn,
      );
      expect(fl24.minRaiseTo(state), 8);
    });

    test('minBet capped at stack when stack < bet size', () {
      final state = _makeState(
        seats: [_seat(0, stack: 1), _seat(1)],
        street: Street.preflop,
        bbAmount: 2,
      );
      expect(fl24.minBet(state), 1);
    });

    test('maxBet capped at stack when stack < bet size', () {
      final state = _makeState(
        seats: [_seat(0, stack: 3), _seat(1)],
        street: Street.turn,
        bbAmount: 2,
      );
      // bigBet = 4, but stack = 3
      expect(fl24.maxBet(state, 0), 3);
    });

    test('maxRaiseTo capped at stack + seatBet', () {
      final state = _makeState(
        seats: [_seat(0, stack: 1, currentBet: 2), _seat(1)],
        currentBet: 2,
        street: Street.preflop,
      );
      // raise to = 2 + 2 = 4, but stack(1) + seatBet(2) = 3
      expect(fl24.maxRaiseTo(state, 0), 3);
    });

    test('\$5/\$10 configuration preflop bet = 5', () {
      final state = _makeState(
        seats: [_seat(0), _seat(1)],
        street: Street.preflop,
        bbAmount: 5,
      );
      expect(fl510.minBet(state), 5);
    });

    test('\$5/\$10 configuration river bet = 10', () {
      final state = _makeState(
        seats: [_seat(0), _seat(1)],
        street: Street.river,
        bbAmount: 5,
      );
      expect(fl510.minBet(state), 10);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // SpreadLimitBet
  // ════════════════════════════════════════════════════════════════════
  group('SpreadLimitBet', () {
    const sl = SpreadLimitBet(lowLimit: 2, highLimit: 10);

    test('name is "Spread Limit"', () {
      expect(sl.name, 'Spread Limit');
    });

    test('raiseCap is null', () {
      expect(sl.raiseCap, isNull);
    });

    test('minBet equals lowLimit', () {
      final state = _makeState(
        seats: [_seat(0), _seat(1)],
        bbAmount: 2,
      );
      expect(sl.minBet(state), 2);
    });

    test('maxBet equals highLimit', () {
      final state = _makeState(
        seats: [_seat(0, stack: 1000), _seat(1)],
      );
      expect(sl.maxBet(state, 0), 10);
    });

    test('minBet capped at stack when stack < lowLimit', () {
      final state = _makeState(
        seats: [_seat(0, stack: 1), _seat(1)],
        bbAmount: 2,
      );
      expect(sl.minBet(state), 1);
    });

    test('maxBet capped at stack when stack < highLimit', () {
      final state = _makeState(
        seats: [_seat(0, stack: 5), _seat(1)],
      );
      expect(sl.maxBet(state, 0), 5);
    });

    test('minRaiseTo = currentBet + lowLimit', () {
      final state = _makeState(
        seats: [_seat(0), _seat(1)],
        currentBet: 10,
      );
      expect(sl.minRaiseTo(state), 12);
    });

    test('maxRaiseTo = currentBet + highLimit', () {
      final state = _makeState(
        seats: [_seat(0, stack: 1000), _seat(1)],
        currentBet: 10,
      );
      expect(sl.maxRaiseTo(state, 0), 20);
    });

    test('maxRaiseTo capped at stack + seatBet', () {
      final state = _makeState(
        seats: [_seat(0, stack: 5, currentBet: 10), _seat(1)],
        currentBet: 10,
      );
      // currentBet(10) + highLimit(10) = 20, but stack(5) + seatBet(10) = 15
      expect(sl.maxRaiseTo(state, 0), 15);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // Cross-strategy type checks
  // ════════════════════════════════════════════════════════════════════
  group('BetLimit type hierarchy', () {
    test('all implementations are BetLimit subtypes', () {
      expect(const NoLimitBet(), isA<BetLimit>());
      expect(const PotLimitBet(), isA<BetLimit>());
      expect(const FixedLimitBet(smallBet: 2, bigBet: 4), isA<BetLimit>());
      expect(const SpreadLimitBet(lowLimit: 1, highLimit: 5), isA<BetLimit>());
    });
  });
}
