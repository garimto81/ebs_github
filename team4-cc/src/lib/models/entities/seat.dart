// Seat entity — Freezed DTO for WebSocket/REST serialization.
// See BS-05-03 and DATA-04 §Seat.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'player.dart';

part 'seat.freezed.dart';
part 'seat.g.dart';

@freezed
class Seat with _$Seat {
  const factory Seat({
    required int seatNo,
    @Default('empty') String seatStatus, // WSOP LIVE 9-state FSM
    @Default('active') String activity, // active/folded/sittingOut/allIn
    Player? player,
    @Default(false) bool isDealer,
    @Default(false) bool isSB,
    @Default(false) bool isBB,
    @Default(false) bool actionOn,
  }) = _Seat;

  factory Seat.fromJson(Map<String, dynamic> json) => _$SeatFromJson(json);
}
