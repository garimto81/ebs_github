// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skin_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SkinMetadataImpl _$$SkinMetadataImplFromJson(Map<String, dynamic> json) =>
    _$SkinMetadataImpl(
      title: json['title'] as String,
      description: json['description'] as String,
      author: json['author'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
    );

Map<String, dynamic> _$$SkinMetadataImplToJson(_$SkinMetadataImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'author': instance.author,
      'tags': instance.tags,
    };
