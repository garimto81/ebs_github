import '../cards/card.dart';
import '../cards/deck.dart';
import '../cards/hand_evaluator.dart';
import 'stud_variant.dart';

/// Razz (Game 21) — A-5 Lowball Stud.
///
/// Goal: make the lowest possible 5-card hand from 7 cards.
/// Ace plays low (value 1). Straights and flushes are ignored.
/// Best hand: A-2-3-4-5 (the Wheel). No 8-or-better qualifier.
/// Bring-in: highest visible door card on 3rd street (reversed).
class Razz extends StudVariant {
  @override
  String get name => 'Razz';

  @override
  bool get isHiLo => false;

  @override
  bool get bringInLowest => false; // Highest door card brings in

  @override
  Deck createDeck({int? seed}) => Deck.standard(seed: seed);

  @override
  HandRank evaluateHi(List<Card> hole, List<Card> community) {
    // Razz: best low hand wins. Use A-5 lowball evaluation.
    // The "hi" evaluation returns the best low — lower is better.
    return HandEvaluator.bestLowballA5(hole);
  }
}
