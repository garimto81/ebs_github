// PlayerStats entity — Freezed DTO for WebSocket/REST serialization.
// Real-time poker statistics per player (HUD data).

import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_stats.freezed.dart';
part 'player_stats.g.dart';

@freezed
class PlayerStats with _$PlayerStats {
  const factory PlayerStats({
    required int playerId,
    @Default(0) int handsPlayed,
    @Default(0.0) double vpip,
    @Default(0.0) double pfr,
    @Default(0.0) double threeBet,
    @Default(0.0) double aggressionFactor,
    @Default(0.0) double wtsd,
    @Default(0) int sessionHands,
    @Default(0) int totalHands,
  }) = _PlayerStats;

  factory PlayerStats.fromJson(Map<String, dynamic> json) =>
      _$PlayerStatsFromJson(json);
}
