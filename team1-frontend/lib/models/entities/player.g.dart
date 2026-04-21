// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayerImpl _$$PlayerImplFromJson(Map<String, dynamic> json) => _$PlayerImpl(
      playerId: (json['playerId'] as num).toInt(),
      wsopId: json['wsopId'] as String?,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      nationality: json['nationality'] as String?,
      countryCode: json['countryCode'] as String?,
      profileImage: json['profileImage'] as String?,
      playerStatus: json['playerStatus'] as String,
      isDemo: json['isDemo'] as bool? ?? false,
      source: json['source'] as String,
      syncedAt: json['syncedAt'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      stack: (json['stack'] as num?)?.toInt(),
      tableName: json['tableName'] as String?,
      seatIndex: (json['seatIndex'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$PlayerImplToJson(_$PlayerImpl instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'wsopId': instance.wsopId,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'nationality': instance.nationality,
      'countryCode': instance.countryCode,
      'profileImage': instance.profileImage,
      'playerStatus': instance.playerStatus,
      'isDemo': instance.isDemo,
      'source': instance.source,
      'syncedAt': instance.syncedAt,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'stack': instance.stack,
      'tableName': instance.tableName,
      'seatIndex': instance.seatIndex,
    };
