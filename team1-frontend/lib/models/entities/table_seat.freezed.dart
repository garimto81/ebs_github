// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'table_seat.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TableSeat _$TableSeatFromJson(Map<String, dynamic> json) {
  return _TableSeat.fromJson(json);
}

/// @nodoc
mixin _$TableSeat {
  @JsonKey(name: 'seat_id')
  int get seatId => throw _privateConstructorUsedError;
  @JsonKey(name: 'table_id')
  int get tableId => throw _privateConstructorUsedError;
  @JsonKey(name: 'seat_no')
  int get seatNo => throw _privateConstructorUsedError;
  @JsonKey(name: 'player_id')
  int? get playerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'wsop_id')
  String? get wsopId => throw _privateConstructorUsedError;
  @JsonKey(name: 'player_name')
  String? get playerName => throw _privateConstructorUsedError;
  String? get nationality => throw _privateConstructorUsedError;
  @JsonKey(name: 'country_code')
  String? get countryCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'chip_count')
  int get chipCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'profile_image')
  String? get profileImage => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'player_move_status')
  String? get playerMoveStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  String get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this TableSeat to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TableSeat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TableSeatCopyWith<TableSeat> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TableSeatCopyWith<$Res> {
  factory $TableSeatCopyWith(TableSeat value, $Res Function(TableSeat) then) =
      _$TableSeatCopyWithImpl<$Res, TableSeat>;
  @useResult
  $Res call(
      {@JsonKey(name: 'seat_id') int seatId,
      @JsonKey(name: 'table_id') int tableId,
      @JsonKey(name: 'seat_no') int seatNo,
      @JsonKey(name: 'player_id') int? playerId,
      @JsonKey(name: 'wsop_id') String? wsopId,
      @JsonKey(name: 'player_name') String? playerName,
      String? nationality,
      @JsonKey(name: 'country_code') String? countryCode,
      @JsonKey(name: 'chip_count') int chipCount,
      @JsonKey(name: 'profile_image') String? profileImage,
      String status,
      @JsonKey(name: 'player_move_status') String? playerMoveStatus,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'updated_at') String updatedAt});
}

/// @nodoc
class _$TableSeatCopyWithImpl<$Res, $Val extends TableSeat>
    implements $TableSeatCopyWith<$Res> {
  _$TableSeatCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TableSeat
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seatId = null,
    Object? tableId = null,
    Object? seatNo = null,
    Object? playerId = freezed,
    Object? wsopId = freezed,
    Object? playerName = freezed,
    Object? nationality = freezed,
    Object? countryCode = freezed,
    Object? chipCount = null,
    Object? profileImage = freezed,
    Object? status = null,
    Object? playerMoveStatus = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      seatId: null == seatId
          ? _value.seatId
          : seatId // ignore: cast_nullable_to_non_nullable
              as int,
      tableId: null == tableId
          ? _value.tableId
          : tableId // ignore: cast_nullable_to_non_nullable
              as int,
      seatNo: null == seatNo
          ? _value.seatNo
          : seatNo // ignore: cast_nullable_to_non_nullable
              as int,
      playerId: freezed == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as int?,
      wsopId: freezed == wsopId
          ? _value.wsopId
          : wsopId // ignore: cast_nullable_to_non_nullable
              as String?,
      playerName: freezed == playerName
          ? _value.playerName
          : playerName // ignore: cast_nullable_to_non_nullable
              as String?,
      nationality: freezed == nationality
          ? _value.nationality
          : nationality // ignore: cast_nullable_to_non_nullable
              as String?,
      countryCode: freezed == countryCode
          ? _value.countryCode
          : countryCode // ignore: cast_nullable_to_non_nullable
              as String?,
      chipCount: null == chipCount
          ? _value.chipCount
          : chipCount // ignore: cast_nullable_to_non_nullable
              as int,
      profileImage: freezed == profileImage
          ? _value.profileImage
          : profileImage // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      playerMoveStatus: freezed == playerMoveStatus
          ? _value.playerMoveStatus
          : playerMoveStatus // ignore: cast_nullable_to_non_nullable
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
abstract class _$$TableSeatImplCopyWith<$Res>
    implements $TableSeatCopyWith<$Res> {
  factory _$$TableSeatImplCopyWith(
          _$TableSeatImpl value, $Res Function(_$TableSeatImpl) then) =
      __$$TableSeatImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'seat_id') int seatId,
      @JsonKey(name: 'table_id') int tableId,
      @JsonKey(name: 'seat_no') int seatNo,
      @JsonKey(name: 'player_id') int? playerId,
      @JsonKey(name: 'wsop_id') String? wsopId,
      @JsonKey(name: 'player_name') String? playerName,
      String? nationality,
      @JsonKey(name: 'country_code') String? countryCode,
      @JsonKey(name: 'chip_count') int chipCount,
      @JsonKey(name: 'profile_image') String? profileImage,
      String status,
      @JsonKey(name: 'player_move_status') String? playerMoveStatus,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'updated_at') String updatedAt});
}

