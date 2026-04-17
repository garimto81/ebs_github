// Navigation / selection state providers — simplified for single-page dashboard.
//
// Series and Event selection drive the dashboard sections.
// Flight is auto-derived from the selected event (active flight).

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Selection state (simple StateProviders)
// ---------------------------------------------------------------------------

final currentSeriesIdProvider = StateProvider<int?>((ref) => null);
final currentSeriesNameProvider = StateProvider<String?>((ref) => null);

final currentEventIdProvider = StateProvider<int?>((ref) => null);
final currentEventNameProvider = StateProvider<String?>((ref) => null);

// Flight ID is auto-set by the dashboard when an event's active flight resolves.
// Kept as StateProvider for ws_dispatch.dart compatibility.
final currentFlightIdProvider = StateProvider<int?>((ref) => null);

final currentTableIdProvider = StateProvider<int?>((ref) => null);
final currentTableNameProvider = StateProvider<String?>((ref) => null);

// ---------------------------------------------------------------------------
// Selection helpers
// ---------------------------------------------------------------------------

/// Select a series — resets event, flight, and table.
void selectSeries(WidgetRef ref, int? id, {String? name}) {
  ref.read(currentSeriesIdProvider.notifier).state = id;
  ref.read(currentSeriesNameProvider.notifier).state = name;
  ref.read(currentEventIdProvider.notifier).state = null;
  ref.read(currentEventNameProvider.notifier).state = null;
  ref.read(currentFlightIdProvider.notifier).state = null;
  ref.read(currentTableIdProvider.notifier).state = null;
  ref.read(currentTableNameProvider.notifier).state = null;
}

/// Select an event — resets flight and table.
void selectEvent(WidgetRef ref, int? id, {String? name}) {
  ref.read(currentEventIdProvider.notifier).state = id;
  ref.read(currentEventNameProvider.notifier).state = name;
  ref.read(currentFlightIdProvider.notifier).state = null;
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

/// Current breadcrumb depth (0 = nothing, 3 = table selected).
final breadcrumbDepthProvider = Provider<int>((ref) {
  if (ref.watch(currentTableIdProvider) != null) return 3;
  if (ref.watch(currentEventIdProvider) != null) return 2;
  if (ref.watch(currentSeriesIdProvider) != null) return 1;
  return 0;
});
