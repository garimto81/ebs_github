// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'seat_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$HoleCard {
  String get suit => throw _privateConstructorUsedError; // "s", "h", "d", "c"
  String get rank => throw _privateConstructorUsedError;

  /// Create a copy of HoleCard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HoleCardCopyWith<HoleCard> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HoleCardCopyWith<$Res> {
  factory $HoleCardCopyWith(HoleCard value, $Res Function(HoleCard) then) =
      _$HoleCardCopyWithImpl<$Res, HoleCard>;
  @useResult
  $Res call({String suit, String rank});
}

/// @nodoc
class _$HoleCardCopyWithImpl<$Res, $Val extends HoleCard>
    implements $HoleCardCopyWith<$Res> {
  _$HoleCardCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HoleCard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? suit = null,
    Object? rank = null,
  }) {
    return _then(_value.copyWith(
      suit: null == suit
          ? _value.suit
          : suit // ignore: cast_nullable_to_non_nullable
              as String,
      rank: null == rank
          ? _value.rank
          : rank // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HoleCardImplCopyWith<$Res>
    implements $HoleCardCopyWith<$Res> {
  factory _$$HoleCardImplCopyWith(
          _$HoleCardImpl value, $Res Function(_$HoleCardImpl) then) =
      __$$HoleCardImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String suit, String rank});
}

/// @nodoc
class __$$HoleCardImplCopyWithImpl<$Res>
    extends _$HoleCardCopyWithImpl<$Res, _$HoleCardImpl>
    implements _$$HoleCardImplCopyWith<$Res> {
  __$$HoleCardImplCopyWithImpl(
      _$HoleCardImpl _value, $Res Function(_$HoleCardImpl) _then)
      : super(_value, _then);

  /// Create a copy of HoleCard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? suit = null,
    Object? rank = null,
  }) {
    return _then(_$HoleCardImpl(
      suit: null == suit
          ? _value.suit
          : suit // ignore: cast_nullable_to_non_nullable
              as String,
      rank: null == rank
          ? _value.rank
          : rank // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$HoleCardImpl extends _HoleCard {
  const _$HoleCardImpl({required this.suit, required this.rank}) : super._();

  @override
  final String suit;
// "s", "h", "d", "c"
  @override
  final String rank;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HoleCardImpl &&
            (identical(other.suit, suit) || other.suit == suit) &&
            (identical(other.rank, rank) || other.rank == rank));
  }

  @override
  int get hashCode => Object.hash(runtimeType, suit, rank);

  /// Create a copy of HoleCard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HoleCardImplCopyWith<_$HoleCardImpl> get copyWith =>
      __$$HoleCardImplCopyWithImpl<_$HoleCardImpl>(this, _$identity);
}

abstract class _HoleCard extends HoleCard {
  const factory _HoleCard(
      {required final String suit,
      required final String rank}) = _$HoleCardImpl;
  const _HoleCard._() : super._();

  @override
  String get suit; // "s", "h", "d", "c"
  @override
  String get rank;

  /// Create a copy of HoleCard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HoleCardImplCopyWith<_$HoleCardImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PlayerInfo {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get stack => throw _privateConstructorUsedError;
  String get countryCode => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;

  /// Create a copy of PlayerInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerInfoCopyWith<PlayerInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerInfoCopyWith<$Res> {
  factory $PlayerInfoCopyWith(
          PlayerInfo value, $Res Function(PlayerInfo) then) =
      _$PlayerInfoCopyWithImpl<$Res, PlayerInfo>;
  @useResult
  $Res call(
      {int id, String name, int stack, String countryCode, String? avatarUrl});
}

/// @nodoc
class _$PlayerInfoCopyWithImpl<$Res, $Val extends PlayerInfo>
    implements $PlayerInfoCopyWith<$Res> {
  _$PlayerInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? stack = null,
    Object? countryCode = null,
    Object? avatarUrl = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      stack: null == stack
          ? _value.stack
          : stack // ignore: cast_nullable_to_non_nullable
              as int,
      countryCode: null == countryCode
          ? _value.countryCode
          : countryCode // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlayerInfoImplCopyWith<$Res>
    implements $PlayerInfoCopyWith<$Res> {
  factory _$$PlayerInfoImplCopyWith(
          _$PlayerInfoImpl value, $Res Function(_$PlayerInfoImpl) then) =
      __$$PlayerInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id, String name, int stack, String countryCode, String? avatarUrl});
}

