// Player entity — Freezed DTO for WebSocket/REST serialization.
// See DATA-04 §Player entity.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'card_model.dart';

part 'player.freezed.dart';
part 'player.g.dart';

@freezed
class Player with _$Player {
  const factory Player({
    required int id,
    required String name,
    @Default('') String countryCode,
    @Default(0) int stack,
    @Default('active') String status, // active/folded/sittingOut/allIn
    @Default(0) int currentBet,
    String? position, // btn/sb/bb/utg/...
    @Default([]) List<CardModel> holeCards,
    String? avatarUrl,
    String? vipLevel,
    int? wsopId,
  }) = _Player;

  factory Player.fromJson(Map<String, dynamic> json) =>
      _$PlayerFromJson(json);
}
