import 'package:freezed_annotation/freezed_annotation.dart';

part 'output_preset.freezed.dart';
part 'output_preset.g.dart';

@freezed
class OutputPreset with _$OutputPreset {
  const factory OutputPreset({
    @JsonKey(name: 'presetId') required int presetId,
    required String name,
    @JsonKey(name: 'outputType') required String outputType,
    required int width,
    required int height,
    required int framerate,
    @JsonKey(name: 'securityDelaySec') required int securityDelaySec,
    @JsonKey(name: 'chromaKey') required bool chromaKey,
    @JsonKey(name: 'isDefault') required bool isDefault,
  }) = _OutputPreset;

  factory OutputPreset.fromJson(Map<String, dynamic> json) =>
      _$OutputPresetFromJson(json);
}
