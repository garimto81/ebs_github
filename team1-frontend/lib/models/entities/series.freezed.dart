// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'series.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Series _$SeriesFromJson(Map<String, dynamic> json) {
  return _Series.fromJson(json);
}

/// @nodoc
mixin _$Series {
  @JsonKey(name: 'series_id')
  int get seriesId => throw _privateConstructorUsedError;
  @JsonKey(name: 'competition_id')
  int get competitionId => throw _privateConstructorUsedError;
  @JsonKey(name: 'series_name')
  String get seriesName => throw _privateConstructorUsedError;
  int get year => throw _privateConstructorUsedError;
  @JsonKey(name: 'begin_at')
  String get beginAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'end_at')
  String get endAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String? get imageUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'time_zone')
  String get timeZone => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  @JsonKey(name: 'country_code')
  String? get countryCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_completed')
  bool get isCompleted => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_displayed')
  bool get isDisplayed => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_demo')
  bool get isDemo => throw _privateConstructorUsedError;
  String get source => throw _privateConstructorUsedError;
  @JsonKey(name: 'synced_at')
  String? get syncedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  String get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Series to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Series
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SeriesCopyWith<Series> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SeriesCopyWith<$Res> {
  factory $SeriesCopyWith(Series value, $Res Function(Series) then) =
      _$SeriesCopyWithImpl<$Res, Series>;
  @useResult
  $Res call(
      {@JsonKey(name: 'series_id') int seriesId,
      @JsonKey(name: 'competition_id') int competitionId,
      @JsonKey(name: 'series_name') String seriesName,
      int year,
      @JsonKey(name: 'begin_at') String beginAt,
      @JsonKey(name: 'end_at') String endAt,
      @JsonKey(name: 'image_url') String? imageUrl,
      @JsonKey(name: 'time_zone') String timeZone,
      String currency,
      @JsonKey(name: 'country_code') String? countryCode,
      @JsonKey(name: 'is_completed') bool isCompleted,
      @JsonKey(name: 'is_displayed') bool isDisplayed,
      @JsonKey(name: 'is_demo') bool isDemo,
      String source,
      @JsonKey(name: 'synced_at') String? syncedAt,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'updated_at') String updatedAt});
}

/// @nodoc
class _$SeriesCopyWithImpl<$Res, $Val extends Series>
    implements $SeriesCopyWith<$Res> {
  _$SeriesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Series
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seriesId = null,
    Object? competitionId = null,
    Object? seriesName = null,
    Object? year = null,
    Object? beginAt = null,
    Object? endAt = null,
    Object? imageUrl = freezed,
    Object? timeZone = null,
    Object? currency = null,
    Object? countryCode = freezed,
    Object? isCompleted = null,
    Object? isDisplayed = null,
    Object? isDemo = null,
    Object? source = null,
    Object? syncedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      seriesId: null == seriesId
          ? _value.seriesId
          : seriesId // ignore: cast_nullable_to_non_nullable
              as int,
      competitionId: null == competitionId
          ? _value.competitionId
          : competitionId // ignore: cast_nullable_to_non_nullable
              as int,
      seriesName: null == seriesName
          ? _value.seriesName
          : seriesName // ignore: cast_nullable_to_non_nullable
              as String,
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      beginAt: null == beginAt
          ? _value.beginAt
          : beginAt // ignore: cast_nullable_to_non_nullable
              as String,
      endAt: null == endAt
          ? _value.endAt
          : endAt // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      timeZone: null == timeZone
          ? _value.timeZone
          : timeZone // ignore: cast_nullable_to_non_nullable
              as String,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      countryCode: freezed == countryCode
          ? _value.countryCode
          : countryCode // ignore: cast_nullable_to_non_nullable
              as String?,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      isDisplayed: null == isDisplayed
          ? _value.isDisplayed
          : isDisplayed // ignore: cast_nullable_to_non_nullable
              as bool,
      isDemo: null == isDemo
          ? _value.isDemo
          : isDemo // ignore: cast_nullable_to_non_nullable
              as bool,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      syncedAt: freezed == syncedAt
          ? _value.syncedAt
          : syncedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SeriesImplCopyWith<$Res> implements $SeriesCopyWith<$Res> {
  factory _$$SeriesImplCopyWith(
          _$SeriesImpl value, $Res Function(_$SeriesImpl) then) =
      __$$SeriesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'series_id') int seriesId,
      @JsonKey(name: 'competition_id') int competitionId,
      @JsonKey(name: 'series_name') String seriesName,
      int year,
      @JsonKey(name: 'begin_at') String beginAt,
      @JsonKey(name: 'end_at') String endAt,
      @JsonKey(name: 'image_url') String? imageUrl,
      @JsonKey(name: 'time_zone') String timeZone,
      String currency,
      @JsonKey(name: 'country_code') String? countryCode,
      @JsonKey(name: 'is_completed') bool isCompleted,
      @JsonKey(name: 'is_displayed') bool isDisplayed,
      @JsonKey(name: 'is_demo') bool isDemo,
      String source,
      @JsonKey(name: 'synced_at') String? syncedAt,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'updated_at') String updatedAt});
}

