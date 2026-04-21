// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'series.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SeriesImpl _$$SeriesImplFromJson(Map<String, dynamic> json) => _$SeriesImpl(
      seriesId: (json['seriesId'] as num).toInt(),
      competitionId: (json['competitionId'] as num).toInt(),
      seriesName: json['seriesName'] as String,
      year: (json['year'] as num).toInt(),
      beginAt: json['beginAt'] as String,
      endAt: json['endAt'] as String,
      imageUrl: json['imageUrl'] as String?,
      timeZone: json['timeZone'] as String,
      currency: json['currency'] as String,
      countryCode: json['countryCode'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isDisplayed: json['isDisplayed'] as bool? ?? true,
      isDemo: json['isDemo'] as bool? ?? false,
      source: json['source'] as String,
      syncedAt: json['syncedAt'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );

Map<String, dynamic> _$$SeriesImplToJson(_$SeriesImpl instance) =>
    <String, dynamic>{
      'seriesId': instance.seriesId,
      'competitionId': instance.competitionId,
      'seriesName': instance.seriesName,
      'year': instance.year,
      'beginAt': instance.beginAt,
      'endAt': instance.endAt,
      'imageUrl': instance.imageUrl,
      'timeZone': instance.timeZone,
      'currency': instance.currency,
      'countryCode': instance.countryCode,
      'isCompleted': instance.isCompleted,
      'isDisplayed': instance.isDisplayed,
      'isDemo': instance.isDemo,
      'source': instance.source,
      'syncedAt': instance.syncedAt,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
