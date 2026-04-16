import 'package:freezed_annotation/freezed_annotation.dart';

part 'ws_event_envelope.freezed.dart';
part 'ws_event_envelope.g.dart';

@freezed
class WsEventEnvelope with _$WsEventEnvelope {
  const factory WsEventEnvelope({
    required int seq,
    required String channel,
    required String event,
    required Map<String, dynamic> payload,
    required String ts,
  }) = _WsEventEnvelope;

  factory WsEventEnvelope.fromJson(Map<String, dynamic> json) =>
      _$WsEventEnvelopeFromJson(json);
}
