/// Cycle 5 v02: Multi-hand state + button rotate (issue #287).
///
/// ManualNextHand event는 hand_end 이후 다음 hand 진입을 트리거합니다.
/// 본 테스트는 ManualNextHand 처리가 dealer/SB/BB rotation + handNumber
/// 증가를 정확히 수행함을 검증합니다.
///
/// 표준 hold'em 규칙:
///   - 3+ seats: dealer +1 mod N. SB = dealer+1, BB = dealer+2 (active seats만)
///   - heads-up: dealer = SB, 나머지 1명 = BB (button-back-to-back은
///     dead-button rule로 별도 처리; dead_button_test.dart 참조)
///
/// 참조:
///   - lib/engine.dart::_endHandFull (dealer rotation 기존 패턴)
///   - lib/engine.dart::_startHandFull (SB/BB 계산 기존 패턴)
///   - docs/2. Development/2.3 Game Engine/Rules/Multi_Hand_State.md (spec)
library;

import 'package:test/test.dart';
import 'package:ebs_game_engine/engine.dart';

Seat _seat(int i, {int stack = 1000, SeatStatus status = SeatStatus.active}) {
  return Seat(index: i, label: 'P$i', stack: stack, status: status);
}

GameState _stateAfterHand({
  required int seatCount,
  required int dealerSeat,
  int handNumber = 1,
}) {
  final seats = List<Seat>.generate(seatCount, (i) => _seat(i));
  return GameState(
    sessionId: 'multi-hand-test',
    variantName: 'nlh',
    seats: seats,
    deck: Deck.standard(),
    dealerSeat: dealerSeat,
    sbSeat: (dealerSeat + 1) % seatCount,
    bbSeat: (dealerSeat + 2) % seatCount,
    bbAmount: 10,
    handNumber: handNumber,
    handInProgress: false,
    street: Street.idle,
  );
}

