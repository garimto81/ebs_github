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
  @JsonKey(name: 'tableId')
  int get tableId => throw _privateConstructorUsedError;
  @JsonKey(name: 'eventFlightId')
  int get eventFlightId => throw _privateConstructorUsedError;
  @JsonKey(name: 'tableNo')
  int get tableNo => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'maxPlayers')
  int get maxPlayers => throw _privateConstructorUsedError;
  @JsonKey(name: 'gameType')
  int get gameType => throw _privateConstructorUsedError;
  @JsonKey(name: 'smallBlind')
  int? get smallBlind => throw _privateConstructorUsedError;
  @JsonKey(name: 'bigBlind')
  int? get bigBlind => throw _privateConstructorUsedError;
  @JsonKey(name: 'anteType')
  int get anteType => throw _privateConstructorUsedError;
  @JsonKey(name: 'anteAmount')
  int get anteAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'rfidReaderId')
  int? get rfidReaderId => throw _privateConstructorUsedError;
  @JsonKey(name: 'deckRegistered')
  bool get deckRegistered => throw _privateConstructorUsedError;
  @JsonKey(name: 'outputType')
  String? get outputType => throw _privateConstructorUsedError;
  @JsonKey(name: 'currentGame')
  int? get currentGame => throw _privateConstructorUsedError;
  @JsonKey(name: 'delaySeconds')
  int get delaySeconds => throw _privateConstructorUsedError;
  int? get ring => throw _privateConstructorUsedError;
  @JsonKey(name: 'isBreakingTable')
  bool get isBreakingTable => throw _privateConstructorUsedError;
  String get source => throw _privateConstructorUsedError;
  @JsonKey(name: 'createdAt')
  String get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updatedAt')
  String get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'seatedCount')
  int? get seatedCount =>
      throw _privateConstructorUsedError; // Cycle 20 (#439, S2 Wave 3c): aggregate chip count for the table.
