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
  group('Dead Button Rule', () {
    test('TC1: dealer sittingOut - SB/BB assigned to next active seats', () {
      // 4 seats: dealer=0(sittingOut), seat1(active), seat2(active), seat3(active)
      final seats = [
        _seat(0, status: SeatStatus.sittingOut),
        _seat(1),
        _seat(2),
        _seat(3),
      ];
      final state = _makeState(seats: seats, dealerSeat: 0);

      // SB should be seat 1 (first active after dealer)
      // BB should be seat 2 (second active after dealer)
      final result = Engine.applyFull(state, HandStart(
        dealerSeat: 0,
        blinds: {1: 5, 2: 10},
      ));

      expect(result.state.sbSeat, 1);
      expect(result.state.bbSeat, 2);
    });

    test('TC2: dealer+SB both sittingOut - BB correctly assigned', () {
      // 4 seats: dealer=0(sittingOut), seat1(sittingOut), seat2(active), seat3(active)
      final seats = [
        _seat(0, status: SeatStatus.sittingOut),
        _seat(1, status: SeatStatus.sittingOut),
        _seat(2),
        _seat(3),
      ];
      final state = _makeState(seats: seats, dealerSeat: 0);

      // First active after dealer is seat 2 (SB), then seat 3 (BB)
      final result = Engine.applyFull(state, HandStart(
        dealerSeat: 0,
        blinds: {2: 5, 3: 10},
      ));

      expect(result.state.sbSeat, 2);
      expect(result.state.bbSeat, 3);
    });

    test('TC3: only 2 active players among many - heads-up like behavior', () {
      // 6 seats: only seat 2 and seat 5 are active, dealer=0(sittingOut)
      final seats = [
        _seat(0, status: SeatStatus.sittingOut),
        _seat(1, status: SeatStatus.sittingOut),
        _seat(2),
        _seat(3, status: SeatStatus.sittingOut),
        _seat(4, status: SeatStatus.sittingOut),
        _seat(5),
      ];
      final state = _makeState(seats: seats, dealerSeat: 0);

      // Active seats from dealer+1: seat 2 (SB), seat 5 (BB)
      final result = Engine.applyFull(state, HandStart(
        dealerSeat: 0,
        blinds: {2: 5, 5: 10},
      ));

      expect(result.state.sbSeat, 2);
      expect(result.state.bbSeat, 5);
      // Hand should be in progress
      expect(result.state.handInProgress, isTrue);
    });

    test('TC4: dead button - sittingOut seats get missed blind flags', () {
      // dealer=0(sittingOut), SB position=1(sittingOut), BB position=2(active)
      final seats = [
        _seat(0, status: SeatStatus.sittingOut),
        _seat(1, status: SeatStatus.sittingOut),
        _seat(2),
        _seat(3),
      ];
      final state = _makeState(seats: seats, dealerSeat: 0);

      final result = Engine.applyFull(state, HandStart(
        dealerSeat: 0,
        blinds: {2: 5, 3: 10},
      ));

      // Seat 1 was in SB position and sittingOut → missedSb
      expect(result.state.seats[1].missedSb, isTrue);
    });
  });
}
