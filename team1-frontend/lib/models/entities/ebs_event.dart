import 'package:freezed_annotation/freezed_annotation.dart';

part 'ebs_event.freezed.dart';
part 'ebs_event.g.dart';

@freezed
class EbsEvent with _$EbsEvent {
  const factory EbsEvent({
    @JsonKey(name: 'eventId') required int eventId,
    @JsonKey(name: 'seriesId') required int seriesId,
    @JsonKey(name: 'eventNo') @Default(0) int eventNo,
    @JsonKey(name: 'eventName') required String eventName,
    @JsonKey(name: 'buyIn') int? buyIn,
    @JsonKey(name: 'displayBuyIn') String? displayBuyIn,
    @JsonKey(name: 'gameType') @Default(0) int gameType,
    @JsonKey(name: 'betStructure') @Default(0) int betStructure,
    @JsonKey(name: 'eventGameType') @Default(0) int eventGameType,
    @JsonKey(name: 'gameMode') @Default('single') String gameMode,
    @JsonKey(name: 'allowedGames') String? allowedGames,
    @JsonKey(name: 'rotationOrder') String? rotationOrder,
    @JsonKey(name: 'rotationTrigger') String? rotationTrigger,
    @JsonKey(name: 'blindStructureId') int? blindStructureId,
    @JsonKey(name: 'startingChip') int? startingChip,
    @JsonKey(name: 'tableSize') @Default(9) int tableSize,
    @JsonKey(name: 'totalEntries') @Default(0) int totalEntries,
    @JsonKey(name: 'playersLeft') @Default(0) int playersLeft,
    @JsonKey(name: 'startTime') String? startTime,
    @Default('created') String status,
    @Default('api') String source,
    @JsonKey(name: 'syncedAt') String? syncedAt,
    @JsonKey(name: 'createdAt') String? createdAt,
    @JsonKey(name: 'updatedAt') String? updatedAt,
  }) = _EbsEvent;

  factory EbsEvent.fromJson(Map<String, dynamic> json) =>
      _$EbsEventFromJson(json);
}
