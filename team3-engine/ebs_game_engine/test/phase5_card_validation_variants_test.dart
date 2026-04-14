import 'package:test/test.dart';
import 'package:ebs_game_engine/engine.dart';

/// Helper: create a simple GameState for testing.
GameState _makeState({
  int seatCount = 3,
  int bbAmount = 10,
}) {
  final seats = List.generate(
    seatCount,
    (i) => Seat(index: i, label: 'P${i + 1}', stack: 1000),
  );
  final deck = Deck.standard();
  return GameState(
    sessionId: 'test',
    variantName: 'nlh',
    seats: seats,
    deck: deck,
    bbAmount: bbAmount,
  );
}

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // Task 5.3: Card Mismatch / Wrong Card Detection
  // ═══════════════════════════════════════════════════════════════════════════
  group('Engine.validateCards', () {
    test('empty state returns no duplicates', () {
      final state = _makeState();
      expect(Engine.validateCards(state), isEmpty);
    });

    test('no duplicates with unique cards returns empty list', () {
      final state = _makeState(seatCount: 2);
      // Deal unique hole cards to each seat
      state.seats[0].holeCards = [Card.parse('As'), Card.parse('Kh')];
      state.seats[1].holeCards = [Card.parse('Qd'), Card.parse('Jc')];
      expect(Engine.validateCards(state), isEmpty);
    });

    test('full valid deal (2 players + 5 community, all unique) returns empty',
        () {
      final state = _makeState(seatCount: 2);
      state.seats[0].holeCards = [Card.parse('As'), Card.parse('Kh')];
      state.seats[1].holeCards = [Card.parse('Qd'), Card.parse('Jc')];
      final community = [
        Card.parse('Ts'),
        Card.parse('9h'),
        Card.parse('8d'),
        Card.parse('7c'),
        Card.parse('6s'),
      ];
      final stateWithCommunity = state.copyWith(community: community);
      expect(Engine.validateCards(stateWithCommunity), isEmpty);
    });

    test('duplicate hole card within same seat detected', () {
      final state = _makeState(seatCount: 1);
      state.seats[0].holeCards = [Card.parse('As'), Card.parse('As')];
      final result = Engine.validateCards(state);
      expect(result, hasLength(1));
      expect(result.first, contains('Duplicate card at seat 0'));
    });

    test('same card in two different seats detected', () {
      final state = _makeState(seatCount: 2);
      state.seats[0].holeCards = [Card.parse('As'), Card.parse('Kh')];
      state.seats[1].holeCards = [Card.parse('As'), Card.parse('Qd')];
      final result = Engine.validateCards(state);
      expect(result, hasLength(1));
      expect(result.first, contains('Duplicate card at seat 1'));
    });

    test('duplicate community card detected', () {
      final state = _makeState();
      final community = [
        Card.parse('Ts'),
        Card.parse('9h'),
        Card.parse('Ts'),
      ];
      final stateWithCommunity = state.copyWith(community: community);
      final result = Engine.validateCards(stateWithCommunity);
      expect(result, hasLength(1));
      expect(result.first, contains('Duplicate community card'));
    });

    test('same card in hole and community detected', () {
      final state = _makeState(seatCount: 1);
      state.seats[0].holeCards = [Card.parse('As'), Card.parse('Kh')];
      final community = [Card.parse('As'), Card.parse('Qd'), Card.parse('Jc')];
      final stateWithCommunity = state.copyWith(community: community);
      final result = Engine.validateCards(stateWithCommunity);
      expect(result, hasLength(1));
      expect(result.first, contains('Duplicate card at seat 0'));
    });

    test('multiple duplicates all reported', () {
      final state = _makeState(seatCount: 2);
      state.seats[0].holeCards = [Card.parse('As'), Card.parse('Kh')];
      state.seats[1].holeCards = [Card.parse('As'), Card.parse('Kh')];
      final result = Engine.validateCards(state);
      expect(result, hasLength(2));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Task 5.4: FL Hold'em Variant
  // ═══════════════════════════════════════════════════════════════════════════
  group('FixedLimitHoldem variant', () {
    test('properties: name, holeCardCount, communityCardCount, isHiLo', () {
      final flh = FixedLimitHoldem();
      expect(flh.name, "FL Hold'em");
      expect(flh.holeCardCount, 2);
      expect(flh.communityCardCount, 5);
      expect(flh.isHiLo, false);
    });

    test('betLimit is FixedLimitBet', () {
      final flh = FixedLimitHoldem();
      expect(flh.betLimit, isA<FixedLimitBet>());
    });

    test('evaluateHi produces valid hand rank', () {
      final flh = FixedLimitHoldem();
      final hole = [Card.parse('As'), Card.parse('Ks')];
      final community = [
        Card.parse('Qs'),
        Card.parse('Js'),
        Card.parse('Ts'),
        Card.parse('2h'),
        Card.parse('3d'),
      ];
      final rank = flh.evaluateHi(hole, community);
      // Royal flush (A-K-Q-J-T of spades)
      expect(rank.category, HandCategory.royalFlush);
    });

    test('registry lookup flh returns FixedLimitHoldem', () {
      final factory = variantRegistry['flh'];
      expect(factory, isNotNull);
      expect(factory!(), isA<FixedLimitHoldem>());
    });

    test('custom smallBet/bigBet', () {
      final flh = FixedLimitHoldem(smallBet: 5, bigBet: 10);
      final limit = flh.betLimit as FixedLimitBet;
      expect(limit.smallBet, 5);
      expect(limit.bigBet, 10);
    });

    test('registry flh_5_10 has correct bet sizes', () {
      final variant = variantRegistry['flh_5_10']!() as FixedLimitHoldem;
      final limit = variant.betLimit as FixedLimitBet;
      expect(limit.smallBet, 5);
      expect(limit.bigBet, 10);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Task 5.4: PL Hold'em Variant
  // ═══════════════════════════════════════════════════════════════════════════
  group('PotLimitHoldem variant', () {
    test('properties: name, holeCardCount, communityCardCount, isHiLo', () {
      final plh = PotLimitHoldem();
      expect(plh.name, "PL Hold'em");
      expect(plh.holeCardCount, 2);
      expect(plh.communityCardCount, 5);
      expect(plh.isHiLo, false);
    });

    test('betLimit is PotLimitBet', () {
      final plh = PotLimitHoldem();
      expect(plh.betLimit, isA<PotLimitBet>());
    });

    test('evaluateHi produces valid hand rank', () {
      final plh = PotLimitHoldem();
      final hole = [Card.parse('Ah'), Card.parse('Ad')];
      final community = [
        Card.parse('As'),
        Card.parse('Ac'),
        Card.parse('Kh'),
        Card.parse('2d'),
        Card.parse('3c'),
      ];
      final rank = plh.evaluateHi(hole, community);
      expect(rank.category, HandCategory.fourOfAKind);
    });

    test('registry lookup plh returns PotLimitHoldem', () {
      final factory = variantRegistry['plh'];
      expect(factory, isNotNull);
      expect(factory!(), isA<PotLimitHoldem>());
    });

    test('NLH default betLimit is NoLimitBet', () {
      final nlh = Nlh();
      expect(nlh.betLimit, isA<NoLimitBet>());
    });
  });
}
