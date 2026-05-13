// BO WebSocket client for CC/Overlay.
//
// - Connects to `ws://{host}/ws/cc?table_id={id}&token={token}`.
// - Tracks monotonic `seq` field (CCR-021) via SeqTracker; on gap detection
//   invokes `GET /events/replay?from_seq=X&to_seq=Y` before applying the
//   triggering event.
// - Dispatches `skin_updated` events (CCR-015) to the SkinConsumer.
// - Dispatches `chip_count_synced` events (Cycle 20 #437, WS §4.2.11) — BO
//   forwards WSOP LIVE webhook chip count snapshots to update seat stacks.
// - Reconnect policy (CCR-022 §9 / BS-05-00 §BO 복구):
//     0ms → 5s → 10s × 100 → stop.
// - Heartbeat: ping every 30s, pong timeout 10s, 3 consecutive failures →
//   disconnect + reconnect.
// - Offline buffering: disconnected CC actions go to LocalEventBuffer;
//   on reconnect, drain → ReplayEvents batch.
//
// See: docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md
//      §1 endpoint + envelope (seq, CCR-015), §3 event types, §reconnect policy.
//      §4.2.11 chip_count_synced (Cycle 20 #437).

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../data/local/event_buffer.dart';
import '../../foundation/utils/seq_tracker.dart';
import '../../resources/constants.dart';

/// Callback for incoming events.
typedef EventHandler = void Function(Map<String, dynamic> payload);

/// Fetches missing events for a seq gap range (inclusive).
typedef ReplayFetcher = Future<List<Map<String, dynamic>>> Function(
    int fromSeq, int toSeq);

/// Called when the offline buffer is full and cannot accept more events.
typedef BufferFullCallback = void Function();

/// WebSocket connection state FSM.
enum WsConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

/// BO WebSocket client with reconnect FSM, heartbeat, command sending,
/// event type dispatching, and offline buffering.
class BoWebSocketClient {
  BoWebSocketClient({
    required this.wsUrl,
    required this.tableId,
    required this.token,
    required this.onEvent,
    required this.fetchReplay,
    BufferFullCallback? onBufferFull,
  }) : _onBufferFull = onBufferFull;

  // ---------------------------------------------------------------------------
  // Construction parameters
  // ---------------------------------------------------------------------------

  final String wsUrl;
  final int tableId;
  final String token;
  final EventHandler onEvent;
  final ReplayFetcher fetchReplay;
  final BufferFullCallback? _onBufferFull;

  // ---------------------------------------------------------------------------
  // Internal state
  // ---------------------------------------------------------------------------

  WebSocketChannel? _channel;
  final SeqTracker _seq = SeqTracker();
  StreamSubscription<dynamic>? _sub;

  /// Outbound command sequence counter.
  int _outSeq = 1;

  /// Current reconnect attempt (0-indexed). Reset on successful connect.
  int _reconnectAttempt = 0;

  /// Consecutive pong failures.
  int _missedPongs = 0;

  /// Whether we are waiting for a pong.
  bool _awaitingPong = false;

  Timer? _heartbeatTimer;
  Timer? _pongTimeoutTimer;
  Timer? _reconnectTimer;

  /// Offline event buffer (capacity from AppConstants).
  final LocalEventBuffer _offlineBuffer =
      LocalEventBuffer(capacity: AppConstants.localEventBufferCapacity);

  // ---------------------------------------------------------------------------
  // Connection state stream
  // ---------------------------------------------------------------------------

  final StreamController<WsConnectionState> _connectionStateController =
      StreamController<WsConnectionState>.broadcast();

  WsConnectionState _state = WsConnectionState.disconnected;

  /// Stream of connection state changes.
  Stream<WsConnectionState> get connectionState =>
      _connectionStateController.stream;

  /// Current connection state (synchronous read).
  WsConnectionState get currentState => _state;

  void _setState(WsConnectionState newState) {
    if (_state == newState) return;
    _state = newState;
    _connectionStateController.add(newState);
  }

  // ---------------------------------------------------------------------------
  // Event type dispatching
  // ---------------------------------------------------------------------------

  final Map<String, List<EventHandler>> _handlers = {};

  /// Register a handler for a specific event type (e.g. `'HandStarted'`).
  void on(String eventType, EventHandler handler) {
    _handlers.putIfAbsent(eventType, () => []).add(handler);
  }

