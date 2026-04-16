// Hand History screen — list of hands with expandable detail + table filter.
//
// Ported from _archive-quasar/src/pages/HandHistoryPage.vue (122 LOC).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../foundation/widgets/empty_state.dart';
import '../../../foundation/widgets/loading_state.dart';
import '../../../models/models.dart';
import '../../../resources/l10n/app_localizations.dart';
import '../providers/hand_history_provider.dart';
import '../widgets/hand_detail.dart';

class HandHistoryScreen extends ConsumerStatefulWidget {
  const HandHistoryScreen({super.key});

  @override
  ConsumerState<HandHistoryScreen> createState() => _HandHistoryScreenState();
}

class _HandHistoryScreenState extends ConsumerState<HandHistoryScreen> {
  int? _expandedHandId;

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(handHistoryProvider.notifier).fetchFirst());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(handHistoryProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + table filter
          Row(
            children: [
              Text(l.lobbyHandHistoryTitle,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              // Table selector placeholder — will be wired when
              // TableRepository provides the options list.
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<int>(
                  initialValue: state.filterTableId,
                  decoration: InputDecoration(
                    labelText: l.lobbyHandHistorySelectTable,
                    isDense: true,
                  ),
                  items: const [],
                  onChanged: (tableId) {
                    ref
                        .read(handHistoryProvider.notifier)
                        .fetchFirst(tableId: tableId);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          Expanded(child: _buildContent(state, l, theme)),
        ],
      ),
    );
  }

  Widget _buildContent(
      HandHistoryState state, AppLocalizations l, ThemeData theme) {
    if (state.isLoading && state.items.isEmpty) {
      return const LoadingState();
    }
    if (state.items.isEmpty) {
      return EmptyState(
          message: l.lobbyHandHistoryEmpty, icon: Icons.history);
    }

    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          showCheckboxColumn: false,
          columns: [
            DataColumn(label: Text(l.lobbyHandHistoryHandNo)),
            DataColumn(label: Text(l.lobbyHandHistoryTime)),
            DataColumn(label: Text(l.lobbyHandHistoryBoard)),
            DataColumn(label: Text(l.lobbyHandHistoryPot), numeric: true),
            DataColumn(label: Text(l.lobbyHandHistoryStreet)),
          ],
          rows: state.items.expand((hand) => _buildHandRows(hand)).toList(),
        ),
      ),
    );
  }

  List<DataRow> _buildHandRows(Hand hand) {
    final isExpanded = _expandedHandId == hand.handId;
    return [
      DataRow(
        onSelectChanged: (_) {
          setState(() {
            _expandedHandId = isExpanded ? null : hand.handId;
          });
        },
        cells: [
          DataCell(Text(hand.handNumber.toString())),
          DataCell(Text(hand.startedAt)),
          DataCell(Text(hand.boardCards)),
          DataCell(Text(hand.potTotal.toStringAsFixed(0))),
          DataCell(Text(hand.currentStreet ?? 'ended')),
        ],
      ),
      if (isExpanded)
        DataRow(cells: [
          DataCell(
            SizedBox(
              width: double.infinity,
              child: HandDetail(handId: hand.handId),
            ),
          ),
          const DataCell(SizedBox.shrink()),
          const DataCell(SizedBox.shrink()),
          const DataCell(SizedBox.shrink()),
          const DataCell(SizedBox.shrink()),
        ]),
    ];
  }
}
