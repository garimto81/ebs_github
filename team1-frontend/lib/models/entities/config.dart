import 'package:freezed_annotation/freezed_annotation.dart';

part 'config.freezed.dart';
part 'config.g.dart';

@freezed
class EbsConfig with _$EbsConfig {
  const factory EbsConfig({
    required int id,
    required String key,
    required String value,
    required String category,
    String? description,
  }) = _EbsConfig;

  factory EbsConfig.fromJson(Map<String, dynamic> json) =>
      _$EbsConfigFromJson(json);
}
