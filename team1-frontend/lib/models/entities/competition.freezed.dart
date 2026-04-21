// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'competition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Competition _$CompetitionFromJson(Map<String, dynamic> json) {
  return _Competition.fromJson(json);
}

/// @nodoc
mixin _$Competition {
  @JsonKey(name: 'competitionId')
  int get competitionId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'competitionType')
  int get competitionType => throw _privateConstructorUsedError;
  @JsonKey(name: 'competitionTag')
  int get competitionTag => throw _privateConstructorUsedError;
  @JsonKey(name: 'createdAt')
  String get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updatedAt')
  String get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Competition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Competition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompetitionCopyWith<Competition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompetitionCopyWith<$Res> {
  factory $CompetitionCopyWith(
          Competition value, $Res Function(Competition) then) =
      _$CompetitionCopyWithImpl<$Res, Competition>;
  @useResult
  $Res call(
      {@JsonKey(name: 'competitionId') int competitionId,
      String name,
      @JsonKey(name: 'competitionType') int competitionType,
      @JsonKey(name: 'competitionTag') int competitionTag,
      @JsonKey(name: 'createdAt') String createdAt,
      @JsonKey(name: 'updatedAt') String updatedAt});
}

/// @nodoc
class _$CompetitionCopyWithImpl<$Res, $Val extends Competition>
    implements $CompetitionCopyWith<$Res> {
  _$CompetitionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Competition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? competitionId = null,
    Object? name = null,
    Object? competitionType = null,
    Object? competitionTag = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      competitionId: null == competitionId
          ? _value.competitionId
          : competitionId // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      competitionType: null == competitionType
          ? _value.competitionType
          : competitionType // ignore: cast_nullable_to_non_nullable
              as int,
      competitionTag: null == competitionTag
          ? _value.competitionTag
          : competitionTag // ignore: cast_nullable_to_non_nullable
              as int,
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
abstract class _$$CompetitionImplCopyWith<$Res>
    implements $CompetitionCopyWith<$Res> {
  factory _$$CompetitionImplCopyWith(
          _$CompetitionImpl value, $Res Function(_$CompetitionImpl) then) =
      __$$CompetitionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'competitionId') int competitionId,
      String name,
      @JsonKey(name: 'competitionType') int competitionType,
      @JsonKey(name: 'competitionTag') int competitionTag,
      @JsonKey(name: 'createdAt') String createdAt,
      @JsonKey(name: 'updatedAt') String updatedAt});
}

/// @nodoc
class __$$CompetitionImplCopyWithImpl<$Res>
    extends _$CompetitionCopyWithImpl<$Res, _$CompetitionImpl>
    implements _$$CompetitionImplCopyWith<$Res> {
  __$$CompetitionImplCopyWithImpl(
      _$CompetitionImpl _value, $Res Function(_$CompetitionImpl) _then)
      : super(_value, _then);

  /// Create a copy of Competition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? competitionId = null,
    Object? name = null,
    Object? competitionType = null,
    Object? competitionTag = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$CompetitionImpl(
      competitionId: null == competitionId
          ? _value.competitionId
          : competitionId // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      competitionType: null == competitionType
          ? _value.competitionType
          : competitionType // ignore: cast_nullable_to_non_nullable
              as int,
      competitionTag: null == competitionTag
          ? _value.competitionTag
          : competitionTag // ignore: cast_nullable_to_non_nullable
              as int,
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
class _$CompetitionImpl implements _Competition {
  const _$CompetitionImpl(
      {@JsonKey(name: 'competitionId') required this.competitionId,
      required this.name,
      @JsonKey(name: 'competitionType') required this.competitionType,
      @JsonKey(name: 'competitionTag') required this.competitionTag,
      @JsonKey(name: 'createdAt') required this.createdAt,
      @JsonKey(name: 'updatedAt') required this.updatedAt});

  factory _$CompetitionImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompetitionImplFromJson(json);

  @override
  @JsonKey(name: 'competitionId')
  final int competitionId;
  @override
  final String name;
  @override
  @JsonKey(name: 'competitionType')
  final int competitionType;
  @override
  @JsonKey(name: 'competitionTag')
  final int competitionTag;
  @override
  @JsonKey(name: 'createdAt')
  final String createdAt;
  @override
  @JsonKey(name: 'updatedAt')
  final String updatedAt;

  @override
  String toString() {
    return 'Competition(competitionId: $competitionId, name: $name, competitionType: $competitionType, competitionTag: $competitionTag, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompetitionImpl &&
            (identical(other.competitionId, competitionId) ||
                other.competitionId == competitionId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.competitionType, competitionType) ||
                other.competitionType == competitionType) &&
            (identical(other.competitionTag, competitionTag) ||
                other.competitionTag == competitionTag) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, competitionId, name,
      competitionType, competitionTag, createdAt, updatedAt);

  /// Create a copy of Competition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompetitionImplCopyWith<_$CompetitionImpl> get copyWith =>
      __$$CompetitionImplCopyWithImpl<_$CompetitionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CompetitionImplToJson(
      this,
    );
  }
}

abstract class _Competition implements Competition {
  const factory _Competition(
          {@JsonKey(name: 'competitionId') required final int competitionId,
          required final String name,
          @JsonKey(name: 'competitionType') required final int competitionType,
          @JsonKey(name: 'competitionTag') required final int competitionTag,
          @JsonKey(name: 'createdAt') required final String createdAt,
          @JsonKey(name: 'updatedAt') required final String updatedAt}) =
      _$CompetitionImpl;

  factory _Competition.fromJson(Map<String, dynamic> json) =
      _$CompetitionImpl.fromJson;

  @override
  @JsonKey(name: 'competitionId')
  int get competitionId;
  @override
  String get name;
  @override
  @JsonKey(name: 'competitionType')
  int get competitionType;
  @override
  @JsonKey(name: 'competitionTag')
  int get competitionTag;
  @override
  @JsonKey(name: 'createdAt')
  String get createdAt;
  @override
  @JsonKey(name: 'updatedAt')
  String get updatedAt;

  /// Create a copy of Competition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompetitionImplCopyWith<_$CompetitionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
