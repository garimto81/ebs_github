sealed class Action {
  const Action();
}

class Fold extends Action {
  const Fold();
}

class Check extends Action {
  const Check();
}

class Call extends Action {
  final int amount;
  const Call(this.amount);
}

class Bet extends Action {
  final int amount;
  const Bet(this.amount);
}

class Raise extends Action {
  final int toAmount;
  const Raise(this.toAmount);
}

class AllIn extends Action {
  final int amount;
  const AllIn(this.amount);
}
