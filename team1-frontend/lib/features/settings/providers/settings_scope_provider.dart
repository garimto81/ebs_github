// SG-003 Settings Scope Resolution (4-level: Global/Series/Event/Table).
//
// WSOP LIVE pattern: lower scope overrides higher. A Table-level setting wins
// over Event, which wins over Series, which wins over Global defaults.
//
// Storage: BO `settings_kv` table (scope_level + scope_id + tab + key + JSONB value)
// API: GET/PUT /api/v1/settings?scope=<level>&scope_id=<uuid>&tab=<tab>
//
// team1 session TODO markers:
//   [TODO-T1-001] wire real BO API calls via Dio (currently Mock)
//   [TODO-T1-002] propagate scope changes from Lobby TableSelector
//   [TODO-T1-003] cache resolved effective values + invalidate on WS settings_changed event

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Scope hierarchy (lower index = higher priority — Table overrides Event overrides Series overrides Global).
enum SettingsScopeLevel {
  table(0),
  event(1),
  series(2),
  global(3);

  const SettingsScopeLevel(this.priority);
  final int priority;
}

/// Immutable snapshot of active scope (which Table/Event/Series user is viewing).
class ActiveScope {
  const ActiveScope({
    this.tableId,
    this.eventId,
    this.seriesId,
  });

  final String? tableId;
  final String? eventId;
  final String? seriesId;

  ActiveScope copyWith({
    String? tableId,
    String? eventId,
    String? seriesId,
  }) {
    return ActiveScope(
      tableId: tableId ?? this.tableId,
      eventId: eventId ?? this.eventId,
      seriesId: seriesId ?? this.seriesId,
    );
  }
}

/// Currently active scope — set by Lobby when user selects a Table/Event/Series.
final activeScopeProvider = StateProvider<ActiveScope>((_) => const ActiveScope());

/// Resolve effective setting value by traversing scope hierarchy.
///
/// Returns the first non-null value found, falling back to [defaultValue].
///
/// Example:
///   final effective = resolveSetting(
///     values: {
///       SettingsScopeLevel.table: null,
///       SettingsScopeLevel.event: 'fast',
///       SettingsScopeLevel.series: 'normal',
///       SettingsScopeLevel.global: 'normal',
///     },
///     defaultValue: 'normal',
///   ); // → 'fast' (event wins over series/global since table is null)
T resolveSetting<T>({
  required Map<SettingsScopeLevel, T?> values,
  required T defaultValue,
}) {
  // Ordered by priority (table → event → series → global).
  for (final level in SettingsScopeLevel.values) {
    final v = values[level];
    if (v != null) return v;
  }
  return defaultValue;
}

/// API call helper signature (team1 session implements via Dio).
typedef SettingsFetcher = Future<Map<String, dynamic>?> Function(
  SettingsScopeLevel level,
  String? scopeId,
  String tab,
);

/// Placeholder provider — team1 wires this to real BO API.
///
/// [TODO-T1-001]: replace with Dio-backed implementation.
final settingsFetcherProvider = Provider<SettingsFetcher>((ref) {
  return (level, scopeId, tab) async {
    // Stub: return empty map so resolveSetting falls back to defaults.
    return <String, dynamic>{};
  };
});
