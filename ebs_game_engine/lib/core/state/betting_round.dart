class BettingRound {
  int currentBet;
  int minRaise;
  int lastRaise;
  int lastAggressor;
  Set<int> actedThisRound;
  bool bbOptionPending;

  BettingRound({
    this.currentBet = 0,
    this.minRaise = 0,
    this.lastRaise = 0,
    this.lastAggressor = -1,
    Set<int>? actedThisRound,
    this.bbOptionPending = false,
  }) : actedThisRound = actedThisRound ?? {};

  BettingRound copy() => BettingRound(
    currentBet: currentBet,
    minRaise: minRaise,
    lastRaise: lastRaise,
    lastAggressor: lastAggressor,
    actedThisRound: Set.of(actedThisRound),
    bbOptionPending: bbOptionPending,
  );
}