/// @nodoc
class __$$SeriesImplCopyWithImpl<$Res>
    extends _$SeriesCopyWithImpl<$Res, _$SeriesImpl>
    implements _$$SeriesImplCopyWith<$Res> {
  __$$SeriesImplCopyWithImpl(
      _$SeriesImpl _value, $Res Function(_$SeriesImpl) _then)
      : super(_value, _then);

  /// Create a copy of Series
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seriesId = null,
    Object? competitionId = null,
    Object? seriesName = null,
    Object? year = null,
    Object? beginAt = null,
    Object? endAt = null,
    Object? imageUrl = freezed,
    Object? timeZone = null,
    Object? currency = null,
    Object? countryCode = freezed,
    Object? isCompleted = null,
    Object? isDisplayed = null,
    Object? isDemo = null,
    Object? source = null,
    Object? syncedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$SeriesImpl(
      seriesId: null == seriesId
          ? _value.seriesId
          : seriesId // ignore: cast_nullable_to_non_nullable
              as int,
      competitionId: null == competitionId
          ? _value.competitionId
          : competitionId // ignore: cast_nullable_to_non_nullable
              as int,
      seriesName: null == seriesName
          ? _value.seriesName
          : seriesName // ignore: cast_nullable_to_non_nullable
              as String,
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      beginAt: null == beginAt
          ? _value.beginAt
          : beginAt // ignore: cast_nullable_to_non_nullable
              as String,
      endAt: null == endAt
          ? _value.endAt
          : endAt // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      timeZone: null == timeZone
          ? _value.timeZone
          : timeZone // ignore: cast_nullable_to_non_nullable
              as String,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      countryCode: freezed == countryCode
          ? _value.countryCode
          : countryCode // ignore: cast_nullable_to_non_nullable
              as String?,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      isDisplayed: null == isDisplayed
          ? _value.isDisplayed
          : isDisplayed // ignore: cast_nullable_to_non_nullable
              as bool,
      isDemo: null == isDemo
          ? _value.isDemo
          : isDemo // ignore: cast_nullable_to_non_nullable
              as bool,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      syncedAt: freezed == syncedAt
          ? _value.syncedAt
          : syncedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SeriesImpl implements _Series {
  const _$SeriesImpl(
      {@JsonKey(name: 'series_id') required this.seriesId,
      @JsonKey(name: 'competition_id') required this.competitionId,
      @JsonKey(name: 'series_name') required this.seriesName,
      required this.year,
      @JsonKey(name: 'begin_at') required this.beginAt,
      @JsonKey(name: 'end_at') required this.endAt,
      @JsonKey(name: 'image_url') this.imageUrl,
      @JsonKey(name: 'time_zone') required this.timeZone,
      required this.currency,
      @JsonKey(name: 'country_code') this.countryCode,
      @JsonKey(name: 'is_completed') this.isCompleted = false,
      @JsonKey(name: 'is_displayed') this.isDisplayed = true,
      @JsonKey(name: 'is_demo') this.isDemo = false,
      required this.source,
      @JsonKey(name: 'synced_at') this.syncedAt,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt});

  factory _$SeriesImpl.fromJson(Map<String, dynamic> json) =>
      _$$SeriesImplFromJson(json);

  @override
  @JsonKey(name: 'series_id')
  final int seriesId;
  @override
  @JsonKey(name: 'competition_id')
  final int competitionId;
  @override
  @JsonKey(name: 'series_name')
  final String seriesName;
  @override
  final int year;
  @override
  @JsonKey(name: 'begin_at')
  final String beginAt;
  @override
  @JsonKey(name: 'end_at')
  final String endAt;
  @override
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @override
  @JsonKey(name: 'time_zone')
  final String timeZone;
  @override
  final String currency;
  @override
  @JsonKey(name: 'country_code')
  final String? countryCode;
  @override
  @JsonKey(name: 'is_completed')
  final bool isCompleted;
  @override
  @JsonKey(name: 'is_displayed')
  final bool isDisplayed;
  @override
  @JsonKey(name: 'is_demo')
  final bool isDemo;
  @override
  final String source;
  @override
  @JsonKey(name: 'synced_at')
  final String? syncedAt;
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  @override
  String toString() {
    return 'Series(seriesId: $seriesId, competitionId: $competitionId, seriesName: $seriesName, year: $year, beginAt: $beginAt, endAt: $endAt, imageUrl: $imageUrl, timeZone: $timeZone, currency: $currency, countryCode: $countryCode, isCompleted: $isCompleted, isDisplayed: $isDisplayed, isDemo: $isDemo, source: $source, syncedAt: $syncedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SeriesImpl &&
            (identical(other.seriesId, seriesId) ||
                other.seriesId == seriesId) &&
            (identical(other.competitionId, competitionId) ||
                other.competitionId == competitionId) &&
            (identical(other.seriesName, seriesName) ||
                other.seriesName == seriesName) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.beginAt, beginAt) || other.beginAt == beginAt) &&
            (identical(other.endAt, endAt) || other.endAt == endAt) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.timeZone, timeZone) ||
                other.timeZone == timeZone) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.countryCode, countryCode) ||
                other.countryCode == countryCode) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.isDisplayed, isDisplayed) ||
                other.isDisplayed == isDisplayed) &&
            (identical(other.isDemo, isDemo) || other.isDemo == isDemo) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.syncedAt, syncedAt) ||
                other.syncedAt == syncedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      seriesId,
      competitionId,
      seriesName,
      year,
      beginAt,
      endAt,
      imageUrl,
      timeZone,
      currency,
      countryCode,
      isCompleted,
      isDisplayed,
      isDemo,
      source,
      syncedAt,
      createdAt,
      updatedAt);

  /// Create a copy of Series
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SeriesImplCopyWith<_$SeriesImpl> get copyWith =>
      __$$SeriesImplCopyWithImpl<_$SeriesImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SeriesImplToJson(
      this,
    );
  }
}

