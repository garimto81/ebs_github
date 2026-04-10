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
  int? anteAmount,
  int? anteType,
  bool straddleEnabled = false,
  int? straddleSeat,
  int? actionTimeoutMs,
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
    anteAmount: anteAmount,
    anteType: anteType,
    straddleEnabled: straddleEnabled,
    straddleSeat: straddleSeat,
    actionTimeoutMs: actionTimeoutMs,
  );
}

/// Helper: start a hand with blinds posted and return resulting state.
GameState _startedHand({
  int seatCount = 6,
  int stack = 1000,
  int dealerSeat = 0,
  int bbAmount = 10,
  int? anteAmount,
  int? anteType,
  bool straddleEnabled = false,
  int? straddleSeat,
  int? actionTimeoutMs,
}) {
  final state = _makeState(
    seatCount: seatCount,
    stack: stack,
    dealerSeat: dealerSeat,
    bbAmount: bbAmount,
    handInProgress: false,
    anteAmount: anteAmount,
    anteType: anteType,
    straddleEnabled: straddleEnabled,
    straddleSeat: straddleSeat,
    actionTimeoutMs: actionTimeoutMs,
  );
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
  // Task 3.1: Raise Action Restart
  // ═══════════════════════════════════════════════════════════════════════
  group('Raise Action Restart', () {
    test('after raise, only raiser in actedThisRound', () {
      // 3-player: dealer=0, SB=1, BB=2. First to act = seat 0 (UTG)
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      expect(state.actionOn, 0); // UTG acts first

      // UTG calls (10)
      state = Engine.apply(state, const PlayerAction(0, Call(10)));
      expect(state.betting.actedThisRound.contains(0), true);

      // SB calls (5 more to make 10)
      state = Engine.apply(state, const PlayerAction(1, Call(5)));
      expect(state.betting.actedThisRound.contains(1), true);

      // BB raises to 30
      state = Engine.apply(state, const PlayerAction(2, Raise(30)));

      // After raise, only raiser (seat 2) should be in actedThisRound
      expect(state.betting.actedThisRound, {2});
    });

    test('after raise, isRoundComplete returns false', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);

      // UTG calls
      state = Engine.apply(state, const PlayerAction(0, Call(10)));
      // SB calls
      state = Engine.apply(state, const PlayerAction(1, Call(5)));
      // BB raises to 30
      state = Engine.apply(state, const PlayerAction(2, Raise(30)));

      // Round is NOT complete — UTG and SB need to act
      expect(BettingRules.isRoundComplete(state), false);
    });

    test('call after raise marks player acted, but round not complete until all acted', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);

      // UTG calls, SB calls, BB raises to 30
      state = Engine.apply(state, const PlayerAction(0, Call(10)));
      state = Engine.apply(state, const PlayerAction(1, Call(5)));
      state = Engine.apply(state, const PlayerAction(2, Raise(30)));

      // UTG calls the raise
      state = Engine.apply(state, const PlayerAction(0, Call(20)));
      expect(state.betting.actedThisRound.contains(0), true);
      expect(state.betting.actedThisRound.contains(2), true);

      // Round NOT complete — SB hasn't re-acted
      expect(BettingRules.isRoundComplete(state), false);
    });

    test('all players act after raise → round complete', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);

      // UTG calls, SB calls, BB raises to 30
      state = Engine.apply(state, const PlayerAction(0, Call(10)));
      state = Engine.apply(state, const PlayerAction(1, Call(5)));
      state = Engine.apply(state, const PlayerAction(2, Raise(30)));

      // UTG calls 20 more
      state = Engine.apply(state, const PlayerAction(0, Call(20)));
      // SB calls 20 more
      state = Engine.apply(state, const PlayerAction(1, Call(20)));

      // Now all 3 have acted and matched bet → round complete
      // Engine auto-advances to flop
      expect(state.street, Street.flop);
    });

    test('re-raise resets actedThisRound again', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);

      // UTG raises to 30
      state = Engine.apply(state, const PlayerAction(0, Raise(30)));
      expect(state.betting.actedThisRound, {0});

      // SB re-raises to 80
      state = Engine.apply(state, const PlayerAction(1, Raise(80)));
      // Only SB in actedThisRound
      expect(state.betting.actedThisRound, {1});
      expect(BettingRules.isRoundComplete(state), false);
    });

    test('all-in raise resets actedThisRound', () {
      // Player with 50 stack goes all-in for more than current bet (10)
      var state = _startedHand(seatCount: 3, stack: 50, dealerSeat: 0);

      // UTG calls 10
      state = Engine.apply(state, const PlayerAction(0, Call(10)));

      // SB goes all-in for 45 (stack=50, already posted 5 SB)
      // currentBet will be 5 + 45 = 50, which is > 10 → this is a raise
      state = Engine.apply(state, const PlayerAction(1, AllIn(45)));

      expect(state.seats[1].isAllIn, true);
      expect(state.betting.actedThisRound, {1});
      expect(BettingRules.isRoundComplete(state), false);
    });

    test('all-in for less than call does NOT reset actedThisRound', () {
      // Player with small stack goes all-in but can't even call
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      // Manually reduce seat 1's stack so SB has only 5 (posted as blind)
      // After blinds: seat 1 stack = 995 (posted 5). Let's use a raise scenario.

      // UTG raises to 30
      state = Engine.apply(state, const PlayerAction(0, Raise(30)));
      expect(state.betting.actedThisRound, {0});

      // Manually set seat 1 stack to 5 (short stack, currentBet=5 from SB)
      // SB goes all-in for 5 more → currentBet = 10, but currentBet(10) < betting.currentBet(30)
      // This is NOT a raise, so actedThisRound should NOT be reset
      state.seats[1].stack = 5;
      state = BettingRules.applyAction(state, 1, const AllIn(5));

      // Seat 1 is all-in for less, seat 0 should still be in actedThisRound
      expect(state.seats[1].isAllIn, true);
      expect(state.seats[1].currentBet, 10); // 5 SB + 5 all-in
      expect(state.betting.currentBet, 30); // Unchanged
      expect(state.betting.actedThisRound.contains(0), true);
      expect(state.betting.actedThisRound.contains(1), true);
    });

    test('3 players: P0 bets, P1 raises, P2 must act, P0 must re-act', () {
      // Postflop scenario: no blinds to worry about
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      // Everyone calls preflop first → auto-advance to flop
      state = Engine.apply(state, const PlayerAction(0, Call(10)));
      state = Engine.apply(state, const PlayerAction(1, Call(5)));
      state = Engine.apply(state, const PlayerAction(2, Check()));
      expect(state.street, Street.flop);
      expect(state.betting.actedThisRound, isEmpty);

      // First to act postflop: first active after dealer (seat 0)
      // That would be seat 1
      final firstAct = state.actionOn;
      expect(firstAct, 1);

      // P1 bets 20
      state = Engine.apply(state, const PlayerAction(1, Bet(20)));
      expect(state.betting.actedThisRound.contains(1), true);

      // P2 raises to 60
      state = Engine.apply(state, const PlayerAction(2, Raise(60)));
      // After raise: only P2 in actedThisRound
      expect(state.betting.actedThisRound, {2});

      // P0 must act (not yet in actedThisRound)
      expect(state.betting.actedThisRound.contains(0), false);
      // P1 must re-act (no longer in actedThisRound)
      expect(state.betting.actedThisRound.contains(1), false);

      // P0 calls
      state = Engine.apply(state, const PlayerAction(0, Call(60)));
      expect(state.betting.actedThisRound.contains(0), true);
      expect(BettingRules.isRoundComplete(state), false); // P1 hasn't re-acted

      // P1 calls
      state = Engine.apply(state, const PlayerAction(1, Call(40)));
      // All acted + all bets match → flop complete, auto-advance to turn
      expect(state.street, Street.turn);
    });

    test('raise after BB option resets actedThisRound', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);

      // UTG calls
      state = Engine.apply(state, const PlayerAction(0, Call(10)));
      // SB calls
      state = Engine.apply(state, const PlayerAction(1, Call(5)));
      // BB has option — raises to 30
      state = Engine.apply(state, const PlayerAction(2, Raise(30)));

      expect(state.betting.bbOptionPending, false);
      expect(state.betting.actedThisRound, {2});
    });

    test('bet on postflop adds bettor to actedThisRound (no reset needed)', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      // Complete preflop
      state = Engine.apply(state, const PlayerAction(0, Call(10)));
      state = Engine.apply(state, const PlayerAction(1, Call(5)));
      state = Engine.apply(state, const PlayerAction(2, Check()));

      // Advance to flop
      state = Engine.apply(state, const StreetAdvance(Street.flop));

      // P1 bets 20
      state = Engine.apply(state, const PlayerAction(1, Bet(20)));
      // Bet does NOT reset — just adds bettor
      expect(state.betting.actedThisRound.contains(1), true);
      expect(state.betting.actedThisRound.length, 1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Task 3.2: FirstToAct Special Cases
  // ═══════════════════════════════════════════════════════════════════════
  group('FirstToAct Special Cases', () {
    test('BB Ante 1st (anteType=3): BB acts first preflop', () {
      final state = _startedHand(
        seatCount: 6,
        dealerSeat: 0,
        bbAmount: 10,
        anteAmount: 5,
        anteType: 3,
      );
      // dealer=0, SB=1, BB=2
      // With anteType=3, BB acts first
      expect(state.actionOn, 2);
    });

    test('BB Ante 1st (anteType=3): BB option pending', () {
      final state = _startedHand(
        seatCount: 6,
        dealerSeat: 0,
        bbAmount: 10,
        anteAmount: 5,
        anteType: 3,
      );
      // BB acts first with option (can check or raise)
      expect(state.betting.bbOptionPending, true);
    });

    test('TB Ante 1st (anteType=6): SB acts first preflop', () {
      final state = _startedHand(
        seatCount: 6,
        dealerSeat: 0,
        bbAmount: 10,
        anteAmount: 5,
        anteType: 6,
      );
      // dealer=0, SB=1, BB=2
      // With anteType=6, SB acts first
      expect(state.actionOn, 1);
    });

    test('straddle: first to act is seat after straddle', () {
      // 6-max: dealer=0, SB=1, BB=2, straddle=3
      final state = _startedHand(
        seatCount: 6,
        dealerSeat: 0,
        bbAmount: 10,
        straddleEnabled: true,
        straddleSeat: 3,
      );
      // First to act = next active after straddle seat (3) = seat 4
      expect(state.actionOn, 4);
    });

    test('standard preflop: UTG (after BB) acts first', () {
      final state = _startedHand(seatCount: 6, dealerSeat: 0);
      // dealer=0, SB=1, BB=2 → UTG=3
      expect(state.actionOn, 3);
    });

    test('heads-up preflop: SB/dealer acts first', () {
      final state = _startedHand(seatCount: 2, dealerSeat: 0);
      // Heads-up: dealer=0=SB, BB=1
      // SB acts first preflop
      expect(state.actionOn, 0);
    });

    test('heads-up postflop: BB (non-dealer) acts first', () {
      var state = _startedHand(seatCount: 2, dealerSeat: 0);
      // Complete preflop: SB(0) calls, BB(1) checks
      state = Engine.apply(state, const PlayerAction(0, Call(5)));
      state = Engine.apply(state, const PlayerAction(1, Check()));

      // Advance to flop
      state = Engine.apply(state, const StreetAdvance(Street.flop));
      // Postflop: first active after dealer(0) = seat 1 (BB)
      expect(state.actionOn, 1);
    });

    test('postflop: first active after dealer', () {
      var state = _startedHand(seatCount: 4, dealerSeat: 0);
      // Complete preflop
      state = Engine.apply(state, const PlayerAction(3, Call(10)));
      state = Engine.apply(state, const PlayerAction(1, Call(5)));
      state = Engine.apply(state, const PlayerAction(2, Check()));

      state = Engine.apply(state, const StreetAdvance(Street.flop));
      // dealer=0, first active after dealer = seat 1
      expect(state.actionOn, 1);
    });

    test('postflop with folded player: skips folded', () {
      var state = _startedHand(seatCount: 4, dealerSeat: 0);
      // Seat 3 (UTG) folds, seat 1 calls, seat 2 checks
      state = Engine.apply(state, const PlayerAction(3, Fold()));
      state = Engine.apply(state, const PlayerAction(1, Call(5)));
      state = Engine.apply(state, const PlayerAction(2, Check()));

      state = Engine.apply(state, const StreetAdvance(Street.flop));
      // dealer=0, next active after 0: seat 1 (active), seat 3 is folded
      expect(state.actionOn, 1);
    });

    test('3-player: dealer=2, SB=0, BB=1, UTG=2', () {
      final state = _startedHand(seatCount: 3, dealerSeat: 2);
      // SB=0, BB=1, UTG=dealer=2
      expect(state.actionOn, 2);
    });

    test('standard ante (anteType=0): normal UTG acts first', () {
      final state = _startedHand(
        seatCount: 6,
        dealerSeat: 0,
        bbAmount: 10,
        anteAmount: 5,
        anteType: 0,
      );
      // Standard ante doesn't change first-to-act
      // UTG = seat 3
      expect(state.actionOn, 3);
    });

    test('button ante (anteType=1): normal UTG acts first', () {
      final state = _startedHand(
        seatCount: 6,
        dealerSeat: 0,
        bbAmount: 10,
        anteAmount: 5,
        anteType: 1,
      );
      expect(state.actionOn, 3);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Task 3.3: Action Timeout
  // ═══════════════════════════════════════════════════════════════════════
  group('Action Timeout', () {
    test('TimeoutFold folds the player', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      final actionSeat = state.actionOn; // seat 0 (UTG)
      expect(actionSeat, 0);

      state = Engine.apply(state, TimeoutFold(actionSeat));
      expect(state.seats[actionSeat].isFolded, true);
    });

    test('TimeoutFold advances to next player', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      // UTG (seat 0) times out
      state = Engine.apply(state, const TimeoutFold(0));
      // Next to act should be SB (seat 1)
      expect(state.actionOn, 1);
    });

    test('TimeoutFold on all but one → actionOn = -1 (all-fold)', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      // UTG folds via timeout
      state = Engine.apply(state, const TimeoutFold(0));
      // SB folds via timeout
      state = Engine.apply(state, const TimeoutFold(1));
      // Only BB left → all-fold
      expect(state.actionOn, -1);
    });

    test('actionTimeoutMs stored on GameState', () {
      final state = _makeState(actionTimeoutMs: 30000);
      expect(state.actionTimeoutMs, 30000);
    });

    test('actionTimeoutMs null by default', () {
      final state = _makeState();
      expect(state.actionTimeoutMs, isNull);
    });

    test('actionTimeoutMs preserved through copyWith', () {
      final state = _makeState(actionTimeoutMs: 15000);
      final copy = state.copyWith(street: Street.flop);
      expect(copy.actionTimeoutMs, 15000);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Task 3.4: BettingRound Complete Refinement
  // ═══════════════════════════════════════════════════════════════════════
  group('BettingRound Complete', () {
    test('complete: all active acted and matched bet', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      // UTG calls, SB calls, BB checks option
      state = Engine.apply(state, const PlayerAction(0, Call(10)));
      state = Engine.apply(state, const PlayerAction(1, Call(5)));
      state = Engine.apply(state, const PlayerAction(2, Check()));
      // Round complete → auto-advance to flop
      expect(state.street, Street.flop);
    });

    test('not complete: one player has not acted', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      // Only UTG acts
      state = Engine.apply(state, const PlayerAction(0, Call(10)));
      expect(BettingRules.isRoundComplete(state), false);
    });

    test('not complete: BB option pending', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      // UTG calls, SB calls — BB option still pending
      state = Engine.apply(state, const PlayerAction(0, Call(10)));
      state = Engine.apply(state, const PlayerAction(1, Call(5)));
      // BB option is pending, so round not complete even though all bets match
      expect(state.betting.bbOptionPending, true);
      expect(BettingRules.isRoundComplete(state), false);
    });

    test('complete: only 1 active player (others folded)', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      state = Engine.apply(state, const PlayerAction(0, Fold()));
      state = Engine.apply(state, const PlayerAction(1, Fold()));
      // Only BB active → round complete
      expect(state.actionOn, -1);
    });

    test('after raise: not complete (others need to re-act)', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      state = Engine.apply(state, const PlayerAction(0, Call(10)));
      state = Engine.apply(state, const PlayerAction(1, Call(5)));
      state = Engine.apply(state, const PlayerAction(2, Raise(30)));
      // Two players need to re-act
      expect(BettingRules.isRoundComplete(state), false);
    });

    test('all-in players excluded from active check', () {
      var state = _startedHand(seatCount: 3, stack: 50, dealerSeat: 0);
      // UTG calls 10
      state = Engine.apply(state, const PlayerAction(0, Call(10)));
      // SB goes all-in (45 chips, total bet = 50)
      state = Engine.apply(state, const PlayerAction(1, AllIn(45)));
      // BB calls the all-in (40 more to make 50)
      state = Engine.apply(state, const PlayerAction(2, Call(40)));
      // UTG must re-act after all-in raise
      state = Engine.apply(state, const PlayerAction(0, Call(40)));

      // SB is all-in (not active), so only UTG and BB need to have acted
      // All players are all-in (stack=50, total bet=50) → all-in runout
      // Engine auto-deals flop→turn→river
      expect(state.street, Street.river);
      expect(state.community.length, 5);
    });

    test('check/check/check on flop → complete', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      // Complete preflop → auto-advance to flop
      state = Engine.apply(state, const PlayerAction(0, Call(10)));
      state = Engine.apply(state, const PlayerAction(1, Call(5)));
      state = Engine.apply(state, const PlayerAction(2, Check()));
      expect(state.street, Street.flop);

      // All check on flop: P1, P2, P0
      state = Engine.apply(state, const PlayerAction(1, Check()));
      state = Engine.apply(state, const PlayerAction(2, Check()));
      state = Engine.apply(state, const PlayerAction(0, Check()));

      // All checked → auto-advance to turn
      expect(state.street, Street.turn);
    });

    test('bet/call/call on flop → complete', () {
      var state = _startedHand(seatCount: 3, dealerSeat: 0);
      // Complete preflop → auto-advance to flop
      state = Engine.apply(state, const PlayerAction(0, Call(10)));
      state = Engine.apply(state, const PlayerAction(1, Call(5)));
      state = Engine.apply(state, const PlayerAction(2, Check()));
      expect(state.street, Street.flop);

      // P1 bets 20, P2 calls, P0 calls
      state = Engine.apply(state, const PlayerAction(1, Bet(20)));
      state = Engine.apply(state, const PlayerAction(2, Call(20)));
      state = Engine.apply(state, const PlayerAction(0, Call(20)));

      // Flop complete → auto-advance to turn
      expect(state.street, Street.turn);
    });
  });
}
