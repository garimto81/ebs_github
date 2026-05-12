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
      if (instance.buyIn case final value?) 'buyIn': value,
      if (instance.displayBuyIn case final value?) 'displayBuyIn': value,
      'gameType': instance.gameType,
      'betStructure': instance.betStructure,
      'eventGameType': instance.eventGameType,
      'gameMode': instance.gameMode,
      if (instance.allowedGames case final value?) 'allowedGames': value,
      if (instance.rotationOrder case final value?) 'rotationOrder': value,
      if (instance.rotationTrigger case final value?) 'rotationTrigger': value,
      if (instance.blindStructureId case final value?)
        'blindStructureId': value,
      if (instance.startingChip case final value?) 'startingChip': value,
      'tableSize': instance.tableSize,
      'totalEntries': instance.totalEntries,
      'playersLeft': instance.playersLeft,
      if (instance.startTime case final value?) 'startTime': value,
      'status': instance.status,
      'source': instance.source,
      if (instance.syncedAt case final value?) 'syncedAt': value,
      if (instance.createdAt case final value?) 'createdAt': value,
      if (instance.updatedAt case final value?) 'updatedAt': value,
    };
