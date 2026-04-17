import 'package:freezed_annotation/freezed_annotation.dart';

part 'player.freezed.dart';
part 'player.g.dart';

@freezed
class Player with _$Player {
  const factory Player({
    @JsonKey(name: 'player_id') required int playerId,
    @JsonKey(name: 'wsop_id') String? wsopId,
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') required String lastName,
    String? nationality,
    @JsonKey(name: 'country_code') String? countryCode,
    @JsonKey(name: 'profile_image') String? profileImage,
    @JsonKey(name: 'player_status') required String playerStatus,
    @JsonKey(name: 'is_demo') @Default(false) bool isDemo,
    required String source,
    @JsonKey(name: 'synced_at') String? syncedAt,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    int? stack,
    @JsonKey(name: 'table_name') String? tableName,
    @JsonKey(name: 'seat_index') int? seatIndex,
  }) = _Player;

  factory Player.fromJson(Map<String, dynamic> json) =>
      _$PlayerFromJson(json);
}
