import 'package:test/test.dart';
import 'package:ebs_game_engine/engine.dart';

List<Card> _parseCards(List<String> notations) =>
    notations.map(Card.parse).toList();

GameState _makeShowdownState({
  int seatCount = 3,
  int dealerSeat = 0,
  int lastAggressor = -1,
  List<SeatStatus>? statuses,
  List<List<String>>? holeCards,
}) {
  final seats = List.generate(seatCount, (i) {
    final status = statuses != null ? statuses[i] : SeatStatus.active;
    final cards = holeCards != null ? _parseCards(holeCards[i]) : <Card>[];
    return Seat(
      index: i,
      label: 'P${i + 1}',
      stack: 1000,
      status: status,
      holeCards: cards,
    );
  });
  final state = GameState(
    sessionId: 'test',
    variantName: 'nlh',
    seats: seats,
    deck: Deck.standard(),
    dealerSeat: dealerSeat,
    street: Street.showdown,
  );
  state.betting.lastAggressor = lastAggressor;
  return state;
}

void main() {
  group('ShowdownOrder.canMuck', () {
    test('TC1: all-in player cannot muck', () {
      final state = _makeShowdownState(
        statuses: [SeatStatus.allIn, SeatStatus.active, SeatStatus.active],
        holeCards: [['As', 'Ks'], ['Qd', 'Qc'], ['Jh', 'Jd']],
      );

      final result = ShowdownOrder.canMuck(
        seatIndex: 0,
        state: state,
        isWinner: false,
      );
      expect(result, isFalse);
    });

    test('TC2: winner cannot muck', () {
      final state = _makeShowdownState(
        holeCards: [['As', 'Ks'], ['Qd', 'Qc'], ['Jh', 'Jd']],
      );

      final result = ShowdownOrder.canMuck(
        seatIndex: 0,
        state: state,
        isWinner: true,
      );
      expect(result, isFalse);
    });

    test('TC3: losing non-allIn player can muck', () {
      final state = _makeShowdownState(
        holeCards: [['As', 'Ks'], ['Qd', 'Qc'], ['Jh', 'Jd']],
      );

      final result = ShowdownOrder.canMuck(
        seatIndex: 2,
        state: state,
        isWinner: false,
      );
      expect(result, isTrue);
    });
  });

  group('ShowdownOrder.getRevealOrder', () {
    test('TC4: last aggressor reveals first', () {
      final state = _makeShowdownState(
        lastAggressor: 2,
        holeCards: [['As', 'Ks'], ['Qd', 'Qc'], ['Jh', 'Jd']],
      );

      final order = ShowdownOrder.getRevealOrder(state);
      expect(order.first, 2);
    });

    test('TC5: no aggressor - starts from dealer left', () {
      final state = _makeShowdownState(
        dealerSeat: 0,
        lastAggressor: -1,
        holeCards: [['As', 'Ks'], ['Qd', 'Qc'], ['Jh', 'Jd']],
      );

      final order = ShowdownOrder.getRevealOrder(state);
      // Dealer=0, so order starts from seat 1
      expect(order.first, 1);
    });
  });

  group('ShowdownOrder.getShowdownInfo', () {
    test('TC6: winner mustShow=true, loser non-allIn mustShow=false', () {
      final state = _makeShowdownState(
        lastAggressor: 0,
        holeCards: [['As', 'Ks'], ['Qd', 'Qc'], ['Jh', 'Jd']],
      );

      final awards = {0: 300}; // seat 0 wins
      final info = ShowdownOrder.getShowdownInfo(state, awards);

      // Seat 0: winner → mustShow=true
      final seat0Info = info.firstWhere((i) => i.seatIndex == 0);
      expect(seat0Info.mustShow, isTrue);
      expect(seat0Info.isWinner, isTrue);

      // Seat 1: loser, not allIn → mustShow=false (can muck)
      final seat1Info = info.firstWhere((i) => i.seatIndex == 1);
      expect(seat1Info.mustShow, isFalse);
      expect(seat1Info.isWinner, isFalse);
    });

    test('TC7: allIn loser mustShow=true (cannot muck)', () {
      final state = _makeShowdownState(
        statuses: [SeatStatus.active, SeatStatus.allIn, SeatStatus.active],
        lastAggressor: 0,
        holeCards: [['As', 'Ks'], ['Qd', 'Qc'], ['Jh', 'Jd']],
      );

      final awards = {0: 300};
      final info = ShowdownOrder.getShowdownInfo(state, awards);

      // Seat 1: allIn loser → mustShow=true
      final seat1Info = info.firstWhere((i) => i.seatIndex == 1);
      expect(seat1Info.mustShow, isTrue);
      expect(seat1Info.isWinner, isFalse);
    });

    test('TC8: revealOrder matches getRevealOrder', () {
      final state = _makeShowdownState(
        lastAggressor: 1,
        holeCards: [['As', 'Ks'], ['Qd', 'Qc'], ['Jh', 'Jd']],
      );

      final awards = {1: 300};
      final info = ShowdownOrder.getShowdownInfo(state, awards);

      // First in reveal order should be seat 1 (last aggressor)
      expect(info.first.seatIndex, 1);
      expect(info.first.revealOrder, 0);
    });
  });
}
