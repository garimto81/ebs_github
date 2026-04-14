import '../cards/card.dart';
import '../cards/deck.dart';
import '../cards/hand_evaluator.dart';
import 'draw_variant.dart';

/// 2-7 Single Draw Lowball.
///
/// Single draw round. A = High (14). Straights and flushes count
/// against you (make the hand worse). Best hand: 7-5-4-3-2 offsuit.
class DeuceSevenSingle extends DrawVariant {
  @override
  String get name => '2-7 Single Draw';

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
    return HandEvaluator.bestLowball27(hole);
  }
}
