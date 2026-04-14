import '../cards/card.dart';
import '../cards/deck.dart';
import '../cards/hand_evaluator.dart';
import '../cards/badugi_evaluator.dart';
import 'draw_variant.dart';

/// Badeucy — Hi-Lo split: Badugi (hi) + 2-7 Lowball (lo).
///
/// 5 hole cards, 3 draw rounds. Pot splits between:
/// - Hi: best Badugi from C(5,4) combinations
/// - Lo: best 2-7 Lowball from 5 cards
class Badeucy extends DrawVariant {
  @override
  String get name => 'Badeucy';

  @override
  Deck createDeck({int? seed}) => Deck.standard(seed: seed);

  @override
  int get holeCardCount => 5;

  @override
  bool get isHiLo => true;

  @override
  int get drawRounds => 3;

  @override
  HandRank evaluateHi(List<Card> hole, List<Card> community) {
    // Best Badugi from all C(5,4) combinations
    final badugi = BadugiEvaluator.bestBadugi(hole);

    final kickers = badugi.values.reversed.map((v) => 15 - v).toList();
    return HandRank(
      category: HandCategory.highCard,
      kickers: kickers,
      strength: badugi.cardCount * 100,
    );
  }

  @override
  HandRank? evaluateLo(List<Card> hole, List<Card> community) {
    return HandEvaluator.bestLowball27(hole);
  }
}
