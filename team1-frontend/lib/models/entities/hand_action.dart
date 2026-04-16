import 'package:freezed_annotation/freezed_annotation.dart';

part 'hand_action.freezed.dart';
part 'hand_action.g.dart';

@freezed
class HandAction with _$HandAction {
  const factory HandAction({
    required int id,
    @JsonKey(name: 'hand_id') required int handId,
    @JsonKey(name: 'seat_no') required int seatNo,
    @JsonKey(name: 'action_type') required String actionType,
    @JsonKey(name: 'action_amount') required int actionAmount,
    @JsonKey(name: 'pot_after') int? potAfter,
    required String street,
    @JsonKey(name: 'action_order') required int actionOrder,
    @JsonKey(name: 'board_cards') String? boardCards,
    @JsonKey(name: 'action_time') String? actionTime,
  }) = _HandAction;

  factory HandAction.fromJson(Map<String, dynamic> json) =>
      _$HandActionFromJson(json);
}
