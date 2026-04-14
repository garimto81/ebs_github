import 'package:test/test.dart';
import 'package:ebs_game_engine/engine.dart';
import 'package:ebs_game_engine/harness/session.dart';

/// Tests that Engine.applyFull() emits correct OutputEvents for each handler.
void main() {
  late GameState baseState;

  setUp(() {
    baseState = GameState(
      sessionId: 'emit-test',
      variantName: 'NLH',
      street: Street.idle,
      seats: [
        Seat(index: 0, label: 'P0', stack: 1000),
        Seat(index: 1, label: 'P1', stack: 1000),
        Seat(index: 2, label: 'P2', stack: 1000),
      ],
      deck: Deck.standard(seed: 42),
    );
  });

  group('applyFull OutputEvent emission', () {
    test('HandStart emits StateChanged(idle→preflop)', () {
      final result = Engine.applyFull(
        baseState,
        const HandStart(dealerSeat: 0, blinds: {1: 1, 2: 2}),
      );

      expect(result.state.street, Street.preflop);
      expect(result.state.handInProgress, isTrue);
      expect(result.outputs, isNotEmpty);

      final sc = result.outputs.whereType<StateChanged>().first;
      expect(sc.fromState, 'idle');
      expect(sc.toState, 'preflop');
    });

    test('apply() returns same state as applyFull().state', () {
      const event = HandStart(dealerSeat: 0, blinds: {1: 1, 2: 2});
      final legacy = Engine.apply(baseState, event);
      final full = Engine.applyFull(baseState, event);

      expect(full.state.street, legacy.street);
      expect(full.state.actionOn, legacy.actionOn);
      expect(full.state.pot.main, legacy.pot.main);
    });

    test('DealHoleCards emits no outputs', () {
      // First start a hand
      var state = Engine.apply(
        baseState,
        const HandStart(dealerSeat: 0, blinds: {1: 1, 2: 2}),
      );

      final deck = Deck.standard(seed: 99);
      final result = Engine.applyFull(state, DealHoleCards({
        0: [deck.draw(), deck.draw()],
        1: [deck.draw(), deck.draw()],
        2: [deck.draw(), deck.draw()],
      }));

      expect(result.outputs, isEmpty);
    });

    test('DealCommunity emits BoardUpdated', () {
      var state = Engine.apply(
        baseState,
        const HandStart(dealerSeat: 0, blinds: {1: 1, 2: 2}),
      );

      final deck = Deck.standard(seed: 99);
      final cards = [deck.draw(), deck.draw(), deck.draw()];
      final result = Engine.applyFull(state, DealCommunity(cards));

      expect(result.outputs, hasLength(1));
      final bu = result.outputs.first as BoardUpdated;
      expect(bu.cardCount, 3);
    });

    test('PlayerAction(Fold) emits ActionProcessed + PotUpdated', () {
      var state = Engine.apply(
        baseState,
        const HandStart(dealerSeat: 0, blinds: {1: 1, 2: 2}),
      );

      // actionOn should be set; fold that player
      final seatToAct = state.actionOn;
      final result = Engine.applyFull(
        state,
        PlayerAction(seatToAct, const Fold()),
      );

      final ap = result.outputs.whereType<ActionProcessed>();
      expect(ap, isNotEmpty);
      expect(ap.first.seatIndex, seatToAct);
      expect(ap.first.actionType, 'fold');

      final pu = result.outputs.whereType<PotUpdated>();
      expect(pu, isNotEmpty);
    });

    test('PlayerAction(Call) emits ActionProcessed + PotUpdated + ActionOnChanged', () {
      var state = Engine.apply(
        baseState,
        const HandStart(dealerSeat: 0, blinds: {1: 1, 2: 2}),
      );

      final seatToAct = state.actionOn;
      final result = Engine.applyFull(
        state,
        PlayerAction(seatToAct, const Call(2)),
      );

      final ap = result.outputs.whereType<ActionProcessed>().first;
      expect(ap.seatIndex, seatToAct);
      expect(ap.actionType, 'call');
      expect(ap.amount, 2);

      final pu = result.outputs.whereType<PotUpdated>();
      expect(pu, isNotEmpty);

      // Should have ActionOnChanged since round is not complete
      final aoc = result.outputs.whereType<ActionOnChanged>();
      expect(aoc, isNotEmpty);
    });

    test('StreetAdvance emits StateChanged', () {
      var state = Engine.apply(
        baseState,
        const HandStart(dealerSeat: 0, blinds: {1: 1, 2: 2}),
      );

      final result = Engine.applyFull(
        state,
        const StreetAdvance(Street.flop),
      );

      final sc = result.outputs.whereType<StateChanged>();
      expect(sc, isNotEmpty);
      expect(sc.first.fromState, 'preflop');
      expect(sc.first.toState, 'flop');
    });

    test('PotAwarded emits WinnerDetermined', () {
      var state = Engine.apply(
        baseState,
        const HandStart(dealerSeat: 0, blinds: {1: 1, 2: 2}),
      );

      final result = Engine.applyFull(
        state,
        const PotAwarded({0: 100}),
      );

      final wd = result.outputs.whereType<WinnerDetermined>().first;
      expect(wd.awards, {0: 100});
    });

    test('HandEnd emits HandCompleted + StateChanged', () {
      var state = Engine.apply(
        baseState,
        const HandStart(dealerSeat: 0, blinds: {1: 1, 2: 2}),
      );

      final result = Engine.applyFull(state, const HandEnd());

      final hc = result.outputs.whereType<HandCompleted>().first;
      expect(hc.handNumber, state.handNumber);

      final sc = result.outputs.whereType<StateChanged>().first;
      expect(sc.toState, 'idle');
    });

    test('MisDeal emits StateChanged(→idle)', () {
      var state = Engine.apply(
        baseState,
        const HandStart(dealerSeat: 0, blinds: {1: 1, 2: 2}),
      );

      final result = Engine.applyFull(state, const MisDeal());

      final sc = result.outputs.whereType<StateChanged>().first;
      expect(sc.fromState, 'preflop');
      expect(sc.toState, 'idle');
    });

    test('BombPotConfig emits no outputs', () {
      final result = Engine.applyFull(
        baseState,
        const BombPotConfig(100),
      );

      expect(result.outputs, isEmpty);
    });

    test('RunItChoice emits StateChanged(→runItMultiple)', () {
      // Need river state for RunItChoice
      var state = Engine.apply(
        baseState,
        const HandStart(dealerSeat: 0, blinds: {1: 1, 2: 2}),
      );
      state = state.copyWith(street: Street.river);

      final result = Engine.applyFull(state, const RunItChoice(2));

      final sc = result.outputs.whereType<StateChanged>().first;
      expect(sc.toState, 'runItMultiple');
    });

    test('ManualNextHand emits StateChanged(→idle)', () {
      var state = Engine.apply(
        baseState,
        const HandStart(dealerSeat: 0, blinds: {1: 1, 2: 2}),
      );

      final result = Engine.applyFull(state, const ManualNextHand());

      final sc = result.outputs.whereType<StateChanged>().first;
      expect(sc.toState, 'idle');
    });

    test('TimeoutFold emits ActionProcessed(fold)', () {
      var state = Engine.apply(
        baseState,
        const HandStart(dealerSeat: 0, blinds: {1: 1, 2: 2}),
      );

      final seatToAct = state.actionOn;
      final result = Engine.applyFull(
        state,
        TimeoutFold(seatToAct),
      );

      final ap = result.outputs.whereType<ActionProcessed>().first;
      expect(ap.seatIndex, seatToAct);
      expect(ap.actionType, 'fold');
    });

    test('MuckDecision(hide) emits no outputs', () {
      var state = Engine.apply(
        baseState,
        const HandStart(dealerSeat: 0, blinds: {1: 1, 2: 2}),
      );

      final result = Engine.applyFull(
        state,
        const MuckDecision(0, showCards: false),
      );

      expect(result.outputs, isEmpty);
    });

    test('MuckDecision(show) emits no outputs', () {
      final result = Engine.applyFull(
        baseState,
        const MuckDecision(0, showCards: true),
      );

      expect(result.outputs, isEmpty);
    });
  });

  group('Session.addEventFull', () {
    test('returns ReduceResult with outputs', () {
      final session = Session(
        id: 'test-session',
        variant: Nlh(),
        initial: baseState,
      );

      final result = session.addEventFull(
        const HandStart(dealerSeat: 0, blinds: {1: 1, 2: 2}),
      );

      expect(result.state.street, Street.preflop);
      expect(result.outputs, isNotEmpty);
      final sc = result.outputs.whereType<StateChanged>().first;
      expect(sc.fromState, 'idle');
      expect(sc.toState, 'preflop');
    });

    test('addEvent and addEventFull produce same state', () {
      final session1 = Session(
        id: 's1',
        variant: Nlh(),
        initial: baseState,
      );
      final session2 = Session(
        id: 's2',
        variant: Nlh(),
        initial: baseState,
      );

      const event = HandStart(dealerSeat: 0, blinds: {1: 1, 2: 2});
      final legacyState = session1.addEvent(event);
      final fullResult = session2.addEventFull(event);

      expect(fullResult.state.street, legacyState.street);
      expect(fullResult.state.actionOn, legacyState.actionOn);
      expect(fullResult.state.pot.main, legacyState.pot.main);
    });
  });
}
