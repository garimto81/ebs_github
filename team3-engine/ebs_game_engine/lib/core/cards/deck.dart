import 'dart:math';
import 'card.dart';

class Deck {
  final List<Card> _cards;
  final List<Card> _preset = [];
  int _presetIndex = 0;

  Deck._(this._cards);

  factory Deck.standard({int? seed}) {
    final cards = [
      for (final suit in Suit.values)
        for (final rank in Rank.values) Card(suit, rank),
    ];
    cards.shuffle(seed != null ? Random(seed) : Random());
    return Deck._(cards);
  }

  factory Deck.shortDeck({int? seed}) {
    const removed = {Rank.two, Rank.three, Rank.four, Rank.five};
    final cards = [
      for (final suit in Suit.values)
        for (final rank in Rank.values)
          if (!removed.contains(rank)) Card(suit, rank),
    ];
    cards.shuffle(seed != null ? Random(seed) : Random());
    return Deck._(cards);
  }

  int get remaining => (_preset.length - _presetIndex) + _cards.length;

  void setPreset(List<Card> cards) {
    _preset.addAll(cards);
    for (final c in cards) {
      _cards.remove(c);
    }
  }

  Card draw() {
    if (_presetIndex < _preset.length) {
      return _preset[_presetIndex++];
    }
    if (_cards.isEmpty) {
      throw StateError('Deck is empty');
    }
    return _cards.removeLast();
  }

  /// Reshuffle discarded cards back into the deck.
  /// Used in Draw games when deck runs out.
  void reshuffle(List<Card> discards, {int? seed}) {
    _cards.addAll(discards);
    _cards.shuffle(seed != null ? Random(seed) : Random());
  }

  Deck copy() {
    final d = Deck._(List.of(_cards));
    d._preset.addAll(_preset);
    d._presetIndex = _presetIndex;
    return d;
  }
}
