// Blind Structure settings tab — CRUD list of blind structures with
// expandable levels. Each structure shows level_no, small_blind,
// big_blind, ante, duration_minutes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../foundation/widgets/empty_state.dart';
import '../../../foundation/widgets/loading_state.dart';
import '../../../models/models.dart';
import '../../../repositories/settings_repository.dart';
import '../providers/blind_structure_provider.dart';

class BlindStructureScreen extends ConsumerStatefulWidget {
  const BlindStructureScreen({super.key});

  @override
  ConsumerState<BlindStructureScreen> createState() =>
      _BlindStructureScreenState();
}

class _BlindStructureScreenState extends ConsumerState<BlindStructureScreen> {
  int? _expandedId;

  @override
  Widget build(BuildContext context) {
    final structuresAsync = ref.watch(blindStructureListProvider);

    return structuresAsync.when(
      loading: () => const LoadingState(),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (structures) {
        if (structures.isEmpty) {
          return const EmptyState(
            message: 'No blind structures defined',
            icon: Icons.casino,
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Action bar
            Row(
              children: [
                Text(
                  'Blind Structures',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showCreateDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Structure'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Structure list
            ...structures.map((s) => _buildStructureCard(context, s)),
          ],
        );
      },
    );
  }

  Widget _buildStructureCard(BuildContext context, BlindStructure structure) {
    final isExpanded = _expandedId == structure.blindStructureId;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(
              structure.name,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Updated: ${structure.updatedAt}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Edit',
                  onPressed: () =>
                      _showEditDialog(context, structure),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  tooltip: 'Delete',
                  onPressed: () =>
                      _confirmDelete(context, structure),
                ),
                Icon(isExpanded
                    ? Icons.expand_less
                    : Icons.expand_more),
              ],
            ),
            onTap: () {
              setState(() {
                _expandedId = isExpanded
                    ? null
                    : structure.blindStructureId;
              });
            },
          ),
          if (isExpanded)
            _BlindLevelsTable(
                blindStructureId: structure.blindStructureId),
        ],
      ),
    );
  }

  // -- Dialogs ---------------------------------------------------------------

  Future<void> _showCreateDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Blind Structure'),
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
      final repo = ref.read(settingsRepositoryProvider);
      await repo.createBlindStructure({'name': result});
      ref.invalidate(blindStructureListProvider);
    }
  }

  Future<void> _showEditDialog(
      BuildContext context, BlindStructure structure) async {
    final nameController = TextEditingController(text: structure.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Blind Structure'),
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
      final repo = ref.read(settingsRepositoryProvider);
      await repo.updateBlindStructure(
        structure.blindStructureId,
        {'name': result},
      );
      ref.invalidate(blindStructureListProvider);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, BlindStructure structure) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Blind Structure?'),
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
      final repo = ref.read(settingsRepositoryProvider);
      await repo.deleteBlindStructure(structure.blindStructureId);
      ref.invalidate(blindStructureListProvider);
      if (_expandedId == structure.blindStructureId) {
        setState(() => _expandedId = null);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Levels table (loaded when a structure card is expanded)
// ---------------------------------------------------------------------------

class _BlindLevelsTable extends ConsumerWidget {
  final int blindStructureId;
  const _BlindLevelsTable({required this.blindStructureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync =
        ref.watch(blindStructureLevelsProvider(blindStructureId));

    return levelsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error loading levels: $err'),
      ),
      data: (levels) {
        if (levels.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No levels defined'),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('Level')),
                DataColumn(label: Text('Small'), numeric: true),
                DataColumn(label: Text('Big'), numeric: true),
                DataColumn(label: Text('Ante'), numeric: true),
                DataColumn(label: Text('Duration (min)'), numeric: true),
              ],
              rows: levels.map((lvl) {
                return DataRow(cells: [
                  DataCell(Text(lvl.levelNo.toString())),
                  DataCell(Text(_fmt(lvl.smallBlind))),
                  DataCell(Text(_fmt(lvl.bigBlind))),
                  DataCell(Text(_fmt(lvl.ante))),
                  DataCell(Text(lvl.durationMinutes.toString())),
                ]);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  static String _fmt(int v) {
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}k';
    }
    return v.toString();
  }
}