// Derived locally from `chip_count_synced` WS events (sum of seats[].chipCount).
// Not part of REST schema — backend persists chip_count per-seat only.
  @JsonKey(name: 'chipTotal')
  int get chipTotal => throw _privateConstructorUsedError;

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
      {@JsonKey(name: 'tableId') int tableId,
      @JsonKey(name: 'eventFlightId') int eventFlightId,
      @JsonKey(name: 'tableNo') int tableNo,
      String name,
      String type,
      String status,
      @JsonKey(name: 'maxPlayers') int maxPlayers,
      @JsonKey(name: 'gameType') int gameType,
      @JsonKey(name: 'smallBlind') int? smallBlind,
      @JsonKey(name: 'bigBlind') int? bigBlind,
      @JsonKey(name: 'anteType') int anteType,
      @JsonKey(name: 'anteAmount') int anteAmount,
      @JsonKey(name: 'rfidReaderId') int? rfidReaderId,
      @JsonKey(name: 'deckRegistered') bool deckRegistered,
      @JsonKey(name: 'outputType') String? outputType,
      @JsonKey(name: 'currentGame') int? currentGame,
      @JsonKey(name: 'delaySeconds') int delaySeconds,
      int? ring,
      @JsonKey(name: 'isBreakingTable') bool isBreakingTable,
      String source,
      @JsonKey(name: 'createdAt') String createdAt,
      @JsonKey(name: 'updatedAt') String updatedAt,
      @JsonKey(name: 'seatedCount') int? seatedCount,
      @JsonKey(name: 'chipTotal') int chipTotal});
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
    Object? chipTotal = null,
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
      chipTotal: null == chipTotal
          ? _value.chipTotal
          : chipTotal // ignore: cast_nullable_to_non_nullable
              as int,
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
      {@JsonKey(name: 'tableId') int tableId,
      @JsonKey(name: 'eventFlightId') int eventFlightId,
      @JsonKey(name: 'tableNo') int tableNo,
      String name,
      String type,
      String status,
      @JsonKey(name: 'maxPlayers') int maxPlayers,
      @JsonKey(name: 'gameType') int gameType,
      @JsonKey(name: 'smallBlind') int? smallBlind,
      @JsonKey(name: 'bigBlind') int? bigBlind,
      @JsonKey(name: 'anteType') int anteType,
      @JsonKey(name: 'anteAmount') int anteAmount,
      @JsonKey(name: 'rfidReaderId') int? rfidReaderId,
      @JsonKey(name: 'deckRegistered') bool deckRegistered,
      @JsonKey(name: 'outputType') String? outputType,
      @JsonKey(name: 'currentGame') int? currentGame,
      @JsonKey(name: 'delaySeconds') int delaySeconds,
      int? ring,
      @JsonKey(name: 'isBreakingTable') bool isBreakingTable,
      String source,
      @JsonKey(name: 'createdAt') String createdAt,
      @JsonKey(name: 'updatedAt') String updatedAt,
      @JsonKey(name: 'seatedCount') int? seatedCount,
      @JsonKey(name: 'chipTotal') int chipTotal});
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
    Object? chipTotal = null,
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
      chipTotal: null == chipTotal
          ? _value.chipTotal
          : chipTotal // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EbsTableImpl implements _EbsTable {
  const _$EbsTableImpl(
      {@JsonKey(name: 'tableId') required this.tableId,
      @JsonKey(name: 'eventFlightId') required this.eventFlightId,
      @JsonKey(name: 'tableNo') required this.tableNo,
      required this.name,
      required this.type,
      required this.status,
      @JsonKey(name: 'maxPlayers') required this.maxPlayers,
      @JsonKey(name: 'gameType') required this.gameType,
      @JsonKey(name: 'smallBlind') this.smallBlind,
      @JsonKey(name: 'bigBlind') this.bigBlind,
      @JsonKey(name: 'anteType') this.anteType = 0,
      @JsonKey(name: 'anteAmount') this.anteAmount = 0,
      @JsonKey(name: 'rfidReaderId') this.rfidReaderId,
      @JsonKey(name: 'deckRegistered') this.deckRegistered = false,
      @JsonKey(name: 'outputType') this.outputType,
      @JsonKey(name: 'currentGame') this.currentGame,
      @JsonKey(name: 'delaySeconds') this.delaySeconds = 0,
      this.ring,
      @JsonKey(name: 'isBreakingTable') this.isBreakingTable = false,
      required this.source,
      @JsonKey(name: 'createdAt') required this.createdAt,
      @JsonKey(name: 'updatedAt') required this.updatedAt,
      @JsonKey(name: 'seatedCount') this.seatedCount,
      @JsonKey(name: 'chipTotal') this.chipTotal = 0});

  factory _$EbsTableImpl.fromJson(Map<String, dynamic> json) =>
      _$$EbsTableImplFromJson(json);

  @override
  @JsonKey(name: 'tableId')
  final int tableId;
  @override
  @JsonKey(name: 'eventFlightId')
  final int eventFlightId;
  @override
  @JsonKey(name: 'tableNo')
  final int tableNo;
  @override
  final String name;
  @override
  final String type;
  @override
  final String status;
  @override
  @JsonKey(name: 'maxPlayers')
  final int maxPlayers;
  @override
  @JsonKey(name: 'gameType')
  final int gameType;
  @override
  @JsonKey(name: 'smallBlind')
  final int? smallBlind;
  @override
  @JsonKey(name: 'bigBlind')
  final int? bigBlind;
  @override
  @JsonKey(name: 'anteType')
  final int anteType;
  @override
  @JsonKey(name: 'anteAmount')
  final int anteAmount;
  @override
  @JsonKey(name: 'rfidReaderId')
  final int? rfidReaderId;
  @override
  @JsonKey(name: 'deckRegistered')
  final bool deckRegistered;
  @override
  @JsonKey(name: 'outputType')
  final String? outputType;
  @override
  @JsonKey(name: 'currentGame')
  final int? currentGame;
  @override
  @JsonKey(name: 'delaySeconds')
  final int delaySeconds;
  @override
  final int? ring;
  @override
  @JsonKey(name: 'isBreakingTable')
  final bool isBreakingTable;
  @override
  final String source;
  @override
  @JsonKey(name: 'createdAt')
  final String createdAt;
  @override
  @JsonKey(name: 'updatedAt')
  final String updatedAt;
  @override
  @JsonKey(name: 'seatedCount')
  final int? seatedCount;
