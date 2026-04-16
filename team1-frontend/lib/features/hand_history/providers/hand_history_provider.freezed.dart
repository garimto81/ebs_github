// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hand_history_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$HandHistoryState {
  List<Hand> get items => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get hasMore => throw _privateConstructorUsedError;
  int get currentPage => throw _privateConstructorUsedError;
  int get pageSize => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  int? get filterTableId => throw _privateConstructorUsedError;

  /// Create a copy of HandHistoryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HandHistoryStateCopyWith<HandHistoryState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HandHistoryStateCopyWith<$Res> {
  factory $HandHistoryStateCopyWith(
          HandHistoryState value, $Res Function(HandHistoryState) then) =
      _$HandHistoryStateCopyWithImpl<$Res, HandHistoryState>;
  @useResult
  $Res call(
      {List<Hand> items,
      bool isLoading,
      bool hasMore,
      int currentPage,
      int pageSize,
      String? error,
      int? filterTableId});
}

/// @nodoc
class _$HandHistoryStateCopyWithImpl<$Res, $Val extends HandHistoryState>
    implements $HandHistoryStateCopyWith<$Res> {
  _$HandHistoryStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HandHistoryState
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
    Object? filterTableId = freezed,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<Hand>,
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
      filterTableId: freezed == filterTableId
          ? _value.filterTableId
          : filterTableId // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HandHistoryStateImplCopyWith<$Res>
    implements $HandHistoryStateCopyWith<$Res> {
  factory _$$HandHistoryStateImplCopyWith(_$HandHistoryStateImpl value,
          $Res Function(_$HandHistoryStateImpl) then) =
      __$$HandHistoryStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<Hand> items,
      bool isLoading,
      bool hasMore,
      int currentPage,
      int pageSize,
      String? error,
      int? filterTableId});
}

/// @nodoc
class __$$HandHistoryStateImplCopyWithImpl<$Res>
    extends _$HandHistoryStateCopyWithImpl<$Res, _$HandHistoryStateImpl>
    implements _$$HandHistoryStateImplCopyWith<$Res> {
  __$$HandHistoryStateImplCopyWithImpl(_$HandHistoryStateImpl _value,
      $Res Function(_$HandHistoryStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of HandHistoryState
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
    Object? filterTableId = freezed,
  }) {
    return _then(_$HandHistoryStateImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<Hand>,
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
      filterTableId: freezed == filterTableId
          ? _value.filterTableId
          : filterTableId // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

class _$HandHistoryStateImpl implements _HandHistoryState {
  const _$HandHistoryStateImpl(
      {final List<Hand> items = const [],
      this.isLoading = false,
      this.hasMore = false,
      this.currentPage = 0,
      this.pageSize = 50,
      this.error,
      this.filterTableId})
      : _items = items;

  final List<Hand> _items;
  @override
  @JsonKey()
  List<Hand> get items {
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
  final int? filterTableId;

  @override
  String toString() {
    return 'HandHistoryState(items: $items, isLoading: $isLoading, hasMore: $hasMore, currentPage: $currentPage, pageSize: $pageSize, error: $error, filterTableId: $filterTableId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HandHistoryStateImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.currentPage, currentPage) ||
                other.currentPage == currentPage) &&
            (identical(other.pageSize, pageSize) ||
                other.pageSize == pageSize) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.filterTableId, filterTableId) ||
                other.filterTableId == filterTableId));
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
      filterTableId);

  /// Create a copy of HandHistoryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HandHistoryStateImplCopyWith<_$HandHistoryStateImpl> get copyWith =>
      __$$HandHistoryStateImplCopyWithImpl<_$HandHistoryStateImpl>(
          this, _$identity);
}

abstract class _HandHistoryState implements HandHistoryState {
  const factory _HandHistoryState(
      {final List<Hand> items,
      final bool isLoading,
      final bool hasMore,
      final int currentPage,
      final int pageSize,
      final String? error,
      final int? filterTableId}) = _$HandHistoryStateImpl;

  @override
  List<Hand> get items;
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
  int? get filterTableId;

  /// Create a copy of HandHistoryState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HandHistoryStateImplCopyWith<_$HandHistoryStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
