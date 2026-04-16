// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'output_preset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OutputPresetImpl _$$OutputPresetImplFromJson(Map<String, dynamic> json) =>
    _$OutputPresetImpl(
      presetId: (json['preset_id'] as num).toInt(),
      name: json['name'] as String,
      outputType: json['output_type'] as String,
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      framerate: (json['framerate'] as num).toInt(),
      securityDelaySec: (json['security_delay_sec'] as num).toInt(),
      chromaKey: json['chroma_key'] as bool,
      isDefault: json['is_default'] as bool,
    );

Map<String, dynamic> _$$OutputPresetImplToJson(_$OutputPresetImpl instance) =>
    <String, dynamic>{
      'preset_id': instance.presetId,
      'name': instance.name,
      'output_type': instance.outputType,
      'width': instance.width,
      'height': instance.height,
      'framerate': instance.framerate,
      'security_delay_sec': instance.securityDelaySec,
      'chroma_key': instance.chromaKey,
      'is_default': instance.isDefault,
    };
