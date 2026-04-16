import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../foundation/widgets/empty_state.dart';
import '../../../foundation/widgets/error_banner.dart';
import '../../../foundation/widgets/loading_state.dart';
import '../../../models/models.dart';
import '../providers/flight_provider.dart';
import '../providers/nav_provider.dart';

/// Flight list screen (standalone deep-link view).
///
/// Typically flights are shown as accordion sub-rows inside EventListScreen.
/// This standalone view is used when the user deep-links to
/// `/events/:eventId/flights`.
///
/// Ported from FlightListPage.vue.
class FlightListScreen extends ConsumerStatefulWidget {
  final int eventId;
  const FlightListScreen({super.key, required this.eventId});

  @override
  ConsumerState<FlightListScreen> createState() => _FlightListScreenState();
}

class _FlightListScreenState extends ConsumerState<FlightListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(flightListProvider(widget.eventId).notifier).fetch(),
    );
  }

  void _reload() {
    ref.read(flightListProvider(widget.eventId).notifier).fetch();
  }

  void _handleOpen(EventFlight flight) {
    if (!['running', 'registering'].contains(flight.status)) return;
    selectFlight(ref, flight.eventFlightId, name: flight.displayName);
    context.go('/events/${widget.eventId}/tables?day=${flight.dayIndex}');
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'running':
        return Colors.green;
      case 'registering':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncFlights = ref.watch(flightListProvider(widget.eventId));

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Flights',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      'Event #${widget.eventId}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () {
                    // TODO: new flight creation
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Flight'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Content
            Expanded(
              child: asyncFlights.when(
                loading: () => const LoadingState(),
                error: (err, _) =>
                    ErrorBanner(message: err.toString(), onRetry: _reload),
                data: (flights) {
                  if (flights.isEmpty) {
                    return const EmptyState(
                      message: 'No flights found',
                      icon: Icons.flight_takeoff,
                    );
                  }
                  return _buildFlightTable(flights);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlightTable(List<EventFlight> flights) {
    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: 20,
        showCheckboxColumn: false,
        columns: const [
          DataColumn(label: Text('Flight')),
          DataColumn(label: Text('Start')),
          DataColumn(label: Text('Entries'), numeric: true),
          DataColumn(label: Text('Players Left'), numeric: true),
          DataColumn(label: Text('Tables'), numeric: true),
          DataColumn(label: Text('Level'), numeric: true),
          DataColumn(label: Text('Status')),
        ],
        rows: [
          for (final f in flights)
            DataRow(
              onSelectChanged: (_) => _handleOpen(f),
              cells: [
                DataCell(Text(f.displayName)),
                DataCell(Text(f.startTime ?? '\u2014')),
                DataCell(Text('${f.entries}')),
                DataCell(Text('${f.playersLeft}')),
                DataCell(Text('${f.tableCount}')),
                DataCell(Text('${f.playLevel}')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor(f.status),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      f.status,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
