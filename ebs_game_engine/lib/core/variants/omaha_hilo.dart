import '../cards/card.dart';
import '../cards/deck.dart';
import '../cards/hand_evaluator.dart';
import 'variant.dart';

class OmahaHiLo extends Variant {
  @override
  String get name => 'Omaha Hi-Lo';

  @override
  Deck createDeck({int? seed}) => Deck.standard(seed: seed);

  @override
  int get holeCardCount => 4;

  @override
  int get communityCardCount => 5;

  @override
  bool get isHiLo => true;

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

  @override
  HandRank? evaluateLo(List<Card> hole, List<Card> community) {
    return HandEvaluator.bestOmahaLo(hole: hole, community: community);
  }
}
