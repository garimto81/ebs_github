import 'package:freezed_annotation/freezed_annotation.dart';

import 'skin_metadata.dart';

part 'skin.freezed.dart';
part 'skin.g.dart';

@freezed
class Skin with _$Skin {
  const factory Skin({
    @JsonKey(name: 'skin_id') required int skinId,
    required String name,
    required String version,
    required String status,
    required SkinMetadata metadata,
    @JsonKey(name: 'file_size') required int fileSize,
    @JsonKey(name: 'uploaded_at') required String uploadedAt,
    @JsonKey(name: 'activated_at') String? activatedAt,
    @JsonKey(name: 'preview_url') String? previewUrl,
  }) = _Skin;

  factory Skin.fromJson(Map<String, dynamic> json) => _$SkinFromJson(json);
}
