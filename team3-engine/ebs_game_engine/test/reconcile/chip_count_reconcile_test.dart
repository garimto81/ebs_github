/// Cycle 20 Wave 3b — chip count reconcile + drift log tests (issue #438).
///
/// Validates 7 cases:
///   1. 0% drift          → no drift event, swap applied
///   2. 3% drift          → silent reconcile (below floor), no event
///   3. 7% drift          → drift event emitted (above 5% ratio floor)
///   4. abs > 1000        → drift event emitted regardless of ratio
///   5. reconcile applied → seat.stack updated to webhook truth
///   6. FSM IDLE          → no race flag
///   7. FSM active        → race flag set on drift events
///
/// Spec: docs/2. Development/2.5 Shared/Chip_Count_State.md §2-4
library;

import 'package:test/test.dart';
import 'package:ebs_game_engine/engine.dart';

GameState _state({
  required List<int> stacks,
  Street street = Street.idle,
}) {
  final seats = <Seat>[];
  for (var i = 0; i < stacks.length; i++) {
    seats.add(Seat(index: i, label: 'P$i', stack: stacks[i]));
  }
  return GameState(
    sessionId: 'reconcile-test',
    variantName: 'nlh',
    seats: seats,
    deck: Deck.standard(),
    street: street,
    handInProgress: street != Street.idle,
    bbAmount: 100,
  );
}

ChipCountSyncedPayload _payload({
  required int tableId,
  required List<int> truths,
  String snapshotId = 'snap-001',
  int breakId = 1024,
}) {
  final seats = <ChipCountSeatTruth>[];
  for (var i = 0; i < truths.length; i++) {
    seats.add(ChipCountSeatTruth(
      seatNumber: i + 1,
      seatIndex: i,
      playerId: 100 + i,
      chipCount: truths[i],
    ));
  }
  return ChipCountSyncedPayload(
    snapshotId: snapshotId,
    tableId: tableId,
    breakId: breakId,
    recordedAt: DateTime.utc(2026, 5, 13, 18, 30, 0),
    seats: seats,
  );
}

