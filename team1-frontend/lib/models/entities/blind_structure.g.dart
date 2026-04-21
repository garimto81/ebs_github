// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blind_structure.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BlindStructureImpl _$$BlindStructureImplFromJson(Map<String, dynamic> json) =>
    _$BlindStructureImpl(
      blindStructureId: (json['blindStructureId'] as num).toInt(),
      name: json['name'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );

Map<String, dynamic> _$$BlindStructureImplToJson(
        _$BlindStructureImpl instance) =>
    <String, dynamic>{
      'blindStructureId': instance.blindStructureId,
      'name': instance.name,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
