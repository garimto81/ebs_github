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
import '../widgets/event_form_dialog.dart';

/// Event list (Management) screen with multi-filter bar, status tabs,
/// 15-column DataTable, and flight accordion sub-rows.
///
/// Ported from EventListPage.vue.
class EventListScreen extends ConsumerStatefulWidget {
  final int seriesId;
  const EventListScreen({super.key, required this.seriesId});

  @override
  ConsumerState<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends ConsumerState<EventListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _eventNoCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _gameTypeFilter = 'All';
  bool _showToday = false;
  final Set<int> _expandedIds = {};

  static const _statusTabs = [
    'all',
    'announced',
    'registering',
    'running',
    'completed',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _statusTabs.length, vsync: this);
    Future.microtask(
      () => ref.read(eventListProvider(widget.seriesId).notifier).fetch(),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _eventNoCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _eventNoCtrl.clear();
      _nameCtrl.clear();
      _gameTypeFilter = 'All';
      _showToday = false;
      _tabCtrl.index = 0;
    });
  }

  void _reload() {
    ref.read(eventListProvider(widget.seriesId).notifier).fetch();
  }

  List<EbsEvent> _filter(List<EbsEvent> events) {
    var result = events;

    // Status tab
    final tab = _statusTabs[_tabCtrl.index];
    if (tab != 'all') {
      result = result.where((e) => e.status == tab).toList();
    }

    // Today filter
    if (_showToday) {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      result = result
          .where((e) => (e.startTime ?? '').startsWith(today))
          .toList();
    }

    // Event No
    final noQ = _eventNoCtrl.text.trim();
    if (noQ.isNotEmpty) {
      result =
          result.where((e) => e.eventNo.toString().contains(noQ)).toList();
    }

    // Name
    final nameQ = _nameCtrl.text.trim().toLowerCase();
    if (nameQ.isNotEmpty) {
      result = result
          .where((e) => e.eventName.toLowerCase().contains(nameQ))
          .toList();
    }

    // Game type
    if (_gameTypeFilter != 'All') {
      final gv = int.tryParse(_gameTypeFilter);
      if (gv != null) {
        result = result.where((e) => e.gameType == gv).toList();
      }
    }

    return result;
  }

  Map<String, int> _statusCounts(List<EbsEvent> events) {
    return {
      'all': events.length,
      'announced': events.where((e) => e.status == 'announced').length,
      'registering': events.where((e) => e.status == 'registering').length,
      'running': events.where((e) => e.status == 'running').length,
      'completed': events.where((e) => e.status == 'completed').length,
    };
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'running':
        return Colors.green;
      case 'registering':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'announced':
        return Colors.grey.shade600;
      default:
        return Colors.grey;
    }
  }

  String _formatCurrency(dynamic val) {
    if (val == null) return '\u2014';
    final num = double.tryParse(val.toString());
    if (num == null) return '\u2014';
    return '\$${num.toStringAsFixed(0)}';
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (_) => EventFormDialog(
        seriesId: widget.seriesId,
        onSaved: _reload,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncEvents = ref.watch(eventListProvider(widget.seriesId));

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(),
            const SizedBox(height: 8),
            _buildFilterBar(),
            const SizedBox(height: 8),
            _buildStatusTabs(asyncEvents),
            const SizedBox(height: 4),
            _buildQuickFilters(),
            const SizedBox(height: 8),
            Expanded(child: _buildContent(asyncEvents)),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Management',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              'Series #${widget.seriesId}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
          ],
        ),
        const Spacer(),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _showCreateDialog,
          icon: const Icon(Icons.add),
          label: const Text('Create New Tournament'),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: TextField(
            controller: _eventNoCtrl,
            decoration: const InputDecoration(
              labelText: 'Event No.',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 180,
          child: TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 140,
          child: DropdownButtonFormField<String>(
            initialValue: _gameTypeFilter,
            decoration: const InputDecoration(
              labelText: 'Game Type',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(value: 'All', child: Text('All')),
              for (final g in GameType.values)
                DropdownMenuItem(value: '${g.value}', child: Text(g.label)),
            ],
            onChanged: (v) => setState(() => _gameTypeFilter = v ?? 'All'),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _resetFilters,
          tooltip: 'Reset filters',
        ),
      ],
    );
  }

  Widget _buildStatusTabs(AsyncValue<List<EbsEvent>> asyncEvents) {
    final counts =
        _statusCounts(asyncEvents.valueOrNull ?? []);
    return TabBar(
      controller: _tabCtrl,
      isScrollable: true,
      onTap: (_) => setState(() {}),
      indicatorColor: Theme.of(context).colorScheme.primary,
      labelColor: Theme.of(context).colorScheme.primary,
      unselectedLabelColor: Colors.grey,
      tabs: [
        for (final tab in _statusTabs)
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tab[0].toUpperCase() + tab.substring(1)),
                const SizedBox(width: 4),
                Badge(
                  label: Text('${counts[tab] ?? 0}'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQuickFilters() {
    return Row(
      children: [
        FilterChip(
          avatar: const Icon(Icons.today, size: 16),
          label: const Text("Today's Events"),
          selected: _showToday,
          onSelected: (v) => setState(() => _showToday = v),
        ),
      ],
    );
  }

  Widget _buildContent(AsyncValue<List<EbsEvent>> asyncEvents) {
    return asyncEvents.when(
      loading: () => const LoadingState(),
      error: (err, _) => ErrorBanner(message: err.toString(), onRetry: _reload),
      data: (events) {
        final filtered = _filter(events);
        if (filtered.isEmpty) {
          return const EmptyState(
            message: 'No events found',
            icon: Icons.event,
          );
        }
        return _buildEventTable(filtered);
      },
    );
  }

  Widget _buildEventTable(List<EbsEvent> events) {
    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: 12,
        headingRowHeight: 40,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 48,
        columns: const [
          DataColumn(label: Text('Start')),
          DataColumn(label: Text('No.')),
          DataColumn(label: Text('Event Name / Flights')),
          DataColumn(label: Text('Remain/Total')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Level')),
          DataColumn(label: Text('Buy-In'), numeric: true),
        ],
        rows: [
          for (final event in events) ...[
            _buildEventRow(event),
            if (_expandedIds.contains(event.eventId))
              ..._buildFlightRows(event.eventId),
          ],
        ],
      ),
    );
  }

  DataRow _buildEventRow(EbsEvent event) {
    final isExpanded = _expandedIds.contains(event.eventId);
    return DataRow(
      onSelectChanged: (_) {
        selectEvent(ref, event.eventId, name: event.eventName);
        context.go('/events/${event.eventId}/tables');
      },
      cells: [
        DataCell(Text(
          event.startTime != null && event.startTime!.length >= 10
              ? event.startTime!.substring(5, 10)
              : '\u2014',
        )),
        DataCell(Text('${event.eventNo}')),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedIds.remove(event.eventId);
                    } else {
                      _expandedIds.add(event.eventId);
                      // Fetch flights for this event
                      ref
                          .read(flightListProvider(event.eventId).notifier)
                          .fetch();
                    }
                  });
                },
                child: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  event.eventName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        DataCell(Text('${event.playersLeft}/${event.totalEntries}')),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _statusColor(event.status),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              event.status,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
        const DataCell(Text('\u2014')), // current_level not on model
        DataCell(Text(_formatCurrency(event.displayBuyIn))),
      ],
    );
  }

  List<DataRow> _buildFlightRows(int eventId) {
    final asyncFlights = ref.watch(flightListProvider(eventId));
    return asyncFlights.when(
      loading: () => [
        const DataRow(cells: [
          DataCell(SizedBox.shrink()),
          DataCell(SizedBox.shrink()),
          DataCell(Text('Loading flights...')),
          DataCell(SizedBox.shrink()),
          DataCell(SizedBox.shrink()),
          DataCell(SizedBox.shrink()),
          DataCell(SizedBox.shrink()),
        ]),
      ],
      error: (_, __) => [],
      data: (flights) => flights.map((f) {
        return DataRow(
          color: WidgetStatePropertyAll(Colors.grey.shade50),
          onSelectChanged: (_) {
            context.go('/events/$eventId/tables?day=${f.dayIndex}');
          },
          cells: [
            const DataCell(SizedBox.shrink()),
            const DataCell(SizedBox.shrink()),
            DataCell(
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text('\u2514 ${f.flightName}'),
              ),
            ),
            DataCell(Text('${f.tableCount} tables')),
            DataCell(
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor(f.status),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  f.status,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
            DataCell(Text('Lvl ${f.playLevel}')),
            const DataCell(SizedBox.shrink()),
          ],
        );
      }).toList(),
    );
  }
}
