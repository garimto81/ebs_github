// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ebs_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

EbsEvent _$EbsEventFromJson(Map<String, dynamic> json) {
  return _EbsEvent.fromJson(json);
}

/// @nodoc
mixin _$EbsEvent {
  @JsonKey(name: 'event_id')
  int get eventId => throw _privateConstructorUsedError;
  @JsonKey(name: 'series_id')
  int get seriesId => throw _privateConstructorUsedError;
  @JsonKey(name: 'event_no')
  int get eventNo => throw _privateConstructorUsedError;
  @JsonKey(name: 'event_name')
  String get eventName => throw _privateConstructorUsedError;
  @JsonKey(name: 'buy_in')
  int? get buyIn => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_buy_in')
  String? get displayBuyIn => throw _privateConstructorUsedError;
  @JsonKey(name: 'game_type')
  int get gameType => throw _privateConstructorUsedError;
  @JsonKey(name: 'bet_structure')
  int get betStructure => throw _privateConstructorUsedError;
  @JsonKey(name: 'event_game_type')
  int get eventGameType => throw _privateConstructorUsedError;
  @JsonKey(name: 'game_mode')
  String get gameMode => throw _privateConstructorUsedError;
  @JsonKey(name: 'allowed_games')
  String? get allowedGames => throw _privateConstructorUsedError;
  @JsonKey(name: 'rotation_order')
  String? get rotationOrder => throw _privateConstructorUsedError;
  @JsonKey(name: 'rotation_trigger')
  String? get rotationTrigger => throw _privateConstructorUsedError;
  @JsonKey(name: 'blind_structure_id')
  int? get blindStructureId => throw _privateConstructorUsedError;
  @JsonKey(name: 'starting_chip')
  int? get startingChip => throw _privateConstructorUsedError;
  @JsonKey(name: 'table_size')
  int get tableSize => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_entries')
  int get totalEntries => throw _privateConstructorUsedError;
  @JsonKey(name: 'players_left')
  int get playersLeft => throw _privateConstructorUsedError;
  @JsonKey(name: 'start_time')
  String? get startTime => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get source => throw _privateConstructorUsedError;
  @JsonKey(name: 'synced_at')
  String? get syncedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  String? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this EbsEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EbsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EbsEventCopyWith<EbsEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EbsEventCopyWith<$Res> {
  factory $EbsEventCopyWith(EbsEvent value, $Res Function(EbsEvent) then) =
      _$EbsEventCopyWithImpl<$Res, EbsEvent>;
  @useResult
  $Res call(
      {@JsonKey(name: 'event_id') int eventId,
      @JsonKey(name: 'series_id') int seriesId,
      @JsonKey(name: 'event_no') int eventNo,
      @JsonKey(name: 'event_name') String eventName,
      @JsonKey(name: 'buy_in') int? buyIn,
      @JsonKey(name: 'display_buy_in') String? displayBuyIn,
      @JsonKey(name: 'game_type') int gameType,
      @JsonKey(name: 'bet_structure') int betStructure,
      @JsonKey(name: 'event_game_type') int eventGameType,
      @JsonKey(name: 'game_mode') String gameMode,
      @JsonKey(name: 'allowed_games') String? allowedGames,
      @JsonKey(name: 'rotation_order') String? rotationOrder,
      @JsonKey(name: 'rotation_trigger') String? rotationTrigger,
      @JsonKey(name: 'blind_structure_id') int? blindStructureId,
      @JsonKey(name: 'starting_chip') int? startingChip,
      @JsonKey(name: 'table_size') int tableSize,
      @JsonKey(name: 'total_entries') int totalEntries,
      @JsonKey(name: 'players_left') int playersLeft,
      @JsonKey(name: 'start_time') String? startTime,
      String status,
      String source,
      @JsonKey(name: 'synced_at') String? syncedAt,
      @JsonKey(name: 'created_at') String? createdAt,
      @JsonKey(name: 'updated_at') String? updatedAt});
}

/// @nodoc
class _$EbsEventCopyWithImpl<$Res, $Val extends EbsEvent>
    implements $EbsEventCopyWith<$Res> {
  _$EbsEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EbsEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? eventId = null,
    Object? seriesId = null,
    Object? eventNo = null,
    Object? eventName = null,
    Object? buyIn = freezed,
    Object? displayBuyIn = freezed,
    Object? gameType = null,
    Object? betStructure = null,
    Object? eventGameType = null,
    Object? gameMode = null,
    Object? allowedGames = freezed,
    Object? rotationOrder = freezed,
    Object? rotationTrigger = freezed,
    Object? blindStructureId = freezed,
    Object? startingChip = freezed,
    Object? tableSize = null,
    Object? totalEntries = null,
    Object? playersLeft = null,
    Object? startTime = freezed,
    Object? status = null,
    Object? source = null,
    Object? syncedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as int,
      seriesId: null == seriesId
          ? _value.seriesId
          : seriesId // ignore: cast_nullable_to_non_nullable
              as int,
      eventNo: null == eventNo
          ? _value.eventNo
          : eventNo // ignore: cast_nullable_to_non_nullable
              as int,
      eventName: null == eventName
          ? _value.eventName
          : eventName // ignore: cast_nullable_to_non_nullable
              as String,
      buyIn: freezed == buyIn
          ? _value.buyIn
          : buyIn // ignore: cast_nullable_to_non_nullable
              as int?,
      displayBuyIn: freezed == displayBuyIn
          ? _value.displayBuyIn
          : displayBuyIn // ignore: cast_nullable_to_non_nullable
              as String?,
      gameType: null == gameType
          ? _value.gameType
          : gameType // ignore: cast_nullable_to_non_nullable
              as int,
      betStructure: null == betStructure
          ? _value.betStructure
          : betStructure // ignore: cast_nullable_to_non_nullable
              as int,
      eventGameType: null == eventGameType
          ? _value.eventGameType
          : eventGameType // ignore: cast_nullable_to_non_nullable
              as int,
      gameMode: null == gameMode
          ? _value.gameMode
          : gameMode // ignore: cast_nullable_to_non_nullable
              as String,
      allowedGames: freezed == allowedGames
          ? _value.allowedGames
          : allowedGames // ignore: cast_nullable_to_non_nullable
              as String?,
      rotationOrder: freezed == rotationOrder
          ? _value.rotationOrder
          : rotationOrder // ignore: cast_nullable_to_non_nullable
              as String?,
      rotationTrigger: freezed == rotationTrigger
          ? _value.rotationTrigger
          : rotationTrigger // ignore: cast_nullable_to_non_nullable
              as String?,
      blindStructureId: freezed == blindStructureId
          ? _value.blindStructureId
          : blindStructureId // ignore: cast_nullable_to_non_nullable
              as int?,
      startingChip: freezed == startingChip
          ? _value.startingChip
          : startingChip // ignore: cast_nullable_to_non_nullable
              as int?,
      tableSize: null == tableSize
          ? _value.tableSize
          : tableSize // ignore: cast_nullable_to_non_nullable
              as int,
      totalEntries: null == totalEntries
          ? _value.totalEntries
          : totalEntries // ignore: cast_nullable_to_non_nullable
              as int,
      playersLeft: null == playersLeft
          ? _value.playersLeft
          : playersLeft // ignore: cast_nullable_to_non_nullable
              as int,
      startTime: freezed == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      syncedAt: freezed == syncedAt
          ? _value.syncedAt
          : syncedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EbsEventImplCopyWith<$Res>
    implements $EbsEventCopyWith<$Res> {
  factory _$$EbsEventImplCopyWith(
          _$EbsEventImpl value, $Res Function(_$EbsEventImpl) then) =
      __$$EbsEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'event_id') int eventId,
      @JsonKey(name: 'series_id') int seriesId,
      @JsonKey(name: 'event_no') int eventNo,
      @JsonKey(name: 'event_name') String eventName,
      @JsonKey(name: 'buy_in') int? buyIn,
      @JsonKey(name: 'display_buy_in') String? displayBuyIn,
      @JsonKey(name: 'game_type') int gameType,
      @JsonKey(name: 'bet_structure') int betStructure,
      @JsonKey(name: 'event_game_type') int eventGameType,
      @JsonKey(name: 'game_mode') String gameMode,
      @JsonKey(name: 'allowed_games') String? allowedGames,
      @JsonKey(name: 'rotation_order') String? rotationOrder,
      @JsonKey(name: 'rotation_trigger') String? rotationTrigger,
      @JsonKey(name: 'blind_structure_id') int? blindStructureId,
      @JsonKey(name: 'starting_chip') int? startingChip,
      @JsonKey(name: 'table_size') int tableSize,
      @JsonKey(name: 'total_entries') int totalEntries,
      @JsonKey(name: 'players_left') int playersLeft,
      @JsonKey(name: 'start_time') String? startTime,
      String status,
      String source,
      @JsonKey(name: 'synced_at') String? syncedAt,
      @JsonKey(name: 'created_at') String? createdAt,
      @JsonKey(name: 'updated_at') String? updatedAt});
}

