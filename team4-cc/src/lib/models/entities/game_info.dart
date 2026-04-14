// WriteGameInfo payload (24 fields) from CCR-024.
// See API-05 §9 WriteGameInfo protocol.
//
// Full schema dispatched from CC when NEW HAND button is clicked.
// Server validates against checklist in API-05 §9 and responds with either
// GameInfoAck { hand_id, ready_for_deal } or GameInfoRejected { error_code }.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_info.freezed.dart';
part 'game_info.g.dart';

@freezed
class GameInfo with _$GameInfo {
  const factory GameInfo({
    required int tableId,
    required int handId,
    required int dealerSeat,
    required int sbSeat,
    required int bbSeat,
    required int sbAmount,
    required int bbAmount,
    @Default(0) int anteAmount,
    @Default(false) bool bigBlindAnte,
    @Default([]) List<int> straddleSeats,
    int? straddleAmount,
    required String blindStructureId,
    required int blindLevel,
    required DateTime currentLevelStartTs,
    required DateTime nextLevelStartTs,
    required String gameType,
    @Default([]) List<String> allowedGames,
    List<String>? rotationOrder,
    @Default([]) List<int> chipDenominations,
    @Default([]) List<int> activeSeats,
    @Default(false) bool deadButtonMode,
    @Default(false) bool runItMultipleAllowed,
    @Default(false) bool bombPotEnabled,
    int? capBbMultiplier,
  }) = _GameInfo;

  factory GameInfo.fromJson(Map<String, dynamic> json) =>
      _$GameInfoFromJson(json);
}
