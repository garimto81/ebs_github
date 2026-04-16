// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

EbsConfig _$EbsConfigFromJson(Map<String, dynamic> json) {
  return _EbsConfig.fromJson(json);
}

/// @nodoc
mixin _$EbsConfig {
  int get id => throw _privateConstructorUsedError;
  String get key => throw _privateConstructorUsedError;
  String get value => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  /// Serializes this EbsConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EbsConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EbsConfigCopyWith<EbsConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EbsConfigCopyWith<$Res> {
  factory $EbsConfigCopyWith(EbsConfig value, $Res Function(EbsConfig) then) =
      _$EbsConfigCopyWithImpl<$Res, EbsConfig>;
  @useResult
  $Res call(
      {int id, String key, String value, String category, String? description});
}

/// @nodoc
class _$EbsConfigCopyWithImpl<$Res, $Val extends EbsConfig>
    implements $EbsConfigCopyWith<$Res> {
  _$EbsConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EbsConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? key = null,
    Object? value = null,
    Object? category = null,
    Object? description = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EbsConfigImplCopyWith<$Res>
    implements $EbsConfigCopyWith<$Res> {
  factory _$$EbsConfigImplCopyWith(
          _$EbsConfigImpl value, $Res Function(_$EbsConfigImpl) then) =
      __$$EbsConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id, String key, String value, String category, String? description});
}

/// @nodoc
class __$$EbsConfigImplCopyWithImpl<$Res>
    extends _$EbsConfigCopyWithImpl<$Res, _$EbsConfigImpl>
    implements _$$EbsConfigImplCopyWith<$Res> {
  __$$EbsConfigImplCopyWithImpl(
      _$EbsConfigImpl _value, $Res Function(_$EbsConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of EbsConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? key = null,
    Object? value = null,
    Object? category = null,
    Object? description = freezed,
  }) {
    return _then(_$EbsConfigImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EbsConfigImpl implements _EbsConfig {
  const _$EbsConfigImpl(
      {required this.id,
      required this.key,
      required this.value,
      required this.category,
      this.description});

  factory _$EbsConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$EbsConfigImplFromJson(json);

  @override
  final int id;
  @override
  final String key;
  @override
  final String value;
  @override
  final String category;
  @override
  final String? description;

  @override
  String toString() {
    return 'EbsConfig(id: $id, key: $key, value: $value, category: $category, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EbsConfigImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, key, value, category, description);

  /// Create a copy of EbsConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EbsConfigImplCopyWith<_$EbsConfigImpl> get copyWith =>
      __$$EbsConfigImplCopyWithImpl<_$EbsConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EbsConfigImplToJson(
      this,
    );
  }
}

abstract class _EbsConfig implements EbsConfig {
  const factory _EbsConfig(
      {required final int id,
      required final String key,
      required final String value,
      required final String category,
      final String? description}) = _$EbsConfigImpl;

  factory _EbsConfig.fromJson(Map<String, dynamic> json) =
      _$EbsConfigImpl.fromJson;

  @override
  int get id;
  @override
  String get key;
  @override
  String get value;
  @override
  String get category;
  @override
  String? get description;

  /// Create a copy of EbsConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EbsConfigImplCopyWith<_$EbsConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
