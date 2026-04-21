// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hand_player.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

HandPlayer _$HandPlayerFromJson(Map<String, dynamic> json) {
  return _HandPlayer.fromJson(json);
}

/// @nodoc
mixin _$HandPlayer {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'handId')
  int get handId => throw _privateConstructorUsedError;
  @JsonKey(name: 'seatNo')
  int get seatNo => throw _privateConstructorUsedError;
  @JsonKey(name: 'playerId')
  int? get playerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'playerName')
  String get playerName => throw _privateConstructorUsedError;
  @JsonKey(name: 'holeCards')
  String get holeCards => throw _privateConstructorUsedError;
  @JsonKey(name: 'startStack')
  int get startStack => throw _privateConstructorUsedError;
  @JsonKey(name: 'endStack')
  int get endStack => throw _privateConstructorUsedError;
  @JsonKey(name: 'finalAction')
  String? get finalAction => throw _privateConstructorUsedError;
  @JsonKey(name: 'isWinner')
  bool get isWinner => throw _privateConstructorUsedError;
  int get pnl => throw _privateConstructorUsedError;
  @JsonKey(name: 'handRank')
  String? get handRank => throw _privateConstructorUsedError;
  @JsonKey(name: 'winProbability')
  double? get winProbability => throw _privateConstructorUsedError;
  bool get vpip => throw _privateConstructorUsedError;
  bool get pfr => throw _privateConstructorUsedError;

  /// Serializes this HandPlayer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HandPlayer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HandPlayerCopyWith<HandPlayer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HandPlayerCopyWith<$Res> {
  factory $HandPlayerCopyWith(
          HandPlayer value, $Res Function(HandPlayer) then) =
      _$HandPlayerCopyWithImpl<$Res, HandPlayer>;
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'handId') int handId,
      @JsonKey(name: 'seatNo') int seatNo,
      @JsonKey(name: 'playerId') int? playerId,
      @JsonKey(name: 'playerName') String playerName,
      @JsonKey(name: 'holeCards') String holeCards,
      @JsonKey(name: 'startStack') int startStack,
      @JsonKey(name: 'endStack') int endStack,
      @JsonKey(name: 'finalAction') String? finalAction,
      @JsonKey(name: 'isWinner') bool isWinner,
      int pnl,
      @JsonKey(name: 'handRank') String? handRank,
      @JsonKey(name: 'winProbability') double? winProbability,
      bool vpip,
      bool pfr});
}

/// @nodoc
class _$HandPlayerCopyWithImpl<$Res, $Val extends HandPlayer>
    implements $HandPlayerCopyWith<$Res> {
  _$HandPlayerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HandPlayer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? handId = null,
    Object? seatNo = null,
    Object? playerId = freezed,
    Object? playerName = null,
    Object? holeCards = null,
    Object? startStack = null,
    Object? endStack = null,
    Object? finalAction = freezed,
    Object? isWinner = null,
    Object? pnl = null,
    Object? handRank = freezed,
    Object? winProbability = freezed,
    Object? vpip = null,
    Object? pfr = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      handId: null == handId
          ? _value.handId
          : handId // ignore: cast_nullable_to_non_nullable
              as int,
      seatNo: null == seatNo
          ? _value.seatNo
          : seatNo // ignore: cast_nullable_to_non_nullable
              as int,
      playerId: freezed == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as int?,
      playerName: null == playerName
          ? _value.playerName
          : playerName // ignore: cast_nullable_to_non_nullable
              as String,
      holeCards: null == holeCards
          ? _value.holeCards
          : holeCards // ignore: cast_nullable_to_non_nullable
              as String,
      startStack: null == startStack
          ? _value.startStack
          : startStack // ignore: cast_nullable_to_non_nullable
              as int,
      endStack: null == endStack
          ? _value.endStack
          : endStack // ignore: cast_nullable_to_non_nullable
              as int,
      finalAction: freezed == finalAction
          ? _value.finalAction
          : finalAction // ignore: cast_nullable_to_non_nullable
              as String?,
      isWinner: null == isWinner
          ? _value.isWinner
          : isWinner // ignore: cast_nullable_to_non_nullable
              as bool,
      pnl: null == pnl
          ? _value.pnl
          : pnl // ignore: cast_nullable_to_non_nullable
              as int,
      handRank: freezed == handRank
          ? _value.handRank
          : handRank // ignore: cast_nullable_to_non_nullable
              as String?,
      winProbability: freezed == winProbability
          ? _value.winProbability
          : winProbability // ignore: cast_nullable_to_non_nullable
              as double?,
      vpip: null == vpip
          ? _value.vpip
          : vpip // ignore: cast_nullable_to_non_nullable
              as bool,
      pfr: null == pfr
          ? _value.pfr
          : pfr // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HandPlayerImplCopyWith<$Res>
    implements $HandPlayerCopyWith<$Res> {
  factory _$$HandPlayerImplCopyWith(
          _$HandPlayerImpl value, $Res Function(_$HandPlayerImpl) then) =
      __$$HandPlayerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'handId') int handId,
      @JsonKey(name: 'seatNo') int seatNo,
      @JsonKey(name: 'playerId') int? playerId,
      @JsonKey(name: 'playerName') String playerName,
      @JsonKey(name: 'holeCards') String holeCards,
      @JsonKey(name: 'startStack') int startStack,
      @JsonKey(name: 'endStack') int endStack,
      @JsonKey(name: 'finalAction') String? finalAction,
      @JsonKey(name: 'isWinner') bool isWinner,
      int pnl,
      @JsonKey(name: 'handRank') String? handRank,
      @JsonKey(name: 'winProbability') double? winProbability,
      bool vpip,
      bool pfr});
}

