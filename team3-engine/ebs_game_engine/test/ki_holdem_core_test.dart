/// Hold'em Core KI Bug Reproduction Tests
/// KI-03 (Side Pot integration), KI-05 (Raise overflow), KI-09 (Invalid transitions)
import 'package:test/test.dart';
import 'package:ebs_game_engine/engine.dart';

/// Helper: create a minimal NLH GameState for testing
GameState _makeState({
  required List<int> stacks,
  int dealer = 0,
  int bb = 10,
  int sb = 5,
}) {
  final seats = <Seat>[];
  for (var i = 0; i < stacks.length; i++) {
    seats.add(Seat(
      index: i,
      label: 'P$i',
      stack: stacks[i],
      isDealer: i == dealer,
    ));
  }

  return GameState(
    sessionId: 'test',
    variantName: 'nlh',
    seats: seats,
    deck: Deck.standard(seed: 42),
    bbAmount: bb,
  );
}

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // KI-05: Raise toAmount > stack → 음수 stack
  // File: betting_rules.dart L146-148
  // Bug: `increment = toAmount - seat.currentBet; seat.stack -= increment;`
  //      No guard when increment > stack.
  // ═══════════════════════════════════════════════════════════════════════════
  group('KI-05: Raise overflow', () {
    test('Raise with toAmount > stack should not produce negative stack', () {
      // Setup: P0 has 100 stack, currentBet=10, tries Raise(200)
      // increment = 200 - 10 = 190, but stack is only 100
      var state = _makeState(stacks: [100, 1000, 1000]);

      // Start hand: dealer=0, SB=1(5), BB=2(10)
      state = Engine.apply(state, HandStart(
        dealerSeat: 0,
        blinds: {1: 5, 2: 10},
      ));

      // Deal hole cards
      state = Engine.apply(state, DealHoleCards({
        0: [Card.parse('As'), Card.parse('Ad')],
        1: [Card.parse('Ks'), Card.parse('Kh')],
        2: [Card.parse('Qs'), Card.parse('Qh')],
      }));

      // P0 (first to act in 3-player preflop) tries Raise(200)
      // P0 stack=100, currentBet=0, so increment=200 > stack
      state = Engine.apply(state, PlayerAction(0, Raise(200)));

      // Stack should NEVER be negative
      final p0 = state.seats[0];
      expect(p0.stack, greaterThanOrEqualTo(0),
          reason: 'KI-05: stack must never go negative after raise');
    });

    test('Raise exceeding stack should clamp to all-in', () {
      var state = _makeState(stacks: [100, 1000, 1000]);

      state = Engine.apply(state, HandStart(
        dealerSeat: 0,
        blinds: {1: 5, 2: 10},
      ));

      state = Engine.apply(state, DealHoleCards({
        0: [Card.parse('As'), Card.parse('Ad')],
        1: [Card.parse('Ks'), Card.parse('Kh')],
        2: [Card.parse('Qs'), Card.parse('Qh')],
      }));

      // P0 tries to raise more than their stack
      state = Engine.apply(state, PlayerAction(0, Raise(200)));

      final p0 = state.seats[0];
      expect(p0.stack, equals(0),
          reason: 'Should be clamped to all-in (stack=0)');
      expect(p0.isAllIn, isTrue,
          reason: 'Status should be allIn when raise exceeds stack');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // KI-09: Invalid state transitions not blocked
  // File: engine.dart _streetAdvance()
  // Bug: StreetAdvance accepts any target street without validation.
  //      PRE_FLOP → RIVER should be rejected.
  // ═══════════════════════════════════════════════════════════════════════════
  group('KI-09: Invalid state transitions', () {
    test('PRE_FLOP → RIVER should be rejected (must go through FLOP, TURN)', () {
      var state = _makeState(stacks: [1000, 1000]);

      state = Engine.apply(state, HandStart(
        dealerSeat: 0,
        blinds: {0: 5, 1: 10},
      ));

      state = Engine.apply(state, DealHoleCards({
        0: [Card.parse('As'), Card.parse('Ad')],
        1: [Card.parse('Ks'), Card.parse('Kh')],
      }));

      expect(state.street, equals(Street.preflop));

      // Try to jump directly to RIVER — should be rejected
      final afterBadAdvance = Engine.apply(
        state,
        StreetAdvance(Street.river),
      );

      // Street should NOT be river — transition is invalid
      expect(afterBadAdvance.street, isNot(equals(Street.river)),
          reason: 'KI-09: PRE_FLOP→RIVER direct jump must be blocked');
    });

    test('FLOP → SHOWDOWN should be rejected (must go through TURN, RIVER)', () {
      var state = _makeState(stacks: [1000, 1000]);

      state = Engine.apply(state, HandStart(
        dealerSeat: 0,
        blinds: {0: 5, 1: 10},
      ));

      state = Engine.apply(state, DealHoleCards({
        0: [Card.parse('As'), Card.parse('Ad')],
        1: [Card.parse('Ks'), Card.parse('Kh')],
      }));

      // Advance to FLOP (valid)
      state = Engine.apply(state, StreetAdvance(Street.flop));
      expect(state.street, equals(Street.flop));

      // Try FLOP → SHOWDOWN (invalid)
      final afterBadAdvance = Engine.apply(
        state,
        StreetAdvance(Street.showdown),
      );

      expect(afterBadAdvance.street, isNot(equals(Street.showdown)),
          reason: 'KI-09: FLOP→SHOWDOWN direct jump must be blocked');
    });

    test('valid transitions should still work: preflop→flop→turn→river', () {
      var state = _makeState(stacks: [1000, 1000]);

      state = Engine.apply(state, HandStart(
        dealerSeat: 0,
        blinds: {0: 5, 1: 10},
      ));

      state = Engine.apply(state, DealHoleCards({
        0: [Card.parse('As'), Card.parse('Ad')],
        1: [Card.parse('Ks'), Card.parse('Kh')],
      }));

      state = Engine.apply(state, StreetAdvance(Street.flop));
      expect(state.street, equals(Street.flop));

      state = Engine.apply(state, StreetAdvance(Street.turn));
      expect(state.street, equals(Street.turn));

      state = Engine.apply(state, StreetAdvance(Street.river));
      expect(state.street, equals(Street.river));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // KI-03: Side Pot — engine never calls calculateSidePots()
  // File: pot.dart + engine.dart
  // Bug: All bets go to pot.main. Side pots are never generated.
  //      seat.currentBet is reset each street, losing cumulative data.
  // ═══════════════════════════════════════════════════════════════════════════
  group('KI-03: Side Pot engine integration', () {
    test('all-in with different stacks should create side pots', () {
      var state = _makeState(stacks: [500, 1000, 2000]);

      state = Engine.apply(state, HandStart(
        dealerSeat: 0,
        blinds: {1: 5, 2: 10},
      ));

      state = Engine.apply(state, DealHoleCards({
        0: [Card.parse('As'), Card.parse('Ad')],
        1: [Card.parse('Ks'), Card.parse('Kh')],
        2: [Card.parse('Qs'), Card.parse('Qh')],
      }));

      // P0 all-in 500
      state = Engine.apply(state, PlayerAction(0, AllIn(500)));
      // P1 all-in 1000
      state = Engine.apply(state, PlayerAction(1, AllIn(1000)));
      // P2 calls 1000
      state = Engine.apply(state, PlayerAction(2, Call(1000)));

      // After 3 all-ins, pot should have side pots
      // Main pot: 500 × 3 = 1500 (all eligible)
      // Side pot: 500 × 2 = 1000 (P1, P2 only)
      expect(state.pot.sides.isNotEmpty, isTrue,
          reason: 'KI-03: Engine must create side pots after multi-way all-in');

      // Total must equal sum of contributions
      // P0: 500, P1: 1000 (5 blind + 995), P2: 1000 (10 blind + 990)
      // But blinds are posted first, then actions
      final total = state.pot.total;
      expect(total, greaterThan(0),
          reason: 'Pot total must reflect all contributions');
    });

    test('currentBet should preserve cumulative contributions across streets', () {
      var state = _makeState(stacks: [1000, 1000]);

      state = Engine.apply(state, HandStart(
        dealerSeat: 0,
        blinds: {0: 5, 1: 10},
      ));

      state = Engine.apply(state, DealHoleCards({
        0: [Card.parse('As'), Card.parse('Ad')],
        1: [Card.parse('Ks'), Card.parse('Kh')],
      }));

      // P0 calls 10, P1 checks
      state = Engine.apply(state, PlayerAction(0, Call(10)));
      state = Engine.apply(state, PlayerAction(1, Check()));

      final potAfterPreflop = state.pot.total;
      expect(potAfterPreflop, equals(20),
          reason: 'Pot after preflop: SB5+BB10+Call5 = 20');

      // Advance to flop
      state = Engine.apply(state, StreetAdvance(Street.flop));

      // After street advance, pot total should be preserved
      expect(state.pot.total, equals(potAfterPreflop),
          reason: 'Pot total must persist across street advances');
    });
  });
}
