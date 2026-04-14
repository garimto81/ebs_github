// HandAction entity — Freezed DTO for WebSocket/REST serialization.
// Individual betting action within a hand.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'hand_action.freezed.dart';
part 'hand_action.g.dart';

@freezed
class HandAction with _$HandAction {
  const factory HandAction({
    required String actionType, // ActionType as string
    required int seatNo,
    @Default(0) int amount,
    @Default(0) int potAfter,
    required DateTime timestamp,
  }) = _HandAction;

  factory HandAction.fromJson(Map<String, dynamic> json) =>
      _$HandActionFromJson(json);
}
