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
//   [TODO-T4-005] health-check endpoint probe (GET /engine/health)
//   [TODO-T4-006] wire this provider into AppRouter redirect guards
//   [TODO-T4-007] integrate StubEngine stream on Degraded/Offline entry
//   [TODO-T4-008] add manual reconnect action button

import 'dart:async';

import 'package:dio/dio.dart';
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
  EngineConnectionController({required this.client})
      : super(EngineConnectionState(
          stage: EngineConnectionStage.connecting,
          baseUrl: client.baseUrl,
        ));

  final EngineClient client;
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

  Future<void> _tryConnect() async {
    final attempt = state.attemptCount;
    try {
      // [TODO-T4-005] Replace with actual health-check call:
      //   final response = await client.healthCheck();
      // For skeleton, simulate via a short delay.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Success path (skeleton always succeeds unless overridden):
      state = state.copyWith(
        stage: EngineConnectionStage.online,
        lastError: null,
      );
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
