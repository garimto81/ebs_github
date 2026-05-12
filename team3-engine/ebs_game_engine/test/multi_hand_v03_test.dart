/// Cycle 6 v03: Multi-hand straddle_seat 이동 + ante_override + run_it_twice (issue #310).
///
/// v02 (Multi_Hand_State.md) 위에 다음 룰 검증:
///   - straddle_seat 활성 시 ManualNextHand 처리에서 straddleSeat 도 회전
///   - heads-up 진입 시 straddle 무효화
///   - AnteOverride 이벤트로 anteAmount/anteType 변경
///   - RunItChoice(times=2) → pot 1/2 분할 + 각 board winners 산출
///
/// 참조:
///   - lib/engine.dart::_handleManualNextHandFull (v03 straddle 회전)
///   - lib/engine.dart::_handleAnteOverrideFull (신규)
///   - lib/engine.dart::_handleRunItChoiceFull (v03 분할 pot)
///   - docs/2. Development/2.3 Game Engine/Rules/Multi_Hand_v03.md (spec)
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
  bool straddleEnabled = false,
  int? straddleSeat,
  int? anteAmount,
  int? anteType,
}) {
  final seats = List<Seat>.generate(seatCount, (i) => _seat(i));
  return GameState(
    sessionId: 'v03-test',
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
    straddleEnabled: straddleEnabled,
    straddleSeat: straddleSeat,
    anteAmount: anteAmount,
    anteType: anteType,
  );
}

