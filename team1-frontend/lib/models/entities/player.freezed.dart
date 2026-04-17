// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Player _$PlayerFromJson(Map<String, dynamic> json) {
  return _Player.fromJson(json);
}

/// @nodoc
mixin _$Player {
  @JsonKey(name: 'player_id')
  int get playerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'wsop_id')
  String? get wsopId => throw _privateConstructorUsedError;
  @JsonKey(name: 'first_name')
  String get firstName => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_name')
  String get lastName => throw _privateConstructorUsedError;
  String? get nationality => throw _privateConstructorUsedError;
  @JsonKey(name: 'country_code')
  String? get countryCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'profile_image')
  String? get profileImage => throw _privateConstructorUsedError;
  @JsonKey(name: 'player_status')
  String get playerStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_demo')
  bool get isDemo => throw _privateConstructorUsedError;
  String get source => throw _privateConstructorUsedError;
  @JsonKey(name: 'synced_at')
  String? get syncedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  String get updatedAt => throw _privateConstructorUsedError;
  int? get stack => throw _privateConstructorUsedError;
  @JsonKey(name: 'table_name')
  String? get tableName => throw _privateConstructorUsedError;
  @JsonKey(name: 'seat_index')
  int? get seatIndex => throw _privateConstructorUsedError;

  /// Serializes this Player to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerCopyWith<Player> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerCopyWith<$Res> {
  factory $PlayerCopyWith(Player value, $Res Function(Player) then) =
      _$PlayerCopyWithImpl<$Res, Player>;
  @useResult
  $Res call(
      {@JsonKey(name: 'player_id') int playerId,
      @JsonKey(name: 'wsop_id') String? wsopId,
      @JsonKey(name: 'first_name') String firstName,
      @JsonKey(name: 'last_name') String lastName,
      String? nationality,
      @JsonKey(name: 'country_code') String? countryCode,
      @JsonKey(name: 'profile_image') String? profileImage,
      @JsonKey(name: 'player_status') String playerStatus,
      @JsonKey(name: 'is_demo') bool isDemo,
      String source,
      @JsonKey(name: 'synced_at') String? syncedAt,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'updated_at') String updatedAt,
      int? stack,
      @JsonKey(name: 'table_name') String? tableName,
      @JsonKey(name: 'seat_index') int? seatIndex});
}

/// @nodoc
class _$PlayerCopyWithImpl<$Res, $Val extends Player>
    implements $PlayerCopyWith<$Res> {
  _$PlayerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? wsopId = freezed,
    Object? firstName = null,
    Object? lastName = null,
    Object? nationality = freezed,
    Object? countryCode = freezed,
    Object? profileImage = freezed,
    Object? playerStatus = null,
    Object? isDemo = null,
    Object? source = null,
    Object? syncedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? stack = freezed,
    Object? tableName = freezed,
    Object? seatIndex = freezed,
  }) {
    return _then(_value.copyWith(
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as int,
      wsopId: freezed == wsopId
          ? _value.wsopId
          : wsopId // ignore: cast_nullable_to_non_nullable
              as String?,
      firstName: null == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String,
      lastName: null == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String,
      nationality: freezed == nationality
          ? _value.nationality
          : nationality // ignore: cast_nullable_to_non_nullable
              as String?,
      countryCode: freezed == countryCode
          ? _value.countryCode
          : countryCode // ignore: cast_nullable_to_non_nullable
              as String?,
      profileImage: freezed == profileImage
          ? _value.profileImage
          : profileImage // ignore: cast_nullable_to_non_nullable
              as String?,
      playerStatus: null == playerStatus
          ? _value.playerStatus
          : playerStatus // ignore: cast_nullable_to_non_nullable
              as String,
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
      stack: freezed == stack
          ? _value.stack
          : stack // ignore: cast_nullable_to_non_nullable
              as int?,
      tableName: freezed == tableName
          ? _value.tableName
          : tableName // ignore: cast_nullable_to_non_nullable
              as String?,
      seatIndex: freezed == seatIndex
          ? _value.seatIndex
          : seatIndex // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlayerImplCopyWith<$Res> implements $PlayerCopyWith<$Res> {
  factory _$$PlayerImplCopyWith(
          _$PlayerImpl value, $Res Function(_$PlayerImpl) then) =
      __$$PlayerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'player_id') int playerId,
      @JsonKey(name: 'wsop_id') String? wsopId,
      @JsonKey(name: 'first_name') String firstName,
      @JsonKey(name: 'last_name') String lastName,
      String? nationality,
      @JsonKey(name: 'country_code') String? countryCode,
      @JsonKey(name: 'profile_image') String? profileImage,
      @JsonKey(name: 'player_status') String playerStatus,
      @JsonKey(name: 'is_demo') bool isDemo,
      String source,
      @JsonKey(name: 'synced_at') String? syncedAt,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'updated_at') String updatedAt,
      int? stack,
      @JsonKey(name: 'table_name') String? tableName,
      @JsonKey(name: 'seat_index') int? seatIndex});
}

