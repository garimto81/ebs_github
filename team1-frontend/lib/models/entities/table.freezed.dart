// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'table.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

EbsTable _$EbsTableFromJson(Map<String, dynamic> json) {
  return _EbsTable.fromJson(json);
}

/// @nodoc
mixin _$EbsTable {
  @JsonKey(name: 'table_id')
  int get tableId => throw _privateConstructorUsedError;
  @JsonKey(name: 'event_flight_id')
  int get eventFlightId => throw _privateConstructorUsedError;
  @JsonKey(name: 'table_no')
  int get tableNo => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_players')
  int get maxPlayers => throw _privateConstructorUsedError;
  @JsonKey(name: 'game_type')
  int get gameType => throw _privateConstructorUsedError;
  @JsonKey(name: 'small_blind')
  int? get smallBlind => throw _privateConstructorUsedError;
  @JsonKey(name: 'big_blind')
  int? get bigBlind => throw _privateConstructorUsedError;
  @JsonKey(name: 'ante_type')
  int get anteType => throw _privateConstructorUsedError;
  @JsonKey(name: 'ante_amount')
  int get anteAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'rfid_reader_id')
  int? get rfidReaderId => throw _privateConstructorUsedError;
  @JsonKey(name: 'deck_registered')
  bool get deckRegistered => throw _privateConstructorUsedError;
  @JsonKey(name: 'output_type')
  String? get outputType => throw _privateConstructorUsedError;
  @JsonKey(name: 'current_game')
  int? get currentGame => throw _privateConstructorUsedError;
  @JsonKey(name: 'delay_seconds')
  int get delaySeconds => throw _privateConstructorUsedError;
  int? get ring => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_breaking_table')
  bool get isBreakingTable => throw _privateConstructorUsedError;
  String get source => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  String get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'seated_count')
  int? get seatedCount => throw _privateConstructorUsedError;

  /// Serializes this EbsTable to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EbsTable
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EbsTableCopyWith<EbsTable> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EbsTableCopyWith<$Res> {
  factory $EbsTableCopyWith(EbsTable value, $Res Function(EbsTable) then) =
      _$EbsTableCopyWithImpl<$Res, EbsTable>;
  @useResult
  $Res call(
      {@JsonKey(name: 'table_id') int tableId,
      @JsonKey(name: 'event_flight_id') int eventFlightId,
      @JsonKey(name: 'table_no') int tableNo,
      String name,
      String type,
      String status,
      @JsonKey(name: 'max_players') int maxPlayers,
      @JsonKey(name: 'game_type') int gameType,
      @JsonKey(name: 'small_blind') int? smallBlind,
      @JsonKey(name: 'big_blind') int? bigBlind,
      @JsonKey(name: 'ante_type') int anteType,
      @JsonKey(name: 'ante_amount') int anteAmount,
      @JsonKey(name: 'rfid_reader_id') int? rfidReaderId,
      @JsonKey(name: 'deck_registered') bool deckRegistered,
      @JsonKey(name: 'output_type') String? outputType,
      @JsonKey(name: 'current_game') int? currentGame,
      @JsonKey(name: 'delay_seconds') int delaySeconds,
      int? ring,
      @JsonKey(name: 'is_breaking_table') bool isBreakingTable,
      String source,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'updated_at') String updatedAt,
      @JsonKey(name: 'seated_count') int? seatedCount});
}

