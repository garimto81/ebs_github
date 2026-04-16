import 'package:freezed_annotation/freezed_annotation.dart';

part 'hand_player.freezed.dart';
part 'hand_player.g.dart';

@freezed
class HandPlayer with _$HandPlayer {
  const factory HandPlayer({
    required int id,
    @JsonKey(name: 'hand_id') required int handId,
    @JsonKey(name: 'seat_no') required int seatNo,
    @JsonKey(name: 'player_id') int? playerId,
    @JsonKey(name: 'player_name') required String playerName,
    @JsonKey(name: 'hole_cards') required String holeCards,
    @JsonKey(name: 'start_stack') required int startStack,
    @JsonKey(name: 'end_stack') required int endStack,
    @JsonKey(name: 'final_action') String? finalAction,
    @JsonKey(name: 'is_winner') required bool isWinner,
    required int pnl,
    @JsonKey(name: 'hand_rank') String? handRank,
    @JsonKey(name: 'win_probability') double? winProbability,
    required bool vpip,
    required bool pfr,
  }) = _HandPlayer;

  factory HandPlayer.fromJson(Map<String, dynamic> json) =>
      _$HandPlayerFromJson(json);
}
