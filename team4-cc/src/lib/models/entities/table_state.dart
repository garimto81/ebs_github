// TableState entity — Freezed DTO for WebSocket/REST serialization.
// Aggregate root for a single table's real-time state.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'game_info.dart';
import 'hand.dart';
import 'seat.dart';

part 'table_state.freezed.dart';
part 'table_state.g.dart';

@freezed
class TableState with _$TableState {
  const factory TableState({
    required int tableId,
    required String tableName,
    @Default('empty') String status, // TableFsm state name
    @Default([]) List<Seat> seats,
    Hand? currentHand,
    GameInfo? gameInfo,
    @Default(0) int handCount,
  }) = _TableState;

  factory TableState.fromJson(Map<String, dynamic> json) =>
      _$TableStateFromJson(json);
}
