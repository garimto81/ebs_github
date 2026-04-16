// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AuthState {
  AuthStatus get status => throw _privateConstructorUsedError;
  LaunchConfig? get config => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  String? get role =>
      throw _privateConstructorUsedError; // Admin | Operator | Viewer
  List<int>? get assignedTables => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AuthStateCopyWith<AuthState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthStateCopyWith<$Res> {
  factory $AuthStateCopyWith(AuthState value, $Res Function(AuthState) then) =
      _$AuthStateCopyWithImpl<$Res, AuthState>;
  @useResult
  $Res call(
      {AuthStatus status,
      LaunchConfig? config,
      String? errorMessage,
      String? role,
      List<int>? assignedTables});

  $LaunchConfigCopyWith<$Res>? get config;
}

/// @nodoc
class _$AuthStateCopyWithImpl<$Res, $Val extends AuthState>
    implements $AuthStateCopyWith<$Res> {
  _$AuthStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? config = freezed,
    Object? errorMessage = freezed,
    Object? role = freezed,
    Object? assignedTables = freezed,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as AuthStatus,
      config: freezed == config
          ? _value.config
          : config // ignore: cast_nullable_to_non_nullable
              as LaunchConfig?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      role: freezed == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String?,
      assignedTables: freezed == assignedTables
          ? _value.assignedTables
          : assignedTables // ignore: cast_nullable_to_non_nullable
              as List<int>?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $LaunchConfigCopyWith<$Res>? get config {
    if (_value.config == null) {
      return null;
    }

    return $LaunchConfigCopyWith<$Res>(_value.config!, (value) {
      return _then(_value.copyWith(config: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AuthStateImplCopyWith<$Res>
    implements $AuthStateCopyWith<$Res> {
  factory _$$AuthStateImplCopyWith(
          _$AuthStateImpl value, $Res Function(_$AuthStateImpl) then) =
      __$$AuthStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {AuthStatus status,
      LaunchConfig? config,
      String? errorMessage,
      String? role,
      List<int>? assignedTables});

  @override
  $LaunchConfigCopyWith<$Res>? get config;
}

/// @nodoc
class __$$AuthStateImplCopyWithImpl<$Res>
    extends _$AuthStateCopyWithImpl<$Res, _$AuthStateImpl>
    implements _$$AuthStateImplCopyWith<$Res> {
  __$$AuthStateImplCopyWithImpl(
      _$AuthStateImpl _value, $Res Function(_$AuthStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? config = freezed,
    Object? errorMessage = freezed,
    Object? role = freezed,
    Object? assignedTables = freezed,
  }) {
    return _then(_$AuthStateImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as AuthStatus,
      config: freezed == config
          ? _value.config
          : config // ignore: cast_nullable_to_non_nullable
              as LaunchConfig?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      role: freezed == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String?,
      assignedTables: freezed == assignedTables
          ? _value._assignedTables
          : assignedTables // ignore: cast_nullable_to_non_nullable
              as List<int>?,
    ));
  }
}

/// @nodoc

class _$AuthStateImpl implements _AuthState {
  const _$AuthStateImpl(
      {this.status = AuthStatus.unauthenticated,
      this.config,
      this.errorMessage,
      this.role,
      final List<int>? assignedTables})
      : _assignedTables = assignedTables;

  @override
  @JsonKey()
  final AuthStatus status;
  @override
  final LaunchConfig? config;
  @override
  final String? errorMessage;
  @override
  final String? role;
// Admin | Operator | Viewer
  final List<int>? _assignedTables;
// Admin | Operator | Viewer
  @override
  List<int>? get assignedTables {
    final value = _assignedTables;
    if (value == null) return null;
    if (_assignedTables is EqualUnmodifiableListView) return _assignedTables;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'AuthState(status: $status, config: $config, errorMessage: $errorMessage, role: $role, assignedTables: $assignedTables)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.config, config) || other.config == config) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.role, role) || other.role == role) &&
            const DeepCollectionEquality()
                .equals(other._assignedTables, _assignedTables));
  }

  @override
  int get hashCode => Object.hash(runtimeType, status, config, errorMessage,
      role, const DeepCollectionEquality().hash(_assignedTables));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthStateImplCopyWith<_$AuthStateImpl> get copyWith =>
      __$$AuthStateImplCopyWithImpl<_$AuthStateImpl>(this, _$identity);
}

abstract class _AuthState implements AuthState {
  const factory _AuthState(
      {final AuthStatus status,
      final LaunchConfig? config,
      final String? errorMessage,
      final String? role,
      final List<int>? assignedTables}) = _$AuthStateImpl;

  @override
  AuthStatus get status;
  @override
  LaunchConfig? get config;
  @override
  String? get errorMessage;
  @override
  String? get role;
  @override // Admin | Operator | Viewer
  List<int>? get assignedTables;
  @override
  @JsonKey(ignore: true)
  _$$AuthStateImplCopyWith<_$AuthStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
