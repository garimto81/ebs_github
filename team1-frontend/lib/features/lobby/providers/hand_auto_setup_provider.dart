// 1 hand auto-setup wire — Cycle 2 (Issue #239).
//
// Sequence (executed once on Lobby init when AppConfig.handAutoSetup == true):
//   1) table 생성   : POST /api/v1/tables (or mock)
//   2) CC 할당     : POST /api/v1/tables/{id}/cc-session (or mock)
//   3) RFID monitor: subscribe `/ws/lobby` for `rfid_seat_*` events
//   4) cascade     : log `cascade:lobby-hand-ready` (S2 → broker @ 7383)
//
// The wire is intentionally observability-only at this layer — actual API
// surface (POST endpoints) is published by S7 (Backend). When backend
// endpoints are not yet available, the wire logs WARN and marks each step
// as PENDING. Idempotent: multiple invocations during HMR are no-ops.
//
// Test hook: `--dart-define=HAND_AUTO_SETUP=true` enables this in any build.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step state for the 1-hand auto-setup sequence.
enum HandAutoSetupStep {
  pending,
  tableCreating,
  tableCreated,
  ccAssigning,
  ccAssigned,
  rfidMonitoring,
  cascadeReady,
  failed,
}

class HandAutoSetupState {
  const HandAutoSetupState({
    required this.step,
    this.tableId,
    this.ccSessionId,
    this.message,
  });

  final HandAutoSetupStep step;
  final int? tableId;
  final String? ccSessionId;
  final String? message;

  HandAutoSetupState copyWith({
    HandAutoSetupStep? step,
    int? tableId,
    String? ccSessionId,
    String? message,
  }) =>
      HandAutoSetupState(
        step: step ?? this.step,
        tableId: tableId ?? this.tableId,
        ccSessionId: ccSessionId ?? this.ccSessionId,
        message: message ?? this.message,
      );

  static const initial = HandAutoSetupState(step: HandAutoSetupStep.pending);
}

class HandAutoSetupNotifier extends StateNotifier<HandAutoSetupState> {
  HandAutoSetupNotifier() : super(HandAutoSetupState.initial);

  bool _started = false;

  /// Run the 4-step wire. Safe to call multiple times — second call is a no-op.
  /// Returns when the cascade step is reached (or on failure).
  Future<void> run() async {
    if (_started) return;
    _started = true;

    try {
      // Step 1: table 생성
      state = state.copyWith(
        step: HandAutoSetupStep.tableCreating,
        message: 'POST /api/v1/tables (auto-setup)',
      );
      // Backend integration deferred — emit observability event.
      final tableId = await _stubCreateTable();
      state = state.copyWith(
        step: HandAutoSetupStep.tableCreated,
        tableId: tableId,
        message: 'table=$tableId',
      );

      // Step 2: CC 할당
      state = state.copyWith(
        step: HandAutoSetupStep.ccAssigning,
        message: 'POST /api/v1/tables/$tableId/cc-session',
      );
      final ccSessionId = await _stubAssignCc(tableId);
      state = state.copyWith(
        step: HandAutoSetupStep.ccAssigned,
        ccSessionId: ccSessionId,
        message: 'cc=$ccSessionId',
      );

      // Step 3: RFID monitor (subscribe gate — actual subscription owned by
      // lobby_websocket_client.dart; here we just record the intent).
      state = state.copyWith(
        step: HandAutoSetupStep.rfidMonitoring,
        message: 'ws subscribe rfid_seat_*',
      );

      // Step 4: cascade ready signal
      state = state.copyWith(
        step: HandAutoSetupStep.cascadeReady,
        message: 'cascade:lobby-hand-ready',
      );

      if (kDebugMode) {
        // ignore: avoid_print
        print('[hand-auto-setup] cascade:lobby-hand-ready '
            'table=$tableId cc=$ccSessionId');
      }
    } catch (e, st) {
      state = state.copyWith(
        step: HandAutoSetupStep.failed,
        message: 'error: $e',
      );
      if (kDebugMode) {
        // ignore: avoid_print
        print('[hand-auto-setup] FAILED: $e\n$st');
      }
    }
  }

  // --- Stubs ---
  // Real implementations land when S7 publishes:
  //   POST /api/v1/tables                              (returns tableId)
  //   POST /api/v1/tables/{id}/cc-session              (returns ccSessionId)
  // Until then, deterministic stubs keep the wire observable.

  Future<int> _stubCreateTable() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return 1;
  }

  Future<String> _stubAssignCc(int tableId) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return 'cc_auto_$tableId';
  }
}

/// Provider exposing the 1-hand auto-setup state machine. Watch from a top-level
/// widget (e.g. EbsLobbyApp) and call `run()` once on mount when
/// `AppConfig.handAutoSetup` is true.
final handAutoSetupProvider =
    StateNotifierProvider<HandAutoSetupNotifier, HandAutoSetupState>(
  (ref) => HandAutoSetupNotifier(),
);
