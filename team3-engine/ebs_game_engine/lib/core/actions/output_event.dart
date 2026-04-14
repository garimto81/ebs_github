/// Output events emitted by the engine for UI/consumer notification.
sealed class OutputEvent {
  const OutputEvent();
}

/// OE-01: Game state changed (street advance, hand start/end).
class StateChanged extends OutputEvent {
  final String fromState;
  final String toState;
  const StateChanged({required this.fromState, required this.toState});
}

/// OE-02: A player action was processed.
class ActionProcessed extends OutputEvent {
  final int seatIndex;
  final String actionType;
  final int? amount;
  const ActionProcessed(
      {required this.seatIndex, required this.actionType, this.amount});
}

/// OE-03 / OE-19: Pot amount updated.
/// [displayToPlayers]: WSOP Rule 101 — false in Spread Limit to hide pot size.
class PotUpdated extends OutputEvent {
  final int mainPot;
  final List<int> sidePots;
  final bool displayToPlayers;
  const PotUpdated(
      {required this.mainPot,
      required this.sidePots,
      this.displayToPlayers = true});
}

/// OE-04: Community board cards changed.
class BoardUpdated extends OutputEvent {
  final int cardCount;
  const BoardUpdated({required this.cardCount});
}

/// OE-05: Action moved to a different seat.
class ActionOnChanged extends OutputEvent {
  final int seatIndex;
  const ActionOnChanged({required this.seatIndex});
}

/// OE-06: Winner(s) determined for a pot.
class WinnerDetermined extends OutputEvent {
  final Map<int, int> awards; // seatIndex -> amount won
  const WinnerDetermined({required this.awards});
}

/// OE-07: An event was rejected (invalid action, wrong state, etc.).
class Rejected extends OutputEvent {
  final String reason;
  const Rejected({required this.reason});
}

/// OE-08: Undo was applied.
class UndoApplied extends OutputEvent {
  final int stepsUndone;
  const UndoApplied({required this.stepsUndone});
}

/// OE-09: Hand completed (all actions done, pot awarded).
class HandCompleted extends OutputEvent {
  final int handNumber;
  const HandCompleted({required this.handNumber});
}

/// OE-10: Equity/win percentage updated.
class EquityUpdated extends OutputEvent {
  final Map<int, double> equities; // seatIndex -> win probability (0.0-1.0)
  const EquityUpdated({required this.equities});
}

/// Card revealed to specific audiences.
class CardRevealed extends OutputEvent {
  final int seatIndex;
  final List<String> cardCodes; // e.g., ['As', 'Kh']
  final String visibility; // 'all', 'broadcast', 'none'
  const CardRevealed(
      {required this.seatIndex,
      required this.cardCodes,
      required this.visibility});
}

/// Card mismatch detected.
class CardMismatchDetected extends OutputEvent {
  final String expected;
  final String detected;
  const CardMismatchDetected({required this.expected, required this.detected});
}

/// 7-2 side bet bonus awarded.
class SevenDeuceBonusAwarded extends OutputEvent {
  final int seatIndex;
  final int bonusAmount;
  const SevenDeuceBonusAwarded(
      {required this.seatIndex, required this.bonusAmount});
}

/// OE-11: Player voluntarily tabled (showed) their hand (WSOP Rule 71).
class HandTabled extends OutputEvent {
  final int seatIndex;
  final List<String> cards;
  const HandTabled({required this.seatIndex, required this.cards});
}

/// OE-12: Folded hand retrieved by manager ruling (WSOP Rule 110).
class HandRetrieved extends OutputEvent {
  final int seatIndex;
  final String managerRationale;
  const HandRetrieved(
      {required this.seatIndex, required this.managerRationale});
}

/// OE-13: Hand killed by manager ruling (WSOP Rule 71 exception).
class HandKilled extends OutputEvent {
  final int seatIndex;
  final String managerRationale;
  const HandKilled({required this.seatIndex, required this.managerRationale});
}

/// OE-14: Mucked cards retrieved for re-evaluation (WSOP Rule 109).
class MuckRetrieved extends OutputEvent {
  final int seatIndex;
  final List<String> cards;
  final String rationale;
  const MuckRetrieved(
      {required this.seatIndex, required this.cards, required this.rationale});
}

/// OE-15: Four-card flop recovered (WSOP Rule 89).
class FlopRecovered extends OutputEvent {
  final List<String> originalCards;
  final List<String> newFlop;
  final String? reservedBurn;
  const FlopRecovered(
      {required this.originalCards,
      required this.newFlop,
      this.reservedBurn});
}

/// OE-16: RFID deck integrity warning (WSOP Rule 78).
class DeckIntegrityWarning extends OutputEvent {
  final int failureCount;
  final String suggestedAction;
  const DeckIntegrityWarning(
      {required this.failureCount, required this.suggestedAction});
}

/// OE-17: Deck change procedure started (WSOP Rule 78).
class DeckChangeStarted extends OutputEvent {
  final String reason;
  final String requestedBy;
  const DeckChangeStarted(
      {required this.reason, required this.requestedBy});
}

/// OE-18: Mixed game transition (e.g., HORSE rotation).
class GameTransitioned extends OutputEvent {
  final String fromGame;
  final String toGame;
  final bool buttonFrozen;
  const GameTransitioned(
      {required this.fromGame,
      required this.toGame,
      this.buttonFrozen = false});
}
