// 10-seat state management (BS-05-03).

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/enums/seat_status.dart';

part 'seat_provider.freezed.dart';

// ---------------------------------------------------------------------------
// Value objects (Freezed)
// ---------------------------------------------------------------------------

/// Minimal card representation for holecards.
@freezed
class HoleCard with _$HoleCard {
  const HoleCard._();

  const factory HoleCard({
    required String suit, // "s", "h", "d", "c"
    required String rank, // "A", "2"-"9", "T", "J", "Q", "K"
  }) = _HoleCard;

  @override
  String toString() => '$rank$suit';
}

/// Player info embedded in a seat.
@freezed
class PlayerInfo with _$PlayerInfo {
  const factory PlayerInfo({
    required int id,
    required String name,
    @Default(0) int stack,
    @Default('') String countryCode,
    String? avatarUrl,
  }) = _PlayerInfo;
}

/// Single seat state.
@freezed
class SeatState with _$SeatState {
  const SeatState._();

  const factory SeatState({
    required int seatNo, // 1-based (1..10)
    @Default(SeatStatus.empty) SeatStatus status,
    @Default(PlayerActivity.active) PlayerActivity activity,
    PlayerInfo? player,
    @Default(false) bool isDealer,
    @Default(false) bool isSB,
    @Default(false) bool isBB,
    @Default(false) bool actionOn,
    @Default([]) List<HoleCard> holeCards,
    @Default(0) int currentBet,
  }) = _SeatState;

