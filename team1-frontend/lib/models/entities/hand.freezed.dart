// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hand.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Hand _$HandFromJson(Map<String, dynamic> json) {
  return _Hand.fromJson(json);
}

/// @nodoc
mixin _$Hand {
  @JsonKey(name: 'handId')
  int get handId => throw _privateConstructorUsedError;
  @JsonKey(name: 'tableId')
  int get tableId => throw _privateConstructorUsedError;
  @JsonKey(name: 'handNumber')
  int get handNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'gameType')
  int get gameType => throw _privateConstructorUsedError;
  @JsonKey(name: 'betStructure')
  int get betStructure => throw _privateConstructorUsedError;
  @JsonKey(name: 'dealerSeat')
  int get dealerSeat => throw _privateConstructorUsedError;
  @JsonKey(name: 'boardCards')
  String get boardCards => throw _privateConstructorUsedError;
  @JsonKey(name: 'potTotal')
  int get potTotal => throw _privateConstructorUsedError;
  @JsonKey(name: 'sidePots')
  String get sidePots => throw _privateConstructorUsedError;
  @JsonKey(name: 'currentStreet')
  String? get currentStreet => throw _privateConstructorUsedError;
  @JsonKey(name: 'startedAt')
  String get startedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'endedAt')
  String? get endedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'durationSec')
  int get durationSec => throw _privateConstructorUsedError;
  @JsonKey(name: 'createdAt')
  String get createdAt =>
      throw _privateConstructorUsedError; // v03 game-rules fields (Cycle 7, #329)
  @JsonKey(name: 'anteAmount')
  int get anteAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'straddleAmount')
  int? get straddleAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'runItTwiceCount')
  int get runItTwiceCount => throw _privateConstructorUsedError;

  /// Serializes this Hand to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Hand
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HandCopyWith<Hand> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HandCopyWith<$Res> {
  factory $HandCopyWith(Hand value, $Res Function(Hand) then) =
      _$HandCopyWithImpl<$Res, Hand>;
  @useResult
  $Res call(
      {@JsonKey(name: 'handId') int handId,
      @JsonKey(name: 'tableId') int tableId,
      @JsonKey(name: 'handNumber') int handNumber,
      @JsonKey(name: 'gameType') int gameType,
      @JsonKey(name: 'betStructure') int betStructure,
      @JsonKey(name: 'dealerSeat') int dealerSeat,
      @JsonKey(name: 'boardCards') String boardCards,
      @JsonKey(name: 'potTotal') int potTotal,
      @JsonKey(name: 'sidePots') String sidePots,
      @JsonKey(name: 'currentStreet') String? currentStreet,
      @JsonKey(name: 'startedAt') String startedAt,
      @JsonKey(name: 'endedAt') String? endedAt,
      @JsonKey(name: 'durationSec') int durationSec,
      @JsonKey(name: 'createdAt') String createdAt,
      @JsonKey(name: 'anteAmount') int anteAmount,
      @JsonKey(name: 'straddleAmount') int? straddleAmount,
      @JsonKey(name: 'runItTwiceCount') int runItTwiceCount});
}