/// @nodoc
class __$$TableSeatImplCopyWithImpl<$Res>
    extends _$TableSeatCopyWithImpl<$Res, _$TableSeatImpl>
    implements _$$TableSeatImplCopyWith<$Res> {
  __$$TableSeatImplCopyWithImpl(
      _$TableSeatImpl _value, $Res Function(_$TableSeatImpl) _then)
      : super(_value, _then);

  /// Create a copy of TableSeat
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seatId = null,
    Object? tableId = null,
    Object? seatNo = null,
    Object? playerId = freezed,
    Object? wsopId = freezed,
    Object? playerName = freezed,
    Object? nationality = freezed,
    Object? countryCode = freezed,
    Object? chipCount = null,
    Object? profileImage = freezed,
    Object? status = null,
    Object? playerMoveStatus = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$TableSeatImpl(
      seatId: null == seatId
          ? _value.seatId
          : seatId // ignore: cast_nullable_to_non_nullable
              as int,
      tableId: null == tableId
          ? _value.tableId
          : tableId // ignore: cast_nullable_to_non_nullable
              as int,
      seatNo: null == seatNo
          ? _value.seatNo
          : seatNo // ignore: cast_nullable_to_non_nullable
              as int,
      playerId: freezed == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as int?,
      wsopId: freezed == wsopId
          ? _value.wsopId
          : wsopId // ignore: cast_nullable_to_non_nullable
              as String?,
      playerName: freezed == playerName
          ? _value.playerName
          : playerName // ignore: cast_nullable_to_non_nullable
              as String?,
      nationality: freezed == nationality
          ? _value.nationality
          : nationality // ignore: cast_nullable_to_non_nullable
              as String?,
      countryCode: freezed == countryCode
          ? _value.countryCode
          : countryCode // ignore: cast_nullable_to_non_nullable
              as String?,
      chipCount: null == chipCount
          ? _value.chipCount
          : chipCount // ignore: cast_nullable_to_non_nullable
              as int,
      profileImage: freezed == profileImage
          ? _value.profileImage
          : profileImage // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      playerMoveStatus: freezed == playerMoveStatus
          ? _value.playerMoveStatus
          : playerMoveStatus // ignore: cast_nullable_to_non_nullable
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
class _$TableSeatImpl implements _TableSeat {
  const _$TableSeatImpl(
      {@JsonKey(name: 'seat_id') required this.seatId,
      @JsonKey(name: 'table_id') required this.tableId,
      @JsonKey(name: 'seat_no') required this.seatNo,
      @JsonKey(name: 'player_id') this.playerId,
      @JsonKey(name: 'wsop_id') this.wsopId,
      @JsonKey(name: 'player_name') this.playerName,
      this.nationality,
      @JsonKey(name: 'country_code') this.countryCode,
      @JsonKey(name: 'chip_count') required this.chipCount,
      @JsonKey(name: 'profile_image') this.profileImage,
      required this.status,
      @JsonKey(name: 'player_move_status') this.playerMoveStatus,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt});

  factory _$TableSeatImpl.fromJson(Map<String, dynamic> json) =>
      _$$TableSeatImplFromJson(json);

  @override
  @JsonKey(name: 'seat_id')
  final int seatId;
  @override
  @JsonKey(name: 'table_id')
  final int tableId;
  @override
  @JsonKey(name: 'seat_no')
  final int seatNo;
  @override
  @JsonKey(name: 'player_id')
  final int? playerId;
  @override
  @JsonKey(name: 'wsop_id')
  final String? wsopId;
  @override
  @JsonKey(name: 'player_name')
  final String? playerName;
  @override
  final String? nationality;
  @override
  @JsonKey(name: 'country_code')
  final String? countryCode;
  @override
  @JsonKey(name: 'chip_count')
  final int chipCount;
  @override
  @JsonKey(name: 'profile_image')
  final String? profileImage;
  @override
  final String status;
  @override
  @JsonKey(name: 'player_move_status')
  final String? playerMoveStatus;
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  @override
  String toString() {
    return 'TableSeat(seatId: $seatId, tableId: $tableId, seatNo: $seatNo, playerId: $playerId, wsopId: $wsopId, playerName: $playerName, nationality: $nationality, countryCode: $countryCode, chipCount: $chipCount, profileImage: $profileImage, status: $status, playerMoveStatus: $playerMoveStatus, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TableSeatImpl &&
            (identical(other.seatId, seatId) || other.seatId == seatId) &&
            (identical(other.tableId, tableId) || other.tableId == tableId) &&
            (identical(other.seatNo, seatNo) || other.seatNo == seatNo) &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.wsopId, wsopId) || other.wsopId == wsopId) &&
            (identical(other.playerName, playerName) ||
                other.playerName == playerName) &&
            (identical(other.nationality, nationality) ||
                other.nationality == nationality) &&
            (identical(other.countryCode, countryCode) ||
                other.countryCode == countryCode) &&
            (identical(other.chipCount, chipCount) ||
                other.chipCount == chipCount) &&
            (identical(other.profileImage, profileImage) ||
                other.profileImage == profileImage) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.playerMoveStatus, playerMoveStatus) ||
                other.playerMoveStatus == playerMoveStatus) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      seatId,
      tableId,
      seatNo,
      playerId,
      wsopId,
      playerName,
      nationality,
      countryCode,
      chipCount,
      profileImage,
      status,
      playerMoveStatus,
      createdAt,
      updatedAt);

  /// Create a copy of TableSeat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TableSeatImplCopyWith<_$TableSeatImpl> get copyWith =>
      __$$TableSeatImplCopyWithImpl<_$TableSeatImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TableSeatImplToJson(
      this,
    );
  }
}

