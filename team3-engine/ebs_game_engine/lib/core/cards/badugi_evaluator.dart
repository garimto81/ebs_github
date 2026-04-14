import 'card.dart';

/// Represents a Badugi hand ranking.
///
/// Badugi uses 4 cards with unique suits and ranks.
/// Duplicate suits or ranks cause the highest offending card to be removed.
/// 4-card badugi > 3-card > 2-card > 1-card.
/// Within same card count, lowest high card wins.
class BadugiRank implements Comparable<BadugiRank> {
  /// Number of valid cards in the badugi hand (1-4).
  final int cardCount;

  /// The values of valid cards, sorted ascending (Ace = 1).
  final List<int> values;

  const BadugiRank({required this.cardCount, required this.values});

  @override
  int compareTo(BadugiRank other) {
    // More cards = better hand
    if (cardCount != other.cardCount) {
      return cardCount.compareTo(other.cardCount);
    }
    // Same card count: compare from highest card down (lower is better)
    // We compare reversed (highest first) and invert: lower value wins
    for (var i = values.length - 1; i >= 0 && i >= 0; i--) {
      if (i >= other.values.length) return 1;
      if (values[i] != other.values[i]) {
        // Lower value is better in Badugi, so invert comparison
        return other.values[i].compareTo(values[i]);
      }
    }
    return 0;
  }

  @override
  bool operator ==(Object other) =>
      other is BadugiRank && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(cardCount, Object.hashAll(values));

  @override
  String toString() => 'Badugi$cardCount($values)';
}

/// Evaluator for Badugi poker hands.
class BadugiEvaluator {
  BadugiEvaluator._();

  /// Evaluate the best Badugi hand from N cards.
  ///
  /// For N > 4, tries all C(N,4) combinations and returns the best.
  /// For N <= 4, evaluates the hand directly.
  static BadugiRank bestBadugi(List<Card> cards) {
    assert(cards.isNotEmpty, 'Need at least 1 card');

    if (cards.length <= 4) {
      return _evaluateBadugi(cards);
    }

    // Try all 4-card combinations
    BadugiRank? best;
    for (final combo in _combinations(cards, 4)) {
      final rank = _evaluateBadugi(combo);
      if (best == null || rank.compareTo(best) > 0) {
        best = rank;
      }
    }
    return best!;
  }

  /// Evaluate a Badugi hand (up to 4 cards).
  ///
  /// Remove cards that create duplicate suits or ranks,
  /// keeping the combination that yields the best (most cards, lowest values) hand.
  static BadugiRank _evaluateBadugi(List<Card> cards) {
    // Convert to (value, suit) pairs. Ace = 1 in Badugi.
    final entries = cards.map((c) {
      final v = c.rank.value == 14 ? 1 : c.rank.value;
      return _BadugiCard(v, c.suit);
    }).toList();

    // Try all subsets from largest to smallest to find the best valid badugi
    BadugiRank? best;
    for (var size = entries.length; size >= 1; size--) {
      for (final subset in _combinations(entries, size)) {
        if (_isValidBadugi(subset)) {
          final vals = subset.map((e) => e.value).toList()..sort();
          final rank = BadugiRank(cardCount: size, values: vals);
          if (best == null || rank.compareTo(best) > 0) {
            best = rank;
          }
        }
      }
      // If we found a valid hand at this size, no need to check smaller
      if (best != null) break;
    }

    return best!;
  }

  /// Check if all cards have unique suits and unique ranks.
  static bool _isValidBadugi(List<_BadugiCard> cards) {
    final suits = <Suit>{};
    final values = <int>{};
    for (final c in cards) {
      if (!suits.add(c.suit)) return false;
      if (!values.add(c.value)) return false;
    }
    return true;
  }

  /// Generate all combinations of size k from the list.
  static Iterable<List<T>> _combinations<T>(List<T> list, int k) sync* {
    if (k == 0) {
      yield [];
      return;
    }
    if (list.length < k) return;

    for (var i = 0; i <= list.length - k; i++) {
      for (final rest in _combinations(list.sublist(i + 1), k - 1)) {
        yield [list[i], ...rest];
      }
    }
  }
}

class _BadugiCard {
  final int value;
  final Suit suit;
  const _BadugiCard(this.value, this.suit);
}
