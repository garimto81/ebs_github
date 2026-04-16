// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ebs_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EbsEventImpl _$$EbsEventImplFromJson(Map<String, dynamic> json) =>
    _$EbsEventImpl(
      eventId: (json['event_id'] as num).toInt(),
      seriesId: (json['series_id'] as num).toInt(),
      eventNo: (json['event_no'] as num).toInt(),
      eventName: json['event_name'] as String,
      buyIn: (json['buy_in'] as num?)?.toInt(),
      displayBuyIn: json['display_buy_in'] as String?,
      gameType: (json['game_type'] as num).toInt(),
      betStructure: (json['bet_structure'] as num).toInt(),
      eventGameType: (json['event_game_type'] as num).toInt(),
      gameMode: json['game_mode'] as String,
      allowedGames: json['allowed_games'] as String?,
      rotationOrder: json['rotation_order'] as String?,
      rotationTrigger: json['rotation_trigger'] as String?,
      blindStructureId: (json['blind_structure_id'] as num?)?.toInt(),
      startingChip: (json['starting_chip'] as num?)?.toInt(),
      tableSize: (json['table_size'] as num).toInt(),
      totalEntries: (json['total_entries'] as num).toInt(),
      playersLeft: (json['players_left'] as num).toInt(),
      startTime: json['start_time'] as String?,
      status: json['status'] as String,
      source: json['source'] as String,
      syncedAt: json['synced_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$$EbsEventImplToJson(_$EbsEventImpl instance) =>
    <String, dynamic>{
      'event_id': instance.eventId,
      'series_id': instance.seriesId,
      'event_no': instance.eventNo,
      'event_name': instance.eventName,
      'buy_in': instance.buyIn,
      'display_buy_in': instance.displayBuyIn,
      'game_type': instance.gameType,
      'bet_structure': instance.betStructure,
      'event_game_type': instance.eventGameType,
      'game_mode': instance.gameMode,
      'allowed_games': instance.allowedGames,
      'rotation_order': instance.rotationOrder,
      'rotation_trigger': instance.rotationTrigger,
      'blind_structure_id': instance.blindStructureId,
      'starting_chip': instance.startingChip,
      'table_size': instance.tableSize,
      'total_entries': instance.totalEntries,
      'players_left': instance.playersLeft,
      'start_time': instance.startTime,
      'status': instance.status,
      'source': instance.source,
      'synced_at': instance.syncedAt,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
