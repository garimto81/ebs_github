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
  @JsonKey(name: 'hand_id')
  int get handId => throw _privateConstructorUsedError;
  @JsonKey(name: 'table_id')
  int get tableId => throw _privateConstructorUsedError;
  @JsonKey(name: 'hand_number')
  int get handNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'game_type')
  int get gameType => throw _privateConstructorUsedError;
  @JsonKey(name: 'bet_structure')
  int get betStructure => throw _privateConstructorUsedError;
  @JsonKey(name: 'dealer_seat')
  int get dealerSeat => throw _privateConstructorUsedError;
  @JsonKey(name: 'board_cards')
  String get boardCards => throw _privateConstructorUsedError;
  @JsonKey(name: 'pot_total')
  int get potTotal => throw _privateConstructorUsedError;
  @JsonKey(name: 'side_pots')
  String get sidePots => throw _privateConstructorUsedError;
  @JsonKey(name: 'current_street')
  String? get currentStreet => throw _privateConstructorUsedError;
  @JsonKey(name: 'started_at')
  String get startedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'ended_at')
  String? get endedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'duration_sec')
  int get durationSec => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;

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
      {@JsonKey(name: 'hand_id') int handId,
      @JsonKey(name: 'table_id') int tableId,
      @JsonKey(name: 'hand_number') int handNumber,
      @JsonKey(name: 'game_type') int gameType,
      @JsonKey(name: 'bet_structure') int betStructure,
      @JsonKey(name: 'dealer_seat') int dealerSeat,
      @JsonKey(name: 'board_cards') String boardCards,
      @JsonKey(name: 'pot_total') int potTotal,
      @JsonKey(name: 'side_pots') String sidePots,
      @JsonKey(name: 'current_street') String? currentStreet,
      @JsonKey(name: 'started_at') String startedAt,
      @JsonKey(name: 'ended_at') String? endedAt,
      @JsonKey(name: 'duration_sec') int durationSec,
      @JsonKey(name: 'created_at') String createdAt});
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
      {@JsonKey(name: 'hand_id') int handId,
      @JsonKey(name: 'table_id') int tableId,
      @JsonKey(name: 'hand_number') int handNumber,
      @JsonKey(name: 'game_type') int gameType,
      @JsonKey(name: 'bet_structure') int betStructure,
      @JsonKey(name: 'dealer_seat') int dealerSeat,
      @JsonKey(name: 'board_cards') String boardCards,
      @JsonKey(name: 'pot_total') int potTotal,
      @JsonKey(name: 'side_pots') String sidePots,
      @JsonKey(name: 'current_street') String? currentStreet,
      @JsonKey(name: 'started_at') String startedAt,
      @JsonKey(name: 'ended_at') String? endedAt,
      @JsonKey(name: 'duration_sec') int durationSec,
      @JsonKey(name: 'created_at') String createdAt});
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
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HandImpl implements _Hand {
  const _$HandImpl(
      {@JsonKey(name: 'hand_id') required this.handId,
      @JsonKey(name: 'table_id') required this.tableId,
      @JsonKey(name: 'hand_number') required this.handNumber,
      @JsonKey(name: 'game_type') required this.gameType,
      @JsonKey(name: 'bet_structure') required this.betStructure,
      @JsonKey(name: 'dealer_seat') required this.dealerSeat,
      @JsonKey(name: 'board_cards') required this.boardCards,
      @JsonKey(name: 'pot_total') required this.potTotal,
      @JsonKey(name: 'side_pots') required this.sidePots,
      @JsonKey(name: 'current_street') this.currentStreet,
      @JsonKey(name: 'started_at') required this.startedAt,
      @JsonKey(name: 'ended_at') this.endedAt,
      @JsonKey(name: 'duration_sec') required this.durationSec,
      @JsonKey(name: 'created_at') required this.createdAt});

  factory _$HandImpl.fromJson(Map<String, dynamic> json) =>
      _$$HandImplFromJson(json);

  @override
  @JsonKey(name: 'hand_id')
  final int handId;
  @override
  @JsonKey(name: 'table_id')
  final int tableId;
  @override
  @JsonKey(name: 'hand_number')
  final int handNumber;
  @override
  @JsonKey(name: 'game_type')
  final int gameType;
  @override
  @JsonKey(name: 'bet_structure')
  final int betStructure;
  @override
  @JsonKey(name: 'dealer_seat')
  final int dealerSeat;
  @override
  @JsonKey(name: 'board_cards')
  final String boardCards;
  @override
  @JsonKey(name: 'pot_total')
  final int potTotal;
  @override
  @JsonKey(name: 'side_pots')
  final String sidePots;
  @override
  @JsonKey(name: 'current_street')
  final String? currentStreet;
  @override
  @JsonKey(name: 'started_at')
  final String startedAt;
  @override
  @JsonKey(name: 'ended_at')
  final String? endedAt;
  @override
  @JsonKey(name: 'duration_sec')
  final int durationSec;
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;

  @override
  String toString() {
    return 'Hand(handId: $handId, tableId: $tableId, handNumber: $handNumber, gameType: $gameType, betStructure: $betStructure, dealerSeat: $dealerSeat, boardCards: $boardCards, potTotal: $potTotal, sidePots: $sidePots, currentStreet: $currentStreet, startedAt: $startedAt, endedAt: $endedAt, durationSec: $durationSec, createdAt: $createdAt)';
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
                other.createdAt == createdAt));
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
      createdAt);

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
          {@JsonKey(name: 'hand_id') required final int handId,
          @JsonKey(name: 'table_id') required final int tableId,
          @JsonKey(name: 'hand_number') required final int handNumber,
          @JsonKey(name: 'game_type') required final int gameType,
          @JsonKey(name: 'bet_structure') required final int betStructure,
          @JsonKey(name: 'dealer_seat') required final int dealerSeat,
          @JsonKey(name: 'board_cards') required final String boardCards,
          @JsonKey(name: 'pot_total') required final int potTotal,
          @JsonKey(name: 'side_pots') required final String sidePots,
          @JsonKey(name: 'current_street') final String? currentStreet,
          @JsonKey(name: 'started_at') required final String startedAt,
          @JsonKey(name: 'ended_at') final String? endedAt,
          @JsonKey(name: 'duration_sec') required final int durationSec,
          @JsonKey(name: 'created_at') required final String createdAt}) =
      _$HandImpl;

  factory _Hand.fromJson(Map<String, dynamic> json) = _$HandImpl.fromJson;

  @override
  @JsonKey(name: 'hand_id')
  int get handId;
  @override
  @JsonKey(name: 'table_id')
  int get tableId;
  @override
  @JsonKey(name: 'hand_number')
  int get handNumber;
  @override
  @JsonKey(name: 'game_type')
  int get gameType;
  @override
  @JsonKey(name: 'bet_structure')
  int get betStructure;
  @override
  @JsonKey(name: 'dealer_seat')
  int get dealerSeat;
  @override
  @JsonKey(name: 'board_cards')
  String get boardCards;
  @override
  @JsonKey(name: 'pot_total')
  int get potTotal;
  @override
  @JsonKey(name: 'side_pots')
  String get sidePots;
  @override
  @JsonKey(name: 'current_street')
  String? get currentStreet;
  @override
  @JsonKey(name: 'started_at')
  String get startedAt;
  @override
  @JsonKey(name: 'ended_at')
  String? get endedAt;
  @override
  @JsonKey(name: 'duration_sec')
  int get durationSec;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;

  /// Create a copy of Hand
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HandImplCopyWith<_$HandImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
