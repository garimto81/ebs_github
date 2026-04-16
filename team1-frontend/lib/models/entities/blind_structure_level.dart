import 'package:freezed_annotation/freezed_annotation.dart';

part 'blind_structure_level.freezed.dart';
part 'blind_structure_level.g.dart';

@freezed
class BlindStructureLevel with _$BlindStructureLevel {
  const factory BlindStructureLevel({
    required int id,
    @JsonKey(name: 'blind_structure_id') required int blindStructureId,
    @JsonKey(name: 'level_no') required int levelNo,
    @JsonKey(name: 'small_blind') required int smallBlind,
    @JsonKey(name: 'big_blind') required int bigBlind,
    required int ante,
    @JsonKey(name: 'duration_minutes') required int durationMinutes,
  }) = _BlindStructureLevel;

  factory BlindStructureLevel.fromJson(Map<String, dynamic> json) =>
      _$BlindStructureLevelFromJson(json);
}
