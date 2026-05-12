import 'package:freezed_annotation/freezed_annotation.dart';

part 'hand_player.freezed.dart';
part 'hand_player.g.dart';

/// HandPlayer — per-seat record for a single Hand.
///
/// Cycle 7 (v03 game rules) extension:
///   - [runItTwiceShare] — Fraction of pot this player won when
///     Hand.runItTwiceCount > 1. null or 1.0 = full winner (default).
///     0.5 = won 1 of 2 boards. Only meaningful when isWinner = true.
@freezed
class HandPlayer with _$HandPlayer {
  const factory HandPlayer({
    required int id,
    @JsonKey(name: 'handId') required int handId,
    @JsonKey(name: 'seatNo') required int seatNo,
    @JsonKey(name: 'playerId') int? playerId,
    @JsonKey(name: 'playerName') required String playerName,
    @JsonKey(name: 'holeCards') required String holeCards,
    @JsonKey(name: 'startStack') required int startStack,
    @JsonKey(name: 'endStack') required int endStack,
    @JsonKey(name: 'finalAction') String? finalAction,
    @JsonKey(name: 'isWinner') required bool isWinner,
    required int pnl,
    @JsonKey(name: 'handRank') String? handRank,
    @JsonKey(name: 'winProbability') double? winProbability,
    required bool vpip,
    required bool pfr,
    // v03 game-rules fields (Cycle 7, #329)
    @JsonKey(name: 'runItTwiceShare') double? runItTwiceShare,
  }) = _HandPlayer;

  factory HandPlayer.fromJson(Map<String, dynamic> json) =>
      _$HandPlayerFromJson(json);
}
