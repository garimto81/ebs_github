// Riverpod providers for Lobby WebSocket lifecycle.
//
// - lobbyWsClientProvider: manages the LobbyWebSocketClient instance
// - wsConnectionStateProvider: mirrors WsStatus for UI consumption

import 'dart:async';

import 'package:ebs_common/ebs_common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums/ws_status.dart';
import 'bo_api_client.dart';
import 'lobby_websocket_client.dart';
import 'ws_dispatch.dart';

// ---------------------------------------------------------------------------
// WS Client Provider
// ---------------------------------------------------------------------------

final lobbyWsClientProvider = Provider<LobbyWebSocketClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final apiClient = ref.watch(boApiClientProvider);

  // Token accessor — reads current token from the API client.
  String getToken() => apiClient.accessToken ?? '';

  // Replay fetcher — calls REST to fill seq gaps (CCR-021).
  Future<List<WsEventEnvelope>> fetchReplay(int fromSeq, int toSeq) async {
    final result = await apiClient.post<Map<String, dynamic>>(
      '/Ws/Replay',
      data: {'fromSeq': fromSeq, 'toSeq': toSeq},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    final events = result['events'];
    if (events is List) {
      return events
          .map((e) => WsEventEnvelope.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  final client = LobbyWebSocketClient(
    wsBaseUrl: config.wsBaseUrl,
    getToken: getToken,
    onEvent: (event) => _dispatchIncomingEvent(ref, event),
    fetchReplay: fetchReplay,
  );

  ref.onDispose(() => client.dispose());
  return client;
});

// ---------------------------------------------------------------------------
// Connection State Provider
// ---------------------------------------------------------------------------

final wsConnectionStateProvider =
    StreamProvider<WsStatus>((ref) {
  final client = ref.watch(lobbyWsClientProvider);
  // Seed with current status, then follow the stream.
  final controller = StreamController<WsStatus>();
  controller.add(client.status);
  final sub = client.statusStream.listen(controller.add);
  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });
  return controller.stream;
});

// ---------------------------------------------------------------------------
// Event dispatch — bridges ebs_common WsEventEnvelope to ws_dispatch.dart
// ---------------------------------------------------------------------------

void _dispatchIncomingEvent(Ref ref, WsEventEnvelope event) {
  // Convert the ebs_common envelope to the local ws_dispatch envelope and
  // route to the appropriate feature providers.
  final localEnvelope = WsDispatchEnvelope(
    event: event.event,
    payload: event.payload,
    seq: event.seq,
  );
  dispatchWsEvent(<T>(p) => ref.read(p), localEnvelope);
}
