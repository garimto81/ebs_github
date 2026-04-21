// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_flight.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EventFlightImpl _$$EventFlightImplFromJson(Map<String, dynamic> json) =>
    _$EventFlightImpl(
      eventFlightId: (json['event_flight_id'] as num).toInt(),
      eventId: (json['event_id'] as num).toInt(),
      displayName: json['display_name'] as String? ?? '',
      startTime: json['start_time'] as String?,
      isTbd: json['is_tbd'] as bool? ?? false,
      entries: (json['entries'] as num?)?.toInt() ?? 0,
      playersLeft: (json['players_left'] as num?)?.toInt() ?? 0,
      tableCount: (json['table_count'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'created',
      playLevel: (json['play_level'] as num?)?.toInt() ?? 1,
      remainTime: (json['remain_time'] as num?)?.toInt(),
      source: json['source'] as String? ?? 'api',
      syncedAt: json['synced_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      playerCount: (json['player_count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$EventFlightImplToJson(_$EventFlightImpl instance) =>
    <String, dynamic>{
      'event_flight_id': instance.eventFlightId,
      'event_id': instance.eventId,
      'display_name': instance.displayName,
      'start_time': instance.startTime,
      'is_tbd': instance.isTbd,
      'entries': instance.entries,
      'players_left': instance.playersLeft,
      'table_count': instance.tableCount,
      'status': instance.status,
      'play_level': instance.playLevel,
      'remain_time': instance.remainTime,
      'source': instance.source,
      'synced_at': instance.syncedAt,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'player_count': instance.playerCount,
    };
