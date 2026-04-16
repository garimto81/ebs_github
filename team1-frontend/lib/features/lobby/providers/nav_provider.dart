// Navigation / selection state providers — ported from navStore.ts.
//
// Cascading reset: when a parent level changes, all children reset to null.
// This is enforced by the select* helper functions which should be called
// instead of setting providers directly.

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Selection state (simple StateProviders)
// ---------------------------------------------------------------------------

final currentSeriesIdProvider = StateProvider<int?>((ref) => null);
final currentSeriesNameProvider = StateProvider<String?>((ref) => null);

final currentEventIdProvider = StateProvider<int?>((ref) => null);
final currentEventNameProvider = StateProvider<String?>((ref) => null);

final currentFlightIdProvider = StateProvider<int?>((ref) => null);
final currentFlightNameProvider = StateProvider<String?>((ref) => null);

final currentTableIdProvider = StateProvider<int?>((ref) => null);
final currentTableNameProvider = StateProvider<String?>((ref) => null);

// ---------------------------------------------------------------------------
// Cascading selection helpers
// ---------------------------------------------------------------------------

/// Select a series — resets event, flight, and table.
void selectSeries(WidgetRef ref, int? id, {String? name}) {
  ref.read(currentSeriesIdProvider.notifier).state = id;
  ref.read(currentSeriesNameProvider.notifier).state = name;
  ref.read(currentEventIdProvider.notifier).state = null;
  ref.read(currentEventNameProvider.notifier).state = null;
  ref.read(currentFlightIdProvider.notifier).state = null;
  ref.read(currentFlightNameProvider.notifier).state = null;
  ref.read(currentTableIdProvider.notifier).state = null;
  ref.read(currentTableNameProvider.notifier).state = null;
}

/// Select an event — resets flight and table.
void selectEvent(WidgetRef ref, int? id, {String? name}) {
  ref.read(currentEventIdProvider.notifier).state = id;
  ref.read(currentEventNameProvider.notifier).state = name;
  ref.read(currentFlightIdProvider.notifier).state = null;
  ref.read(currentFlightNameProvider.notifier).state = null;
  ref.read(currentTableIdProvider.notifier).state = null;
  ref.read(currentTableNameProvider.notifier).state = null;
}

/// Select a flight — resets table.
void selectFlight(WidgetRef ref, int? id, {String? name}) {
  ref.read(currentFlightIdProvider.notifier).state = id;
  ref.read(currentFlightNameProvider.notifier).state = name;
  ref.read(currentTableIdProvider.notifier).state = null;
  ref.read(currentTableNameProvider.notifier).state = null;
}

/// Select a table.
void selectTable(WidgetRef ref, int? id, {String? name}) {
  ref.read(currentTableIdProvider.notifier).state = id;
  ref.read(currentTableNameProvider.notifier).state = name;
}

/// Reset entire navigation breadcrumb.
void resetNav(WidgetRef ref) {
  selectSeries(ref, null);
}

// ---------------------------------------------------------------------------
// Breadcrumb derived state (convenience)
// ---------------------------------------------------------------------------

/// True when at least one level is selected.
final hasSelectionProvider = Provider<bool>((ref) {
  return ref.watch(currentSeriesIdProvider) != null;
});

/// Current breadcrumb depth (0 = nothing selected, 4 = table selected).
final breadcrumbDepthProvider = Provider<int>((ref) {
  if (ref.watch(currentTableIdProvider) != null) return 4;
  if (ref.watch(currentFlightIdProvider) != null) return 3;
  if (ref.watch(currentEventIdProvider) != null) return 2;
  if (ref.watch(currentSeriesIdProvider) != null) return 1;
  return 0;
});
