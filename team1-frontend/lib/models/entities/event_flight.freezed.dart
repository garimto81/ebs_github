// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_flight.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

EventFlight _$EventFlightFromJson(Map<String, dynamic> json) {
  return _EventFlight.fromJson(json);
}

/// @nodoc
mixin _$EventFlight {
  @JsonKey(name: 'eventFlightId')
  int get eventFlightId => throw _privateConstructorUsedError;
  @JsonKey(name: 'eventId')
  int get eventId => throw _privateConstructorUsedError;
  @JsonKey(name: 'displayName')
  String get displayName => throw _privateConstructorUsedError;
  @JsonKey(name: 'startTime')
  String? get startTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'isTbd')
  bool get isTbd => throw _privateConstructorUsedError;
  int get entries => throw _privateConstructorUsedError;
  @JsonKey(name: 'playersLeft')
  int get playersLeft => throw _privateConstructorUsedError;
  @JsonKey(name: 'tableCount')
  int get tableCount => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'playLevel')
  int get playLevel => throw _privateConstructorUsedError;
  @JsonKey(name: 'remainTime')
  int? get remainTime => throw _privateConstructorUsedError;
  String get source => throw _privateConstructorUsedError;
  @JsonKey(name: 'syncedAt')
  String? get syncedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'createdAt')
  String? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updatedAt')
  String? get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'playerCount')
  int? get playerCount => throw _privateConstructorUsedError;

  /// Serializes this EventFlight to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EventFlight
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EventFlightCopyWith<EventFlight> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EventFlightCopyWith<$Res> {
  factory $EventFlightCopyWith(
          EventFlight value, $Res Function(EventFlight) then) =
      _$EventFlightCopyWithImpl<$Res, EventFlight>;
  @useResult
  $Res call(
      {@JsonKey(name: 'eventFlightId') int eventFlightId,
      @JsonKey(name: 'eventId') int eventId,
      @JsonKey(name: 'displayName') String displayName,
      @JsonKey(name: 'startTime') String? startTime,
      @JsonKey(name: 'isTbd') bool isTbd,
      int entries,
      @JsonKey(name: 'playersLeft') int playersLeft,
      @JsonKey(name: 'tableCount') int tableCount,
      String status,
      @JsonKey(name: 'playLevel') int playLevel,
      @JsonKey(name: 'remainTime') int? remainTime,
      String source,
      @JsonKey(name: 'syncedAt') String? syncedAt,
      @JsonKey(name: 'createdAt') String? createdAt,
      @JsonKey(name: 'updatedAt') String? updatedAt,
      @JsonKey(name: 'playerCount') int? playerCount});
}

/// @nodoc
class _$EventFlightCopyWithImpl<$Res, $Val extends EventFlight>
    implements $EventFlightCopyWith<$Res> {
  _$EventFlightCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EventFlight
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? eventFlightId = null,
    Object? eventId = null,
    Object? displayName = null,
    Object? startTime = freezed,
    Object? isTbd = null,
    Object? entries = null,
    Object? playersLeft = null,
    Object? tableCount = null,
    Object? status = null,
    Object? playLevel = null,
    Object? remainTime = freezed,
    Object? source = null,
    Object? syncedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? playerCount = freezed,
  }) {
    return _then(_value.copyWith(
      eventFlightId: null == eventFlightId
          ? _value.eventFlightId
          : eventFlightId // ignore: cast_nullable_to_non_nullable
              as int,
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as int,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: freezed == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String?,
      isTbd: null == isTbd
          ? _value.isTbd
          : isTbd // ignore: cast_nullable_to_non_nullable
              as bool,
      entries: null == entries
          ? _value.entries
          : entries // ignore: cast_nullable_to_non_nullable
              as int,
      playersLeft: null == playersLeft
          ? _value.playersLeft
          : playersLeft // ignore: cast_nullable_to_non_nullable
              as int,
      tableCount: null == tableCount
          ? _value.tableCount
          : tableCount // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      playLevel: null == playLevel
          ? _value.playLevel
          : playLevel // ignore: cast_nullable_to_non_nullable
              as int,
      remainTime: freezed == remainTime
          ? _value.remainTime
          : remainTime // ignore: cast_nullable_to_non_nullable
              as int?,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      syncedAt: freezed == syncedAt
          ? _value.syncedAt
          : syncedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      playerCount: freezed == playerCount
          ? _value.playerCount
          : playerCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EventFlightImplCopyWith<$Res>
    implements $EventFlightCopyWith<$Res> {
  factory _$$EventFlightImplCopyWith(
          _$EventFlightImpl value, $Res Function(_$EventFlightImpl) then) =
      __$$EventFlightImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'eventFlightId') int eventFlightId,
      @JsonKey(name: 'eventId') int eventId,
      @JsonKey(name: 'displayName') String displayName,
      @JsonKey(name: 'startTime') String? startTime,
      @JsonKey(name: 'isTbd') bool isTbd,
      int entries,
      @JsonKey(name: 'playersLeft') int playersLeft,
      @JsonKey(name: 'tableCount') int tableCount,
      String status,
      @JsonKey(name: 'playLevel') int playLevel,
      @JsonKey(name: 'remainTime') int? remainTime,
      String source,
      @JsonKey(name: 'syncedAt') String? syncedAt,
      @JsonKey(name: 'createdAt') String? createdAt,
      @JsonKey(name: 'updatedAt') String? updatedAt,
      @JsonKey(name: 'playerCount') int? playerCount});
}

