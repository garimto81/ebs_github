import 'package:freezed_annotation/freezed_annotation.dart';

part 'ebs_event.freezed.dart';
part 'ebs_event.g.dart';

@freezed
class EbsEvent with _$EbsEvent {
  const factory EbsEvent({
    @JsonKey(name: 'event_id') required int eventId,
    @JsonKey(name: 'series_id') required int seriesId,
    @JsonKey(name: 'event_no') @Default(0) int eventNo,
    @JsonKey(name: 'event_name') required String eventName,
    @JsonKey(name: 'buy_in') int? buyIn,
    @JsonKey(name: 'display_buy_in') String? displayBuyIn,
    @JsonKey(name: 'game_type') @Default(0) int gameType,
    @JsonKey(name: 'bet_structure') @Default(0) int betStructure,
    @JsonKey(name: 'event_game_type') @Default(0) int eventGameType,
    @JsonKey(name: 'game_mode') @Default('single') String gameMode,
    @JsonKey(name: 'allowed_games') String? allowedGames,
    @JsonKey(name: 'rotation_order') String? rotationOrder,
    @JsonKey(name: 'rotation_trigger') String? rotationTrigger,
    @JsonKey(name: 'blind_structure_id') int? blindStructureId,
    @JsonKey(name: 'starting_chip') int? startingChip,
    @JsonKey(name: 'table_size') @Default(9) int tableSize,
    @JsonKey(name: 'total_entries') @Default(0) int totalEntries,
    @JsonKey(name: 'players_left') @Default(0) int playersLeft,
    @JsonKey(name: 'start_time') String? startTime,
    @Default('created') String status,
    @Default('api') String source,
    @JsonKey(name: 'synced_at') String? syncedAt,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _EbsEvent;

  factory EbsEvent.fromJson(Map<String, dynamic> json) =>
      _$EbsEventFromJson(json);
}
