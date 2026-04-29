// EBS Lobby — Flights screen (KPI strip + flights table).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../foundation/theme/ebs_typography.dart';
import '../../../foundation/widgets/empty_state.dart';
import '../../../foundation/widgets/error_banner.dart';
import '../../../foundation/widgets/loading_state.dart';
import '../../../foundation/widgets/lobby_breadcrumb.dart';
import '../../../models/models.dart';
import '../providers/event_provider.dart';
import '../providers/flight_provider.dart';
import '../providers/nav_provider.dart';
import '../widgets/lobby_kpi_strip.dart';
import '../widgets/lobby_status_badge.dart';

class LobbyFlightsScreen extends ConsumerStatefulWidget {
  const LobbyFlightsScreen({super.key, required this.eventId});
  final int eventId;

  @override
  ConsumerState<LobbyFlightsScreen> createState() =>
      _LobbyFlightsScreenState();
}

class _LobbyFlightsScreenState extends ConsumerState<LobbyFlightsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(flightListProvider(widget.eventId).notifier).fetch();
      // Resolve event name for breadcrumb.
      final seriesId = ref.read(currentSeriesIdProvider);
      if (seriesId != null) {
        final events =
            ref.read(eventListProvider(seriesId)).valueOrNull ?? [];
        final ev = events.where((e) => e.eventId == widget.eventId).firstOrNull;
        if (ev != null) {
          selectEvent(ref, ev.eventId, name: ev.eventName);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncFlights = ref.watch(flightListProvider(widget.eventId));
    final seriesName = ref.watch(currentSeriesNameProvider) ?? 'Series';
    final eventName =
        ref.watch(currentEventNameProvider) ?? 'Event #${widget.eventId}';

    return Column(
      children: [
        LobbyBreadcrumb(crumbs: [
          LobbyBreadcrumbCrumb(
            label: 'Home',
            onTap: () => context.go('/lobby/series'),
          ),
          LobbyBreadcrumbCrumb(
            label: seriesName,
            onTap: () => context.go('/lobby/series'),
          ),
          LobbyBreadcrumbCrumb(
            label: eventName,
            onTap: () {
              final sid = ref.read(currentSeriesIdProvider);
              if (sid != null) context.go('/lobby/events/$sid');
            },
          ),
          const LobbyBreadcrumbCrumb(label: 'Flights'),
        ]),
        Expanded(
          child: asyncFlights.when(
            loading: () => const LoadingState(),
            error: (err, _) => ErrorBanner(
              message: err.toString(),
              onRetry: () => ref
                  .read(flightListProvider(widget.eventId).notifier)
                  .fetch(),
            ),
            data: (flights) {
              if (flights.isEmpty) {
                return const EmptyState(
                  message: 'No flights for this event',
                  icon: Icons.flight_takeoff_outlined,
                );
              }
              return Column(
                children: [
                  LobbyKpiStrip(cards: _kpis(flights)),
                  Expanded(
                    child: _FlightsTable(
                      flights: flights,
                      onOpen: _onOpen,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  List<KpiCard> _kpis(List<EventFlight> flights) {
    final entries =
        flights.fold<int>(0, (s, f) => s + f.entries);
    final surviving =
        flights.fold<int>(0, (s, f) => s + f.playersLeft);
    final running =
        flights.where((f) => f.status == 'running').length;
    return [
      KpiCard(label: 'FLIGHTS', value: '${flights.length}'),
      KpiCard(label: 'TOTAL ENTRIES', value: _fmt(entries)),
      KpiCard(
        label: 'SURVIVING',
        value: _fmt(surviving),
        tone: surviving > 0 ? KpiTone.live : KpiTone.neutral,
      ),
      KpiCard(
        label: 'RUNNING',
        value: '$running',
        tone: running > 0 ? KpiTone.live : KpiTone.neutral,
      ),
      const KpiCard(label: 'PRIZE POOL', value: '—', sub: 'pending'),
    ];
  }

  String _fmt(int v) => v.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  void _onOpen(EventFlight f) {
    ref.read(currentFlightIdProvider.notifier).state = f.eventFlightId;
    context.go('/lobby/flight/${f.eventFlightId}/tables');
  }
}

class _FlightsTable extends StatelessWidget {
  const _FlightsTable({required this.flights, required this.onOpen});
  final List<EventFlight> flights;
  final ValueChanged<EventFlight> onOpen;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 900),
        child: SingleChildScrollView(
          child: DataTable(
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text('START TIME')),
              DataColumn(label: Text('FLIGHT')),
              DataColumn(label: Text('ENTRIES'), numeric: true),
              DataColumn(label: Text('SURVIVORS'), numeric: true),
              DataColumn(label: Text('TABLES'), numeric: true),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('')),
            ],
            rows: [
              for (final f in flights)
                DataRow(
                  selected: f.status == 'running',
                  onSelectChanged: (_) => onOpen(f),
                  cells: [
                    DataCell(Text(_short(f.startTime ?? ''),
                        style: EbsTypography.tableNumeric)),
                    DataCell(Text(f.displayName,
                        style: EbsTypography.tableCell.copyWith(
                            fontWeight: FontWeight.w600))),
                    DataCell(Text('${f.entries}',
                        style: EbsTypography.tableNumeric)),
                    DataCell(Text('${f.playersLeft}',
                        style: EbsTypography.tableNumeric)),
                    DataCell(Text('${f.tableCount}',
                        style: EbsTypography.tableNumeric)),
                    DataCell(LobbyStatusBadge(status: f.status)),
                    DataCell(TextButton(
                      onPressed: () => onOpen(f),
                      child: const Text('Open ›'),
                    )),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _short(String iso) =>
      iso.length >= 16 ? iso.substring(5, 16).replaceAll('T', ' ') : iso;
}
