import 'package:test/test.dart';
import 'package:ebs_game_engine/engine.dart';

void main() {
  group('MisDeal ante return', () {
    GameState _makeBaseState({
      int seatCount = 3,
      int stack = 1000,
      int? anteType,
      int? anteAmount,
    }) {
      return GameState(
        sessionId: 'test',
        variantName: 'nlh',
        seats: List.generate(
            seatCount,
            (i) => Seat(
                  index: i,
                  label: 'P$i',
                  stack: stack,
                )),
        deck: Deck.standard(seed: 42),
        anteType: anteType,
        anteAmount: anteAmount,
      );
    }

    test('standard ante (type 0) returned on misdeal', () {
      var state = _makeBaseState(anteType: 0, anteAmount: 5);
      // Start hand with dealer=0, SB=1(5), BB=2(10)
      state = Engine.apply(
          state,
          const HandStart(
            dealerSeat: 0,
            blinds: {1: 5, 2: 10},
          ));
      // Each player posted 5 ante + blinds for seats 1 and 2
      // Verify ante was deducted
      final stacksAfterStart = state.seats.map((s) => s.stack).toList();
      expect(stacksAfterStart.every((s) => s < 1000), isTrue,
          reason: 'Stacks should be reduced after antes+blinds');

      // Now trigger misdeal
      state = Engine.apply(state, const MisDeal());

      // All stacks should be restored to original 1000
      for (final seat in state.seats) {
        expect(seat.stack, 1000,
            reason: 'Seat ${seat.index} stack not restored');
      }
    });

    test('BB ante (type 2) returned on misdeal', () {
      var state = _makeBaseState(anteType: 2, anteAmount: 5);
      state = Engine.apply(
          state,
          const HandStart(
            dealerSeat: 0,
            blinds: {1: 5, 2: 10},
          ));

      state = Engine.apply(state, const MisDeal());

      for (final seat in state.seats) {
        expect(seat.stack, 1000,
            reason: 'Seat ${seat.index} stack not restored');
      }
    });

    test('ante + blinds all returned on misdeal', () {
      var state = _makeBaseState(seatCount: 4, anteType: 0, anteAmount: 10);
      state = Engine.apply(
          state,
          const HandStart(
            dealerSeat: 0,
            blinds: {1: 5, 2: 10},
          ));

      state = Engine.apply(state, const MisDeal());

      for (final seat in state.seats) {
        expect(seat.stack, 1000,
            reason:
                'Seat ${seat.index} stack not restored after ante+blind misdeal');
      }
    });
  });
}
