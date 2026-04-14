import '../cards/card.dart';
import '../cards/deck.dart';
import '../cards/hand_evaluator.dart';
import 'draw_variant.dart';

/// A-5 Triple Draw Lowball.
///
/// Three draw rounds. A = Low (1). Straights and flushes are ignored.
/// Best hand: A-2-3-4-5 (Wheel).
class AceFiveTriple extends DrawVariant {
  @override
  String get name => 'A-5 Triple Draw';

  @override
  Deck createDeck({int? seed}) => Deck.standard(seed: seed);

  @override
  int get holeCardCount => 5;

  @override
  bool get isHiLo => false;

  @override
  int get drawRounds => 3;

  @override
  HandRank evaluateHi(List<Card> hole, List<Card> community) {
    return HandEvaluator.bestLowballA5(hole);
  }
}
