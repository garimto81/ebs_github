// 10-seat state management (BS-05-03).
//
// Uses inline SeatState / PlayerInfo classes instead of Freezed entities
// (generated .freezed.dart files not yet available). Will be replaced
// with Freezed Seat / Player when build_runner runs.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/enums/seat_status.dart';

// ---------------------------------------------------------------------------
// Lightweight value objects (Freezed-free, copyWith included)
// ---------------------------------------------------------------------------

/// Minimal card representation for holecards.
class HoleCard {
  const HoleCard({required this.suit, required this.rank});

  final String suit; // "s", "h", "d", "c"
  final String rank; // "A", "2"-"9", "T", "J", "Q", "K"

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HoleCard && suit == other.suit && rank == other.rank;

  @override
  int get hashCode => Object.hash(suit, rank);

  @override
  String toString() => '$rank$suit';
}

/// Player info embedded in a seat.
class PlayerInfo {
  const PlayerInfo({
    required this.id,
    required this.name,
    this.stack = 0,
    this.countryCode = '',
    this.avatarUrl,
  });

  final int id;
  final String name;
  final int stack;
  final String countryCode;
  final String? avatarUrl;

  PlayerInfo copyWith({
    int? id,
    String? name,
    int? stack,
    String? countryCode,
    String? avatarUrl,
  }) =>
      PlayerInfo(
        id: id ?? this.id,
        name: name ?? this.name,
        stack: stack ?? this.stack,
        countryCode: countryCode ?? this.countryCode,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );
}

/// Single seat state.
class SeatState {
  const SeatState({
    required this.seatNo,
    this.status = SeatStatus.empty,
    this.activity = PlayerActivity.active,
    this.player,
    this.isDealer = false,
    this.isSB = false,
    this.isBB = false,
    this.actionOn = false,
    this.holeCards = const [],
    this.currentBet = 0,
  });

  final int seatNo; // 1-based (1..10)
  final SeatStatus status;
  final PlayerActivity activity;
  final PlayerInfo? player;
  final bool isDealer;
  final bool isSB;
  final bool isBB;
  final bool actionOn;
  final List<HoleCard> holeCards;
  final int currentBet;

  bool get isOccupied => player != null;
  bool get isEmpty => player == null && status == SeatStatus.empty;

  SeatState copyWith({
    int? seatNo,
    SeatStatus? status,
    PlayerActivity? activity,
    PlayerInfo? player,
    bool clearPlayer = false,
    bool? isDealer,
    bool? isSB,
    bool? isBB,
    bool? actionOn,
    List<HoleCard>? holeCards,
    int? currentBet,
  }) =>
      SeatState(
        seatNo: seatNo ?? this.seatNo,
        status: status ?? this.status,
        activity: activity ?? this.activity,
        player: clearPlayer ? null : (player ?? this.player),
        isDealer: isDealer ?? this.isDealer,
        isSB: isSB ?? this.isSB,
        isBB: isBB ?? this.isBB,
        actionOn: actionOn ?? this.actionOn,
        holeCards: holeCards ?? this.holeCards,
        currentBet: currentBet ?? this.currentBet,
      );
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
  void seatPlayer(int seatNo, PlayerInfo player) {
    state = _update(
      seatNo,
      (s) => s.copyWith(
        player: player,
        status: SeatStatus.newSeat,
        activity: PlayerActivity.active,
      ),
    );
  }

  /// Remove player from [seatNo]. Status -> empty.
  void vacateSeat(int seatNo) {
    state = _update(
      seatNo,
      (s) => s.copyWith(
        clearPlayer: true,
        status: SeatStatus.empty,
        activity: PlayerActivity.active,
        holeCards: const [],
        currentBet: 0,
        isDealer: false,
        isSB: false,
        isBB: false,
        actionOn: false,
      ),
    );
  }

  /// Move player from seat [from] to seat [to].
  void moveSeat(int from, int to) {
    final source = _seat(from);
    if (source.player == null) return;

    final player = source.player!;
    // Vacate source
    state = _update(from, (s) => s.copyWith(
      clearPlayer: true,
      status: SeatStatus.empty,
      holeCards: const [],
      currentBet: 0,
    ));
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
  void setActionOn(int? seatNo) {
    state = [
      for (final s in state)
        s.copyWith(actionOn: seatNo != null && s.seatNo == seatNo),
    ];
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
