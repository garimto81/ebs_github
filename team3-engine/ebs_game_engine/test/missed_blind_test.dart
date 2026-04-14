import 'package:test/test.dart';
import 'package:ebs_game_engine/engine.dart';

Seat _seat(int i, {int stack = 1000, SeatStatus status = SeatStatus.active}) {
  return Seat(index: i, label: 'P$i', stack: stack, status: status);
}

GameState _makeState({required List<Seat> seats, int dealerSeat = 0}) {
  return GameState(
    sessionId: 'test',
    variantName: 'nlh',
    seats: seats,
    deck: Deck.standard(),
    dealerSeat: dealerSeat,
  );
}

void main() {
  group('Missed Blind', () {
    test('TC1: SB position sit-out sets missedSb=true', () {
      // 3 players: dealer=0, SB position=1(sittingOut), BB position=2
      final seats = [
        _seat(0),
        _seat(1, status: SeatStatus.sittingOut),
        _seat(2),
      ];
      final state = _makeState(seats: seats, dealerSeat: 0);

      final result = Engine.applyFull(state, HandStart(
        dealerSeat: 0,
        blinds: {2: 10}, // only BB posts (seat 1 is sittingOut)
      ));

      // Seat 1 should have missedSb flagged
      expect(result.state.seats[1].missedSb, isTrue);
    });

    test('TC2: BB position sit-out sets missedBb=true', () {
      // 4 players: dealer=0, SB=1(active), BB=2(sittingOut), seat3(active)
      final seats = [
        _seat(0),
        _seat(1),
        _seat(2, status: SeatStatus.sittingOut),
        _seat(3),
      ];
      final state = _makeState(seats: seats, dealerSeat: 0);

      final result = Engine.applyFull(state, HandStart(
        dealerSeat: 0,
        blinds: {1: 5, 3: 10}, // SB=seat1, BB skips seat2 to seat3
      ));

      // Seat 2 should have missedBb flagged
      expect(result.state.seats[2].missedBb, isTrue);
    });

    test('TC3: returning player with missedBb posts dead+live blind', () {
      // dealer=0, active seats after dealer: [1,2,3]
      // SB=seat1(5), BB=seat2(10), seat3 has missedBb
      final seats = [
        _seat(0),
        _seat(1),
        _seat(2),
        Seat(
          index: 3,
          label: 'P3',
          stack: 1000,
          status: SeatStatus.active,
          missedBb: true,
        ),
      ];
      final state = _makeState(seats: seats, dealerSeat: 0);

      final result = Engine.applyFull(state, HandStart(
        dealerSeat: 0,
        blinds: {1: 5, 2: 10},
      ));

      // Seat 3 should have posted: dead blind (SB=5) + live blind (BB=10) = 15 total
      // Stack should be 1000 - 15 = 985
      expect(result.state.seats[3].stack, 985);
      // Flags should be reset
      expect(result.state.seats[3].missedBb, isFalse);
      expect(result.state.seats[3].missedSb, isFalse);
    });

    test('TC4: returning player with missedSb only posts dead blind', () {
      // dealer=0, active seats after dealer: [1,2,3]
      // SB=seat1(5), BB=seat2(10), seat3 has missedSb
      final seats = [
        _seat(0),
        _seat(1),
        _seat(2),
        Seat(
          index: 3,
          label: 'P3',
          stack: 1000,
          status: SeatStatus.active,
          missedSb: true,
        ),
      ];
      final state = _makeState(seats: seats, dealerSeat: 0);

      final result = Engine.applyFull(state, HandStart(
        dealerSeat: 0,
        blinds: {1: 5, 2: 10},
      ));

      // Seat 3 should have posted dead blind (SB amount=5) only
      // Stack should be 1000 - 5 = 995
      expect(result.state.seats[3].stack, 995);
      expect(result.state.seats[3].missedSb, isFalse);
    });

    test('TC5: Seat copy preserves missed blind flags', () {
      final seat = Seat(
        index: 0,
        label: 'P0',
        stack: 1000,
        missedSb: true,
        missedBb: true,
      );
      final copied = seat.copy();
      expect(copied.missedSb, isTrue);
      expect(copied.missedBb, isTrue);
    });
  });
}
