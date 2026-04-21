import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_flight.freezed.dart';
part 'event_flight.g.dart';

@freezed
class EventFlight with _$EventFlight {
  const factory EventFlight({
    @JsonKey(name: 'event_flight_id') required int eventFlightId,
    @JsonKey(name: 'event_id') required int eventId,
    @JsonKey(name: 'display_name') @Default('') String displayName,
    @JsonKey(name: 'start_time') String? startTime,
    @JsonKey(name: 'is_tbd') @Default(false) bool isTbd,
    @Default(0) int entries,
    @JsonKey(name: 'players_left') @Default(0) int playersLeft,
    @JsonKey(name: 'table_count') @Default(0) int tableCount,
    @Default('created') String status,
    @JsonKey(name: 'play_level') @Default(1) int playLevel,
    @JsonKey(name: 'remain_time') int? remainTime,
    @Default('api') String source,
    @JsonKey(name: 'synced_at') String? syncedAt,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
    @JsonKey(name: 'player_count') int? playerCount,
  }) = _EventFlight;

  factory EventFlight.fromJson(Map<String, dynamic> json) =>
      _$EventFlightFromJson(json);
}
