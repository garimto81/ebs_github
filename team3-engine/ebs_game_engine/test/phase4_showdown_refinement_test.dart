import 'package:test/test.dart';
import 'package:ebs_game_engine/engine.dart';

/// Helper: create a simple GameState for testing.
GameState _makeState({
  int seatCount = 3,
  int dealerSeat = 0,
  List<int>? stacks,
  int bbAmount = 10,
  int lastAggressor = -1,
  CardRevealConfig? revealConfig,
  CanvasType canvasType = CanvasType.broadcast,
}) {
  final seats = List.generate(seatCount, (i) => Seat(
    index: i,
    label: 'P${i + 1}',
    stack: stacks != null ? stacks[i] : 1000,
  ));
  final deck = Deck.standard();
  final state = GameState(
    sessionId: 'test',
    variantName: 'nlh',
    seats: seats,
    deck: deck,
    dealerSeat: dealerSeat,
    bbAmount: bbAmount,
    revealConfig: revealConfig,
    canvasType: canvasType,
  );
  state.betting.lastAggressor = lastAggressor;
  return state;
}

/// Helper: create cards for testing hand evaluation.
List<Card> _parseCards(List<String> notations) =>
    notations.map(Card.parse).toList();

void main() {
  final nlh = Nlh();

  // ═══════════════════════════════════════════════════════════════════════════
  // Task 4.1: Side Pot Reverse-Order Judgment
  // ═══════════════════════════════════════════════════════════════════════════
  group('Side Pot Reverse Order', () {
    test('3-way all-in: pots evaluated smallest eligible first', () {
      // P0: 100 chips, P1: 200 chips, P2: 300 chips (all-in)
      // Main pot (100*3=300, eligible: {0,1,2})
      // Side pot 1 (100*2=200, eligible: {1,2})
      // Side pot 2 (100*1=100, eligible: {2})
      // Evaluation order should be: {2} first, then {1,2}, then {0,1,2}
      final seats = [
        Seat(index: 0, label: 'P1', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['As', 'Ks'])), // Best hand
        Seat(index: 1, label: 'P2', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['Qd', 'Qc'])),
        Seat(index: 2, label: 'P3', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['2h', '3h'])), // Worst hand
      ];
      final community = _parseCards(['Ah', 'Kd', '7s', '8c', '9d']);

      final pots = [
        SidePot(300, {0, 1, 2}), // Main pot (3 eligible)
        SidePot(200, {1, 2}),     // Side pot 1 (2 eligible)
        SidePot(100, {2}),        // Side pot 2 (1 eligible, only P2)
      ];

      final awards = Showdown.evaluate(
        seats: seats,
        community: community,
        pots: pots,
        variant: nlh,
        dealerSeat: 0,
      );

      // Pot {2} (100): P2 sole eligible → wins 100
      // Pot {1,2} (200): P1 (QQ) beats P2 (23) → P1 wins 200
      // Pot {0,1,2} (300): P0 (AKs) makes top pair → P0 wins 300
      expect(awards[0], 300);
      expect(awards[1], 200);
      expect(awards[2], 100);
    });

    test('4-way all-in: correct ordering', () {
      final seats = [
        Seat(index: 0, label: 'P1', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['As', 'Ks'])),
        Seat(index: 1, label: 'P2', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['Qd', 'Qc'])),
        Seat(index: 2, label: 'P3', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['Jd', 'Jc'])),
        Seat(index: 3, label: 'P4', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['2h', '3h'])),
      ];
      final community = _parseCards(['Ah', 'Kd', '7s', '8c', '9d']);

      // Pots given in forward order
      final pots = [
        SidePot(400, {0, 1, 2, 3}), // 4 eligible
        SidePot(300, {1, 2, 3}),     // 3 eligible
        SidePot(200, {2, 3}),         // 2 eligible
        SidePot(100, {3}),            // 1 eligible
      ];

      final awards = Showdown.evaluate(
        seats: seats,
        community: community,
        pots: pots,
        variant: nlh,
        dealerSeat: 0,
      );

      // P3 (seat 3) wins 100 (sole eligible)
      // P2 (seat 2, JJ) wins 200 (beats P3's 2h3h, in {2,3})
      // P1 (seat 1, QQ) wins 300 (beats JJ and 23, in {1,2,3})
      // P0 (seat 0, AKs) wins 400 (best hand)
      expect(awards[3], 100);
      expect(awards[2], 200);
      expect(awards[1], 300);
      expect(awards[0], 400);
    });

    test('single pot: no change in behavior', () {
      final seats = [
        Seat(index: 0, label: 'P1', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['As', 'Ks'])),
        Seat(index: 1, label: 'P2', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['Qd', 'Qc'])),
      ];
      final community = _parseCards(['Ah', '7d', '8s', '2c', '3d']);

      final pots = [SidePot(200, {0, 1})];
      final awards = Showdown.evaluate(
        seats: seats,
        community: community,
        pots: pots,
        variant: nlh,
        dealerSeat: 0,
      );

      expect(awards[0], 200);
      expect(awards.containsKey(1), false);
    });

    test('pots with same eligible size preserve stable order', () {
      // Two pots with 2 eligible each — both processed
      final seats = [
        Seat(index: 0, label: 'P1', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['As', 'Ks'])),
        Seat(index: 1, label: 'P2', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['Qd', 'Qc'])),
      ];
      final community = _parseCards(['Ah', '7d', '8s', '2c', '3d']);

      final pots = [
        SidePot(100, {0, 1}),
        SidePot(200, {0, 1}),
      ];
      final awards = Showdown.evaluate(
        seats: seats,
        community: community,
        pots: pots,
        variant: nlh,
        dealerSeat: 0,
      );

      expect(awards[0], 300); // Wins both
    });

    test('empty eligible set after filtering folded is skipped', () {
      final seats = [
        Seat(index: 0, label: 'P1', stack: 0, status: SeatStatus.folded,
            holeCards: []),
        Seat(index: 1, label: 'P2', stack: 1000, status: SeatStatus.active,
            holeCards: _parseCards(['Qd', 'Qc'])),
      ];
      final community = _parseCards(['Ah', '7d', '8s', '2c', '3d']);

      // A pot where all eligible have folded
      final pots = [
        SidePot(100, {0}), // P0 folded — empty after filter
        SidePot(200, {0, 1}), // P1 wins
      ];
      final awards = Showdown.evaluate(
        seats: seats,
        community: community,
        pots: pots,
        variant: nlh,
        dealerSeat: 0,
      );

      expect(awards[1], 200);
      expect(awards.containsKey(0), false);
    });

    test('sorted order is ascending by eligible count', () {
      // Provide pots in descending order; verify they are sorted
      final seats = [
        Seat(index: 0, label: 'P1', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['As', 'Ks'])),
        Seat(index: 1, label: 'P2', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['2h', '3h'])),
        Seat(index: 2, label: 'P3', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['4d', '5d'])),
      ];
      final community = _parseCards(['Ah', 'Kd', '7s', '8c', '9d']);

      // Given in descending order (3, 2, 1)
      final pots = [
        SidePot(300, {0, 1, 2}),
        SidePot(200, {0, 1}),
        SidePot(100, {0}),
      ];

      final awards = Showdown.evaluate(
        seats: seats,
        community: community,
        pots: pots,
        variant: nlh,
        dealerSeat: 0,
      );

      // P0 wins all (best hand)
      expect(awards[0], 600);
    });

    test('side pot winner gets correct total across multiple pots', () {
      final seats = [
        Seat(index: 0, label: 'P1', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['2h', '3h'])), // Worst
        Seat(index: 1, label: 'P2', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['Qs', 'Qd'])), // Medium
        Seat(index: 2, label: 'P3', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['As', 'Ks'])), // Best
      ];
      final community = _parseCards(['Ah', 'Kd', '7s', '8c', '9d']);

      final pots = [
        SidePot(300, {0, 1, 2}),
        SidePot(200, {1, 2}),
      ];

      final awards = Showdown.evaluate(
        seats: seats,
        community: community,
        pots: pots,
        variant: nlh,
      );

      expect(awards[2], 500); // Wins both pots
      expect(awards.containsKey(0), false);
      expect(awards.containsKey(1), false);
    });

    test('sole eligible winner takes entire pot regardless of order', () {
      // Only 1 eligible player in each pot — no hand evaluation needed
      final seats = [
        Seat(index: 0, label: 'P1', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['As', 'Ks'])),
        Seat(index: 1, label: 'P2', stack: 0, status: SeatStatus.folded,
            holeCards: []),
      ];
      final community = _parseCards(['Ah', '7d', '8s', '2c', '3d']);

      final pots = [
        SidePot(150, {0}),
        SidePot(50, {0}),
      ];
      final awards = Showdown.evaluate(
        seats: seats,
        community: community,
        pots: pots,
        variant: nlh,
      );

      expect(awards[0], 200);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Task 4.2: Odd Chip Allocation (Dealer-Left)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Odd Chip Allocation', () {
    test('2 winners, odd pot: dealer-left winner gets extra chip', () {
      // Dealer at seat 0, winners at seats 1 and 2
      // Seat 1 is closer to dealer's left → gets odd chip
      final seats = [
        Seat(index: 0, label: 'P1', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['2h', '3h'])),
        Seat(index: 1, label: 'P2', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['As', 'Ks'])),
        Seat(index: 2, label: 'P3', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['Ad', 'Kd'])), // Tie with P2
      ];
      final community = _parseCards(['Ah', 'Kh', '7s', '8c', '9d']);

      final pots = [SidePot(301, {0, 1, 2})]; // 301 / 2 = 150 each + 1 odd
      final awards = Showdown.evaluate(
        seats: seats,
        community: community,
        pots: pots,
        variant: nlh,
        dealerSeat: 0,
      );

      // Tied winners: seats 1 and 2
      // Dealer at 0, seat 1 is closest to dealer's left
      expect(awards[1], 151); // 150 + 1 odd chip
      expect(awards[2], 150);
    });

    test('3 winners, pot not divisible by 3', () {
      final seats = [
        Seat(index: 0, label: 'P1', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['As', 'Ks'])),
        Seat(index: 1, label: 'P2', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['Ad', 'Kd'])),
        Seat(index: 2, label: 'P3', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['Ac', 'Kc'])),
      ];
      final community = _parseCards(['Ah', 'Kh', '7s', '8c', '9d']);

      // 302 / 3 = 100 r 2 → seats closest to dealer's left get 1 each
      final pots = [SidePot(302, {0, 1, 2})];
      final awards = Showdown.evaluate(
        seats: seats,
        community: community,
        pots: pots,
        variant: nlh,
        dealerSeat: 0,
      );

      // Dealer at 0, clockwise: 1, 2, 0
      // First 2 get odd chips: seats 1 and 2
      expect(awards[1], 101);
      expect(awards[2], 101);
      expect(awards[0], 100);
    });

    test('dealer at different position changes odd chip recipient', () {
      final seats = [
        Seat(index: 0, label: 'P1', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['As', 'Ks'])),
        Seat(index: 1, label: 'P2', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['Ad', 'Kd'])),
        Seat(index: 2, label: 'P3', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['Ac', 'Kc'])),
      ];
      final community = _parseCards(['Ah', 'Kh', '7s', '8c', '9d']);

      final pots = [SidePot(301, {0, 1, 2})];

      // Dealer at seat 2
      final awards = Showdown.evaluate(
        seats: seats,
        community: community,
        pots: pots,
        variant: nlh,
        dealerSeat: 2,
      );

      // Clockwise from dealer (2): 0, 1, 2
      // Seat 0 gets the odd chip
      expect(awards[0], 101);
      expect(awards[1], 100);
      expect(awards[2], 100);
    });

    test('without dealerSeat: fallback behavior preserved', () {
      final seats = [
        Seat(index: 0, label: 'P1', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['As', 'Ks'])),
        Seat(index: 1, label: 'P2', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['Ad', 'Kd'])),
      ];
      final community = _parseCards(['Ah', 'Kh', '7s', '8c', '9d']);

      final pots = [SidePot(301, {0, 1})];
      final awards = Showdown.evaluate(
        seats: seats,
        community: community,
        pots: pots,
        variant: nlh,
        // No dealerSeat
      );

      // Fallback: first winner in list gets odd chip
      final total = (awards[0] ?? 0) + (awards[1] ?? 0);
      expect(total, 301);
      // One must get 151, other 150
      expect(
        (awards[0] == 151 && awards[1] == 150) ||
        (awards[0] == 150 && awards[1] == 151),
        true,
      );
    });

    test('even pot: no odd chip issue', () {
      final seats = [
        Seat(index: 0, label: 'P1', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['As', 'Ks'])),
        Seat(index: 1, label: 'P2', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['Ad', 'Kd'])),
      ];
      final community = _parseCards(['Ah', 'Kh', '7s', '8c', '9d']);

      final pots = [SidePot(300, {0, 1})];
      final awards = Showdown.evaluate(
        seats: seats,
        community: community,
        pots: pots,
        variant: nlh,
        dealerSeat: 0,
      );

      expect(awards[0], 150);
      expect(awards[1], 150);
    });

    test('heads-up odd chip goes to non-dealer (dealer-left = opponent)', () {
      final seats = [
        Seat(index: 0, label: 'P1', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['As', 'Ks'])),
        Seat(index: 1, label: 'P2', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['Ad', 'Kd'])),
      ];
      final community = _parseCards(['Ah', 'Kh', '7s', '8c', '9d']);

      // Dealer at seat 0 → dealer's left = seat 1
      final pots = [SidePot(101, {0, 1})];
      final awards = Showdown.evaluate(
        seats: seats,
        community: community,
        pots: pots,
        variant: nlh,
        dealerSeat: 0,
      );

      expect(awards[1], 51); // Dealer-left gets odd chip
      expect(awards[0], 50);
    });

    test('4-seat table, dealer at 2, winners at 0 and 3', () {
      final seats = [
        Seat(index: 0, label: 'P1', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['As', 'Ks'])),
        Seat(index: 1, label: 'P2', stack: 0, status: SeatStatus.folded,
            holeCards: []),
        Seat(index: 2, label: 'P3', stack: 0, status: SeatStatus.folded,
            holeCards: []),
        Seat(index: 3, label: 'P4', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['Ad', 'Kd'])),
      ];
      final community = _parseCards(['Ah', 'Kh', '7s', '8c', '9d']);

      final pots = [SidePot(201, {0, 1, 2, 3})];
      final awards = Showdown.evaluate(
        seats: seats,
        community: community,
        pots: pots,
        variant: nlh,
        dealerSeat: 2,
      );

      // Dealer at 2, clockwise: 3(dist=0), 0(dist=1), 1(dist=2), 2(dist=3)
      // Winners: 0 and 3. Seat 3 is closer to dealer's left
      expect(awards[3], 101);
      expect(awards[0], 100);
    });

    test('odd chip with 5 winners and 3 remainder chips', () {
      final seats = List.generate(5, (i) => Seat(
        index: i, label: 'P${i + 1}', stack: 0, status: SeatStatus.allIn,
        holeCards: _parseCards(['As', 'Ks']),
      ));
      // All same hand — 5-way tie
      // Give seat 1 and 2 different but equivalent cards to maintain tie
      seats[1].holeCards = _parseCards(['Ad', 'Kd']);
      seats[2].holeCards = _parseCards(['Ac', 'Kc']);
      seats[3].holeCards = _parseCards(['Ah', 'Kh']);
      // seats[4] will also tie since community makes the board
      final community = _parseCards(['Qs', 'Qd', 'Qc', 'Qh', 'Jd']);
      // With 4 queens on board, everyone plays QQQQK — all tie

      final pots = [SidePot(503, {0, 1, 2, 3, 4})]; // 503 / 5 = 100 r 3
      final awards = Showdown.evaluate(
        seats: seats,
        community: community,
        pots: pots,
        variant: nlh,
        dealerSeat: 0,
      );

      // Dealer at 0, clockwise: 1(dist=0), 2(dist=1), 3(dist=2), 4(dist=3), 0(dist=4)
      // First 3 get odd chips: seats 1, 2, 3
      expect(awards[1], 101);
      expect(awards[2], 101);
      expect(awards[3], 101);
      expect(awards[4], 100);
      expect(awards[0], 100);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Task 4.3: Fold Player Dead Money
  // ═══════════════════════════════════════════════════════════════════════════
  group('Dead Money (Folded Players)', () {
    test('folded player bet stays in pot', () {
      // Folded players contribute to pot but do not appear in eligible
      final bets = {0: 100, 1: 100, 2: 100};
      final folded = {2}; // Seat 2 folded
      final sidePots = Pot.calculateSidePots(bets: bets, folded: folded);

      // Total should be 300 (including folded player's 100)
      final totalAmount = sidePots.fold(0, (sum, p) => sum + p.amount);
      expect(totalAmount, 300);
    });

    test('folded player NOT in eligible set', () {
      final bets = {0: 100, 1: 100, 2: 100};
      final folded = {2};
      final sidePots = Pot.calculateSidePots(bets: bets, folded: folded);

      for (final pot in sidePots) {
        expect(pot.eligible.contains(2), false);
      }
    });

    test('side pot with folded contributor has correct eligible', () {
      // P0: 50, P1: 100, P2: 100 (folded)
      final bets = {0: 50, 1: 100, 2: 100};
      final folded = {2};
      final sidePots = Pot.calculateSidePots(bets: bets, folded: folded);

      // Level 50: contributors {0,1,2}, amount = 50*3 = 150, eligible = {0,1}
      // Level 100: contributors {1,2}, amount = 50*2 = 100, eligible = {1}
      expect(sidePots.length, 2);
      expect(sidePots[0].amount, 150);
      expect(sidePots[0].eligible, {0, 1});
      expect(sidePots[1].amount, 100);
      expect(sidePots[1].eligible, {1});
    });

    test('all-in player with folded player dead money goes to winner', () {
      final seats = [
        Seat(index: 0, label: 'P1', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['As', 'Ks'])),
        Seat(index: 1, label: 'P2', stack: 0, status: SeatStatus.allIn,
            holeCards: _parseCards(['Qd', 'Qc'])),
        Seat(index: 2, label: 'P3', stack: 900, status: SeatStatus.folded,
            holeCards: []),
      ];
      final community = _parseCards(['Ah', '7d', '8s', '2c', '3d']);

      // P2 folded after putting 100 in. P0 and P1 each put 100.
      final pots = [SidePot(300, {0, 1})]; // P2 money is here but not eligible
      final awards = Showdown.evaluate(
        seats: seats,
        community: community,
        pots: pots,
        variant: nlh,
      );

      expect(awards[0], 300); // P0 wins all including dead money
    });

    test('multiple folded players contribute to main pot', () {
      final bets = {0: 100, 1: 100, 2: 100, 3: 100};
      final folded = {2, 3};
      final sidePots = Pot.calculateSidePots(bets: bets, folded: folded);

      final totalAmount = sidePots.fold(0, (sum, p) => sum + p.amount);
      expect(totalAmount, 400);

      // All pots should exclude folded players from eligible
      for (final pot in sidePots) {
        expect(pot.eligible.intersection({2, 3}).isEmpty, true);
      }
    });

    test('folded player with partial bet creates correct side pots', () {
      // P0: 50 (all-in), P1: 100, P2: 30 (folded)
      final bets = {0: 50, 1: 100, 2: 30};
      final folded = {2};
      final sidePots = Pot.calculateSidePots(bets: bets, folded: folded);

      // Level 30: contributors {0,1,2}, amount = 30*3 = 90, eligible = {0,1}
      // Level 50: contributors {0,1}, amount = 20*2 = 40, eligible = {0,1}
      // Level 100: contributors {1}, amount = 50*1 = 50, eligible = {1}
      expect(sidePots.length, 3);
      expect(sidePots[0].amount, 90);
      expect(sidePots[0].eligible, {0, 1});
      expect(sidePots[1].amount, 40);
      expect(sidePots[1].eligible, {0, 1});
      expect(sidePots[2].amount, 50);
      expect(sidePots[2].eligible, {1});
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Task 4.4: Showdown Order (Last Aggressor First)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Showdown Order', () {
    test('last aggressor first', () {
      final state = _makeState(seatCount: 3, dealerSeat: 0, lastAggressor: 2);
      state.seats[0].holeCards = _parseCards(['As', 'Ks']);
      state.seats[1].holeCards = _parseCards(['Qd', 'Qc']);
      state.seats[2].holeCards = _parseCards(['Jd', 'Jc']);

      final order = ShowdownOrder.getRevealOrder(state);
      expect(order.first, 2); // Last aggressor
      expect(order, [2, 0, 1]); // Then clockwise from aggressor
    });

    test('no aggressor (checked around): dealer-left first', () {
      final state = _makeState(seatCount: 3, dealerSeat: 0, lastAggressor: -1);
      state.seats[0].holeCards = _parseCards(['As', 'Ks']);
      state.seats[1].holeCards = _parseCards(['Qd', 'Qc']);
      state.seats[2].holeCards = _parseCards(['Jd', 'Jc']);

      final order = ShowdownOrder.getRevealOrder(state);
      expect(order, [1, 2, 0]); // Clockwise from dealer
    });

    test('3 players, aggressor at seat 1', () {
      final state = _makeState(seatCount: 3, dealerSeat: 0, lastAggressor: 1);
      state.seats[0].holeCards = _parseCards(['As', 'Ks']);
      state.seats[1].holeCards = _parseCards(['Qd', 'Qc']);
      state.seats[2].holeCards = _parseCards(['Jd', 'Jc']);

      final order = ShowdownOrder.getRevealOrder(state);
      expect(order, [1, 2, 0]);
    });

    test('folded player excluded from order', () {
      final state = _makeState(seatCount: 3, dealerSeat: 0, lastAggressor: 2);
      state.seats[0].holeCards = _parseCards(['As', 'Ks']);
      state.seats[1].status = SeatStatus.folded;
      state.seats[1].holeCards = [];
      state.seats[2].holeCards = _parseCards(['Jd', 'Jc']);

      final order = ShowdownOrder.getRevealOrder(state);
      expect(order, [2, 0]); // Seat 1 excluded
    });

    test('heads-up showdown order with aggressor', () {
      final state = _makeState(seatCount: 2, dealerSeat: 0, lastAggressor: 1);
      state.seats[0].holeCards = _parseCards(['As', 'Ks']);
      state.seats[1].holeCards = _parseCards(['Qd', 'Qc']);

      final order = ShowdownOrder.getRevealOrder(state);
      expect(order, [1, 0]);
    });

    test('heads-up showdown order without aggressor', () {
      final state = _makeState(seatCount: 2, dealerSeat: 0, lastAggressor: -1);
      state.seats[0].holeCards = _parseCards(['As', 'Ks']);
      state.seats[1].holeCards = _parseCards(['Qd', 'Qc']);

      final order = ShowdownOrder.getRevealOrder(state);
      expect(order, [1, 0]); // Dealer-left first
    });

    test('aggressor folded: falls back to dealer-left', () {
      final state = _makeState(seatCount: 3, dealerSeat: 0, lastAggressor: 1);
      state.seats[0].holeCards = _parseCards(['As', 'Ks']);
      state.seats[1].status = SeatStatus.folded;
      state.seats[1].holeCards = []; // Folded, no cards
      state.seats[2].holeCards = _parseCards(['Jd', 'Jc']);

      final order = ShowdownOrder.getRevealOrder(state);
      // Aggressor (seat 1) has no cards, not in active list
      // Falls back to dealer-left: seat 2, then 0
      expect(order, [2, 0]);
    });

    test('empty active players returns empty list', () {
      final state = _makeState(seatCount: 3, dealerSeat: 0);
      // All folded / no cards
      for (final s in state.seats) {
        s.status = SeatStatus.folded;
        s.holeCards = [];
      }

      final order = ShowdownOrder.getRevealOrder(state);
      expect(order, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Task 4.5: Muck Rights
  // ═══════════════════════════════════════════════════════════════════════════
  group('Muck Decision', () {
    test('MuckDecision showCards=false clears holeCards', () {
      final state = _makeState(seatCount: 3, dealerSeat: 0);
      state.seats[1].holeCards = _parseCards(['As', 'Ks']);

      final newState = Engine.apply(
        state,
        const MuckDecision(1, showCards: false),
      );

      expect(newState.seats[1].holeCards, isEmpty);
    });

    test('MuckDecision showCards=true: cards remain', () {
      final state = _makeState(seatCount: 3, dealerSeat: 0);
      state.seats[1].holeCards = _parseCards(['As', 'Ks']);

      final newState = Engine.apply(
        state,
        const MuckDecision(1, showCards: true),
      );

      expect(newState.seats[1].holeCards.length, 2);
    });

    test('MuckDecision does not affect other seats', () {
      final state = _makeState(seatCount: 3, dealerSeat: 0);
      state.seats[0].holeCards = _parseCards(['Qd', 'Qc']);
      state.seats[1].holeCards = _parseCards(['As', 'Ks']);
      state.seats[2].holeCards = _parseCards(['Jd', 'Jc']);

      final newState = Engine.apply(
        state,
        const MuckDecision(1, showCards: false),
      );

      expect(newState.seats[0].holeCards.length, 2);
      expect(newState.seats[1].holeCards, isEmpty);
      expect(newState.seats[2].holeCards.length, 2);
    });

    test('multiple muck decisions independently applied', () {
      var state = _makeState(seatCount: 3, dealerSeat: 0);
      state.seats[0].holeCards = _parseCards(['Qd', 'Qc']);
      state.seats[1].holeCards = _parseCards(['As', 'Ks']);
      state.seats[2].holeCards = _parseCards(['Jd', 'Jc']);

      state = Engine.apply(state, const MuckDecision(0, showCards: false));
      state = Engine.apply(state, const MuckDecision(2, showCards: true));

      expect(state.seats[0].holeCards, isEmpty);
      expect(state.seats[1].holeCards.length, 2);
      expect(state.seats[2].holeCards.length, 2);
    });

    test('muck on seat with no cards is no-op', () {
      final state = _makeState(seatCount: 3, dealerSeat: 0);
      state.seats[1].holeCards = [];

      final newState = Engine.apply(
        state,
        const MuckDecision(1, showCards: false),
      );

      expect(newState.seats[1].holeCards, isEmpty);
    });

    test('MuckDecision event has correct fields', () {
      const event = MuckDecision(2, showCards: true);
      expect(event.seatIndex, 2);
      expect(event.showCards, true);
    });

    test('MuckDecision showCards=false then show=true restores nothing', () {
      var state = _makeState(seatCount: 2, dealerSeat: 0);
      state.seats[0].holeCards = _parseCards(['As', 'Ks']);

      state = Engine.apply(state, const MuckDecision(0, showCards: false));
      expect(state.seats[0].holeCards, isEmpty);

      // Showing after muck doesn't restore cards (already cleared)
      state = Engine.apply(state, const MuckDecision(0, showCards: true));
      expect(state.seats[0].holeCards, isEmpty);
    });

    test('MuckDecision preserves game state fields', () {
      final state = _makeState(seatCount: 2, dealerSeat: 0, bbAmount: 20);
      state.seats[0].holeCards = _parseCards(['As', 'Ks']);

      final newState = Engine.apply(
        state,
        const MuckDecision(0, showCards: false),
      );

      expect(newState.dealerSeat, 0);
      expect(newState.bbAmount, 20);
      expect(newState.sessionId, 'test');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Task 4.6: Card Reveal Config
  // ═══════════════════════════════════════════════════════════════════════════
  group('Card Reveal Config', () {
    test('venue canvas always returns false', () {
      final state = _makeState(
        canvasType: CanvasType.venue,
        revealConfig: const CardRevealConfig(
          revealType: RevealType.allImmediate,
        ),
      );

      final result = ShowdownOrder.shouldRevealCards(
        seatIndex: 0,
        state: state,
        revealOrder: [0, 1, 2],
        isWinner: true,
      );

      expect(result, false);
    });

    test('broadcast + allImmediate returns true', () {
      final state = _makeState(
        canvasType: CanvasType.broadcast,
        revealConfig: const CardRevealConfig(
          revealType: RevealType.allImmediate,
        ),
      );

      final result = ShowdownOrder.shouldRevealCards(
        seatIndex: 0,
        state: state,
        revealOrder: [0, 1, 2],
        isWinner: false,
      );

      expect(result, true);
    });

    test('winnerOnly: winner true, loser false', () {
      final state = _makeState(
        revealConfig: const CardRevealConfig(
          revealType: RevealType.winnerOnly,
        ),
      );

      expect(
        ShowdownOrder.shouldRevealCards(
          seatIndex: 0, state: state, revealOrder: [0, 1], isWinner: true,
        ),
        true,
      );
      expect(
        ShowdownOrder.shouldRevealCards(
          seatIndex: 1, state: state, revealOrder: [0, 1], isWinner: false,
        ),
        false,
      );
    });

    test('manualReveal returns false', () {
      final state = _makeState(
        revealConfig: const CardRevealConfig(
          revealType: RevealType.manualReveal,
        ),
      );

      expect(
        ShowdownOrder.shouldRevealCards(
          seatIndex: 0, state: state, revealOrder: [0], isWinner: true,
        ),
        false,
      );
    });

    test('externalControl returns false', () {
      final state = _makeState(
        revealConfig: const CardRevealConfig(
          revealType: RevealType.externalControl,
        ),
      );

      expect(
        ShowdownOrder.shouldRevealCards(
          seatIndex: 0, state: state, revealOrder: [0], isWinner: true,
        ),
        false,
      );
    });

    test('default config (no revealConfig) uses broadcast defaults', () {
      final state = _makeState(); // No revealConfig set

      // Default is lastAggressorFirst → shows all in order
      expect(
        ShowdownOrder.shouldRevealCards(
          seatIndex: 0, state: state, revealOrder: [0], isWinner: false,
        ),
        true,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Task 4.7: Canvas Type
  // ═══════════════════════════════════════════════════════════════════════════
  group('Canvas Type', () {
    test('default canvas type is broadcast', () {
      final state = _makeState();
      expect(state.canvasType, CanvasType.broadcast);
    });

    test('venue canvas never reveals', () {
      final state = _makeState(canvasType: CanvasType.venue);

      // Even with allImmediate, venue never reveals
      final stateWithConfig = state.copyWith(
        revealConfig: const CardRevealConfig(
          revealType: RevealType.allImmediate,
        ),
        canvasType: CanvasType.venue,
      );

      expect(
        ShowdownOrder.shouldRevealCards(
          seatIndex: 0,
          state: stateWithConfig,
          revealOrder: [0],
          isWinner: true,
        ),
        false,
      );
    });
  });
}
