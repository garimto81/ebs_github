// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ebs_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EbsEventImpl _$$EbsEventImplFromJson(Map<String, dynamic> json) =>
    _$EbsEventImpl(
      eventId: (json['eventId'] as num).toInt(),
      seriesId: (json['seriesId'] as num).toInt(),
      eventNo: (json['eventNo'] as num?)?.toInt() ?? 0,
      eventName: json['eventName'] as String,
      buyIn: (json['buyIn'] as num?)?.toInt(),
      displayBuyIn: json['displayBuyIn'] as String?,
      gameType: (json['gameType'] as num?)?.toInt() ?? 0,
      betStructure: (json['betStructure'] as num?)?.toInt() ?? 0,
      eventGameType: (json['eventGameType'] as num?)?.toInt() ?? 0,
      gameMode: json['gameMode'] as String? ?? 'single',
      allowedGames: json['allowedGames'] as String?,
      rotationOrder: json['rotationOrder'] as String?,
      rotationTrigger: json['rotationTrigger'] as String?,
      blindStructureId: (json['blindStructureId'] as num?)?.toInt(),
      startingChip: (json['startingChip'] as num?)?.toInt(),
      tableSize: (json['tableSize'] as num?)?.toInt() ?? 9,
      totalEntries: (json['totalEntries'] as num?)?.toInt() ?? 0,
      playersLeft: (json['playersLeft'] as num?)?.toInt() ?? 0,
      startTime: json['startTime'] as String?,
      status: json['status'] as String? ?? 'created',
      source: json['source'] as String? ?? 'api',
      syncedAt: json['syncedAt'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$$EbsEventImplToJson(_$EbsEventImpl instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'seriesId': instance.seriesId,
      'eventNo': instance.eventNo,
      'eventName': instance.eventName,
      'buyIn': instance.buyIn,
      'displayBuyIn': instance.displayBuyIn,
      'gameType': instance.gameType,
      'betStructure': instance.betStructure,
      'eventGameType': instance.eventGameType,
      'gameMode': instance.gameMode,
      'allowedGames': instance.allowedGames,
      'rotationOrder': instance.rotationOrder,
      'rotationTrigger': instance.rotationTrigger,
      'blindStructureId': instance.blindStructureId,
      'startingChip': instance.startingChip,
      'tableSize': instance.tableSize,
      'totalEntries': instance.totalEntries,
      'playersLeft': instance.playersLeft,
      'startTime': instance.startTime,
      'status': instance.status,
      'source': instance.source,
      'syncedAt': instance.syncedAt,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
