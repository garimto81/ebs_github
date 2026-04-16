import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_flight.freezed.dart';
part 'event_flight.g.dart';

@freezed
class EventFlight with _$EventFlight {
  const factory EventFlight({
    @JsonKey(name: 'event_flight_id') required int eventFlightId,
    @JsonKey(name: 'event_id') required int eventId,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'start_time') String? startTime,
    @JsonKey(name: 'is_tbd') required bool isTbd,
    required int entries,
    @JsonKey(name: 'players_left') required int playersLeft,
    @JsonKey(name: 'table_count') required int tableCount,
    required String status,
    @JsonKey(name: 'play_level') required int playLevel,
    @JsonKey(name: 'remain_time') int? remainTime,
    required String source,
    @JsonKey(name: 'synced_at') String? syncedAt,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    @JsonKey(name: 'flight_id') required int flightId,
    @JsonKey(name: 'day_index') required int dayIndex,
    @JsonKey(name: 'flight_name') required String flightName,
    @JsonKey(name: 'player_count') int? playerCount,
  }) = _EventFlight;

  factory EventFlight.fromJson(Map<String, dynamic> json) =>
      _$EventFlightFromJson(json);
}
