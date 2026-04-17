import 'package:freezed_annotation/freezed_annotation.dart';

part 'series.freezed.dart';
part 'series.g.dart';

@freezed
class Series with _$Series {
  const factory Series({
    @JsonKey(name: 'series_id') required int seriesId,
    @JsonKey(name: 'competition_id') required int competitionId,
    @JsonKey(name: 'series_name') required String seriesName,
    required int year,
    @JsonKey(name: 'begin_at') required String beginAt,
    @JsonKey(name: 'end_at') required String endAt,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'time_zone') required String timeZone,
    required String currency,
    @JsonKey(name: 'country_code') String? countryCode,
    @JsonKey(name: 'is_completed') @Default(false) bool isCompleted,
    @JsonKey(name: 'is_displayed') @Default(true) bool isDisplayed,
    @JsonKey(name: 'is_demo') @Default(false) bool isDemo,
    required String source,
    @JsonKey(name: 'synced_at') String? syncedAt,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _Series;

  factory Series.fromJson(Map<String, dynamic> json) =>
      _$SeriesFromJson(json);
}