abstract class _TableSeat implements TableSeat {
  const factory _TableSeat(
          {@JsonKey(name: 'seat_id') required final int seatId,
          @JsonKey(name: 'table_id') required final int tableId,
          @JsonKey(name: 'seat_no') required final int seatNo,
          @JsonKey(name: 'player_id') final int? playerId,
          @JsonKey(name: 'wsop_id') final String? wsopId,
          @JsonKey(name: 'player_name') final String? playerName,
          final String? nationality,
          @JsonKey(name: 'country_code') final String? countryCode,
          @JsonKey(name: 'chip_count') required final int chipCount,
          @JsonKey(name: 'profile_image') final String? profileImage,
          required final String status,
          @JsonKey(name: 'player_move_status') final String? playerMoveStatus,
          @JsonKey(name: 'created_at') required final String createdAt,
          @JsonKey(name: 'updated_at') required final String updatedAt}) =
      _$TableSeatImpl;

  factory _TableSeat.fromJson(Map<String, dynamic> json) =
      _$TableSeatImpl.fromJson;

  @override
  @JsonKey(name: 'seat_id')
  int get seatId;
  @override
  @JsonKey(name: 'table_id')
  int get tableId;
  @override
  @JsonKey(name: 'seat_no')
  int get seatNo;
  @override
  @JsonKey(name: 'player_id')
  int? get playerId;
  @override
  @JsonKey(name: 'wsop_id')
  String? get wsopId;
  @override
  @JsonKey(name: 'player_name')
  String? get playerName;
  @override
  String? get nationality;
  @override
  @JsonKey(name: 'country_code')
  String? get countryCode;
  @override
  @JsonKey(name: 'chip_count')
  int get chipCount;
  @override
  @JsonKey(name: 'profile_image')
  String? get profileImage;
  @override
  String get status;
  @override
  @JsonKey(name: 'player_move_status')
  String? get playerMoveStatus;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  String get updatedAt;

  /// Create a copy of TableSeat
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TableSeatImplCopyWith<_$TableSeatImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
