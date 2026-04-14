import '../cards/card.dart';
import '../cards/deck.dart';
import '../cards/hand_evaluator.dart';
import 'variant.dart';

/// Abstract base class for all Stud poker variants.
///
/// Stud games deal individual cards to each player (no community cards).
/// Players receive a mix of face-down (hidden) and face-up (visible) cards
/// across multiple streets (3rd through 7th street).
abstract class StudVariant extends Variant {
  /// Stud players receive 7 cards total (3 down + 4 up).
  @override
  int get holeCardCount => 7;

  /// Stud has no community cards — all cards are individual.
  @override
  int get communityCardCount => 0;

  /// Number of betting streets (always 5: 3rd, 4th, 5th, 6th, 7th).
  int get streetCount => 5;

  /// Whether the lowest door card has the bring-in obligation.
  ///
  /// - `true` (default): lowest up card brings in (Stud, Stud Hi-Lo).
  /// - `false`: highest up card brings in (Razz).
  bool get bringInLowest => true;

  /// Number of face-down cards dealt in the initial deal (3rd street).
  int get initialDownCards => 2;

  /// Number of face-up cards dealt in the initial deal (3rd street).
  int get initialUpCards => 1;
}
