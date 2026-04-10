import 'dart:math';
import '../cards/card.dart';
import '../cards/hand_evaluator.dart';

/// Monte Carlo equity calculator for Hold'em.
class EquityCalculator {
  EquityCalculator._();

  /// Calculate equity for each player given current hole cards and board.
  /// Returns map of playerIndex → equity (0.0 to 1.0).
  ///
  /// [hands] maps player index to their 2 hole cards.
  /// [board] is the current community cards (0-5 cards).
  /// [iterations] is the number of Monte Carlo simulations.
  static Map<int, double> calculate({
    required Map<int, List<Card>> hands,
    List<Card> board = const [],
    int iterations = 10000,
    int? seed,
  }) {
    if (hands.isEmpty) return {};

    final playerIndices = hands.keys.toList();
    final wins = <int, double>{};
    for (final idx in playerIndices) {
      wins[idx] = 0.0;
    }

    // Cards already in play (hole cards + board)
    final usedCards = <Card>{};
    for (final cards in hands.values) {
      usedCards.addAll(cards);
    }
    usedCards.addAll(board);

    // Remaining deck
    final remainingCards = [
      for (final suit in Suit.values)
        for (final rank in Rank.values)
          if (!usedCards.contains(Card(suit, rank))) Card(suit, rank),
    ];

    final cardsNeeded = 5 - board.length;
    final rng = Random(seed);

    if (cardsNeeded == 0) {
      // River: exact evaluation, no simulation needed
      HandRank? bestRank;
      var bestPlayers = <int>[];

      for (final idx in playerIndices) {
        final allCards = [...hands[idx]!, ...board];
        final rank = HandEvaluator.bestHand(allCards);

        if (bestRank == null || rank.compareTo(bestRank) > 0) {
          bestRank = rank;
          bestPlayers = [idx];
        } else if (rank.compareTo(bestRank) == 0) {
          bestPlayers.add(idx);
        }
      }

      final equity = <int, double>{};
      final share = 1.0 / bestPlayers.length;
      for (final idx in playerIndices) {
        equity[idx] = bestPlayers.contains(idx) ? share : 0.0;
      }
      return equity;
    }

    for (var i = 0; i < iterations; i++) {
      // Shuffle remaining and pick cards needed for board
      final shuffled = List<Card>.of(remainingCards)..shuffle(rng);
      final simBoard = [...board, ...shuffled.sublist(0, cardsNeeded)];

      // Evaluate each player's best hand
      HandRank? bestRank;
      var bestPlayers = <int>[];

      for (final idx in playerIndices) {
        final allCards = [...hands[idx]!, ...simBoard];
        final rank = HandEvaluator.bestHand(allCards);

        if (bestRank == null || rank.compareTo(bestRank) > 0) {
          bestRank = rank;
          bestPlayers = [idx];
        } else if (rank.compareTo(bestRank) == 0) {
          bestPlayers.add(idx);
        }
      }

      // Award fractional wins for ties
      final share = 1.0 / bestPlayers.length;
      for (final idx in bestPlayers) {
        wins[idx] = wins[idx]! + share;
      }
    }

    // Convert to equity (0.0 to 1.0)
    final equity = <int, double>{};
    for (final idx in playerIndices) {
      equity[idx] = wins[idx]! / iterations;
    }
    return equity;
  }
}
