// 1 hand auto-setup wire — Cycle 2 (Issue #239) + Cycle 6 multi-hand (Issue #312).
//
// Cycle 2: single hand wire (table → CC → RFID monitor → cascade).
// Cycle 6: Hand 2 stage 추가 — S8 #301 ManualNextHand contract 소비.
//
//   1) table 생성   : POST /api/v1/tables (or stub)
//   2) CC 할당     : POST /api/v1/tables/{id}/cc-session (or stub)
//   3) RFID monitor: subscribe `/ws/lobby` for `rfid_seat_*` events
//   4) cascade     : log `cascade:lobby-hand-ready` (S2 → broker @ 7383)
//   5) hand1 complete: pot accumulated, winner determined (stub)
//   6) next hand   : POST /api/session/{id}/next-hand → dealer rotation
//   7) hand2 dealt : handNumber=2, dealer rotated (1 seat clockwise)
//   8) handHistory tracked locally (engine #301 §6 — not persisted server-side)
//
// Idempotent: multiple invocations during HMR are no-ops.
//
// Test hook: `--dart-define=HAND_AUTO_SETUP=true` enables this in any build.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step state for the multi-hand auto-setup sequence.
enum HandAutoSetupStep {
  pending,
  tableCreating,
  tableCreated,
  ccAssigning,
  ccAssigned,
  rfidMonitoring,
  cascadeReady,
  hand1Complete,
  nextHandRotating,
  hand2Dealt,
  failed,
}

/// Single completed-hand record. Engine (#301 §6) intentionally does NOT
/// persist handHistory[]; events log is SSOT. Lobby keeps a local visual
/// summary for the operator (last N hands).
class HandHistoryEntry {
  const HandHistoryEntry({
    required this.handNumber,
    required this.winnerSeat,
    required this.winnerName,
    required this.pot,
    required this.dealerSeat,
  });

  final int handNumber;
  final int winnerSeat;
  final String winnerName;
  final int pot;
  final int dealerSeat;
}

class HandAutoSetupState {
  const HandAutoSetupState({
    required this.step,
    this.tableId,
    this.ccSessionId,
    this.sessionId,
    this.handNumber = 1,
    this.dealerSeat = 1,
    this.maxSeats = 6,
    this.currentPot = 0,
    this.message,
    this.handHistory = const [],
  });

  final HandAutoSetupStep step;
  final int? tableId;
  final String? ccSessionId;
  final String? sessionId;
  final int handNumber;
  final int dealerSeat;
  final int maxSeats;
  final int currentPot;
  final String? message;
  final List<HandHistoryEntry> handHistory;

  HandAutoSetupState copyWith({
    HandAutoSetupStep? step,
    int? tableId,
    String? ccSessionId,
    String? sessionId,
    int? handNumber,
    int? dealerSeat,
    int? maxSeats,
    int? currentPot,
    String? message,
    List<HandHistoryEntry>? handHistory,
  }) =>
      HandAutoSetupState(
        step: step ?? this.step,
        tableId: tableId ?? this.tableId,
        ccSessionId: ccSessionId ?? this.ccSessionId,
        sessionId: sessionId ?? this.sessionId,
        handNumber: handNumber ?? this.handNumber,
        dealerSeat: dealerSeat ?? this.dealerSeat,
        maxSeats: maxSeats ?? this.maxSeats,
        currentPot: currentPot ?? this.currentPot,
        message: message ?? this.message,
        handHistory: handHistory ?? this.handHistory,
      );

  static const initial = HandAutoSetupState(step: HandAutoSetupStep.pending);
}

class HandAutoSetupNotifier extends StateNotifier<HandAutoSetupState> {
  HandAutoSetupNotifier() : super(HandAutoSetupState.initial);

  bool _started = false;

  /// Run the multi-hand wire. Safe to call multiple times — second call is
  /// a no-op. Returns when Hand 2 is dealt (or on failure).
  Future<void> run() async {
    if (_started) return;
    _started = true;

    try {
      // Step 1: table 생성
      state = state.copyWith(
        step: HandAutoSetupStep.tableCreating,
        message: 'POST /api/v1/tables (auto-setup)',
      );
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
        sessionId: 'sess_$tableId',
        message: 'cc=$ccSessionId',
      );

      // Step 3: RFID monitor
      state = state.copyWith(
        step: HandAutoSetupStep.rfidMonitoring,
        message: 'ws subscribe rfid_seat_*',
      );
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Step 4: cascade ready (Hand 1 dealt)
      state = state.copyWith(
        step: HandAutoSetupStep.cascadeReady,
        currentPot: 0,
        message: 'cascade:lobby-hand-ready (hand 1)',
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));

      if (kDebugMode) {
        // ignore: avoid_print
        print('[hand-auto-setup] cascade:lobby-hand-ready '
            'table=$tableId cc=$ccSessionId hand=1 dealer=${state.dealerSeat}');
      }

      // Step 5: hand 1 complete — pot built up, winner determined.
      // Stub deterministic: winner = dealer seat, pot = 240 (40 ante × 6).
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final hand1Winner = state.dealerSeat;
      const hand1Pot = 240;
      final hand1Entry = HandHistoryEntry(
        handNumber: 1,
        winnerSeat: hand1Winner,
        winnerName: 'Player$hand1Winner',
        pot: hand1Pot,
        dealerSeat: state.dealerSeat,
      );
      state = state.copyWith(
        step: HandAutoSetupStep.hand1Complete,
        currentPot: hand1Pot,
        handHistory: [...state.handHistory, hand1Entry],
        message: 'hand 1 done — seat $hand1Winner wins $hand1Pot',
      );

      // Step 6: ManualNextHand → dealer rotation.
      // Real path: POST /api/session/$sessionId/next-hand (Engine #301).
      // Stub: rotate dealer (n → n+1 mod maxSeats), reset pot, handNumber++.
      state = state.copyWith(
        step: HandAutoSetupStep.nextHandRotating,
        message:
            'POST /api/session/${state.sessionId}/next-hand (dealer rotate)',
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final newDealer = (state.dealerSeat % state.maxSeats) + 1;

      // Step 7: hand 2 dealt.
      state = state.copyWith(
        step: HandAutoSetupStep.hand2Dealt,
        handNumber: 2,
        dealerSeat: newDealer,
        currentPot: 0,
        message: 'hand 2 dealt — dealer rotated 1→$newDealer',
      );

      if (kDebugMode) {
        // ignore: avoid_print
        print('[hand-auto-setup] hand 2 dealt — '
            'handNumber=2 dealer=$newDealer history=${state.handHistory.length}');
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
  //   POST /api/session/{id}/next-hand                 (Engine #301 — landed)
  // Until S7 endpoints land, deterministic stubs keep the wire observable
  // and let the multi-hand UI render against known shape.

  Future<int> _stubCreateTable() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return 1;
  }

  Future<String> _stubAssignCc(int tableId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return 'cc_auto_$tableId';
  }
}

/// Provider exposing the multi-hand auto-setup state machine. Watch from a
/// top-level widget (e.g. EbsLobbyApp) and call `run()` once on mount when
/// `AppConfig.handAutoSetup` is true.
final handAutoSetupProvider =
    StateNotifierProvider<HandAutoSetupNotifier, HandAutoSetupState>(
  (ref) => HandAutoSetupNotifier(),
);
