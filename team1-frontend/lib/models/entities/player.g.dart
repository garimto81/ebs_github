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
      if (instance.wsopId case final value?) 'wsopId': value,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      if (instance.nationality case final value?) 'nationality': value,
      if (instance.countryCode case final value?) 'countryCode': value,
      if (instance.profileImage case final value?) 'profileImage': value,
      'playerStatus': instance.playerStatus,
      'isDemo': instance.isDemo,
      'source': instance.source,
      if (instance.syncedAt case final value?) 'syncedAt': value,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      if (instance.stack case final value?) 'stack': value,
      if (instance.tableName case final value?) 'tableName': value,
      if (instance.seatIndex case final value?) 'seatIndex': value,
    };
