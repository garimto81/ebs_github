// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'skin_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SkinMetadata _$SkinMetadataFromJson(Map<String, dynamic> json) {
  return _SkinMetadata.fromJson(json);
}

/// @nodoc
mixin _$SkinMetadata {
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String? get author => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;

  /// Serializes this SkinMetadata to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SkinMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SkinMetadataCopyWith<SkinMetadata> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SkinMetadataCopyWith<$Res> {
  factory $SkinMetadataCopyWith(
          SkinMetadata value, $Res Function(SkinMetadata) then) =
      _$SkinMetadataCopyWithImpl<$Res, SkinMetadata>;
  @useResult
  $Res call(
      {String title, String description, String? author, List<String> tags});
}

/// @nodoc
class _$SkinMetadataCopyWithImpl<$Res, $Val extends SkinMetadata>
    implements $SkinMetadataCopyWith<$Res> {
  _$SkinMetadataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SkinMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? description = null,
    Object? author = freezed,
    Object? tags = null,
  }) {
    return _then(_value.copyWith(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      author: freezed == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SkinMetadataImplCopyWith<$Res>
    implements $SkinMetadataCopyWith<$Res> {
  factory _$$SkinMetadataImplCopyWith(
          _$SkinMetadataImpl value, $Res Function(_$SkinMetadataImpl) then) =
      __$$SkinMetadataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String title, String description, String? author, List<String> tags});
}

/// @nodoc
class __$$SkinMetadataImplCopyWithImpl<$Res>
    extends _$SkinMetadataCopyWithImpl<$Res, _$SkinMetadataImpl>
    implements _$$SkinMetadataImplCopyWith<$Res> {
  __$$SkinMetadataImplCopyWithImpl(
      _$SkinMetadataImpl _value, $Res Function(_$SkinMetadataImpl) _then)
      : super(_value, _then);

  /// Create a copy of SkinMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? description = null,
    Object? author = freezed,
    Object? tags = null,
  }) {
    return _then(_$SkinMetadataImpl(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      author: freezed == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SkinMetadataImpl implements _SkinMetadata {
  const _$SkinMetadataImpl(
      {this.title = '',
      this.description = '',
      this.author,
      final List<String> tags = const []})
      : _tags = tags;

  factory _$SkinMetadataImpl.fromJson(Map<String, dynamic> json) =>
      _$$SkinMetadataImplFromJson(json);

  @override
  @JsonKey()
  final String title;
  @override
  @JsonKey()
  final String description;
  @override
  final String? author;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  String toString() {
    return 'SkinMetadata(title: $title, description: $description, author: $author, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SkinMetadataImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.author, author) || other.author == author) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, title, description, author,
      const DeepCollectionEquality().hash(_tags));

  /// Create a copy of SkinMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SkinMetadataImplCopyWith<_$SkinMetadataImpl> get copyWith =>
      __$$SkinMetadataImplCopyWithImpl<_$SkinMetadataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SkinMetadataImplToJson(
      this,
    );
  }
}

abstract class _SkinMetadata implements SkinMetadata {
  const factory _SkinMetadata(
      {final String title,
      final String description,
      final String? author,
      final List<String> tags}) = _$SkinMetadataImpl;

  factory _SkinMetadata.fromJson(Map<String, dynamic> json) =
      _$SkinMetadataImpl.fromJson;

  @override
  String get title;
  @override
  String get description;
  @override
  String? get author;
  @override
  List<String> get tags;

  /// Create a copy of SkinMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SkinMetadataImplCopyWith<_$SkinMetadataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
