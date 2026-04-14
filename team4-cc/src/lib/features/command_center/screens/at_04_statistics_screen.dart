// AT-04 Statistics screen (BS-05-07, CCR-027).
// 10-seat VPIP/PFR/3Bet/AF/Hands/WTSD table with individual + table Push to GFX.
//
// Entry: pushed from AT-01 toolbar (Statistics icon).
// RBAC: Admin/Operator full, Viewer read-only.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../foundation/theme/ebs_spacing.dart';
import '../../../foundation/theme/ebs_typography.dart';
import '../../../resources/constants.dart';
import '../../auth/auth_provider.dart';
import '../../stats/providers/stats_provider.dart';

// ---------------------------------------------------------------------------
// AT-04 Statistics Screen
// ---------------------------------------------------------------------------

class At04StatisticsScreen extends ConsumerStatefulWidget {
  const At04StatisticsScreen({super.key});

  @override
  ConsumerState<At04StatisticsScreen> createState() =>
      _At04StatisticsScreenState();
}

class _At04StatisticsScreenState extends ConsumerState<At04StatisticsScreen> {
  int _historyPage = 0;
  int? _expandedHandNumber;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = ref.watch(authProvider);
    final isViewer = auth.role == 'Viewer';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics', style: EbsTypography.toolbarTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!isViewer)
            TextButton.icon(
              onPressed: _pushTableStatsToGfx,
              icon: const Icon(Icons.cast, size: 18),
              label: const Text('Push Table Stats to GFX'),
            ),
        ],
      ),
      body: Column(
        children: [
          // -- Hand count summary --
          _HandCountBar(ref: ref),
          const Divider(height: 1),

          // -- Player stats table --
          Expanded(
            flex: 3,
            child: _PlayerStatsTable(isViewer: isViewer),
          ),

          Divider(height: 1, color: cs.outline),

          // -- Hand history --
          Expanded(
            flex: 2,
            child: _HandHistorySection(
              page: _historyPage,
              expandedHandNumber: _expandedHandNumber,
              onPageChanged: (p) => setState(() => _historyPage = p),
              onToggleExpand: (handNum) => setState(() {
                _expandedHandNumber =
                    _expandedHandNumber == handNum ? null : handNum;
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _pushTableStatsToGfx() {
    debugPrint('Push Table Stats to GFX');
  }
}

// =============================================================================
// Hand Count Bar
// =============================================================================

class _HandCountBar extends StatelessWidget {
  const _HandCountBar({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final sessionCount = ref.watch(sessionHandCountProvider);
    final totalCount = ref.watch(totalHandCountProvider);
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EbsSpacing.md,
        vertical: EbsSpacing.sm,
      ),
      color: cs.surface,
      child: Row(
        children: [
          _CountChip(label: 'Session Hands', value: sessionCount),
          const SizedBox(width: EbsSpacing.lg),
          _CountChip(label: 'Total Hands', value: totalCount),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: EbsTypography.infoBar.copyWith(color: cs.onSurface),
        ),
        Text(
          '$value',
          style: EbsTypography.stackAmount.copyWith(fontSize: 14),
        ),
      ],
    );
  }
}

// =============================================================================
// Player Stats Table
// =============================================================================

class _PlayerStatsTable extends ConsumerWidget {
  const _PlayerStatsTable({required this.isViewer});
  final bool isViewer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final cs = Theme.of(context).colorScheme;

    if (stats.isEmpty) {
      return Center(
        child: Text(
          'No player statistics available',
          style: EbsTypography.infoBar.copyWith(color: cs.onSurface),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(EbsSpacing.sm),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(cs.surface),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return cs.primary.withAlpha(20);
          }
          return null;
        }),
        columnSpacing: EbsSpacing.md,
        columns: [
          const DataColumn(label: Text('Seat')),
          const DataColumn(label: Text('Player')),
          const DataColumn(label: Text('VPIP'), numeric: true),
          const DataColumn(label: Text('PFR'), numeric: true),
          const DataColumn(label: Text('3-Bet'), numeric: true),
          const DataColumn(label: Text('AF'), numeric: true),
          const DataColumn(label: Text('Hands'), numeric: true),
          const DataColumn(label: Text('WTSD'), numeric: true),
          if (!isViewer) const DataColumn(label: Text('GFX')),
        ],
        rows: stats.map((s) {
          return DataRow(
            cells: [
              DataCell(Text('S${s.seatNo}')),
              DataCell(Text(
                s.playerName,
                overflow: TextOverflow.ellipsis,
              )),
              DataCell(Text('${s.vpip.toStringAsFixed(1)}%')),
              DataCell(Text('${s.pfr.toStringAsFixed(1)}%')),
              DataCell(Text('${s.threeBet.toStringAsFixed(1)}%')),
              DataCell(Text(s.af.toStringAsFixed(2))),
              DataCell(Text('${s.hands}')),
              DataCell(Text('${s.wtsd.toStringAsFixed(1)}%')),
              if (!isViewer)
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.play_arrow, size: 18),
                    tooltip: 'Push to GFX',
                    onPressed: () =>
                        debugPrint('Push S${s.seatNo} stats to GFX'),
                    splashRadius: 16,
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// Hand History Section
// =============================================================================

class _HandHistorySection extends ConsumerWidget {
  const _HandHistorySection({
    required this.page,
    required this.expandedHandNumber,
    required this.onPageChanged,
    required this.onToggleExpand,
  });

  final int page;
  final int? expandedHandNumber;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onToggleExpand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(handHistoryProvider);
    final cs = Theme.of(context).colorScheme;
    const pageSize = AppConstants.handHistoryPageSize;
    final totalPages = (history.length / pageSize).ceil().clamp(1, 999);
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, history.length);
    final pageItems = history.isEmpty ? <HandHistoryEntry>[] : history.sublist(start, end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // -- Header --
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: EbsSpacing.md,
            vertical: EbsSpacing.xs,
          ),
          color: cs.surface,
          child: Row(
            children: [
              Text(
                'Hand History',
                style: EbsTypography.toolbarTitle.copyWith(fontSize: 14),
              ),
              const Spacer(),
              // -- Pagination --
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: page > 0 ? () => onPageChanged(page - 1) : null,
                tooltip: 'Previous',
                splashRadius: 16,
              ),
              Text(
                '${page + 1} / $totalPages',
                style: EbsTypography.infoBar,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed:
                    page < totalPages - 1 ? () => onPageChanged(page + 1) : null,
                tooltip: 'Next',
                splashRadius: 16,
              ),
            ],
          ),
        ),

        // -- Hand rows --
        Expanded(
          child: pageItems.isEmpty
              ? Center(
                  child: Text(
                    'No hands played yet',
                    style: EbsTypography.infoBar.copyWith(color: cs.onSurface),
                  ),
                )
              : ListView.builder(
                  itemCount: pageItems.length,
                  itemBuilder: (context, i) {
                    final entry = pageItems[i];
                    final isExpanded =
                        expandedHandNumber == entry.handNumber;
                    return _HandHistoryRow(
                      entry: entry,
                      isExpanded: isExpanded,
                      onTap: () => onToggleExpand(entry.handNumber),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Individual hand history row (expandable)
// ---------------------------------------------------------------------------

class _HandHistoryRow extends StatelessWidget {
  const _HandHistoryRow({
    required this.entry,
    required this.isExpanded,
    required this.onTap,
  });

  final HandHistoryEntry entry;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final losers = entry.loserNames.join(', ');

    return Column(
      children: [
        // -- Summary row --
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: EbsSpacing.md,
              vertical: EbsSpacing.sm,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    '#${entry.handNumber}',
                    style: EbsTypography.infoBar.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                // Winner
                Icon(Icons.emoji_events, size: 14, color: cs.secondary),
                const SizedBox(width: 4),
                Text(
                  entry.winnerName,
                  style: EbsTypography.playerName.copyWith(
                    color: cs.secondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: EbsSpacing.md),
                // Loser(s)
                Expanded(
                  child: Text(
                    losers.isNotEmpty ? 'vs $losers' : '',
                    style: EbsTypography.infoBar,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Pot
                Text(
                  _fmtChips(entry.potSize),
                  style: EbsTypography.stackAmount.copyWith(fontSize: 12),
                ),
                const SizedBox(width: EbsSpacing.sm),
                Icon(
                  isExpanded
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: 18,
                  color: cs.onSurface,
                ),
              ],
            ),
          ),
        ),

        // -- Expanded detail --
        if (isExpanded) _HandDetail(entry: entry),

        Divider(height: 1, color: cs.outline),
      ],
    );
  }

  static String _fmtChips(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
  }
}

// ---------------------------------------------------------------------------
// Hand detail (inline expand)
// ---------------------------------------------------------------------------

class _HandDetail extends StatelessWidget {
  const _HandDetail({required this.entry});
  final HandHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        EbsSpacing.xl,
        0,
        EbsSpacing.md,
        EbsSpacing.sm,
      ),
      color: cs.surface.withAlpha(120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Board cards
          if (entry.boardCards.isNotEmpty) ...[
            const SizedBox(height: EbsSpacing.xs),
            Row(
              children: [
                Text(
                  'Board: ',
                  style: EbsTypography.infoBar.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                ...entry.boardCards.map((card) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Container(
                        width: 32,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: cs.outline),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          card,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )),
              ],
            ),
          ],

          // Actions
          if (entry.actions.isNotEmpty) ...[
            const SizedBox(height: EbsSpacing.xs),
            Text(
              'Actions:',
              style: EbsTypography.infoBar.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            for (final action in entry.actions)
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  action,
                  style: EbsTypography.infoBar.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