void main() {
  group('Cycle 6 v03: straddle_seat 이동', () {
    test('straddle 활성 시 straddleSeat 도 1칸 회전 (6-seat)', () {
      final state = _stateAfterHand(
        seatCount: 6,
        dealerSeat: 0,
        handNumber: 1,
        straddleEnabled: true,
        straddleSeat: 3,
      );
      final result = Engine.applyFull(state, const ManualNextHand());
      expect(result.state.straddleEnabled, isTrue,
          reason: '6-seat (non-headsup) 에서 straddle 은 활성 유지');
      expect(result.state.straddleSeat, 4,
          reason: 'straddleSeat 도 dealer 와 동일하게 1칸 회전 (3 → 4)');
      expect(result.state.dealerSeat, 1, reason: 'dealer 1칸 회전 (v02 동일)');
    });

    test('straddle 활성 round-robin (6-seat × 4 hand)', () {
      var state = _stateAfterHand(
        seatCount: 6,
        dealerSeat: 0,
        handNumber: 1,
        straddleEnabled: true,
        straddleSeat: 3,
      );
      // hand 1 → hand 2
      state = Engine.applyFull(state, const ManualNextHand()).state;
      expect(state.straddleSeat, 4);
      // hand 2 → hand 3
      state = Engine.applyFull(state, const ManualNextHand()).state;
      expect(state.straddleSeat, 5);
      // hand 3 → hand 4
      state = Engine.applyFull(state, const ManualNextHand()).state;
      expect(state.straddleSeat, 0,
          reason: 'wrap-around: 5 → 0');
      // hand 4 → hand 5
      state = Engine.applyFull(state, const ManualNextHand()).state;
      expect(state.straddleSeat, 1);
    });

    test('heads-up 진입 시 straddleEnabled=false 무효화', () {
      // 3 active 에서 1명 sittingOut → heads-up
      final seats = [
        _seat(0, status: SeatStatus.sittingOut),
        _seat(1),
        _seat(2),
      ];
      final state = GameState(
        sessionId: 'v03-headsup',
        variantName: 'nlh',
        seats: seats,
        deck: Deck.standard(),
        dealerSeat: 1,
        sbSeat: 2,
        bbSeat: 1,
        bbAmount: 10,
        handNumber: 1,
        handInProgress: false,
        street: Street.idle,
        straddleEnabled: true,
        straddleSeat: 2,
      );
      final result = Engine.applyFull(state, const ManualNextHand());
      expect(result.state.straddleEnabled, isFalse,
          reason: 'heads-up 진입 시 straddle 무효화');
    });

    test('sittingOut 건너뛰기 — straddle 도 동일 패턴', () {
      // seats: 0=active, 1=sittingOut, 2=active, 3=active, 4=active, 5=active
      final seats = [
        _seat(0),
        _seat(1, status: SeatStatus.sittingOut),
        _seat(2),
        _seat(3),
        _seat(4),
        _seat(5),
      ];
      final state = GameState(
        sessionId: 'v03-skip',
        variantName: 'nlh',
        seats: seats,
        deck: Deck.standard(),
        dealerSeat: 0,
        sbSeat: 2,
        bbSeat: 3,
        bbAmount: 10,
        handNumber: 1,
        handInProgress: false,
        street: Street.idle,
        straddleEnabled: true,
        straddleSeat: 0,
      );
      final result = Engine.applyFull(state, const ManualNextHand());
      expect(result.state.straddleSeat, 2,
          reason: 'straddleSeat 0 → 다음 active = 2 (1 건너뜀)');
    });

    test('straddle 미활성 시 straddleSeat 변경 없음', () {
      final state = _stateAfterHand(
        seatCount: 6,
        dealerSeat: 0,
        handNumber: 1,
        straddleEnabled: false,
        straddleSeat: null,
      );
      final result = Engine.applyFull(state, const ManualNextHand());
      expect(result.state.straddleEnabled, isFalse);
      expect(result.state.straddleSeat, isNull);
    });
  });

  group('Cycle 6 v03: AnteOverride', () {
    test('AnteOverride amount 변경 + type 유지', () {
      final state = _stateAfterHand(
        seatCount: 6,
        dealerSeat: 0,
        anteAmount: 50,
        anteType: 0,
      );
      final result = Engine.applyFull(
        state,
        const AnteOverride(amount: 100),
      );
      expect(result.state.anteAmount, 100,
          reason: 'AnteOverride 가 anteAmount 변경');
      expect(result.state.anteType, 0, reason: 'type 미지정 시 기존 anteType 유지');
    });

    test('AnteOverride amount + type 모두 변경', () {
      final state = _stateAfterHand(
        seatCount: 6,
        dealerSeat: 0,
        anteAmount: 50,
        anteType: 0,
      );
      final result = Engine.applyFull(
        state,
        const AnteOverride(amount: 100, type: 2),
      );
      expect(result.state.anteAmount, 100);
      expect(result.state.anteType, 2, reason: 'type override 적용 (0 → 2)');
    });

    test('AnteOverride amount=0 또는 음수 → 무시 (validation)', () {
      final state = _stateAfterHand(
        seatCount: 6,
        dealerSeat: 0,
        anteAmount: 50,
        anteType: 0,
      );
      final result1 = Engine.applyFull(state, const AnteOverride(amount: 0));
      expect(result1.state.anteAmount, 50, reason: 'amount=0 → 무시');
      final result2 = Engine.applyFull(state, const AnteOverride(amount: -10));
      expect(result2.state.anteAmount, 50, reason: 'amount<0 → 무시');
    });

    test('AnteOverride 후 ManualNextHand 까지 영구 유지', () {
      var state = _stateAfterHand(
        seatCount: 6,
        dealerSeat: 0,
        anteAmount: 50,
        anteType: 0,
      );
      state = Engine.applyFull(state, const AnteOverride(amount: 100)).state;
      state = Engine.applyFull(state, const ManualNextHand()).state;
      expect(state.anteAmount, 100,
          reason: 'ManualNextHand 이후에도 override 값 유지');
    });
  });

  group('Cycle 6 v03: RunItChoice (times=2) 분할 pot', () {
    GameState buildRiverState() {
      // 2 seat all-in, pot 200, river 까지 5 community
      final seats = [
        _seat(0, stack: 0, status: SeatStatus.allIn),
        _seat(1, stack: 0, status: SeatStatus.allIn),
      ];
      seats[0].holeCards = [Card.parse('As'), Card.parse('Kh')];
      seats[1].holeCards = [Card.parse('Qd'), Card.parse('Jc')];
      final pot = Pot();
      pot.main = 200;
      final state = GameState(
        sessionId: 'v03-rit',
        variantName: 'nlh',
        seats: seats,
        deck: Deck.standard(),
        pot: pot,
        community: [
          Card.parse('2h'),
          Card.parse('5d'),
          Card.parse('9c'),
          Card.parse('Th'),
          Card.parse('3s'),
        ],
        dealerSeat: 0,
        sbSeat: 0,
        bbSeat: 1,
        bbAmount: 10,
        handInProgress: true,
        street: Street.river,
        runItTimes: null,
      );
      return state;
    }

    test('times=2 river-trigger → runItBoard2Cards 5장 board 생성', () {
      final state = buildRiverState();
      final result = Engine.applyFull(state, const RunItChoice(2));
      expect(result.state.runItBoard2Cards, isNotNull);
      expect(result.state.runItBoard2Cards!.length, 5,
          reason: 'board 2 는 flop 3장 공유 + 새 turn/river 2장 = 5장 완성');
      expect(result.state.runItTimes, 2);
      expect(result.state.street, Street.runItMultiple);
    });

    test('times=2 → board 2 의 flop 3장은 board 1 과 동일 (river 트리거 표준)', () {
      final state = buildRiverState();
      final flopShared = state.community.take(3).toList();
      final result = Engine.applyFull(state, const RunItChoice(2));
      final board2 = result.state.runItBoard2Cards!;
      expect(board2.take(3).map((c) => c.notation).toList(),
          flopShared.map((c) => c.notation).toList(),
          reason: 'flop 은 동일, turn/river 만 새로 deal');
      // board 2 의 turn/river 는 deck 에서 새로 deal — board 1 과 달라야
      expect(board2[3].notation != state.community[3].notation ||
              board2[4].notation != state.community[4].notation,
          isTrue,
          reason: 'board 2 의 turn/river 는 새로 deal 된 카드');
    });

    test('Engine.runItAwards → totalPot 정합 (board1 + board2 = total)', () {
      final state = buildRiverState();
      final afterRit = Engine.applyFull(state, const RunItChoice(2)).state;
      final awards = Engine.runItAwards(afterRit);
      expect(awards, isNotNull, reason: 'helper 결과는 non-null');
      final totalAwarded = awards!.values.fold<int>(0, (a, b) => a + b);
      expect(totalAwarded, 200,
          reason: 'board1 + board2 award 합산 = totalPot (200)');
    });

    test('Engine.runItAwards → runItTimes 없으면 null 반환', () {
      final state = buildRiverState();
      final awards = Engine.runItAwards(state);
      expect(awards, isNull, reason: 'RunItChoice 미실행 상태 → null');
    });

    test('Engine.runItAwards 결과를 PotAwarded 로 적용 → 정합', () {
      final state = buildRiverState();
      final initialStack0 = state.seats[0].stack;
      final initialStack1 = state.seats[1].stack;

      var working = Engine.applyFull(state, const RunItChoice(2)).state;
      final awards = Engine.runItAwards(working)!;
      working = Engine.applyFull(working, PotAwarded(awards)).state;

      final delta0 = working.seats[0].stack - initialStack0;
      final delta1 = working.seats[1].stack - initialStack1;
      expect(delta0 + delta1, 200, reason: 'PotAwarded 후 chip 정합');
      expect(working.pot.main, 0, reason: 'PotAwarded 후 pot 클리어');
    });

    test('times=2 + community 5장 미만 (flop trigger) → 기존 동작 (board2 생성 X)', () {
      final seats = [
        _seat(0, stack: 100, status: SeatStatus.allIn),
        _seat(1, stack: 100, status: SeatStatus.allIn),
      ];
      seats[0].holeCards = [Card.parse('As'), Card.parse('Kh')];
      seats[1].holeCards = [Card.parse('Qd'), Card.parse('Jc')];
      final pot = Pot();
      pot.main = 200;
      final state = GameState(
        sessionId: 'v03-rit-flop',
        variantName: 'nlh',
        seats: seats,
        deck: Deck.standard(),
        pot: pot,
        community: [Card.parse('2h'), Card.parse('5d'), Card.parse('9c')],
        dealerSeat: 0,
        sbSeat: 0,
        bbSeat: 1,
        bbAmount: 10,
        handInProgress: true,
        street: Street.flop,
      );
      final result = Engine.applyFull(state, const RunItChoice(2));
      expect(result.state.runItBoard2Cards, isNull,
          reason: 'flop trigger (community<5) → v02 legacy 동작');
      expect(result.state.runItTimes, 2);
      expect(result.state.street, Street.runItMultiple);
    });

    test('times=3 → 기존 동작 (state 전환만, board2 생성 X — Cycle 6 범위 밖)', () {
      final state = buildRiverState();
      final result = Engine.applyFull(state, const RunItChoice(3));
      expect(result.state.runItTimes, 3);
      expect(result.state.street, Street.runItMultiple);
      expect(result.state.runItBoard2Cards, isNull,
          reason: 'times=3 은 별도 issue — runItBoard2Cards 미사용');
    });
  });

  group('Cycle 6 v03: v02 회귀 (rotation 정합 유지)', () {
    test('v02 6-seat round-robin 정합 (straddle off)', () {
      var state = _stateAfterHand(seatCount: 6, dealerSeat: 0);
      state = Engine.applyFull(state, const ManualNextHand()).state;
      expect(state.dealerSeat, 1);
      expect(state.sbSeat, 2);
      expect(state.bbSeat, 3);
    });

    test('v02 handNumber++ 정합 (straddle on/off 무관)', () {
      final state = _stateAfterHand(
        seatCount: 6,
        dealerSeat: 0,
        straddleEnabled: true,
        straddleSeat: 3,
      );
      final result = Engine.applyFull(state, const ManualNextHand());
      expect(result.state.handNumber, 2);
    });
  });
}
