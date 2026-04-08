import '../cards/card.dart';
import '../cards/hand_evaluator.dart';
import '../state/seat.dart';
import '../state/pot.dart';
import '../variants/variant.dart';

/// Pure-function showdown evaluation.
class Showdown {
  Showdown._();

  /// Evaluate all pots and return a map of seatIndex → total amount won.
  ///
  /// For each pot:
  /// - If 1 eligible non-folded → award entire pot.
  /// - Evaluate hi hands for all eligible non-folded seats.
  /// - If variant.isHiLo: split 50/50 between hi and lo winners.
  ///   If no lo qualifier → hi takes all.
  /// - Ties: split evenly (integer division, remainder to first winner).
  static Map<int, int> evaluate({
    required List<Seat> seats,
    required List<Card> community,
    required List<SidePot> pots,
    required Variant variant,
  }) {
    final awards = <int, int>{};

    for (final pot in pots) {
      // Filter to eligible, non-folded seats
      final eligible = pot.eligible
          .where((i) => !seats[i].isFolded)
          .toList();

      if (eligible.isEmpty) continue;

      if (eligible.length == 1) {
        awards[eligible.first] = (awards[eligible.first] ?? 0) + pot.amount;
        continue;
      }

      if (variant.isHiLo) {
        _awardHiLo(awards, seats, community, eligible, pot.amount, variant);
      } else {
        _awardHi(awards, seats, community, eligible, pot.amount, variant);
      }
    }

    return awards;
  }

  static void _awardHi(
    Map<int, int> awards,
    List<Seat> seats,
    List<Card> community,
    List<int> eligible,
    int potAmount,
    Variant variant,
  ) {
    final winners = _findHiWinners(seats, community, eligible, variant);
    _splitPot(awards, winners, potAmount);
  }

  static void _awardHiLo(
    Map<int, int> awards,
    List<Seat> seats,
    List<Card> community,
    List<int> eligible,
    int potAmount,
    Variant variant,
  ) {
    final hiWinners = _findHiWinners(seats, community, eligible, variant);
    final loWinners = _findLoWinners(seats, community, eligible, variant);

    if (loWinners.isEmpty) {
      // No qualifying lo — hi takes all
      _splitPot(awards, hiWinners, potAmount);
    } else {
      final hiHalf = potAmount ~/ 2;
      final loHalf = potAmount - hiHalf;
      _splitPot(awards, hiWinners, hiHalf);
      _splitPot(awards, loWinners, loHalf);
    }
  }

  static List<int> _findHiWinners(
    List<Seat> seats,
    List<Card> community,
    List<int> eligible,
    Variant variant,
  ) {
    HandRank? bestRank;
    var winners = <int>[];

    for (final idx in eligible) {
      final hole = seats[idx].holeCards;
      final rank = variant.evaluateHi(hole, community);

      if (bestRank == null || rank.compareTo(bestRank) > 0) {
        bestRank = rank;
        winners = [idx];
      } else if (rank.compareTo(bestRank) == 0) {
        winners.add(idx);
      }
    }

    return winners;
  }

  static List<int> _findLoWinners(
    List<Seat> seats,
    List<Card> community,
    List<int> eligible,
    Variant variant,
  ) {
    HandRank? bestLo;
    var winners = <int>[];

    for (final idx in eligible) {
      final hole = seats[idx].holeCards;
      final lo = variant.evaluateLo(hole, community);
      if (lo == null) continue;

      if (bestLo == null || lo.compareTo(bestLo) > 0) {
        bestLo = lo;
        winners = [idx];
      } else if (lo.compareTo(bestLo) == 0) {
        winners.add(idx);
      }
    }

    return winners;
  }

  static void _splitPot(
    Map<int, int> awards,
    List<int> winners,
    int amount,
  ) {
    if (winners.isEmpty) return;
    final share = amount ~/ winners.length;
    final remainder = amount % winners.length;

    for (var i = 0; i < winners.length; i++) {
      final extra = i < remainder ? 1 : 0;
      final idx = winners[i];
      awards[idx] = (awards[idx] ?? 0) + share + extra;
    }
  }
}
