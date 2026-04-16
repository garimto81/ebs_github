// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audit_log_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AuditLogState {
  List<AuditLog> get items => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get hasMore => throw _privateConstructorUsedError;
  int get currentPage => throw _privateConstructorUsedError;
  int get pageSize => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  String? get filterEntityType => throw _privateConstructorUsedError;
  int? get filterUserId => throw _privateConstructorUsedError;

  /// Create a copy of AuditLogState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuditLogStateCopyWith<AuditLogState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuditLogStateCopyWith<$Res> {
  factory $AuditLogStateCopyWith(
          AuditLogState value, $Res Function(AuditLogState) then) =
      _$AuditLogStateCopyWithImpl<$Res, AuditLogState>;
  @useResult
  $Res call(
      {List<AuditLog> items,
      bool isLoading,
      bool hasMore,
      int currentPage,
      int pageSize,
      String? error,
      String? filterEntityType,
      int? filterUserId});
}

/// @nodoc
class _$AuditLogStateCopyWithImpl<$Res, $Val extends AuditLogState>
    implements $AuditLogStateCopyWith<$Res> {
  _$AuditLogStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuditLogState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? isLoading = null,
    Object? hasMore = null,
    Object? currentPage = null,
    Object? pageSize = null,
    Object? error = freezed,
    Object? filterEntityType = freezed,
    Object? filterUserId = freezed,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<AuditLog>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      currentPage: null == currentPage
          ? _value.currentPage
          : currentPage // ignore: cast_nullable_to_non_nullable
              as int,
      pageSize: null == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      filterEntityType: freezed == filterEntityType
          ? _value.filterEntityType
          : filterEntityType // ignore: cast_nullable_to_non_nullable
              as String?,
      filterUserId: freezed == filterUserId
          ? _value.filterUserId
          : filterUserId // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AuditLogStateImplCopyWith<$Res>
    implements $AuditLogStateCopyWith<$Res> {
  factory _$$AuditLogStateImplCopyWith(
          _$AuditLogStateImpl value, $Res Function(_$AuditLogStateImpl) then) =
      __$$AuditLogStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<AuditLog> items,
      bool isLoading,
      bool hasMore,
      int currentPage,
      int pageSize,
      String? error,
      String? filterEntityType,
      int? filterUserId});
}

/// @nodoc
class __$$AuditLogStateImplCopyWithImpl<$Res>
    extends _$AuditLogStateCopyWithImpl<$Res, _$AuditLogStateImpl>
    implements _$$AuditLogStateImplCopyWith<$Res> {
  __$$AuditLogStateImplCopyWithImpl(
      _$AuditLogStateImpl _value, $Res Function(_$AuditLogStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuditLogState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? isLoading = null,
    Object? hasMore = null,
    Object? currentPage = null,
    Object? pageSize = null,
    Object? error = freezed,
    Object? filterEntityType = freezed,
    Object? filterUserId = freezed,
  }) {
    return _then(_$AuditLogStateImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<AuditLog>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      currentPage: null == currentPage
          ? _value.currentPage
          : currentPage // ignore: cast_nullable_to_non_nullable
              as int,
      pageSize: null == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      filterEntityType: freezed == filterEntityType
          ? _value.filterEntityType
          : filterEntityType // ignore: cast_nullable_to_non_nullable
              as String?,
      filterUserId: freezed == filterUserId
          ? _value.filterUserId
          : filterUserId // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

class _$AuditLogStateImpl implements _AuditLogState {
  const _$AuditLogStateImpl(
      {final List<AuditLog> items = const [],
      this.isLoading = false,
      this.hasMore = false,
      this.currentPage = 0,
      this.pageSize = 50,
      this.error,
      this.filterEntityType,
      this.filterUserId})
      : _items = items;

  final List<AuditLog> _items;
  @override
  @JsonKey()
  List<AuditLog> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool hasMore;
  @override
  @JsonKey()
  final int currentPage;
  @override
  @JsonKey()
  final int pageSize;
  @override
  final String? error;
  @override
  final String? filterEntityType;
  @override
  final int? filterUserId;

  @override
  String toString() {
    return 'AuditLogState(items: $items, isLoading: $isLoading, hasMore: $hasMore, currentPage: $currentPage, pageSize: $pageSize, error: $error, filterEntityType: $filterEntityType, filterUserId: $filterUserId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuditLogStateImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.currentPage, currentPage) ||
                other.currentPage == currentPage) &&
            (identical(other.pageSize, pageSize) ||
                other.pageSize == pageSize) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.filterEntityType, filterEntityType) ||
                other.filterEntityType == filterEntityType) &&
            (identical(other.filterUserId, filterUserId) ||
                other.filterUserId == filterUserId));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_items),
      isLoading,
      hasMore,
      currentPage,
      pageSize,
      error,
      filterEntityType,
      filterUserId);

  /// Create a copy of AuditLogState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuditLogStateImplCopyWith<_$AuditLogStateImpl> get copyWith =>
      __$$AuditLogStateImplCopyWithImpl<_$AuditLogStateImpl>(this, _$identity);
}

abstract class _AuditLogState implements AuditLogState {
  const factory _AuditLogState(
      {final List<AuditLog> items,
      final bool isLoading,
      final bool hasMore,
      final int currentPage,
      final int pageSize,
      final String? error,
      final String? filterEntityType,
      final int? filterUserId}) = _$AuditLogStateImpl;

  @override
  List<AuditLog> get items;
  @override
  bool get isLoading;
  @override
  bool get hasMore;
  @override
  int get currentPage;
  @override
  int get pageSize;
  @override
  String? get error;
  @override
  String? get filterEntityType;
  @override
  int? get filterUserId;

  /// Create a copy of AuditLogState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuditLogStateImplCopyWith<_$AuditLogStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
