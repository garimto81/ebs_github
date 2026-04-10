import '../cards/card.dart';
import '../cards/deck.dart';
import '../cards/hand_evaluator.dart';
import 'variant.dart';

/// No-Limit Texas Hold'em implementation.
class Nlh extends Variant {
  @override
  String get name => "NL Hold'em";

  @override
  Deck createDeck({int? seed}) => Deck.standard(seed: seed);

  @override
  int get holeCardCount => 2;

  @override
  int get communityCardCount => 5;

  @override
  bool get isHiLo => false;

  @override
  HandRank evaluateHi(List<Card> hole, List<Card> community) {
    return HandEvaluator.bestHand(
      [...hole, ...community],
      categoryOrder: categoryOrder,
    );
  }
}
