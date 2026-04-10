enum Suit {
  spade('s'),
  heart('h'),
  diamond('d'),
  club('c');

  final String symbol;
  const Suit(this.symbol);

  static Suit fromSymbol(String s) => switch (s) {
    's' => spade,
    'h' => heart,
    'd' => diamond,
    'c' => club,
    _ => throw ArgumentError('Invalid suit symbol: $s'),
  };
}

enum Rank {
  two(2, '2'),
  three(3, '3'),
  four(4, '4'),
  five(5, '5'),
  six(6, '6'),
  seven(7, '7'),
  eight(8, '8'),
  nine(9, '9'),
  ten(10, 'T'),
  jack(11, 'J'),
  queen(12, 'Q'),
  king(13, 'K'),
  ace(14, 'A');

  final int value;
  final String symbol;
  const Rank(this.value, this.symbol);

  static Rank fromSymbol(String s) => values.firstWhere(
    (r) => r.symbol == s,
    orElse: () => throw ArgumentError('Invalid rank symbol: $s'),
  );
}

class Card {
  final Suit suit;
  final Rank rank;

  const Card(this.suit, this.rank);

  String get notation => '${rank.symbol}${suit.symbol}';

  factory Card.parse(String notation) {
    if (notation.length != 2) {
      throw ArgumentError('Card notation must be 2 chars: $notation');
    }
    return Card(
      Suit.fromSymbol(notation[1]),
      Rank.fromSymbol(notation[0]),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Card && suit == other.suit && rank == other.rank;

  @override
  int get hashCode => Object.hash(suit, rank);

  @override
  String toString() => notation;
}
