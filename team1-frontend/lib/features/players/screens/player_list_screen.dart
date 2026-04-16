import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../foundation/widgets/empty_state.dart';
import '../../../foundation/widgets/loading_state.dart';
import '../../../models/models.dart';
import '../../lobby/providers/player_provider.dart';

class PlayerListScreen extends ConsumerStatefulWidget {
  const PlayerListScreen({super.key});

  @override
  ConsumerState<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends ConsumerState<PlayerListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(playerListProvider.notifier).fetch(),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(playerSearchQueryProvider.notifier).state = value.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playerListProvider);
    final searchQuery = ref.watch(playerSearchQueryProvider).toLowerCase();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Text(
                  'Players',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search players...',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: playersAsync.when(
                loading: () => const LoadingState(),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (players) {
                  final filtered = searchQuery.isEmpty
                      ? players
                      : players.where((p) {
                          final name =
                              '${p.firstName} ${p.lastName}'.toLowerCase();
                          return name.contains(searchQuery);
                        }).toList();

                  if (filtered.isEmpty) {
                    return const EmptyState(
                      message: 'No players found',
                      icon: Icons.person,
                    );
                  }

                  return _PlayerDataTable(
                    players: filtered,
                    onTap: (p) =>
                        context.go('/players/${p.playerId}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerDataTable extends StatefulWidget {
  final List<Player> players;
  final ValueChanged<Player> onTap;

  const _PlayerDataTable({
    required this.players,
    required this.onTap,
  });

  @override
  State<_PlayerDataTable> createState() => _PlayerDataTableState();
}

class _PlayerDataTableState extends State<_PlayerDataTable> {
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: PaginatedDataTable(
        header: Text('${widget.players.length} players'),
        columns: [
          DataColumn(
            label: const Text('Name'),
            onSort: _onSort,
          ),
          DataColumn(
            label: const Text('WSOP ID'),
            onSort: _onSort,
          ),
          DataColumn(
            label: const Text('Current Table'),
            onSort: _onSort,
          ),
          DataColumn(
            label: const Text('Stack'),
            numeric: true,
            onSort: _onSort,
          ),
          DataColumn(
            label: const Text('Status'),
            onSort: _onSort,
          ),
        ],
        source: _PlayerDataSource(
          players: _sorted(),
          onTap: widget.onTap,
        ),
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        rowsPerPage: _rowsPerPage,
        availableRowsPerPage: const [10, 20, 50],
        onRowsPerPageChanged: (value) {
          if (value != null) {
            setState(() => _rowsPerPage = value);
          }
        },
      ),
    );
  }

  List<Player> _sorted() {
    final list = List<Player>.from(widget.players);
    list.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 0:
          cmp = '${a.firstName} ${a.lastName}'
              .compareTo('${b.firstName} ${b.lastName}');
        case 1:
          cmp = (a.wsopId ?? '').compareTo(b.wsopId ?? '');
        case 2:
          cmp = (a.tableName ?? '').compareTo(b.tableName ?? '');
        case 3:
          cmp = (a.stack ?? 0).compareTo(b.stack ?? 0);
        case 4:
          cmp = a.playerStatus.compareTo(b.playerStatus);
        default:
          cmp = 0;
      }
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }
}

class _PlayerDataSource extends DataTableSource {
  final List<Player> players;
  final ValueChanged<Player> onTap;

  _PlayerDataSource({required this.players, required this.onTap});

  @override
  DataRow? getRow(int index) {
    if (index >= players.length) return null;
    final p = players[index];
    return DataRow.byIndex(
      index: index,
      onSelectChanged: (_) => onTap(p),
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                child: Text(
                  p.firstName.isNotEmpty ? p.firstName[0] : '?',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Text('${p.firstName} ${p.lastName}'),
            ],
          ),
        ),
        DataCell(Text(p.wsopId ?? '\u2014')),
        DataCell(Text(p.tableName ?? '\u2014')),
        DataCell(Text(p.stack != null ? _formatNumber(p.stack!) : '\u2014')),
        DataCell(_StatusBadge(status: p.playerStatus)),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => players.length;

  @override
  int get selectedRowCount => 0;

  static String _formatNumber(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k';
    }
    return value.toString();
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          color: isActive ? Colors.green : Colors.grey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
