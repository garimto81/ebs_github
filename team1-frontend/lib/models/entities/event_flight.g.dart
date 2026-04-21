// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_flight.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EventFlightImpl _$$EventFlightImplFromJson(Map<String, dynamic> json) =>
    _$EventFlightImpl(
      eventFlightId: (json['eventFlightId'] as num).toInt(),
      eventId: (json['eventId'] as num).toInt(),
      displayName: json['displayName'] as String? ?? '',
      startTime: json['startTime'] as String?,
      isTbd: json['isTbd'] as bool? ?? false,
      entries: (json['entries'] as num?)?.toInt() ?? 0,
      playersLeft: (json['playersLeft'] as num?)?.toInt() ?? 0,
      tableCount: (json['tableCount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'created',
      playLevel: (json['playLevel'] as num?)?.toInt() ?? 1,
      remainTime: (json['remainTime'] as num?)?.toInt(),
      source: json['source'] as String? ?? 'api',
      syncedAt: json['syncedAt'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      playerCount: (json['playerCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$EventFlightImplToJson(_$EventFlightImpl instance) =>
    <String, dynamic>{
      'eventFlightId': instance.eventFlightId,
      'eventId': instance.eventId,
      'displayName': instance.displayName,
      'startTime': instance.startTime,
      'isTbd': instance.isTbd,
      'entries': instance.entries,
      'playersLeft': instance.playersLeft,
      'tableCount': instance.tableCount,
      'status': instance.status,
      'playLevel': instance.playLevel,
      'remainTime': instance.remainTime,
      'source': instance.source,
      'syncedAt': instance.syncedAt,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'playerCount': instance.playerCount,
    };
