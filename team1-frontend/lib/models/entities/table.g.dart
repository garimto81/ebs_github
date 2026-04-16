// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EbsTableImpl _$$EbsTableImplFromJson(Map<String, dynamic> json) =>
    _$EbsTableImpl(
      tableId: (json['table_id'] as num).toInt(),
      eventFlightId: (json['event_flight_id'] as num).toInt(),
      tableNo: (json['table_no'] as num).toInt(),
      name: json['name'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      maxPlayers: (json['max_players'] as num).toInt(),
      gameType: (json['game_type'] as num).toInt(),
      smallBlind: (json['small_blind'] as num?)?.toInt(),
      bigBlind: (json['big_blind'] as num?)?.toInt(),
      anteType: (json['ante_type'] as num).toInt(),
      anteAmount: (json['ante_amount'] as num).toInt(),
      rfidReaderId: (json['rfid_reader_id'] as num?)?.toInt(),
      deckRegistered: json['deck_registered'] as bool,
      outputType: json['output_type'] as String?,
      currentGame: (json['current_game'] as num?)?.toInt(),
      delaySeconds: (json['delay_seconds'] as num).toInt(),
      ring: (json['ring'] as num?)?.toInt(),
      isBreakingTable: json['is_breaking_table'] as bool,
      source: json['source'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      seatedCount: (json['seated_count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$EbsTableImplToJson(_$EbsTableImpl instance) =>
    <String, dynamic>{
      'table_id': instance.tableId,
      'event_flight_id': instance.eventFlightId,
      'table_no': instance.tableNo,
      'name': instance.name,
      'type': instance.type,
      'status': instance.status,
      'max_players': instance.maxPlayers,
      'game_type': instance.gameType,
      'small_blind': instance.smallBlind,
      'big_blind': instance.bigBlind,
      'ante_type': instance.anteType,
      'ante_amount': instance.anteAmount,
      'rfid_reader_id': instance.rfidReaderId,
      'deck_registered': instance.deckRegistered,
      'output_type': instance.outputType,
      'current_game': instance.currentGame,
      'delay_seconds': instance.delaySeconds,
      'ring': instance.ring,
      'is_breaking_table': instance.isBreakingTable,
      'source': instance.source,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'seated_count': instance.seatedCount,
    };
