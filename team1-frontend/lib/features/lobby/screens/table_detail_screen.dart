import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../foundation/widgets/error_banner.dart';
import '../../../foundation/widgets/loading_state.dart';
import '../../../models/models.dart';
import '../widgets/add_player_dialog.dart';

/// Table detail screen with large seat map and player DataTable.
///
/// Ported from TableDetailPage.vue.
class TableDetailScreen extends ConsumerStatefulWidget {
  final int tableId;
  const TableDetailScreen({super.key, required this.tableId});

  @override
  ConsumerState<TableDetailScreen> createState() => _TableDetailScreenState();
}

class _TableDetailScreenState extends ConsumerState<TableDetailScreen> {
  bool _loading = false;
  String? _error;
  EbsTable? _table;
  List<TableSeat> _seats = [];
  bool _launching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // TODO: wire repository calls
      // _table = await ref.read(tableRepositoryProvider).getById(widget.tableId);
      // _seats = await ref.read(seatRepositoryProvider).getByTable(widget.tableId);
      _table = null;
      _seats = [];
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _maxSeats => _table?.maxPlayers ?? 10;

  List<int> get _emptySeats {
    final occupied = _seats.map((s) => s.seatNo).toSet();
    return [for (int i = 1; i <= _maxSeats; i++) if (!occupied.contains(i)) i];
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'live':
        return Colors.green;
      case 'setup':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _seatPlayerName(int seatNo) {
    final seat = _seats.cast<TableSeat?>().firstWhere(
          (s) => s!.seatNo == seatNo,
          orElse: () => null,
        );
    if (seat == null || seat.playerName == null) return 'empty';
    final parts = seat.playerName!.split(' ');
    if (parts.length >= 2) return '${parts[0]} ${parts[1][0]}.';
    return seat.playerName!;
  }

  bool _isSeatOccupied(int seatNo) {
    return _seats.any((s) => s.seatNo == seatNo && s.status == 'occupied');
  }

  void _showAddPlayerDialog() {
    showDialog(
      context: context,
      builder: (_) => AddPlayerDialog(
        tableId: widget.tableId,
        emptySeats: _emptySeats,
        onSaved: _loadData,
      ),
    );
  }

  Future<void> _handleLaunchCc() async {
    setState(() => _launching = true);
    try {
      // TODO: wire CC launch API
      await Future.delayed(const Duration(milliseconds: 300));
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (_loading)
              const Expanded(child: LoadingState())
            else if (_error != null)
              ErrorBanner(message: _error!, onRetry: _loadData)
            else
              Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _table?.name ?? 'Table #${widget.tableId}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_table != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor(_table!.status),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _table!.status,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
                if (_table?.type == 'feature') ...[
                  const SizedBox(width: 4),
                  Icon(Icons.star, color: Colors.amber.shade600, size: 20),
                ],
              ],
            ),
            if (_table != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Blinds ${_table!.smallBlind ?? 0}/${_table!.bigBlind ?? 0}'
                  '${_table!.anteAmount > 0 ? ' \u00b7 Ante ${_table!.anteAmount}' : ''}'
                  ' \u00b7 ${_table!.maxPlayers} max',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
              ),
          ],
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: _showAddPlayerDialog,
          icon: const Icon(Icons.person_add),
          label: const Text('Add Player'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          onPressed: _launching ? null : _handleLaunchCc,
          icon: _launching
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.open_in_new),
          label: const Text('Enter CC'),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seat map grid
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seat Map',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  _buildSeatMapGrid(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Player DataTable
          _buildPlayerTable(),
        ],
      ),
    );
  }

  Widget _buildSeatMapGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (int seatNo = 1; seatNo <= _maxSeats; seatNo++)
          _buildSeatMapCell(seatNo),
      ],
    );
  }

  Widget _buildSeatMapCell(int seatNo) {
    final occupied = _isSeatOccupied(seatNo);
    return Tooltip(
      message: 'Seat $seatNo: ${_seatPlayerName(seatNo)}',
      child: Container(
        width: 90,
        height: 56,
        decoration: BoxDecoration(
          color: occupied
              ? Colors.green.shade100
              : Colors.grey.shade200,
          border: Border.all(
            color: occupied ? Colors.green : Colors.grey.shade400,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$seatNo',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              _seatPlayerName(seatNo),
              style: const TextStyle(fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerTable() {
    return DataTable(
      columnSpacing: 24,
      columns: const [
        DataColumn(label: Text('Seat')),
        DataColumn(label: Text('Player Name')),
        DataColumn(label: Text('Stack'), numeric: true),
        DataColumn(label: Text('Status')),
      ],
      rows: [
        for (final seat in _seats)
          DataRow(cells: [
            DataCell(Text('${seat.seatNo}')),
            DataCell(Text(seat.playerName ?? '\u2014')),
            DataCell(Text(seat.chipCount.toString())),
            DataCell(
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: seat.status == 'occupied'
                      ? Colors.green
                      : Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  seat.status,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          ]),
      ],
    );
  }
}
