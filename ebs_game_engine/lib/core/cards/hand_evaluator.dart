import 'card.dart';

/// Hand category rankings for poker.
enum HandCategory {
  royalFlush(10),
  straightFlush(9),
  fourOfAKind(8),
  fullHouse(7),
  flush(6),
  straight(5),
  threeOfAKind(4),
  twoPair(3),
  onePair(2),
  highCard(1);

  final int defaultStrength;
  const HandCategory(this.defaultStrength);

  /// Standard poker hand ranking order (highest to lowest).
  static const standardOrder = [
    royalFlush,
    straightFlush,
    fourOfAKind,
    fullHouse,
    flush,
    straight,
    threeOfAKind,
    twoPair,
    onePair,
    highCard,
  ];

  /// Short Deck 6+: flush beats full house, straight beats trips.
  static const shortDeck6PlusOrder = [
    royalFlush,
    straightFlush,
    fourOfAKind,
    flush,
    fullHouse,
    straight,
    threeOfAKind,
    twoPair,
    onePair,
    highCard,
  ];

  /// Short Deck Triton: flush beats full house, trips beats straight.
  static const shortDeckTritonOrder = [
    royalFlush,
    straightFlush,
    fourOfAKind,
    flush,
    fullHouse,
    threeOfAKind,
    straight,
    twoPair,
    onePair,
    highCard,
  ];
}

/// Represents a fully evaluated poker hand with category, kickers,
/// and a strength value derived from the category order.
class HandRank implements Comparable<HandRank> {
  final HandCategory category;
  final List<int> kickers;
  final int strength;

  const HandRank({
    required this.category,
    required this.kickers,
    required this.strength,
  });

  @override
  int compareTo(HandRank other) {
    if (strength != other.strength) return strength.compareTo(other.strength);
    for (var i = 0; i < kickers.length && i < other.kickers.length; i++) {
      if (kickers[i] != other.kickers[i]) {
        return kickers[i].compareTo(other.kickers[i]);
      }
    }
    return 0;
  }

  @override
  bool operator ==(Object other) =>
      other is HandRank && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(category, Object.hashAll(kickers));

  @override
  String toString() => '${category.name}($kickers)';
}

/// Core poker hand evaluator supporting standard, Omaha, and Hi-Lo.
class HandEvaluator {
  HandEvaluator._();

  /// Find the best 5-card hand from N cards (C(N,5) combinations).
  static HandRank bestHand(
    List<Card> cards, {
    List<HandCategory>? categoryOrder,
  }) {
    final order = categoryOrder ?? HandCategory.standardOrder;
    assert(cards.length >= 5, 'Need at least 5 cards');

    HandRank? best;
    for (final combo in _combinations(cards, 5)) {
      final rank = _evaluate5(combo, order);
      if (best == null || rank.compareTo(best) > 0) {
        best = rank;
      }
    }
    return best!;
  }

  /// Omaha: must use exactly 2 hole cards + 3 community cards.
  static HandRank bestOmaha({
    required List<Card> hole,
    required List<Card> community,
    List<HandCategory>? categoryOrder,
  }) {
    final order = categoryOrder ?? HandCategory.standardOrder;

    HandRank? best;
    for (final h2 in _combinations(hole, 2)) {
      for (final c3 in _combinations(community, 3)) {
        final rank = _evaluate5([...h2, ...c3], order);
        if (best == null || rank.compareTo(best) > 0) {
          best = rank;
        }
      }
    }
    return best!;
  }

  /// Evaluate a 5-card lo hand (8-or-better).
  /// Returns null if the hand doesn't qualify.
  /// Ace counts as 1 for lo. No pairs allowed. All cards must be ≤ 8.
  static HandRank? evaluateLo(List<Card> fiveCards) {
    assert(fiveCards.length == 5, 'Lo evaluation requires exactly 5 cards');

    // Convert to lo values (Ace = 1, others = face value)
    final values = fiveCards
        .map((c) => c.rank.value == 14 ? 1 : c.rank.value)
        .toList()
      ..sort();

    // Check for pairs (duplicates)
    for (var i = 0; i < values.length - 1; i++) {
      if (values[i] == values[i + 1]) return null;
    }

    // Check all ≤ 8
    if (values.last > 8) return null;

    // Lo hand: lower is better. We store kickers high-to-low so that
    // compareTo naturally gives "better lo" a higher value.
    // Actually, for lo: the hand with the lowest high card wins.
    // We want: A-2-3-4-5 > A-2-3-4-8 (wheel is best lo).
    // To make compareTo work where "better lo beats worse lo":
    // Invert the values so lower raw values produce higher kickers.
    // Max lo card is 8, so invert: kicker = 9 - value
    final kickers = values.reversed.map((v) => 9 - v).toList();

    return HandRank(
      category: HandCategory.highCard,
      kickers: kickers,
      strength: 1, // All lo hands are "high card" category
    );
  }