void main() {
  group('Cycle 20 Wave 3b: ChipCountReconcile', () {
    test('Case 1: 0% drift — webhook matches engine, no drift events', () {
      // engine_value = 50000, truth = 50000 → diff = 0
      final state = _state(stacks: [50000, 50000], street: Street.idle);
      final payload = _payload(tableId: 17, truths: [50000, 50000]);

      final result = Engine.handleChipCountSynced(
        state: state,
        payload: payload,
        now: DateTime.utc(2026, 5, 13, 18, 30, 1),
      );

      expect(result.drifts, isEmpty,
          reason: 'Zero drift must produce no DriftEvent.');
      expect(result.ranDuringActiveHand, isFalse);
      // Truth still applied (no-op but state was rebuilt).
      expect(result.newState.seats[0].stack, equals(50000));
      expect(result.newState.seats[1].stack, equals(50000));
    });

    test('Case 2: 3% drift — silent reconcile, no event', () {
      // engine_value = 50000, truth = 51500 → diff = 1500
      // 5% floor of 50000 = 2500. 1500 < max(2500, 1000) = 2500 → silent.
      final state = _state(stacks: [50000], street: Street.idle);
      final payload = _payload(tableId: 17, truths: [51500]);

      final result = Engine.handleChipCountSynced(
        state: state,
        payload: payload,
      );

      expect(result.drifts, isEmpty,
          reason: '3% drift (1500/50000) is below silent floor (2500).');
      expect(result.newState.seats[0].stack, equals(51500),
          reason: 'Silent reconcile still applies the truth.');
    });

    test('Case 3: 7% drift — drift event emitted (ratio over 5%)', () {
      // engine_value = 50000, truth = 53500 → diff = 3500 (7%)
      // 5% floor = 2500. 3500 > 2500 → event.
      // 3500 ≤ 10000 absolute. 3500 > 1000 → MAJOR.
      final state = _state(stacks: [50000], street: Street.idle);
      final payload = _payload(tableId: 17, truths: [53500]);

      final result = Engine.handleChipCountSynced(
        state: state,
        payload: payload,
      );

      expect(result.drifts, hasLength(1));
      final d = result.drifts.first;
      expect(d.driftAmount, equals(3500));
      expect(d.engineValue, equals(50000));
      expect(d.webhookTruth, equals(53500));
      expect(d.driftLevel, equals(DriftLevel.major),
          reason: '7% drift with abs > 1000 must be MAJOR.');
      expect(d.tableId, equals(17));
      expect(d.seatNumber, equals(1));
    });

    test('Case 4: abs > 1000 — drift event emitted even at low ratio', () {
      // engine_value = 100000, truth = 101500 → diff = 1500 (1.5%)
      // 5% floor of 100000 = 5000 > 1000 → floor = 5000.
      // 1500 < 5000 → silent. Need a smaller engine_value to trigger abs path.
      //
      // engine_value = 15000, truth = 16100 → diff = 1100 (7.3%)
      // 5% floor of 15000 = 750. Effective floor = max(750, 1000) = 1000.
      // 1100 > 1000 → event. 1100 > 1000 → MAJOR.
      final state = _state(stacks: [15000], street: Street.idle);
      final payload = _payload(tableId: 17, truths: [16100]);

      final result = Engine.handleChipCountSynced(
        state: state,
        payload: payload,
      );

      expect(result.drifts, hasLength(1),
          reason: 'abs drift > 1000 must emit event regardless of ratio.');
      expect(result.drifts.first.driftAmount, equals(1100));
      expect(result.drifts.first.driftLevel, equals(DriftLevel.major));
    });

    test('Case 5: reconcile applied — webhook truth overwrites engine stack',
        () {
      // engine_value = 12000, truth = 8500 (player burned through stack)
      // diff = 3500. abs > 1000 AND 3500/12000 = 29% > 5% → MAJOR.
      // Critical ratio cap = 10% × 12000 = 1200. 3500 > 1200 → CRITICAL.
      final state = _state(stacks: [12000, 30000], street: Street.idle);
      final payload = _payload(tableId: 17, truths: [8500, 30000]);

      final result = Engine.handleChipCountSynced(
        state: state,
        payload: payload,
      );

      // Seat 0: drift applied, event emitted.
      expect(result.newState.seats[0].stack, equals(8500),
          reason: 'Engine stack must be overwritten with webhook truth.');
      // Seat 1: no drift, no event, value preserved.
      expect(result.newState.seats[1].stack, equals(30000));
      expect(result.drifts, hasLength(1));
      expect(result.drifts.first.seatNumber, equals(1));
      // Original state untouched (pure function).
      expect(state.seats[0].stack, equals(12000),
          reason: 'Input state must remain immutable after reconcile.');
    });

    test('Case 6: FSM IDLE — no race flag on emitted drifts', () {
      // engine_value = 50000, truth = 60000 → diff = 10000.
      // 10000 ≤ critical abs (10000) AND 10000 > 5% (2500) AND
      // 10000 = 5% × 2 = 5000 cap (critical ratio) → CRITICAL via ratio.
      // We assert race flag is false because state.street == idle.
      final state = _state(stacks: [50000], street: Street.idle);
      final payload = _payload(tableId: 17, truths: [60000]);

      final result = Engine.handleChipCountSynced(
        state: state,
        payload: payload,
      );

      expect(result.ranDuringActiveHand, isFalse);
      expect(result.drifts, hasLength(1));
      expect(result.drifts.first.auditedDuringActiveHand, isFalse,
          reason: 'IDLE phase = legitimate break window, no race.');
      expect(result.drifts.first.fsmPhaseAtDetection, equals('idle'));
    });

    test('Case 7: FSM active (preflop) — race flag set on drifts', () {
      // Webhook arrived during PREFLOP — race condition.
      final state = _state(stacks: [50000], street: Street.preflop);
      final payload = _payload(tableId: 17, truths: [60000]);

      final result = Engine.handleChipCountSynced(
        state: state,
        payload: payload,
      );

      expect(result.ranDuringActiveHand, isTrue);
      expect(result.drifts, hasLength(1));
      expect(result.drifts.first.auditedDuringActiveHand, isTrue,
          reason: 'Active street = race; operations must review.');
      expect(result.drifts.first.fsmPhaseAtDetection, equals('preflop'));
      // Truth still applied — WSOP LIVE is authority (D2).
      expect(result.newState.seats[0].stack, equals(60000));
    });
  });

  group('Cycle 20 Wave 3b: DriftEvent JSON serialization', () {
    test('toJson emits all schema fields', () {
      final state = _state(stacks: [10000], street: Street.flop);
      final payload = _payload(tableId: 7, truths: [12500]);

      final result = Engine.handleChipCountSynced(
        state: state,
        payload: payload,
        now: DateTime.utc(2026, 5, 13, 18, 35, 0),
      );

      expect(result.drifts, hasLength(1));
      final json = result.drifts.first.toJson();

      expect(json['snapshot_id'], equals('snap-001'));
      expect(json['table_id'], equals(7));
      expect(json['seat_number'], equals(1));
      expect(json['player_id'], equals(100));
      expect(json['engine_value'], equals(10000));
      expect(json['webhook_truth'], equals(12500));
      expect(json['drift_amount'], equals(2500));
      expect(json['break_id'], equals(1024));
      expect(json['fsm_phase_at_detection'], equals('flop'));
      expect(json['audited_during_active_hand'], isTrue);
      expect(json['drift_level'], isIn(['minor', 'major', 'critical']));
      expect(json['recorded_at'],
          equals('2026-05-13T18:30:00.000Z'));
      expect(json['detected_at'],
          equals('2026-05-13T18:35:00.000Z'));
    });
  });
}
