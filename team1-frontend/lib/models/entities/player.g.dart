// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayerImpl _$$PlayerImplFromJson(Map<String, dynamic> json) => _$PlayerImpl(
      playerId: (json['player_id'] as num).toInt(),
      wsopId: json['wsop_id'] as String?,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      nationality: json['nationality'] as String?,
      countryCode: json['country_code'] as String?,
      profileImage: json['profile_image'] as String?,
      playerStatus: json['player_status'] as String,
      isDemo: json['is_demo'] as bool,
      source: json['source'] as String,
      syncedAt: json['synced_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      stack: (json['stack'] as num?)?.toInt(),
      tableName: json['table_name'] as String?,
      seatIndex: (json['seat_index'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$PlayerImplToJson(_$PlayerImpl instance) =>
    <String, dynamic>{
      'player_id': instance.playerId,
      'wsop_id': instance.wsopId,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'nationality': instance.nationality,
      'country_code': instance.countryCode,
      'profile_image': instance.profileImage,
      'player_status': instance.playerStatus,
      'is_demo': instance.isDemo,
      'source': instance.source,
      'synced_at': instance.syncedAt,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'stack': instance.stack,
      'table_name': instance.tableName,
      'seat_index': instance.seatIndex,
    };
