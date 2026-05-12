// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table_seat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TableSeatImpl _$$TableSeatImplFromJson(Map<String, dynamic> json) =>
    _$TableSeatImpl(
      seatId: (json['seatId'] as num).toInt(),
      tableId: (json['tableId'] as num).toInt(),
      seatNo: (json['seatNo'] as num).toInt(),
      playerId: (json['playerId'] as num?)?.toInt(),
      wsopId: json['wsopId'] as String?,
      playerName: json['playerName'] as String?,
      nationality: json['nationality'] as String?,
      countryCode: json['countryCode'] as String?,
      chipCount: (json['chipCount'] as num).toInt(),
      profileImage: json['profileImage'] as String?,
      status: json['status'] as String,
      playerMoveStatus: json['playerMoveStatus'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );

Map<String, dynamic> _$$TableSeatImplToJson(_$TableSeatImpl instance) =>
    <String, dynamic>{
      'seatId': instance.seatId,
      'tableId': instance.tableId,
      'seatNo': instance.seatNo,
      if (instance.playerId case final value?) 'playerId': value,
      if (instance.wsopId case final value?) 'wsopId': value,
      if (instance.playerName case final value?) 'playerName': value,
      if (instance.nationality case final value?) 'nationality': value,
      if (instance.countryCode case final value?) 'countryCode': value,
      'chipCount': instance.chipCount,
      if (instance.profileImage case final value?) 'profileImage': value,
      'status': instance.status,
      if (instance.playerMoveStatus case final value?)
        'playerMoveStatus': value,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
