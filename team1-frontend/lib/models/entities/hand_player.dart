import 'package:freezed_annotation/freezed_annotation.dart';

part 'hand_player.freezed.dart';
part 'hand_player.g.dart';

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
  }) = _HandPlayer;

  factory HandPlayer.fromJson(Map<String, dynamic> json) =>
      _$HandPlayerFromJson(json);
}
