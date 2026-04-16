import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../foundation/widgets/loading_state.dart';
import '../../../models/models.dart';
import '../providers/ge_provider.dart';
import '../widgets/rive_preview.dart';

/// Graphic Editor detail — skin metadata, Rive preview, activate/delete.
///
/// Ported from GraphicEditorDetailPage.vue (CCR-011, UI-04).
class GeDetailScreen extends ConsumerStatefulWidget {
  final String skinId;
  const GeDetailScreen({super.key, required this.skinId});

  @override
  ConsumerState<GeDetailScreen> createState() => _GeDetailScreenState();
}

class _GeDetailScreenState extends ConsumerState<GeDetailScreen> {
  bool _editing = false;
  bool _saving = false;
  bool _activating = false;

  // Draft fields for edit mode.
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _authorCtrl;
  List<String> _tagsDraft = [];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _authorCtrl = TextEditingController();

    // Select this skin in the provider.
    final id = int.tryParse(widget.skinId);
    if (id != null) {
      Future.microtask(() {
        ref.read(selectedSkinIdProvider.notifier).state = id;
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Supported output resolutions shown as informational chips.
  static const _resolutions = [
    '1920x1080',
    '2560x1440',
    '3840x2160',
  ];

  // -----------------------------------------------------------------------
  // Edit lifecycle
  // -----------------------------------------------------------------------

  void _startEdit(Skin skin) {
    setState(() {
      _editing = true;
      _titleCtrl.text = skin.metadata.title;
      _descCtrl.text = skin.metadata.description;
      _authorCtrl.text = skin.metadata.author ?? '';
      _tagsDraft = List<String>.from(skin.metadata.tags);
    });
  }

  void _cancelEdit() {
    setState(() => _editing = false);
  }

  Future<void> _saveMetadata(Skin skin) async {
    setState(() => _saving = true);
    try {
      final updated = SkinMetadata(
        title: _titleCtrl.text,
        description: _descCtrl.text,
        author: _authorCtrl.text.isEmpty ? null : _authorCtrl.text,
        tags: _tagsDraft,
      );
      ref.read(metadataDraftProvider.notifier).state = updated;

      // TODO: wire API — repository.updateMetadata(skin.skinId, updated)
      // For now update locally.
      ref.read(skinListProvider.notifier).applyRemoteUpdate(
            skin.copyWith(metadata: updated),
          );
      setState(() => _editing = false);
    } finally {
      setState(() => _saving = false);
    }
  }

  // -----------------------------------------------------------------------
  // Actions
  // -----------------------------------------------------------------------

  Future<void> _handleActivate(Skin skin) async {
    setState(() => _activating = true);
    try {
      // TODO: wire API — repository.activate(skin.skinId)
      ref.read(skinListProvider.notifier).setActive(skin.skinId);
      ref.read(activeSkinIdProvider.notifier).state = skin.skinId;
    } finally {
      setState(() => _activating = false);
    }
  }

  Future<void> _handleDeactivate(Skin skin) async {
    setState(() => _activating = true);
    try {
      // TODO: wire API — repository.deactivate(skin.skinId)
      ref.read(skinListProvider.notifier).applyRemoteUpdate(
            skin.copyWith(status: 'validated'),
          );
      ref.read(activeSkinIdProvider.notifier).state = null;
    } finally {
      setState(() => _activating = false);
    }
  }

  Future<void> _handleDelete(Skin skin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Skin'),
        content: Text(
          'Delete "${skin.metadata.title.isNotEmpty ? skin.metadata.title : skin.name}"? This cannot be undone.',
        ),
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
    if (confirmed != true || !mounted) return;
    // TODO: wire API — repository.delete(skin.skinId)
    ref.read(skinListProvider.notifier).applyRemoteDelete(skin.skinId);
    context.go('/graphic-editor');
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final skin = ref.watch(selectedSkinProvider);
    final activeSkinId = ref.watch(activeSkinIdProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            TextButton.icon(
              onPressed: () => context.go('/graphic-editor'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
            const SizedBox(height: 16),

            // Content
            if (skin == null)
              const Expanded(child: LoadingState())
            else
              Expanded(child: _buildContent(skin, activeSkinId)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Skin skin, int? activeSkinId) {
    final isActive = skin.skinId == activeSkinId;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column: Preview + Status
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildPreviewCard(),
                const SizedBox(height: 16),
                _buildStatusCard(skin, isActive),
                const SizedBox(height: 16),
                _buildResolutionCard(),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Right column: Metadata
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            child: _buildMetadataCard(skin),
          ),
        ),
      ],
    );
  }

  // -----------------------------------------------------------------------
  // Cards
  // -----------------------------------------------------------------------

  Widget _buildPreviewCard() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Preview',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const Divider(height: 1),
          const SizedBox(
            height: 240,
            child: RivePreview(riveBytes: null), // TODO: load actual bytes
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(Skin skin, bool isActive) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor(skin.status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    skin.status.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow('Version', 'v${skin.version}'),
            _infoRow('File size', _formatFileSize(skin.fileSize)),
            _infoRow('Uploaded', skin.uploadedAt),
            if (skin.activatedAt != null)
              _infoRow('Activated', skin.activatedAt!),
            const SizedBox(height: 12),
            // Action buttons
            Wrap(
              spacing: 8,
              children: [
                if (!isActive)
                  FilledButton(
                    onPressed: _activating ? null : () => _handleActivate(skin),
                    child: _activating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Activate'),
                  ),
                if (isActive)
                  FilledButton.tonal(
                    onPressed:
                        _activating ? null : () => _handleDeactivate(skin),
                    child: _activating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Deactivate'),
                  ),
                OutlinedButton(
                  onPressed: () => _handleDelete(skin),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResolutionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supported Resolutions',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _resolutions.map((r) {
                return Chip(
                  label: Text(r),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard(Skin skin) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Metadata',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _editing
                ? _buildEditForm(skin)
                : _buildReadOnlyMeta(skin),
          ),
          // Edit / Save / Cancel actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!_editing)
                  TextButton.icon(
                    onPressed: () => _startEdit(skin),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                if (_editing) ...[
                  TextButton(
                    onPressed: _cancelEdit,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : () => _saveMetadata(skin),
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyMeta(Skin skin) {
    final meta = skin.metadata;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _metaField('Title', meta.title.isNotEmpty ? meta.title : skin.name),
        _metaField('Description', meta.description.isNotEmpty ? meta.description : '\u2014'),
        _metaField('Author', meta.author ?? '\u2014'),
        const SizedBox(height: 8),
        Text(
          'Tags',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: 4),
        meta.tags.isNotEmpty
            ? Wrap(
                spacing: 6,
                runSpacing: 6,
                children: meta.tags
                    .map((t) => Chip(
                          label: Text(t),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              )
            : const Text('\u2014'),
        const SizedBox(height: 16),
        // Color palette placeholder (from skin manifest)
        Text(
          'Color Palette (8 role colors)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: 8),
        _buildColorPalette(),
        const SizedBox(height: 16),
        // Font info placeholder
        Text(
          'Font',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: 4),
        // TODO: read from skin manifest
        const Text('Roboto Mono (bundled)'),
      ],
    );
  }

  Widget _buildEditForm(Skin skin) {
    return Column(
      children: [
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descCtrl,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _authorCtrl,
          decoration: const InputDecoration(
            labelText: 'Author',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        // Tags editor — simple comma-separated input for now.
        TextField(
          decoration: const InputDecoration(
            labelText: 'Tags (comma-separated)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          controller: TextEditingController(text: _tagsDraft.join(', ')),
          onChanged: (val) {
            _tagsDraft = val
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList();
          },
        ),
      ],
    );
  }

  // -----------------------------------------------------------------------
  // Small helpers
  // -----------------------------------------------------------------------

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          Flexible(child: Text(value, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }

  Widget _metaField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  /// Placeholder 8-color palette. In production these come from the skin
  /// manifest's role color map.
  Widget _buildColorPalette() {
    // TODO: read from skin manifest — skin.metadata.roleColors
    const placeholderColors = [
      Color(0xFFE53935), // Player 1
      Color(0xFF1E88E5), // Player 2
      Color(0xFF43A047), // Player 3
      Color(0xFFFDD835), // Player 4
      Color(0xFF8E24AA), // Player 5
      Color(0xFFFF6F00), // Player 6
      Color(0xFF00ACC1), // Player 7
      Color(0xFF6D4C41), // Player 8
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: placeholderColors.map((c) {
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        );
      }).toList(),
    );
  }
}