/// @nodoc
class __$$HandPlayerImplCopyWithImpl<$Res>
    extends _$HandPlayerCopyWithImpl<$Res, _$HandPlayerImpl>
    implements _$$HandPlayerImplCopyWith<$Res> {
  __$$HandPlayerImplCopyWithImpl(
      _$HandPlayerImpl _value, $Res Function(_$HandPlayerImpl) _then)
      : super(_value, _then);

  /// Create a copy of HandPlayer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? handId = null,
    Object? seatNo = null,
    Object? playerId = freezed,
    Object? playerName = null,
    Object? holeCards = null,
    Object? startStack = null,
    Object? endStack = null,
    Object? finalAction = freezed,
    Object? isWinner = null,
    Object? pnl = null,
    Object? handRank = freezed,
    Object? winProbability = freezed,
    Object? vpip = null,
    Object? pfr = null,
  }) {
    return _then(_$HandPlayerImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      handId: null == handId
          ? _value.handId
          : handId // ignore: cast_nullable_to_non_nullable
              as int,
      seatNo: null == seatNo
          ? _value.seatNo
          : seatNo // ignore: cast_nullable_to_non_nullable
              as int,
      playerId: freezed == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as int?,
      playerName: null == playerName
          ? _value.playerName
          : playerName // ignore: cast_nullable_to_non_nullable
              as String,
      holeCards: null == holeCards
          ? _value.holeCards
          : holeCards // ignore: cast_nullable_to_non_nullable
              as String,
      startStack: null == startStack
          ? _value.startStack
          : startStack // ignore: cast_nullable_to_non_nullable
              as int,
      endStack: null == endStack
          ? _value.endStack
          : endStack // ignore: cast_nullable_to_non_nullable
              as int,
      finalAction: freezed == finalAction
          ? _value.finalAction
          : finalAction // ignore: cast_nullable_to_non_nullable
              as String?,
      isWinner: null == isWinner
          ? _value.isWinner
          : isWinner // ignore: cast_nullable_to_non_nullable
              as bool,
      pnl: null == pnl
          ? _value.pnl
          : pnl // ignore: cast_nullable_to_non_nullable
              as int,
      handRank: freezed == handRank
          ? _value.handRank
          : handRank // ignore: cast_nullable_to_non_nullable
              as String?,
      winProbability: freezed == winProbability
          ? _value.winProbability
          : winProbability // ignore: cast_nullable_to_non_nullable
              as double?,
      vpip: null == vpip
          ? _value.vpip
          : vpip // ignore: cast_nullable_to_non_nullable
              as bool,
      pfr: null == pfr
          ? _value.pfr
          : pfr // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HandPlayerImpl implements _HandPlayer {
  const _$HandPlayerImpl(
      {required this.id,
      @JsonKey(name: 'handId') required this.handId,
      @JsonKey(name: 'seatNo') required this.seatNo,
      @JsonKey(name: 'playerId') this.playerId,
      @JsonKey(name: 'playerName') required this.playerName,
      @JsonKey(name: 'holeCards') required this.holeCards,
      @JsonKey(name: 'startStack') required this.startStack,
      @JsonKey(name: 'endStack') required this.endStack,
      @JsonKey(name: 'finalAction') this.finalAction,
      @JsonKey(name: 'isWinner') required this.isWinner,
      required this.pnl,
      @JsonKey(name: 'handRank') this.handRank,
      @JsonKey(name: 'winProbability') this.winProbability,
      required this.vpip,
      required this.pfr});

  factory _$HandPlayerImpl.fromJson(Map<String, dynamic> json) =>
      _$$HandPlayerImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(name: 'handId')
  final int handId;
  @override
  @JsonKey(name: 'seatNo')
  final int seatNo;
  @override
  @JsonKey(name: 'playerId')
  final int? playerId;
  @override
  @JsonKey(name: 'playerName')
  final String playerName;
  @override
  @JsonKey(name: 'holeCards')
  final String holeCards;
  @override
  @JsonKey(name: 'startStack')
  final int startStack;
  @override
  @JsonKey(name: 'endStack')
  final int endStack;
  @override
  @JsonKey(name: 'finalAction')
  final String? finalAction;
  @override
  @JsonKey(name: 'isWinner')
  final bool isWinner;
  @override
  final int pnl;
  @override
  @JsonKey(name: 'handRank')
  final String? handRank;
  @override
  @JsonKey(name: 'winProbability')
  final double? winProbability;
  @override
  final bool vpip;
  @override
  final bool pfr;

  @override
  String toString() {
    return 'HandPlayer(id: $id, handId: $handId, seatNo: $seatNo, playerId: $playerId, playerName: $playerName, holeCards: $holeCards, startStack: $startStack, endStack: $endStack, finalAction: $finalAction, isWinner: $isWinner, pnl: $pnl, handRank: $handRank, winProbability: $winProbability, vpip: $vpip, pfr: $pfr)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HandPlayerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.handId, handId) || other.handId == handId) &&
            (identical(other.seatNo, seatNo) || other.seatNo == seatNo) &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.playerName, playerName) ||
                other.playerName == playerName) &&
            (identical(other.holeCards, holeCards) ||
                other.holeCards == holeCards) &&
            (identical(other.startStack, startStack) ||
                other.startStack == startStack) &&
            (identical(other.endStack, endStack) ||
                other.endStack == endStack) &&
            (identical(other.finalAction, finalAction) ||
                other.finalAction == finalAction) &&
            (identical(other.isWinner, isWinner) ||
                other.isWinner == isWinner) &&
            (identical(other.pnl, pnl) || other.pnl == pnl) &&
            (identical(other.handRank, handRank) ||
                other.handRank == handRank) &&
            (identical(other.winProbability, winProbability) ||
                other.winProbability == winProbability) &&
            (identical(other.vpip, vpip) || other.vpip == vpip) &&
            (identical(other.pfr, pfr) || other.pfr == pfr));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      handId,
      seatNo,
      playerId,
      playerName,
      holeCards,
      startStack,
      endStack,
      finalAction,
      isWinner,
      pnl,
      handRank,
      winProbability,
      vpip,
      pfr);

  /// Create a copy of HandPlayer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HandPlayerImplCopyWith<_$HandPlayerImpl> get copyWith =>
      __$$HandPlayerImplCopyWithImpl<_$HandPlayerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HandPlayerImplToJson(
      this,
    );
  }
}

