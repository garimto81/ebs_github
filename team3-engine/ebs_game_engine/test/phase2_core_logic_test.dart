import 'package:ebs_game_engine/engine.dart';
import 'package:test/test.dart';

/// Helper: create a standard N-seat game state for testing.
GameState _makeState({
  int seatCount = 6,
  int stack = 1000,
  int dealerSeat = 0,
  int bbAmount = 10,
  bool handInProgress = true,
  Street street = Street.preflop,
  int actionOn = -1,
  int handNumber = 0,
  bool bombPotEnabled = false,
  int? bombPotAmount,
}) {
  final seats = List.generate(
    seatCount,
    (i) => Seat(index: i, label: 'P$i', stack: stack),
  );
  return GameState(
    sessionId: 'test',
    variantName: 'NLH',
    seats: seats,
    deck: Deck.standard(seed: 42),
    dealerSeat: dealerSeat,
    bbAmount: bbAmount,
    handInProgress: handInProgress,
    street: street,
    actionOn: actionOn,
    handNumber: handNumber,
    bombPotEnabled: bombPotEnabled,
    bombPotAmount: bombPotAmount,
  );
}

/// Helper: start a hand with blinds posted and return resulting state.
GameState _startedHand({
  int seatCount = 6,
  int stack = 1000,
  int dealerSeat = 0,
  int bbAmount = 10,
  bool bombPotEnabled = false,
  int? bombPotAmount,
}) {
  final state = _makeState(
    seatCount: seatCount,
    stack: stack,
    dealerSeat: dealerSeat,
    bbAmount: bbAmount,
    handInProgress: false,
    bombPotEnabled: bombPotEnabled,
    bombPotAmount: bombPotAmount,
  );
  // For a 6-max game: dealer=0, SB=1, BB=2
  // For heads-up: dealer=0(SB), BB=1
  final Map<int, int> blinds;
  if (seatCount == 2) {
    blinds = {dealerSeat: bbAmount ~/ 2, (dealerSeat + 1) % 2: bbAmount};
  } else {
    final sbIdx = (dealerSeat + 1) % seatCount;
    final bbIdx = (dealerSeat + 2) % seatCount;
    blinds = {sbIdx: bbAmount ~/ 2, bbIdx: bbAmount};
  }
  return Engine.apply(state, HandStart(dealerSeat: dealerSeat, blinds: blinds));
}

