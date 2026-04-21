import 'package:freezed_annotation/freezed_annotation.dart';

part 'blind_structure_level.freezed.dart';
part 'blind_structure_level.g.dart';

@freezed
class BlindStructureLevel with _$BlindStructureLevel {
  const factory BlindStructureLevel({
    required int id,
    @JsonKey(name: 'blindStructureId') required int blindStructureId,
    @JsonKey(name: 'levelNo') required int levelNo,
    @JsonKey(name: 'smallBlind') required int smallBlind,
    @JsonKey(name: 'bigBlind') required int bigBlind,
    required int ante,
    @JsonKey(name: 'durationMinutes') required int durationMinutes,
  }) = _BlindStructureLevel;

  factory BlindStructureLevel.fromJson(Map<String, dynamic> json) =>
      _$BlindStructureLevelFromJson(json);
}
