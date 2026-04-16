// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ws_event_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WsEventEnvelopeImpl _$$WsEventEnvelopeImplFromJson(
        Map<String, dynamic> json) =>
    _$WsEventEnvelopeImpl(
      seq: (json['seq'] as num).toInt(),
      channel: json['channel'] as String,
      event: json['event'] as String,
      payload: json['payload'] as Map<String, dynamic>,
      ts: json['ts'] as String,
    );

Map<String, dynamic> _$$WsEventEnvelopeImplToJson(
        _$WsEventEnvelopeImpl instance) =>
    <String, dynamic>{
      'seq': instance.seq,
      'channel': instance.channel,
      'event': instance.event,
      'payload': instance.payload,
      'ts': instance.ts,
    };