/// @nodoc
class _$HandCopyWithImpl<$Res, $Val extends Hand>
    implements $HandCopyWith<$Res> {
  _$HandCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Hand
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? handId = null,
    Object? tableId = null,
    Object? handNumber = null,
    Object? gameType = null,
    Object? betStructure = null,
    Object? dealerSeat = null,
    Object? boardCards = null,
    Object? potTotal = null,
    Object? sidePots = null,
    Object? currentStreet = freezed,
    Object? startedAt = null,
    Object? endedAt = freezed,
    Object? durationSec = null,
    Object? createdAt = null,
    Object? anteAmount = null,
    Object? straddleAmount = freezed,
    Object? runItTwiceCount = null,
  }) {
    return _then(_value.copyWith(
      handId: null == handId
          ? _value.handId
          : handId // ignore: cast_nullable_to_non_nullable
              as int,
      tableId: null == tableId
          ? _value.tableId
          : tableId // ignore: cast_nullable_to_non_nullable
              as int,
      handNumber: null == handNumber
          ? _value.handNumber
          : handNumber // ignore: cast_nullable_to_non_nullable
              as int,
      gameType: null == gameType
          ? _value.gameType
          : gameType // ignore: cast_nullable_to_non_nullable
              as int,
      betStructure: null == betStructure
          ? _value.betStructure
          : betStructure // ignore: cast_nullable_to_non_nullable
              as int,
      dealerSeat: null == dealerSeat
          ? _value.dealerSeat
          : dealerSeat // ignore: cast_nullable_to_non_nullable
              as int,
      boardCards: null == boardCards
          ? _value.boardCards
          : boardCards // ignore: cast_nullable_to_non_nullable
              as String,
      potTotal: null == potTotal
          ? _value.potTotal
          : potTotal // ignore: cast_nullable_to_non_nullable
              as int,
      sidePots: null == sidePots
          ? _value.sidePots
          : sidePots // ignore: cast_nullable_to_non_nullable
              as String,
      currentStreet: freezed == currentStreet
          ? _value.currentStreet
          : currentStreet // ignore: cast_nullable_to_non_nullable
              as String?,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as String,
      endedAt: freezed == endedAt
          ? _value.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      durationSec: null == durationSec
          ? _value.durationSec
          : durationSec // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      anteAmount: null == anteAmount
          ? _value.anteAmount
          : anteAmount // ignore: cast_nullable_to_non_nullable
              as int,
      straddleAmount: freezed == straddleAmount
          ? _value.straddleAmount
          : straddleAmount // ignore: cast_nullable_to_non_nullable
              as int?,
      runItTwiceCount: null == runItTwiceCount
          ? _value.runItTwiceCount
          : runItTwiceCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HandImplCopyWith<$Res> implements $HandCopyWith<$Res> {
  factory _$$HandImplCopyWith(
          _$HandImpl value, $Res Function(_$HandImpl) then) =
      __$$HandImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'handId') int handId,
      @JsonKey(name: 'tableId') int tableId,
      @JsonKey(name: 'handNumber') int handNumber,
      @JsonKey(name: 'gameType') int gameType,
      @JsonKey(name: 'betStructure') int betStructure,
      @JsonKey(name: 'dealerSeat') int dealerSeat,
      @JsonKey(name: 'boardCards') String boardCards,
      @JsonKey(name: 'potTotal') int potTotal,
      @JsonKey(name: 'sidePots') String sidePots,
      @JsonKey(name: 'currentStreet') String? currentStreet,
      @JsonKey(name: 'startedAt') String startedAt,
      @JsonKey(name: 'endedAt') String? endedAt,
      @JsonKey(name: 'durationSec') int durationSec,
      @JsonKey(name: 'createdAt') String createdAt,
      @JsonKey(name: 'anteAmount') int anteAmount,
      @JsonKey(name: 'straddleAmount') int? straddleAmount,
      @JsonKey(name: 'runItTwiceCount') int runItTwiceCount});
}

