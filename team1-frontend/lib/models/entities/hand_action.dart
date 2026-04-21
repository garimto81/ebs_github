import 'package:freezed_annotation/freezed_annotation.dart';

part 'hand_action.freezed.dart';
part 'hand_action.g.dart';

@freezed
class HandAction with _$HandAction {
  const factory HandAction({
    required int id,
    @JsonKey(name: 'handId') required int handId,
    @JsonKey(name: 'seatNo') required int seatNo,
    @JsonKey(name: 'actionType') required String actionType,
    @JsonKey(name: 'actionAmount') required int actionAmount,
    @JsonKey(name: 'potAfter') int? potAfter,
    required String street,
    @JsonKey(name: 'actionOrder') required int actionOrder,
    @JsonKey(name: 'boardCards') String? boardCards,
    @JsonKey(name: 'actionTime') String? actionTime,
  }) = _HandAction;

  factory HandAction.fromJson(Map<String, dynamic> json) =>
      _$HandActionFromJson(json);
}
