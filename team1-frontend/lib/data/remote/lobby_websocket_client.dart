// Lobby WebSocket client — read-only /ws/lobby connection (CCR-021).
//
// Ported from _archive-quasar/src/stores/wsStore.ts.
// Team 1 only consumes events (no sendCommand). Simpler than team4's
// BoWebSocketClient which includes heartbeat, offline buffering, and
// bidirectional command sending.

import 'dart:async';
import 'dart:convert';

import 'package:ebs_common/ebs_common.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../models/enums/ws_status.dart';

// ---------------------------------------------------------------------------
// Client
// ---------------------------------------------------------------------------

class LobbyWebSocketClient {
  LobbyWebSocketClient({
    required this.wsBaseUrl,
    required this.getToken,
    required this.onEvent,
    required this.fetchReplay,
  });

  final String wsBaseUrl;
  final String Function() getToken;
  final void Function(WsEventEnvelope event) onEvent;

  /// Called when a seq gap is detected — fetch missing events from REST.
  final Future<List<WsEventEnvelope>> Function(int fromSeq, int toSeq)
      fetchReplay;

  // -- Internal state ------------------------------------------------------

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final SeqTracker _seq = SeqTracker();
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;

  static const _initialBackoffMs = 1000;
  static const _maxBackoffMs = 30000;

  // -- Connection state stream ---------------------------------------------

  final StreamController<WsStatus> _statusController =
      StreamController<WsStatus>.broadcast();
  WsStatus _status = WsStatus.disconnected;

  Stream<WsStatus> get statusStream => _statusController.stream;
  WsStatus get status => _status;

  void _setStatus(WsStatus s) {
    if (_status == s) return;
    _status = s;
    _statusController.add(s);
  }

  // -- Connect / Disconnect ------------------------------------------------

  void connect() {
    if (_status == WsStatus.connected || _status == WsStatus.connecting) {
      return;
    }
    _setStatus(WsStatus.connecting);
    _doConnect();
  }

  void _doConnect() {
    try {
      final token = getToken();
      final uri = Uri.parse('$wsBaseUrl/ws/lobby?token=$token');
      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        _onRawMessage,
        onError: (_) {
          _setStatus(WsStatus.error);
          _scheduleReconnect();
        },
        onDone: () {
          if (_status != WsStatus.disconnected) {
            _scheduleReconnect();
          }
        },
      );

      _setStatus(WsStatus.connected);
      _reconnectAttempt = 0;
    } catch (_) {
      _setStatus(WsStatus.error);
      _scheduleReconnect();
    }
  }

  void disconnect() {
    _setStatus(WsStatus.disconnected);
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _cleanup();
    _seq.reset(0);
  }

  void dispose() {
    disconnect();
    _statusController.close();
  }

  // -- Message handling ----------------------------------------------------

  Future<void> _onRawMessage(dynamic raw) async {
    if (raw is! String) return;
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final envelope = WsEventEnvelope.fromJson(json);

    // CCR-021 sequence validation via SeqTracker.
    final gaps = _seq.apply(envelope.seq);
    for (final (from, to) in gaps) {
      try {
        final missing = await fetchReplay(from, to);
        for (final ev in missing) {
          onEvent(ev);
        }
      } catch (_) {
        // Best-effort replay; gap may remain.
      }
    }

    onEvent(envelope);
  }

  // -- Reconnect -----------------------------------------------------------

  void _scheduleReconnect() {
    if (_status == WsStatus.disconnected) return;
    _setStatus(WsStatus.reconnecting);
    _reconnectAttempt++;

    final delayMs = _backoffMs(_reconnectAttempt);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () {
      _cleanup();
      _doConnect();
    });
  }

  int _backoffMs(int attempt) {
    // 1s → 2s → 4s → 8s → ... → 30s cap
    final ms = _initialBackoffMs * (1 << (attempt - 1));
    return ms.clamp(0, _maxBackoffMs);
  }

  // -- Cleanup -------------------------------------------------------------

  void _cleanup() {
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }
}