/// @nodoc
class __$$HandImplCopyWithImpl<$Res>
    extends _$HandCopyWithImpl<$Res, _$HandImpl>
    implements _$$HandImplCopyWith<$Res> {
  __$$HandImplCopyWithImpl(_$HandImpl _value, $Res Function(_$HandImpl) _then)
      : super(_value, _then);

  /// Create a copy of Hand
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? handId = null,
    Object? tableId = null,
    Object? handNumber = null,
    Object? gameType = null,
    Object? betStructure = null,
    Object? dealerSeat = null,
    Object? boardCards = null,
    Object? potTotal = null,
    Object? sidePots = null,
    Object? currentStreet = freezed,
    Object? startedAt = null,
    Object? endedAt = freezed,
    Object? durationSec = null,
    Object? createdAt = null,
    Object? anteAmount = null,
    Object? straddleAmount = freezed,
    Object? runItTwiceCount = null,
  }) {
    return _then(_$HandImpl(
      handId: null == handId
          ? _value.handId
          : handId // ignore: cast_nullable_to_non_nullable
              as int,
      tableId: null == tableId
          ? _value.tableId
          : tableId // ignore: cast_nullable_to_non_nullable
              as int,
      handNumber: null == handNumber
          ? _value.handNumber
          : handNumber // ignore: cast_nullable_to_non_nullable
              as int,
      gameType: null == gameType
          ? _value.gameType
          : gameType // ignore: cast_nullable_to_non_nullable
              as int,
      betStructure: null == betStructure
          ? _value.betStructure
          : betStructure // ignore: cast_nullable_to_non_nullable
              as int,
      dealerSeat: null == dealerSeat
          ? _value.dealerSeat
          : dealerSeat // ignore: cast_nullable_to_non_nullable
              as int,
      boardCards: null == boardCards
          ? _value.boardCards
          : boardCards // ignore: cast_nullable_to_non_nullable
              as String,
      potTotal: null == potTotal
          ? _value.potTotal
          : potTotal // ignore: cast_nullable_to_non_nullable
              as int,
      sidePots: null == sidePots
          ? _value.sidePots
          : sidePots // ignore: cast_nullable_to_non_nullable
              as String,
      currentStreet: freezed == currentStreet
          ? _value.currentStreet
          : currentStreet // ignore: cast_nullable_to_non_nullable
              as String?,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as String,
      endedAt: freezed == endedAt
          ? _value.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      durationSec: null == durationSec
          ? _value.durationSec
          : durationSec // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      anteAmount: null == anteAmount
          ? _value.anteAmount
          : anteAmount // ignore: cast_nullable_to_non_nullable
              as int,
      straddleAmount: freezed == straddleAmount
          ? _value.straddleAmount
          : straddleAmount // ignore: cast_nullable_to_non_nullable
              as int?,
      runItTwiceCount: null == runItTwiceCount
          ? _value.runItTwiceCount
          : runItTwiceCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HandImpl implements _Hand {
  const _$HandImpl(
      {@JsonKey(name: 'handId') required this.handId,
      @JsonKey(name: 'tableId') required this.tableId,
      @JsonKey(name: 'handNumber') required this.handNumber,
      @JsonKey(name: 'gameType') required this.gameType,
      @JsonKey(name: 'betStructure') required this.betStructure,
      @JsonKey(name: 'dealerSeat') required this.dealerSeat,
      @JsonKey(name: 'boardCards') required this.boardCards,
      @JsonKey(name: 'potTotal') required this.potTotal,
      @JsonKey(name: 'sidePots') required this.sidePots,
      @JsonKey(name: 'currentStreet') this.currentStreet,
      @JsonKey(name: 'startedAt') required this.startedAt,
      @JsonKey(name: 'endedAt') this.endedAt,
      @JsonKey(name: 'durationSec') required this.durationSec,
      @JsonKey(name: 'createdAt') required this.createdAt,
      @JsonKey(name: 'anteAmount') this.anteAmount = 0,
      @JsonKey(name: 'straddleAmount') this.straddleAmount,
      @JsonKey(name: 'runItTwiceCount') this.runItTwiceCount = 1});

  factory _$HandImpl.fromJson(Map<String, dynamic> json) =>
      _$$HandImplFromJson(json);

  @override
  @JsonKey(name: 'handId')
  final int handId;
  @override
  @JsonKey(name: 'tableId')
  final int tableId;
  @override
  @JsonKey(name: 'handNumber')
  final int handNumber;
  @override
  @JsonKey(name: 'gameType')
  final int gameType;
  @override
  @JsonKey(name: 'betStructure')
  final int betStructure;
  @override
  @JsonKey(name: 'dealerSeat')
  final int dealerSeat;
  @override
  @JsonKey(name: 'boardCards')
  final String boardCards;
  @override
  @JsonKey(name: 'potTotal')
  final int potTotal;
  @override
  @JsonKey(name: 'sidePots')
  final String sidePots;
  @override
  @JsonKey(name: 'currentStreet')
  final String? currentStreet;
  @override
  @JsonKey(name: 'startedAt')
  final String startedAt;
  @override
  @JsonKey(name: 'endedAt')
  final String? endedAt;
  @override
  @JsonKey(name: 'durationSec')
  final int durationSec;
  @override
  @JsonKey(name: 'createdAt')
  final String createdAt;
// v03 game-rules fields (Cycle 7, #329)
  @override
  @JsonKey(name: 'anteAmount')
  final int anteAmount;
  @override
  @JsonKey(name: 'straddleAmount')
  final int? straddleAmount;
  @override
  @JsonKey(name: 'runItTwiceCount')
  final int runItTwiceCount;

  @override
  String toString() {
    return 'Hand(handId: $handId, tableId: $tableId, handNumber: $handNumber, gameType: $gameType, betStructure: $betStructure, dealerSeat: $dealerSeat, boardCards: $boardCards, potTotal: $potTotal, sidePots: $sidePots, currentStreet: $currentStreet, startedAt: $startedAt, endedAt: $endedAt, durationSec: $durationSec, createdAt: $createdAt, anteAmount: $anteAmount, straddleAmount: $straddleAmount, runItTwiceCount: $runItTwiceCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HandImpl &&
            (identical(other.handId, handId) || other.handId == handId) &&
            (identical(other.tableId, tableId) || other.tableId == tableId) &&
            (identical(other.handNumber, handNumber) ||
                other.handNumber == handNumber) &&
            (identical(other.gameType, gameType) ||
                other.gameType == gameType) &&
            (identical(other.betStructure, betStructure) ||
                other.betStructure == betStructure) &&
            (identical(other.dealerSeat, dealerSeat) ||
                other.dealerSeat == dealerSeat) &&
            (identical(other.boardCards, boardCards) ||
                other.boardCards == boardCards) &&
            (identical(other.potTotal, potTotal) ||
                other.potTotal == potTotal) &&
            (identical(other.sidePots, sidePots) ||
                other.sidePots == sidePots) &&
            (identical(other.currentStreet, currentStreet) ||
                other.currentStreet == currentStreet) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt) &&
            (identical(other.durationSec, durationSec) ||
                other.durationSec == durationSec) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.anteAmount, anteAmount) ||
                other.anteAmount == anteAmount) &&
            (identical(other.straddleAmount, straddleAmount) ||
                other.straddleAmount == straddleAmount) &&
            (identical(other.runItTwiceCount, runItTwiceCount) ||
                other.runItTwiceCount == runItTwiceCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      handId,
      tableId,
      handNumber,
      gameType,
      betStructure,
      dealerSeat,
      boardCards,
      potTotal,
      sidePots,
      currentStreet,
      startedAt,
      endedAt,
      durationSec,
      createdAt,
      anteAmount,
      straddleAmount,
      runItTwiceCount);

  /// Create a copy of Hand
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HandImplCopyWith<_$HandImpl> get copyWith =>
      __$$HandImplCopyWithImpl<_$HandImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HandImplToJson(
      this,
    );
  }
}

