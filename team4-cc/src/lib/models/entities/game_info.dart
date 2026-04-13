// WriteGameInfo payload (24 fields) from CCR-024.
// See API-05 §9 WriteGameInfo 프로토콜.
//
// This is the full schema dispatched from CC when NEW HAND button is clicked.
// Server validates against checklist in API-05 §9 and responds with either
// GameInfoAck { hand_id, ready_for_deal } or GameInfoRejected { error_code }.

class GameInfo {
  const GameInfo({
    required this.tableId,
    required this.handId,
    required this.dealerSeat,
    required this.sbSeat,
    required this.bbSeat,
    required this.sbAmount,
    required this.bbAmount,
    required this.anteAmount,
    required this.bigBlindAnte,
    required this.straddleSeats,
    this.straddleAmount,
    required this.blindStructureId,
    required this.blindLevel,
    required this.currentLevelStartTs,
    required this.nextLevelStartTs,
    required this.gameType,
    required this.allowedGames,
    this.rotationOrder,
    required this.chipDenominations,
    required this.activeSeats,
    required this.deadButtonMode,
    required this.runItMultipleAllowed,
    required this.bombPotEnabled,
    this.capBbMultiplier,
  });

  final int tableId;
  final int handId;
  final int dealerSeat;
  final int sbSeat;
  final int bbSeat;
  final int sbAmount;
  final int bbAmount;
  final int anteAmount;
  final bool bigBlindAnte;
  final List<int> straddleSeats;
  final int? straddleAmount;
  final String blindStructureId;
  final int blindLevel;
  final DateTime currentLevelStartTs;
  final DateTime nextLevelStartTs;
  final String gameType;
  final List<String> allowedGames;
  final List<String>? rotationOrder;
  final List<int> chipDenominations;
  final List<int> activeSeats;
  final bool deadButtonMode;
  final bool runItMultipleAllowed;
  final bool bombPotEnabled;
  final int? capBbMultiplier;

  // TODO(CCR-024): add Freezed + json_serializable for wire format
}
