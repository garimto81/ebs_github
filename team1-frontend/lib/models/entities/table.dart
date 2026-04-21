import 'package:freezed_annotation/freezed_annotation.dart';

part 'table.freezed.dart';
part 'table.g.dart';

@freezed
class EbsTable with _$EbsTable {
  const factory EbsTable({
    @JsonKey(name: 'tableId') required int tableId,
    @JsonKey(name: 'eventFlightId') required int eventFlightId,
    @JsonKey(name: 'tableNo') required int tableNo,
    required String name,
    required String type,
    required String status,
    @JsonKey(name: 'maxPlayers') required int maxPlayers,
    @JsonKey(name: 'gameType') required int gameType,
    @JsonKey(name: 'smallBlind') int? smallBlind,
    @JsonKey(name: 'bigBlind') int? bigBlind,
    @JsonKey(name: 'anteType') @Default(0) int anteType,
    @JsonKey(name: 'anteAmount') @Default(0) int anteAmount,
    @JsonKey(name: 'rfidReaderId') int? rfidReaderId,
    @JsonKey(name: 'deckRegistered') @Default(false) bool deckRegistered,
    @JsonKey(name: 'outputType') String? outputType,
    @JsonKey(name: 'currentGame') int? currentGame,
    @JsonKey(name: 'delaySeconds') @Default(0) int delaySeconds,
    int? ring,
    @JsonKey(name: 'isBreakingTable') @Default(false) bool isBreakingTable,
    required String source,
    @JsonKey(name: 'createdAt') required String createdAt,
    @JsonKey(name: 'updatedAt') required String updatedAt,
    @JsonKey(name: 'seatedCount') int? seatedCount,
  }) = _EbsTable;

  factory EbsTable.fromJson(Map<String, dynamic> json) =>
      _$EbsTableFromJson(json);
}