/// @nodoc
class __$$PlayerImplCopyWithImpl<$Res>
    extends _$PlayerCopyWithImpl<$Res, _$PlayerImpl>
    implements _$$PlayerImplCopyWith<$Res> {
  __$$PlayerImplCopyWithImpl(
      _$PlayerImpl _value, $Res Function(_$PlayerImpl) _then)
      : super(_value, _then);

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? wsopId = freezed,
    Object? firstName = null,
    Object? lastName = null,
    Object? nationality = freezed,
    Object? countryCode = freezed,
    Object? profileImage = freezed,
    Object? playerStatus = null,
    Object? isDemo = null,
    Object? source = null,
    Object? syncedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? stack = freezed,
    Object? tableName = freezed,
    Object? seatIndex = freezed,
  }) {
    return _then(_$PlayerImpl(
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as int,
      wsopId: freezed == wsopId
          ? _value.wsopId
          : wsopId // ignore: cast_nullable_to_non_nullable
              as String?,
      firstName: null == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String,
      lastName: null == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String,
      nationality: freezed == nationality
          ? _value.nationality
          : nationality // ignore: cast_nullable_to_non_nullable
              as String?,
      countryCode: freezed == countryCode
          ? _value.countryCode
          : countryCode // ignore: cast_nullable_to_non_nullable
              as String?,
      profileImage: freezed == profileImage
          ? _value.profileImage
          : profileImage // ignore: cast_nullable_to_non_nullable
              as String?,
      playerStatus: null == playerStatus
          ? _value.playerStatus
          : playerStatus // ignore: cast_nullable_to_non_nullable
              as String,
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
      stack: freezed == stack
          ? _value.stack
          : stack // ignore: cast_nullable_to_non_nullable
              as int?,
      tableName: freezed == tableName
          ? _value.tableName
          : tableName // ignore: cast_nullable_to_non_nullable
              as String?,
      seatIndex: freezed == seatIndex
          ? _value.seatIndex
          : seatIndex // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayerImpl implements _Player {
  const _$PlayerImpl(
      {@JsonKey(name: 'player_id') required this.playerId,
      @JsonKey(name: 'wsop_id') this.wsopId,
      @JsonKey(name: 'first_name') required this.firstName,
      @JsonKey(name: 'last_name') required this.lastName,
      this.nationality,
      @JsonKey(name: 'country_code') this.countryCode,
      @JsonKey(name: 'profile_image') this.profileImage,
      @JsonKey(name: 'player_status') required this.playerStatus,
      @JsonKey(name: 'is_demo') this.isDemo = false,
      required this.source,
      @JsonKey(name: 'synced_at') this.syncedAt,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt,
      this.stack,
      @JsonKey(name: 'table_name') this.tableName,
      @JsonKey(name: 'seat_index') this.seatIndex});

  factory _$PlayerImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerImplFromJson(json);

  @override
  @JsonKey(name: 'player_id')
  final int playerId;
  @override
  @JsonKey(name: 'wsop_id')
  final String? wsopId;
  @override
  @JsonKey(name: 'first_name')
  final String firstName;
  @override
  @JsonKey(name: 'last_name')
  final String lastName;
  @override
  final String? nationality;
  @override
  @JsonKey(name: 'country_code')
  final String? countryCode;
  @override
  @JsonKey(name: 'profile_image')
  final String? profileImage;
  @override
  @JsonKey(name: 'player_status')
  final String playerStatus;
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
  final int? stack;
  @override
  @JsonKey(name: 'table_name')
  final String? tableName;
  @override
  @JsonKey(name: 'seat_index')
  final int? seatIndex;

  @override
  String toString() {
    return 'Player(playerId: $playerId, wsopId: $wsopId, firstName: $firstName, lastName: $lastName, nationality: $nationality, countryCode: $countryCode, profileImage: $profileImage, playerStatus: $playerStatus, isDemo: $isDemo, source: $source, syncedAt: $syncedAt, createdAt: $createdAt, updatedAt: $updatedAt, stack: $stack, tableName: $tableName, seatIndex: $seatIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerImpl &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.wsopId, wsopId) || other.wsopId == wsopId) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.nationality, nationality) ||
                other.nationality == nationality) &&
            (identical(other.countryCode, countryCode) ||
                other.countryCode == countryCode) &&
            (identical(other.profileImage, profileImage) ||
                other.profileImage == profileImage) &&
            (identical(other.playerStatus, playerStatus) ||
                other.playerStatus == playerStatus) &&
            (identical(other.isDemo, isDemo) || other.isDemo == isDemo) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.syncedAt, syncedAt) ||
                other.syncedAt == syncedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.stack, stack) || other.stack == stack) &&
            (identical(other.tableName, tableName) ||
                other.tableName == tableName) &&
            (identical(other.seatIndex, seatIndex) ||
                other.seatIndex == seatIndex));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      playerId,
      wsopId,
      firstName,
      lastName,
      nationality,
      countryCode,
      profileImage,
      playerStatus,
      isDemo,
      source,
      syncedAt,
      createdAt,
      updatedAt,
      stack,
      tableName,
      seatIndex);

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerImplCopyWith<_$PlayerImpl> get copyWith =>
      __$$PlayerImplCopyWithImpl<_$PlayerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerImplToJson(
      this,
    );
  }
}

