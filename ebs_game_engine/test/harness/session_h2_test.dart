import 'package:test/test.dart';
import 'package:ebs_game_engine/engine.dart';
import 'package:ebs_game_engine/harness/session.dart';

// ── Helpers ──

/// Applies a PlayerAction to the session.
/// Engine auto-advances street and deals community cards when round completes.
void _applyPlayerAction(Session session, PlayerAction event) {
  session.addEvent(event);
}

Seat _seat(int i, {int stack = 1000}) {
  return Seat(
    index: i,
    label: 'Seat ${i + 1}',
    stack: stack,
    isDealer: i == 0,
  );
}

Variant _nlh() => variantRegistry['nlh']!();

Session _createSession({
  int seatCount = 3,
  int dealerSeat = 0,
  int? anteType,
  int? anteAmount,
  bool straddleEnabled = false,
  int? straddleSeat,
  bool bombPotEnabled = false,
  int? bombPotAmount,
  CanvasType canvasType = CanvasType.broadcast,
  bool sevenDeuceEnabled = false,
  int? sevenDeuceAmount,
  int? runItTimes,
  int? actionTimeoutMs,
}) {
  final variant = _nlh();
  final seats = List.generate(
    seatCount,
    (i) => _seat(i),
  );
  final deck = variant.createDeck(seed: 42);

  final initial = GameState(
    sessionId: 'test-session',
    variantName: variant.name,
    seats: seats,
    deck: deck,
    dealerSeat: dealerSeat,
    anteType: anteType,
    anteAmount: anteAmount,
    straddleEnabled: straddleEnabled,
    straddleSeat: straddleSeat,
    bombPotEnabled: bombPotEnabled,
    bombPotAmount: bombPotAmount,
    canvasType: canvasType,
    sevenDeuceEnabled: sevenDeuceEnabled,
    sevenDeuceAmount: sevenDeuceAmount,
    runItTimes: runItTimes,
    actionTimeoutMs: actionTimeoutMs,
  );

  return Session(id: initial.sessionId, variant: variant, initial: initial);
}

