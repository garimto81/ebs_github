// Idempotency-Key header generator for CCR-019.
//
// Every mutation HTTP request from CC must carry a unique UUID4 header
// `Idempotency-Key` per API-05 edit history 2026-04-10 (CCR-003). This
// prevents double-application of actions on network retry, operator
// double-click, or client crash recovery (ref: WSOP Chip Master.md 2-phase
// confirmation and Waiting API.md seat draw retries).

import 'package:uuid/uuid.dart';

class UuidIdempotency {
  UuidIdempotency._();

  static const _uuid = Uuid();

  /// Generate a fresh UUID4 for a single mutation request.
  static String generate() => _uuid.v4();

  /// HTTP header name (case-insensitive).
  static const headerName = 'Idempotency-Key';
}
