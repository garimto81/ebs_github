import '../cards/card.dart';
import '../cards/deck.dart';
import '../cards/hand_evaluator.dart';
import 'variant.dart';

/// Short Deck Triton variant.
/// Flush beats full house; three of a kind beats straight.
class ShortDeckTriton extends Variant {
  @override
  String get name => 'Short Deck Triton';

  @override
  Deck createDeck({int? seed}) => Deck.shortDeck(seed: seed);

  @override
  int get holeCardCount => 2;

  @override
  int get communityCardCount => 5;

  @override
  bool get isHiLo => false;

  @override
  List<HandCategory> get categoryOrder => HandCategory.shortDeckTritonOrder;

  @override
  HandRank evaluateHi(List<Card> hole, List<Card> community) {
    return HandEvaluator.bestHand(
      [...hole, ...community],
      categoryOrder: categoryOrder,
    );
  }
}
