import '../cards/card.dart';
import '../cards/deck.dart';
import '../cards/hand_evaluator.dart';
import 'variant.dart';

/// Pineapple Hold'em implementation.
///
/// Players receive 3 hole cards and must discard 1 before the flop.
/// After the discard, hand evaluation follows standard NLH rules.
class Pineapple extends Variant {
  @override
  String get name => 'Pineapple';

  @override
  Deck createDeck({int? seed}) => Deck.standard(seed: seed);

  @override
  int get holeCardCount => 3;

  @override
  int get communityCardCount => 5;

  @override
  bool get isHiLo => false;

  @override
  bool get requiresDiscard => true;

  /// Discard occurs after street 0 (preflop), i.e. before the flop.
  @override
  int get discardAfterStreet => 0;

  /// After discarding, players may use any combination of hole + community cards.
  @override
  int get mustUseHole => 0;

  @override
  HandRank evaluateHi(List<Card> hole, List<Card> community) {
    return HandEvaluator.bestHand(
      [...hole, ...community],
      categoryOrder: categoryOrder,
    );
  }
}