// Cycle 20 (#439, S2 Wave 3c): aggregate chip count for the table.
// Derived locally from `chip_count_synced` WS events (sum of seats[].chipCount).
// Not part of REST schema — backend persists chip_count per-seat only.
  @override
  @JsonKey(name: 'chipTotal')
  final int chipTotal;

  @override
  String toString() {
    return 'EbsTable(tableId: $tableId, eventFlightId: $eventFlightId, tableNo: $tableNo, name: $name, type: $type, status: $status, maxPlayers: $maxPlayers, gameType: $gameType, smallBlind: $smallBlind, bigBlind: $bigBlind, anteType: $anteType, anteAmount: $anteAmount, rfidReaderId: $rfidReaderId, deckRegistered: $deckRegistered, outputType: $outputType, currentGame: $currentGame, delaySeconds: $delaySeconds, ring: $ring, isBreakingTable: $isBreakingTable, source: $source, createdAt: $createdAt, updatedAt: $updatedAt, seatedCount: $seatedCount, chipTotal: $chipTotal)';
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
                other.seatedCount == seatedCount) &&
            (identical(other.chipTotal, chipTotal) ||
                other.chipTotal == chipTotal));
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
        seatedCount,
        chipTotal
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
      {@JsonKey(name: 'tableId') required final int tableId,
      @JsonKey(name: 'eventFlightId') required final int eventFlightId,
      @JsonKey(name: 'tableNo') required final int tableNo,
      required final String name,
      required final String type,
      required final String status,
      @JsonKey(name: 'maxPlayers') required final int maxPlayers,
      @JsonKey(name: 'gameType') required final int gameType,
      @JsonKey(name: 'smallBlind') final int? smallBlind,
      @JsonKey(name: 'bigBlind') final int? bigBlind,
      @JsonKey(name: 'anteType') final int anteType,
      @JsonKey(name: 'anteAmount') final int anteAmount,
      @JsonKey(name: 'rfidReaderId') final int? rfidReaderId,
      @JsonKey(name: 'deckRegistered') final bool deckRegistered,
      @JsonKey(name: 'outputType') final String? outputType,
      @JsonKey(name: 'currentGame') final int? currentGame,
      @JsonKey(name: 'delaySeconds') final int delaySeconds,
      final int? ring,
      @JsonKey(name: 'isBreakingTable') final bool isBreakingTable,
      required final String source,
      @JsonKey(name: 'createdAt') required final String createdAt,
      @JsonKey(name: 'updatedAt') required final String updatedAt,
      @JsonKey(name: 'seatedCount') final int? seatedCount,
      @JsonKey(name: 'chipTotal') final int chipTotal}) = _$EbsTableImpl;

  factory _EbsTable.fromJson(Map<String, dynamic> json) =
      _$EbsTableImpl.fromJson;

  @override
  @JsonKey(name: 'tableId')
  int get tableId;
  @override
  @JsonKey(name: 'eventFlightId')
  int get eventFlightId;
  @override
  @JsonKey(name: 'tableNo')
  int get tableNo;
  @override
  String get name;
  @override
  String get type;
  @override
  String get status;
  @override
  @JsonKey(name: 'maxPlayers')
  int get maxPlayers;
  @override
  @JsonKey(name: 'gameType')
  int get gameType;
  @override
  @JsonKey(name: 'smallBlind')
  int? get smallBlind;
  @override
  @JsonKey(name: 'bigBlind')
  int? get bigBlind;
  @override
  @JsonKey(name: 'anteType')
  int get anteType;
  @override
  @JsonKey(name: 'anteAmount')
  int get anteAmount;
  @override
  @JsonKey(name: 'rfidReaderId')
  int? get rfidReaderId;
  @override
  @JsonKey(name: 'deckRegistered')
  bool get deckRegistered;
  @override
  @JsonKey(name: 'outputType')
  String? get outputType;
  @override
  @JsonKey(name: 'currentGame')
  int? get currentGame;
  @override
  @JsonKey(name: 'delaySeconds')
  int get delaySeconds;
  @override
  int? get ring;
  @override
  @JsonKey(name: 'isBreakingTable')
  bool get isBreakingTable;
  @override
  String get source;
  @override
  @JsonKey(name: 'createdAt')
  String get createdAt;
  @override
  @JsonKey(name: 'updatedAt')
  String get updatedAt;
  @override
  @JsonKey(name: 'seatedCount')
  int?
      get seatedCount; // Cycle 20 (#439, S2 Wave 3c): aggregate chip count for the table.
// Derived locally from `chip_count_synced` WS events (sum of seats[].chipCount).
// Not part of REST schema — backend persists chip_count per-seat only.
  @override
  @JsonKey(name: 'chipTotal')
  int get chipTotal;

  /// Create a copy of EbsTable
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EbsTableImplCopyWith<_$EbsTableImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