abstract class _Hand implements Hand {
  const factory _Hand(
          {@JsonKey(name: 'handId') required final int handId,
          @JsonKey(name: 'tableId') required final int tableId,
          @JsonKey(name: 'handNumber') required final int handNumber,
          @JsonKey(name: 'gameType') required final int gameType,
          @JsonKey(name: 'betStructure') required final int betStructure,
          @JsonKey(name: 'dealerSeat') required final int dealerSeat,
          @JsonKey(name: 'boardCards') required final String boardCards,
          @JsonKey(name: 'potTotal') required final int potTotal,
          @JsonKey(name: 'sidePots') required final String sidePots,
          @JsonKey(name: 'currentStreet') final String? currentStreet,
          @JsonKey(name: 'startedAt') required final String startedAt,
          @JsonKey(name: 'endedAt') final String? endedAt,
          @JsonKey(name: 'durationSec') required final int durationSec,
          @JsonKey(name: 'createdAt') required final String createdAt,
          @JsonKey(name: 'anteAmount') final int anteAmount,
          @JsonKey(name: 'straddleAmount') final int? straddleAmount,
          @JsonKey(name: 'runItTwiceCount') final int runItTwiceCount}) =
      _$HandImpl;

  factory _Hand.fromJson(Map<String, dynamic> json) = _$HandImpl.fromJson;

  @override
  @JsonKey(name: 'handId')
  int get handId;
  @override
  @JsonKey(name: 'tableId')
  int get tableId;
  @override
  @JsonKey(name: 'handNumber')
  int get handNumber;
  @override
  @JsonKey(name: 'gameType')
  int get gameType;
  @override
  @JsonKey(name: 'betStructure')
  int get betStructure;
  @override
  @JsonKey(name: 'dealerSeat')
  int get dealerSeat;
  @override
  @JsonKey(name: 'boardCards')
  String get boardCards;
  @override
  @JsonKey(name: 'potTotal')
  int get potTotal;
  @override
  @JsonKey(name: 'sidePots')
  String get sidePots;
  @override
  @JsonKey(name: 'currentStreet')
  String? get currentStreet;
  @override
  @JsonKey(name: 'startedAt')
  String get startedAt;
  @override
  @JsonKey(name: 'endedAt')
  String? get endedAt;
  @override
  @JsonKey(name: 'durationSec')
  int get durationSec;
  @override
  @JsonKey(name: 'createdAt')
  String get createdAt; // v03 game-rules fields (Cycle 7, #329)
  @override
  @JsonKey(name: 'anteAmount')
  int get anteAmount;
  @override
  @JsonKey(name: 'straddleAmount')
  int? get straddleAmount;
  @override
  @JsonKey(name: 'runItTwiceCount')
  int get runItTwiceCount;

  /// Create a copy of Hand
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HandImplCopyWith<_$HandImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
