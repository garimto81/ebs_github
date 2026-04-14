import '../cards/card.dart';
import '../cards/deck.dart';
import '../cards/hand_evaluator.dart';
import '../cards/badugi_evaluator.dart';
import 'draw_variant.dart';

/// Badugi — 4-card lowball draw game with unique suit/rank requirement.
///
/// Three draw rounds. 4 hole cards. Best hand: A-2-3-4 all different suits.
/// 4-card badugi > 3-card > 2-card > 1-card.
class Badugi extends DrawVariant {
  /// Cached BadugiRank from the last evaluateHi call, for external comparison.
  BadugiRank? lastBadugiRank;

  @override
  String get name => 'Badugi';

  @override
  Deck createDeck({int? seed}) => Deck.standard(seed: seed);

  @override
  int get holeCardCount => 4;

  @override
  bool get isHiLo => false;

  @override
  int get drawRounds => 3;

  @override
  int get maxDiscard => 4;

  @override
  HandRank evaluateHi(List<Card> hole, List<Card> community) {
    final badugi = BadugiEvaluator.bestBadugi(hole);
    lastBadugiRank = badugi;

    // Convert BadugiRank to HandRank for the engine's generic interface.
    // Strength: cardCount * 100 gives clear tier separation.
    // Kickers: inverted values (lower = better in badugi, so invert for compareTo).
    final kickers = badugi.values.reversed.map((v) => 15 - v).toList();
    return HandRank(
      category: HandCategory.highCard,
      kickers: kickers,
      strength: badugi.cardCount * 100,
    );
  }
}
