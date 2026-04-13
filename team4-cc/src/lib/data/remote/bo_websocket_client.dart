// BO WebSocket client for CC/Overlay.
//
// - Connects to `ws://{host}/ws/cc?table_id={id}&token={token}`.
// - Tracks monotonic `seq` field (CCR-021) via SeqTracker; on gap detection
//   invokes `GET /events/replay?from_seq=X&to_seq=Y` before applying the
//   triggering event.
// - Dispatches `skin_updated` events (CCR-015) to the SkinConsumer.
// - Reconnect policy (CCR-022 §9 / BS-05-00 §BO 복구):
//     0ms → 5s → 10s × 100 → stop.
//
// See: contracts/api/API-05-websocket-events.md §1.4 (CCR-003 idempotency_key),
//      §envelope seq field (CCR-015), §reconnect policy.

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../foundation/utils/seq_tracker.dart';

typedef EventHandler = void Function(Map<String, dynamic> payload);
typedef ReplayFetcher = Future<List<Map<String, dynamic>>> Function(
    int fromSeq, int toSeq);

class BoWebSocketClient {
  BoWebSocketClient({
    required this.wsUrl,
    required this.tableId,
    required this.token,
    required this.onEvent,
    required this.fetchReplay,
  });

  final String wsUrl;
  final int tableId;
  final String token;
  final EventHandler onEvent;
  final ReplayFetcher fetchReplay;

  WebSocketChannel? _channel;
  final SeqTracker _seq = SeqTracker();
  StreamSubscription<dynamic>? _sub;

  /// Connect and start listening. Does NOT retry internally; the caller
  /// handles the reconnect backoff policy (0ms → 5s → 10s × 100).
  Future<void> connect() async {
    final uri = Uri.parse(
      '$wsUrl/ws/cc?table_id=$tableId&token=$token',
    );
    _channel = WebSocketChannel.connect(uri);
    _sub = _channel!.stream.listen(_onRawMessage, onError: _onError);
  }

  Future<void> _onRawMessage(dynamic raw) async {
    final Map<String, dynamic> payload = raw is String
        ? (jsonDecode(raw) as Map<String, dynamic>)
        : <String, dynamic>{};

    final seq = payload['seq'];
    if (seq is int) {
      final gaps = _seq.apply(seq);
      for (final (from, to) in gaps) {
        // Fetch missing events first, apply in order, then apply triggering event.
        final missing = await fetchReplay(from, to);
        for (final ev in missing) {
          onEvent(ev);
        }
      }
    }

    onEvent(payload);
  }

  void _onError(Object error) {
    // TODO(CCR-022 §9): promote to reconnect FSM in higher-level orchestrator.
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    await _channel?.sink.close();
    _sub = null;
    _channel = null;
  }
}
