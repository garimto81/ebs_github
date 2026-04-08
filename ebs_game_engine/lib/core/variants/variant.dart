import '../cards/card.dart';
import '../cards/deck.dart';
import '../cards/hand_evaluator.dart';

/// Abstract interface for all poker game variants.
abstract class Variant {
  /// Display name of the variant.
  String get name;

  /// Create a new shuffled deck for this variant.
  Deck createDeck({int? seed});

  /// Number of hole (private) cards dealt to each player.
  int get holeCardCount;

  /// Total community cards dealt across all streets.
  int get communityCardCount;

  /// Whether this variant splits the pot between hi and lo hands.
  bool get isHiLo;

  /// Community cards dealt before the first betting round (e.g., Courchevel).
  int get preflopCommunityCount => 0;

  /// Whether players must discard cards at some point.
  bool get requiresDiscard => false;

  /// Street index after which discard occurs (-1 = never).
  int get discardAfterStreet => -1;

  /// Number of hole cards that MUST be used (0 = any, 2 = Omaha).
  int get mustUseHole => 0;

  /// Number of community cards that MUST be used (0 = any, 3 = Omaha).
  int get mustUseCommunity => 0;

  /// Hand category ranking order for this variant.
  List<HandCategory> get categoryOrder => HandCategory.standardOrder;

  /// Evaluate the best hi hand from hole + community cards.
  HandRank evaluateHi(List<Card> hole, List<Card> community);

  /// Evaluate the best lo hand (returns null if variant has no lo,
  /// or if no qualifying lo hand exists).
  HandRank? evaluateLo(List<Card> hole, List<Card> community) => null;
}
