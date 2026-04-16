// Hand detail widget — shows players table, board cards, and actions by street.
//
// Ported from _archive-quasar/src/components/hand-history/HandDetail.vue (141 LOC).
// Loaded lazily when a hand row is expanded in HandHistoryScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../foundation/widgets/empty_state.dart';
import '../../../models/models.dart';
import '../../../repositories/hand_repository.dart';
import '../../../resources/l10n/app_localizations.dart';

class HandDetail extends ConsumerStatefulWidget {
  final int handId;
  const HandDetail({super.key, required this.handId});

  @override
  ConsumerState<HandDetail> createState() => _HandDetailState();
}

class _HandDetailState extends ConsumerState<HandDetail> {
  Hand? _hand;
  List<HandPlayer> _players = [];
  List<HandAction> _actions = [];
  var _loading = true;

  static const _streets = ['Preflop', 'Flop', 'Turn', 'River'];

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final repo = ref.read(handRepositoryProvider);
    try {
      final results = await Future.wait([
        repo.getHand(widget.handId),
        repo.getPlayers(widget.handId),
        repo.getActions(widget.handId),
      ]);
      if (mounted) {
        setState(() {
          _hand = results[0] as Hand;
          _players = results[1] as List<HandPlayer>;
          _actions = results[2] as List<HandAction>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, List<HandAction>> get _actionsByStreet {
    final grouped = <String, List<HandAction>>{};
    for (final street in _streets) {
      final streetActions = _actions
          .where((a) => a.street == street)
          .toList()
        ..sort((a, b) => a.actionOrder.compareTo(b.actionOrder));
      if (streetActions.isNotEmpty) {
        grouped[street] = streetActions;
      }
    }
    return grouped;
  }

  List<String> get _boardCards {
    final cards = _hand?.boardCards;
    if (cards == null || cards.isEmpty) return [];
    return cards.split(RegExp(r'[,\s]+')).where((s) => s.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_actions.isEmpty && _players.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: EmptyState(
            message: l.lobbyHandHistoryNoDetail, icon: Icons.info),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Players table --
          Text(l.lobbyHandHistoryPlayers,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildPlayersTable(l),
          const SizedBox(height: 16),

          // -- Board cards --
          if (_boardCards.isNotEmpty) ...[
            Row(
              children: [
                Text('${l.lobbyHandHistoryBoard}: ',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                ..._boardCards.map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Chip(
                      label: Text(card),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // -- Actions by street --
          Text(l.lobbyHandHistoryActions,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._actionsByStreet.entries.map(
            (entry) => _buildStreetActions(entry.key, entry.value, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersTable(AppLocalizations l) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        columns: [
          DataColumn(label: Text(l.lobbyHandHistorySeat)),
          DataColumn(label: Text(l.lobbyHandHistoryPlayer)),
          DataColumn(label: Text(l.lobbyHandHistoryHoleCards)),
          DataColumn(
              label: Text(l.lobbyHandHistoryStartStack), numeric: true),
          DataColumn(
              label: Text(l.lobbyHandHistoryEndStack), numeric: true),
          DataColumn(label: Text(l.lobbyHandHistoryPnl), numeric: true),
          DataColumn(label: Text(l.lobbyHandHistoryWinner)),
        ],
        rows: _players.map((p) {
          final pnlPrefix = p.pnl >= 0 ? '+' : '';
          return DataRow(cells: [
            DataCell(Text(p.seatNo.toString())),
            DataCell(Text(p.playerName)),
            DataCell(Text(p.holeCards)),
            DataCell(Text(p.startStack.toStringAsFixed(0))),
            DataCell(Text(p.endStack.toStringAsFixed(0))),
            DataCell(Text('$pnlPrefix${p.pnl}')),
            DataCell(Text(p.isWinner ? '\u2605' : '')),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildStreetActions(
      String street, List<HandAction> actions, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(street,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.outline,
              )),
          const SizedBox(height: 4),
          Card(
            child: Column(
              children: actions.map((a) {
                return ListTile(
                  dense: true,
                  leading: Chip(
                    label: Text('Seat ${a.seatNo}'),
                    visualDensity: VisualDensity.compact,
                  ),
                  title: Row(
                    children: [
                      Text(a.actionType),
                      if (a.actionAmount > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          a.actionAmount.toStringAsFixed(0),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                  trailing: a.potAfter != null
                      ? Text(
                          'Pot: ${a.potAfter!.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.outline,
                          ),
                        )
                      : null,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
