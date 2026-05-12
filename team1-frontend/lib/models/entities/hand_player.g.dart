// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hand_player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HandPlayerImpl _$$HandPlayerImplFromJson(Map<String, dynamic> json) =>
    _$HandPlayerImpl(
      id: (json['id'] as num).toInt(),
      handId: (json['handId'] as num).toInt(),
      seatNo: (json['seatNo'] as num).toInt(),
      playerId: (json['playerId'] as num?)?.toInt(),
      playerName: json['playerName'] as String,
      holeCards: json['holeCards'] as String,
      startStack: (json['startStack'] as num).toInt(),
      endStack: (json['endStack'] as num).toInt(),
      finalAction: json['finalAction'] as String?,
      isWinner: json['isWinner'] as bool,
      pnl: (json['pnl'] as num).toInt(),
      handRank: json['handRank'] as String?,
      winProbability: (json['winProbability'] as num?)?.toDouble(),
      vpip: json['vpip'] as bool,
      pfr: json['pfr'] as bool,
      runItTwiceShare: (json['runItTwiceShare'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$HandPlayerImplToJson(_$HandPlayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'handId': instance.handId,
      'seatNo': instance.seatNo,
      if (instance.playerId case final value?) 'playerId': value,
      'playerName': instance.playerName,
      'holeCards': instance.holeCards,
      'startStack': instance.startStack,
      'endStack': instance.endStack,
      if (instance.finalAction case final value?) 'finalAction': value,
      'isWinner': instance.isWinner,
      'pnl': instance.pnl,
      if (instance.handRank case final value?) 'handRank': value,
      if (instance.winProbability case final value?) 'winProbability': value,
      'vpip': instance.vpip,
      'pfr': instance.pfr,
      if (instance.runItTwiceShare case final value?) 'runItTwiceShare': value,
    };
