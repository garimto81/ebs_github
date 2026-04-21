import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_flight.freezed.dart';
part 'event_flight.g.dart';

@freezed
class EventFlight with _$EventFlight {
  const factory EventFlight({
    @JsonKey(name: 'eventFlightId') required int eventFlightId,
    @JsonKey(name: 'eventId') required int eventId,
    @JsonKey(name: 'displayName') @Default('') String displayName,
    @JsonKey(name: 'startTime') String? startTime,
    @JsonKey(name: 'isTbd') @Default(false) bool isTbd,
    @Default(0) int entries,
    @JsonKey(name: 'playersLeft') @Default(0) int playersLeft,
    @JsonKey(name: 'tableCount') @Default(0) int tableCount,
    @Default('created') String status,
    @JsonKey(name: 'playLevel') @Default(1) int playLevel,
    @JsonKey(name: 'remainTime') int? remainTime,
    @Default('api') String source,
    @JsonKey(name: 'syncedAt') String? syncedAt,
    @JsonKey(name: 'createdAt') String? createdAt,
    @JsonKey(name: 'updatedAt') String? updatedAt,
    @JsonKey(name: 'playerCount') int? playerCount,
  }) = _EventFlight;

  factory EventFlight.fromJson(Map<String, dynamic> json) =>
      _$EventFlightFromJson(json);
}
