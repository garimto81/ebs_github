import '../cards/card.dart';
import '../cards/deck.dart';
import '../cards/hand_evaluator.dart';
import 'draw_variant.dart';

/// Five Card Draw — single draw, standard high hand evaluation.
class FiveCardDraw extends DrawVariant {
  @override
  String get name => '5-Card Draw';

  @override
  Deck createDeck({int? seed}) => Deck.standard(seed: seed);

  @override
  int get holeCardCount => 5;

  @override
  bool get isHiLo => false;

  @override
  int get drawRounds => 1;

  @override
  HandRank evaluateHi(List<Card> hole, List<Card> community) {
    // Draw games: no community cards, evaluate 5 hole cards directly
    return HandEvaluator.bestHand(hole);
  }
}
