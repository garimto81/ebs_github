// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blind_structure.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BlindStructureImpl _$$BlindStructureImplFromJson(Map<String, dynamic> json) =>
    _$BlindStructureImpl(
      blindStructureId: (json['blind_structure_id'] as num).toInt(),
      name: json['name'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$$BlindStructureImplToJson(
        _$BlindStructureImpl instance) =>
    <String, dynamic>{
      'blind_structure_id': instance.blindStructureId,
      'name': instance.name,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
