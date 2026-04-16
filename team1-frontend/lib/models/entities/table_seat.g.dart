// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table_seat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TableSeatImpl _$$TableSeatImplFromJson(Map<String, dynamic> json) =>
    _$TableSeatImpl(
      seatId: (json['seat_id'] as num).toInt(),
      tableId: (json['table_id'] as num).toInt(),
      seatNo: (json['seat_no'] as num).toInt(),
      playerId: (json['player_id'] as num?)?.toInt(),
      wsopId: json['wsop_id'] as String?,
      playerName: json['player_name'] as String?,
      nationality: json['nationality'] as String?,
      countryCode: json['country_code'] as String?,
      chipCount: (json['chip_count'] as num).toInt(),
      profileImage: json['profile_image'] as String?,
      status: json['status'] as String,
      playerMoveStatus: json['player_move_status'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$$TableSeatImplToJson(_$TableSeatImpl instance) =>
    <String, dynamic>{
      'seat_id': instance.seatId,
      'table_id': instance.tableId,
      'seat_no': instance.seatNo,
      'player_id': instance.playerId,
      'wsop_id': instance.wsopId,
      'player_name': instance.playerName,
      'nationality': instance.nationality,
      'country_code': instance.countryCode,
      'chip_count': instance.chipCount,
      'profile_image': instance.profileImage,
      'status': instance.status,
      'player_move_status': instance.playerMoveStatus,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
