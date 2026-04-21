// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hand.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HandImpl _$$HandImplFromJson(Map<String, dynamic> json) => _$HandImpl(
      handId: (json['handId'] as num).toInt(),
      tableId: (json['tableId'] as num).toInt(),
      handNumber: (json['handNumber'] as num).toInt(),
      gameType: (json['gameType'] as num).toInt(),
      betStructure: (json['betStructure'] as num).toInt(),
      dealerSeat: (json['dealerSeat'] as num).toInt(),
      boardCards: json['boardCards'] as String,
      potTotal: (json['potTotal'] as num).toInt(),
      sidePots: json['sidePots'] as String,
      currentStreet: json['currentStreet'] as String?,
      startedAt: json['startedAt'] as String,
      endedAt: json['endedAt'] as String?,
      durationSec: (json['durationSec'] as num).toInt(),
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$$HandImplToJson(_$HandImpl instance) =>
    <String, dynamic>{
      'handId': instance.handId,
      'tableId': instance.tableId,
      'handNumber': instance.handNumber,
      'gameType': instance.gameType,
      'betStructure': instance.betStructure,
      'dealerSeat': instance.dealerSeat,
      'boardCards': instance.boardCards,
      'potTotal': instance.potTotal,
      'sidePots': instance.sidePots,
      'currentStreet': instance.currentStreet,
      'startedAt': instance.startedAt,
      'endedAt': instance.endedAt,
      'durationSec': instance.durationSec,
      'createdAt': instance.createdAt,
    };
