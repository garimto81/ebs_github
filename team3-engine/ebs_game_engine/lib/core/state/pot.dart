class SidePot {
  final int amount;
  final Set<int> eligible;
  const SidePot(this.amount, this.eligible);
}

class Pot {
  int main;
  List<SidePot> sides;

  Pot({this.main = 0, List<SidePot>? sides}) : sides = sides ?? [];

  int get total => main + sides.fold(0, (sum, s) => sum + s.amount);

  void addToMain(int amount) {
    main += amount;
  }

  static List<SidePot> calculateSidePots({
    required Map<int, int> bets,
    required Set<int> folded,
  }) {
    if (bets.isEmpty) return [];
    final levels = bets.values.toSet().toList()..sort();
    final pots = <SidePot>[];
    int prevLevel = 0;
    for (final level in levels) {
      final contributors = bets.entries
          .where((e) => e.value >= level)
          .map((e) => e.key)
          .toSet();
      final amount = (level - prevLevel) * contributors.length;
      if (amount > 0) {
        final eligible = contributors.difference(folded);
        pots.add(SidePot(amount, eligible));
      }
      prevLevel = level;
    }
    return pots;
  }

  Pot copy() => Pot(main: main, sides: List.of(sides));
}
