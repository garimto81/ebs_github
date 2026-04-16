import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../foundation/widgets/empty_state.dart';
import '../../../foundation/widgets/error_banner.dart';
import '../../../foundation/widgets/loading_state.dart';
import '../../../models/models.dart';
import '../providers/flight_provider.dart';
import '../providers/table_provider.dart';
import '../widgets/day_tabs.dart';
import '../widgets/seat_grid.dart';
import '../widgets/table_form_dialog.dart';

/// Table list screen with Day tabs, seat grid rows, rebalance button.
///
/// Ported from TableListPage.vue.
class TableListScreen extends ConsumerStatefulWidget {
  final int eventId;
  final int? initialDay;

  const TableListScreen({
    super.key,
    required this.eventId,
    this.initialDay,
  });

  @override
  ConsumerState<TableListScreen> createState() => _TableListScreenState();
}

class _TableListScreenState extends ConsumerState<TableListScreen> {
  late int _selectedDay;
  final _searchCtrl = TextEditingController();
  bool _rebalancing = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDay ?? 0;
    Future.microtask(_reload);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    await ref.read(flightListProvider(widget.eventId).notifier).fetch();
    _fetchTablesForCurrentDay();
  }

  void _fetchTablesForCurrentDay() {
    final flights = ref.read(flightListProvider(widget.eventId)).valueOrNull;
    if (flights == null) return;
    final current = flights.cast<EventFlight?>().firstWhere(
          (f) => f!.dayIndex == _selectedDay,
          orElse: () => flights.isNotEmpty ? flights.first : null,
        );
    if (current != null) {
      ref.read(tableListProvider(current.flightId).notifier).fetch();
    }
  }

  int? get _currentFlightId {
    final flights =
        ref.read(flightListProvider(widget.eventId)).valueOrNull ?? [];
    final f = flights.cast<EventFlight?>().firstWhere(
          (f) => f!.dayIndex == _selectedDay,
          orElse: () => null,
        );
    return f?.flightId;
  }

  List<EbsTable> _currentTables() {
    final fid = _currentFlightId;
    if (fid == null) return [];
    return ref.watch(tableListProvider(fid)).valueOrNull ?? [];
  }

  Future<void> _handleRebalance() async {
    final fid = _currentFlightId;
    if (fid == null) return;
    setState(() => _rebalancing = true);
    try {
      // TODO: wire repository rebalance call + WS saga listener
      await Future.delayed(const Duration(milliseconds: 500));
      _fetchTablesForCurrentDay();
    } finally {
      if (mounted) setState(() => _rebalancing = false);
    }
  }

  void _showTableForm(EbsTable? table) {
    final fid = _currentFlightId;
    if (fid == null) return;
    showDialog(
      context: context,
      builder: (_) => TableFormDialog(
        flightId: fid,
        table: table,
        onSaved: _fetchTablesForCurrentDay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncFlights = ref.watch(flightListProvider(widget.eventId));
    final tables = _currentTables();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryBar(tables),
            const SizedBox(height: 12),
            // Day tabs
            asyncFlights.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (flights) => DayTabs(
                flights: flights,
                selectedDayIndex: _selectedDay,
                onDaySelected: (day) {
                  setState(() => _selectedDay = day);
                  _fetchTablesForCurrentDay();
                },
              ),
            ),
            const SizedBox(height: 8),
            _buildToolbar(),
            const SizedBox(height: 12),
            Expanded(child: _buildContent(tables)),
            if (tables.isNotEmpty) ...[
              const SizedBox(height: 8),
              const SeatGridLegend(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar(List<EbsTable> tables) {
    final totalSeats =
        tables.fold<int>(0, (sum, t) => sum + t.maxPlayers);
    final occupied =
        tables.fold<int>(0, (sum, t) => sum + (t.seatedCount ?? 0));
    return Row(
      children: [
        _SummaryStat(label: 'Players', value: '$occupied / $totalSeats'),
        const SizedBox(width: 24),
        _SummaryStat(label: 'Total Tables', value: '${tables.length}'),
        const SizedBox(width: 24),
        _SummaryStat(
          label: 'Seats',
          value: '$totalSeats (empty: ${totalSeats - occupied})',
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Row(
      children: [
        SizedBox(
          width: 200,
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Search player...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const Spacer(),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.orange.shade800,
          ),
          onPressed: _rebalancing ? null : _handleRebalance,
          icon: _rebalancing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.shuffle),
          label: const Text('Rebalance'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () => _showTableForm(null),
          icon: const Icon(Icons.add),
          label: const Text('New Table'),
        ),
      ],
    );
  }

  Widget _buildContent(List<EbsTable> tables) {
    final fid = _currentFlightId;
    if (fid == null) {
      return const EmptyState(
        message: 'No flight selected',
        icon: Icons.table_restaurant,
      );
    }

    final asyncTables = ref.watch(tableListProvider(fid));
    return asyncTables.when(
      loading: () => const LoadingState(),
      error: (err, _) => ErrorBanner(
        message: err.toString(),
        onRetry: _fetchTablesForCurrentDay,
      ),
      data: (tableList) {
        if (tableList.isEmpty) {
          return const EmptyState(
            message: 'No tables found',
            icon: Icons.table_restaurant,
          );
        }
        return SingleChildScrollView(
          child: DataTable(
            columnSpacing: 16,
            columns: const [
              DataColumn(label: Text('Table # / Name')),
              DataColumn(label: Text('Seats')),
              DataColumn(label: Text('Actions')),
            ],
            rows: [
              for (final table in tableList) _buildTableRow(table),
            ],
          ),
        );
      },
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
          PopupMenuButton<String>(
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'cc', child: Text('Enter CC')),
              PopupMenuItem(
                value: 'feature',
                child: Text(
                  table.type == 'feature'
                      ? 'Remove Feature'
                      : 'Set as Feature',
                ),
              ),
            ],
            onSelected: (action) {
              if (action == 'cc') {
                // TODO: launch CC
              }
            },
            child: const Icon(Icons.more_vert, size: 20),
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

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
