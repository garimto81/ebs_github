/// Output events emitted by the engine for UI/consumer notification.
///
/// **OE 번호 권위**: API-04 §6.0 OutputEvent 카탈로그 (실측 21종).
/// 외부 SSOT: `docs/2. Development/2.3 Game Engine/APIs/Overlay_Output_Events.md`.
/// 행동 명세 view: `docs/2. Development/2.3 Game Engine/Behavioral_Specs/Triggers_and_Event_Pipeline.md` §3.4 + §3.4.1.
///
/// 2026-04-28 (B-351 + B-352): 주석의 OE 번호를 BS-06-09 옛 번호 → API-04 권위로 재정렬.
/// (구 BS-06-09 OE-11~18 = API-04 OE-14~21, 3칸 shift)
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

/// OE-03: Pot amount updated.
///
/// [displayToPlayers]: WSOP Rule 101 — false in Spread Limit to hide pot size.
/// 본 필드는 API-04 §6.0 의 OE-03 payload 확장 (BS-06-09 의 별도 OE-19 view 와 동치).
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

/// OE-11: Card revealed to specific audiences (hole / board).
///
/// [visibility]: 'all' (Broadcast + Venue), 'broadcast' (Broadcast only), 'none' (hidden).
/// 트리거: BS-06-12 §2 (SeatHoleCardCalled / Triggers 도메인 §3.5 T2 — turn-based hole release)
///        + §3 (FlopRevealed/TurnRevealed/RiverRevealed / T6/T7/T8 — atomic flop).
class CardRevealed extends OutputEvent {
  final int seatIndex;
  final List<String> cardCodes; // e.g., ['As', 'Kh']
  final String visibility; // 'all', 'broadcast', 'none'
  const CardRevealed(
      {required this.seatIndex,
      required this.cardCodes,
      required this.visibility});
}

/// OE-12: Card mismatch detected (RFID detection ≠ expected).
///
/// 트리거: Triggers 도메인 §3.16.2 (CC + RFID 다른 카드 — `CARD_CONFLICT`)
///        + Variants & Evaluation 도메인 §3.17 매트릭스 7 (Venue/Broadcast 분기).
class CardMismatchDetected extends OutputEvent {
  final String expected;
  final String detected;
  const CardMismatchDetected({required this.expected, required this.detected});
}

/// OE-13: 7-2 side bet bonus awarded (winner held 7-2 offsuit).
///
/// 권위: Variants & Evaluation 도메인 §3.9 (7-2 Side Bet 매트릭스)
///      + Betting & Pots 도메인 §5.12 (Showdown.checkSevenDeuceBonus()).
class SevenDeuceBonusAwarded extends OutputEvent {
  final int seatIndex;
  final int bonusAmount;
  const SevenDeuceBonusAwarded(
      {required this.seatIndex, required this.bonusAmount});
}

/// OE-14: Player voluntarily tabled (showed) their hand (WSOP Rule 71).
///
/// (구 BS-06-09 OE-11. 2026-04-28 API-04 권위로 재번호 — B-351.)
class HandTabled extends OutputEvent {
  final int seatIndex;
  final List<String> cards;
  const HandTabled({required this.seatIndex, required this.cards});
}

/// OE-15: Folded hand retrieved by manager ruling (WSOP Rule 110).
///
/// (구 BS-06-09 OE-12.)
class HandRetrieved extends OutputEvent {
  final int seatIndex;
  final String managerRationale;
  const HandRetrieved(
      {required this.seatIndex, required this.managerRationale});
}

/// OE-16: Hand killed by manager ruling (WSOP Rule 71 exception).
///
/// (구 BS-06-09 OE-13.)
class HandKilled extends OutputEvent {
  final int seatIndex;
  final String managerRationale;
  const HandKilled({required this.seatIndex, required this.managerRationale});
}

/// OE-17: Mucked cards retrieved for re-evaluation (WSOP Rule 109).
///
/// (구 BS-06-09 OE-14.)
class MuckRetrieved extends OutputEvent {
  final int seatIndex;
  final List<String> cards;
  final String rationale;
  const MuckRetrieved(
      {required this.seatIndex, required this.cards, required this.rationale});
}

/// OE-18: Four-card flop recovered (WSOP Rule 89).
///
/// (구 BS-06-09 OE-15.)
class FlopRecovered extends OutputEvent {
  final List<String> originalCards;
  final List<String> newFlop;
  final String? reservedBurn;
  const FlopRecovered(
      {required this.originalCards,
      required this.newFlop,
      this.reservedBurn});
}

/// OE-19: RFID deck integrity warning (WSOP Rule 78).
///
/// (구 BS-06-09 OE-16. API-04 권위 번호.)
class DeckIntegrityWarning extends OutputEvent {
  final int failureCount;
  final String suggestedAction;
  const DeckIntegrityWarning(
      {required this.failureCount, required this.suggestedAction});
}

/// OE-20: Deck change procedure started (WSOP Rule 78).
///
/// (구 BS-06-09 OE-17.)
class DeckChangeStarted extends OutputEvent {
  final String reason;
  final String requestedBy;
  const DeckChangeStarted(
      {required this.reason, required this.requestedBy});
}

/// OE-21: Mixed game transition (e.g., HORSE rotation).
///
/// (구 BS-06-09 OE-18.)
class GameTransitioned extends OutputEvent {
  final String fromGame;
  final String toGame;
  final bool buttonFrozen;
  const GameTransitioned(
      {required this.fromGame,
      required this.toGame,
      this.buttonFrozen = false});
}
