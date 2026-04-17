import 'package:freezed_annotation/freezed_annotation.dart';

part 'skin_metadata.freezed.dart';
part 'skin_metadata.g.dart';

@freezed
class SkinMetadata with _$SkinMetadata {
  const factory SkinMetadata({
    @Default('') String title,
    @Default('') String description,
    String? author,
    @Default([]) List<String> tags,
  }) = _SkinMetadata;

  factory SkinMetadata.fromJson(Map<String, dynamic> json) =>
      _$SkinMetadataFromJson(json);

  factory SkinMetadata.empty() =>
      const SkinMetadata(title: '', description: '', tags: []);
}
