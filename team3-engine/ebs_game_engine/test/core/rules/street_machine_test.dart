import 'package:test/test.dart';
import 'package:ebs_game_engine/core/rules/street_machine.dart';
import 'package:ebs_game_engine/core/state/game_state.dart';
import 'package:ebs_game_engine/core/state/seat.dart';
import 'package:ebs_game_engine/core/state/betting_round.dart';
import 'package:ebs_game_engine/core/cards/deck.dart';

GameState _makeState({
  required List<Seat> seats,
  int dealerSeat = 0,
  int actionOn = -1,
  Street street = Street.preflop,
  int bbSeat = 1,
  int sbSeat = 0,
  int bbAmount = 20,
}) {
  return GameState(
    sessionId: 'test',
    variantName: 'nlh',
    seats: seats,
    deck: Deck.standard(seed: 1),
    dealerSeat: dealerSeat,
    actionOn: actionOn,
    street: street,
    bbSeat: bbSeat,
    sbSeat: sbSeat,
    bbAmount: bbAmount,
    handInProgress: true,
    betting: BettingRound(currentBet: 0, minRaise: bbAmount),
  );
}

Seat _seat(int i, {int stack = 1000, SeatStatus status = SeatStatus.active}) {
  return Seat(index: i, label: 'P$i', stack: stack, status: status);
}

void main() {
  group('StreetMachine.nextStreet', () {
    test('transitions preflop→flop→turn→river→showdown', () {
      expect(StreetMachine.nextStreet(Street.preflop), Street.flop);
      expect(StreetMachine.nextStreet(Street.flop), Street.turn);
      expect(StreetMachine.nextStreet(Street.turn), Street.river);
      expect(StreetMachine.nextStreet(Street.river), Street.showdown);
    });

    test('showdown transitions to handComplete', () {
      expect(StreetMachine.nextStreet(Street.showdown), Street.handComplete);
    });

    test('handComplete throws', () {
      expect(() => StreetMachine.nextStreet(Street.handComplete), throwsStateError);
    });
  });

  group('StreetMachine.communityCardsToDeal', () {
    test('flop=3, turn=1, river=1', () {
      expect(StreetMachine.communityCardsToDeal(Street.flop), 3);
      expect(StreetMachine.communityCardsToDeal(Street.turn), 1);
      expect(StreetMachine.communityCardsToDeal(Street.river), 1);
    });

    test('preflop and showdown return 0', () {
      expect(StreetMachine.communityCardsToDeal(Street.preflop), 0);
      expect(StreetMachine.communityCardsToDeal(Street.showdown), 0);
    });
  });

  group('StreetMachine.firstToAct', () {
    test('postflop: SB acts first (per BS-06-10:82-86)', () {
      // Dealer=0, SB=1, all active → SB (seat 1) acts first
      final state = _makeState(
        seats: [_seat(0), _seat(1), _seat(2)],
        dealerSeat: 0,
        sbSeat: 1,
        street: Street.flop,
      );
      expect(StreetMachine.firstToAct(state), 1);
    });

    test('postflop: skips folded SB, next active acts', () {
      // Dealer=0, SB=1 folded → next active = seat 2
      final state = _makeState(
        seats: [_seat(0), _seat(1, status: SeatStatus.folded), _seat(2)],
        dealerSeat: 0,
        sbSeat: 1,
        street: Street.flop,
      );
      expect(StreetMachine.firstToAct(state), 2);
    });

    test('preflop: UTG (after BB)', () {
      // 3 players: dealer=0, SB=1, BB=2 → UTG = seat 0
      final state = _makeState(
        seats: [_seat(0), _seat(1), _seat(2)],
        dealerSeat: 0,
        bbSeat: 2,
        sbSeat: 1,
        street: Street.preflop,
      );
      expect(StreetMachine.firstToAct(state), 0);
    });

    test('heads-up preflop: BTN/SB acts first', () {
      // 2 players: dealer=0 (also SB), BB=1 → preflop first = seat 0 (SB/BTN)
      final state = _makeState(
        seats: [_seat(0), _seat(1)],
        dealerSeat: 0,
        sbSeat: 0,
        bbSeat: 1,
        street: Street.preflop,
      );
      expect(StreetMachine.firstToAct(state), 0);
    });

    test('postflop: skips allIn SB, next active acts', () {
      // Dealer=0, SB=1 allIn → first actionable = seat 2
      final state = _makeState(
        seats: [_seat(0), _seat(1, status: SeatStatus.allIn), _seat(2)],
        dealerSeat: 0,
        sbSeat: 1,
        street: Street.flop,
      );
      expect(StreetMachine.firstToAct(state), 2);
    });
  });

  group('StreetMachine.nextToAct', () {
    test('wraps around to find next active seat', () {
      final state = _makeState(
        seats: [_seat(0), _seat(1, status: SeatStatus.folded), _seat(2)],
        actionOn: 0,
        street: Street.flop,
      );
      expect(StreetMachine.nextToAct(state), 2);
    });

    test('wraps past end of seats list', () {
      final state = _makeState(
        seats: [_seat(0), _seat(1), _seat(2)],
        actionOn: 2,
        street: Street.flop,
      );
      expect(StreetMachine.nextToAct(state), 0);
    });
  });

  group('StreetMachine.advanceStreet', () {
    test('resets betting round and sets firstToAct', () {
      final state = _makeState(
        seats: [
          _seat(0)..currentBet = 20,
          _seat(1)..currentBet = 20,
          _seat(2),
        ],
        dealerSeat: 0,
        street: Street.preflop,
      );
      final next = StreetMachine.advanceStreet(state);
      expect(next.street, Street.flop);
      expect(next.betting.currentBet, 0);
      expect(next.betting.actedThisRound, isEmpty);
      expect(next.betting.bbOptionPending, isFalse);
      // All seat currentBets reset
      for (final s in next.seats) {
        expect(s.currentBet, 0);
      }
      // firstToAct should be seat 0 (SB, per BS-06-10:82-86. sbSeat defaults to 0)
      expect(next.actionOn, 0);
    });
  });
}
