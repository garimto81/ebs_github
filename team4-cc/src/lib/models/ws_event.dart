// WebSocket Event Envelope — Freezed DTO for all WS messages.
// See API-05 §WebSocket protocol, CCR-021 seq/replay.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'ws_event.freezed.dart';
part 'ws_event.g.dart';

@freezed
class WsEvent with _$WsEvent {
  const factory WsEvent({
    required String type,
    required Map<String, dynamic> data,
    int? seq,
    String? timestamp,
    String? error,
    Map<String, dynamic>? metadata,
  }) = _WsEvent;

  factory WsEvent.fromJson(Map<String, dynamic> json) =>
      _$WsEventFromJson(json);
}