abstract class _Player implements Player {
  const factory _Player(
      {@JsonKey(name: 'player_id') required final int playerId,
      @JsonKey(name: 'wsop_id') final String? wsopId,
      @JsonKey(name: 'first_name') required final String firstName,
      @JsonKey(name: 'last_name') required final String lastName,
      final String? nationality,
      @JsonKey(name: 'country_code') final String? countryCode,
      @JsonKey(name: 'profile_image') final String? profileImage,
      @JsonKey(name: 'player_status') required final String playerStatus,
      @JsonKey(name: 'is_demo') final bool isDemo,
      required final String source,
      @JsonKey(name: 'synced_at') final String? syncedAt,
      @JsonKey(name: 'created_at') required final String createdAt,
      @JsonKey(name: 'updated_at') required final String updatedAt,
      final int? stack,
      @JsonKey(name: 'table_name') final String? tableName,
      @JsonKey(name: 'seat_index') final int? seatIndex}) = _$PlayerImpl;

  factory _Player.fromJson(Map<String, dynamic> json) = _$PlayerImpl.fromJson;

  @override
  @JsonKey(name: 'player_id')
  int get playerId;
  @override
  @JsonKey(name: 'wsop_id')
  String? get wsopId;
  @override
  @JsonKey(name: 'first_name')
  String get firstName;
  @override
  @JsonKey(name: 'last_name')
  String get lastName;
  @override
  String? get nationality;
  @override
  @JsonKey(name: 'country_code')
  String? get countryCode;
  @override
  @JsonKey(name: 'profile_image')
  String? get profileImage;
  @override
  @JsonKey(name: 'player_status')
  String get playerStatus;
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
  @override
  int? get stack;
  @override
  @JsonKey(name: 'table_name')
  String? get tableName;
  @override
  @JsonKey(name: 'seat_index')
  int? get seatIndex;

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerImplCopyWith<_$PlayerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
