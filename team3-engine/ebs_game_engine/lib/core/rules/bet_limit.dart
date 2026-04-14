import '../state/game_state.dart';

/// Abstract interface for betting limit strategies.
///
/// Each poker variant uses one of four betting structures:
/// No-Limit, Pot-Limit, Fixed-Limit, or Spread-Limit.
/// This strategy pattern lets the engine swap structures
/// without changing action-resolution logic.
abstract class BetLimit {
  const BetLimit();

  /// Human-readable name (e.g. "No Limit", "Pot Limit").
  String get name;

  /// Minimum opening bet (first voluntary wager on a street).
  int minBet(GameState state);

  /// Maximum opening bet for the seat at [seatIndex].
  int maxBet(GameState state, int seatIndex);

  /// Minimum raise-to amount (total bet after raising).
  int minRaiseTo(GameState state);

  /// Maximum raise-to amount for the seat at [seatIndex].
  int maxRaiseTo(GameState state, int seatIndex);

  /// Maximum number of bets+raises per street, or `null` for unlimited.
  ///
  /// Fixed-Limit standard is 4 (1 bet + 3 raises).
  int? get raiseCap;
}