/// @nodoc
class _$EbsTableCopyWithImpl<$Res, $Val extends EbsTable>
    implements $EbsTableCopyWith<$Res> {
  _$EbsTableCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EbsTable
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tableId = null,
    Object? eventFlightId = null,
    Object? tableNo = null,
    Object? name = null,
    Object? type = null,
    Object? status = null,
    Object? maxPlayers = null,
    Object? gameType = null,
    Object? smallBlind = freezed,
    Object? bigBlind = freezed,
    Object? anteType = null,
    Object? anteAmount = null,
    Object? rfidReaderId = freezed,
    Object? deckRegistered = null,
    Object? outputType = freezed,
    Object? currentGame = freezed,
    Object? delaySeconds = null,
    Object? ring = freezed,
    Object? isBreakingTable = null,
    Object? source = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? seatedCount = freezed,
  }) {
    return _then(_value.copyWith(
      tableId: null == tableId
          ? _value.tableId
          : tableId // ignore: cast_nullable_to_non_nullable
              as int,
      eventFlightId: null == eventFlightId
          ? _value.eventFlightId
          : eventFlightId // ignore: cast_nullable_to_non_nullable
              as int,
      tableNo: null == tableNo
          ? _value.tableNo
          : tableNo // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      maxPlayers: null == maxPlayers
          ? _value.maxPlayers
          : maxPlayers // ignore: cast_nullable_to_non_nullable
              as int,
      gameType: null == gameType
          ? _value.gameType
          : gameType // ignore: cast_nullable_to_non_nullable
              as int,
      smallBlind: freezed == smallBlind
          ? _value.smallBlind
          : smallBlind // ignore: cast_nullable_to_non_nullable
              as int?,
      bigBlind: freezed == bigBlind
          ? _value.bigBlind
          : bigBlind // ignore: cast_nullable_to_non_nullable
              as int?,
      anteType: null == anteType
          ? _value.anteType
          : anteType // ignore: cast_nullable_to_non_nullable
              as int,
      anteAmount: null == anteAmount
          ? _value.anteAmount
          : anteAmount // ignore: cast_nullable_to_non_nullable
              as int,
      rfidReaderId: freezed == rfidReaderId
          ? _value.rfidReaderId
          : rfidReaderId // ignore: cast_nullable_to_non_nullable
              as int?,
      deckRegistered: null == deckRegistered
          ? _value.deckRegistered
          : deckRegistered // ignore: cast_nullable_to_non_nullable
              as bool,
      outputType: freezed == outputType
          ? _value.outputType
          : outputType // ignore: cast_nullable_to_non_nullable
              as String?,
      currentGame: freezed == currentGame
          ? _value.currentGame
          : currentGame // ignore: cast_nullable_to_non_nullable
              as int?,
      delaySeconds: null == delaySeconds
          ? _value.delaySeconds
          : delaySeconds // ignore: cast_nullable_to_non_nullable
              as int,
      ring: freezed == ring
          ? _value.ring
          : ring // ignore: cast_nullable_to_non_nullable
              as int?,
      isBreakingTable: null == isBreakingTable
          ? _value.isBreakingTable
          : isBreakingTable // ignore: cast_nullable_to_non_nullable
              as bool,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String,
      seatedCount: freezed == seatedCount
          ? _value.seatedCount
          : seatedCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EbsTableImplCopyWith<$Res>
    implements $EbsTableCopyWith<$Res> {
  factory _$$EbsTableImplCopyWith(
          _$EbsTableImpl value, $Res Function(_$EbsTableImpl) then) =
      __$$EbsTableImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'table_id') int tableId,
      @JsonKey(name: 'event_flight_id') int eventFlightId,
      @JsonKey(name: 'table_no') int tableNo,
      String name,
      String type,
      String status,
      @JsonKey(name: 'max_players') int maxPlayers,
      @JsonKey(name: 'game_type') int gameType,
      @JsonKey(name: 'small_blind') int? smallBlind,
      @JsonKey(name: 'big_blind') int? bigBlind,
      @JsonKey(name: 'ante_type') int anteType,
      @JsonKey(name: 'ante_amount') int anteAmount,
      @JsonKey(name: 'rfid_reader_id') int? rfidReaderId,
      @JsonKey(name: 'deck_registered') bool deckRegistered,
      @JsonKey(name: 'output_type') String? outputType,
      @JsonKey(name: 'current_game') int? currentGame,
      @JsonKey(name: 'delay_seconds') int delaySeconds,
      int? ring,
      @JsonKey(name: 'is_breaking_table') bool isBreakingTable,
      String source,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'updated_at') String updatedAt,
      @JsonKey(name: 'seated_count') int? seatedCount});
}

