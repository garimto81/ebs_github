// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SessionUser _$SessionUserFromJson(Map<String, dynamic> json) {
  return _SessionUser.fromJson(json);
}

/// @nodoc
mixin _$SessionUser {
  @JsonKey(name: 'user_id')
  int get userId => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_name')
  String? get displayName => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  Map<String, int> get permissions => throw _privateConstructorUsedError;
  @JsonKey(name: 'table_ids')
  List<int> get tableIds => throw _privateConstructorUsedError;

  /// Serializes this SessionUser to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SessionUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SessionUserCopyWith<SessionUser> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionUserCopyWith<$Res> {
  factory $SessionUserCopyWith(
          SessionUser value, $Res Function(SessionUser) then) =
      _$SessionUserCopyWithImpl<$Res, SessionUser>;
  @useResult
  $Res call(
      {@JsonKey(name: 'user_id') int userId,
      String email,
      @JsonKey(name: 'display_name') String? displayName,
      String role,
      Map<String, int> permissions,
      @JsonKey(name: 'table_ids') List<int> tableIds});
}

/// @nodoc
class _$SessionUserCopyWithImpl<$Res, $Val extends SessionUser>
    implements $SessionUserCopyWith<$Res> {
  _$SessionUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SessionUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? email = null,
    Object? displayName = freezed,
    Object? role = null,
    Object? permissions = null,
    Object? tableIds = null,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      permissions: null == permissions
          ? _value.permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      tableIds: null == tableIds
          ? _value.tableIds
          : tableIds // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SessionUserImplCopyWith<$Res>
    implements $SessionUserCopyWith<$Res> {
  factory _$$SessionUserImplCopyWith(
          _$SessionUserImpl value, $Res Function(_$SessionUserImpl) then) =
      __$$SessionUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'user_id') int userId,
      String email,
      @JsonKey(name: 'display_name') String? displayName,
      String role,
      Map<String, int> permissions,
      @JsonKey(name: 'table_ids') List<int> tableIds});
}

/// @nodoc
class __$$SessionUserImplCopyWithImpl<$Res>
    extends _$SessionUserCopyWithImpl<$Res, _$SessionUserImpl>
    implements _$$SessionUserImplCopyWith<$Res> {
  __$$SessionUserImplCopyWithImpl(
      _$SessionUserImpl _value, $Res Function(_$SessionUserImpl) _then)
      : super(_value, _then);

  /// Create a copy of SessionUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? email = null,
    Object? displayName = freezed,
    Object? role = null,
    Object? permissions = null,
    Object? tableIds = null,
  }) {
    return _then(_$SessionUserImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      permissions: null == permissions
          ? _value._permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      tableIds: null == tableIds
          ? _value._tableIds
          : tableIds // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SessionUserImpl implements _SessionUser {
  const _$SessionUserImpl(
      {@JsonKey(name: 'user_id') required this.userId,
      required this.email,
      @JsonKey(name: 'display_name') this.displayName,
      required this.role,
      final Map<String, int> permissions = const {},
      @JsonKey(name: 'table_ids') final List<int> tableIds = const []})
      : _permissions = permissions,
        _tableIds = tableIds;

  factory _$SessionUserImpl.fromJson(Map<String, dynamic> json) =>
      _$$SessionUserImplFromJson(json);

  @override
  @JsonKey(name: 'user_id')
  final int userId;
  @override
  final String email;
  @override
  @JsonKey(name: 'display_name')
  final String? displayName;
  @override
  final String role;
  final Map<String, int> _permissions;
  @override
  @JsonKey()
  Map<String, int> get permissions {
    if (_permissions is EqualUnmodifiableMapView) return _permissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_permissions);
  }

  final List<int> _tableIds;
  @override
  @JsonKey(name: 'table_ids')
  List<int> get tableIds {
    if (_tableIds is EqualUnmodifiableListView) return _tableIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tableIds);
  }

  @override
  String toString() {
    return 'SessionUser(userId: $userId, email: $email, displayName: $displayName, role: $role, permissions: $permissions, tableIds: $tableIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionUserImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.role, role) || other.role == role) &&
            const DeepCollectionEquality()
                .equals(other._permissions, _permissions) &&
            const DeepCollectionEquality().equals(other._tableIds, _tableIds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      email,
      displayName,
      role,
      const DeepCollectionEquality().hash(_permissions),
      const DeepCollectionEquality().hash(_tableIds));

  /// Create a copy of SessionUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionUserImplCopyWith<_$SessionUserImpl> get copyWith =>
      __$$SessionUserImplCopyWithImpl<_$SessionUserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SessionUserImplToJson(
      this,
    );
  }
}

abstract class _SessionUser implements SessionUser {
  const factory _SessionUser(
          {@JsonKey(name: 'user_id') required final int userId,
          required final String email,
          @JsonKey(name: 'display_name') final String? displayName,
          required final String role,
          final Map<String, int> permissions,
          @JsonKey(name: 'table_ids') final List<int> tableIds}) =
      _$SessionUserImpl;

  factory _SessionUser.fromJson(Map<String, dynamic> json) =
      _$SessionUserImpl.fromJson;

  @override
  @JsonKey(name: 'user_id')
  int get userId;
  @override
  String get email;
  @override
  @JsonKey(name: 'display_name')
  String? get displayName;
  @override
  String get role;
  @override
  Map<String, int> get permissions;
  @override
  @JsonKey(name: 'table_ids')
  List<int> get tableIds;

  /// Create a copy of SessionUser
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SessionUserImplCopyWith<_$SessionUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
