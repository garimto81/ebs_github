import '../cards/card.dart';
import '../cards/deck.dart';
import '../cards/hand_evaluator.dart';
import 'variant.dart';

class Courchevel extends Variant {
  final bool hiLo;
  Courchevel({this.hiLo = false});

  @override
  String get name => hiLo ? 'Courchevel Hi-Lo' : 'Courchevel';

  @override
  Deck createDeck({int? seed}) => Deck.standard(seed: seed);

  @override
  int get holeCardCount => 5;

  @override
  int get communityCardCount => 5;

  @override
  bool get isHiLo => hiLo;

  @override
  int get preflopCommunityCount => 1;

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
    if (!hiLo) return null;
    return HandEvaluator.bestOmahaLo(hole: hole, community: community);
  }
}
