// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_flight.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EventFlightImpl _$$EventFlightImplFromJson(Map<String, dynamic> json) =>
    _$EventFlightImpl(
      eventFlightId: (json['event_flight_id'] as num).toInt(),
      eventId: (json['event_id'] as num).toInt(),
      displayName: json['display_name'] as String,
      startTime: json['start_time'] as String?,
      isTbd: json['is_tbd'] as bool,
      entries: (json['entries'] as num).toInt(),
      playersLeft: (json['players_left'] as num).toInt(),
      tableCount: (json['table_count'] as num).toInt(),
      status: json['status'] as String,
      playLevel: (json['play_level'] as num).toInt(),
      remainTime: (json['remain_time'] as num?)?.toInt(),
      source: json['source'] as String,
      syncedAt: json['synced_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      flightId: (json['flight_id'] as num).toInt(),
      dayIndex: (json['day_index'] as num).toInt(),
      flightName: json['flight_name'] as String,
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
      'flight_id': instance.flightId,
      'day_index': instance.dayIndex,
      'flight_name': instance.flightName,
      'player_count': instance.playerCount,
    };
