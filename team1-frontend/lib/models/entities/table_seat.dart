import 'package:freezed_annotation/freezed_annotation.dart';

part 'table_seat.freezed.dart';
part 'table_seat.g.dart';

@freezed
class TableSeat with _$TableSeat {
  const factory TableSeat({
    @JsonKey(name: 'seat_id') required int seatId,
    @JsonKey(name: 'table_id') required int tableId,
    @JsonKey(name: 'seat_no') required int seatNo,
    @JsonKey(name: 'player_id') int? playerId,
    @JsonKey(name: 'wsop_id') String? wsopId,
    @JsonKey(name: 'player_name') String? playerName,
    String? nationality,
    @JsonKey(name: 'country_code') String? countryCode,
    @JsonKey(name: 'chip_count') required int chipCount,
    @JsonKey(name: 'profile_image') String? profileImage,
    required String status,
    @JsonKey(name: 'player_move_status') String? playerMoveStatus,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _TableSeat;

  factory TableSeat.fromJson(Map<String, dynamic> json) =>
      _$TableSeatFromJson(json);
}
