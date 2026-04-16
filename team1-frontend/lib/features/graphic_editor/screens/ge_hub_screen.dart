import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../foundation/widgets/empty_state.dart';
import '../../../foundation/widgets/loading_state.dart';
import '../../../models/models.dart';
import '../providers/ge_provider.dart';

/// Graphic Editor hub — grid of available skins with upload, activate, delete.
///
/// Ported from GraphicEditorHubPage.vue (CCR-011, UI-04).
class GeHubScreen extends ConsumerStatefulWidget {
  const GeHubScreen({super.key});

  @override
  ConsumerState<GeHubScreen> createState() => _GeHubScreenState();
}

class _GeHubScreenState extends ConsumerState<GeHubScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger initial fetch.
    Future.microtask(() => ref.read(skinListProvider.notifier).fetch());
  }

  // -----------------------------------------------------------------------
  // Actions
  // -----------------------------------------------------------------------

  Future<void> _handleUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['riv', 'zip'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    final notifier = ref.read(skinUploadProvider.notifier);
    notifier.startUpload();

    // TODO: wire actual API upload — repository.upload(file.bytes!, file.name)
    // For now simulate progress.
    for (var i = 0; i <= 100; i += 20) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      notifier.updateProgress(i.toDouble());
    }
    notifier.setReady();
  }

  Future<void> _handleActivate(Skin skin) async {
    ref.read(activationPendingProvider.notifier).state = true;
    try {
      // TODO: wire API — repository.activate(skin.skinId)
      ref.read(skinListProvider.notifier).setActive(skin.skinId);
      ref.read(activeSkinIdProvider.notifier).state = skin.skinId;
    } finally {
      ref.read(activationPendingProvider.notifier).state = false;
    }
  }

  Future<void> _handleDelete(Skin skin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Skin'),
        content: Text('Delete "${skin.metadata.title.isNotEmpty ? skin.metadata.title : skin.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // TODO: wire API — repository.delete(skin.skinId)
    ref.read(skinListProvider.notifier).applyRemoteDelete(skin.skinId);
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'validated':
        return Colors.blue;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final skinsAsync = ref.watch(skinListProvider);
    final uploadState = ref.watch(skinUploadProvider);
    final activeSkinId = ref.watch(activeSkinIdProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(uploadState),
            const SizedBox(height: 16),

            // Upload progress
            if (uploadState.status == SkinUploadStatus.uploading)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(
                  value: uploadState.progress / 100,
                ),
              ),

            // Content
            Expanded(
              child: skinsAsync.when(
                loading: () => const LoadingState(),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (skins) {
                  if (skins.isEmpty) {
                    return const EmptyState(
                      message: 'No skins uploaded yet',
                      icon: Icons.palette,
                    );
                  }
                  return _buildGrid(skins, activeSkinId);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(SkinUploadState uploadState) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Graphic Editor',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Browse, upload, and activate overlay skins',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed:
              uploadState.status == SkinUploadStatus.uploading ? null : _handleUpload,
          icon: const Icon(Icons.upload),
          label: const Text('Upload'),
        ),
      ],
    );
  }

  Widget _buildGrid(List<Skin> skins, int? activeSkinId) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 800
                ? 3
                : constraints.maxWidth > 500
                    ? 2
                    : 1;

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: skins.length,
          itemBuilder: (context, index) {
            final skin = skins[index];
            final isActive = skin.skinId == activeSkinId;
            return _SkinCard(
              skin: skin,
              isActive: isActive,
              statusColor: _statusColor(skin.status),
              onTap: () => context.go('/graphic-editor/${skin.skinId}'),
              onActivate: () => _handleActivate(skin),
              onDelete: () => _handleDelete(skin),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Skin card
// ---------------------------------------------------------------------------

class _SkinCard extends StatelessWidget {
  final Skin skin;
  final bool isActive;
  final Color statusColor;
  final VoidCallback onTap;
  final VoidCallback onActivate;
  final VoidCallback onDelete;

  const _SkinCard({
    required this.skin,
    required this.isActive,
    required this.statusColor,
    required this.onTap,
    required this.onActivate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? const BorderSide(color: Colors.green, width: 2)
            : BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview thumbnail
            Expanded(
              child: skin.previewUrl != null
                  ? Image.network(
                      skin.previewUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(context),
                    )
                  : _placeholder(context),
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          skin.metadata.title.isNotEmpty
                              ? skin.metadata.title
                              : skin.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ACTIVE',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'v${skin.version}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                      const Spacer(),
                      // Context actions
                      PopupMenuButton<String>(
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        onSelected: (value) {
                          switch (value) {
                            case 'activate':
                              onActivate();
                            case 'delete':
                              onDelete();
                          }
                        },
                        itemBuilder: (_) => [
                          if (!isActive)
                            const PopupMenuItem(
                              value: 'activate',
                              child: Text('Activate'),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