  /// Remove a previously registered handler.
  void off(String eventType, EventHandler handler) {
    _handlers[eventType]?.remove(handler);
  }

  // ---------------------------------------------------------------------------
  // Connect / Reconnect FSM
  // ---------------------------------------------------------------------------

  /// Connect and start listening. Manages reconnect internally.
  Future<void> connect() async {
    if (_state == WsConnectionState.connected ||
        _state == WsConnectionState.connecting) {
      return;
    }
    _setState(WsConnectionState.connecting);
    await _doConnect();
  }

  Future<void> _doConnect() async {
    try {
      final uri = Uri.parse(
        '$wsUrl/ws/cc?table_id=$tableId&token=$token',
      );
      _channel = WebSocketChannel.connect(uri);
      _sub = _channel!.stream.listen(
        _onRawMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _setState(WsConnectionState.connected);
      _reconnectAttempt = 0;
      _missedPongs = 0;
      _awaitingPong = false;

      _startHeartbeat();

      // Drain offline buffer → send as ReplayEvents batch.
      await _drainOfflineBuffer();
    } catch (e) {
      _onError(e);
    }
  }

  void _onDone() {
    _stopHeartbeat();
    if (_state == WsConnectionState.disconnected ||
        _state == WsConnectionState.failed) {
      return; // Intentional disconnect or already failed.
    }
    _scheduleReconnect();
  }

  void _onError(Object error) {
    _stopHeartbeat();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_state == WsConnectionState.failed ||
        _state == WsConnectionState.disconnected) {
      return;
    }

    if (_reconnectAttempt >= AppConstants.maxReconnectAttempts) {
      _setState(WsConnectionState.failed);
      return;
    }

    _setState(WsConnectionState.reconnecting);

    final backoffMs = _getBackoffMs(_reconnectAttempt);
    _reconnectAttempt++;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(milliseconds: backoffMs),
      () async {
        await _cleanup();
        await _doConnect();
      },
    );
  }

  /// Backoff schedule: attempt 0 → 0ms, attempt 1 → 5000ms,
  /// attempt 2+ → 10000ms (from AppConstants.reconnectBackoffMs).
  int _getBackoffMs(int attempt) {
    const schedule = AppConstants.reconnectBackoffMs;
    if (attempt < schedule.length) {
      return schedule[attempt];
    }
    return schedule.last;
  }

  // ---------------------------------------------------------------------------
  // Heartbeat (ping/pong)
  // ---------------------------------------------------------------------------

  static const _heartbeatIntervalMs = 30000;
  static const _pongTimeoutMs = 10000;
  static const _maxMissedPongs = 3;

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(
      const Duration(milliseconds: _heartbeatIntervalMs),
      (_) => _sendPing(),
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = null;
  }

  void _sendPing() {
    if (_state != WsConnectionState.connected) return;

    _awaitingPong = true;
    try {
      _channel?.sink.add(jsonEncode({'type': 'ping'}));
    } catch (_) {
      // sink already closed — handled by onDone/onError.
      return;
    }

    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = Timer(
      const Duration(milliseconds: _pongTimeoutMs),
      () {
        if (!_awaitingPong) return;
        _missedPongs++;
        _awaitingPong = false;
        if (_missedPongs >= _maxMissedPongs) {
          // 3 consecutive failures → disconnect + reconnect.
          _stopHeartbeat();
          _scheduleReconnect();
        }
      },
    );
  }

  void _handlePong() {
    _awaitingPong = false;
    _missedPongs = 0;
    _pongTimeoutTimer?.cancel();
  }

  // ---------------------------------------------------------------------------
  // Message handling
  // ---------------------------------------------------------------------------

  Future<void> _onRawMessage(dynamic raw) async {
    final Map<String, dynamic> payload = raw is String
        ? (jsonDecode(raw) as Map<String, dynamic>)
        : <String, dynamic>{};

    final type = payload['type'] as String?;

    // Handle pong responses (not dispatched to event handlers).
    if (type == 'pong') {
      _handlePong();
      return;
    }

    // Seq tracking (CCR-021).
    final seq = payload['seq'];
    if (seq is int) {
      final gaps = _seq.apply(seq);
      for (final (from, to) in gaps) {
        final missing = await fetchReplay(from, to);
        for (final ev in missing) {
          _dispatchEvent(ev);
        }
      }
    }

    _dispatchEvent(payload);
  }

  /// Dispatch to the global onEvent callback and type-specific handlers.
  void _dispatchEvent(Map<String, dynamic> payload) {
    onEvent(payload);

    final type = payload['type'] as String?;
    if (type != null && _handlers.containsKey(type)) {
      for (final handler in _handlers[type]!) {
        handler(payload);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Send commands (CC → BO)
  // ---------------------------------------------------------------------------

  /// Send a command to BO. If disconnected, buffers locally.
  ///
  /// Returns `true` if sent or buffered successfully, `false` if the offline
  /// buffer is full (caller should show "Hand Reset Required" warning).
  bool sendCommand(String type, Map<String, dynamic> data, {
    String? idempotencyKey,
  }) {
    final envelope = <String, dynamic>{
      'type': type,
      'payload': data,
      'seq': _outSeq++,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'source_id': 'cc-table-$tableId',
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
    };

    if (_state == WsConnectionState.connected) {
      try {
        _channel?.sink.add(jsonEncode(envelope));
        return true;
      } catch (_) {
        // Fall through to offline buffering.
      }
    }

    // Offline: buffer locally (BS-05-00 §BO 복구).
    final event = LocalEvent(
      type: type,
      payload: envelope,
      localTimestamp: DateTime.now(),
    );
    final accepted = _offlineBuffer.tryAppend(event);
    if (!accepted) {
      _onBufferFull?.call();
    }
    return accepted;
  }

  // ---------------------------------------------------------------------------
  // Typed commands (WebSocket_Events.md §9-§12)
  // ---------------------------------------------------------------------------

  /// §10 WriteAction — operator submits a player action.
  bool sendAction({
    required int handId,
    required int seat,
    required String actionType,
    int amount = 0,
    String? idempotencyKey,
  }) {
    return sendCommand('WriteAction', {
      'hand_id': handId,
      'seat': seat,
      'action_type': actionType,
      'amount': amount,
    }, idempotencyKey: idempotencyKey);
  }

  /// §11 WriteDeal — operator presses DEAL button.
  bool sendDeal({
    required int handId,
    String? idempotencyKey,
  }) {
    return sendCommand('WriteDeal', {
      'hand_id': handId,
    }, idempotencyKey: idempotencyKey);
  }

  // ---------------------------------------------------------------------------
  // Typed subscriptions (WebSocket_Events.md §4)
  // ---------------------------------------------------------------------------

  /// §4.2.11 chip_count_synced (Cycle 20 #437) — register a handler for the
  /// WSOP LIVE chip count snapshot broadcast. The handler receives the raw
  /// envelope `{type, seq, data: {table_id, snapshot_id, break_id, seats,
  /// recorded_at, received_at, signature_ok}}`.
  ///
  /// Thin convenience over [on] — included for discoverability + type-aligned
  /// onboarding (matches the typed `sendAction` / `sendDeal` outgoing API).
  void onChipCountSynced(EventHandler handler) {
    on('chip_count_synced', handler);
  }

  // ---------------------------------------------------------------------------
  // Offline buffer drain
  // ---------------------------------------------------------------------------

  Future<void> _drainOfflineBuffer() async {
    if (_offlineBuffer.length == 0) return;

    final buffered = _offlineBuffer.drain();

    // Send as a ReplayEvents batch.
    final batch = <Map<String, dynamic>>[];
    for (final event in buffered) {
      batch.add(event.payload);
    }

    if (batch.isNotEmpty) {
      final replayEnvelope = <String, dynamic>{
        'type': 'ReplayEvents',
        'data': {'events': batch},
        'seq': _outSeq++,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };
      try {
        _channel?.sink.add(jsonEncode(replayEnvelope));
      } catch (_) {
        // If send fails, re-buffer (best effort).
        for (final event in buffered) {
          _offlineBuffer.tryAppend(event);
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Disconnect / cleanup
  // ---------------------------------------------------------------------------

  /// Intentional disconnect. Stops reconnect attempts.
  Future<void> disconnect() async {
    _setState(WsConnectionState.disconnected);
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stopHeartbeat();
    await _cleanup();
    await _connectionStateController.close();
  }

  Future<void> _cleanup() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _channel?.sink.close();
    } catch (_) {
      // Already closed.
    }
    _channel = null;
  }
}
