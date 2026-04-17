// Prize Structure settings tab — CRUD list of payout structures.
// Each structure shows payout percentages by rank.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../foundation/widgets/empty_state.dart';
import '../../../foundation/widgets/loading_state.dart';
import '../../../repositories/payout_structure_repository.dart';
import '../providers/payout_structure_provider.dart';

class PrizeStructureScreen extends ConsumerWidget {
  const PrizeStructureScreen({super.key});

  // TODO(B-F005): series selector 도입 시 교체. 현재는 series 1 기본.
  static const int _defaultSeriesId = 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final structuresAsync =
        ref.watch(payoutStructureListProvider(_defaultSeriesId));

    return structuresAsync.when(
      loading: () => const LoadingState(),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (structures) {
        if (structures.isEmpty) {
          return const EmptyState(
            message: 'No prize structures defined',
            icon: Icons.emoji_events,
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Action bar
            Row(
              children: [
                Text(
                  'Prize Structures',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showCreateDialog(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Structure'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Structure cards
            ...structures.map((s) => _buildStructureCard(context, ref, s)),
          ],
        );
      },
    );
  }

  Widget _buildStructureCard(
    BuildContext context,
    WidgetRef ref,
    PayoutStructure structure,
  ) {
    final theme = Theme.of(context);
    final payouts = _extractPayouts(structure.raw);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  structure.name,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Edit',
                  onPressed: () =>
                      _showEditDialog(context, ref, structure),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  tooltip: 'Delete',
                  onPressed: () =>
                      _confirmDelete(context, ref, structure),
                ),
              ],
            ),

            // Payout table
            if (payouts.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: DataTable(
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('Rank')),
                    DataColumn(label: Text('Payout %'), numeric: true),
                  ],
                  rows: payouts.entries.map((entry) {
                    return DataRow(cells: [
                      DataCell(Text(entry.key)),
                      DataCell(Text('${entry.value}%')),
                    ]);
                  }).toList(),
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'No payout levels defined',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Extract payout entries from the raw JSON.
  /// Supports: { "payouts": { "1": 50, "2": 30, ... } }
  /// or        { "payouts": [ { "rank": 1, "percentage": 50 }, ... ] }
  Map<String, dynamic> _extractPayouts(Map<String, dynamic> raw) {
    final payoutsField = raw['payouts'];
    if (payoutsField is Map<String, dynamic>) {
      return payoutsField;
    }
    if (payoutsField is List) {
      final map = <String, dynamic>{};
      for (final entry in payoutsField) {
        if (entry is Map<String, dynamic>) {
          final rank = entry['rank']?.toString() ?? '?';
          final pct = entry['percentage'] ?? entry['payout_pct'] ?? 0;
          map[rank] = pct;
        }
      }
      return map;
    }
    return {};
  }

  // -- Dialogs ---------------------------------------------------------------

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Prize Structure'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final repo = ref.read(payoutStructureRepositoryProvider);
      await repo.createPayoutStructure(
        _defaultSeriesId,
        {'name': result, 'payouts': {}},
      );
      ref.invalidate(payoutStructureListProvider(_defaultSeriesId));
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    PayoutStructure structure,
  ) async {
    final nameController = TextEditingController(text: structure.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Prize Structure'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && result != structure.name) {
      final repo = ref.read(payoutStructureRepositoryProvider);
      await repo.updatePayoutStructure(
        _defaultSeriesId,
        structure.payoutStructureId,
        {'name': result},
      );
      ref.invalidate(payoutStructureListProvider(_defaultSeriesId));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    PayoutStructure structure,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Prize Structure?'),
        content: Text(
            'Are you sure you want to delete "${structure.name}"? '
            'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final repo = ref.read(payoutStructureRepositoryProvider);
      await repo.deletePayoutStructure(
        _defaultSeriesId,
        structure.payoutStructureId,
      );
      ref.invalidate(payoutStructureListProvider(_defaultSeriesId));
    }
  }
}
