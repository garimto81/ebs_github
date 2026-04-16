// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'blind_structure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BlindStructure _$BlindStructureFromJson(Map<String, dynamic> json) {
  return _BlindStructure.fromJson(json);
}

/// @nodoc
mixin _$BlindStructure {
  @JsonKey(name: 'blind_structure_id')
  int get blindStructureId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  String get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this BlindStructure to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BlindStructure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BlindStructureCopyWith<BlindStructure> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BlindStructureCopyWith<$Res> {
  factory $BlindStructureCopyWith(
          BlindStructure value, $Res Function(BlindStructure) then) =
      _$BlindStructureCopyWithImpl<$Res, BlindStructure>;
  @useResult
  $Res call(
      {@JsonKey(name: 'blind_structure_id') int blindStructureId,
      String name,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'updated_at') String updatedAt});
}

/// @nodoc
class _$BlindStructureCopyWithImpl<$Res, $Val extends BlindStructure>
    implements $BlindStructureCopyWith<$Res> {
  _$BlindStructureCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BlindStructure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? blindStructureId = null,
    Object? name = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      blindStructureId: null == blindStructureId
          ? _value.blindStructureId
          : blindStructureId // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
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
abstract class _$$BlindStructureImplCopyWith<$Res>
    implements $BlindStructureCopyWith<$Res> {
  factory _$$BlindStructureImplCopyWith(_$BlindStructureImpl value,
          $Res Function(_$BlindStructureImpl) then) =
      __$$BlindStructureImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'blind_structure_id') int blindStructureId,
      String name,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'updated_at') String updatedAt});
}

/// @nodoc
class __$$BlindStructureImplCopyWithImpl<$Res>
    extends _$BlindStructureCopyWithImpl<$Res, _$BlindStructureImpl>
    implements _$$BlindStructureImplCopyWith<$Res> {
  __$$BlindStructureImplCopyWithImpl(
      _$BlindStructureImpl _value, $Res Function(_$BlindStructureImpl) _then)
      : super(_value, _then);

  /// Create a copy of BlindStructure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? blindStructureId = null,
    Object? name = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$BlindStructureImpl(
      blindStructureId: null == blindStructureId
          ? _value.blindStructureId
          : blindStructureId // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
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
class _$BlindStructureImpl implements _BlindStructure {
  const _$BlindStructureImpl(
      {@JsonKey(name: 'blind_structure_id') required this.blindStructureId,
      required this.name,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt});

  factory _$BlindStructureImpl.fromJson(Map<String, dynamic> json) =>
      _$$BlindStructureImplFromJson(json);

  @override
  @JsonKey(name: 'blind_structure_id')
  final int blindStructureId;
  @override
  final String name;
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  @override
  String toString() {
    return 'BlindStructure(blindStructureId: $blindStructureId, name: $name, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BlindStructureImpl &&
            (identical(other.blindStructureId, blindStructureId) ||
                other.blindStructureId == blindStructureId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, blindStructureId, name, createdAt, updatedAt);

  /// Create a copy of BlindStructure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BlindStructureImplCopyWith<_$BlindStructureImpl> get copyWith =>
      __$$BlindStructureImplCopyWithImpl<_$BlindStructureImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BlindStructureImplToJson(
      this,
    );
  }
}

abstract class _BlindStructure implements BlindStructure {
  const factory _BlindStructure(
      {@JsonKey(name: 'blind_structure_id') required final int blindStructureId,
      required final String name,
      @JsonKey(name: 'created_at') required final String createdAt,
      @JsonKey(name: 'updated_at')
      required final String updatedAt}) = _$BlindStructureImpl;

  factory _BlindStructure.fromJson(Map<String, dynamic> json) =
      _$BlindStructureImpl.fromJson;

  @override
  @JsonKey(name: 'blind_structure_id')
  int get blindStructureId;
  @override
  String get name;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  String get updatedAt;

  /// Create a copy of BlindStructure
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BlindStructureImplCopyWith<_$BlindStructureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
