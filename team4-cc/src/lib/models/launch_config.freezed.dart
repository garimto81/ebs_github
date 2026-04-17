// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'launch_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$LaunchConfig {
  int get tableId => throw _privateConstructorUsedError;
  String get token => throw _privateConstructorUsedError; // JWT launch token
  String get ccInstanceId => throw _privateConstructorUsedError; // UUID
  String get wsUrl => throw _privateConstructorUsedError; // ws://host/ws/cc
  String get boBaseUrl =>
      throw _privateConstructorUsedError; // REST API base URL
  String get engineUrl =>
      throw _privateConstructorUsedError; // Game Engine harness
  bool get demoMode => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $LaunchConfigCopyWith<LaunchConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LaunchConfigCopyWith<$Res> {
  factory $LaunchConfigCopyWith(
          LaunchConfig value, $Res Function(LaunchConfig) then) =
      _$LaunchConfigCopyWithImpl<$Res, LaunchConfig>;
  @useResult
  $Res call(
      {int tableId,
      String token,
      String ccInstanceId,
      String wsUrl,
      String boBaseUrl,
      String engineUrl,
      bool demoMode});
}

/// @nodoc
class _$LaunchConfigCopyWithImpl<$Res, $Val extends LaunchConfig>
    implements $LaunchConfigCopyWith<$Res> {
  _$LaunchConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tableId = null,
    Object? token = null,
    Object? ccInstanceId = null,
    Object? wsUrl = null,
    Object? boBaseUrl = null,
    Object? engineUrl = null,
    Object? demoMode = null,
  }) {
    return _then(_value.copyWith(
      tableId: null == tableId
          ? _value.tableId
          : tableId // ignore: cast_nullable_to_non_nullable
              as int,
      token: null == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String,
      ccInstanceId: null == ccInstanceId
          ? _value.ccInstanceId
          : ccInstanceId // ignore: cast_nullable_to_non_nullable
              as String,
      wsUrl: null == wsUrl
          ? _value.wsUrl
          : wsUrl // ignore: cast_nullable_to_non_nullable
              as String,
      boBaseUrl: null == boBaseUrl
          ? _value.boBaseUrl
          : boBaseUrl // ignore: cast_nullable_to_non_nullable
              as String,
      engineUrl: null == engineUrl
          ? _value.engineUrl
          : engineUrl // ignore: cast_nullable_to_non_nullable
              as String,
      demoMode: null == demoMode
          ? _value.demoMode
          : demoMode // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LaunchConfigImplCopyWith<$Res>
    implements $LaunchConfigCopyWith<$Res> {
  factory _$$LaunchConfigImplCopyWith(
          _$LaunchConfigImpl value, $Res Function(_$LaunchConfigImpl) then) =
      __$$LaunchConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int tableId,
      String token,
      String ccInstanceId,
      String wsUrl,
      String boBaseUrl,
      String engineUrl,
      bool demoMode});
}

/// @nodoc
class __$$LaunchConfigImplCopyWithImpl<$Res>
    extends _$LaunchConfigCopyWithImpl<$Res, _$LaunchConfigImpl>
    implements _$$LaunchConfigImplCopyWith<$Res> {
  __$$LaunchConfigImplCopyWithImpl(
      _$LaunchConfigImpl _value, $Res Function(_$LaunchConfigImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tableId = null,
    Object? token = null,
    Object? ccInstanceId = null,
    Object? wsUrl = null,
    Object? boBaseUrl = null,
    Object? engineUrl = null,
    Object? demoMode = null,
  }) {
    return _then(_$LaunchConfigImpl(
      tableId: null == tableId
          ? _value.tableId
          : tableId // ignore: cast_nullable_to_non_nullable
              as int,
      token: null == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String,
      ccInstanceId: null == ccInstanceId
          ? _value.ccInstanceId
          : ccInstanceId // ignore: cast_nullable_to_non_nullable
              as String,
      wsUrl: null == wsUrl
          ? _value.wsUrl
          : wsUrl // ignore: cast_nullable_to_non_nullable
              as String,
      boBaseUrl: null == boBaseUrl
          ? _value.boBaseUrl
          : boBaseUrl // ignore: cast_nullable_to_non_nullable
              as String,
      engineUrl: null == engineUrl
          ? _value.engineUrl
          : engineUrl // ignore: cast_nullable_to_non_nullable
              as String,
      demoMode: null == demoMode
          ? _value.demoMode
          : demoMode // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$LaunchConfigImpl implements _LaunchConfig {
  const _$LaunchConfigImpl(
      {required this.tableId,
      required this.token,
      required this.ccInstanceId,
      required this.wsUrl,
      this.boBaseUrl = 'http://localhost:8000',
      this.engineUrl = 'http://localhost:8080',
      this.demoMode = false});

  @override
  final int tableId;
  @override
  final String token;
// JWT launch token
  @override
  final String ccInstanceId;
// UUID
  @override
  final String wsUrl;
// ws://host/ws/cc
  @override
  @JsonKey()
  final String boBaseUrl;
// REST API base URL
  @override
  @JsonKey()
  final String engineUrl;
// Game Engine harness
  @override
  @JsonKey()
  final bool demoMode;

  @override
  String toString() {
    return 'LaunchConfig(tableId: $tableId, token: $token, ccInstanceId: $ccInstanceId, wsUrl: $wsUrl, boBaseUrl: $boBaseUrl, engineUrl: $engineUrl, demoMode: $demoMode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LaunchConfigImpl &&
            (identical(other.tableId, tableId) || other.tableId == tableId) &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.ccInstanceId, ccInstanceId) ||
                other.ccInstanceId == ccInstanceId) &&
            (identical(other.wsUrl, wsUrl) || other.wsUrl == wsUrl) &&
            (identical(other.boBaseUrl, boBaseUrl) ||
                other.boBaseUrl == boBaseUrl) &&
            (identical(other.engineUrl, engineUrl) ||
                other.engineUrl == engineUrl) &&
            (identical(other.demoMode, demoMode) ||
                other.demoMode == demoMode));
  }

  @override
  int get hashCode => Object.hash(runtimeType, tableId, token, ccInstanceId,
      wsUrl, boBaseUrl, engineUrl, demoMode);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LaunchConfigImplCopyWith<_$LaunchConfigImpl> get copyWith =>
      __$$LaunchConfigImplCopyWithImpl<_$LaunchConfigImpl>(this, _$identity);
}

abstract class _LaunchConfig implements LaunchConfig {
  const factory _LaunchConfig(
      {required final int tableId,
      required final String token,
      required final String ccInstanceId,
      required final String wsUrl,
      final String boBaseUrl,
      final String engineUrl,
      final bool demoMode}) = _$LaunchConfigImpl;

  @override
  int get tableId;
  @override
  String get token;
  @override // JWT launch token
  String get ccInstanceId;
  @override // UUID
  String get wsUrl;
  @override // ws://host/ws/cc
  String get boBaseUrl;
  @override // REST API base URL
  String get engineUrl;
  @override // Game Engine harness
  bool get demoMode;
  @override
  @JsonKey(ignore: true)
  _$$LaunchConfigImplCopyWith<_$LaunchConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
