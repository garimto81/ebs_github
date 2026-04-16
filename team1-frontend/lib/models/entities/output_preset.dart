import 'package:freezed_annotation/freezed_annotation.dart';

part 'output_preset.freezed.dart';
part 'output_preset.g.dart';

@freezed
class OutputPreset with _$OutputPreset {
  const factory OutputPreset({
    @JsonKey(name: 'preset_id') required int presetId,
    required String name,
    @JsonKey(name: 'output_type') required String outputType,
    required int width,
    required int height,
    required int framerate,
    @JsonKey(name: 'security_delay_sec') required int securityDelaySec,
    @JsonKey(name: 'chroma_key') required bool chromaKey,
    @JsonKey(name: 'is_default') required bool isDefault,
  }) = _OutputPreset;

  factory OutputPreset.fromJson(Map<String, dynamic> json) =>
      _$OutputPresetFromJson(json);
}
