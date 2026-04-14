import '../state/game_state.dart';
import '../state/card_reveal_config.dart';

/// Data class for showdown reveal info per seat.
class ShowdownSeatInfo {
  final int seatIndex;
  final int revealOrder;
  final bool mustShow;
  final bool isWinner;

  const ShowdownSeatInfo({
    required this.seatIndex,
    required this.revealOrder,
    required this.mustShow,
    required this.isWinner,
  });
}

/// Determines the order in which players reveal cards at showdown,
/// and whether cards should be visible based on reveal configuration.
class ShowdownOrder {
  ShowdownOrder._();

  /// Get the reveal order: last aggressor first, then clockwise from dealer.
  static List<int> getRevealOrder(GameState state) {
    final active = <int>[];
    for (var i = 0; i < state.seats.length; i++) {
      final s = state.seats[i];
      if (!s.isFolded && s.holeCards.isNotEmpty) {
        active.add(i);
      }
    }

    if (active.isEmpty) return [];

    final lastAgg = state.betting.lastAggressor;

    if (lastAgg >= 0 && active.contains(lastAgg)) {
      // Last aggressor first, then clockwise
      final ordered = <int>[lastAgg];
      final n = state.seats.length;
      for (var i = 1; i < n; i++) {
        final idx = (lastAgg + i) % n;
        if (active.contains(idx) && idx != lastAgg) {
          ordered.add(idx);
        }
      }
      return ordered;
    }

    // No aggressor (checked around): start from dealer's left, clockwise
    final dealer = state.dealerSeat;
    final n = state.seats.length;
    final ordered = <int>[];
    for (var i = 1; i <= n; i++) {
      final idx = (dealer + i) % n;
      if (active.contains(idx)) {
        ordered.add(idx);
      }
    }
    return ordered;
  }

  /// Determine if a seat's cards should be visible based on reveal config.
  static bool shouldRevealCards({
    required int seatIndex,
    required GameState state,
    required List<int> revealOrder,
    required bool isWinner,
  }) {
    final config = state.revealConfig ?? CardRevealConfig.broadcast;

    // Venue canvas: never show (unless forced)
    if (state.canvasType == CanvasType.venue) return false;

    switch (config.revealType) {
      case RevealType.allImmediate:
        return true;
      case RevealType.winnerOnly:
        return isWinner;
      case RevealType.lastAggressorFirst:
        return true; // All show in order
      case RevealType.manualReveal:
      case RevealType.externalControl:
        return false; // External decision
      case RevealType.allAfterDecision:
        return true; // After all muck decisions made
    }
  }

  /// Determine if a player can muck (refuse to show) their cards.
  /// All-in players cannot muck. Winners at showdown must show.
  static bool canMuck({
    required int seatIndex,
    required GameState state,
    required bool isWinner,
  }) {
    final seat = state.seats[seatIndex];
    // All-in players must show (cannot muck)
    if (seat.isAllIn) return false;
    // Winners at showdown must show
    if (isWinner) return false;
    // Others can muck
    return true;
  }

  /// Get showdown info for all participating seats.
  /// [awards] maps seatIndex → amount won.
  static List<ShowdownSeatInfo> getShowdownInfo(
    GameState state,
    Map<int, int> awards,
  ) {
    final order = getRevealOrder(state);
    return order.map((idx) {
      final isWinner = awards.containsKey(idx);
      return ShowdownSeatInfo(
        seatIndex: idx,
        revealOrder: order.indexOf(idx),
        mustShow: !canMuck(seatIndex: idx, state: state, isWinner: isWinner),
        isWinner: isWinner,
      );
    }).toList();
  }
}