abstract class _Series implements Series {
  const factory _Series(
          {@JsonKey(name: 'series_id') required final int seriesId,
          @JsonKey(name: 'competition_id') required final int competitionId,
          @JsonKey(name: 'series_name') required final String seriesName,
          required final int year,
          @JsonKey(name: 'begin_at') required final String beginAt,
          @JsonKey(name: 'end_at') required final String endAt,
          @JsonKey(name: 'image_url') final String? imageUrl,
          @JsonKey(name: 'time_zone') required final String timeZone,
          required final String currency,
          @JsonKey(name: 'country_code') final String? countryCode,
          @JsonKey(name: 'is_completed') final bool isCompleted,
          @JsonKey(name: 'is_displayed') final bool isDisplayed,
          @JsonKey(name: 'is_demo') final bool isDemo,
          required final String source,
          @JsonKey(name: 'synced_at') final String? syncedAt,
          @JsonKey(name: 'created_at') required final String createdAt,
          @JsonKey(name: 'updated_at') required final String updatedAt}) =
      _$SeriesImpl;

  factory _Series.fromJson(Map<String, dynamic> json) = _$SeriesImpl.fromJson;

  @override
  @JsonKey(name: 'series_id')
  int get seriesId;
  @override
  @JsonKey(name: 'competition_id')
  int get competitionId;
  @override
  @JsonKey(name: 'series_name')
  String get seriesName;
  @override
  int get year;
  @override
  @JsonKey(name: 'begin_at')
  String get beginAt;
  @override
  @JsonKey(name: 'end_at')
  String get endAt;
  @override
  @JsonKey(name: 'image_url')
  String? get imageUrl;
  @override
  @JsonKey(name: 'time_zone')
  String get timeZone;
  @override
  String get currency;
  @override
  @JsonKey(name: 'country_code')
  String? get countryCode;
  @override
  @JsonKey(name: 'is_completed')
  bool get isCompleted;
  @override
  @JsonKey(name: 'is_displayed')
  bool get isDisplayed;
  @override
  @JsonKey(name: 'is_demo')
  bool get isDemo;
  @override
  String get source;
  @override
  @JsonKey(name: 'synced_at')
  String? get syncedAt;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  String get updatedAt;

  /// Create a copy of Series
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SeriesImplCopyWith<_$SeriesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
