import '../cards/card.dart';
import '../cards/deck.dart';
import '../cards/hand_evaluator.dart';
import 'stud_variant.dart';

/// 7-Card Stud (Game 19) — high hand only.
///
/// Each player receives 7 cards (2 down, 4 up, 1 down).
/// Best 5-card high hand wins.
/// Bring-in: lowest visible door card on 3rd street.
class SevenCardStud extends StudVariant {
  @override
  String get name => '7-Card Stud';

  @override
  bool get isHiLo => false;

  @override
  bool get bringInLowest => true;

  @override
  Deck createDeck({int? seed}) => Deck.standard(seed: seed);

  @override
  HandRank evaluateHi(List<Card> hole, List<Card> community) {
    // In Stud, all 7 cards are in hole; community is always empty.
    // Find the best 5-card hand from all 7.
    return HandEvaluator.bestHand(hole);
  }
}