/// @nodoc
class __$$EbsEventImplCopyWithImpl<$Res>
    extends _$EbsEventCopyWithImpl<$Res, _$EbsEventImpl>
    implements _$$EbsEventImplCopyWith<$Res> {
  __$$EbsEventImplCopyWithImpl(
      _$EbsEventImpl _value, $Res Function(_$EbsEventImpl) _then)
      : super(_value, _then);

  /// Create a copy of EbsEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? eventId = null,
    Object? seriesId = null,
    Object? eventNo = null,
    Object? eventName = null,
    Object? buyIn = freezed,
    Object? displayBuyIn = freezed,
    Object? gameType = null,
    Object? betStructure = null,
    Object? eventGameType = null,
    Object? gameMode = null,
    Object? allowedGames = freezed,
    Object? rotationOrder = freezed,
    Object? rotationTrigger = freezed,
    Object? blindStructureId = freezed,
    Object? startingChip = freezed,
    Object? tableSize = null,
    Object? totalEntries = null,
    Object? playersLeft = null,
    Object? startTime = freezed,
    Object? status = null,
    Object? source = null,
    Object? syncedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$EbsEventImpl(
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as int,
      seriesId: null == seriesId
          ? _value.seriesId
          : seriesId // ignore: cast_nullable_to_non_nullable
              as int,
      eventNo: null == eventNo
          ? _value.eventNo
          : eventNo // ignore: cast_nullable_to_non_nullable
              as int,
      eventName: null == eventName
          ? _value.eventName
          : eventName // ignore: cast_nullable_to_non_nullable
              as String,
      buyIn: freezed == buyIn
          ? _value.buyIn
          : buyIn // ignore: cast_nullable_to_non_nullable
              as int?,
      displayBuyIn: freezed == displayBuyIn
          ? _value.displayBuyIn
          : displayBuyIn // ignore: cast_nullable_to_non_nullable
              as String?,
      gameType: null == gameType
          ? _value.gameType
          : gameType // ignore: cast_nullable_to_non_nullable
              as int,
      betStructure: null == betStructure
          ? _value.betStructure
          : betStructure // ignore: cast_nullable_to_non_nullable
              as int,
      eventGameType: null == eventGameType
          ? _value.eventGameType
          : eventGameType // ignore: cast_nullable_to_non_nullable
              as int,
      gameMode: null == gameMode
          ? _value.gameMode
          : gameMode // ignore: cast_nullable_to_non_nullable
              as String,
      allowedGames: freezed == allowedGames
          ? _value.allowedGames
          : allowedGames // ignore: cast_nullable_to_non_nullable
              as String?,
      rotationOrder: freezed == rotationOrder
          ? _value.rotationOrder
          : rotationOrder // ignore: cast_nullable_to_non_nullable
              as String?,
      rotationTrigger: freezed == rotationTrigger
          ? _value.rotationTrigger
          : rotationTrigger // ignore: cast_nullable_to_non_nullable
              as String?,
      blindStructureId: freezed == blindStructureId
          ? _value.blindStructureId
          : blindStructureId // ignore: cast_nullable_to_non_nullable
              as int?,
      startingChip: freezed == startingChip
          ? _value.startingChip
          : startingChip // ignore: cast_nullable_to_non_nullable
              as int?,
      tableSize: null == tableSize
          ? _value.tableSize
          : tableSize // ignore: cast_nullable_to_non_nullable
              as int,
      totalEntries: null == totalEntries
          ? _value.totalEntries
          : totalEntries // ignore: cast_nullable_to_non_nullable
              as int,
      playersLeft: null == playersLeft
          ? _value.playersLeft
          : playersLeft // ignore: cast_nullable_to_non_nullable
              as int,
      startTime: freezed == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      syncedAt: freezed == syncedAt
          ? _value.syncedAt
          : syncedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EbsEventImpl implements _EbsEvent {
  const _$EbsEventImpl(
      {@JsonKey(name: 'event_id') required this.eventId,
      @JsonKey(name: 'series_id') required this.seriesId,
      @JsonKey(name: 'event_no') this.eventNo = 0,
      @JsonKey(name: 'event_name') required this.eventName,
      @JsonKey(name: 'buy_in') this.buyIn,
      @JsonKey(name: 'display_buy_in') this.displayBuyIn,
      @JsonKey(name: 'game_type') this.gameType = 0,
      @JsonKey(name: 'bet_structure') this.betStructure = 0,
      @JsonKey(name: 'event_game_type') this.eventGameType = 0,
      @JsonKey(name: 'game_mode') this.gameMode = 'single',
      @JsonKey(name: 'allowed_games') this.allowedGames,
      @JsonKey(name: 'rotation_order') this.rotationOrder,
      @JsonKey(name: 'rotation_trigger') this.rotationTrigger,
      @JsonKey(name: 'blind_structure_id') this.blindStructureId,
      @JsonKey(name: 'starting_chip') this.startingChip,
      @JsonKey(name: 'table_size') this.tableSize = 9,
      @JsonKey(name: 'total_entries') this.totalEntries = 0,
      @JsonKey(name: 'players_left') this.playersLeft = 0,
      @JsonKey(name: 'start_time') this.startTime,
      this.status = 'created',
      this.source = 'api',
      @JsonKey(name: 'synced_at') this.syncedAt,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt});

  factory _$EbsEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$EbsEventImplFromJson(json);

  @override
  @JsonKey(name: 'event_id')
  final int eventId;
  @override
  @JsonKey(name: 'series_id')
  final int seriesId;
  @override
  @JsonKey(name: 'event_no')
  final int eventNo;
  @override
  @JsonKey(name: 'event_name')
  final String eventName;
  @override
  @JsonKey(name: 'buy_in')
  final int? buyIn;
  @override
  @JsonKey(name: 'display_buy_in')
  final String? displayBuyIn;
  @override
  @JsonKey(name: 'game_type')
  final int gameType;
  @override
  @JsonKey(name: 'bet_structure')
  final int betStructure;
  @override
  @JsonKey(name: 'event_game_type')
  final int eventGameType;
  @override
  @JsonKey(name: 'game_mode')
  final String gameMode;
  @override
  @JsonKey(name: 'allowed_games')
  final String? allowedGames;
  @override
  @JsonKey(name: 'rotation_order')
  final String? rotationOrder;
  @override
  @JsonKey(name: 'rotation_trigger')
  final String? rotationTrigger;
  @override
  @JsonKey(name: 'blind_structure_id')
  final int? blindStructureId;
  @override
  @JsonKey(name: 'starting_chip')
  final int? startingChip;
  @override
  @JsonKey(name: 'table_size')
  final int tableSize;
  @override
  @JsonKey(name: 'total_entries')
  final int totalEntries;
  @override
  @JsonKey(name: 'players_left')
  final int playersLeft;
  @override
  @JsonKey(name: 'start_time')
  final String? startTime;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey()
  final String source;
  @override
  @JsonKey(name: 'synced_at')
  final String? syncedAt;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  @override
  String toString() {
    return 'EbsEvent(eventId: $eventId, seriesId: $seriesId, eventNo: $eventNo, eventName: $eventName, buyIn: $buyIn, displayBuyIn: $displayBuyIn, gameType: $gameType, betStructure: $betStructure, eventGameType: $eventGameType, gameMode: $gameMode, allowedGames: $allowedGames, rotationOrder: $rotationOrder, rotationTrigger: $rotationTrigger, blindStructureId: $blindStructureId, startingChip: $startingChip, tableSize: $tableSize, totalEntries: $totalEntries, playersLeft: $playersLeft, startTime: $startTime, status: $status, source: $source, syncedAt: $syncedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EbsEventImpl &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.seriesId, seriesId) ||
                other.seriesId == seriesId) &&
            (identical(other.eventNo, eventNo) || other.eventNo == eventNo) &&
            (identical(other.eventName, eventName) ||
                other.eventName == eventName) &&
            (identical(other.buyIn, buyIn) || other.buyIn == buyIn) &&
            (identical(other.displayBuyIn, displayBuyIn) ||
                other.displayBuyIn == displayBuyIn) &&
            (identical(other.gameType, gameType) ||
                other.gameType == gameType) &&
            (identical(other.betStructure, betStructure) ||
                other.betStructure == betStructure) &&
            (identical(other.eventGameType, eventGameType) ||
                other.eventGameType == eventGameType) &&
            (identical(other.gameMode, gameMode) ||
                other.gameMode == gameMode) &&
            (identical(other.allowedGames, allowedGames) ||
                other.allowedGames == allowedGames) &&
            (identical(other.rotationOrder, rotationOrder) ||
                other.rotationOrder == rotationOrder) &&
            (identical(other.rotationTrigger, rotationTrigger) ||
                other.rotationTrigger == rotationTrigger) &&
            (identical(other.blindStructureId, blindStructureId) ||
                other.blindStructureId == blindStructureId) &&
            (identical(other.startingChip, startingChip) ||
                other.startingChip == startingChip) &&
            (identical(other.tableSize, tableSize) ||
                other.tableSize == tableSize) &&
            (identical(other.totalEntries, totalEntries) ||
                other.totalEntries == totalEntries) &&
            (identical(other.playersLeft, playersLeft) ||
                other.playersLeft == playersLeft) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.syncedAt, syncedAt) ||
                other.syncedAt == syncedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        eventId,
        seriesId,
        eventNo,
        eventName,
        buyIn,
        displayBuyIn,
        gameType,
        betStructure,
        eventGameType,
        gameMode,
        allowedGames,
        rotationOrder,
        rotationTrigger,
        blindStructureId,
        startingChip,
        tableSize,
        totalEntries,
        playersLeft,
        startTime,
        status,
        source,
        syncedAt,
        createdAt,
        updatedAt
      ]);

  /// Create a copy of EbsEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EbsEventImplCopyWith<_$EbsEventImpl> get copyWith =>
      __$$EbsEventImplCopyWithImpl<_$EbsEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EbsEventImplToJson(
      this,
    );
  }
}

