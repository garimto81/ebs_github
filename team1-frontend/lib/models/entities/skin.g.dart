// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SkinImpl _$$SkinImplFromJson(Map<String, dynamic> json) => _$SkinImpl(
      skinId: (json['skin_id'] as num).toInt(),
      name: json['name'] as String,
      version: json['version'] as String? ?? '1.0.0',
      status: json['status'] as String? ?? 'inactive',
      metadata: json['metadata'] == null
          ? null
          : SkinMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      uploadedAt: json['uploaded_at'] as String?,
      activatedAt: json['activated_at'] as String?,
      previewUrl: json['preview_url'] as String?,
    );

Map<String, dynamic> _$$SkinImplToJson(_$SkinImpl instance) =>
    <String, dynamic>{
      'skin_id': instance.skinId,
      'name': instance.name,
      'version': instance.version,
      'status': instance.status,
      'metadata': instance.metadata,
      'file_size': instance.fileSize,
      'uploaded_at': instance.uploadedAt,
      'activated_at': instance.activatedAt,
      'preview_url': instance.previewUrl,
    };
