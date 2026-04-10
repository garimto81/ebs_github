import '../cards/card.dart';
import '../cards/deck.dart';
import '../cards/hand_evaluator.dart';
import 'variant.dart';

/// Short Deck 6+ variant.
/// Flush beats full house; straight beats three of a kind.
class ShortDeck extends Variant {
  @override
  String get name => 'Short Deck 6+';

  @override
  Deck createDeck({int? seed}) => Deck.shortDeck(seed: seed);

  @override
  int get holeCardCount => 2;

  @override
  int get communityCardCount => 5;

  @override
  bool get isHiLo => false;

  @override
  List<HandCategory> get categoryOrder => HandCategory.shortDeck6PlusOrder;

  @override
  HandRank evaluateHi(List<Card> hole, List<Card> community) {
    return HandEvaluator.bestHand(
      [...hole, ...community],
      categoryOrder: categoryOrder,
    );
  }
}
