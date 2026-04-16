// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SettingsSectionState {
  SettingsSection get section => throw _privateConstructorUsedError;
  Map<String, dynamic> get committed => throw _privateConstructorUsedError;
  Map<String, dynamic> get draft => throw _privateConstructorUsedError;
  bool get isDirty => throw _privateConstructorUsedError;
  bool get isSaving => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of SettingsSectionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SettingsSectionStateCopyWith<SettingsSectionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SettingsSectionStateCopyWith<$Res> {
  factory $SettingsSectionStateCopyWith(SettingsSectionState value,
          $Res Function(SettingsSectionState) then) =
      _$SettingsSectionStateCopyWithImpl<$Res, SettingsSectionState>;
  @useResult
  $Res call(
      {SettingsSection section,
      Map<String, dynamic> committed,
      Map<String, dynamic> draft,
      bool isDirty,
      bool isSaving,
      bool isLoading,
      String? error});
}

/// @nodoc
class _$SettingsSectionStateCopyWithImpl<$Res,
        $Val extends SettingsSectionState>
    implements $SettingsSectionStateCopyWith<$Res> {
  _$SettingsSectionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SettingsSectionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? section = null,
    Object? committed = null,
    Object? draft = null,
    Object? isDirty = null,
    Object? isSaving = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      section: null == section
          ? _value.section
          : section // ignore: cast_nullable_to_non_nullable
              as SettingsSection,
      committed: null == committed
          ? _value.committed
          : committed // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      draft: null == draft
          ? _value.draft
          : draft // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      isDirty: null == isDirty
          ? _value.isDirty
          : isDirty // ignore: cast_nullable_to_non_nullable
              as bool,
      isSaving: null == isSaving
          ? _value.isSaving
          : isSaving // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SettingsSectionStateImplCopyWith<$Res>
    implements $SettingsSectionStateCopyWith<$Res> {
  factory _$$SettingsSectionStateImplCopyWith(_$SettingsSectionStateImpl value,
          $Res Function(_$SettingsSectionStateImpl) then) =
      __$$SettingsSectionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {SettingsSection section,
      Map<String, dynamic> committed,
      Map<String, dynamic> draft,
      bool isDirty,
      bool isSaving,
      bool isLoading,
      String? error});
}

/// @nodoc
class __$$SettingsSectionStateImplCopyWithImpl<$Res>
    extends _$SettingsSectionStateCopyWithImpl<$Res, _$SettingsSectionStateImpl>
    implements _$$SettingsSectionStateImplCopyWith<$Res> {
  __$$SettingsSectionStateImplCopyWithImpl(_$SettingsSectionStateImpl _value,
      $Res Function(_$SettingsSectionStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of SettingsSectionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? section = null,
    Object? committed = null,
    Object? draft = null,
    Object? isDirty = null,
    Object? isSaving = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_$SettingsSectionStateImpl(
      section: null == section
          ? _value.section
          : section // ignore: cast_nullable_to_non_nullable
              as SettingsSection,
      committed: null == committed
          ? _value._committed
          : committed // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      draft: null == draft
          ? _value._draft
          : draft // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      isDirty: null == isDirty
          ? _value.isDirty
          : isDirty // ignore: cast_nullable_to_non_nullable
              as bool,
      isSaving: null == isSaving
          ? _value.isSaving
          : isSaving // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$SettingsSectionStateImpl
    with DiagnosticableTreeMixin
    implements _SettingsSectionState {
  const _$SettingsSectionStateImpl(
      {required this.section,
      final Map<String, dynamic> committed = const {},
      final Map<String, dynamic> draft = const {},
      this.isDirty = false,
      this.isSaving = false,
      this.isLoading = false,
      this.error})
      : _committed = committed,
        _draft = draft;

  @override
  final SettingsSection section;
  final Map<String, dynamic> _committed;
  @override
  @JsonKey()
  Map<String, dynamic> get committed {
    if (_committed is EqualUnmodifiableMapView) return _committed;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_committed);
  }

  final Map<String, dynamic> _draft;
  @override
  @JsonKey()
  Map<String, dynamic> get draft {
    if (_draft is EqualUnmodifiableMapView) return _draft;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_draft);
  }

  @override
  @JsonKey()
  final bool isDirty;
  @override
  @JsonKey()
  final bool isSaving;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'SettingsSectionState(section: $section, committed: $committed, draft: $draft, isDirty: $isDirty, isSaving: $isSaving, isLoading: $isLoading, error: $error)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'SettingsSectionState'))
      ..add(DiagnosticsProperty('section', section))
      ..add(DiagnosticsProperty('committed', committed))
      ..add(DiagnosticsProperty('draft', draft))
      ..add(DiagnosticsProperty('isDirty', isDirty))
      ..add(DiagnosticsProperty('isSaving', isSaving))
      ..add(DiagnosticsProperty('isLoading', isLoading))
      ..add(DiagnosticsProperty('error', error));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SettingsSectionStateImpl &&
            (identical(other.section, section) || other.section == section) &&
            const DeepCollectionEquality()
                .equals(other._committed, _committed) &&
            const DeepCollectionEquality().equals(other._draft, _draft) &&
            (identical(other.isDirty, isDirty) || other.isDirty == isDirty) &&
            (identical(other.isSaving, isSaving) ||
                other.isSaving == isSaving) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      section,
      const DeepCollectionEquality().hash(_committed),
      const DeepCollectionEquality().hash(_draft),
      isDirty,
      isSaving,
      isLoading,
      error);

  /// Create a copy of SettingsSectionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SettingsSectionStateImplCopyWith<_$SettingsSectionStateImpl>
      get copyWith =>
          __$$SettingsSectionStateImplCopyWithImpl<_$SettingsSectionStateImpl>(
              this, _$identity);
}

abstract class _SettingsSectionState implements SettingsSectionState {
  const factory _SettingsSectionState(
      {required final SettingsSection section,
      final Map<String, dynamic> committed,
      final Map<String, dynamic> draft,
      final bool isDirty,
      final bool isSaving,
      final bool isLoading,
      final String? error}) = _$SettingsSectionStateImpl;

  @override
  SettingsSection get section;
  @override
  Map<String, dynamic> get committed;
  @override
  Map<String, dynamic> get draft;
  @override
  bool get isDirty;
  @override
  bool get isSaving;
  @override
  bool get isLoading;
  @override
  String? get error;

  /// Create a copy of SettingsSectionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SettingsSectionStateImplCopyWith<_$SettingsSectionStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
