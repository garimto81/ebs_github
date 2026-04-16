// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'skin.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Skin _$SkinFromJson(Map<String, dynamic> json) {
  return _Skin.fromJson(json);
}

/// @nodoc
mixin _$Skin {
  @JsonKey(name: 'skin_id')
  int get skinId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get version => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  SkinMetadata get metadata => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_size')
  int get fileSize => throw _privateConstructorUsedError;
  @JsonKey(name: 'uploaded_at')
  String get uploadedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'activated_at')
  String? get activatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'preview_url')
  String? get previewUrl => throw _privateConstructorUsedError;

  /// Serializes this Skin to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Skin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SkinCopyWith<Skin> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SkinCopyWith<$Res> {
  factory $SkinCopyWith(Skin value, $Res Function(Skin) then) =
      _$SkinCopyWithImpl<$Res, Skin>;
  @useResult
  $Res call(
      {@JsonKey(name: 'skin_id') int skinId,
      String name,
      String version,
      String status,
      SkinMetadata metadata,
      @JsonKey(name: 'file_size') int fileSize,
      @JsonKey(name: 'uploaded_at') String uploadedAt,
      @JsonKey(name: 'activated_at') String? activatedAt,
      @JsonKey(name: 'preview_url') String? previewUrl});

  $SkinMetadataCopyWith<$Res> get metadata;
}

/// @nodoc
class _$SkinCopyWithImpl<$Res, $Val extends Skin>
    implements $SkinCopyWith<$Res> {
  _$SkinCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Skin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? skinId = null,
    Object? name = null,
    Object? version = null,
    Object? status = null,
    Object? metadata = null,
    Object? fileSize = null,
    Object? uploadedAt = null,
    Object? activatedAt = freezed,
    Object? previewUrl = freezed,
  }) {
    return _then(_value.copyWith(
      skinId: null == skinId
          ? _value.skinId
          : skinId // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as SkinMetadata,
      fileSize: null == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      uploadedAt: null == uploadedAt
          ? _value.uploadedAt
          : uploadedAt // ignore: cast_nullable_to_non_nullable
              as String,
      activatedAt: freezed == activatedAt
          ? _value.activatedAt
          : activatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      previewUrl: freezed == previewUrl
          ? _value.previewUrl
          : previewUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of Skin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SkinMetadataCopyWith<$Res> get metadata {
    return $SkinMetadataCopyWith<$Res>(_value.metadata, (value) {
      return _then(_value.copyWith(metadata: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SkinImplCopyWith<$Res> implements $SkinCopyWith<$Res> {
  factory _$$SkinImplCopyWith(
          _$SkinImpl value, $Res Function(_$SkinImpl) then) =
      __$$SkinImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'skin_id') int skinId,
      String name,
      String version,
      String status,
      SkinMetadata metadata,
      @JsonKey(name: 'file_size') int fileSize,
      @JsonKey(name: 'uploaded_at') String uploadedAt,
      @JsonKey(name: 'activated_at') String? activatedAt,
      @JsonKey(name: 'preview_url') String? previewUrl});

  @override
  $SkinMetadataCopyWith<$Res> get metadata;
}

/// @nodoc
class __$$SkinImplCopyWithImpl<$Res>
    extends _$SkinCopyWithImpl<$Res, _$SkinImpl>
    implements _$$SkinImplCopyWith<$Res> {
  __$$SkinImplCopyWithImpl(_$SkinImpl _value, $Res Function(_$SkinImpl) _then)
      : super(_value, _then);

  /// Create a copy of Skin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? skinId = null,
    Object? name = null,
    Object? version = null,
    Object? status = null,
    Object? metadata = null,
    Object? fileSize = null,
    Object? uploadedAt = null,
    Object? activatedAt = freezed,
    Object? previewUrl = freezed,
  }) {
    return _then(_$SkinImpl(
      skinId: null == skinId
          ? _value.skinId
          : skinId // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as SkinMetadata,
      fileSize: null == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      uploadedAt: null == uploadedAt
          ? _value.uploadedAt
          : uploadedAt // ignore: cast_nullable_to_non_nullable
              as String,
      activatedAt: freezed == activatedAt
          ? _value.activatedAt
          : activatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      previewUrl: freezed == previewUrl
          ? _value.previewUrl
          : previewUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SkinImpl implements _Skin {
  const _$SkinImpl(
      {@JsonKey(name: 'skin_id') required this.skinId,
      required this.name,
      required this.version,
      required this.status,
      required this.metadata,
      @JsonKey(name: 'file_size') required this.fileSize,
      @JsonKey(name: 'uploaded_at') required this.uploadedAt,
      @JsonKey(name: 'activated_at') this.activatedAt,
      @JsonKey(name: 'preview_url') this.previewUrl});

  factory _$SkinImpl.fromJson(Map<String, dynamic> json) =>
      _$$SkinImplFromJson(json);

  @override
  @JsonKey(name: 'skin_id')
  final int skinId;
  @override
  final String name;
  @override
  final String version;
  @override
  final String status;
  @override
  final SkinMetadata metadata;
  @override
  @JsonKey(name: 'file_size')
  final int fileSize;
  @override
  @JsonKey(name: 'uploaded_at')
  final String uploadedAt;
  @override
  @JsonKey(name: 'activated_at')
  final String? activatedAt;
  @override
  @JsonKey(name: 'preview_url')
  final String? previewUrl;

  @override
  String toString() {
    return 'Skin(skinId: $skinId, name: $name, version: $version, status: $status, metadata: $metadata, fileSize: $fileSize, uploadedAt: $uploadedAt, activatedAt: $activatedAt, previewUrl: $previewUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SkinImpl &&
            (identical(other.skinId, skinId) || other.skinId == skinId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.uploadedAt, uploadedAt) ||
                other.uploadedAt == uploadedAt) &&
            (identical(other.activatedAt, activatedAt) ||
                other.activatedAt == activatedAt) &&
            (identical(other.previewUrl, previewUrl) ||
                other.previewUrl == previewUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, skinId, name, version, status,
      metadata, fileSize, uploadedAt, activatedAt, previewUrl);

  /// Create a copy of Skin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SkinImplCopyWith<_$SkinImpl> get copyWith =>
      __$$SkinImplCopyWithImpl<_$SkinImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SkinImplToJson(
      this,
    );
  }
}

abstract class _Skin implements Skin {
  const factory _Skin(
      {@JsonKey(name: 'skin_id') required final int skinId,
      required final String name,
      required final String version,
      required final String status,
      required final SkinMetadata metadata,
      @JsonKey(name: 'file_size') required final int fileSize,
      @JsonKey(name: 'uploaded_at') required final String uploadedAt,
      @JsonKey(name: 'activated_at') final String? activatedAt,
      @JsonKey(name: 'preview_url') final String? previewUrl}) = _$SkinImpl;

  factory _Skin.fromJson(Map<String, dynamic> json) = _$SkinImpl.fromJson;

  @override
  @JsonKey(name: 'skin_id')
  int get skinId;
  @override
  String get name;
  @override
  String get version;
  @override
  String get status;
  @override
  SkinMetadata get metadata;
  @override
  @JsonKey(name: 'file_size')
  int get fileSize;
  @override
  @JsonKey(name: 'uploaded_at')
  String get uploadedAt;
  @override
  @JsonKey(name: 'activated_at')
  String? get activatedAt;
  @override
  @JsonKey(name: 'preview_url')
  String? get previewUrl;

  /// Create a copy of Skin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SkinImplCopyWith<_$SkinImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
