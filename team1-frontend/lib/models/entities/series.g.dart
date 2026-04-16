// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'series.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SeriesImpl _$$SeriesImplFromJson(Map<String, dynamic> json) => _$SeriesImpl(
      seriesId: (json['series_id'] as num).toInt(),
      competitionId: (json['competition_id'] as num).toInt(),
      seriesName: json['series_name'] as String,
      year: (json['year'] as num).toInt(),
      beginAt: json['begin_at'] as String,
      endAt: json['end_at'] as String,
      imageUrl: json['image_url'] as String?,
      timeZone: json['time_zone'] as String,
      currency: json['currency'] as String,
      countryCode: json['country_code'] as String?,
      isCompleted: json['is_completed'] as bool,
      isDisplayed: json['is_displayed'] as bool,
      isDemo: json['is_demo'] as bool,
      source: json['source'] as String,
      syncedAt: json['synced_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$$SeriesImplToJson(_$SeriesImpl instance) =>
    <String, dynamic>{
      'series_id': instance.seriesId,
      'competition_id': instance.competitionId,
      'series_name': instance.seriesName,
      'year': instance.year,
      'begin_at': instance.beginAt,
      'end_at': instance.endAt,
      'image_url': instance.imageUrl,
      'time_zone': instance.timeZone,
      'currency': instance.currency,
      'country_code': instance.countryCode,
      'is_completed': instance.isCompleted,
      'is_displayed': instance.isDisplayed,
      'is_demo': instance.isDemo,
      'source': instance.source,
      'synced_at': instance.syncedAt,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
