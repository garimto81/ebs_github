import 'package:test/test.dart';
import 'package:ebs_game_engine/engine.dart';

void main() {
  group('Street enum extension', () {
    test('setupHand exists', () {
      expect(Street.setupHand, isNotNull);
      expect(Street.setupHand.name, 'setupHand');
    });

    test('runItMultiple exists', () {
      expect(Street.runItMultiple, isNotNull);
      expect(Street.runItMultiple.name, 'runItMultiple');
    });

    test('values count is 7', () {
      expect(Street.values.length, 7);
    });

    test('setupHand.index < preflop.index', () {
      expect(Street.setupHand.index, lessThan(Street.preflop.index));
    });

    test('runItMultiple.index > showdown.index', () {
      expect(Street.runItMultiple.index, greaterThan(Street.showdown.index));
    });

    test('original values are preserved in order', () {
      final names = Street.values.map((s) => s.name).toList();
      expect(names, [
        'setupHand',
        'preflop',
        'flop',
        'turn',
        'river',
        'showdown',
        'runItMultiple',
      ]);
    });
  });

  group('StreetMachine with new streets', () {
    test('setupHand -> preflop via nextStreet', () {
      expect(StreetMachine.nextStreet(Street.setupHand), Street.preflop);
    });

    test('runItMultiple throws on nextStreet', () {
      expect(
        () => StreetMachine.nextStreet(Street.runItMultiple),
        throwsStateError,
      );
    });

    test('communityCardsToDeal setupHand = 0', () {
      expect(StreetMachine.communityCardsToDeal(Street.setupHand), 0);
    });

    test('communityCardsToDeal runItMultiple = 0', () {
      expect(StreetMachine.communityCardsToDeal(Street.runItMultiple), 0);
    });

    test('firstToAct returns -1 for setupHand', () {
      final state = GameState(
        sessionId: 'test',
        variantName: 'NLH',
        seats: [
          Seat(index: 0, label: 'S0', stack: 1000),
          Seat(index: 1, label: 'S1', stack: 1000),
        ],
        deck: Deck.standard(),
        street: Street.setupHand,
      );
      expect(StreetMachine.firstToAct(state), -1);
    });
  });

  group('GameState new fields defaults', () {
    late GameState state;

    setUp(() {
      state = GameState(
        sessionId: 'test',
        variantName: 'NLH',
        seats: [Seat(index: 0, label: 'S0', stack: 1000)],
        deck: Deck.standard(),
      );
    });

    test('handNumber defaults to 0', () {
      expect(state.handNumber, 0);
    });

    test('anteAmount defaults to null', () {
      expect(state.anteAmount, isNull);
    });

    test('anteType defaults to null', () {
      expect(state.anteType, isNull);
    });

    test('straddleEnabled defaults to false', () {
      expect(state.straddleEnabled, false);
    });

    test('straddleSeat defaults to null', () {
      expect(state.straddleSeat, isNull);
    });

    test('revealConfig defaults to null', () {
      expect(state.revealConfig, isNull);
    });

    test('canvasType defaults to broadcast', () {
      expect(state.canvasType, CanvasType.broadcast);
    });

    test('bombPotEnabled defaults to false', () {
      expect(state.bombPotEnabled, false);
    });

    test('bombPotAmount defaults to null', () {
      expect(state.bombPotAmount, isNull);
    });

    test('sevenDeuceEnabled defaults to false', () {
      expect(state.sevenDeuceEnabled, false);
    });

    test('sevenDeuceAmount defaults to null', () {
      expect(state.sevenDeuceAmount, isNull);
    });

    test('runItTimes defaults to null', () {
      expect(state.runItTimes, isNull);
    });

    test('actionTimeoutMs defaults to null', () {
      expect(state.actionTimeoutMs, isNull);
    });
  });

  group('GameState copyWith new fields', () {
    late GameState base;

    setUp(() {
      base = GameState(
        sessionId: 'test',
        variantName: 'NLH',
        seats: [Seat(index: 0, label: 'S0', stack: 1000)],
        deck: Deck.standard(),
      );
    });

    test('copyWith handNumber', () {
      final copy = base.copyWith(handNumber: 42);
      expect(copy.handNumber, 42);
      expect(base.handNumber, 0);
    });

    test('copyWith anteAmount and anteType', () {
      final copy = base.copyWith(anteAmount: 100, anteType: 3);
      expect(copy.anteAmount, 100);
      expect(copy.anteType, 3);
    });

    test('copyWith straddleEnabled and straddleSeat', () {
      final copy = base.copyWith(straddleEnabled: true, straddleSeat: 2);
      expect(copy.straddleEnabled, true);
      expect(copy.straddleSeat, 2);
    });

    test('copyWith revealConfig', () {
      const config = CardRevealConfig(
        revealType: RevealType.winnerOnly,
        showType: ShowType.oneCard,
        foldHideType: FoldHideType.briefRevealThenHide,
      );
      final copy = base.copyWith(revealConfig: config);
      expect(copy.revealConfig, isNotNull);
      expect(copy.revealConfig!.revealType, RevealType.winnerOnly);
      expect(copy.revealConfig!.showType, ShowType.oneCard);
      expect(copy.revealConfig!.foldHideType, FoldHideType.briefRevealThenHide);
    });

    test('copyWith canvasType', () {
      final copy = base.copyWith(canvasType: CanvasType.venue);
      expect(copy.canvasType, CanvasType.venue);
    });

    test('copyWith bombPot fields', () {
      final copy = base.copyWith(bombPotEnabled: true, bombPotAmount: 500);
      expect(copy.bombPotEnabled, true);
      expect(copy.bombPotAmount, 500);
    });

    test('copyWith sevenDeuce fields', () {
      final copy = base.copyWith(sevenDeuceEnabled: true, sevenDeuceAmount: 200);
      expect(copy.sevenDeuceEnabled, true);
      expect(copy.sevenDeuceAmount, 200);
    });

    test('copyWith runItTimes', () {
      final copy = base.copyWith(runItTimes: 2);
      expect(copy.runItTimes, 2);
    });

    test('copyWith actionTimeoutMs', () {
      final copy = base.copyWith(actionTimeoutMs: 30000);
      expect(copy.actionTimeoutMs, 30000);
    });
  });

  group('CardRevealConfig integration in GameState', () {
    test('GameState with broadcast config', () {
      final state = GameState(
        sessionId: 'test',
        variantName: 'NLH',
        seats: [Seat(index: 0, label: 'S0', stack: 1000)],
        deck: Deck.standard(),
        revealConfig: CardRevealConfig.broadcast,
        canvasType: CanvasType.broadcast,
      );
      expect(state.revealConfig!.revealType, RevealType.lastAggressorFirst);
      expect(state.canvasType, CanvasType.broadcast);
    });

    test('GameState with venue config', () {
      final state = GameState(
        sessionId: 'test',
        variantName: 'NLH',
        seats: [Seat(index: 0, label: 'S0', stack: 1000)],
        deck: Deck.standard(),
        revealConfig: CardRevealConfig.venue,
        canvasType: CanvasType.venue,
      );
      expect(state.revealConfig!.revealType, RevealType.externalControl);
      expect(state.canvasType, CanvasType.venue);
    });
  });
}