abstract class _EbsEvent implements EbsEvent {
  const factory _EbsEvent(
      {@JsonKey(name: 'event_id') required final int eventId,
      @JsonKey(name: 'series_id') required final int seriesId,
      @JsonKey(name: 'event_no') final int eventNo,
      @JsonKey(name: 'event_name') required final String eventName,
      @JsonKey(name: 'buy_in') final int? buyIn,
      @JsonKey(name: 'display_buy_in') final String? displayBuyIn,
      @JsonKey(name: 'game_type') final int gameType,
      @JsonKey(name: 'bet_structure') final int betStructure,
      @JsonKey(name: 'event_game_type') final int eventGameType,
      @JsonKey(name: 'game_mode') final String gameMode,
      @JsonKey(name: 'allowed_games') final String? allowedGames,
      @JsonKey(name: 'rotation_order') final String? rotationOrder,
      @JsonKey(name: 'rotation_trigger') final String? rotationTrigger,
      @JsonKey(name: 'blind_structure_id') final int? blindStructureId,
      @JsonKey(name: 'starting_chip') final int? startingChip,
      @JsonKey(name: 'table_size') final int tableSize,
      @JsonKey(name: 'total_entries') final int totalEntries,
      @JsonKey(name: 'players_left') final int playersLeft,
      @JsonKey(name: 'start_time') final String? startTime,
      final String status,
      final String source,
      @JsonKey(name: 'synced_at') final String? syncedAt,
      @JsonKey(name: 'created_at') final String? createdAt,
      @JsonKey(name: 'updated_at') final String? updatedAt}) = _$EbsEventImpl;

