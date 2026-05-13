/// ChipCountReconcile — Engine ↔ WSOP LIVE chip count drift detector + applier.
///
/// Receives WSOP LIVE webhook truth (via BO in-process notification —
/// payload schema = `chip_count_synced` WebSocket event §4.2.11) and:
///   1. Compares each seat's webhook chip_count to Engine's current value.
///   2. Classifies drift level per threshold (see [_classifyDrift]).
///   3. Emits a [DriftEvent] for every seat whose drift exceeds the silent
///      reconcile floor (5% of engine_value OR 1000 abs, whichever is larger).
///   4. Applies WSOP LIVE truth to the seat regardless of drift level
///      (WSOP LIVE is the authority during break — Chip_Count_State.md D2).
///   5. Captures Hand FSM phase at moment of reconcile so operations can
///      audit races (webhook arrived during an active hand instead of break).
///
/// Pure: no `dart:io`, no Flutter, no global state — passes a [GameState]
/// in and gets a (newState, drifts) pair out. The Engine's wrapper hook
/// (in `engine.dart`) is responsible for persisting drifts (log file / BO
/// audit ingestion).
///
/// Spec: docs/2. Development/2.5 Shared/Chip_Count_State.md §2-3
///       docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md §4.2.11
library;

import '../core/state/game_state.dart';
import '../core/state/seat.dart';
import '../models/drift_event.dart';

/// One seat slice of a webhook payload — what reconcile needs per seat.
class ChipCountSeatTruth {
  /// Seat number as supplied by webhook (1-indexed per WSOP LIVE convention;
  /// the reconciler maps it to [Seat.index] using [seatIndex] below).
  final int seatNumber;

  /// 0-indexed Engine seat index. Caller computes this (seatNumber - 1, or
  /// custom mapping if WSOP LIVE seat numbering differs from EBS).
  final int seatIndex;

  /// Player id from webhook (nullable when seat is empty).
  final int? playerId;

  /// WSOP LIVE truth for this seat (post-break dealer count).
  final int chipCount;

  const ChipCountSeatTruth({
    required this.seatNumber,
    required this.seatIndex,
    required this.playerId,
    required this.chipCount,
  });
}

/// The full webhook envelope, as broadcast on `chip_count_synced`.
/// Caller (engine.dart hook) parses the WS payload into this struct.
class ChipCountSyncedPayload {
  final String snapshotId;
  final int tableId;
  final int breakId;
  final DateTime recordedAt;
  final List<ChipCountSeatTruth> seats;

  const ChipCountSyncedPayload({
    required this.snapshotId,
    required this.tableId,
    required this.breakId,
    required this.recordedAt,
    required this.seats,
  });
}

/// Outcome of one reconcile pass.
class ChipCountReconcileResult {
  /// New [GameState] with WSOP LIVE truth applied to seat.stack.
  final GameState newState;

  /// Drift records (MINOR/MAJOR/CRITICAL only; silent reconciles omitted).
  /// Caller persists these (Engine log + BO ingestion).
  final List<DriftEvent> drifts;

  /// True when the reconcile ran during an active street — operations may
  /// want to review the timing (webhook should arrive during the break).
  final bool ranDuringActiveHand;

  const ChipCountReconcileResult({
    required this.newState,
    required this.drifts,
    required this.ranDuringActiveHand,
  });
}

/// Pure reconciler.
///
/// Usage:
/// ```dart
/// final result = ChipCountReconcile.reconcile(
///   state: currentEngineState,
///   payload: webhookPayload,
///   now: DateTime.now(),
/// );
/// for (final d in result.drifts) {
///   logger.warn(d.toJson()); // BO ingestion
/// }
/// engineStateStore[tableId] = result.newState;
/// ```
class ChipCountReconcile {
  /// Streets where the hand FSM is considered "active" (not in break).
  /// Reconcile during these phases is a race condition — webhook is still
  /// applied (D2: WSOP LIVE = truth) but [DriftEvent.auditedDuringActiveHand]
  /// is set so operations can review.
  static const _activeStreets = <Street>{
    Street.setupHand,
    Street.preflop,
    Street.flop,
    Street.turn,
    Street.river,
    Street.showdown,
    Street.runItMultiple,
  };

