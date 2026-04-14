import '../cards/card.dart';

/// Bring-in determination for Stud variants.
///
/// On 3rd street, the player with the designated door card (lowest or highest
/// depending on variant) must post the bring-in forced bet.
class BringIn {
  BringIn._();

  /// Standard suit ranking for bring-in tiebreaker (lowest to highest):
  /// Clubs < Diamonds < Hearts < Spades.
  ///
  /// Maps [Suit] to its tiebreaker rank (0 = lowest, 3 = highest).
  static int _suitRank(Suit suit) => switch (suit) {
        Suit.club => 0,
        Suit.diamond => 1,
        Suit.heart => 2,
        Suit.spade => 3,
      };

  /// Determine which seat has the bring-in obligation on 3rd street.
  ///
  /// [upCards]: map of seatIndex to their first visible (door) card.
  /// [bringInLowest]: when `true`, the lowest door card brings in (Stud/Stud Hi-Lo).
  ///   When `false`, the highest door card brings in (Razz).
  ///
  /// Tiebreaker: suit ranking (Clubs < Diamonds < Hearts < Spades).
  /// For bringInLowest=true, the lowest suit wins the tie (posts bring-in).
  /// For bringInLowest=false, the highest suit wins the tie (posts bring-in).
  ///
  /// Returns the seat index of the player who must post the bring-in.
  static int determineBringIn(
    Map<int, Card> upCards, {
    bool bringInLowest = true,
  }) {
    assert(upCards.isNotEmpty, 'Need at least one up card');

    final entries = upCards.entries.toList()
      ..sort((a, b) {
        // Compare by rank value
        final rankCmp = bringInLowest
            ? a.value.rank.value.compareTo(b.value.rank.value)
            : b.value.rank.value.compareTo(a.value.rank.value);
        if (rankCmp != 0) return rankCmp;

        // Tiebreaker by suit rank
        return bringInLowest
            ? _suitRank(a.value.suit).compareTo(_suitRank(b.value.suit))
            : _suitRank(b.value.suit).compareTo(_suitRank(a.value.suit));
      });

    return entries.first.key;
  }

  /// Determine which seat acts first on 4th+ street based on visible cards.
  ///
  /// [visibleHands]: map of seatIndex to their list of visible (up) cards.
  /// The player showing the strongest visible hand acts first.
  ///
  /// For 2-4 visible cards, comparison uses:
  /// 1. Best group (four-of-a-kind > trips > pair > high card)
  /// 2. Rank of the best group
  /// 3. Highest remaining kicker
  ///
  /// Returns the seat index of the player who acts first.
  static int bestVisibleHand(Map<int, List<Card>> visibleHands) {
    assert(visibleHands.isNotEmpty, 'Need at least one visible hand');

    int? bestSeat;
    int bestScore = -1;

    for (final entry in visibleHands.entries) {
      if (entry.value.isEmpty) continue;

      final score = _scoreVisibleHand(entry.value);
      if (score > bestScore) {
        bestScore = score;
        bestSeat = entry.key;
      }
    }

    return bestSeat ?? visibleHands.keys.first;
  }

  /// Score a partial visible hand for comparison.
  ///
  /// Encoding: groupSize * 10000 + groupRank * 100 + highestCard
  /// This ensures pairs beat high cards, higher pairs beat lower pairs, etc.
  static int _scoreVisibleHand(List<Card> cards) {
    final sorted = List<Card>.of(cards)
      ..sort((a, b) => b.rank.value.compareTo(a.rank.value));

    // Count groups by rank
    final groups = <int, int>{};
    for (final c in sorted) {
      groups[c.rank.value] = (groups[c.rank.value] ?? 0) + 1;
    }

    // Find best group (highest count, then highest rank)
    int maxCount = 0;
    int maxCountRank = 0;
    for (final entry in groups.entries) {
      if (entry.value > maxCount ||
          (entry.value == maxCount && entry.key > maxCountRank)) {
        maxCount = entry.value;
        maxCountRank = entry.key;
      }
    }

    final highCard = sorted.first.rank.value;
    return maxCount * 10000 + maxCountRank * 100 + highCard;
  }
}
