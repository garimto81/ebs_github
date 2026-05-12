import 'package:flutter/material.dart';

import '../../../foundation/widgets/empty_state.dart';
import '../../../models/models.dart';
import 'game_rules_badges.dart';

/// Expandable hand detail — Players table + Board cards + Actions by street.
///
/// Ported from Quasar `hand-history/HandDetail.vue`. Read-only. Caller
/// provides resolved [hand] + [players] + [actions] lists (typically from
/// `reportDataProvider` after expanding a row in `ReportsScreen`
/// hands-summary tab). This keeps the widget pure/testable — I/O stays
/// in the parent.
///
/// Cycle 7 (v03 game rules):
///   - GameRulesBadges row at top (Ante / Straddle / Run It Twice).
///   - Players table shows winner share % when runItTwiceCount > 1
///     (e.g. star + "50%" when two winners split two boards).
class HandDetail extends StatelessWidget {
  final Hand hand;
  final List<HandPlayer> players;
  final List<HandAction> actions;

  const HandDetail({
    super.key,
    required this.hand,
    required this.players,
    required this.actions,
  });

  static const _streets = <String>['Preflop', 'Flop', 'Turn', 'River'];

  List<String> get _boardCards =>
      hand.boardCards.split(RegExp(r'[,\s]+')).where((s) => s.isNotEmpty).toList();

  Map<String, List<HandAction>> get _actionsByStreet {
    final grouped = <String, List<HandAction>>{for (final s in _streets) s: []};
    for (final a in actions) {
      final bucket = grouped[a.street];
      if (bucket != null) bucket.add(a);
    }
    for (final bucket in grouped.values) {
      bucket.sort((a, b) => a.actionOrder.compareTo(b.actionOrder));
    }
    return grouped;
  }

  bool get _hasGameRulesBadges =>
      hand.anteAmount > 0 ||
      (hand.straddleAmount != null && hand.straddleAmount! > 0) ||
      hand.runItTwiceCount > 1;

  @override
  Widget build(BuildContext context) {
    final empty = players.isEmpty && actions.isEmpty;
    if (empty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: EmptyState(message: 'No detail for this hand', icon: Icons.info),
      );
    }

    final grouped = _actionsByStreet;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // v03 game-rules badges row (Cycle 7)
          if (_hasGameRulesBadges) ...[
            GameRulesBadges(
              anteAmount: hand.anteAmount,
              straddleAmount: hand.straddleAmount,
              runItTwiceCount: hand.runItTwiceCount,
            ),
            const SizedBox(height: 12),
          ],

          // Players
          const _SectionLabel('Players'),
          _PlayersTable(
            players: players,
            runItTwiceCount: hand.runItTwiceCount,
          ),

          // Board cards
          if (_boardCards.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Board:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final card in _boardCards)
                      Chip(
                        label: Text(card),
                        backgroundColor: Colors.grey.shade900,
                        labelStyle: const TextStyle(color: Colors.white),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ),
          ],

          // Actions by street
          const SizedBox(height: 16),
          const _SectionLabel('Actions'),
          for (final street in _streets)
            if ((grouped[street] ?? const []).isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  street,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                ),
              ),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final a in grouped[street]!) _ActionRow(action: a),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _PlayersTable extends StatelessWidget {
  final List<HandPlayer> players;
  final int runItTwiceCount;
  const _PlayersTable({required this.players, required this.runItTwiceCount});

  String _fmt(int v) => v.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]},',
      );

  /// Winner cell content:
  /// - Single run (runItTwiceCount <= 1): star or empty.
  /// - Multi run: star + "N%" share when isWinner & runItTwiceShare set.
  ///   Falls back to bare star when share missing.
  String _winnerLabel(HandPlayer p) {
    if (!p.isWinner) return '';
    if (runItTwiceCount <= 1) return '*';
    final share = p.runItTwiceShare;
    if (share == null) return '*';
    final pct = (share * 100).round();
    return '* $pct%';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        columns: [
          const DataColumn(label: Text('Seat')),
          const DataColumn(label: Text('Player')),
          const DataColumn(label: Text('Hole Cards')),
          const DataColumn(label: Text('Start'), numeric: true),
          const DataColumn(label: Text('End'), numeric: true),
          const DataColumn(label: Text('PnL'), numeric: true),
          DataColumn(
            label: Text(runItTwiceCount > 1 ? 'Winner (share)' : ''),
          ),
        ],
        rows: [
          for (final p in players)
            DataRow(cells: [
              DataCell(Text('${p.seatNo}')),
              DataCell(Text(p.playerName)),
              DataCell(Text(p.holeCards)),
              DataCell(Text(_fmt(p.startStack))),
              DataCell(Text(_fmt(p.endStack))),
              DataCell(Text(
                (p.pnl >= 0 ? '+' : '') + _fmt(p.pnl),
                style: TextStyle(
                  color: p.pnl >= 0 ? Colors.green : Colors.red,
                ),
              )),
              DataCell(Text(
                _winnerLabel(p),
                style: TextStyle(
                  fontWeight: p.isWinner ? FontWeight.bold : FontWeight.normal,
                  color: p.isWinner ? Colors.amber.shade800 : null,
                ),
              )),
            ]),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final HandAction action;
  const _ActionRow({required this.action});

  String _fmt(int v) => v.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]},',
      );

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Chip(
        label: Text('Seat ${action.seatNo}'),
        visualDensity: VisualDensity.compact,
        backgroundColor: Colors.grey.shade200,
      ),
      title: Row(
        children: [
          Text(action.actionType),
          if (action.actionAmount > 0) ...[
            const SizedBox(width: 8),
            Text(
              _fmt(action.actionAmount),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
      trailing: action.potAfter != null
          ? Text(
              'Pot: ${_fmt(action.potAfter!)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            )
          : null,
    );
  }
}
