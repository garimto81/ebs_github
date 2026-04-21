import 'package:freezed_annotation/freezed_annotation.dart';

part 'series.freezed.dart';
part 'series.g.dart';

@freezed
class Series with _$Series {
  const factory Series({
    @JsonKey(name: 'seriesId') required int seriesId,
    @JsonKey(name: 'competitionId') required int competitionId,
    @JsonKey(name: 'seriesName') required String seriesName,
    required int year,
    @JsonKey(name: 'beginAt') required String beginAt,
    @JsonKey(name: 'endAt') required String endAt,
    @JsonKey(name: 'imageUrl') String? imageUrl,
    @JsonKey(name: 'timeZone') required String timeZone,
    required String currency,
    @JsonKey(name: 'countryCode') String? countryCode,
    @JsonKey(name: 'isCompleted') @Default(false) bool isCompleted,
    @JsonKey(name: 'isDisplayed') @Default(true) bool isDisplayed,
    @JsonKey(name: 'isDemo') @Default(false) bool isDemo,
    required String source,
    @JsonKey(name: 'syncedAt') String? syncedAt,
    @JsonKey(name: 'createdAt') required String createdAt,
    @JsonKey(name: 'updatedAt') required String updatedAt,
  }) = _Series;

  factory Series.fromJson(Map<String, dynamic> json) =>
      _$SeriesFromJson(json);
}
