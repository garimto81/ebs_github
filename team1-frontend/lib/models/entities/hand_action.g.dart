// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hand_action.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HandActionImpl _$$HandActionImplFromJson(Map<String, dynamic> json) =>
    _$HandActionImpl(
      id: (json['id'] as num).toInt(),
      handId: (json['handId'] as num).toInt(),
      seatNo: (json['seatNo'] as num).toInt(),
      actionType: json['actionType'] as String,
      actionAmount: (json['actionAmount'] as num).toInt(),
      potAfter: (json['potAfter'] as num?)?.toInt(),
      street: json['street'] as String,
      actionOrder: (json['actionOrder'] as num).toInt(),
      boardCards: json['boardCards'] as String?,
      actionTime: json['actionTime'] as String?,
    );

Map<String, dynamic> _$$HandActionImplToJson(_$HandActionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'handId': instance.handId,
      'seatNo': instance.seatNo,
      'actionType': instance.actionType,
      'actionAmount': instance.actionAmount,
      'potAfter': instance.potAfter,
      'street': instance.street,
      'actionOrder': instance.actionOrder,
      'boardCards': instance.boardCards,
      'actionTime': instance.actionTime,
    };
