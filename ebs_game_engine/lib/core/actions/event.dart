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