void main() {
  group('Cycle 5 v02: ManualNextHand rotation', () {
    test('handNumber++ after ManualNextHand', () {
      final state = _stateAfterHand(seatCount: 6, dealerSeat: 0, handNumber: 1);
      final result = Engine.applyFull(state, const ManualNextHand());
      expect(result.state.handNumber, 2,
          reason: 'ManualNextHand must increment handNumber for next hand');
    });

    test('6-seat dealer rotates +1 mod 6', () {
      final state = _stateAfterHand(seatCount: 6, dealerSeat: 0, handNumber: 1);
      final result = Engine.applyFull(state, const ManualNextHand());
      expect(result.state.dealerSeat, 1,
          reason: 'dealer should rotate +1 after ManualNextHand');
    });

    test('6-seat SB rotates to dealer+1, BB to dealer+2', () {
      final state = _stateAfterHand(seatCount: 6, dealerSeat: 0, handNumber: 1);
      final result = Engine.applyFull(state, const ManualNextHand());
      expect(result.state.dealerSeat, 1);
      expect(result.state.sbSeat, 2,
          reason: 'SB = (new dealer + 1) % seatCount');
      expect(result.state.bbSeat, 3,
          reason: 'BB = (new dealer + 2) % seatCount');
    });

    test('6-seat round-robin: 6 ManualNextHand returns dealer to origin', () {
      var state = _stateAfterHand(seatCount: 6, dealerSeat: 0, handNumber: 1);
      for (var i = 0; i < 6; i++) {
        state = Engine.applyFull(state, const ManualNextHand()).state;
      }
      expect(state.dealerSeat, 0,
          reason: '6 rotations on 6 seats should return to origin');
      expect(state.handNumber, 7,
          reason: 'handNumber should be 1 + 6 = 7');
    });

    test('heads-up: dealer rotates to other seat, dealer=SB', () {
      final seats = [_seat(0), _seat(1)];
      final state = GameState(
        sessionId: 'hu-test',
        variantName: 'nlh',
        seats: seats,
        deck: Deck.standard(),
        dealerSeat: 0,
        sbSeat: 0,
        bbSeat: 1,
        bbAmount: 10,
        handNumber: 1,
        street: Street.idle,
      );

      final result = Engine.applyFull(state, const ManualNextHand());
      expect(result.state.dealerSeat, 1,
          reason: 'heads-up dealer toggles to other seat');
      expect(result.state.sbSeat, 1,
          reason: 'heads-up: dealer = SB (standard rule)');
      expect(result.state.bbSeat, 0,
          reason: 'heads-up: non-dealer = BB');
    });

    test('sitting-out seat is skipped when rotating dealer', () {
      final seats = [
        _seat(0),
        _seat(1, status: SeatStatus.sittingOut),
        _seat(2),
        _seat(3),
      ];
      final state = GameState(
        sessionId: 'skip-test',
        variantName: 'nlh',
        seats: seats,
        deck: Deck.standard(),
        dealerSeat: 0,
        sbSeat: 2,
        bbSeat: 3,
        bbAmount: 10,
        handNumber: 1,
        street: Street.idle,
      );

      final result = Engine.applyFull(state, const ManualNextHand());
      expect(result.state.dealerSeat, 2,
          reason: 'dealer skips sitting-out seat 1');
    });

    test('ManualNextHand resets street to idle and clears community', () {
      final state = _stateAfterHand(seatCount: 6, dealerSeat: 0).copyWith(
        street: Street.handComplete,
        community: [Card.parse('Ah'), Card.parse('Kd'), Card.parse('Qs')],
      );
      final result = Engine.applyFull(state, const ManualNextHand());
      expect(result.state.street, Street.idle);
      expect(result.state.community, isEmpty);
      expect(result.state.handInProgress, isFalse);
    });

    test('ManualNextHand clears all hole cards', () {
      final seats = List<Seat>.generate(6, (i) => _seat(i));
      seats[0].holeCards = [Card.parse('As'), Card.parse('Kh')];
      seats[1].holeCards = [Card.parse('Qc'), Card.parse('Jd')];
      final state = GameState(
        sessionId: 'hole-test',
        variantName: 'nlh',
        seats: seats,
        deck: Deck.standard(),
        dealerSeat: 0,
        sbSeat: 1,
        bbSeat: 2,
        bbAmount: 10,
        handNumber: 1,
        street: Street.idle,
      );

      final result = Engine.applyFull(state, const ManualNextHand());
      for (final seat in result.state.seats) {
        expect(seat.holeCards, isEmpty,
            reason: 'seat ${seat.index} hole cards must be cleared');
      }
    });

    test('StateChanged output event emitted', () {
      final state = _stateAfterHand(seatCount: 6, dealerSeat: 0);
      final result = Engine.applyFull(state, const ManualNextHand());
      expect(
        result.outputs.whereType<StateChanged>(),
        isNotEmpty,
        reason: 'ManualNextHand must emit StateChanged output',
      );
    });
  });

  group('Cycle 5 v02: round-robin scenarios', () {
    test('3-seat: 9 hands -> 3 full rotations', () {
      var state = _stateAfterHand(seatCount: 3, dealerSeat: 0, handNumber: 1);
      final dealers = <int>[state.dealerSeat];
      for (var i = 0; i < 9; i++) {
        state = Engine.applyFull(state, const ManualNextHand()).state;
        dealers.add(state.dealerSeat);
      }
      expect(dealers, [0, 1, 2, 0, 1, 2, 0, 1, 2, 0]);
      expect(state.handNumber, 10);
    });

    test('all seats sitting-out except 1 -> dealer stays', () {
      final seats = [
        _seat(0),
        _seat(1, status: SeatStatus.sittingOut),
        _seat(2, status: SeatStatus.sittingOut),
      ];
      final state = GameState(
        sessionId: 'lone-test',
        variantName: 'nlh',
        seats: seats,
        deck: Deck.standard(),
        dealerSeat: 0,
        sbSeat: 0,
        bbSeat: 0,
        bbAmount: 10,
        handNumber: 1,
        street: Street.idle,
      );

      final result = Engine.applyFull(state, const ManualNextHand());
      expect(result.state.dealerSeat, 0,
          reason: 'sole active seat keeps dealer button');
    });
  });
}
