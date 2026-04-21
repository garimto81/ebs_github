import 'package:freezed_annotation/freezed_annotation.dart';

part 'table_seat.freezed.dart';
part 'table_seat.g.dart';

@freezed
class TableSeat with _$TableSeat {
  const factory TableSeat({
    @JsonKey(name: 'seatId') required int seatId,
    @JsonKey(name: 'tableId') required int tableId,
    @JsonKey(name: 'seatNo') required int seatNo,
    @JsonKey(name: 'playerId') int? playerId,
    @JsonKey(name: 'wsopId') String? wsopId,
    @JsonKey(name: 'playerName') String? playerName,
    String? nationality,
    @JsonKey(name: 'countryCode') String? countryCode,
    @JsonKey(name: 'chipCount') required int chipCount,
    @JsonKey(name: 'profileImage') String? profileImage,
    required String status,
    @JsonKey(name: 'playerMoveStatus') String? playerMoveStatus,
    @JsonKey(name: 'createdAt') required String createdAt,
    @JsonKey(name: 'updatedAt') required String updatedAt,
  }) = _TableSeat;

  factory TableSeat.fromJson(Map<String, dynamic> json) =>
      _$TableSeatFromJson(json);
}
