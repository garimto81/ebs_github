// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'output_preset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OutputPresetImpl _$$OutputPresetImplFromJson(Map<String, dynamic> json) =>
    _$OutputPresetImpl(
      presetId: (json['presetId'] as num).toInt(),
      name: json['name'] as String,
      outputType: json['outputType'] as String,
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      framerate: (json['framerate'] as num).toInt(),
      securityDelaySec: (json['securityDelaySec'] as num).toInt(),
      chromaKey: json['chromaKey'] as bool,
      isDefault: json['isDefault'] as bool,
    );

Map<String, dynamic> _$$OutputPresetImplToJson(_$OutputPresetImpl instance) =>
    <String, dynamic>{
      'presetId': instance.presetId,
      'name': instance.name,
      'outputType': instance.outputType,
      'width': instance.width,
      'height': instance.height,
      'framerate': instance.framerate,
      'securityDelaySec': instance.securityDelaySec,
      'chromaKey': instance.chromaKey,
      'isDefault': instance.isDefault,
    };