abstract class _HandPlayer implements HandPlayer {
  const factory _HandPlayer(
      {required final int id,
      @JsonKey(name: 'handId') required final int handId,
      @JsonKey(name: 'seatNo') required final int seatNo,
      @JsonKey(name: 'playerId') final int? playerId,
      @JsonKey(name: 'playerName') required final String playerName,
      @JsonKey(name: 'holeCards') required final String holeCards,
      @JsonKey(name: 'startStack') required final int startStack,
      @JsonKey(name: 'endStack') required final int endStack,
      @JsonKey(name: 'finalAction') final String? finalAction,
      @JsonKey(name: 'isWinner') required final bool isWinner,
      required final int pnl,
      @JsonKey(name: 'handRank') final String? handRank,
      @JsonKey(name: 'winProbability') final double? winProbability,
      required final bool vpip,
      required final bool pfr}) = _$HandPlayerImpl;

  factory _HandPlayer.fromJson(Map<String, dynamic> json) =
      _$HandPlayerImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'handId')
  int get handId;
  @override
  @JsonKey(name: 'seatNo')
  int get seatNo;
  @override
  @JsonKey(name: 'playerId')
  int? get playerId;
  @override
  @JsonKey(name: 'playerName')
  String get playerName;
  @override
  @JsonKey(name: 'holeCards')
  String get holeCards;
  @override
  @JsonKey(name: 'startStack')
  int get startStack;
  @override
  @JsonKey(name: 'endStack')
  int get endStack;
  @override
  @JsonKey(name: 'finalAction')
  String? get finalAction;
  @override
  @JsonKey(name: 'isWinner')
  bool get isWinner;
  @override
  int get pnl;
  @override
  @JsonKey(name: 'handRank')
  String? get handRank;
  @override
  @JsonKey(name: 'winProbability')
  double? get winProbability;
  @override
  bool get vpip;
  @override
  bool get pfr;

  /// Create a copy of HandPlayer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HandPlayerImplCopyWith<_$HandPlayerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