  factory _EbsEvent.fromJson(Map<String, dynamic> json) =
      _$EbsEventImpl.fromJson;

  @override
  @JsonKey(name: 'event_id')
  int get eventId;
  @override
  @JsonKey(name: 'series_id')
  int get seriesId;
  @override
  @JsonKey(name: 'event_no')
  int get eventNo;
  @override
  @JsonKey(name: 'event_name')
  String get eventName;
  @override
  @JsonKey(name: 'buy_in')
  int? get buyIn;
  @override
  @JsonKey(name: 'display_buy_in')
  String? get displayBuyIn;
  @override
  @JsonKey(name: 'game_type')
  int get gameType;
  @override
  @JsonKey(name: 'bet_structure')
  int get betStructure;
  @override
  @JsonKey(name: 'event_game_type')
  int get eventGameType;
  @override
  @JsonKey(name: 'game_mode')
  String get gameMode;
  @override
  @JsonKey(name: 'allowed_games')
  String? get allowedGames;
  @override
  @JsonKey(name: 'rotation_order')
  String? get rotationOrder;
  @override
  @JsonKey(name: 'rotation_trigger')
  String? get rotationTrigger;
  @override
  @JsonKey(name: 'blind_structure_id')
  int? get blindStructureId;
  @override
  @JsonKey(name: 'starting_chip')
  int? get startingChip;
  @override
  @JsonKey(name: 'table_size')
  int get tableSize;
  @override
  @JsonKey(name: 'total_entries')
  int get totalEntries;
  @override
  @JsonKey(name: 'players_left')
  int get playersLeft;
  @override
  @JsonKey(name: 'start_time')
  String? get startTime;
  @override
  String get status;
  @override
  String get source;
  @override
  @JsonKey(name: 'synced_at')
  String? get syncedAt;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  String? get updatedAt;

  /// Create a copy of EbsEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EbsEventImplCopyWith<_$EbsEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
