import 'package:test/test.dart';
import 'package:ebs_game_engine/core/cards/card.dart';
import 'package:ebs_game_engine/core/cards/hand_evaluator.dart';
import 'package:ebs_game_engine/core/variants/short_deck.dart';
import 'package:ebs_game_engine/core/variants/short_deck_triton.dart';

List<Card> p(String s) => s.split(' ').map(Card.parse).toList();

void main() {
  group('Short Deck 6+', () {
    final sd = ShortDeck();

    test('creates 36-card deck', () {
      expect(sd.createDeck(seed: 42).remaining, 36);
    });

    test('flush beats full house', () {
      final flush = sd.evaluateHi(p('Ah Jh'), p('8h 6h 9h Kc Qd'));
      final fh = sd.evaluateHi(p('As Ad'), p('Ac Ks Kh 7d 6c'));
      expect(flush.compareTo(fh), greaterThan(0));
    });

    test('straight beats three of a kind', () {
      final straight = sd.evaluateHi(p('Ts 9h'), p('8d 7c 6s Kh Qd'));
      final trips = sd.evaluateHi(p('Qs Qh'), p('Qd 7c 6s Kh Ad'));
      expect(straight.compareTo(trips), greaterThan(0));
    });
  });

  group('Short Deck Triton', () {
    final triton = ShortDeckTriton();

    test('three of a kind beats straight', () {
      final trips = triton.evaluateHi(p('Qs Qh'), p('Qd 7c 6s Kh Ad'));
      final straight = triton.evaluateHi(p('Ts 9h'), p('8d 7c 6s Kh Qd'));
      expect(trips.compareTo(straight), greaterThan(0));
    });
  });
}
