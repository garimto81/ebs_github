// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hand_player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HandPlayerImpl _$$HandPlayerImplFromJson(Map<String, dynamic> json) =>
    _$HandPlayerImpl(
      id: (json['id'] as num).toInt(),
      handId: (json['hand_id'] as num).toInt(),
      seatNo: (json['seat_no'] as num).toInt(),
      playerId: (json['player_id'] as num?)?.toInt(),
      playerName: json['player_name'] as String,
      holeCards: json['hole_cards'] as String,
      startStack: (json['start_stack'] as num).toInt(),
      endStack: (json['end_stack'] as num).toInt(),
      finalAction: json['final_action'] as String?,
      isWinner: json['is_winner'] as bool,
      pnl: (json['pnl'] as num).toInt(),
      handRank: json['hand_rank'] as String?,
      winProbability: (json['win_probability'] as num?)?.toDouble(),
      vpip: json['vpip'] as bool,
      pfr: json['pfr'] as bool,
    );

Map<String, dynamic> _$$HandPlayerImplToJson(_$HandPlayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'hand_id': instance.handId,
      'seat_no': instance.seatNo,
      'player_id': instance.playerId,
      'player_name': instance.playerName,
      'hole_cards': instance.holeCards,
      'start_stack': instance.startStack,
      'end_stack': instance.endStack,
      'final_action': instance.finalAction,
      'is_winner': instance.isWinner,
      'pnl': instance.pnl,
      'hand_rank': instance.handRank,
      'win_probability': instance.winProbability,
      'vpip': instance.vpip,
      'pfr': instance.pfr,
    };
