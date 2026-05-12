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
      if (instance.potAfter case final value?) 'potAfter': value,
      'street': instance.street,
      'actionOrder': instance.actionOrder,
      if (instance.boardCards case final value?) 'boardCards': value,
      if (instance.actionTime case final value?) 'actionTime': value,
    };
