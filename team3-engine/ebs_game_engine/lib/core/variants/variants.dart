export 'variant.dart';
export 'nlh.dart';
export 'flh.dart';
export 'plh.dart';
export 'short_deck.dart';
export 'short_deck_triton.dart';
export 'pineapple.dart';
export 'omaha.dart';
export 'omaha_hilo.dart';
export 'five_card_omaha.dart';
export 'six_card_omaha.dart';
export 'courchevel.dart';

import 'variant.dart';
import 'nlh.dart';
import 'flh.dart';
import 'plh.dart';
import 'short_deck.dart';
import 'short_deck_triton.dart';
import 'pineapple.dart';
import 'omaha.dart';
import 'omaha_hilo.dart';
import 'five_card_omaha.dart';
import 'six_card_omaha.dart';
import 'courchevel.dart';

final Map<String, Variant Function()> variantRegistry = {
  'nlh': () => Nlh(),
  'flh': () => FixedLimitHoldem(),
  'flh_2_4': () => FixedLimitHoldem(smallBet: 2, bigBet: 4),
  'flh_5_10': () => FixedLimitHoldem(smallBet: 5, bigBet: 10),
  'plh': () => PotLimitHoldem(),
  'short_deck': () => ShortDeck(),
  'short_deck_triton': () => ShortDeckTriton(),
  'pineapple': () => Pineapple(),
  'omaha': () => Omaha(),
  'omaha_hilo': () => OmahaHiLo(),
  'five_card_omaha': () => FiveCardOmaha(),
  'five_card_omaha_hilo': () => FiveCardOmaha(hiLo: true),
  'six_card_omaha': () => SixCardOmaha(),
  'six_card_omaha_hilo': () => SixCardOmaha(hiLo: true),
  'courchevel': () => Courchevel(),
  'courchevel_hilo': () => Courchevel(hiLo: true),
};
