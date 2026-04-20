// SG-002 Engine Connection State Machine (3-stage).
//
// States:
//   Connecting  → initial boot (splash screen, 0~5s)
//   Degraded    → initial connect failed, retries in progress (5~15s),
//                 Demo Mode auto-enabled, warning banner visible
//   Offline     → retry exhausted (3 attempts), Demo Mode persists,
//                 manual "재연결" button available
//   Online      → connection healthy (optional terminal state for clarity)
//
// Retry policy: exponential backoff 1s → 2s → 4s, max 3 attempts.
//
// team4 session TODO markers:
//   [TODO-T4-006] wire this provider into AppRouter redirect guards
//   [TODO-T4-008] add manual reconnect action button

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/remote/engine_client.dart';
import '../services/stub_engine.dart';

/// 3-stage connection state for the Game Engine harness.
enum EngineConnectionStage {
  connecting,
  degraded,
  offline,
  online,
}

class EngineConnectionState {
  const EngineConnectionState({
    required this.stage,
    this.lastError,
    this.attemptCount = 0,
    this.baseUrl = '',
  });

  final EngineConnectionStage stage;
  final String? lastError;
  final int attemptCount;
  final String baseUrl;

  bool get shouldUseStub => stage == EngineConnectionStage.degraded ||
      stage == EngineConnectionStage.offline;

  EngineConnectionState copyWith({
    EngineConnectionStage? stage,
    String? lastError,
    int? attemptCount,
    String? baseUrl,
  }) {
    return EngineConnectionState(
      stage: stage ?? this.stage,
      lastError: lastError ?? this.lastError,
      attemptCount: attemptCount ?? this.attemptCount,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }
}

class EngineConnectionController extends StateNotifier<EngineConnectionState> {
  EngineConnectionController({
    required this.client,
    Dio? healthDio,
  })  : _healthDio = healthDio ??
            Dio(BaseOptions(
              baseUrl: client.baseUrl,
              connectTimeout: const Duration(seconds: 3),
              sendTimeout: const Duration(seconds: 2),
              receiveTimeout: const Duration(seconds: 2),
            )),
        super(EngineConnectionState(
          stage: EngineConnectionStage.connecting,
          baseUrl: client.baseUrl,
        ));

  final EngineClient client;
  final Dio _healthDio;
  Timer? _retryTimer;

  static const _maxAttempts = 3;
  static const _retryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];

  /// Entry point — call once at app boot.
  Future<void> probeAndConnect() async {
    state = state.copyWith(
      stage: EngineConnectionStage.connecting,
      attemptCount: 0,
    );
    await _tryConnect();
  }

  /// Actual health-check probe.
  ///
  /// Strategy (per SG-002):
  ///   1. `GET /engine/health` — primary endpoint (team3 harness convention).
  ///   2. Fallback: `GET /` — any 2xx/4xx response proves reachability.
  ///
  /// Returns `true` if the engine is reachable; throws `DioException` on
  /// connection timeout / connection refused so the caller can transition.
  Future<bool> _probeHealth() async {
    try {
      final response = await _healthDio.get<dynamic>('/engine/health');
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } on DioException catch (e) {
      // Connection-level failures → propagate to caller for retry logic.
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        rethrow;
      }
      // 404/405 on /engine/health → try fallback root probe.
      try {
        final fallback = await _healthDio.get<dynamic>('/');
        final code = fallback.statusCode ?? 0;
        // Even 404 on root proves the server is listening.
        return code > 0;
      } on DioException {
        rethrow;
      }
    }
  }

  Future<void> _tryConnect() async {
    final attempt = state.attemptCount;
    try {
      final ok = await _probeHealth();
      if (ok) {
        state = state.copyWith(
          stage: EngineConnectionStage.online,
          lastError: null,
        );
      } else {
        await _handleConnectFailure(attempt, 'non-2xx health response');
      }
    } on DioException catch (e) {
      await _handleConnectFailure(attempt, e.message ?? 'DioException');
    } catch (e) {
      await _handleConnectFailure(attempt, e.toString());
    }
  }

  Future<void> _handleConnectFailure(int attempt, String errorMsg) async {
    final nextAttempt = attempt + 1;

    if (nextAttempt > _maxAttempts) {
      state = state.copyWith(
        stage: EngineConnectionStage.offline,
        lastError: errorMsg,
        attemptCount: nextAttempt,
      );
      return;
    }

    // Degraded while retrying — Demo Mode kicks in.
    state = state.copyWith(
      stage: EngineConnectionStage.degraded,
      lastError: errorMsg,
      attemptCount: nextAttempt,
    );

    final delay = _retryDelays[attempt.clamp(0, _retryDelays.length - 1)];
    _retryTimer = Timer(delay, () {
      _tryConnect();
    });
  }

  /// User-initiated manual reconnect (from offline banner).
  Future<void> manualReconnect() async {
    _retryTimer?.cancel();
    await probeAndConnect();
  }

  // test-only: reset to initial connecting state (retries cleared).
  // Used by widget tests to drive 3-stage transitions deterministically.
  @visibleForTesting
  void reset() {
    _retryTimer?.cancel();
    state = EngineConnectionState(
      stage: EngineConnectionStage.connecting,
      baseUrl: client.baseUrl,
    );
  }

  // test-only: force a specific stage without running the probe.
  // Used by widget tests to drive 3-stage transitions deterministically.
  @visibleForTesting
  void setStage(EngineConnectionStage stage, {String? lastError}) {
    _retryTimer?.cancel();
    state = state.copyWith(stage: stage, lastError: lastError);
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }
}

// Riverpod providers ---------------------------------------------------------

final engineClientProvider = Provider<EngineClient>((ref) {
  return EngineClient();
});

final engineConnectionProvider =
    StateNotifierProvider<EngineConnectionController, EngineConnectionState>(
  (ref) {
    final client = ref.watch(engineClientProvider);
    return EngineConnectionController(client: client);
  },
);

/// Lazily created stub engine — only materialized when in Demo Mode.
final stubEngineProvider = Provider<StubEngine>((ref) {
  final stub = StubEngine();
  ref.onDispose(() async => stub.dispose());
  return stub;
});

/// Bridges engineConnection ↔ stubEngine lifecycle.
///
/// [TODO-T4-007] When connection enters Degraded/Offline, subscribe to the
/// stub-engine event stream so the Overlay can render demo content. When
/// connection returns to Online, cancel the subscription.
///
/// Watch this provider from the app root once (e.g. in AppRouter) so the
/// listener stays alive for the session.
final stubEngineBridgeProvider = Provider<void>((ref) {
  StreamSubscription<StubOutputEvent>? subscription;

  ref.listen<EngineConnectionState>(
    engineConnectionProvider,
    (prev, next) {
      final shouldSubscribe = next.shouldUseStub;
      final wasSubscribed = prev?.shouldUseStub ?? false;

      if (shouldSubscribe && !wasSubscribed) {
        // Entering Demo Mode — start consuming stub events.
        final stub = ref.read(stubEngineProvider);
        subscription = stub.events.listen((_) {
          // TODO-T4-007: fan-out stub events to overlay consumer.
          // Intentionally left as skeleton — the overlay consumer is the
          // subscriber of record (lib/features/overlay/services/skin_consumer.dart).
        });
      } else if (!shouldSubscribe && wasSubscribed) {
        // Back online — release stub subscription.
        subscription?.cancel();
        subscription = null;
      }
    },
    fireImmediately: true,
  );

  ref.onDispose(() {
    subscription?.cancel();
  });
});
