import 'package:test/test.dart';
import 'package:ebs_game_engine/core/cards/card.dart';
import 'package:ebs_game_engine/core/cards/deck.dart';

void main() {
  group('Deck', () {
    test('standard deck has 52 cards', () {
      final deck = Deck.standard(seed: 42);
      expect(deck.remaining, 52);
    });

    test('standard deck has no duplicates', () {
      final deck = Deck.standard(seed: 42);
      final cards = <Card>[];
      for (var i = 0; i < 52; i++) {
        cards.add(deck.draw());
      }
      expect(cards.toSet().length, 52);
    });

    test('shortDeck has 36 cards (no 2-5)', () {
      final deck = Deck.shortDeck(seed: 42);
      expect(deck.remaining, 36);
      final cards = <Card>[];
      for (var i = 0; i < 36; i++) {
        cards.add(deck.draw());
      }
      final ranks = cards.map((c) => c.rank).toSet();
      expect(ranks.contains(Rank.two), false);
      expect(ranks.contains(Rank.three), false);
      expect(ranks.contains(Rank.four), false);
      expect(ranks.contains(Rank.five), false);
      expect(ranks.contains(Rank.six), true);
    });

    test('draw removes card from deck', () {
      final deck = Deck.standard(seed: 42);
      deck.draw();
      expect(deck.remaining, 51);
    });

    test('draw throws when empty', () {
      final deck = Deck.standard(seed: 42);
      for (var i = 0; i < 52; i++) deck.draw();
      expect(() => deck.draw(), throwsStateError);
    });

    test('deterministic with same seed', () {
      final a = Deck.standard(seed: 42);
      final b = Deck.standard(seed: 42);
      for (var i = 0; i < 10; i++) {
        expect(a.draw(), b.draw());
      }
    });

    test('preset draws specific cards first', () {
      final deck = Deck.standard(seed: 42);
      final preset = [Card.parse('As'), Card.parse('Kh')];
      deck.setPreset(preset);
      expect(deck.draw(), Card.parse('As'));
      expect(deck.draw(), Card.parse('Kh'));
      expect(deck.remaining, 50);
    });
  });
}