/// @nodoc
class __$$EbsTableImplCopyWithImpl<$Res>
    extends _$EbsTableCopyWithImpl<$Res, _$EbsTableImpl>
    implements _$$EbsTableImplCopyWith<$Res> {
  __$$EbsTableImplCopyWithImpl(
      _$EbsTableImpl _value, $Res Function(_$EbsTableImpl) _then)
      : super(_value, _then);

  /// Create a copy of EbsTable
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tableId = null,
    Object? eventFlightId = null,
    Object? tableNo = null,
    Object? name = null,
    Object? type = null,
    Object? status = null,
    Object? maxPlayers = null,
    Object? gameType = null,
    Object? smallBlind = freezed,
    Object? bigBlind = freezed,
    Object? anteType = null,
    Object? anteAmount = null,
    Object? rfidReaderId = freezed,
    Object? deckRegistered = null,
    Object? outputType = freezed,
    Object? currentGame = freezed,
    Object? delaySeconds = null,
    Object? ring = freezed,
    Object? isBreakingTable = null,
    Object? source = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? seatedCount = freezed,
  }) {
    return _then(_$EbsTableImpl(
      tableId: null == tableId
          ? _value.tableId
          : tableId // ignore: cast_nullable_to_non_nullable
              as int,
      eventFlightId: null == eventFlightId
          ? _value.eventFlightId
          : eventFlightId // ignore: cast_nullable_to_non_nullable
              as int,
      tableNo: null == tableNo
          ? _value.tableNo
          : tableNo // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      maxPlayers: null == maxPlayers
          ? _value.maxPlayers
          : maxPlayers // ignore: cast_nullable_to_non_nullable
              as int,
      gameType: null == gameType
          ? _value.gameType
          : gameType // ignore: cast_nullable_to_non_nullable
              as int,
      smallBlind: freezed == smallBlind
          ? _value.smallBlind
          : smallBlind // ignore: cast_nullable_to_non_nullable
              as int?,
      bigBlind: freezed == bigBlind
          ? _value.bigBlind
          : bigBlind // ignore: cast_nullable_to_non_nullable
              as int?,
      anteType: null == anteType
          ? _value.anteType
          : anteType // ignore: cast_nullable_to_non_nullable
              as int,
      anteAmount: null == anteAmount
          ? _value.anteAmount
          : anteAmount // ignore: cast_nullable_to_non_nullable
              as int,
      rfidReaderId: freezed == rfidReaderId
          ? _value.rfidReaderId
          : rfidReaderId // ignore: cast_nullable_to_non_nullable
              as int?,
      deckRegistered: null == deckRegistered
          ? _value.deckRegistered
          : deckRegistered // ignore: cast_nullable_to_non_nullable
              as bool,
      outputType: freezed == outputType
          ? _value.outputType
          : outputType // ignore: cast_nullable_to_non_nullable
              as String?,
      currentGame: freezed == currentGame
          ? _value.currentGame
          : currentGame // ignore: cast_nullable_to_non_nullable
              as int?,
      delaySeconds: null == delaySeconds
          ? _value.delaySeconds
          : delaySeconds // ignore: cast_nullable_to_non_nullable
              as int,
      ring: freezed == ring
          ? _value.ring
          : ring // ignore: cast_nullable_to_non_nullable
              as int?,
      isBreakingTable: null == isBreakingTable
          ? _value.isBreakingTable
          : isBreakingTable // ignore: cast_nullable_to_non_nullable
              as bool,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String,
      seatedCount: freezed == seatedCount
          ? _value.seatedCount
          : seatedCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EbsTableImpl implements _EbsTable {
  const _$EbsTableImpl(
      {@JsonKey(name: 'table_id') required this.tableId,
      @JsonKey(name: 'event_flight_id') required this.eventFlightId,
      @JsonKey(name: 'table_no') required this.tableNo,
      required this.name,
      required this.type,
      required this.status,
      @JsonKey(name: 'max_players') required this.maxPlayers,
      @JsonKey(name: 'game_type') required this.gameType,
      @JsonKey(name: 'small_blind') this.smallBlind,
      @JsonKey(name: 'big_blind') this.bigBlind,
      @JsonKey(name: 'ante_type') required this.anteType,
      @JsonKey(name: 'ante_amount') required this.anteAmount,
      @JsonKey(name: 'rfid_reader_id') this.rfidReaderId,
      @JsonKey(name: 'deck_registered') required this.deckRegistered,
      @JsonKey(name: 'output_type') this.outputType,
      @JsonKey(name: 'current_game') this.currentGame,
      @JsonKey(name: 'delay_seconds') required this.delaySeconds,
      this.ring,
      @JsonKey(name: 'is_breaking_table') required this.isBreakingTable,
      required this.source,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt,
      @JsonKey(name: 'seated_count') this.seatedCount});

  factory _$EbsTableImpl.fromJson(Map<String, dynamic> json) =>
      _$$EbsTableImplFromJson(json);

  @override
  @JsonKey(name: 'table_id')
  final int tableId;
  @override
  @JsonKey(name: 'event_flight_id')
  final int eventFlightId;
  @override
  @JsonKey(name: 'table_no')
  final int tableNo;
  @override
  final String name;
  @override
  final String type;
  @override
  final String status;
  @override
  @JsonKey(name: 'max_players')
  final int maxPlayers;
  @override
  @JsonKey(name: 'game_type')
  final int gameType;
  @override
  @JsonKey(name: 'small_blind')
  final int? smallBlind;
  @override
  @JsonKey(name: 'big_blind')
  final int? bigBlind;
  @override
  @JsonKey(name: 'ante_type')
  final int anteType;
  @override
  @JsonKey(name: 'ante_amount')
  final int anteAmount;
  @override
  @JsonKey(name: 'rfid_reader_id')
  final int? rfidReaderId;
  @override
  @JsonKey(name: 'deck_registered')
  final bool deckRegistered;
  @override
  @JsonKey(name: 'output_type')
  final String? outputType;
  @override
  @JsonKey(name: 'current_game')
  final int? currentGame;
  @override
  @JsonKey(name: 'delay_seconds')
  final int delaySeconds;
  @override
  final int? ring;
  @override
  @JsonKey(name: 'is_breaking_table')
  final bool isBreakingTable;
  @override
  final String source;
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  @override
  @JsonKey(name: 'seated_count')
  final int? seatedCount;

  @override
  String toString() {
    return 'EbsTable(tableId: $tableId, eventFlightId: $eventFlightId, tableNo: $tableNo, name: $name, type: $type, status: $status, maxPlayers: $maxPlayers, gameType: $gameType, smallBlind: $smallBlind, bigBlind: $bigBlind, anteType: $anteType, anteAmount: $anteAmount, rfidReaderId: $rfidReaderId, deckRegistered: $deckRegistered, outputType: $outputType, currentGame: $currentGame, delaySeconds: $delaySeconds, ring: $ring, isBreakingTable: $isBreakingTable, source: $source, createdAt: $createdAt, updatedAt: $updatedAt, seatedCount: $seatedCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EbsTableImpl &&
            (identical(other.tableId, tableId) || other.tableId == tableId) &&
            (identical(other.eventFlightId, eventFlightId) ||
                other.eventFlightId == eventFlightId) &&
            (identical(other.tableNo, tableNo) || other.tableNo == tableNo) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.maxPlayers, maxPlayers) ||
                other.maxPlayers == maxPlayers) &&
            (identical(other.gameType, gameType) ||
                other.gameType == gameType) &&
            (identical(other.smallBlind, smallBlind) ||
                other.smallBlind == smallBlind) &&
            (identical(other.bigBlind, bigBlind) ||
                other.bigBlind == bigBlind) &&
            (identical(other.anteType, anteType) ||
                other.anteType == anteType) &&
            (identical(other.anteAmount, anteAmount) ||
                other.anteAmount == anteAmount) &&
            (identical(other.rfidReaderId, rfidReaderId) ||
                other.rfidReaderId == rfidReaderId) &&
            (identical(other.deckRegistered, deckRegistered) ||
                other.deckRegistered == deckRegistered) &&
            (identical(other.outputType, outputType) ||
                other.outputType == outputType) &&
            (identical(other.currentGame, currentGame) ||
                other.currentGame == currentGame) &&
            (identical(other.delaySeconds, delaySeconds) ||
                other.delaySeconds == delaySeconds) &&
            (identical(other.ring, ring) || other.ring == ring) &&
            (identical(other.isBreakingTable, isBreakingTable) ||
                other.isBreakingTable == isBreakingTable) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.seatedCount, seatedCount) ||
                other.seatedCount == seatedCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        tableId,
        eventFlightId,
        tableNo,
        name,
        type,
        status,
        maxPlayers,
        gameType,
        smallBlind,
        bigBlind,
        anteType,
        anteAmount,
        rfidReaderId,
        deckRegistered,
        outputType,
        currentGame,
        delaySeconds,
        ring,
        isBreakingTable,
        source,
        createdAt,
        updatedAt,
        seatedCount
      ]);

  /// Create a copy of EbsTable
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EbsTableImplCopyWith<_$EbsTableImpl> get copyWith =>
      __$$EbsTableImplCopyWithImpl<_$EbsTableImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EbsTableImplToJson(
      this,
    );
  }
}