void main() {
  // ═══════════════════════════════════════════════════════════════════════
  // Task 2.1: All-Fold Detection + Auto Pot Award
  // ═══════════════════════════════════════════════════════════════════════
  group('All-Fold Detection', () {
    test('preflop: all fold to BB → actionOn = -1', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      // Seats: 0=dealer, 1=SB, 2=BB
      // Preflop action order: UTG(0) first, then SB(1), then BB(2)
      // In 3-way, first to act is seat after BB = seat 0
      expect(state.handInProgress, true);

      // Seat 0 (UTG/dealer) folds
      state = Engine.apply(state, const PlayerAction(0, Fold()));
      // Seat 1 (SB) folds
      state = Engine.apply(state, const PlayerAction(1, Fold()));

      // Only BB remains
      expect(state.actionOn, -1);
      final remaining =
          state.seats.where((s) => s.isActive || s.isAllIn).toList();
      expect(remaining.length, 1);
      expect(remaining.first.index, 2); // BB
    });

    test('flop: 3-way, 2 fold → survivor wins signal', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      // Everyone calls preflop (simplified: just use check for BB)
      state = Engine.apply(state, PlayerAction(0, Call(10)));
      state = Engine.apply(state, PlayerAction(1, Call(5)));
      // BB checks (option)
      state = Engine.apply(state, const PlayerAction(2, Check()));

      // Advance to flop
      state = Engine.apply(state, const StreetAdvance(Street.flop));

      // Post-flop: first to act is seat 1 (first active after dealer=0)
      // Seat 1 folds
      state = Engine.apply(state, const PlayerAction(1, Fold()));
      // Seat 2 folds
      state = Engine.apply(state, const PlayerAction(2, Fold()));

      expect(state.actionOn, -1);
      final remaining =
          state.seats.where((s) => s.isActive || s.isAllIn).toList();
      expect(remaining.length, 1);
      expect(remaining.first.index, 0);
    });

    test('verify actionOn = -1 after all fold', () {
      var state = _startedHand(seatCount: 4, dealerSeat: 0);
      // Seats: 0=D, 1=SB, 2=BB, 3=UTG
      // First to act: seat 3 (after BB)
      state = Engine.apply(state, const PlayerAction(3, Fold()));
      state = Engine.apply(state, const PlayerAction(0, Fold()));
      state = Engine.apply(state, const PlayerAction(1, Fold()));
      expect(state.actionOn, -1);
    });

    test('multi-way fold sequence 6-max', () {
      var state = _startedHand(seatCount: 6, dealerSeat: 0);
      // First to act: seat 3 (UTG, after BB=2)
      state = Engine.apply(state, const PlayerAction(3, Fold()));
      state = Engine.apply(state, const PlayerAction(4, Fold()));
      state = Engine.apply(state, const PlayerAction(5, Fold()));
      state = Engine.apply(state, const PlayerAction(0, Fold()));
      state = Engine.apply(state, const PlayerAction(1, Fold()));
      // Only BB (seat 2) remains
      expect(state.actionOn, -1);
      expect(
          state.seats.where((s) => s.isActive || s.isAllIn).length, 1);
    });

    test('all fold except all-in player', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      // Seat 0 goes all-in
      state = Engine.apply(state, PlayerAction(0, AllIn(state.seats[0].stack)));
      // Seat 1 folds
      state = Engine.apply(state, const PlayerAction(1, Fold()));
      // Seat 2 folds
      state = Engine.apply(state, const PlayerAction(2, Fold()));

      expect(state.actionOn, -1);
      final remaining =
          state.seats.where((s) => s.isActive || s.isAllIn).toList();
      expect(remaining.length, 1);
      expect(remaining.first.isAllIn, true);
    });

    test('heads-up: one fold → only 1 player remains', () {
      var state = _startedHand(seatCount: 2, dealerSeat: 0);
      // HU: dealer=SB=seat0 acts first preflop
      state = Engine.apply(state, const PlayerAction(0, Fold()));
      expect(state.actionOn, -1);
      expect(
          state.seats.where((s) => s.isActive || s.isAllIn).length, 1);
    });

    test('fold does not trigger if 2+ players remain', () {
      var state = _startedHand(seatCount: 4, dealerSeat: 0);
      // Seat 3 folds, but 3 remain
      state = Engine.apply(state, const PlayerAction(3, Fold()));
      expect(state.actionOn, isNot(-1));
      expect(
          state.seats.where((s) => s.isActive || s.isAllIn).length, 3);
    });

    test('pot contains blinds after all-fold', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      final potBefore = state.pot.main;
      expect(potBefore, greaterThan(0)); // blinds posted

      state = Engine.apply(state, const PlayerAction(0, Fold()));
      state = Engine.apply(state, const PlayerAction(1, Fold()));
      // Pot still exists (not yet awarded by PotAwarded event)
      expect(state.pot.main, potBefore);
    });

    test('all fold after call sequence', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      // Seat 0 calls
      state = Engine.apply(state, PlayerAction(0, Call(10)));
      // Seat 1 calls
      state = Engine.apply(state, PlayerAction(1, Call(5)));
      // BB checks
      state = Engine.apply(state, const PlayerAction(2, Check()));
      // Advance to flop
      state = Engine.apply(state, const StreetAdvance(Street.flop));

      // Now on flop, everyone folds except seat 0
      state = Engine.apply(state, const PlayerAction(1, Fold()));
      state = Engine.apply(state, const PlayerAction(2, Fold()));
      expect(state.actionOn, -1);
    });

    test('survivor is identifiable after all-fold', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      state = Engine.apply(state, const PlayerAction(0, Fold()));
      state = Engine.apply(state, const PlayerAction(1, Fold()));

      final survivors =
          state.seats.where((s) => s.isActive || s.isAllIn).toList();
      expect(survivors.length, 1);
      expect(survivors.first.index, 2);
      expect(survivors.first.label, 'P2');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Task 2.2: All-In Runout Detection
  // ═══════════════════════════════════════════════════════════════════════
  group('All-In Runout', () {
    test('all active players all-in → isAllInRunout true', () {
      final state = _makeState(seatCount: 3);
      state.seats[0].status = SeatStatus.allIn;
      state.seats[1].status = SeatStatus.allIn;
      state.seats[2].status = SeatStatus.folded;
      expect(Engine.isAllInRunout(state), true);
    });

    test('one player still active → isAllInRunout false', () {
      final state = _makeState(seatCount: 3);
      state.seats[0].status = SeatStatus.active;
      state.seats[1].status = SeatStatus.allIn;
      state.seats[2].status = SeatStatus.folded;
      expect(Engine.isAllInRunout(state), false);
    });

    test('heads-up both all-in → isAllInRunout true', () {
      final state = _makeState(seatCount: 2);
      state.seats[0].status = SeatStatus.allIn;
      state.seats[1].status = SeatStatus.allIn;
      expect(Engine.isAllInRunout(state), true);
    });

    test('3-way with 1 active, 2 all-in → false', () {
      final state = _makeState(seatCount: 3);
      state.seats[0].status = SeatStatus.active;
      state.seats[1].status = SeatStatus.allIn;
      state.seats[2].status = SeatStatus.allIn;
      expect(Engine.isAllInRunout(state), false);
    });

    test('only 1 all-in, rest folded → false (not runout, just winner)', () {
      final state = _makeState(seatCount: 3);
      state.seats[0].status = SeatStatus.allIn;
      state.seats[1].status = SeatStatus.folded;
      state.seats[2].status = SeatStatus.folded;
      expect(Engine.isAllInRunout(state), false);
    });

    test('3 all-in, 0 active → true', () {
      final state = _makeState(seatCount: 3);
      state.seats[0].status = SeatStatus.allIn;
      state.seats[1].status = SeatStatus.allIn;
      state.seats[2].status = SeatStatus.allIn;
      expect(Engine.isAllInRunout(state), true);
    });

    test('all sitting out → false', () {
      final state = _makeState(seatCount: 3);
      state.seats[0].status = SeatStatus.sittingOut;
      state.seats[1].status = SeatStatus.sittingOut;
      state.seats[2].status = SeatStatus.sittingOut;
      expect(Engine.isAllInRunout(state), false);
    });

    test('mixed folded and sitting out → false', () {
      final state = _makeState(seatCount: 3);
      state.seats[0].status = SeatStatus.folded;
      state.seats[1].status = SeatStatus.sittingOut;
      state.seats[2].status = SeatStatus.allIn;
      expect(Engine.isAllInRunout(state), false);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Task 2.3: Dealer Button Auto-Rotation
  // ═══════════════════════════════════════════════════════════════════════
  group('Dealer Rotation', () {
    test('normal rotation: 0→1', () {
      var state = _makeState(dealerSeat: 0, handNumber: 0);
      state = Engine.apply(state, const HandEnd());
      expect(state.dealerSeat, 1);
    });

    test('rotation: 1→2→3', () {
      var state = _makeState(seatCount: 6, dealerSeat: 1, handNumber: 0);
      state = Engine.apply(state, const HandEnd());
      expect(state.dealerSeat, 2);
      state = Engine.apply(state, const HandEnd());
      expect(state.dealerSeat, 3);
    });

    test('skip sitting-out: 0→2 (seat 1 sitting out)', () {
      var state = _makeState(seatCount: 4, dealerSeat: 0);
      state.seats[1].status = SeatStatus.sittingOut;
      state = Engine.apply(state, const HandEnd());
      expect(state.dealerSeat, 2);
    });

    test('wrap around: seat 5 → seat 0', () {
      var state = _makeState(seatCount: 6, dealerSeat: 5);
      state = Engine.apply(state, const HandEnd());
      expect(state.dealerSeat, 0);
    });

    test('hand number increments on endHand', () {
      var state = _makeState(handNumber: 5);
      state = Engine.apply(state, const HandEnd());
      expect(state.handNumber, 6);
    });

    test('hand number increments each endHand', () {
      var state = _makeState(handNumber: 0);
      state = Engine.apply(state, const HandEnd());
      expect(state.handNumber, 1);
      state = Engine.apply(state, const HandEnd());
      expect(state.handNumber, 2);
      state = Engine.apply(state, const HandEnd());
      expect(state.handNumber, 3);
    });

    test('heads-up rotation: 0→1→0', () {
      var state = _makeState(seatCount: 2, dealerSeat: 0);
      state = Engine.apply(state, const HandEnd());
      expect(state.dealerSeat, 1);
      state = Engine.apply(state, const HandEnd());
      expect(state.dealerSeat, 0);
    });

    test('handInProgress set to false after endHand', () {
      var state = _makeState(handInProgress: true);
      state = Engine.apply(state, const HandEnd());
      expect(state.handInProgress, false);
      expect(state.actionOn, -1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Task 2.4: Misdeal Detection
  // ═══════════════════════════════════════════════════════════════════════
  group('MisDeal', () {
    test('MisDeal event: pot returned to zero', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      expect(state.pot.main, greaterThan(0));

      state = Engine.apply(state, const MisDeal());
      expect(state.pot.main, 0);
      expect(state.pot.sides, isEmpty);
    });

    test('players stacks restored (currentBet refunded)', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0, stack: 1000);
      // SB=seat1 posted 5, BB=seat2 posted 10
      // After misdeal, stacks should be restored
      final stacksBefore = state.seats.map((s) => s.stack + s.currentBet).toList();

      state = Engine.apply(state, const MisDeal());

      for (var i = 0; i < state.seats.length; i++) {
        expect(state.seats[i].stack, stacksBefore[i],
            reason: 'Seat $i stack should be restored');
        expect(state.seats[i].currentBet, 0);
      }
    });

    test('all seats reset to active (not folded/allIn)', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      // Simulate a fold before misdeal
      state = Engine.apply(state, const PlayerAction(0, Fold()));
      expect(state.seats[0].isFolded, true);

      state = Engine.apply(state, const MisDeal());
      for (final seat in state.seats) {
        expect(seat.status, SeatStatus.active);
      }
    });

    test('hand no longer in progress', () {
      var state = _startedHand(seatCount: 3);
      expect(state.handInProgress, true);

      state = Engine.apply(state, const MisDeal());
      expect(state.handInProgress, false);
      expect(state.actionOn, -1);
    });

    test('hole cards cleared', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      // Deal some hole cards
      state = Engine.apply(state, DealHoleCards({
        0: [Card.parse('Ah'), Card.parse('Kh')],
        1: [Card.parse('Qs'), Card.parse('Js')],
        2: [Card.parse('Td'), Card.parse('9d')],
      }));
      expect(state.seats[0].holeCards, isNotEmpty);

      state = Engine.apply(state, const MisDeal());
      for (final seat in state.seats) {
        expect(seat.holeCards, isEmpty);
      }
    });

    test('community cards cleared', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      state = Engine.apply(
          state, DealCommunity([Card.parse('Ah'), Card.parse('Kh'), Card.parse('Qh')]));
      expect(state.community, isNotEmpty);

      state = Engine.apply(state, const MisDeal());
      expect(state.community, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Task 2.5: Bomb Pot
  // ═══════════════════════════════════════════════════════════════════════
  group('Bomb Pot', () {
    test('BombPotConfig sets bombPotEnabled and amount', () {
      var state = _makeState();
      expect(state.bombPotEnabled, false);

      state = Engine.apply(state, const BombPotConfig(50));
      expect(state.bombPotEnabled, true);
      expect(state.bombPotAmount, 50);
    });

    test('startHand with bombPot: all players post bomb amount', () {
      var state = _startedHand(
        seatCount: 3,
        stack: 1000,
        dealerSeat: 0,
        bbAmount: 10,
        bombPotEnabled: true,
        bombPotAmount: 50,
      );
      // Each player should have posted blinds + bomb pot amount
      // Bomb pot: each active player posts 50
      // SB=5, BB=10, bomb=50 each
      // Total pot: 5 + 10 + 50*3 = 165
      expect(state.pot.main, 165);
    });

    test('bombPot: street set to flop (skip preflop)', () {
      var state = _startedHand(
        seatCount: 3,
        stack: 1000,
        dealerSeat: 0,
        bbAmount: 10,
        bombPotEnabled: true,
        bombPotAmount: 50,
      );
      expect(state.street, Street.flop);
    });

    test('bombPot: first to act is postflop (after dealer)', () {
      var state = _startedHand(
        seatCount: 3,
        stack: 1000,
        dealerSeat: 0,
        bbAmount: 10,
        bombPotEnabled: true,
        bombPotAmount: 50,
      );
      // Postflop first to act: first active after dealer (seat 0)
      // Should be seat 1
      expect(state.actionOn, 1);
    });

    test('bombPot: player cant afford full amount → all-in', () {
      var state = _startedHand(
        seatCount: 3,
        stack: 30, // Only 30 chips total
        dealerSeat: 0,
        bbAmount: 10,
        bombPotEnabled: true,
        bombPotAmount: 50,
      );
      // SB posted 5 (stack=25), BB posted 10 (stack=20), dealer posted 0 blind
      // Bomb pot: each posts min(50, remaining_stack)
      // Seat 0: 30 stack, posts min(50,30)=30 → all-in
      // Seat 1: 25 stack, posts min(50,25)=25 → all-in
      // Seat 2: 20 stack, posts min(50,20)=20 → all-in
      final allInCount =
          state.seats.where((s) => s.isAllIn).length;
      expect(allInCount, greaterThan(0));
    });

    test('bombPot: currentBet reset for flop betting', () {
      var state = _startedHand(
        seatCount: 3,
        stack: 1000,
        dealerSeat: 0,
        bbAmount: 10,
        bombPotEnabled: true,
        bombPotAmount: 50,
      );
      // Betting round should be reset for flop
      expect(state.betting.currentBet, 0);
      for (final seat in state.seats) {
        if (seat.isActive) {
          expect(seat.currentBet, 0);
        }
      }
    });

    test('bombPot disabled: normal preflop', () {
      var state = _startedHand(
        seatCount: 3,
        stack: 1000,
        dealerSeat: 0,
        bbAmount: 10,
        bombPotEnabled: false,
      );
      expect(state.street, Street.preflop);
      expect(state.pot.main, 15); // SB=5, BB=10
    });

    test('BombPotConfig can be applied multiple times', () {
      var state = _makeState();
      state = Engine.apply(state, const BombPotConfig(50));
      expect(state.bombPotAmount, 50);
      state = Engine.apply(state, const BombPotConfig(100));
      expect(state.bombPotAmount, 100);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Task 2.6: Run It Multiple
  // ═══════════════════════════════════════════════════════════════════════
  group('Run It Multiple', () {
    test('RunItChoice: sets runItTimes', () {
      var state = _makeState();
      state = Engine.apply(state, const RunItChoice(2));
      expect(state.runItTimes, 2);
    });

    test('RunItChoice: street = runItMultiple', () {
      var state = _makeState();
      state = Engine.apply(state, const RunItChoice(2));
      expect(state.street, Street.runItMultiple);
    });

    test('runItTimes = 3 stored', () {
      var state = _makeState();
      state = Engine.apply(state, const RunItChoice(3));
      expect(state.runItTimes, 3);
      expect(state.street, Street.runItMultiple);
    });

    test('RunItChoice preserves other state', () {
      var state = _makeState(handInProgress: true, stack: 500);
      state = Engine.apply(state, const RunItChoice(2));
      expect(state.handInProgress, true);
      expect(state.seats[0].stack, 500);
    });

    test('RunItChoice can change times', () {
      var state = _makeState();
      state = Engine.apply(state, const RunItChoice(2));
      expect(state.runItTimes, 2);
      state = Engine.apply(state, const RunItChoice(3));
      expect(state.runItTimes, 3);
    });

    test('RunItChoice does not affect pot', () {
      var state = _startedHand(seatCount: 3);
      final potBefore = state.pot.main;
      state = Engine.apply(state, const RunItChoice(2));
      expect(state.pot.main, potBefore);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ManualNextHand
  // ═══════════════════════════════════════════════════════════════════════
  group('ManualNextHand', () {
    test('resets handInProgress', () {
      var state = _makeState(handInProgress: true);
      state = Engine.apply(state, const ManualNextHand());
      expect(state.handInProgress, false);
      expect(state.actionOn, -1);
    });

    test('clears bomb pot flags', () {
      var state = _makeState(bombPotEnabled: true, bombPotAmount: 50);
      state = Engine.apply(state, const ManualNextHand());
      expect(state.bombPotEnabled, false);
    });

    test('clears community cards and hole cards', () {
      var state = _makeState();
      state = Engine.apply(
          state, DealCommunity([Card.parse('Ah'), Card.parse('Kh'), Card.parse('Qh')]));
      state = Engine.apply(state, DealHoleCards({
        0: [Card.parse('2c'), Card.parse('3c')],
      }));
      expect(state.community, isNotEmpty);
      expect(state.seats[0].holeCards, isNotEmpty);

      state = Engine.apply(state, const ManualNextHand());
      expect(state.community, isEmpty);
      expect(state.seats[0].holeCards, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // TimeoutFold
  // ═══════════════════════════════════════════════════════════════════════
  group('TimeoutFold', () {
    test('timeout fold acts as regular fold', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      // Seat 0 times out (equivalent to fold)
      state = Engine.apply(state, const TimeoutFold(0));
      expect(state.seats[0].isFolded, true);
    });

    test('timeout fold triggers all-fold when last', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      state = Engine.apply(state, const TimeoutFold(0));
      state = Engine.apply(state, const TimeoutFold(1));
      expect(state.actionOn, -1);
    });
  });
}
