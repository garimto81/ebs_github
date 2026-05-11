// Flight status integer enum — matches integration-tests/scenarios/60-event-flight-status-enum.http
// Backend (S7) emits integer values (0~6, 3 skipped). Frontend uses this enum to display
// status labels + drive Lobby UI affordances (is_registerable / is_pause / is_restricted).
//
// CCR-017 §1 EventFlightStatus 공유 (S7 ↔ S2 contract).

import 'package:json_annotation/json_annotation.dart';

/// Flight lifecycle status (integer enum, 3 is intentionally skipped).
///
/// Transitions (S7 owns the state machine):
///   draft(0) → announce(1) → lateReg(2) → running(4) → onBreak(5) → done(6)
///
/// Value 3 is reserved/skipped for historical reasons (see backend SSOT).
/// Any received value of 3 is invalid and should be rejected (HTTP 422).
@JsonEnum(valueField: 'value')
enum FlightStatus {
  draft(0, 'Draft'),
  announce(1, 'Announce'),
  lateReg(2, 'Late Reg'),
  // 3 skipped — invalid value
  running(4, 'Running'),
  onBreak(5, 'On Break'),
  done(6, 'Done');

  const FlightStatus(this.value, this.label);

  final int value;
  final String label;

  /// Lookup by integer value. Returns null for unknown/invalid values (e.g. 3).
  static FlightStatus? fromValue(int? value) {
    if (value == null) return null;
    for (final s in FlightStatus.values) {
      if (s.value == value) return s;
    }
    return null;
  }

  /// Whether new players can still register for this flight.
  /// True for: announce, lateReg.
  bool get isRegisterable => this == FlightStatus.announce || this == FlightStatus.lateReg;

  /// Whether the flight clock is currently paused (break or done).
  bool get isPause => this == FlightStatus.onBreak || this == FlightStatus.done;

  /// Restricted = announced but already a Day 2+ flight (day_index >= 1).
  /// Caller provides day_index; this is a pure helper.
  bool isRestricted({required int dayIndex}) =>
      this == FlightStatus.announce && dayIndex >= 1;
}
