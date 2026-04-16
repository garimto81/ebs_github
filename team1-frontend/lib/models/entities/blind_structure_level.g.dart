// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blind_structure_level.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BlindStructureLevelImpl _$$BlindStructureLevelImplFromJson(
        Map<String, dynamic> json) =>
    _$BlindStructureLevelImpl(
      id: (json['id'] as num).toInt(),
      blindStructureId: (json['blind_structure_id'] as num).toInt(),
      levelNo: (json['level_no'] as num).toInt(),
      smallBlind: (json['small_blind'] as num).toInt(),
      bigBlind: (json['big_blind'] as num).toInt(),
      ante: (json['ante'] as num).toInt(),
      durationMinutes: (json['duration_minutes'] as num).toInt(),
    );

Map<String, dynamic> _$$BlindStructureLevelImplToJson(
        _$BlindStructureLevelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'blind_structure_id': instance.blindStructureId,
      'level_no': instance.levelNo,
      'small_blind': instance.smallBlind,
      'big_blind': instance.bigBlind,
      'ante': instance.ante,
      'duration_minutes': instance.durationMinutes,
    };
