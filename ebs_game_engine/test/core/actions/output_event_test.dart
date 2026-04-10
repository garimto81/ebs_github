import 'package:test/test.dart';
import 'package:ebs_game_engine/core/actions/output_event.dart';
import 'package:ebs_game_engine/core/actions/reduce_result.dart';
import 'package:ebs_game_engine/core/state/event_log.dart';
import 'package:ebs_game_engine/core/state/card_reveal_config.dart';
import 'package:ebs_game_engine/engine.dart';

void main() {
  // ── OutputEvent construction (13 tests) ──

  group('OutputEvent subclasses', () {
    test('StateChanged holds fromState and toState', () {
      const e = StateChanged(fromState: 'preflop', toState: 'flop');
      expect(e.fromState, 'preflop');
      expect(e.toState, 'flop');
      expect(e, isA<OutputEvent>());
    });

    test('ActionProcessed holds seatIndex, actionType, optional amount', () {
      const e =
          ActionProcessed(seatIndex: 2, actionType: 'raise', amount: 100);
      expect(e.seatIndex, 2);
      expect(e.actionType, 'raise');
      expect(e.amount, 100);
    });

    test('ActionProcessed amount defaults to null', () {
      const e = ActionProcessed(seatIndex: 0, actionType: 'fold');
      expect(e.amount, isNull);
    });

    test('PotUpdated holds mainPot and sidePots', () {
      const e = PotUpdated(mainPot: 500, sidePots: [200, 100]);
      expect(e.mainPot, 500);
      expect(e.sidePots, [200, 100]);
    });

    test('BoardUpdated holds cardCount', () {
      const e = BoardUpdated(cardCount: 3);
      expect(e.cardCount, 3);
    });

    test('ActionOnChanged holds seatIndex', () {
      const e = ActionOnChanged(seatIndex: 4);
      expect(e.seatIndex, 4);
    });

    test('WinnerDetermined holds awards map', () {
      const e = WinnerDetermined(awards: {0: 1000, 2: 500});
      expect(e.awards[0], 1000);
      expect(e.awards[2], 500);
    });

    test('Rejected holds reason', () {
      const e = Rejected(reason: 'invalid action');
      expect(e.reason, 'invalid action');
    });

    test('UndoApplied holds stepsUndone', () {
      const e = UndoApplied(stepsUndone: 3);
      expect(e.stepsUndone, 3);
    });

    test('HandCompleted holds handNumber', () {
      const e = HandCompleted(handNumber: 42);
      expect(e.handNumber, 42);
    });

    test('EquityUpdated holds equities map', () {
      const e = EquityUpdated(equities: {0: 0.65, 1: 0.35});
      expect(e.equities[0], 0.65);
      expect(e.equities[1], 0.35);
    });

    test('CardRevealed holds seatIndex, cardCodes, visibility', () {
      const e = CardRevealed(
          seatIndex: 1, cardCodes: ['As', 'Kh'], visibility: 'broadcast');
      expect(e.seatIndex, 1);
      expect(e.cardCodes, ['As', 'Kh']);
      expect(e.visibility, 'broadcast');
    });

    test('CardMismatchDetected holds expected and detected', () {
      const e = CardMismatchDetected(expected: 'As', detected: 'Ks');
      expect(e.expected, 'As');
      expect(e.detected, 'Ks');
    });

    test('SevenDeuceBonusAwarded holds seatIndex and bonusAmount', () {
      const e = SevenDeuceBonusAwarded(seatIndex: 3, bonusAmount: 500);
      expect(e.seatIndex, 3);
      expect(e.bonusAmount, 500);
    });
  });

  // ── ReduceResult (5 tests) ──

  group('ReduceResult', () {
    late GameState state;

    setUp(() {
      state = GameState(
        sessionId: 'test-session',
        variantName: 'NLH',
        seats: [
          Seat(index: 0, label: 'P0', stack: 1000),
          Seat(index: 1, label: 'P1', stack: 1000),
        ],
        deck: Deck.standard(seed: 42),
      );
    });

    test('default constructor has empty outputs', () {
      final r = ReduceResult(state: state);
      expect(r.outputs, isEmpty);
      expect(r.state.sessionId, 'test-session');
    });

    test('constructor with explicit outputs list', () {
      final r = ReduceResult(
        state: state,
        outputs: [const Rejected(reason: 'test')],
      );
      expect(r.outputs, hasLength(1));
      expect(r.outputs.first, isA<Rejected>());
    });

    test('withEvent factory creates single-event list', () {
      final r = ReduceResult.withEvent(
          state, const BoardUpdated(cardCount: 3));
      expect(r.outputs, hasLength(1));
      expect(r.outputs.first, isA<BoardUpdated>());
    });

    test('withEvents factory creates multi-event list', () {
      final r = ReduceResult.withEvents(state, [
        const StateChanged(fromState: 'preflop', toState: 'flop'),
        const BoardUpdated(cardCount: 3),
        const ActionOnChanged(seatIndex: 0),
      ]);
      expect(r.outputs, hasLength(3));
    });

    test('state is accessible from result', () {
      final r = ReduceResult(state: state);
      expect(r.state.variantName, 'NLH');
      expect(r.state.seats, hasLength(2));
    });
  });

  // ── EventLog (12 tests) ──

  group('EventLog', () {
    late GameState initialState;
    late EventLog log;

    setUp(() {
      initialState = GameState(
        sessionId: 'test-session',
        variantName: 'NLH',
        seats: [
          Seat(index: 0, label: 'P0', stack: 1000),
          Seat(index: 1, label: 'P1', stack: 1000),
        ],
        deck: Deck.standard(seed: 42),
      );
      log = EventLog(initialState);
    });

    test('initialState is preserved', () {
      expect(log.initialState.sessionId, 'test-session');
    });

    test('starts empty', () {
      expect(log.length, 0);
      expect(log.events, isEmpty);
    });

    test('canUndo is false when empty', () {
      expect(log.canUndo, false);
    });

    test('record adds event', () {
      log.record(const HandEnd());
      expect(log.length, 1);
      expect(log.events.first, isA<HandEnd>());
    });

    test('canUndo is true after record', () {
      log.record(const HandEnd());
      expect(log.canUndo, true);
    });

    test('undo 1 step removes last event', () {
      log.record(const HandStart(dealerSeat: 0, blinds: {0: 1, 1: 2}));
      log.record(const HandEnd());
      final removed = log.undo(1);
      expect(removed, 1);
      expect(log.length, 1);
      expect(log.events.first, isA<HandStart>());
    });

    test('undo 3 steps removes last 3 events', () {
      for (var i = 0; i < 5; i++) {
        log.record(const HandEnd());
      }
      final removed = log.undo(3);
      expect(removed, 3);
      expect(log.length, 2);
    });

    test('undo 5 steps (max) removes 5 events', () {
      for (var i = 0; i < 8; i++) {
        log.record(const HandEnd());
      }
      final removed = log.undo(5);
      expect(removed, 5);
      expect(log.length, 3);
    });

    test('undo beyond maxUndoSteps is capped at 5', () {
      for (var i = 0; i < 10; i++) {
        log.record(const HandEnd());
      }
      final removed = log.undo(10);
      expect(removed, 5);
      expect(log.length, 5);
    });

    test('undo more than available events is capped', () {
      log.record(const HandEnd());
      log.record(const HandEnd());
      final removed = log.undo(5);
      expect(removed, 2);
      expect(log.length, 0);
    });

    test('clear removes all events', () {
      for (var i = 0; i < 5; i++) {
        log.record(const HandEnd());
      }
      log.clear();
      expect(log.length, 0);
      expect(log.canUndo, false);
    });

    test('maxUndoSteps constant is 5', () {
      expect(EventLog.maxUndoSteps, 5);
    });
  });

  // ── CardRevealConfig (5 tests) ──

  group('CardRevealConfig', () {
    test('default constructor uses lastAggressorFirst, bothCards, hideImmediately', () {
      const config = CardRevealConfig();
      expect(config.revealType, RevealType.lastAggressorFirst);
      expect(config.showType, ShowType.bothCards);
      expect(config.foldHideType, FoldHideType.hideImmediately);
    });

    test('broadcast static has expected values', () {
      expect(CardRevealConfig.broadcast.revealType,
          RevealType.lastAggressorFirst);
      expect(CardRevealConfig.broadcast.showType, ShowType.bothCards);
      expect(CardRevealConfig.broadcast.foldHideType,
          FoldHideType.hideImmediately);
    });

    test('venue static has expected values', () {
      expect(CardRevealConfig.venue.revealType, RevealType.externalControl);
      expect(CardRevealConfig.venue.showType, ShowType.playerChoice);
      expect(
          CardRevealConfig.venue.foldHideType, FoldHideType.hideImmediately);
    });

    test('copyWith overrides specified fields', () {
      const original = CardRevealConfig();
      final modified = original.copyWith(
        revealType: RevealType.winnerOnly,
        foldHideType: FoldHideType.briefRevealThenHide,
      );
      expect(modified.revealType, RevealType.winnerOnly);
      expect(modified.showType, ShowType.bothCards); // unchanged
      expect(modified.foldHideType, FoldHideType.briefRevealThenHide);
    });

    test('all enum values are accessible', () {
      expect(RevealType.values, hasLength(6));
      expect(ShowType.values, hasLength(4));
      expect(FoldHideType.values, hasLength(2));
      expect(CanvasType.values, hasLength(2));
    });
  });
}
