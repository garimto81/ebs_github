import 'package:test/test.dart';
import 'package:ebs_game_engine/engine.dart';

// ── Helpers ──

Seat _seat(int i,
    {int stack = 1000,
    int currentBet = 0,
    SeatStatus status = SeatStatus.active}) {
  return Seat(
      index: i,
      label: 'P$i',
      stack: stack,
      currentBet: currentBet,
      status: status);
}

/// Build a GameState and apply HandStart, returning the resulting state.
/// [numSeats] players, dealer=0, SB/BB determined automatically.
/// Ante/straddle configured via optional params.
GameState _setup({
  int numSeats = 3,
  int bbAmount = 10,
  int sbAmount = 5,
  int dealerSeat = 0,
  int? anteType,
  int? anteAmount,
  bool straddleEnabled = false,
  int? straddleSeat,
  List<Seat>? customSeats,
}) {
  final seats =
      customSeats ?? List.generate(numSeats, (i) => _seat(i, stack: 1000));
  final n = seats.length;

  // Determine SB/BB the same way the engine does (skip sitting-out)
  final activeSeatIndices = <int>[];
  for (var i = 0; i < n; i++) {
    final idx = (dealerSeat + 1 + i) % n;
    if (seats[idx].status != SeatStatus.sittingOut) {
      activeSeatIndices.add(idx);
    }
  }

  int sbIdx, bbIdx;
  if (n == 2) {
    sbIdx = dealerSeat;
    bbIdx = activeSeatIndices.firstWhere((i) => i != dealerSeat);
  } else {
    sbIdx = activeSeatIndices[0];
    bbIdx = activeSeatIndices[1];
  }

  var state = GameState(
    sessionId: 'test',
    variantName: 'nlh',
    seats: seats,
    deck: Deck.standard(seed: 42),
    bbAmount: bbAmount,
    anteType: anteType,
    anteAmount: anteAmount,
    straddleEnabled: straddleEnabled,
    straddleSeat: straddleSeat,
  );

  state = Engine.apply(
    state,
    HandStart(
      dealerSeat: dealerSeat,
      blinds: {sbIdx: sbAmount, bbIdx: bbAmount},
    ),
  );
  return state;
}

/// Sum of all stacks + pot total — must equal initial chip total.
int _totalChips(GameState state) {
  return state.seats.fold<int>(0, (s, seat) => s + seat.stack) +
      state.pot.total;
}

