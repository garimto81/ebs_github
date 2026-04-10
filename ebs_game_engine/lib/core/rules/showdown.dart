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
  /// - Ties: split evenly (integer division, odd chips to dealer-left).
  /// - Pots are evaluated in ascending eligible-set size order
  ///   (most restricted side pot first).
  static Map<int, int> evaluate({
    required List<Seat> seats,
    required List<Card> community,
    required List<SidePot> pots,
    required Variant variant,
    int? dealerSeat,
  }) {
    final awards = <int, int>{};

    // Sort pots by eligible set size (smallest first = most restricted first)
    final sortedPots = List<SidePot>.of(pots)
      ..sort((a, b) => a.eligible.length.compareTo(b.eligible.length));

    for (final pot in sortedPots) {
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
        _awardHiLo(awards, seats, community, eligible, pot.amount, variant,
            dealerSeat: dealerSeat, seatCount: seats.length);
      } else {
        _awardHi(awards, seats, community, eligible, pot.amount, variant,
            dealerSeat: dealerSeat, seatCount: seats.length);
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
    Variant variant, {
    int? dealerSeat,
    int? seatCount,
  }) {
    final winners = _findHiWinners(seats, community, eligible, variant);
    _splitPot(awards, winners, potAmount,
        dealerSeat: dealerSeat, seatCount: seatCount);
  }

  static void _awardHiLo(
    Map<int, int> awards,
    List<Seat> seats,
    List<Card> community,
    List<int> eligible,
    int potAmount,
    Variant variant, {
    int? dealerSeat,
    int? seatCount,
  }) {
    final hiWinners = _findHiWinners(seats, community, eligible, variant);
    final loWinners = _findLoWinners(seats, community, eligible, variant);

    if (loWinners.isEmpty) {
      // No qualifying lo — hi takes all
      _splitPot(awards, hiWinners, potAmount,
          dealerSeat: dealerSeat, seatCount: seatCount);
    } else {
      // WSOP Rule 73: odd chip goes to Hi side.
      final loHalf = potAmount ~/ 2;
      final hiHalf = potAmount - loHalf;
      _splitPot(awards, hiWinners, hiHalf,
          dealerSeat: dealerSeat, seatCount: seatCount);
      _splitPot(awards, loWinners, loHalf,
          dealerSeat: dealerSeat, seatCount: seatCount);
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

  /// Check if a seat holds offsuit 7-2 (seven and deuce of different suits).
  static bool isSevenDeuce(List<Card> holeCards) {
    if (holeCards.length != 2) return false;
    final ranks = {holeCards[0].rank, holeCards[1].rank};
    if (!ranks.contains(Rank.seven) || !ranks.contains(Rank.two)) return false;
    // Must be offsuit
    return holeCards[0].suit != holeCards[1].suit;
  }

  /// Calculate 7-2 side bet bonus. Returns {seatIndex: bonusAmount} or empty map.
  static Map<int, int> checkSevenDeuceBonus({
    required List<Seat> seats,
    required Map<int, int> awards,
    required int sevenDeuceAmount,
  }) {
    final bonus = <int, int>{};
    // Count non-folded opponents (per BS-06-05:259-262)
    final nonFoldedCount = seats.where((s) => !s.isFolded && s.holeCards.isNotEmpty).length;

    for (final entry in awards.entries) {
      final seat = seats[entry.key];
      if (entry.value > 0 && isSevenDeuce(seat.holeCards)) {
        // Winner with 7-2 offsuit: bonus = amount × non-folded opponents
        bonus[entry.key] = sevenDeuceAmount * (nonFoldedCount - 1);
      }
    }
    return bonus;
  }

  static void _splitPot(
    Map<int, int> awards,
    List<int> winners,
    int amount, {
    int? dealerSeat,
    int? seatCount,
  }) {
    if (winners.isEmpty) return;
    final share = amount ~/ winners.length;
    final remainder = amount % winners.length;

    // Award equal shares
    for (final idx in winners) {
      awards[idx] = (awards[idx] ?? 0) + share;
    }

    // Award odd chips to winner(s) closest to dealer's left
    if (remainder > 0 && dealerSeat != null && seatCount != null) {
      // Sort winners by distance from dealer (clockwise)
      final sorted = List<int>.of(winners)
        ..sort((a, b) {
          final distA = (a - dealerSeat - 1) % seatCount;
          final distB = (b - dealerSeat - 1) % seatCount;
          return distA.compareTo(distB);
        });
      for (var i = 0; i < remainder; i++) {
        awards[sorted[i]] = (awards[sorted[i]] ?? 0) + 1;
      }
    } else if (remainder > 0) {
      // Fallback: first N winners get extra (backward compat)
      for (var i = 0; i < remainder; i++) {
        awards[winners[i]] = (awards[winners[i]] ?? 0) + 1;
      }
    }
  }
}