abstract class _EbsTable implements EbsTable {
  const factory _EbsTable(
      {@JsonKey(name: 'table_id') required final int tableId,
      @JsonKey(name: 'event_flight_id') required final int eventFlightId,
      @JsonKey(name: 'table_no') required final int tableNo,
      required final String name,
      required final String type,
      required final String status,
      @JsonKey(name: 'max_players') required final int maxPlayers,
      @JsonKey(name: 'game_type') required final int gameType,
      @JsonKey(name: 'small_blind') final int? smallBlind,
      @JsonKey(name: 'big_blind') final int? bigBlind,
      @JsonKey(name: 'ante_type') required final int anteType,
      @JsonKey(name: 'ante_amount') required final int anteAmount,
      @JsonKey(name: 'rfid_reader_id') final int? rfidReaderId,
      @JsonKey(name: 'deck_registered') required final bool deckRegistered,
      @JsonKey(name: 'output_type') final String? outputType,
      @JsonKey(name: 'current_game') final int? currentGame,
      @JsonKey(name: 'delay_seconds') required final int delaySeconds,
      final int? ring,
      @JsonKey(name: 'is_breaking_table') required final bool isBreakingTable,
      required final String source,
      @JsonKey(name: 'created_at') required final String createdAt,
      @JsonKey(name: 'updated_at') required final String updatedAt,
      @JsonKey(name: 'seated_count') final int? seatedCount}) = _$EbsTableImpl;

