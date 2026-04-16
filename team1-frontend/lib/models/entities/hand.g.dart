// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hand.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HandImpl _$$HandImplFromJson(Map<String, dynamic> json) => _$HandImpl(
      handId: (json['hand_id'] as num).toInt(),
      tableId: (json['table_id'] as num).toInt(),
      handNumber: (json['hand_number'] as num).toInt(),
      gameType: (json['game_type'] as num).toInt(),
      betStructure: (json['bet_structure'] as num).toInt(),
      dealerSeat: (json['dealer_seat'] as num).toInt(),
      boardCards: json['board_cards'] as String,
      potTotal: (json['pot_total'] as num).toInt(),
      sidePots: json['side_pots'] as String,
      currentStreet: json['current_street'] as String?,
      startedAt: json['started_at'] as String,
      endedAt: json['ended_at'] as String?,
      durationSec: (json['duration_sec'] as num).toInt(),
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$$HandImplToJson(_$HandImpl instance) =>
    <String, dynamic>{
      'hand_id': instance.handId,
      'table_id': instance.tableId,
      'hand_number': instance.handNumber,
      'game_type': instance.gameType,
      'bet_structure': instance.betStructure,
      'dealer_seat': instance.dealerSeat,
      'board_cards': instance.boardCards,
      'pot_total': instance.potTotal,
      'side_pots': instance.sidePots,
      'current_street': instance.currentStreet,
      'started_at': instance.startedAt,
      'ended_at': instance.endedAt,
      'duration_sec': instance.durationSec,
      'created_at': instance.createdAt,
    };
