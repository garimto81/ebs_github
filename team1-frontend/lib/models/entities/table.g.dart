// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EbsTableImpl _$$EbsTableImplFromJson(Map<String, dynamic> json) =>
    _$EbsTableImpl(
      tableId: (json['tableId'] as num).toInt(),
      eventFlightId: (json['eventFlightId'] as num).toInt(),
      tableNo: (json['tableNo'] as num).toInt(),
      name: json['name'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      maxPlayers: (json['maxPlayers'] as num).toInt(),
      gameType: (json['gameType'] as num).toInt(),
      smallBlind: (json['smallBlind'] as num?)?.toInt(),
      bigBlind: (json['bigBlind'] as num?)?.toInt(),
      anteType: (json['anteType'] as num?)?.toInt() ?? 0,
      anteAmount: (json['anteAmount'] as num?)?.toInt() ?? 0,
      rfidReaderId: (json['rfidReaderId'] as num?)?.toInt(),
      deckRegistered: json['deckRegistered'] as bool? ?? false,
      outputType: json['outputType'] as String?,
      currentGame: (json['currentGame'] as num?)?.toInt(),
      delaySeconds: (json['delaySeconds'] as num?)?.toInt() ?? 0,
      ring: (json['ring'] as num?)?.toInt(),
      isBreakingTable: json['isBreakingTable'] as bool? ?? false,
      source: json['source'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      seatedCount: (json['seatedCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$EbsTableImplToJson(_$EbsTableImpl instance) =>
    <String, dynamic>{
      'tableId': instance.tableId,
      'eventFlightId': instance.eventFlightId,
      'tableNo': instance.tableNo,
      'name': instance.name,
      'type': instance.type,
      'status': instance.status,
      'maxPlayers': instance.maxPlayers,
      'gameType': instance.gameType,
      if (instance.smallBlind case final value?) 'smallBlind': value,
      if (instance.bigBlind case final value?) 'bigBlind': value,
      'anteType': instance.anteType,
      'anteAmount': instance.anteAmount,
      if (instance.rfidReaderId case final value?) 'rfidReaderId': value,
      'deckRegistered': instance.deckRegistered,
      if (instance.outputType case final value?) 'outputType': value,
      if (instance.currentGame case final value?) 'currentGame': value,
      'delaySeconds': instance.delaySeconds,
      if (instance.ring case final value?) 'ring': value,
      'isBreakingTable': instance.isBreakingTable,
      'source': instance.source,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      if (instance.seatedCount case final value?) 'seatedCount': value,
    };
