// Pot entity — Freezed DTO for WebSocket/REST serialization.
// Represents main pot or side pot with eligible seats.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'pot.freezed.dart';
part 'pot.g.dart';

@freezed
class Pot with _$Pot {
  const factory Pot({
    @Default(0) int amount,
    @Default([]) List<int> eligibleSeats,
  }) = _Pot;

  factory Pot.fromJson(Map<String, dynamic> json) => _$PotFromJson(json);
}
