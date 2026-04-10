import '../cards/card.dart';
import 'action.dart';
import '../state/game_state.dart';

sealed class Event {
  const Event();
}

class HandStart extends Event {
  final int dealerSeat;
  final Map<int, int> blinds;
  const HandStart({required this.dealerSeat, required this.blinds});
}

class DealHoleCards extends Event {
  final Map<int, List<Card>> cards;
  const DealHoleCards(this.cards);
}

class DealCommunity extends Event {
  final List<Card> cards;
  const DealCommunity(this.cards);
}

class PineappleDiscard extends Event {
  final int seatIndex;
  final Card discarded;
  const PineappleDiscard(this.seatIndex, this.discarded);
}

class PlayerAction extends Event {
  final int seatIndex;
  final Action action;
  const PlayerAction(this.seatIndex, this.action);
}

class StreetAdvance extends Event {
  final Street next;
  const StreetAdvance(this.next);
}

class PotAwarded extends Event {
  final Map<int, int> awards;
  const PotAwarded(this.awards);
}

class HandEnd extends Event {
  const HandEnd();
}

class MisDeal extends Event {
  const MisDeal();
}

class BombPotConfig extends Event {
  final int amount;
  const BombPotConfig(this.amount);
}

class RunItChoice extends Event {
  final int times; // 2 or 3
  const RunItChoice(this.times);
}

class ManualNextHand extends Event {
  const ManualNextHand();
}

class TimeoutFold extends Event {
  final int seatIndex;
  const TimeoutFold(this.seatIndex);
}

class MuckDecision extends Event {
  final int seatIndex;
  final bool showCards; // true = show, false = muck
  const MuckDecision(this.seatIndex, {required this.showCards});
}
