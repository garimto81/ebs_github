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
      'playerId': instance.playerId,
      'wsopId': instance.wsopId,
      'playerName': instance.playerName,
      'nationality': instance.nationality,
      'countryCode': instance.countryCode,
      'chipCount': instance.chipCount,
      'profileImage': instance.profileImage,
      'status': instance.status,
      'playerMoveStatus': instance.playerMoveStatus,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