/// @nodoc
class __$$EventFlightImplCopyWithImpl<$Res>
    extends _$EventFlightCopyWithImpl<$Res, _$EventFlightImpl>
    implements _$$EventFlightImplCopyWith<$Res> {
  __$$EventFlightImplCopyWithImpl(
      _$EventFlightImpl _value, $Res Function(_$EventFlightImpl) _then)
      : super(_value, _then);

  /// Create a copy of EventFlight
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? eventFlightId = null,
    Object? eventId = null,
    Object? displayName = null,
    Object? startTime = freezed,
    Object? isTbd = null,
    Object? entries = null,
    Object? playersLeft = null,
    Object? tableCount = null,
    Object? status = null,
    Object? playLevel = null,
    Object? remainTime = freezed,
    Object? source = null,
    Object? syncedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? playerCount = freezed,
  }) {
    return _then(_$EventFlightImpl(
      eventFlightId: null == eventFlightId
          ? _value.eventFlightId
          : eventFlightId // ignore: cast_nullable_to_non_nullable
              as int,
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as int,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: freezed == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String?,
      isTbd: null == isTbd
          ? _value.isTbd
          : isTbd // ignore: cast_nullable_to_non_nullable
              as bool,
      entries: null == entries
          ? _value.entries
          : entries // ignore: cast_nullable_to_non_nullable
              as int,
      playersLeft: null == playersLeft
          ? _value.playersLeft
          : playersLeft // ignore: cast_nullable_to_non_nullable
              as int,
      tableCount: null == tableCount
          ? _value.tableCount
          : tableCount // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      playLevel: null == playLevel
          ? _value.playLevel
          : playLevel // ignore: cast_nullable_to_non_nullable
              as int,
      remainTime: freezed == remainTime
          ? _value.remainTime
          : remainTime // ignore: cast_nullable_to_non_nullable
              as int?,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      syncedAt: freezed == syncedAt
          ? _value.syncedAt
          : syncedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      playerCount: freezed == playerCount
          ? _value.playerCount
          : playerCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EventFlightImpl implements _EventFlight {
  const _$EventFlightImpl(
      {@JsonKey(name: 'eventFlightId') required this.eventFlightId,
      @JsonKey(name: 'eventId') required this.eventId,
      @JsonKey(name: 'displayName') this.displayName = '',
      @JsonKey(name: 'startTime') this.startTime,
      @JsonKey(name: 'isTbd') this.isTbd = false,
      this.entries = 0,
      @JsonKey(name: 'playersLeft') this.playersLeft = 0,
      @JsonKey(name: 'tableCount') this.tableCount = 0,
      this.status = 'created',
      @JsonKey(name: 'playLevel') this.playLevel = 1,
      @JsonKey(name: 'remainTime') this.remainTime,
      this.source = 'api',
      @JsonKey(name: 'syncedAt') this.syncedAt,
      @JsonKey(name: 'createdAt') this.createdAt,
      @JsonKey(name: 'updatedAt') this.updatedAt,
      @JsonKey(name: 'playerCount') this.playerCount});

  factory _$EventFlightImpl.fromJson(Map<String, dynamic> json) =>
      _$$EventFlightImplFromJson(json);

  @override
  @JsonKey(name: 'eventFlightId')
  final int eventFlightId;
  @override
  @JsonKey(name: 'eventId')
  final int eventId;
  @override
  @JsonKey(name: 'displayName')
  final String displayName;
  @override
  @JsonKey(name: 'startTime')
  final String? startTime;
  @override
  @JsonKey(name: 'isTbd')
  final bool isTbd;
  @override
  @JsonKey()
  final int entries;
  @override
  @JsonKey(name: 'playersLeft')
  final int playersLeft;
  @override
  @JsonKey(name: 'tableCount')
  final int tableCount;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey(name: 'playLevel')
  final int playLevel;
  @override
  @JsonKey(name: 'remainTime')
  final int? remainTime;
  @override
  @JsonKey()
  final String source;
  @override
  @JsonKey(name: 'syncedAt')
  final String? syncedAt;
  @override
  @JsonKey(name: 'createdAt')
  final String? createdAt;
  @override
  @JsonKey(name: 'updatedAt')
  final String? updatedAt;
  @override
  @JsonKey(name: 'playerCount')
  final int? playerCount;

  @override
  String toString() {
    return 'EventFlight(eventFlightId: $eventFlightId, eventId: $eventId, displayName: $displayName, startTime: $startTime, isTbd: $isTbd, entries: $entries, playersLeft: $playersLeft, tableCount: $tableCount, status: $status, playLevel: $playLevel, remainTime: $remainTime, source: $source, syncedAt: $syncedAt, createdAt: $createdAt, updatedAt: $updatedAt, playerCount: $playerCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EventFlightImpl &&
            (identical(other.eventFlightId, eventFlightId) ||
                other.eventFlightId == eventFlightId) &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.isTbd, isTbd) || other.isTbd == isTbd) &&
            (identical(other.entries, entries) || other.entries == entries) &&
            (identical(other.playersLeft, playersLeft) ||
                other.playersLeft == playersLeft) &&
            (identical(other.tableCount, tableCount) ||
                other.tableCount == tableCount) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.playLevel, playLevel) ||
                other.playLevel == playLevel) &&
            (identical(other.remainTime, remainTime) ||
                other.remainTime == remainTime) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.syncedAt, syncedAt) ||
                other.syncedAt == syncedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.playerCount, playerCount) ||
                other.playerCount == playerCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      eventFlightId,
      eventId,
      displayName,
      startTime,
      isTbd,
      entries,
      playersLeft,
      tableCount,
      status,
      playLevel,
      remainTime,
      source,
      syncedAt,
      createdAt,
      updatedAt,
      playerCount);

  /// Create a copy of EventFlight
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EventFlightImplCopyWith<_$EventFlightImpl> get copyWith =>
      __$$EventFlightImplCopyWithImpl<_$EventFlightImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EventFlightImplToJson(
      this,
    );
  }
}

