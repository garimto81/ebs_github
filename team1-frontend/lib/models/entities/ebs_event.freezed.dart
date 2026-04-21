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
  @JsonKey(name: 'eventId')
  int get eventId => throw _privateConstructorUsedError;
  @JsonKey(name: 'seriesId')
  int get seriesId => throw _privateConstructorUsedError;
  @JsonKey(name: 'eventNo')
  int get eventNo => throw _privateConstructorUsedError;
  @JsonKey(name: 'eventName')
  String get eventName => throw _privateConstructorUsedError;
  @JsonKey(name: 'buyIn')
  int? get buyIn => throw _privateConstructorUsedError;
  @JsonKey(name: 'displayBuyIn')
  String? get displayBuyIn => throw _privateConstructorUsedError;
  @JsonKey(name: 'gameType')
  int get gameType => throw _privateConstructorUsedError;
  @JsonKey(name: 'betStructure')
  int get betStructure => throw _privateConstructorUsedError;
  @JsonKey(name: 'eventGameType')
  int get eventGameType => throw _privateConstructorUsedError;
  @JsonKey(name: 'gameMode')
  String get gameMode => throw _privateConstructorUsedError;
  @JsonKey(name: 'allowedGames')
  String? get allowedGames => throw _privateConstructorUsedError;
  @JsonKey(name: 'rotationOrder')
  String? get rotationOrder => throw _privateConstructorUsedError;
  @JsonKey(name: 'rotationTrigger')
  String? get rotationTrigger => throw _privateConstructorUsedError;
  @JsonKey(name: 'blindStructureId')
  int? get blindStructureId => throw _privateConstructorUsedError;
  @JsonKey(name: 'startingChip')
  int? get startingChip => throw _privateConstructorUsedError;
  @JsonKey(name: 'tableSize')
  int get tableSize => throw _privateConstructorUsedError;
  @JsonKey(name: 'totalEntries')
  int get totalEntries => throw _privateConstructorUsedError;
  @JsonKey(name: 'playersLeft')
  int get playersLeft => throw _privateConstructorUsedError;
  @JsonKey(name: 'startTime')
  String? get startTime => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get source => throw _privateConstructorUsedError;
  @JsonKey(name: 'syncedAt')
  String? get syncedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'createdAt')
  String? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updatedAt')
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
      {@JsonKey(name: 'eventId') int eventId,
      @JsonKey(name: 'seriesId') int seriesId,
      @JsonKey(name: 'eventNo') int eventNo,
      @JsonKey(name: 'eventName') String eventName,
      @JsonKey(name: 'buyIn') int? buyIn,
      @JsonKey(name: 'displayBuyIn') String? displayBuyIn,
      @JsonKey(name: 'gameType') int gameType,
      @JsonKey(name: 'betStructure') int betStructure,
      @JsonKey(name: 'eventGameType') int eventGameType,
      @JsonKey(name: 'gameMode') String gameMode,
      @JsonKey(name: 'allowedGames') String? allowedGames,
      @JsonKey(name: 'rotationOrder') String? rotationOrder,
      @JsonKey(name: 'rotationTrigger') String? rotationTrigger,
      @JsonKey(name: 'blindStructureId') int? blindStructureId,
      @JsonKey(name: 'startingChip') int? startingChip,
      @JsonKey(name: 'tableSize') int tableSize,
      @JsonKey(name: 'totalEntries') int totalEntries,
      @JsonKey(name: 'playersLeft') int playersLeft,
      @JsonKey(name: 'startTime') String? startTime,
      String status,
      String source,
      @JsonKey(name: 'syncedAt') String? syncedAt,
      @JsonKey(name: 'createdAt') String? createdAt,
      @JsonKey(name: 'updatedAt') String? updatedAt});
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
      {@JsonKey(name: 'eventId') int eventId,
      @JsonKey(name: 'seriesId') int seriesId,
      @JsonKey(name: 'eventNo') int eventNo,
      @JsonKey(name: 'eventName') String eventName,
      @JsonKey(name: 'buyIn') int? buyIn,
      @JsonKey(name: 'displayBuyIn') String? displayBuyIn,
      @JsonKey(name: 'gameType') int gameType,
      @JsonKey(name: 'betStructure') int betStructure,
      @JsonKey(name: 'eventGameType') int eventGameType,
      @JsonKey(name: 'gameMode') String gameMode,
      @JsonKey(name: 'allowedGames') String? allowedGames,
      @JsonKey(name: 'rotationOrder') String? rotationOrder,
      @JsonKey(name: 'rotationTrigger') String? rotationTrigger,
      @JsonKey(name: 'blindStructureId') int? blindStructureId,
      @JsonKey(name: 'startingChip') int? startingChip,
      @JsonKey(name: 'tableSize') int tableSize,
      @JsonKey(name: 'totalEntries') int totalEntries,
      @JsonKey(name: 'playersLeft') int playersLeft,
      @JsonKey(name: 'startTime') String? startTime,
      String status,
      String source,
      @JsonKey(name: 'syncedAt') String? syncedAt,
      @JsonKey(name: 'createdAt') String? createdAt,
      @JsonKey(name: 'updatedAt') String? updatedAt});
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
      {@JsonKey(name: 'eventId') required this.eventId,
      @JsonKey(name: 'seriesId') required this.seriesId,
      @JsonKey(name: 'eventNo') this.eventNo = 0,
      @JsonKey(name: 'eventName') required this.eventName,
      @JsonKey(name: 'buyIn') this.buyIn,
      @JsonKey(name: 'displayBuyIn') this.displayBuyIn,
      @JsonKey(name: 'gameType') this.gameType = 0,
      @JsonKey(name: 'betStructure') this.betStructure = 0,
      @JsonKey(name: 'eventGameType') this.eventGameType = 0,
      @JsonKey(name: 'gameMode') this.gameMode = 'single',
      @JsonKey(name: 'allowedGames') this.allowedGames,
      @JsonKey(name: 'rotationOrder') this.rotationOrder,
      @JsonKey(name: 'rotationTrigger') this.rotationTrigger,
      @JsonKey(name: 'blindStructureId') this.blindStructureId,
      @JsonKey(name: 'startingChip') this.startingChip,
      @JsonKey(name: 'tableSize') this.tableSize = 9,
      @JsonKey(name: 'totalEntries') this.totalEntries = 0,
      @JsonKey(name: 'playersLeft') this.playersLeft = 0,
      @JsonKey(name: 'startTime') this.startTime,
      this.status = 'created',
      this.source = 'api',
      @JsonKey(name: 'syncedAt') this.syncedAt,
      @JsonKey(name: 'createdAt') this.createdAt,
      @JsonKey(name: 'updatedAt') this.updatedAt});

  factory _$EbsEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$EbsEventImplFromJson(json);

  @override
  @JsonKey(name: 'eventId')
  final int eventId;
  @override
  @JsonKey(name: 'seriesId')
  final int seriesId;
  @override
  @JsonKey(name: 'eventNo')
  final int eventNo;
  @override
  @JsonKey(name: 'eventName')
  final String eventName;
  @override
  @JsonKey(name: 'buyIn')
  final int? buyIn;
  @override
  @JsonKey(name: 'displayBuyIn')
  final String? displayBuyIn;
  @override
  @JsonKey(name: 'gameType')
  final int gameType;
  @override
  @JsonKey(name: 'betStructure')
  final int betStructure;
  @override
  @JsonKey(name: 'eventGameType')
  final int eventGameType;
  @override
  @JsonKey(name: 'gameMode')
  final String gameMode;
  @override
  @JsonKey(name: 'allowedGames')
  final String? allowedGames;
  @override
  @JsonKey(name: 'rotationOrder')
  final String? rotationOrder;
  @override
  @JsonKey(name: 'rotationTrigger')
  final String? rotationTrigger;
  @override
  @JsonKey(name: 'blindStructureId')
  final int? blindStructureId;
  @override
  @JsonKey(name: 'startingChip')
  final int? startingChip;
  @override
  @JsonKey(name: 'tableSize')
  final int tableSize;
  @override
  @JsonKey(name: 'totalEntries')
  final int totalEntries;
  @override
  @JsonKey(name: 'playersLeft')
  final int playersLeft;
  @override
  @JsonKey(name: 'startTime')
  final String? startTime;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey()
  final String source;
  @override
  @JsonKey(name: 'syncedAt')
  final String? syncedAt;
  @override
  @JsonKey(name: 'createdAt')
  final String? createdAt;
  @override
  @JsonKey(name: 'updatedAt')
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
      {@JsonKey(name: 'eventId') required final int eventId,
      @JsonKey(name: 'seriesId') required final int seriesId,
      @JsonKey(name: 'eventNo') final int eventNo,
      @JsonKey(name: 'eventName') required final String eventName,
      @JsonKey(name: 'buyIn') final int? buyIn,
      @JsonKey(name: 'displayBuyIn') final String? displayBuyIn,
      @JsonKey(name: 'gameType') final int gameType,
      @JsonKey(name: 'betStructure') final int betStructure,
      @JsonKey(name: 'eventGameType') final int eventGameType,
      @JsonKey(name: 'gameMode') final String gameMode,
      @JsonKey(name: 'allowedGames') final String? allowedGames,
      @JsonKey(name: 'rotationOrder') final String? rotationOrder,
      @JsonKey(name: 'rotationTrigger') final String? rotationTrigger,
      @JsonKey(name: 'blindStructureId') final int? blindStructureId,
      @JsonKey(name: 'startingChip') final int? startingChip,
      @JsonKey(name: 'tableSize') final int tableSize,
      @JsonKey(name: 'totalEntries') final int totalEntries,
      @JsonKey(name: 'playersLeft') final int playersLeft,
      @JsonKey(name: 'startTime') final String? startTime,
      final String status,
      final String source,
      @JsonKey(name: 'syncedAt') final String? syncedAt,
      @JsonKey(name: 'createdAt') final String? createdAt,
      @JsonKey(name: 'updatedAt') final String? updatedAt}) = _$EbsEventImpl;

  factory _EbsEvent.fromJson(Map<String, dynamic> json) =
      _$EbsEventImpl.fromJson;

  @override
  @JsonKey(name: 'eventId')
  int get eventId;
  @override
  @JsonKey(name: 'seriesId')
  int get seriesId;
  @override
  @JsonKey(name: 'eventNo')
  int get eventNo;
  @override
  @JsonKey(name: 'eventName')
  String get eventName;
  @override
  @JsonKey(name: 'buyIn')
  int? get buyIn;
  @override
  @JsonKey(name: 'displayBuyIn')
  String? get displayBuyIn;
  @override
  @JsonKey(name: 'gameType')
  int get gameType;
  @override
  @JsonKey(name: 'betStructure')
  int get betStructure;
  @override
  @JsonKey(name: 'eventGameType')
  int get eventGameType;
  @override
  @JsonKey(name: 'gameMode')
  String get gameMode;
  @override
  @JsonKey(name: 'allowedGames')
  String? get allowedGames;
  @override
  @JsonKey(name: 'rotationOrder')
  String? get rotationOrder;
  @override
  @JsonKey(name: 'rotationTrigger')
  String? get rotationTrigger;
  @override
  @JsonKey(name: 'blindStructureId')
  int? get blindStructureId;
  @override
  @JsonKey(name: 'startingChip')
  int? get startingChip;
  @override
  @JsonKey(name: 'tableSize')
  int get tableSize;
  @override
  @JsonKey(name: 'totalEntries')
  int get totalEntries;
  @override
  @JsonKey(name: 'playersLeft')
  int get playersLeft;
  @override
  @JsonKey(name: 'startTime')
  String? get startTime;
  @override
  String get status;
  @override
  String get source;
  @override
  @JsonKey(name: 'syncedAt')
  String? get syncedAt;
  @override
  @JsonKey(name: 'createdAt')
  String? get createdAt;
  @override
  @JsonKey(name: 'updatedAt')
  String? get updatedAt;

  /// Create a copy of EbsEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EbsEventImplCopyWith<_$EbsEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
