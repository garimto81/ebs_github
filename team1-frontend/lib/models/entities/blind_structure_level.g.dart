// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blind_structure_level.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BlindStructureLevelImpl _$$BlindStructureLevelImplFromJson(
        Map<String, dynamic> json) =>
    _$BlindStructureLevelImpl(
      id: (json['id'] as num).toInt(),
      blindStructureId: (json['blindStructureId'] as num).toInt(),
      levelNo: (json['levelNo'] as num).toInt(),
      smallBlind: (json['smallBlind'] as num).toInt(),
      bigBlind: (json['bigBlind'] as num).toInt(),
      ante: (json['ante'] as num).toInt(),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
    );

Map<String, dynamic> _$$BlindStructureLevelImplToJson(
        _$BlindStructureLevelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'blindStructureId': instance.blindStructureId,
      'levelNo': instance.levelNo,
      'smallBlind': instance.smallBlind,
      'bigBlind': instance.bigBlind,
      'ante': instance.ante,
      'durationMinutes': instance.durationMinutes,
    };