void main() {
  group('Session.toJson() H2 fields', () {
    test('includes handNumber field', () {
      final session = _createSession();
      final json = session.toJson();
      expect(json['handNumber'], equals(0));
    });

    test('includes anteType and anteAmount when set', () {
      final session = _createSession(anteType: 0, anteAmount: 5);
      final json = session.toJson();
      expect(json['anteType'], equals(0));
      expect(json['anteAmount'], equals(5));
    });

    test('includes null anteType and anteAmount when not set', () {
      final session = _createSession();
      final json = session.toJson();
      expect(json['anteType'], isNull);
      expect(json['anteAmount'], isNull);
    });

    test('includes straddleEnabled and straddleSeat', () {
      final session = _createSession(straddleEnabled: true, straddleSeat: 3);
      final json = session.toJson();
      expect(json['straddleEnabled'], isTrue);
      expect(json['straddleSeat'], equals(3));
    });

    test('straddleEnabled defaults to false', () {
      final session = _createSession();
      final json = session.toJson();
      expect(json['straddleEnabled'], isFalse);
      expect(json['straddleSeat'], isNull);
    });

    test('includes bombPotEnabled and bombPotAmount', () {
      final session = _createSession(bombPotEnabled: true, bombPotAmount: 50);
      final json = session.toJson();
      expect(json['bombPotEnabled'], isTrue);
      expect(json['bombPotAmount'], equals(50));
    });

    test('bombPotEnabled defaults to false', () {
      final session = _createSession();
      final json = session.toJson();
      expect(json['bombPotEnabled'], isFalse);
      expect(json['bombPotAmount'], isNull);
    });

    test('includes canvasType as string', () {
      final session = _createSession(canvasType: CanvasType.venue);
      final json = session.toJson();
      expect(json['canvasType'], equals('venue'));
    });

    test('canvasType defaults to broadcast', () {
      final session = _createSession();
      final json = session.toJson();
      expect(json['canvasType'], equals('broadcast'));
    });

    test('includes sevenDeuceEnabled and sevenDeuceAmount', () {
      final session =
          _createSession(sevenDeuceEnabled: true, sevenDeuceAmount: 100);
      final json = session.toJson();
      expect(json['sevenDeuceEnabled'], isTrue);
      expect(json['sevenDeuceAmount'], equals(100));
    });

    test('includes runItTimes when set', () {
      final session = _createSession(runItTimes: 2);
      final json = session.toJson();
      expect(json['runItTimes'], equals(2));
    });

    test('runItTimes defaults to null', () {
      final session = _createSession();
      final json = session.toJson();
      expect(json['runItTimes'], isNull);
    });

    test('includes actionTimeoutMs when set', () {
      final session = _createSession(actionTimeoutMs: 30000);
      final json = session.toJson();
      expect(json['actionTimeoutMs'], equals(30000));
    });

    test('actionTimeoutMs defaults to null', () {
      final session = _createSession();
      final json = session.toJson();
      expect(json['actionTimeoutMs'], isNull);
    });

    test('includes isAllInRunout field', () {
      final session = _createSession();
      final json = session.toJson();
      expect(json['isAllInRunout'], isFalse);
    });
  });

  group('Session with H2 config applied via HandStart', () {
    test('ante config propagates through HandStart', () {
      final session = _createSession(anteType: 0, anteAmount: 5);
      session.addEvent(
          HandStart(dealerSeat: 0, blinds: {1: 5, 2: 10}));
      final state = session.currentState;
      expect(state.anteType, equals(0));
      expect(state.anteAmount, equals(5));
    });

    test('straddle config propagates through HandStart', () {
      final session = _createSession(straddleEnabled: true, straddleSeat: 0);
      session.addEvent(
          HandStart(dealerSeat: 0, blinds: {1: 5, 2: 10}));
      final json = session.toJson();
      expect(json['straddleEnabled'], isTrue);
    });
  });

  group('New event types via session.addEvent()', () {
    test('MisDeal event resets hand state', () {
      final session = _createSession();
      session.addEvent(
          HandStart(dealerSeat: 0, blinds: {1: 5, 2: 10}));
      session.addEvent(const MisDeal());
      final state = session.currentState;
      expect(state.handInProgress, isFalse);
    });

    test('BombPotConfig event sets bomb pot', () {
      final session = _createSession();
      session.addEvent(BombPotConfig(100));
      final state = session.currentState;
      expect(state.bombPotEnabled, isTrue);
      expect(state.bombPotAmount, equals(100));
    });

    test('RunItChoice event sets run it times', () {
      final session = _createSession();
      session.addEvent(RunItChoice(2));
      final state = session.currentState;
      expect(state.runItTimes, equals(2));
      expect(state.street, equals(Street.runItMultiple));
    });

    test('ManualNextHand resets for new hand', () {
      final session = _createSession();
      session.addEvent(
          HandStart(dealerSeat: 0, blinds: {1: 5, 2: 10}));
      session.addEvent(const ManualNextHand());
      final state = session.currentState;
      expect(state.handInProgress, isFalse);
    });

    test('MuckDecision with showCards=false clears hole cards', () {
      final session = _createSession();
      session.addEvent(
          HandStart(dealerSeat: 0, blinds: {1: 5, 2: 10}));
      session.addEvent(DealHoleCards({
        0: [Card.parse('As'), Card.parse('Kh')],
        1: [Card.parse('Qd'), Card.parse('Qc')],
      }));
      session.addEvent(MuckDecision(0, showCards: false));
      final state = session.currentState;
      expect(state.seats[0].holeCards, isEmpty);
    });

    test('MuckDecision with showCards=true keeps hole cards', () {
      final session = _createSession();
      session.addEvent(
          HandStart(dealerSeat: 0, blinds: {1: 5, 2: 10}));
      session.addEvent(DealHoleCards({
        0: [Card.parse('As'), Card.parse('Kh')],
        1: [Card.parse('Qd'), Card.parse('Qc')],
      }));
      session.addEvent(MuckDecision(0, showCards: true));
      final state = session.currentState;
      expect(state.seats[0].holeCards, hasLength(2));
    });

    test('TimeoutFold folds the player', () {
      final session = _createSession();
      session.addEvent(
          HandStart(dealerSeat: 0, blinds: {1: 5, 2: 10}));
      session.addEvent(DealHoleCards({
        0: [Card.parse('As'), Card.parse('Kh')],
        1: [Card.parse('Qd'), Card.parse('Qc')],
        2: [Card.parse('7h'), Card.parse('2c')],
      }));
      // UTG (seat 0 in 3-handed with dealer=0) — seat 0 acts first preflop
      final state = session.currentState;
      final actionSeat = state.actionOn;
      session.addEvent(TimeoutFold(actionSeat));
      final newState = session.currentState;
      expect(newState.seats[actionSeat].isFolded, isTrue);
    });
  });

  group('toJson() log describes new events', () {
    test('MisDeal appears in log', () {
      final session = _createSession();
      session.addEvent(const MisDeal());
      final json = session.toJson();
      final log = json['log'] as List;
      final last = log.last as Map<String, dynamic>;
      expect(last['type'], 'MisDeal');
      expect(last['description'], contains('MisDeal'));
    });

    test('BombPotConfig appears in log', () {
      final session = _createSession();
      session.addEvent(BombPotConfig(50));
      final json = session.toJson();
      final log = json['log'] as List;
      final last = log.last as Map<String, dynamic>;
      expect(last['type'], 'BombPot');
      expect(last['description'], contains('50'));
    });

    test('RunItChoice appears in log', () {
      final session = _createSession();
      session.addEvent(RunItChoice(3));
      final json = session.toJson();
      final log = json['log'] as List;
      final last = log.last as Map<String, dynamic>;
      expect(last['type'], 'RunIt');
      expect(last['description'], contains('3'));
    });

    test('ManualNextHand appears in log', () {
      final session = _createSession();
      session.addEvent(const ManualNextHand());
      final json = session.toJson();
      final log = json['log'] as List;
      final last = log.last as Map<String, dynamic>;
      expect(last['type'], 'NextHand');
      expect(last['description'], contains('ManualNextHand'));
    });

    test('MuckDecision appears in log', () {
      final session = _createSession();
      session.addEvent(MuckDecision(0, showCards: false));
      final json = session.toJson();
      final log = json['log'] as List;
      final last = log.last as Map<String, dynamic>;
      expect(last['type'], 'Muck');
      expect(last['description'], contains('MuckDecision'));
    });
  });

  group('H2 field updates after events', () {
    test('handNumber increments after HandEnd', () {
      final session = _createSession();
      session.addEvent(
          HandStart(dealerSeat: 0, blinds: {1: 5, 2: 10}));
      session.addEvent(const HandEnd());
      final json = session.toJson();
      expect(json['handNumber'], equals(1));
    });

    test('isAllInRunout true when all active are all-in', () {
      final variant = _nlh();
      final seats = [
        Seat(index: 0, label: 'P0', stack: 0, status: SeatStatus.allIn),
        Seat(index: 1, label: 'P1', stack: 0, status: SeatStatus.allIn),
        Seat(index: 2, label: 'P2', stack: 0, status: SeatStatus.folded),
      ];
      final deck = variant.createDeck(seed: 1);
      final initial = GameState(
        sessionId: 'allin-test',
        variantName: variant.name,
        seats: seats,
        deck: deck,
        dealerSeat: 0,
      );
      final session =
          Session(id: 'allin-test', variant: variant, initial: initial);
      final json = session.toJson();
      expect(json['isAllInRunout'], isTrue);
    });

    test('preflop complete auto-deals 3 flop community cards', () {
      // _maybeAutoAdvanceStreet is triggered by Server._addEvent.
      // Simulate the same logic here: after each PlayerAction, auto-advance
      // street and deal community cards when round is complete.
      final session = _createSession(seatCount: 3, dealerSeat: 0);
      session.addEvent(HandStart(dealerSeat: 0, blinds: {1: 5, 2: 10}));
      session.addEvent(DealHoleCards({
        0: [Card.parse('As'), Card.parse('Kh')],
        1: [Card.parse('Qd'), Card.parse('Jc')],
        2: [Card.parse('Th'), Card.parse('9s')],
      }));
      // UTG(0) call, SB(1) call, BB(2) check → preflop complete
      _applyPlayerAction(session, PlayerAction(0, Call(10)));
      _applyPlayerAction(session, PlayerAction(1, Call(5)));
      _applyPlayerAction(session, PlayerAction(2, const Check()));

      final state = session.currentState;
      expect(state.street, equals(Street.flop));
      expect(state.community.length, equals(3));
    });

    test('flop complete auto-deals 1 turn community card', () {
      final session = _createSession(seatCount: 3, dealerSeat: 0);
      session.addEvent(HandStart(dealerSeat: 0, blinds: {1: 5, 2: 10}));
      session.addEvent(DealHoleCards({
        0: [Card.parse('As'), Card.parse('Kh')],
        1: [Card.parse('Qd'), Card.parse('Jc')],
        2: [Card.parse('Th'), Card.parse('9s')],
      }));
      // Preflop
      _applyPlayerAction(session, PlayerAction(0, Call(10)));
      _applyPlayerAction(session, PlayerAction(1, Call(5)));
      _applyPlayerAction(session, PlayerAction(2, const Check()));
      // Flop: SB(1) check, BB(2) check, dealer(0) check
      _applyPlayerAction(session, PlayerAction(1, const Check()));
      _applyPlayerAction(session, PlayerAction(2, const Check()));
      _applyPlayerAction(session, PlayerAction(0, const Check()));

      final state = session.currentState;
      expect(state.street, equals(Street.turn));
      expect(state.community.length, equals(4));
    });
  });
}
