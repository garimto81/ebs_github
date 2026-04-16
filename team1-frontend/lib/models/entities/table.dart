import 'package:freezed_annotation/freezed_annotation.dart';

part 'table.freezed.dart';
part 'table.g.dart';

@freezed
class EbsTable with _$EbsTable {
  const factory EbsTable({
    @JsonKey(name: 'table_id') required int tableId,
    @JsonKey(name: 'event_flight_id') required int eventFlightId,
    @JsonKey(name: 'table_no') required int tableNo,
    required String name,
    required String type,
    required String status,
    @JsonKey(name: 'max_players') required int maxPlayers,
    @JsonKey(name: 'game_type') required int gameType,
    @JsonKey(name: 'small_blind') int? smallBlind,
    @JsonKey(name: 'big_blind') int? bigBlind,
    @JsonKey(name: 'ante_type') required int anteType,
    @JsonKey(name: 'ante_amount') required int anteAmount,
    @JsonKey(name: 'rfid_reader_id') int? rfidReaderId,
    @JsonKey(name: 'deck_registered') required bool deckRegistered,
    @JsonKey(name: 'output_type') String? outputType,
    @JsonKey(name: 'current_game') int? currentGame,
    @JsonKey(name: 'delay_seconds') required int delaySeconds,
    int? ring,
    @JsonKey(name: 'is_breaking_table') required bool isBreakingTable,
    required String source,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    @JsonKey(name: 'seated_count') int? seatedCount,
  }) = _EbsTable;

  factory EbsTable.fromJson(Map<String, dynamic> json) =>
      _$EbsTableFromJson(json);
}
