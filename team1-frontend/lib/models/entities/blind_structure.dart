import 'package:freezed_annotation/freezed_annotation.dart';

part 'blind_structure.freezed.dart';
part 'blind_structure.g.dart';

@freezed
class BlindStructure with _$BlindStructure {
  const factory BlindStructure({
    @JsonKey(name: 'blindStructureId') required int blindStructureId,
    required String name,
    @JsonKey(name: 'createdAt') required String createdAt,
    @JsonKey(name: 'updatedAt') required String updatedAt,
  }) = _BlindStructure;

  factory BlindStructure.fromJson(Map<String, dynamic> json) =>
      _$BlindStructureFromJson(json);
}
