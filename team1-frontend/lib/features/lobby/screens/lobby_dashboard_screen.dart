import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../foundation/widgets/empty_state.dart';
import '../../../foundation/widgets/error_banner.dart';
import '../../../foundation/widgets/loading_state.dart';
import '../../../models/models.dart';
import '../providers/event_provider.dart';
import '../providers/flight_provider.dart';
import '../providers/nav_provider.dart';
import '../providers/series_provider.dart';
import '../providers/table_provider.dart';
import '../widgets/seat_grid.dart';

/// Single-page Lobby dashboard with 3 sections:
///
/// 1. **Active Series Selector** -- banner (1 series) or dropdown (2+).
/// 2. **Live Events Table** -- event name, flight, tables count, players count.
/// 3. **Tables Detail** -- table rows with SeatGrid + Enter CC button.
class LobbyDashboardScreen extends ConsumerStatefulWidget {
  const LobbyDashboardScreen({super.key});

  @override
  ConsumerState<LobbyDashboardScreen> createState() =>
      _LobbyDashboardScreenState();
}

class _LobbyDashboardScreenState extends ConsumerState<LobbyDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(seriesListProvider.notifier).fetch();
    });
  }

  // -----------------------------------------------------------------------
  // Series selection
  // -----------------------------------------------------------------------

  void _onSeriesChanged(int seriesId, String seriesName) {
    selectSeries(ref, seriesId, name: seriesName);
    ref.read(eventListProvider(seriesId).notifier).fetch();
  }

  // -----------------------------------------------------------------------
  // Event selection -- auto-fetches tables for active flight
  // -----------------------------------------------------------------------

  void _onEventSelected(EbsEvent event) {
    selectEvent(ref, event.eventId, name: event.eventName);
    // Fetch flights, then tables for the first active flight.
    ref.read(flightListProvider(event.eventId).notifier).fetch();
  }

  /// Returns the active flight for the selected event (first running, then
  /// first registering, then first flight).
  EventFlight? _activeFlightForEvent(int eventId) {
    final flights =
        ref.watch(flightListProvider(eventId)).valueOrNull ?? [];
    if (flights.isEmpty) return null;
    return flights.cast<EventFlight?>().firstWhere(
              (f) => f!.status == 'running',
              orElse: () => null,
            ) ??
        flights.cast<EventFlight?>().firstWhere(
              (f) => f!.status == 'registering',
              orElse: () => null,
            ) ??
        flights.first;
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final asyncSeries = ref.watch(seriesListProvider);
    final selectedSeriesId = ref.watch(currentSeriesIdProvider);
    final selectedEventId = ref.watch(currentEventIdProvider);

    // Auto-select first series when data arrives and nothing selected yet.
    asyncSeries.whenData((list) {
      if (list.isNotEmpty && selectedSeriesId == null) {
        Future.microtask(
            () => _onSeriesChanged(list.first.seriesId, list.first.seriesName));
      }
    });

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Active Series Selector
            _buildSeriesSelector(asyncSeries, selectedSeriesId),
            const SizedBox(height: 16),
            // Section 2 + 3 side-by-side or stacked
            Expanded(
              child: selectedSeriesId == null
                  ? const Center(child: Text('Select a series to continue'))
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 2: Live Events
                        Expanded(
                          flex: 2,
                          child: _buildEventsSection(
                            selectedSeriesId,
                            selectedEventId,
                          ),
                        ),
                        const VerticalDivider(width: 24),
                        // Section 3: Tables Detail
                        Expanded(
                          flex: 3,
                          child: selectedEventId != null
                              ? _buildTablesSection(selectedEventId)
                              : const EmptyState(
                                  message:
                                      'Click an event row to view tables',
                                  icon: Icons.table_restaurant,
                                ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // Section 1 -- Series Selector
  // =========================================================================

  Widget _buildSeriesSelector(
    AsyncValue<List<Series>> asyncSeries,
    int? selectedSeriesId,
  ) {
    return asyncSeries.when(
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (err, _) => ErrorBanner(
        message: err.toString(),
        onRetry: () => ref.read(seriesListProvider.notifier).fetch(),
      ),
      data: (seriesList) {
        if (seriesList.isEmpty) {
          return const EmptyState(
            message: 'No series available',
            icon: Icons.emoji_events,
          );
        }

        // Single series -- show as banner
        if (seriesList.length == 1) {
          final s = seriesList.first;
          return _SeriesBanner(series: s);
        }

        // 2+ series -- dropdown
        return Row(
          children: [
            const Icon(Icons.emoji_events, size: 20),
            const SizedBox(width: 8),
            Text(
              'Series',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 320,
              child: DropdownButtonFormField<int>(
                value: selectedSeriesId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: [
                  for (final s in seriesList)
                    DropdownMenuItem(
                      value: s.seriesId,
                      child: Text(
                        '${s.seriesName} (${s.year})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (id) {
                  if (id == null) return;
                  final s = seriesList.firstWhere((s) => s.seriesId == id);
                  _onSeriesChanged(s.seriesId, s.seriesName);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // Section 2 -- Live Events Table
  // =========================================================================

  Widget _buildEventsSection(int seriesId, int? selectedEventId) {
    final asyncEvents = ref.watch(eventListProvider(seriesId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Events',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: asyncEvents.when(
            loading: () => const LoadingState(),
            error: (err, _) => ErrorBanner(
              message: err.toString(),
              onRetry: () =>
                  ref.read(eventListProvider(seriesId).notifier).fetch(),
            ),
            data: (events) {
              if (events.isEmpty) {
                return const EmptyState(
                  message: 'No events found',
                  icon: Icons.event,
                );
              }
              return _buildEventTable(events, selectedEventId);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventTable(List<EbsEvent> events, int? selectedEventId) {
    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: 16,
        headingRowHeight: 40,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 48,
        showCheckboxColumn: false,
        columns: const [
          DataColumn(label: Text('Event Name')),
          DataColumn(label: Text('Flight')),
          DataColumn(label: Text('Tables'), numeric: true),
          DataColumn(label: Text('Players'), numeric: true),
        ],
        rows: [
          for (final event in events)
            DataRow(
              selected: event.eventId == selectedEventId,
              onSelectChanged: (_) => _onEventSelected(event),
              cells: [
                DataCell(
                  Text(
                    event.eventName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: event.eventId == selectedEventId
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                DataCell(Text(_activeFlight(event))),
                DataCell(Text('${_tableCountForEvent(event)}')),
                DataCell(Text(
                    '${event.playersLeft}/${event.totalEntries}')),
              ],
            ),
        ],
      ),
    );
  }

  String _activeFlight(EbsEvent event) {
    final flights =
        ref.watch(flightListProvider(event.eventId)).valueOrNull ?? [];
    if (flights.isEmpty) return '\u2014';
    final active = flights.cast<EventFlight?>().firstWhere(
              (f) => f!.status == 'running',
              orElse: () => null,
            ) ??
        flights.first;
    return active.flightName;
  }

  int _tableCountForEvent(EbsEvent event) {
    final flights =
        ref.watch(flightListProvider(event.eventId)).valueOrNull ?? [];
    if (flights.isEmpty) return 0;
    return flights.fold<int>(0, (sum, f) => sum + f.tableCount);
  }

  // =========================================================================
  // Section 3 -- Tables Detail
  // =========================================================================

  Widget _buildTablesSection(int eventId) {
    final activeFlight = _activeFlightForEvent(eventId);

    if (activeFlight == null) {
      // Flights not loaded yet -- try fetching
      final asyncFlights = ref.watch(flightListProvider(eventId));
      return asyncFlights.when(
        loading: () => const LoadingState(),
        error: (err, _) => ErrorBanner(
          message: err.toString(),
          onRetry: () =>
              ref.read(flightListProvider(eventId).notifier).fetch(),
        ),
        data: (_) => const EmptyState(
          message: 'No flights for this event',
          icon: Icons.flight_takeoff,
        ),
      );
    }

    // Sync active flight ID to nav state for ws_dispatch compatibility.
    final flightId = activeFlight.flightId;
    final currentFlight = ref.watch(currentFlightIdProvider);
    if (currentFlight != flightId) {
      Future.microtask(
          () => ref.read(currentFlightIdProvider.notifier).state = flightId);
    }

    // Ensure tables are fetched for the active flight
    final asyncTables = ref.watch(tableListProvider(flightId));

    // Auto-fetch if still in initial loading state
    asyncTables.whenOrNull(
      loading: () {
        Future.microtask(
            () => ref.read(tableListProvider(flightId).notifier).fetch());
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header + summary
        _buildTablesSectionHeader(asyncTables, activeFlight),
        const SizedBox(height: 8),
        // Table rows
        Expanded(
          child: asyncTables.when(
            loading: () => const LoadingState(),
            error: (err, _) => ErrorBanner(
              message: err.toString(),
              onRetry: () =>
                  ref.read(tableListProvider(flightId).notifier).fetch(),
            ),
            data: (tables) {
              if (tables.isEmpty) {
                return const EmptyState(
                  message: 'No tables found',
                  icon: Icons.table_restaurant,
                );
              }
              return _buildTablesTable(tables);
            },
          ),
        ),
        const SizedBox(height: 4),
        const SeatGridLegend(),
      ],
    );
  }

  Widget _buildTablesSectionHeader(
    AsyncValue<List<EbsTable>> asyncTables,
    EventFlight flight,
  ) {
    final tables = asyncTables.valueOrNull ?? [];
    final totalSeats = tables.fold<int>(0, (s, t) => s + t.maxPlayers);
    final occupied =
        tables.fold<int>(0, (s, t) => s + (t.seatedCount ?? 0));
    final emptySeats = totalSeats - occupied;

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tables \u2014 ${flight.flightName}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Spacer(),
        _SummaryChip(label: 'Players', value: '$occupied/$totalSeats'),
        const SizedBox(width: 12),
        _SummaryChip(label: 'Tables', value: '${tables.length}'),
        const SizedBox(width: 12),
        _SummaryChip(label: 'Empty seats', value: '$emptySeats'),
      ],
    );
  }

  Widget _buildTablesTable(List<EbsTable> tables) {
    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: 16,
        showCheckboxColumn: false,
        columns: const [
          DataColumn(label: Text('Table #')),
          DataColumn(label: Text('Seats')),
          DataColumn(label: Text('Action')),
        ],
        rows: [
          for (final table in tables) _buildTableRow(table),
        ],
      ),
    );
  }

  DataRow _buildTableRow(EbsTable table) {
    final seats = _generateSeats(table);
    return DataRow(
      onSelectChanged: (_) => context.go('/tables/${table.tableId}'),
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (table.type == 'feature') ...[
                Icon(Icons.star, color: Colors.amber.shade600, size: 18),
                const SizedBox(width: 4),
              ],
              Text(
                table.name.isNotEmpty ? table.name : 'Table ${table.tableNo}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        DataCell(SeatGrid(seats: seats, maxSeats: table.maxPlayers)),
        DataCell(
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: () {
              // TODO: launch CC for this table
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Enter CC', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  List<SeatInfo> _generateSeats(EbsTable table) {
    final seated = table.seatedCount ?? 0;
    return List.generate(table.maxPlayers, (i) {
      final occupied = i < seated;
      return SeatInfo(
        seatIndex: i,
        status: occupied ? SeatCellStatus.occupied : SeatCellStatus.empty,
        playerId: occupied ? 1000 + i : null,
      );
    });
  }
}

// ===========================================================================
// Private helper widgets
// ===========================================================================

class _SeriesBanner extends StatelessWidget {
  final Series series;
  const _SeriesBanner({required this.series});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events,
              color: Theme.of(context).colorScheme.onPrimaryContainer),
          const SizedBox(width: 8),
          Text(
            series.seriesName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
          const SizedBox(width: 8),
          Text(
            '${series.year} \u00b7 ${series.currency}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
