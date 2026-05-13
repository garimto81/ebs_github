// Hand History 리스트 화면 — Cycle 21 W3 (Reports 폐기 후 독립 격상).
//
// SSOT: docs/2. Development/2.1 Frontend/Lobby/Hand_History.md
//       docs/2. Development/2.2 Backend/APIs/Players_HandHistory_API.md §2.3
//
// 화면 구성:
//   1) Toolbar — Filter chips (event/table/player/showdown only) + Refresh.
//   2) DataTable — Hand# / Table / Started / Duration / Pot / Winner / Action.
//   3) 무한 스크롤 — 마지막 행 보이면 loadMore.
//   4) Row tap → /hand-history/:id 로 진입.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../foundation/widgets/empty_state.dart';
import '../../../foundation/widgets/error_banner.dart';
import '../../../foundation/widgets/loading_state.dart';
import '../models/hand_history_models.dart';
import '../providers/hand_history_provider.dart';

class HandHistoryScreen extends ConsumerStatefulWidget {
  const HandHistoryScreen({super.key});

  @override
  ConsumerState<HandHistoryScreen> createState() => _HandHistoryScreenState();
}

class _HandHistoryScreenState extends ConsumerState<HandHistoryScreen> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _eventIdCtrl = TextEditingController();
  final TextEditingController _tableIdCtrl = TextEditingController();
  final TextEditingController _playerIdCtrl = TextEditingController();
  bool _showdownOnly = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    Future.microtask(() =>
        ref.read(handHistoryListProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _eventIdCtrl.dispose();
    _tableIdCtrl.dispose();
    _playerIdCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 아래쪽 200px 안에 들어오면 추가 로드.
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 200) {
      ref.read(handHistoryListProvider.notifier).loadMore();
    }
  }

  int? _parseInt(TextEditingController c) {
    final s = c.text.trim();
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  void _applyFilter() {
    final filter = HandHistoryFilter(
      eventId: _parseInt(_eventIdCtrl),
      tableId: _parseInt(_tableIdCtrl),
      playerId: _parseInt(_playerIdCtrl),
      showdownOnly: _showdownOnly,
    );
    ref.read(handHistoryListProvider.notifier).refresh(filter: filter);
  }

  void _resetFilter() {
    _eventIdCtrl.clear();
    _tableIdCtrl.clear();
    _playerIdCtrl.clear();
    setState(() => _showdownOnly = false);
    ref
        .read(handHistoryListProvider.notifier)
        .refresh(filter: const HandHistoryFilter());
  }

  String _fmtPot(int v) => v.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  String _fmtDuration(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  String _fmtStartedAt(String iso) {
    // 단순 표시 — ISO 그대로 자르기 (e.g. 2026-05-13T07:30:00Z → 05-13 07:30).
    if (iso.length < 16) return iso;
    return '${iso.substring(5, 10)} ${iso.substring(11, 16)}';
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(handHistoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hand History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(handHistoryListProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFilterToolbar(),
            const SizedBox(height: 12),
            Expanded(
              child: asyncState.when(
                loading: () => const LoadingState(),
                error: (err, _) => ErrorBanner(
                  message: err.toString(),
                  onRetry: () =>
                      ref.read(handHistoryListProvider.notifier).refresh(),
                ),
                data: (state) {
                  if (state.items.isEmpty) {
                    return const EmptyState(
                      message: 'No hands found',
                      icon: Icons.history,
                    );
                  }
                  return _buildList(state);
                },
              ),
            ),
            const SizedBox(height: 8),
            asyncState.when(
              data: (s) => Text(
                'Showing ${s.items.length} hands${s.hasMore ? " (more available)" : ""}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey.shade600),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterToolbar() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 120,
          child: TextField(
            key: const ValueKey('hh-filter-event'),
            controller: _eventIdCtrl,
            decoration: const InputDecoration(
              labelText: 'Event ID',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        SizedBox(
          width: 120,
          child: TextField(
            key: const ValueKey('hh-filter-table'),
            controller: _tableIdCtrl,
            decoration: const InputDecoration(
              labelText: 'Table ID',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        SizedBox(
          width: 120,
          child: TextField(
            key: const ValueKey('hh-filter-player'),
            controller: _playerIdCtrl,
            decoration: const InputDecoration(
              labelText: 'Player ID',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        FilterChip(
          key: const ValueKey('hh-filter-showdown'),
          label: const Text('Showdown only'),
          selected: _showdownOnly,
          onSelected: (v) => setState(() => _showdownOnly = v),
        ),
        FilledButton.icon(
          key: const ValueKey('hh-filter-apply'),
          icon: const Icon(Icons.filter_alt),
          label: const Text('Apply'),
          onPressed: _applyFilter,
        ),
        TextButton(
          key: const ValueKey('hh-filter-reset'),
          onPressed: _resetFilter,
          child: const Text('Reset'),
        ),
      ],
    );
  }

  Widget _buildList(HandHistoryListState state) {
    return Card(
      margin: EdgeInsets.zero,
      child: SingleChildScrollView(
        controller: _scroll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1000),
          child: Column(
            children: [
              DataTable(
                columnSpacing: 24,
                showCheckboxColumn: false,
                columns: const [
                  DataColumn(label: Text('Hand#'), numeric: true),
                  DataColumn(label: Text('Table'), numeric: true),
                  DataColumn(label: Text('Started')),
                  DataColumn(label: Text('Duration')),
                  DataColumn(label: Text('Pot'), numeric: true),
                  DataColumn(label: Text('Winner')),
                  DataColumn(label: Text('')),
                ],
                rows: [
                  for (final h in state.items)
                    DataRow(
                      key: ValueKey('hh-row-${h.handId}'),
                      onSelectChanged: (_) =>
                          context.go('/hand-history/${h.handId}'),
                      cells: [
                        DataCell(Text('#${h.handNumber}')),
                        DataCell(Text(h.tableId.toString())),
                        DataCell(Text(_fmtStartedAt(h.startedAt))),
                        DataCell(Text(_fmtDuration(h.durationSec))),
                        DataCell(Text(_fmtPot(h.potTotal))),
                        DataCell(Text(h.winnerPlayerName ?? '—')),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            tooltip: 'Details',
                            onPressed: () =>
                                context.go('/hand-history/${h.handId}'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (state.isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(),
                ),
              if (!state.hasMore && state.items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No more hands',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
