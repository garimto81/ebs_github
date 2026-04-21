import 'package:freezed_annotation/freezed_annotation.dart';

part 'player.freezed.dart';
part 'player.g.dart';

@freezed
class Player with _$Player {
  const factory Player({
    @JsonKey(name: 'playerId') required int playerId,
    @JsonKey(name: 'wsopId') String? wsopId,
    @JsonKey(name: 'firstName') required String firstName,
    @JsonKey(name: 'lastName') required String lastName,
    String? nationality,
    @JsonKey(name: 'countryCode') String? countryCode,
    @JsonKey(name: 'profileImage') String? profileImage,
    @JsonKey(name: 'playerStatus') required String playerStatus,
    @JsonKey(name: 'isDemo') @Default(false) bool isDemo,
    required String source,
    @JsonKey(name: 'syncedAt') String? syncedAt,
    @JsonKey(name: 'createdAt') required String createdAt,
    @JsonKey(name: 'updatedAt') required String updatedAt,
    int? stack,
    @JsonKey(name: 'tableName') String? tableName,
    @JsonKey(name: 'seatIndex') int? seatIndex,
  }) = _Player;

  factory Player.fromJson(Map<String, dynamic> json) =>
      _$PlayerFromJson(json);
}
