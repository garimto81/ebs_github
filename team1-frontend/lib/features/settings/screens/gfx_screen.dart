// GFX settings screen — ported from GfxPage.vue.
//
// Layout preset, card style, player display toggles (photo/flag/chip count),
// animation speed slider. Team 1 owns form + rive-js preview only.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

class GfxScreen extends ConsumerStatefulWidget {
  const GfxScreen({super.key});

  @override
  ConsumerState<GfxScreen> createState() => _GfxScreenState();
}

class _GfxScreenState extends ConsumerState<GfxScreen> {
  static const _layoutPresetOptions = [
    ('standard-9', 'Standard (9-max)'),
    ('standard-6', 'Standard (6-max)'),
    ('heads-up', 'Heads Up'),
    ('final-table', 'Final Table'),
  ];

  static const _cardStyleOptions = [
    ('classic', 'Classic'),
    ('four-color', 'Four-Color'),
    ('jumbo', 'Jumbo'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchIfIdle();
  }

  void _fetchIfIdle() {
    final state = ref.read(settingsSectionProvider(SettingsSection.gfx));
    if (!state.isLoading && state.committed.isEmpty && state.error == null) {
      ref.read(settingsSectionProvider(SettingsSection.gfx).notifier).fetch();
    }
  }

  SettingsSectionNotifier get _notifier =>
      ref.read(settingsSectionProvider(SettingsSection.gfx).notifier);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsSectionProvider(SettingsSection.gfx));
    final draft = state.draft;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final animSpeed = (draft['animationSpeed'] as num?)?.toDouble() ?? 1.0;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Layout Preset
        DropdownButtonFormField<String>(
          value: (draft['layoutPreset'] as String?) ?? 'standard-9',
          decoration: const InputDecoration(labelText: 'Layout Preset'),
          items: _layoutPresetOptions
              .map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)))
              .toList(),
          onChanged: (v) => _notifier.updateField('layoutPreset', v),
        ),
        const SizedBox(height: 20),

        // Card Style
        DropdownButtonFormField<String>(
          value: (draft['cardStyle'] as String?) ?? 'classic',
          decoration: const InputDecoration(labelText: 'Card Style'),
          items: _cardStyleOptions
              .map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)))
              .toList(),
          onChanged: (v) => _notifier.updateField('cardStyle', v),
        ),
        const SizedBox(height: 24),

        // Player Display Options
        Text(
          'Player Display Options',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Show Player Photo'),
          value: (draft['showPlayerPhoto'] as bool?) ?? true,
          onChanged: (v) => _notifier.updateField('showPlayerPhoto', v),
        ),
        SwitchListTile(
          title: const Text('Show Player Flag'),
          value: (draft['showPlayerFlag'] as bool?) ?? true,
          onChanged: (v) => _notifier.updateField('showPlayerFlag', v),
        ),
        SwitchListTile(
          title: const Text('Show Chip Count'),
          value: (draft['showChipCount'] as bool?) ?? true,
          onChanged: (v) => _notifier.updateField('showChipCount', v),
        ),
        const SizedBox(height: 24),

        // Animation Speed
        Text(
          'Animation Speed: ${animSpeed.toStringAsFixed(2)}x',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Slider(
          value: animSpeed.clamp(0.5, 3.0),
          min: 0.5,
          max: 3.0,
          divisions: 10,
          label: '${animSpeed.toStringAsFixed(2)}x',
          onChanged: (v) => _notifier.updateField('animationSpeed', v),
        ),

        // Error banner
        if (state.error != null) ...[
          const SizedBox(height: 16),
          MaterialBanner(
            content: Text(state.error!),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            contentTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            actions: const [SizedBox.shrink()],
          ),
        ],
      ],
    );
  }
}
