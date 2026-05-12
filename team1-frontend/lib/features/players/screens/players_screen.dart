import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../foundation/widgets/empty_state.dart';
import '../../../foundation/widgets/error_banner.dart';
import '../../../foundation/widgets/loading_state.dart';
import '../../../models/models.dart';
import '../../lobby/providers/player_provider.dart';
import '../widgets/player_detail_dialog.dart';

/// Players 독립 화면 — `Lobby/UI.md §화면 4 Player (독립 레이어)` 구현.
///
/// DataTable 컬럼: Name / Country / Position / Table / Seat / Stack / Status / Actions.
/// Cycle 17 cascade — Player Dashboard 4 핵심 필드 (Name + 국적 + 포지션 + 칩스택) 강제.
/// 검색 + Status 필터 + Add Player 버튼. 행 클릭 시 상세 다이얼로그.
///
/// Player 는 Lobby 의 Series/Event/Flight/Table drill-down 과 독립된 레이어 —
/// 어느 화면에서든 좌측 NavigationRail 로 진입 가능.
class PlayersScreen extends ConsumerStatefulWidget {
  const PlayersScreen({super.key});

  @override
  ConsumerState<PlayersScreen> createState() => _PlayersScreenState();
}

enum _StatusFilter { all, active, waiting, busted }

