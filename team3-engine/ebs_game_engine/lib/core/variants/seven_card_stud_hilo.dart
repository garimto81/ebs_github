import '../cards/card.dart';
import '../cards/deck.dart';
import '../cards/hand_evaluator.dart';
import 'stud_variant.dart';

/// 7-Card Stud Hi-Lo 8-or-Better (Game 20).
///
/// Split pot: best high hand and best qualifying low hand (8-or-better)
/// each take half the pot. If no qualifying low, high takes all.
/// Bring-in: lowest visible door card on 3rd street.
class SevenCardStudHiLo extends StudVariant {
  @override
  String get name => '7-Card Stud Hi-Lo';

  @override
  bool get isHiLo => true;

  @override
  bool get bringInLowest => true;

  @override
  Deck createDeck({int? seed}) => Deck.standard(seed: seed);

  @override
  HandRank evaluateHi(List<Card> hole, List<Card> community) {
    return HandEvaluator.bestHand(hole);
  }

  @override
  HandRank? evaluateLo(List<Card> hole, List<Card> community) {
    // 8-or-better: find the best qualifying low from C(7,5) combinations.
    return HandEvaluator.bestLow8(hole);
  }
}
