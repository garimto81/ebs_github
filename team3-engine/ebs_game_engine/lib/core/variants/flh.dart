import '../cards/card.dart';
import '../cards/deck.dart';
import '../cards/hand_evaluator.dart';
import '../rules/bet_limit.dart';
import '../rules/fixed_limit.dart';
import 'variant.dart';

/// Fixed Limit Hold'em — same as NLH but with fixed bet sizes.
class FixedLimitHoldem extends Variant {
  final int smallBet;
  final int bigBet;

  FixedLimitHoldem({this.smallBet = 2, this.bigBet = 4});

  @override
  String get name => "FL Hold'em";

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
  BetLimit get betLimit => FixedLimitBet(smallBet: smallBet, bigBet: bigBet);
}
