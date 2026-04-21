// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SkinImpl _$$SkinImplFromJson(Map<String, dynamic> json) => _$SkinImpl(
      skinId: (json['skinId'] as num).toInt(),
      name: json['name'] as String,
      version: json['version'] as String? ?? '1.0.0',
      status: json['status'] as String? ?? 'inactive',
      metadata: json['metadata'] == null
          ? null
          : SkinMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      uploadedAt: json['uploadedAt'] as String?,
      activatedAt: json['activatedAt'] as String?,
      previewUrl: json['previewUrl'] as String?,
    );

Map<String, dynamic> _$$SkinImplToJson(_$SkinImpl instance) =>
    <String, dynamic>{
      'skinId': instance.skinId,
      'name': instance.name,
      'version': instance.version,
      'status': instance.status,
      'metadata': instance.metadata,
      'fileSize': instance.fileSize,
      'uploadedAt': instance.uploadedAt,
      'activatedAt': instance.activatedAt,
      'previewUrl': instance.previewUrl,
    };