  /// Silent reconcile floor: drift ≤ max(5% × engine_value, 1000) → no event.
  ///
  /// Note: spec §3.1 uses `max(5% × engine_value, 500)` for NORMAL level.
  /// Mission directive in issue #438 sets the engine-side detection floor at
  /// abs > 1000 OR ratio > 5%. We honor the mission (stricter than spec
  /// floor): below the floor = silent, at-or-above = recorded.
  static int _silentFloor(int engineValue) {
    final pct = (engineValue.abs() * 5) ~/ 100;
    return pct > 1000 ? pct : 1000;
  }

  /// Classify drift level.
  ///
  /// Threshold table (per mission + spec §3.1):
  ///   - NORMAL (silent): drift ≤ silentFloor (≤ 1000 abs AND ≤ 5% ratio)
  ///   - MINOR:   silentFloor < drift ≤ 1000  (when engine_value > 20000
  ///              so 5% × engine_value > 1000, the silent floor is the ratio).
  ///   - MAJOR:   drift > 1000  AND drift ≤ 10% × engine_value × 2 (= 20%)
  ///              OR drift > 1000 AND drift ≤ 10000
  ///   - CRITICAL: drift > 10000  OR  drift > 20% × engine_value
  ///
  /// Returns null for NORMAL (silent reconcile, no event).
  static DriftLevel? _classifyDrift(int engineValue, int driftAmount) {
    if (driftAmount <= _silentFloor(engineValue)) return null;

    // Critical thresholds (spec §3.1: > 5% × 2 = 10%, OR > 10000)
    final criticalAbs = 10000;
    final criticalRatioCap =
        engineValue.abs() == 0 ? 0 : (engineValue.abs() * 10) ~/ 100;

    if (driftAmount > criticalAbs ||
        (criticalRatioCap > 0 && driftAmount > criticalRatioCap)) {
      return DriftLevel.critical;
    }

    // Major: drift > 1000 AND not critical.
    if (driftAmount > 1000) return DriftLevel.major;

    // Below 1000 but above silentFloor → MINOR.
    // (Only reachable when engine_value > 20000 so 5% > 1000, then silentFloor
    // = 5% and an event in (5%, 1000] is possible. For engine_value ≤ 20000,
    // silentFloor = 1000 and this branch is skipped.)
    return DriftLevel.minor;
  }

  /// Run reconcile pass.
  ///
  /// [now] is injectable for deterministic tests.
  static ChipCountReconcileResult reconcile({
    required GameState state,
    required ChipCountSyncedPayload payload,
    DateTime? now,
  }) {
    final detectedAt = now ?? DateTime.now();
    final ranDuringActiveHand = _activeStreets.contains(state.street);
    final drifts = <DriftEvent>[];

    // copyWith without overriding seats clones the list reference. We need
    // per-seat mutation to be deterministic, so build a new state via copy().
    final newSeats = state.seats.map((s) => s.copy()).toList();
    final newState = state.copyWith(seats: newSeats);

    for (final seatTruth in payload.seats) {
      if (seatTruth.seatIndex < 0 ||
          seatTruth.seatIndex >= newSeats.length) {
        // Out-of-range — skip silently. Caller is responsible for valid
        // mappings (the WSOP LIVE side and EBS side agree on seat layout
        // per Table_Setup spec).
        continue;
      }

      final seat = newSeats[seatTruth.seatIndex];
      final engineValue = seat.stack;
      final webhookTruth = seatTruth.chipCount;
      final diff = (webhookTruth - engineValue).abs();
      final level = _classifyDrift(engineValue, diff);

      // Apply WSOP LIVE truth — authority during break (D2).
      seat.stack = webhookTruth;

      if (level != null) {
        drifts.add(DriftEvent(
          snapshotId: payload.snapshotId,
          tableId: payload.tableId,
          seatNumber: seatTruth.seatNumber,
          playerId: seatTruth.playerId,
          engineValue: engineValue,
          webhookTruth: webhookTruth,
          driftAmount: diff,
          driftLevel: level,
          breakId: payload.breakId,
          recordedAt: payload.recordedAt,
          detectedAt: detectedAt,
          fsmPhaseAtDetection: state.street.name,
          auditedDuringActiveHand: ranDuringActiveHand,
        ));
      }
    }

    return ChipCountReconcileResult(
      newState: newState,
      drifts: drifts,
      ranDuringActiveHand: ranDuringActiveHand,
    );
  }
}
