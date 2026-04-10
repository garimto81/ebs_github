import '../cards/card.dart';
import '../cards/deck.dart';
import '../cards/hand_evaluator.dart';
import '../rules/bet_limit.dart';
import '../rules/pot_limit.dart';
import 'variant.dart';

/// Pot Limit Hold'em — same as NLH but with pot-limit betting.
class PotLimitHoldem extends Variant {
  @override
  String get name => "PL Hold'em";

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

  @override
  BetLimit get betLimit => const PotLimitBet();
}