  factory _EbsTable.fromJson(Map<String, dynamic> json) =
      _$EbsTableImpl.fromJson;

  @override
  @JsonKey(name: 'table_id')
  int get tableId;
  @override
  @JsonKey(name: 'event_flight_id')
  int get eventFlightId;
  @override
  @JsonKey(name: 'table_no')
  int get tableNo;
  @override
  String get name;
  @override
  String get type;
  @override
  String get status;
  @override
  @JsonKey(name: 'max_players')
  int get maxPlayers;
  @override
  @JsonKey(name: 'game_type')
  int get gameType;
  @override
  @JsonKey(name: 'small_blind')
  int? get smallBlind;
  @override
  @JsonKey(name: 'big_blind')
  int? get bigBlind;
  @override
  @JsonKey(name: 'ante_type')
  int get anteType;
  @override
  @JsonKey(name: 'ante_amount')
  int get anteAmount;
  @override
  @JsonKey(name: 'rfid_reader_id')
  int? get rfidReaderId;
  @override
  @JsonKey(name: 'deck_registered')
  bool get deckRegistered;
  @override
  @JsonKey(name: 'output_type')
  String? get outputType;
  @override
  @JsonKey(name: 'current_game')
  int? get currentGame;
  @override
  @JsonKey(name: 'delay_seconds')
  int get delaySeconds;
  @override
  int? get ring;
  @override
  @JsonKey(name: 'is_breaking_table')
  bool get isBreakingTable;
  @override
  String get source;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  String get updatedAt;
  @override
  @JsonKey(name: 'seated_count')
  int? get seatedCount;

  /// Create a copy of EbsTable
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EbsTableImplCopyWith<_$EbsTableImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
