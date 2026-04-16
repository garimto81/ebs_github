// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hand_action.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HandActionImpl _$$HandActionImplFromJson(Map<String, dynamic> json) =>
    _$HandActionImpl(
      id: (json['id'] as num).toInt(),
      handId: (json['hand_id'] as num).toInt(),
      seatNo: (json['seat_no'] as num).toInt(),
      actionType: json['action_type'] as String,
      actionAmount: (json['action_amount'] as num).toInt(),
      potAfter: (json['pot_after'] as num?)?.toInt(),
      street: json['street'] as String,
      actionOrder: (json['action_order'] as num).toInt(),
      boardCards: json['board_cards'] as String?,
      actionTime: json['action_time'] as String?,
    );

Map<String, dynamic> _$$HandActionImplToJson(_$HandActionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'hand_id': instance.handId,
      'seat_no': instance.seatNo,
      'action_type': instance.actionType,
      'action_amount': instance.actionAmount,
      'pot_after': instance.potAfter,
      'street': instance.street,
      'action_order': instance.actionOrder,
      'board_cards': instance.boardCards,
      'action_time': instance.actionTime,
    };
