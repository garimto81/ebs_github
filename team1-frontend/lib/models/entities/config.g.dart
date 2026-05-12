// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EbsConfigImpl _$$EbsConfigImplFromJson(Map<String, dynamic> json) =>
    _$EbsConfigImpl(
      id: (json['id'] as num).toInt(),
      key: json['key'] as String,
      value: json['value'] as String,
      category: json['category'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$EbsConfigImplToJson(_$EbsConfigImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'value': instance.value,
      'category': instance.category,
      if (instance.description case final value?) 'description': value,
    };