abstract class _EventFlight implements EventFlight {
  const factory _EventFlight(
          {@JsonKey(name: 'eventFlightId') required final int eventFlightId,
          @JsonKey(name: 'eventId') required final int eventId,
          @JsonKey(name: 'displayName') final String displayName,
          @JsonKey(name: 'startTime') final String? startTime,
          @JsonKey(name: 'isTbd') final bool isTbd,
          final int entries,
          @JsonKey(name: 'playersLeft') final int playersLeft,
          @JsonKey(name: 'tableCount') final int tableCount,
          final String status,
          @JsonKey(name: 'playLevel') final int playLevel,
          @JsonKey(name: 'remainTime') final int? remainTime,
          final String source,
          @JsonKey(name: 'syncedAt') final String? syncedAt,
          @JsonKey(name: 'createdAt') final String? createdAt,
          @JsonKey(name: 'updatedAt') final String? updatedAt,
          @JsonKey(name: 'playerCount') final int? playerCount}) =
      _$EventFlightImpl;

  factory _EventFlight.fromJson(Map<String, dynamic> json) =
      _$EventFlightImpl.fromJson;

  @override
  @JsonKey(name: 'eventFlightId')
  int get eventFlightId;
  @override
  @JsonKey(name: 'eventId')
  int get eventId;
  @override
  @JsonKey(name: 'displayName')
  String get displayName;
  @override
  @JsonKey(name: 'startTime')
  String? get startTime;
  @override
  @JsonKey(name: 'isTbd')
  bool get isTbd;
  @override
  int get entries;
  @override
  @JsonKey(name: 'playersLeft')
  int get playersLeft;
  @override
  @JsonKey(name: 'tableCount')
  int get tableCount;
  @override
  String get status;
  @override
  @JsonKey(name: 'playLevel')
  int get playLevel;
  @override
  @JsonKey(name: 'remainTime')
  int? get remainTime;
  @override
  String get source;
  @override
  @JsonKey(name: 'syncedAt')
  String? get syncedAt;
  @override
  @JsonKey(name: 'createdAt')
  String? get createdAt;
  @override
  @JsonKey(name: 'updatedAt')
  String? get updatedAt;
  @override
  @JsonKey(name: 'playerCount')
  int? get playerCount;

  /// Create a copy of EventFlight
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EventFlightImplCopyWith<_$EventFlightImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