void main() {
  // ════════════════════════════════════════════════════════════════
  // Ante Type 0 — Standard Ante
  // ════════════════════════════════════════════════════════════════
  group('Ante Type 0 - Standard Ante', () {
    test('all players post ante, pot increases correctly', () {
      final state = _setup(numSeats: 4, anteType: 0, anteAmount: 2);
      // blinds: SB=5, BB=10 → 15
      // ante: 4 players × 2 = 8
      // total pot = 23
      expect(state.pot.total, 23);
      expect(_totalChips(state), 4000);
    });

    test('3 players each post ante', () {
      final state = _setup(numSeats: 3, anteType: 0, anteAmount: 5);
      // blinds 15 + ante 15 = 30
      expect(state.pot.total, 30);
      expect(_totalChips(state), 3000);
    });

    test('player with insufficient stack goes all-in on ante', () {
      final state = _setup(
        customSeats: [
          _seat(0, stack: 1000),
          _seat(1, stack: 3), // SB=5 caps at 3, ante can't post (stack=0)
          _seat(2, stack: 1000),
        ],
        anteType: 0,
        anteAmount: 5,
      );
      // Seat 1: posts 3 (all of stack) as SB blind, 0 left for ante
      expect(state.seats[1].stack, 0);
      expect(state.seats[1].status, SeatStatus.allIn);
      expect(_totalChips(state), 2003);
    });

    test('ante + blinds both posted', () {
      final state = _setup(numSeats: 3, anteType: 0, anteAmount: 1);
      // blinds 15, ante 3 = 18
      expect(state.pot.total, 18);
    });

    test('heads-up with standard ante', () {
      final state = _setup(numSeats: 2, anteType: 0, anteAmount: 5);
      // blinds: SB=5, BB=10 = 15, ante: 2×5 = 10, total = 25
      expect(state.pot.total, 25);
      expect(_totalChips(state), 2000);
    });

    test('ante=0 does not change pot', () {
      final state = _setup(numSeats: 3, anteType: 0, anteAmount: 0);
      // Only blinds
      expect(state.pot.total, 15);
    });

    test('sitting-out players do not post ante', () {
      final state = _setup(
        customSeats: [
          _seat(0, stack: 1000),
          _seat(1, stack: 1000),
          _seat(2, stack: 1000),
          _seat(3, stack: 1000, status: SeatStatus.sittingOut),
        ],
        numSeats: 4,
        anteType: 0,
        anteAmount: 5,
      );
      // Seat 3 sitting out: not active, should not post ante
      // Active players: 3 (seats 0,1,2)
      // blinds 15 + ante 15 = 30
      expect(state.seats[3].stack, 1000); // unchanged
      expect(_totalChips(state), 4000);
    });
  });

  // ════════════════════════════════════════════════════════════════
  // Ante Type 1 — Button Ante
  // ════════════════════════════════════════════════════════════════
  group('Ante Type 1 - Button Ante', () {
    test('dealer posts full ante for all players', () {
      final state = _setup(numSeats: 4, anteType: 1, anteAmount: 2);
      // Dealer=seat0, 4 active players, total ante = 2×4 = 8
      // blinds 15 + ante 8 = 23
      expect(state.pot.total, 23);
      // Dealer stack: 1000 - 8 = 992
      expect(state.seats[0].stack, 992);
      expect(_totalChips(state), 4000);
    });

    test('dealer posts for 3 active players', () {
      final state = _setup(numSeats: 3, anteType: 1, anteAmount: 5);
      // Dealer=0, 3 players, total ante = 15
      // blinds 15 + ante 15 = 30
      expect(state.pot.total, 30);
      expect(state.seats[0].stack, 1000 - 15); // 985
    });

    test('dealer with insufficient stack goes all-in', () {
      final state = _setup(
        customSeats: [
          _seat(0, stack: 20), // dealer, needs to post 5×3=15 ante + nothing else
          _seat(1, stack: 1000),
          _seat(2, stack: 1000),
        ],
        anteType: 1,
        anteAmount: 5,
      );
      // Dealer posts blinds? No — dealer=0, SB=1, BB=2
      // Dealer stack 20, ante = 5×3 = 15 → posts 15 → stack = 5
      expect(state.seats[0].stack, 5);
      expect(_totalChips(state), 2020);
    });

    test('dealer all-in when ante exceeds stack', () {
      final state = _setup(
        customSeats: [
          _seat(0, stack: 5), // dealer, total ante=5×3=15 but only 5
          _seat(1, stack: 1000),
          _seat(2, stack: 1000),
        ],
        anteType: 1,
        anteAmount: 5,
      );
      expect(state.seats[0].stack, 0);
      expect(state.seats[0].status, SeatStatus.allIn);
      expect(_totalChips(state), 2005);
    });
  });

  // ════════════════════════════════════════════════════════════════
  // Ante Type 2 — BB Ante
  // ════════════════════════════════════════════════════════════════
  group('Ante Type 2 - BB Ante', () {
    test('BB posts full ante for all players', () {
      final state = _setup(numSeats: 3, anteType: 2, anteAmount: 5);
      // BB=seat2, 3 players, ante = 5×3 = 15
      // BB blind=10 → stack 1000-10=990, then ante 15 → 975
      expect(state.seats[2].stack, 975);
      // pot = blinds(15) + ante(15) = 30
      expect(state.pot.total, 30);
      expect(_totalChips(state), 3000);
    });

    test('BB with insufficient stack for ante goes all-in', () {
      final state = _setup(
        customSeats: [
          _seat(0, stack: 1000),
          _seat(1, stack: 1000),
          _seat(2, stack: 15), // BB posts 10 blind → 5 left, ante=15 → posts 5
        ],
        anteType: 2,
        anteAmount: 5,
      );
      expect(state.seats[2].stack, 0);
      expect(state.seats[2].status, SeatStatus.allIn);
      expect(_totalChips(state), 2015);
    });

    test('only BB loses chips for ante', () {
      final state = _setup(numSeats: 4, anteType: 2, anteAmount: 2);
      // BB=seat2, 4 active, ante = 2×4 = 8
      // Dealer(0): 1000, SB(1): 1000-5=995, BB(2): 1000-10-8=982, Seat3: 1000
      expect(state.seats[0].stack, 1000);
      expect(state.seats[1].stack, 995);
      expect(state.seats[2].stack, 982);
      expect(state.seats[3].stack, 1000);
    });

    test('4 players BB ante pot calculation', () {
      final state = _setup(numSeats: 4, anteType: 2, anteAmount: 2);
      // blinds(15) + ante(8) = 23
      expect(state.pot.total, 23);
      expect(_totalChips(state), 4000);
    });
  });

  // ════════════════════════════════════════════════════════════════
  // Ante Type 3 — BB Ante 1st (BB acts first)
  // ════════════════════════════════════════════════════════════════
  group('Ante Type 3 - BB Ante 1st', () {
    test('same posting as Type 2', () {
      final state = _setup(numSeats: 3, anteType: 3, anteAmount: 5);
      // Same money as type 2
      expect(state.pot.total, 30);
      expect(state.seats[2].stack, 975);
      expect(_totalChips(state), 3000);
    });

    test('BB acts first preflop', () {
      final state = _setup(numSeats: 3, anteType: 3, anteAmount: 5);
      // BB = seat 2 should act first
      expect(state.actionOn, 2);
    });

    test('BB acts first with 4 players', () {
      final state = _setup(numSeats: 4, anteType: 3, anteAmount: 2);
      // BB = seat 2
      expect(state.actionOn, 2);
    });

    test('BB insufficient stack still acts first', () {
      final state = _setup(
        customSeats: [
          _seat(0, stack: 1000),
          _seat(1, stack: 1000),
          _seat(2, stack: 30), // BB posts blind+ante, not all-in
        ],
        anteType: 3,
        anteAmount: 5,
      );
      // BB=2, blind=10, ante=15, stack=30-10-15=5 (still active)
      expect(state.actionOn, 2);
    });
  });

  // ════════════════════════════════════════════════════════════════
  // Ante Type 4 — Live Ante
  // ════════════════════════════════════════════════════════════════
  group('Ante Type 4 - Live Ante', () {
    test('all post ante counted toward currentBet', () {
      final state = _setup(numSeats: 3, anteType: 4, anteAmount: 5);
      // After blinds: SB bet=5, BB bet=10, seat0 bet=0
      // After live ante: SB bet=5+5=10, BB bet=10+5=15, seat0 bet=0+5=5
      expect(state.seats[0].currentBet, 5); // dealer posted ante
      expect(state.seats[1].currentBet, 10); // SB 5 blind + 5 ante
      expect(state.seats[2].currentBet, 15); // BB 10 blind + 5 ante
      expect(_totalChips(state), 3000);
    });

    test('betting.currentBet updated to max of BB and ante', () {
      final state = _setup(numSeats: 3, anteType: 4, anteAmount: 15);
      // ante=15 > bb=10, so currentBet = 15
      expect(state.betting.currentBet, 15);
    });

    test('betting.currentBet stays at BB when ante is smaller', () {
      final state = _setup(numSeats: 3, anteType: 4, anteAmount: 3);
      // ante=3 < bb=10, currentBet stays 10
      expect(state.betting.currentBet, 10);
    });

    test('pot includes both blinds and live antes', () {
      final state = _setup(numSeats: 3, anteType: 4, anteAmount: 5);
      // blinds 15 + antes 15 = 30
      expect(state.pot.total, 30);
    });
  });

  // ════════════════════════════════════════════════════════════════
  // Ante Type 5 — TB Ante (SB+BB split)
  // ════════════════════════════════════════════════════════════════
  group('Ante Type 5 - TB Ante', () {
    test('SB and BB split total ante', () {
      final state = _setup(numSeats: 4, anteType: 5, anteAmount: 2);
      // 4 players, ante per player = 2, total = 8
      // half = 4 (SB), other half = 4 (BB)
      // SB(seat1): 1000 - 5(blind) - 4(ante) = 991
      // BB(seat2): 1000 - 10(blind) - 4(ante) = 986
      expect(state.seats[1].stack, 991);
      expect(state.seats[2].stack, 986);
      expect(_totalChips(state), 4000);
    });

    test('correct pot calculation', () {
      final state = _setup(numSeats: 4, anteType: 5, anteAmount: 2);
      // blinds(15) + ante(8) = 23
      expect(state.pot.total, 23);
    });

    test('odd total ante rounds correctly', () {
      final state = _setup(numSeats: 3, anteType: 5, anteAmount: 3);
      // 3 players, total ante = 9
      // half = 4 (SB), other = 5 (BB)
      // SB(1): 1000-5-4 = 991, BB(2): 1000-10-5 = 985
      expect(state.seats[1].stack, 991);
      expect(state.seats[2].stack, 985);
      // pot = 15 + 9 = 24
      expect(state.pot.total, 24);
      expect(_totalChips(state), 3000);
    });
  });

  // ════════════════════════════════════════════════════════════════
  // Ante Type 6 — TB Ante 1st (SB acts first)
  // ════════════════════════════════════════════════════════════════
  group('Ante Type 6 - TB Ante 1st', () {
    test('same posting as Type 5', () {
      final state = _setup(numSeats: 4, anteType: 6, anteAmount: 2);
      expect(state.seats[1].stack, 991);
      expect(state.seats[2].stack, 986);
      expect(state.pot.total, 23);
    });

    test('SB acts first preflop', () {
      final state = _setup(numSeats: 4, anteType: 6, anteAmount: 2);
      // SB = seat 1
      expect(state.actionOn, 1);
    });

    test('chip conservation with TB Ante 1st', () {
      final state = _setup(numSeats: 3, anteType: 6, anteAmount: 5);
      expect(_totalChips(state), 3000);
    });
  });

  // ════════════════════════════════════════════════════════════════
  // Straddle
  // ════════════════════════════════════════════════════════════════
  group('Straddle', () {
    test('straddle posts 2xBB', () {
      // 4 players: dealer=0, SB=1, BB=2, straddle=3 (UTG)
      final state = _setup(
        numSeats: 4,
        straddleEnabled: true,
        straddleSeat: 3,
      );
      // Straddle = 2×10 = 20
      // Seat 3 stack: 1000 - 20 = 980
      expect(state.seats[3].stack, 980);
      expect(state.seats[3].currentBet, 20);
      expect(_totalChips(state), 4000);
    });

    test('betting.currentBet equals straddle amount', () {
      final state = _setup(
        numSeats: 4,
        straddleEnabled: true,
        straddleSeat: 3,
      );
      expect(state.betting.currentBet, 20);
    });

    test('first to act is seat after straddle', () {
      final state = _setup(
        numSeats: 4,
        straddleEnabled: true,
        straddleSeat: 3,
      );
      // Straddle on seat 3, first to act = seat 0 (wraps around)
      expect(state.actionOn, 0);
    });

    test('straddle + ante combined', () {
      final state = _setup(
        numSeats: 4,
        anteType: 0,
        anteAmount: 2,
        straddleEnabled: true,
        straddleSeat: 3,
      );
      // blinds(15) + ante(8) + straddle(20) = 43
      expect(state.pot.total, 43);
      expect(_totalChips(state), 4000);
    });

    test('straddle with insufficient stack goes all-in', () {
      final state = _setup(
        customSeats: [
          _seat(0, stack: 1000),
          _seat(1, stack: 1000),
          _seat(2, stack: 1000),
          _seat(3, stack: 15), // straddle=20 but only 15
        ],
        straddleEnabled: true,
        straddleSeat: 3,
      );
      expect(state.seats[3].stack, 0);
      expect(state.seats[3].status, SeatStatus.allIn);
      expect(state.seats[3].currentBet, 15);
      expect(_totalChips(state), 3015);
    });

    test('straddle disabled has no effect', () {
      final state = _setup(
        numSeats: 4,
        straddleEnabled: false,
        straddleSeat: 3,
      );
      expect(state.seats[3].currentBet, 0);
      expect(state.betting.currentBet, 10); // just BB
    });

    test('straddle minRaise set to straddle amount', () {
      final state = _setup(
        numSeats: 4,
        straddleEnabled: true,
        straddleSeat: 3,
      );
      expect(state.betting.minRaise, 20);
    });

    test('5 players with straddle on UTG', () {
      // dealer=0, SB=1, BB=2, UTG=3 (straddle), UTG+1=4
      final state = _setup(
        numSeats: 5,
        straddleEnabled: true,
        straddleSeat: 3,
      );
      // First to act should be seat 4
      expect(state.actionOn, 4);
      expect(state.seats[3].currentBet, 20);
    });
  });

  // ════════════════════════════════════════════════════════════════
  // Dead Button (sitting-out skipped for SB/BB)
  // ════════════════════════════════════════════════════════════════
  group('Dead Button', () {
    test('sitting-out seat skipped for SB', () {
      // dealer=0, seat1 sitting out, seat2 should be SB, seat3=BB
      // But currently: activeSeatIndices after dealer skips sittingOut
      final state = _setup(
        customSeats: [
          _seat(0, stack: 1000), // dealer
          _seat(1, stack: 1000, status: SeatStatus.sittingOut),
          _seat(2, stack: 1000), // should be SB
          _seat(3, stack: 1000), // should be BB
        ],
      );
      expect(state.sbSeat, 2);
      expect(state.bbSeat, 3);
    });

    test('sitting-out seat skipped for BB', () {
      // dealer=0, seat1=SB, seat2 sitting out, seat3=BB
      final state = _setup(
        customSeats: [
          _seat(0, stack: 1000), // dealer
          _seat(1, stack: 1000), // SB
          _seat(2, stack: 1000, status: SeatStatus.sittingOut),
          _seat(3, stack: 1000), // BB
        ],
      );
      expect(state.sbSeat, 1);
      expect(state.bbSeat, 3);
    });

    test('multiple sitting-out seats skipped', () {
      final state = _setup(
        customSeats: [
          _seat(0, stack: 1000), // dealer
          _seat(1, stack: 1000, status: SeatStatus.sittingOut),
          _seat(2, stack: 1000, status: SeatStatus.sittingOut),
          _seat(3, stack: 1000), // SB
          _seat(4, stack: 1000), // BB
        ],
      );
      expect(state.sbSeat, 3);
      expect(state.bbSeat, 4);
    });

    test('sitting-out player stack unchanged', () {
      final state = _setup(
        customSeats: [
          _seat(0, stack: 1000),
          _seat(1, stack: 1000, status: SeatStatus.sittingOut),
          _seat(2, stack: 1000),
          _seat(3, stack: 1000),
        ],
      );
      expect(state.seats[1].stack, 1000);
    });

    test('sitting-out player not included in activePlayers', () {
      final state = _setup(
        customSeats: [
          _seat(0, stack: 1000),
          _seat(1, stack: 1000, status: SeatStatus.sittingOut),
          _seat(2, stack: 1000),
          _seat(3, stack: 1000),
        ],
      );
      final activeIndices = state.activePlayers.map((s) => s.index).toList();
      expect(activeIndices, isNot(contains(1)));
    });
  });

  // ════════════════════════════════════════════════════════════════
  // Heads-up Blinds
  // ════════════════════════════════════════════════════════════════
  group('Heads-up Blinds', () {
    test('dealer is SB in heads-up', () {
      final state = _setup(numSeats: 2, dealerSeat: 0);
      expect(state.sbSeat, 0); // dealer = SB
      expect(state.bbSeat, 1);
    });

    test('SB/dealer acts first preflop in heads-up', () {
      final state = _setup(numSeats: 2, dealerSeat: 0);
      // Preflop: SB acts first in heads-up
      expect(state.actionOn, 0);
    });

    test('BB acts first postflop in heads-up', () {
      final state = _setup(numSeats: 2, dealerSeat: 0);
      // Advance to flop
      final flopState = Engine.apply(state, const StreetAdvance(Street.flop));
      // Postflop: first active after dealer (seat 0) = seat 1
      expect(flopState.actionOn, 1);
    });

    test('heads-up blind amounts correct', () {
      final state = _setup(numSeats: 2, dealerSeat: 0, sbAmount: 5, bbAmount: 10);
      // SB=dealer=seat0 posts 5, BB=seat1 posts 10
      expect(state.seats[0].currentBet, 5);
      expect(state.seats[1].currentBet, 10);
      expect(state.pot.total, 15);
    });
  });

  // ════════════════════════════════════════════════════════════════
  // Blind Posting Failure (short stack / zero stack)
  // ════════════════════════════════════════════════════════════════
  group('Blind Failure', () {
    test('short stack SB posts partial blind and goes all-in', () {
      final state = _setup(
        customSeats: [
          _seat(0, stack: 1000),
          _seat(1, stack: 3), // SB can only post 3 of 5
          _seat(2, stack: 1000),
        ],
      );
      expect(state.seats[1].stack, 0);
      expect(state.seats[1].currentBet, 3);
      expect(state.seats[1].status, SeatStatus.allIn);
      expect(_totalChips(state), 2003);
    });

    test('short stack BB posts partial blind and goes all-in', () {
      final state = _setup(
        customSeats: [
          _seat(0, stack: 1000),
          _seat(1, stack: 1000),
          _seat(2, stack: 7), // BB can only post 7 of 10
        ],
      );
      expect(state.seats[2].stack, 0);
      expect(state.seats[2].currentBet, 7);
      expect(state.seats[2].status, SeatStatus.allIn);
      expect(_totalChips(state), 2007);
    });

    test('zero stack player posts no blind', () {
      // Edge: a player at 0 stack shouldn't happen normally,
      // but verify no crash and conservation holds.
      final seats = [
        _seat(0, stack: 1000),
        _seat(1, stack: 0, status: SeatStatus.allIn),
        _seat(2, stack: 1000),
      ];
      // SB=seat1 (all-in, 0 stack) — posts 0
      var state = GameState(
        sessionId: 'test',
        variantName: 'nlh',
        seats: seats,
        deck: Deck.standard(seed: 42),
        bbAmount: 10,
      );
      state = Engine.apply(
        state,
        const HandStart(
          dealerSeat: 0,
          blinds: {1: 5, 2: 10},
        ),
      );
      // Seat 1 still at 0
      expect(state.seats[1].stack, 0);
      expect(state.seats[1].currentBet, 0);
      expect(_totalChips(state), 2000);
    });
  });
}
