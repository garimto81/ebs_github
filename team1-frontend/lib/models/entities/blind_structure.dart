import 'package:freezed_annotation/freezed_annotation.dart';

part 'blind_structure.freezed.dart';
part 'blind_structure.g.dart';

@freezed
class BlindStructure with _$BlindStructure {
  const factory BlindStructure({
    @JsonKey(name: 'blind_structure_id') required int blindStructureId,
    required String name,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _BlindStructure;

  factory BlindStructure.fromJson(Map<String, dynamic> json) =>
      _$BlindStructureFromJson(json);
}
