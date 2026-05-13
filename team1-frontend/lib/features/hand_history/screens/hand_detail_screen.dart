// Hand Detail 화면 — Cycle 21 W3 (Players_HandHistory_API.md §2.4).
//
// SSOT: Hand_History.md §3 (RBAC + hole_cards 마스킹).
//
// nested 응답을 두 섹션으로 표시:
//   1) Hand meta — hand_id / table / game_type / pot_total / board_cards / 시간.
//   2) Hand players — seat / name / start/end stack / pnl / hole_cards / is_winner.
//   3) Hand actions — order / street / seat / action_type / amount / pot_after.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../foundation/widgets/error_banner.dart';
import '../../../foundation/widgets/loading_state.dart';
import '../models/hand_history_models.dart';
import '../providers/hand_history_provider.dart';

class HandDetailScreen extends ConsumerWidget {
  const HandDetailScreen({super.key, required this.handId});

  final int handId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(handHistoryDetailProvider(handId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/hand-history'),
        ),
        title: Text('Hand #$handId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: () =>
                ref.invalidate(handHistoryDetailProvider(handId)),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingState(),
        error: (err, _) => ErrorBanner(
          message: err.toString(),
          onRetry: () => ref.invalidate(handHistoryDetailProvider(handId)),
        ),
        data: (detail) => _buildDetail(context, detail),
      ),
    );
  }

  String _fmtAmount(int v) => v.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  List<String> _parseCards(String raw) {
    if (raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    } on FormatException {
      // 마스킹된 빈 응답 또는 깨진 JSON → placeholder.
    }
    return const [];
  }

  Widget _cardRow(List<String> cards, {String? placeholder}) {
    if (cards.isEmpty) {
      return Text(placeholder ?? '—',
          style: TextStyle(color: Colors.grey.shade500));
    }
    return Wrap(
      spacing: 4,
      children: [
        for (final c in cards)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              c,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDetail(BuildContext context, HandHistoryDetail d) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHandMeta(d),
          const SizedBox(height: 20),
          Text('Players (${d.handPlayers.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildPlayersTable(d.handPlayers),
          const SizedBox(height: 20),
          Text('Actions (${d.handActions.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildActionsTable(d.handActions),
        ],
      ),
    );
  }

  Widget _buildHandMeta(HandHistoryDetail d) {
    final board = _parseCards(d.boardCards);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _meta('Hand #', '${d.handNumber}'),
            _meta('Table', '${d.tableId}'),
            _meta('Dealer Seat', '${d.dealerSeat}'),
            _meta('Pot', _fmtAmount(d.potTotal)),
            _meta('Started', d.startedAt),
            if (d.endedAt != null) _meta('Ended', d.endedAt!),
            _meta('Duration', '${d.durationSec}s'),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Board',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                _cardRow(board, placeholder: '(no flop)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontFamily: 'monospace')),
      ],
    );
  }

  Widget _buildPlayersTable(List<HandHistoryPlayer> players) {
    if (players.isEmpty) {
      return const Text('No players in this hand.');
    }
    return Card(
      margin: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          columns: const [
            DataColumn(label: Text('Seat'), numeric: true),
            DataColumn(label: Text('Player')),
            DataColumn(label: Text('Hole')),
            DataColumn(label: Text('Start'), numeric: true),
            DataColumn(label: Text('End'), numeric: true),
            DataColumn(label: Text('PnL'), numeric: true),
            DataColumn(label: Text('Rank')),
            DataColumn(label: Text('Winner')),
          ],
          rows: [
            for (final p in players)
              DataRow(
                key: ValueKey('hh-player-${p.id}'),
                cells: [
                  DataCell(Text(p.seatNo.toString())),
                  DataCell(Text(p.playerName)),
                  DataCell(_cardRow(_parseCards(p.holeCards),
                      placeholder: '(masked)')),
                  DataCell(Text(_fmtAmount(p.startStack))),
                  DataCell(Text(_fmtAmount(p.endStack))),
                  DataCell(Text(
                    (p.pnl >= 0 ? '+' : '') + _fmtAmount(p.pnl),
                    style: TextStyle(
                      color: p.pnl > 0
                          ? Colors.green.shade700
                          : (p.pnl < 0 ? Colors.red.shade700 : null),
                    ),
                  )),
                  DataCell(Text(p.handRank ?? '—')),
                  DataCell(p.isWinner
                      ? const Icon(Icons.emoji_events,
                          color: Colors.amber, size: 18)
                      : const Text('—')),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsTable(List<HandHistoryAction> actions) {
    if (actions.isEmpty) {
      return const Text('No recorded actions.');
    }
    return Card(
      margin: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          columns: const [
            DataColumn(label: Text('#'), numeric: true),
            DataColumn(label: Text('Street')),
            DataColumn(label: Text('Seat'), numeric: true),
            DataColumn(label: Text('Action')),
            DataColumn(label: Text('Amount'), numeric: true),
            DataColumn(label: Text('Pot after'), numeric: true),
          ],
          rows: [
            for (final a in actions)
              DataRow(
                key: ValueKey('hh-action-${a.id}'),
                cells: [
                  DataCell(Text(a.actionOrder.toString())),
                  DataCell(Text(a.street)),
                  DataCell(Text(a.seatNo.toString())),
                  DataCell(Text(a.actionType)),
                  DataCell(Text(_fmtAmount(a.actionAmount))),
                  DataCell(Text(
                      a.potAfter != null ? _fmtAmount(a.potAfter!) : '—')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