class _PlayersScreenState extends ConsumerState<PlayersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  _StatusFilter _statusFilter = _StatusFilter.all;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(playerListProvider.notifier).fetch());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    ref.read(playerSearchQueryProvider.notifier).state = query;
    ref.read(playerListProvider.notifier).fetch(query: query);
  }

  List<Player> _applyStatusFilter(List<Player> list) {
    switch (_statusFilter) {
      case _StatusFilter.all:
        return list;
      case _StatusFilter.active:
        return list.where((p) => p.playerStatus == 'active').toList();
      case _StatusFilter.waiting:
        return list.where((p) => p.playerStatus == 'waiting').toList();
      case _StatusFilter.busted:
        return list.where((p) => p.playerStatus == 'busted').toList();
    }
  }

  String _fmt(int? v) =>
      v == null ? '—' : v.toString().replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+$)'),
            (m) => '${m[1]},',
          );

  /// ISO-3166 alpha-2 → 🇦-🇿 Regional Indicator emoji.
  /// Cycle 17 Player Dashboard cascade — 국기 표시 (Overview.md §화면 4).
  String _flagEmoji(String? iso2) {
    if (iso2 == null || iso2.length != 2) return '';
    final upper = iso2.toUpperCase();
    final buf = StringBuffer();
    for (final cu in upper.codeUnits) {
      if (cu < 0x41 || cu > 0x5A) return '';
      buf.writeCharCode(0x1F1E6 + (cu - 0x41));
    }
    return buf.toString();
  }

  Widget _countryCell(Player p) {
    final flag = _flagEmoji(p.countryCode);
    final code = p.countryCode ?? '—';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (flag.isNotEmpty)
          Text(flag, style: const TextStyle(fontSize: 16)),
        if (flag.isNotEmpty) const SizedBox(width: 6),
        Text(code, style: const TextStyle(fontFamily: 'monospace')),
      ],
    );
  }

  /// Position chip — D/SB/BB/UTG/MP/CO/HJ. Hand-time derived value.
  /// null/unknown 시 '—'. Dealer (D) / Small Blind (SB) / Big Blind (BB) 강조.
  Widget _positionBadge(String? position) {
    if (position == null || position.isEmpty) {
      return Text('—', style: TextStyle(color: Colors.grey.shade500));
    }
    final upper = position.toUpperCase();
    final (Color bg, Color fg) = switch (upper) {
      'D' => (Colors.amber.shade200, Colors.amber.shade900),
      'SB' => (Colors.blue.shade100, Colors.blue.shade800),
      'BB' => (Colors.indigo.shade100, Colors.indigo.shade800),
      _ => (Colors.grey.shade200, Colors.grey.shade800),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        upper,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final spec = switch (status) {
      'active' => (Icons.circle, Colors.green, 'Active'),
      'waiting' => (Icons.circle_outlined, Colors.orange, 'Waiting'),
      'busted' => (Icons.cancel_outlined, Colors.red, 'Busted'),
      _ => (Icons.help_outline, Colors.grey, status),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(spec.$1, color: spec.$2, size: 12),
        const SizedBox(width: 4),
        Text(spec.$3, style: TextStyle(color: spec.$2, fontSize: 13)),
      ],
    );
  }

  void _showDetail(Player player) {
    showDialog<void>(
      context: context,
      builder: (_) => PlayerDetailDialog(player: player),
    );
  }

  Future<void> _showAddPlayer() async {
    // 플레이어 생성 다이얼로그는 별도 story — 현재는 placeholder.
    // TODO(B-F005): 플레이어 등록 dialog 구현 연결 (WSOP LIVE API sync 또는 수동 등록)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Player dialog — pending B-F005')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncPlayers = ref.watch(playerListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Players'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildToolbar(),
            const SizedBox(height: 12),
            Expanded(
              child: asyncPlayers.when(
                loading: () => const LoadingState(),
                error: (err, _) => ErrorBanner(
                  message: err.toString(),
                  onRetry: () =>
                      ref.read(playerListProvider.notifier).fetch(),
                ),
                data: (list) {
                  final filtered = _applyStatusFilter(list);
                  if (filtered.isEmpty) {
                    return const EmptyState(
                      message: 'No players',
                      icon: Icons.person_off,
                    );
                  }
                  return _buildTable(filtered);
                },
              ),
            ),
            const SizedBox(height: 8),
            asyncPlayers.when(
              data: (list) => Text(
                'Showing ${_applyStatusFilter(list).length} of ${list.length} players',
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

  Widget _buildToolbar() {
    return Row(
      children: [
        SizedBox(
          width: 320,
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              labelText: 'Search player...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: _onSearch,
          ),
        ),
        const SizedBox(width: 12),
        DropdownMenu<_StatusFilter>(
          initialSelection: _statusFilter,
          label: const Text('Status'),
          width: 180,
          dropdownMenuEntries: const [
            DropdownMenuEntry(value: _StatusFilter.all, label: 'All Status'),
            DropdownMenuEntry(value: _StatusFilter.active, label: 'Active'),
            DropdownMenuEntry(value: _StatusFilter.waiting, label: 'Waiting'),
            DropdownMenuEntry(value: _StatusFilter.busted, label: 'Busted'),
          ],
          onSelected: (v) =>
              setState(() => _statusFilter = v ?? _StatusFilter.all),
        ),
        const Spacer(),
        FilledButton.icon(
          icon: const Icon(Icons.person_add),
          label: const Text('Add Player'),
          onPressed: _showAddPlayer,
        ),
      ],
    );
  }

  Widget _buildTable(List<Player> players) {
    return Card(
      margin: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1080),
          child: DataTable(
            columnSpacing: 24,
            showCheckboxColumn: false,
            // Cycle 17 Player Dashboard cascade — 4 핵심 필드 (Name + Country + Position + Stack).
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Country')),
              DataColumn(label: Text('Pos')),
              DataColumn(label: Text('Table')),
              DataColumn(label: Text('Seat'), numeric: true),
              DataColumn(label: Text('Stack'), numeric: true),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('')),
            ],
            rows: [
              for (final p in players)
                DataRow(
                  key: ValueKey('player-row-${p.playerId}'),
                  onSelectChanged: (_) => _showDetail(p),
                  cells: [
                    DataCell(Text('${p.firstName} ${p.lastName}')),
                    DataCell(_countryCell(p)),
                    DataCell(_positionBadge(p.position)),
                    DataCell(Text(p.tableName ?? '—')),
                    DataCell(Text(p.seatIndex?.toString() ?? '—')),
                    DataCell(Text(_fmt(p.stack))),
                    DataCell(_statusBadge(p.playerStatus)),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        tooltip: 'Actions',
                        onPressed: () => _showDetail(p),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
