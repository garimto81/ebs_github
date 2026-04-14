import 'package:test/test.dart';
import 'package:ebs_game_engine/core/cards/card.dart';

void main() {
  group('Card', () {
    test('creates card with suit and rank', () {
      final card = Card(Suit.spade, Rank.ace);
      expect(card.suit, Suit.spade);
      expect(card.rank, Rank.ace);
    });

    test('displays short notation', () {
      expect(Card(Suit.spade, Rank.ace).notation, 'As');
      expect(Card(Suit.heart, Rank.king).notation, 'Kh');
      expect(Card(Suit.diamond, Rank.ten).notation, 'Td');
      expect(Card(Suit.club, Rank.two).notation, '2c');
    });

    test('parses from notation', () {
      final card = Card.parse('As');
      expect(card.suit, Suit.spade);
      expect(card.rank, Rank.ace);
    });

    test('equality by suit and rank', () {
      final a = Card(Suit.spade, Rank.ace);
      final b = Card(Suit.spade, Rank.ace);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('rank value ordering', () {
      expect(Rank.ace.value, greaterThan(Rank.king.value));
      expect(Rank.two.value, lessThan(Rank.three.value));
    });
  });
}
