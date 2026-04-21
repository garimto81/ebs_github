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
  @JsonKey(name: 'seatId')
  int get seatId => throw _privateConstructorUsedError;
  @JsonKey(name: 'tableId')
  int get tableId => throw _privateConstructorUsedError;
  @JsonKey(name: 'seatNo')
  int get seatNo => throw _privateConstructorUsedError;
  @JsonKey(name: 'playerId')
  int? get playerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'wsopId')
  String? get wsopId => throw _privateConstructorUsedError;
  @JsonKey(name: 'playerName')
  String? get playerName => throw _privateConstructorUsedError;
  String? get nationality => throw _privateConstructorUsedError;
  @JsonKey(name: 'countryCode')
  String? get countryCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'chipCount')
  int get chipCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'profileImage')
  String? get profileImage => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'playerMoveStatus')
  String? get playerMoveStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'createdAt')
  String get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updatedAt')
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
      {@JsonKey(name: 'seatId') int seatId,
      @JsonKey(name: 'tableId') int tableId,
      @JsonKey(name: 'seatNo') int seatNo,
      @JsonKey(name: 'playerId') int? playerId,
      @JsonKey(name: 'wsopId') String? wsopId,
      @JsonKey(name: 'playerName') String? playerName,
      String? nationality,
      @JsonKey(name: 'countryCode') String? countryCode,
      @JsonKey(name: 'chipCount') int chipCount,
      @JsonKey(name: 'profileImage') String? profileImage,
      String status,
      @JsonKey(name: 'playerMoveStatus') String? playerMoveStatus,
      @JsonKey(name: 'createdAt') String createdAt,
      @JsonKey(name: 'updatedAt') String updatedAt});
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
      {@JsonKey(name: 'seatId') int seatId,
      @JsonKey(name: 'tableId') int tableId,
      @JsonKey(name: 'seatNo') int seatNo,
      @JsonKey(name: 'playerId') int? playerId,
      @JsonKey(name: 'wsopId') String? wsopId,
      @JsonKey(name: 'playerName') String? playerName,
      String? nationality,
      @JsonKey(name: 'countryCode') String? countryCode,
      @JsonKey(name: 'chipCount') int chipCount,
      @JsonKey(name: 'profileImage') String? profileImage,
      String status,
      @JsonKey(name: 'playerMoveStatus') String? playerMoveStatus,
      @JsonKey(name: 'createdAt') String createdAt,
      @JsonKey(name: 'updatedAt') String updatedAt});
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
      {@JsonKey(name: 'seatId') required this.seatId,
      @JsonKey(name: 'tableId') required this.tableId,
      @JsonKey(name: 'seatNo') required this.seatNo,
      @JsonKey(name: 'playerId') this.playerId,
      @JsonKey(name: 'wsopId') this.wsopId,
      @JsonKey(name: 'playerName') this.playerName,
      this.nationality,
      @JsonKey(name: 'countryCode') this.countryCode,
      @JsonKey(name: 'chipCount') required this.chipCount,
      @JsonKey(name: 'profileImage') this.profileImage,
      required this.status,
      @JsonKey(name: 'playerMoveStatus') this.playerMoveStatus,
      @JsonKey(name: 'createdAt') required this.createdAt,
      @JsonKey(name: 'updatedAt') required this.updatedAt});

  factory _$TableSeatImpl.fromJson(Map<String, dynamic> json) =>
      _$$TableSeatImplFromJson(json);

  @override
  @JsonKey(name: 'seatId')
  final int seatId;
  @override
  @JsonKey(name: 'tableId')
  final int tableId;
  @override
  @JsonKey(name: 'seatNo')
  final int seatNo;
  @override
  @JsonKey(name: 'playerId')
  final int? playerId;
  @override
  @JsonKey(name: 'wsopId')
  final String? wsopId;
  @override
  @JsonKey(name: 'playerName')
  final String? playerName;
  @override
  final String? nationality;
  @override
  @JsonKey(name: 'countryCode')
  final String? countryCode;
  @override
  @JsonKey(name: 'chipCount')
  final int chipCount;
  @override
  @JsonKey(name: 'profileImage')
  final String? profileImage;
  @override
  final String status;
  @override
  @JsonKey(name: 'playerMoveStatus')
  final String? playerMoveStatus;
  @override
  @JsonKey(name: 'createdAt')
  final String createdAt;
  @override
  @JsonKey(name: 'updatedAt')
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
          {@JsonKey(name: 'seatId') required final int seatId,
          @JsonKey(name: 'tableId') required final int tableId,
          @JsonKey(name: 'seatNo') required final int seatNo,
          @JsonKey(name: 'playerId') final int? playerId,
          @JsonKey(name: 'wsopId') final String? wsopId,
          @JsonKey(name: 'playerName') final String? playerName,
          final String? nationality,
          @JsonKey(name: 'countryCode') final String? countryCode,
          @JsonKey(name: 'chipCount') required final int chipCount,
          @JsonKey(name: 'profileImage') final String? profileImage,
          required final String status,
          @JsonKey(name: 'playerMoveStatus') final String? playerMoveStatus,
          @JsonKey(name: 'createdAt') required final String createdAt,
          @JsonKey(name: 'updatedAt') required final String updatedAt}) =
      _$TableSeatImpl;

  factory _TableSeat.fromJson(Map<String, dynamic> json) =
      _$TableSeatImpl.fromJson;

  @override
  @JsonKey(name: 'seatId')
  int get seatId;
  @override
  @JsonKey(name: 'tableId')
  int get tableId;
  @override
  @JsonKey(name: 'seatNo')
  int get seatNo;
  @override
  @JsonKey(name: 'playerId')
  int? get playerId;
  @override
  @JsonKey(name: 'wsopId')
  String? get wsopId;
  @override
  @JsonKey(name: 'playerName')
  String? get playerName;
  @override
  String? get nationality;
  @override
  @JsonKey(name: 'countryCode')
  String? get countryCode;
  @override
  @JsonKey(name: 'chipCount')
  int get chipCount;
  @override
  @JsonKey(name: 'profileImage')
  String? get profileImage;
  @override
  String get status;
  @override
  @JsonKey(name: 'playerMoveStatus')
  String? get playerMoveStatus;
  @override
  @JsonKey(name: 'createdAt')
  String get createdAt;
  @override
  @JsonKey(name: 'updatedAt')
  String get updatedAt;

  /// Create a copy of TableSeat
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TableSeatImplCopyWith<_$TableSeatImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