  bool get isOccupied => player != null;
  bool get isEmpty => player == null && status == SeatStatus.empty;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class SeatNotifier extends StateNotifier<List<SeatState>> {
  SeatNotifier()
      : super(
          List.generate(10, (i) => SeatState(seatNo: i + 1)),
        );

  // -- helpers ---------------------------------------------------------------

  SeatState _seat(int seatNo) =>
      state.firstWhere((s) => s.seatNo == seatNo);

  List<SeatState> _update(int seatNo, SeatState Function(SeatState) fn) {
    return [
      for (final s in state)
        if (s.seatNo == seatNo) fn(s) else s,
    ];
  }

  // -- mutations -------------------------------------------------------------

  /// Seat a player at [seatNo]. Status -> newSeat.
  ///
  /// Seat_Management.md §2.3.1 Auto-assign: if no dealer currently set,
  /// the newly seated player becomes BTN automatically (빈 테이블 → NEW HAND
  /// 경로를 별도 UI 없이 확보).
  void seatPlayer(int seatNo, PlayerInfo player) {
    state = _update(
      seatNo,
      (s) => s.copyWith(
        player: player,
        status: SeatStatus.newSeat,
        activity: PlayerActivity.active,
      ),
    );

    // §2.3.1 — auto-assign dealer on first seat occupation
    final noDealer = !state.any((s) => s.isDealer);
    if (noDealer) {
      setDealer(seatNo);
    }
  }

  /// Remove player from [seatNo]. Status -> empty.
  ///
  /// Seat_Management.md §2.3.4 edge case: if vacated seat was BTN, auto-move
  /// dealer to the next clockwise occupied seat; if none remain, clear BTN
  /// (dealerSeatProvider -> null, §2.3.1 re-activation on next seatPlayer).
  void vacateSeat(int seatNo) {
    final wasDealer = _seat(seatNo).isDealer;
    state = _update(
      seatNo,
      (_) => SeatState(seatNo: seatNo),
    );

    if (wasDealer) {
      final occupied = state.where((s) => s.player != null).toList();
      if (occupied.isNotEmpty) {
        final next = occupied.firstWhere(
          (s) => s.seatNo > seatNo,
          orElse: () => occupied.first, // wrap
        );
        setDealer(next.seatNo);
      }
      // else: all vacant → no dealer (next seatPlayer triggers §2.3.1)
    }
  }

  /// Move player from seat [from] to seat [to].
  void moveSeat(int from, int to) {
    final source = _seat(from);
    if (source.player == null) return;

    final player = source.player!;
    // Vacate source
    state = _update(from, (s) => SeatState(seatNo: s.seatNo));
    // Place at destination with moved status
    state = _update(to, (s) => s.copyWith(
      player: player,
      status: SeatStatus.moved,
      activity: PlayerActivity.active,
    ));
  }

  /// Toggle sit-out for [seatNo].
  void toggleSitOut(int seatNo) {
    state = _update(seatNo, (s) {
      final next = s.activity == PlayerActivity.sittingOut
          ? PlayerActivity.active
          : PlayerActivity.sittingOut;
      return s.copyWith(activity: next);
    });
  }

  /// Promote seat status from newSeat/moved -> playing.
  void promoteToPlaying(int seatNo) {
    state = _update(seatNo, (s) => s.copyWith(status: SeatStatus.playing));
  }

  /// Mark player as busted.
  void bustPlayer(int seatNo) {
    state = _update(seatNo, (s) => s.copyWith(status: SeatStatus.busted));
  }

  // -- positional markers ----------------------------------------------------

  /// Set dealer button (clears previous dealer).
  void setDealer(int seatNo) {
    state = [
      for (final s in state)
        s.copyWith(isDealer: s.seatNo == seatNo),
    ];
  }

  /// Set small blind marker.
  void setSB(int seatNo) {
    state = [
      for (final s in state)
        s.copyWith(isSB: s.seatNo == seatNo),
    ];
  }

  /// Set big blind marker.
  void setBB(int seatNo) {
    state = [
      for (final s in state)
        s.copyWith(isBB: s.seatNo == seatNo),
    ];
  }

  /// Set action-on indicator (null clears all).
  /// 2026-05-10 B-220 — guard against EMPTY-seat actionOn:
  /// only set if target is occupied (player != null) and not folded/busted.
  void setActionOn(int? seatNo) {
    if (seatNo != null) {
      final target = state.firstWhere(
        (s) => s.seatNo == seatNo,
        orElse: () => state.first,
      );
      if (!target.isOccupied ||
          target.activity == PlayerActivity.folded ||
          target.status == SeatStatus.busted) {
        // Fall back: pick next active occupied seat. If none, clear.
        seatNo = nextActiveAfter(seatNo);
      }
    }
    state = [
      for (final s in state)
        s.copyWith(actionOn: seatNo != null && s.seatNo == seatNo),
    ];
  }

  /// 2026-05-10 B-220 — mark seat activity = folded for current hand.
  /// Used by ws_provider ActionPerformed (action_type=fold).
  void markFolded(int seatNo) {
    state = _update(seatNo, (s) => s.copyWith(activity: PlayerActivity.folded));
  }

  /// 2026-05-10 B-220 — find next occupied seat that is not folded/busted.
  /// Returns null if no other active seat (heads-up edge or last standing).
  int? nextActiveAfter(int fromSeat) {
    for (var offset = 1; offset <= state.length; offset++) {
      final idx = (fromSeat - 1 + offset) % state.length;
      final s = state[idx];
      if (s.isOccupied &&
          s.activity != PlayerActivity.folded &&
          s.status != SeatStatus.busted) {
        return s.seatNo;
      }
    }
    return null;
  }

  // -- card management -------------------------------------------------------

  /// Set holecards for [seatNo] (RFID or manual input).
  void setHoleCards(int seatNo, List<HoleCard> cards) {
    state = _update(seatNo, (s) => s.copyWith(holeCards: cards));
  }

  /// Clear all holecards (new hand).
  void clearAllCards() {
    state = [
      for (final s in state) s.copyWith(holeCards: const []),
    ];
  }

  // -- betting ---------------------------------------------------------------

  /// Update current bet for [seatNo].
  void setCurrentBet(int seatNo, int amount) {
    state = _update(seatNo, (s) => s.copyWith(currentBet: amount));
  }

  /// Set activity (fold, allIn, etc.) for [seatNo].
  void setActivity(int seatNo, PlayerActivity activity) {
    state = _update(seatNo, (s) => s.copyWith(activity: activity));
  }

  /// Update stack for [seatNo].
  void updateStack(int seatNo, int newStack) {
    final seat = _seat(seatNo);
    if (seat.player == null) return;
    state = _update(
      seatNo,
      (s) => s.copyWith(player: s.player!.copyWith(stack: newStack)),
    );
  }

  /// Clear bets for all seats (new street).
  void clearBets() {
    state = [
      for (final s in state) s.copyWith(currentBet: 0),
    ];
  }

  // -- bulk ------------------------------------------------------------------

  /// Bulk replace (server sync / reconnect).
  void replaceAll(List<SeatState> seats) => state = seats;

  /// Reset all seats to empty (table teardown).
  void resetAll() {
    state = List.generate(10, (i) => SeatState(seatNo: i + 1));
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final seatsProvider = StateNotifierProvider<SeatNotifier, List<SeatState>>(
  (ref) => SeatNotifier(),
);

/// Derived: count of active (non-sitting-out, occupied) seats.
final activePlayerCountProvider = Provider<int>((ref) {
  final seats = ref.watch(seatsProvider);
  return seats
      .where((s) =>
          s.player != null && s.activity != PlayerActivity.sittingOut)
      .length;
});

/// Derived: seat number of current dealer, or null.
final dealerSeatProvider = Provider<int?>((ref) {
  final seats = ref.watch(seatsProvider);
  for (final s in seats) {
    if (s.isDealer) return s.seatNo;
  }
  return null;
});

/// Derived: seat number that has action, or null.
final actionOnSeatProvider = Provider<int?>((ref) {
  final seats = ref.watch(seatsProvider);
  for (final s in seats) {
    if (s.actionOn) return s.seatNo;
  }
  return null;
});
