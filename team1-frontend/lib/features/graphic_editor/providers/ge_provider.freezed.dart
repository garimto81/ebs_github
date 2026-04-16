// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ge_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SkinUploadState {
  SkinUploadStatus get status => throw _privateConstructorUsedError;
  double get progress => throw _privateConstructorUsedError;
  List<String> get validationErrors => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of SkinUploadState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SkinUploadStateCopyWith<SkinUploadState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SkinUploadStateCopyWith<$Res> {
  factory $SkinUploadStateCopyWith(
          SkinUploadState value, $Res Function(SkinUploadState) then) =
      _$SkinUploadStateCopyWithImpl<$Res, SkinUploadState>;
  @useResult
  $Res call(
      {SkinUploadStatus status,
      double progress,
      List<String> validationErrors,
      String? error});
}

/// @nodoc
class _$SkinUploadStateCopyWithImpl<$Res, $Val extends SkinUploadState>
    implements $SkinUploadStateCopyWith<$Res> {
  _$SkinUploadStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SkinUploadState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? progress = null,
    Object? validationErrors = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SkinUploadStatus,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      validationErrors: null == validationErrors
          ? _value.validationErrors
          : validationErrors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SkinUploadStateImplCopyWith<$Res>
    implements $SkinUploadStateCopyWith<$Res> {
  factory _$$SkinUploadStateImplCopyWith(_$SkinUploadStateImpl value,
          $Res Function(_$SkinUploadStateImpl) then) =
      __$$SkinUploadStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {SkinUploadStatus status,
      double progress,
      List<String> validationErrors,
      String? error});
}

/// @nodoc
class __$$SkinUploadStateImplCopyWithImpl<$Res>
    extends _$SkinUploadStateCopyWithImpl<$Res, _$SkinUploadStateImpl>
    implements _$$SkinUploadStateImplCopyWith<$Res> {
  __$$SkinUploadStateImplCopyWithImpl(
      _$SkinUploadStateImpl _value, $Res Function(_$SkinUploadStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of SkinUploadState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? progress = null,
    Object? validationErrors = null,
    Object? error = freezed,
  }) {
    return _then(_$SkinUploadStateImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SkinUploadStatus,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      validationErrors: null == validationErrors
          ? _value._validationErrors
          : validationErrors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$SkinUploadStateImpl implements _SkinUploadState {
  const _$SkinUploadStateImpl(
      {this.status = SkinUploadStatus.idle,
      this.progress = 0,
      final List<String> validationErrors = const [],
      this.error})
      : _validationErrors = validationErrors;

  @override
  @JsonKey()
  final SkinUploadStatus status;
  @override
  @JsonKey()
  final double progress;
  final List<String> _validationErrors;
  @override
  @JsonKey()
  List<String> get validationErrors {
    if (_validationErrors is EqualUnmodifiableListView)
      return _validationErrors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_validationErrors);
  }

  @override
  final String? error;

  @override
  String toString() {
    return 'SkinUploadState(status: $status, progress: $progress, validationErrors: $validationErrors, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SkinUploadStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            const DeepCollectionEquality()
                .equals(other._validationErrors, _validationErrors) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, status, progress,
      const DeepCollectionEquality().hash(_validationErrors), error);

  /// Create a copy of SkinUploadState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SkinUploadStateImplCopyWith<_$SkinUploadStateImpl> get copyWith =>
      __$$SkinUploadStateImplCopyWithImpl<_$SkinUploadStateImpl>(
          this, _$identity);
}

abstract class _SkinUploadState implements SkinUploadState {
  const factory _SkinUploadState(
      {final SkinUploadStatus status,
      final double progress,
      final List<String> validationErrors,
      final String? error}) = _$SkinUploadStateImpl;

  @override
  SkinUploadStatus get status;
  @override
  double get progress;
  @override
  List<String> get validationErrors;
  @override
  String? get error;

  /// Create a copy of SkinUploadState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SkinUploadStateImplCopyWith<_$SkinUploadStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
