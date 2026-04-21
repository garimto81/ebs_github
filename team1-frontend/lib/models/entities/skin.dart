import 'package:freezed_annotation/freezed_annotation.dart';

import 'skin_metadata.dart';

part 'skin.freezed.dart';
part 'skin.g.dart';

@freezed
class Skin with _$Skin {
  const Skin._();

  const factory Skin({
    @JsonKey(name: 'skinId') required int skinId,
    required String name,
    @Default('1.0.0') String version,
    @Default('inactive') String status,
    SkinMetadata? metadata,
    @JsonKey(name: 'fileSize') @Default(0) int fileSize,
    @JsonKey(name: 'uploadedAt') String? uploadedAt,
    @JsonKey(name: 'activatedAt') String? activatedAt,
    @JsonKey(name: 'previewUrl') String? previewUrl,
  }) = _Skin;

  factory Skin.fromJson(Map<String, dynamic> json) => _$SkinFromJson(json);

  /// 메타데이터가 없을 때 안전 fallback 제공.
  /// 호출부에서 `skin.metadata.title` 대신 `skin.safeMetadata.title` 사용 가능.
  SkinMetadata get safeMetadata => metadata ?? SkinMetadata.empty();
}