  /// Best lo hand from Omaha constraints (2 hole + 3 community).
  static HandRank? bestOmahaLo({
    required List<Card> hole,
    required List<Card> community,
  }) {
    HandRank? best;
    for (final h2 in _combinations(hole, 2)) {
      for (final c3 in _combinations(community, 3)) {
        final lo = evaluateLo([...h2, ...c3]);
        if (lo != null && (best == null || lo.compareTo(best) > 0)) {
          best = lo;
        }
      }
    }
    return best;
  }

  /// Evaluate exactly 5 cards and return the HandRank.
  static HandRank _evaluate5(
    List<Card> cards,
    List<HandCategory> categoryOrder,
  ) {
    assert(cards.length == 5);

    // Sort by rank value descending
    final sorted = List<Card>.of(cards)
      ..sort((a, b) => b.rank.value.compareTo(a.rank.value));

    final values = sorted.map((c) => c.rank.value).toList();

    // Check flush
    final isFlush = sorted.every((c) => c.suit == sorted.first.suit);

    // Check straight
    final straightResult = _checkStraight(values);
    final isStraight = straightResult != null;
    final straightHigh = straightResult ?? 0;

    // Group by rank: count desc, then value desc
    final groups = <int, int>{};
    for (final v in values) {
      groups[v] = (groups[v] ?? 0) + 1;
    }
    final groupEntries = groups.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        return cmp != 0 ? cmp : b.key.compareTo(a.key);
      });

    final counts = groupEntries.map((e) => e.value).toList();
    final groupValues = groupEntries.map((e) => e.key).toList();

    // Determine category and kickers
    HandCategory category;
    List<int> kickers;

    if (isFlush && isStraight && straightHigh == 14) {
      category = HandCategory.royalFlush;
      kickers = [14]; // Ace-high royal
    } else if (isFlush && isStraight) {
      category = HandCategory.straightFlush;
      kickers = [straightHigh];
    } else if (counts[0] == 4) {
      category = HandCategory.fourOfAKind;
      kickers = [groupValues[0], groupValues[1]];
    } else if (counts[0] == 3 && counts[1] == 2) {
      category = HandCategory.fullHouse;
      kickers = [groupValues[0], groupValues[1]];
    } else if (isFlush) {
      category = HandCategory.flush;
      kickers = values; // Already sorted descending
    } else if (isStraight) {
      category = HandCategory.straight;
      kickers = [straightHigh];
    } else if (counts[0] == 3) {
      category = HandCategory.threeOfAKind;
      kickers = [groupValues[0], groupValues[1], groupValues[2]];
    } else if (counts[0] == 2 && counts[1] == 2) {
      category = HandCategory.twoPair;
      // Two pairs sorted high to low, then kicker
      kickers = [groupValues[0], groupValues[1], groupValues[2]];
    } else if (counts[0] == 2) {
      category = HandCategory.onePair;
      kickers = groupValues; // pair value, then remaining sorted desc
    } else {
      category = HandCategory.highCard;
      kickers = values;
    }

    // Strength from category order position (higher index in order = weaker)
    final orderIndex = categoryOrder.indexOf(category);
    final strength = categoryOrder.length - orderIndex;

    return HandRank(
      category: category,
      kickers: kickers,
      strength: strength,
    );
  }

  /// Check if sorted descending values form a straight.
  /// Returns the high card of the straight, or null if not a straight.
  /// Handles wheel (A-2-3-4-5) and short deck wheel (A-6-7-8-9).
  static int? _checkStraight(List<int> values) {
    // Normal straight check: consecutive descending
    if (_isConsecutiveDesc(values)) {
      return values.first;
    }

    // Wheel: A plays low + 4 consecutive cards
    // Standard: A-2-3-4-5 (restSorted starts at 2)
    // Short Deck: A-6-7-8-9 (restSorted starts at 6)
    if (values.first == 14) {
      final restSorted = [values[1], values[2], values[3], values[4]]..sort();
      if (_isConsecutiveAsc(restSorted) &&
          (restSorted.first == 2 || restSorted.first == 6)) {
        return restSorted.last; // 5-high for standard wheel, 9-high for short deck
      }
    }

    return null;
  }

  static bool _isConsecutiveDesc(List<int> values) {
    for (var i = 0; i < values.length - 1; i++) {
      if (values[i] - values[i + 1] != 1) return false;
    }
    return true;
  }

  static bool _isConsecutiveAsc(List<int> values) {
    for (var i = 0; i < values.length - 1; i++) {
      if (values[i + 1] - values[i] != 1) return false;
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
