import '../cards/card.dart';
import '../cards/deck.dart';
import '../cards/hand_evaluator.dart';
import 'variant.dart';

class Omaha extends Variant {
  @override
  String get name => 'Omaha';

  @override
  Deck createDeck({int? seed}) => Deck.standard(seed: seed);

  @override
  int get holeCardCount => 4;

  @override
  int get communityCardCount => 5;

  @override
  bool get isHiLo => false;

  @override
  int get mustUseHole => 2;

  @override
  int get mustUseCommunity => 3;

  @override
  HandRank evaluateHi(List<Card> hole, List<Card> community) {
    return HandEvaluator.bestOmaha(
      hole: hole,
      community: community,
      categoryOrder: categoryOrder,
    );
  }
}