/// @nodoc
class __$$PlayerInfoImplCopyWithImpl<$Res>
    extends _$PlayerInfoCopyWithImpl<$Res, _$PlayerInfoImpl>
    implements _$$PlayerInfoImplCopyWith<$Res> {
  __$$PlayerInfoImplCopyWithImpl(
      _$PlayerInfoImpl _value, $Res Function(_$PlayerInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of PlayerInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? stack = null,
    Object? countryCode = null,
    Object? avatarUrl = freezed,
  }) {
    return _then(_$PlayerInfoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      stack: null == stack
          ? _value.stack
          : stack // ignore: cast_nullable_to_non_nullable
              as int,
      countryCode: null == countryCode
          ? _value.countryCode
          : countryCode // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$PlayerInfoImpl implements _PlayerInfo {
  const _$PlayerInfoImpl(
      {required this.id,
      required this.name,
      this.stack = 0,
      this.countryCode = '',
      this.avatarUrl});

  @override
  final int id;
  @override
  final String name;
  @override
  @JsonKey()
  final int stack;
  @override
  @JsonKey()
  final String countryCode;
  @override
  final String? avatarUrl;

  @override
  String toString() {
    return 'PlayerInfo(id: $id, name: $name, stack: $stack, countryCode: $countryCode, avatarUrl: $avatarUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerInfoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.stack, stack) || other.stack == stack) &&
            (identical(other.countryCode, countryCode) ||
                other.countryCode == countryCode) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, stack, countryCode, avatarUrl);

  /// Create a copy of PlayerInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerInfoImplCopyWith<_$PlayerInfoImpl> get copyWith =>
      __$$PlayerInfoImplCopyWithImpl<_$PlayerInfoImpl>(this, _$identity);
}

abstract class _PlayerInfo implements PlayerInfo {
  const factory _PlayerInfo(
      {required final int id,
      required final String name,
      final int stack,
      final String countryCode,
      final String? avatarUrl}) = _$PlayerInfoImpl;

  @override
  int get id;
  @override
  String get name;
  @override
  int get stack;
  @override
  String get countryCode;
  @override
  String? get avatarUrl;

  /// Create a copy of PlayerInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerInfoImplCopyWith<_$PlayerInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SeatState {
  int get seatNo => throw _privateConstructorUsedError; // 1-based (1..10)
  SeatStatus get status => throw _privateConstructorUsedError;
  PlayerActivity get activity => throw _privateConstructorUsedError;
  PlayerInfo? get player => throw _privateConstructorUsedError;
  bool get isDealer => throw _privateConstructorUsedError;
  bool get isSB => throw _privateConstructorUsedError;
  bool get isBB => throw _privateConstructorUsedError;
  bool get actionOn => throw _privateConstructorUsedError;
  List<HoleCard> get holeCards => throw _privateConstructorUsedError;
  int get currentBet =>
      throw _privateConstructorUsedError; // Cycle 20 #437 — WSOP LIVE chip_count_synced timestamp. Set when the BO
// forwards a webhook snapshot that touches this seat. Drives the 1s glow
// tint in SeatCell. Null = never synced from WSOP LIVE (Engine-auto).
  DateTime? get lastChipUpdate => throw _privateConstructorUsedError;

  /// Create a copy of SeatState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SeatStateCopyWith<SeatState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SeatStateCopyWith<$Res> {
  factory $SeatStateCopyWith(SeatState value, $Res Function(SeatState) then) =
      _$SeatStateCopyWithImpl<$Res, SeatState>;
  @useResult
  $Res call(
      {int seatNo,
      SeatStatus status,
      PlayerActivity activity,
      PlayerInfo? player,
      bool isDealer,
      bool isSB,
      bool isBB,
      bool actionOn,
      List<HoleCard> holeCards,
      int currentBet,
      DateTime? lastChipUpdate});

  $PlayerInfoCopyWith<$Res>? get player;
}

/// @nodoc
class _$SeatStateCopyWithImpl<$Res, $Val extends SeatState>
    implements $SeatStateCopyWith<$Res> {
  _$SeatStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SeatState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seatNo = null,
    Object? status = null,
    Object? activity = null,
    Object? player = freezed,
    Object? isDealer = null,
    Object? isSB = null,
    Object? isBB = null,
    Object? actionOn = null,
    Object? holeCards = null,
    Object? currentBet = null,
    Object? lastChipUpdate = freezed,
  }) {
    return _then(_value.copyWith(
      seatNo: null == seatNo
          ? _value.seatNo
          : seatNo // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SeatStatus,
      activity: null == activity
          ? _value.activity
          : activity // ignore: cast_nullable_to_non_nullable
              as PlayerActivity,
      player: freezed == player
          ? _value.player
          : player // ignore: cast_nullable_to_non_nullable
              as PlayerInfo?,
      isDealer: null == isDealer
          ? _value.isDealer
          : isDealer // ignore: cast_nullable_to_non_nullable
              as bool,
      isSB: null == isSB
          ? _value.isSB
          : isSB // ignore: cast_nullable_to_non_nullable
              as bool,
      isBB: null == isBB
          ? _value.isBB
          : isBB // ignore: cast_nullable_to_non_nullable
              as bool,
      actionOn: null == actionOn
          ? _value.actionOn
          : actionOn // ignore: cast_nullable_to_non_nullable
              as bool,
      holeCards: null == holeCards
          ? _value.holeCards
          : holeCards // ignore: cast_nullable_to_non_nullable
              as List<HoleCard>,
      currentBet: null == currentBet
          ? _value.currentBet
          : currentBet // ignore: cast_nullable_to_non_nullable
              as int,
      lastChipUpdate: freezed == lastChipUpdate
          ? _value.lastChipUpdate
          : lastChipUpdate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  /// Create a copy of SeatState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlayerInfoCopyWith<$Res>? get player {
    if (_value.player == null) {
      return null;
    }

    return $PlayerInfoCopyWith<$Res>(_value.player!, (value) {
      return _then(_value.copyWith(player: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SeatStateImplCopyWith<$Res>
    implements $SeatStateCopyWith<$Res> {
  factory _$$SeatStateImplCopyWith(
          _$SeatStateImpl value, $Res Function(_$SeatStateImpl) then) =
      __$$SeatStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int seatNo,
      SeatStatus status,
      PlayerActivity activity,
      PlayerInfo? player,
      bool isDealer,
      bool isSB,
      bool isBB,
      bool actionOn,
      List<HoleCard> holeCards,
      int currentBet,
      DateTime? lastChipUpdate});

  @override
  $PlayerInfoCopyWith<$Res>? get player;
}

/// @nodoc
class __$$SeatStateImplCopyWithImpl<$Res>
    extends _$SeatStateCopyWithImpl<$Res, _$SeatStateImpl>
    implements _$$SeatStateImplCopyWith<$Res> {
  __$$SeatStateImplCopyWithImpl(
      _$SeatStateImpl _value, $Res Function(_$SeatStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of SeatState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seatNo = null,
    Object? status = null,
    Object? activity = null,
    Object? player = freezed,
    Object? isDealer = null,
    Object? isSB = null,
    Object? isBB = null,
    Object? actionOn = null,
    Object? holeCards = null,
    Object? currentBet = null,
    Object? lastChipUpdate = freezed,
  }) {
    return _then(_$SeatStateImpl(
      seatNo: null == seatNo
          ? _value.seatNo
          : seatNo // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SeatStatus,
      activity: null == activity
          ? _value.activity
          : activity // ignore: cast_nullable_to_non_nullable
              as PlayerActivity,
      player: freezed == player
          ? _value.player
          : player // ignore: cast_nullable_to_non_nullable
              as PlayerInfo?,
      isDealer: null == isDealer
          ? _value.isDealer
          : isDealer // ignore: cast_nullable_to_non_nullable
              as bool,
      isSB: null == isSB
          ? _value.isSB
          : isSB // ignore: cast_nullable_to_non_nullable
              as bool,
      isBB: null == isBB
          ? _value.isBB
          : isBB // ignore: cast_nullable_to_non_nullable
              as bool,
      actionOn: null == actionOn
          ? _value.actionOn
          : actionOn // ignore: cast_nullable_to_non_nullable
              as bool,
      holeCards: null == holeCards
          ? _value._holeCards
          : holeCards // ignore: cast_nullable_to_non_nullable
              as List<HoleCard>,
      currentBet: null == currentBet
          ? _value.currentBet
          : currentBet // ignore: cast_nullable_to_non_nullable
              as int,
      lastChipUpdate: freezed == lastChipUpdate
          ? _value.lastChipUpdate
          : lastChipUpdate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$SeatStateImpl extends _SeatState {
  const _$SeatStateImpl(
      {required this.seatNo,
      this.status = SeatStatus.empty,
      this.activity = PlayerActivity.active,
      this.player,
      this.isDealer = false,
      this.isSB = false,
      this.isBB = false,
      this.actionOn = false,
      final List<HoleCard> holeCards = const [],
      this.currentBet = 0,
      this.lastChipUpdate})
      : _holeCards = holeCards,
        super._();

  @override
  final int seatNo;
// 1-based (1..10)
  @override
  @JsonKey()
  final SeatStatus status;
  @override
  @JsonKey()
  final PlayerActivity activity;
  @override
  final PlayerInfo? player;
  @override
  @JsonKey()
  final bool isDealer;
  @override
  @JsonKey()
  final bool isSB;
  @override
  @JsonKey()
  final bool isBB;
  @override
  @JsonKey()
  final bool actionOn;
  final List<HoleCard> _holeCards;
  @override
  @JsonKey()
  List<HoleCard> get holeCards {
    if (_holeCards is EqualUnmodifiableListView) return _holeCards;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_holeCards);
  }

  @override
  @JsonKey()
  final int currentBet;
// Cycle 20 #437 — WSOP LIVE chip_count_synced timestamp. Set when the BO
// forwards a webhook snapshot that touches this seat. Drives the 1s glow
// tint in SeatCell. Null = never synced from WSOP LIVE (Engine-auto).
  @override
  final DateTime? lastChipUpdate;

  @override
  String toString() {
    return 'SeatState(seatNo: $seatNo, status: $status, activity: $activity, player: $player, isDealer: $isDealer, isSB: $isSB, isBB: $isBB, actionOn: $actionOn, holeCards: $holeCards, currentBet: $currentBet, lastChipUpdate: $lastChipUpdate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SeatStateImpl &&
            (identical(other.seatNo, seatNo) || other.seatNo == seatNo) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.activity, activity) ||
                other.activity == activity) &&
            (identical(other.player, player) || other.player == player) &&
            (identical(other.isDealer, isDealer) ||
                other.isDealer == isDealer) &&
            (identical(other.isSB, isSB) || other.isSB == isSB) &&
            (identical(other.isBB, isBB) || other.isBB == isBB) &&
            (identical(other.actionOn, actionOn) ||
                other.actionOn == actionOn) &&
            const DeepCollectionEquality()
                .equals(other._holeCards, _holeCards) &&
            (identical(other.currentBet, currentBet) ||
                other.currentBet == currentBet) &&
            (identical(other.lastChipUpdate, lastChipUpdate) ||
                other.lastChipUpdate == lastChipUpdate));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      seatNo,
      status,
      activity,
      player,
      isDealer,
      isSB,
      isBB,
      actionOn,
      const DeepCollectionEquality().hash(_holeCards),
      currentBet,
      lastChipUpdate);

  /// Create a copy of SeatState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SeatStateImplCopyWith<_$SeatStateImpl> get copyWith =>
      __$$SeatStateImplCopyWithImpl<_$SeatStateImpl>(this, _$identity);
}

abstract class _SeatState extends SeatState {
  const factory _SeatState(
      {required final int seatNo,
      final SeatStatus status,
      final PlayerActivity activity,
      final PlayerInfo? player,
      final bool isDealer,
      final bool isSB,
      final bool isBB,
      final bool actionOn,
      final List<HoleCard> holeCards,
      final int currentBet,
      final DateTime? lastChipUpdate}) = _$SeatStateImpl;
  const _SeatState._() : super._();

  @override
  int get seatNo; // 1-based (1..10)
  @override
  SeatStatus get status;
  @override
  PlayerActivity get activity;
  @override
  PlayerInfo? get player;
  @override
  bool get isDealer;
  @override
  bool get isSB;
  @override
  bool get isBB;
  @override
  bool get actionOn;
  @override
  List<HoleCard> get holeCards;
  @override
  int get currentBet; // Cycle 20 #437 — WSOP LIVE chip_count_synced timestamp. Set when the BO
// forwards a webhook snapshot that touches this seat. Drives the 1s glow
// tint in SeatCell. Null = never synced from WSOP LIVE (Engine-auto).
  @override
  DateTime? get lastChipUpdate;

  /// Create a copy of SeatState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SeatStateImplCopyWith<_$SeatStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
